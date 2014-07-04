/*
 *
 * (c) 2013 Thomas Giesel
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 *
 * Thomas Giesel skoe@directbox.com
 */

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>

#include <ftdi.h>

#include "ef3xfer.h"
#include "ef3xfer_internal.h"
#include "str_to_key.h"

static int                 m_ftdi_connected = 0;
static struct ftdi_context m_ftdic;

static int connect_ftdi(void);
static int send_command(const char* p_str_request);
static void receive_response(unsigned char* p_resp,
                             int timeout_secs);

/* function pointers which can be overridden from external apps */
static void ef3xfer_msleep(unsigned msecs);



/*****************************************************************************/
/**
 *
 */
void ef3xfer_disconnect_ftdi(void)
{
    if (!m_ftdi_connected)
        return;

    ftdi_usb_close(&m_ftdic);
    m_ftdi_connected = 0;
}


/*****************************************************************************/
/**
 * Read the given number of bytes from USB. Do not return before the whole
 * number of bytes has been received.
 *
 * Return size on success, 0 otherwise.
 */
int ef3xfer_read_from_ftdi(void* p_buffer, int size)
{
    unsigned char* p = p_buffer;
    int n_read, ret;

    if (!connect_ftdi())
        return 0;

    n_read = 0;
    do
    {
        ret = ftdi_read_data(&m_ftdic, p + n_read, size - n_read);

        if (ret < 0)
        {
            ef3xfer_log_ftdi_error(ret, &m_ftdic);
            return 0;
        }

        if (ret == 0)
            {} // wxMilliSleep(50); // <= todo

        n_read += ret;
    }
    while (n_read < size);

    return n_read;
}


/*****************************************************************************/
/**
 * Write the given number of bytes from USB. Do not return before the whole
 * number of bytes has been written or an error occurred.
 *
 * Return size on success, 0 otherwise.
 */
int ef3xfer_write_to_ftdi(const void* p_buffer, int size)
{
    unsigned char* p = (unsigned char*) p_buffer; /* <= meh */
    int block_size;
    int n_written, ret;

    if (!connect_ftdi())
        return 0;

    n_written = 0;
    while (n_written < size)
    {
        if (size - n_written > 128)
            block_size = 128;
        else
            block_size = size - n_written;

        ret = ftdi_write_data(&m_ftdic, p + n_written, block_size);

        if (ret < 0)
        {
            ef3xfer_log_ftdi_error(ret, &m_ftdic);
            return 0;
        }

        n_written += ret;
    }

    return n_written;
}


/*****************************************************************************/
/**
 *
 */
int ef3xfer_do_handshake(const char* p_str_type)
{
    int waiting;
    char          str_command[20];
    unsigned char str_response[EF3XFER_RESP_SIZE + 1];

    if (strlen(p_str_type) != 3)
    {
        ef3xfer_log_printf("Error: Bad type \"%s\"\n", p_str_type);
        return 0;
    }

    strcpy(str_command, "EFSTART:");
    strcat(str_command, p_str_type);
    /* Send the command as often as we get "WAIT" as response */
    do
    {
        waiting = 0;
        if (!send_command(str_command))
            return 0;

        receive_response(str_response, 30);

        if (str_response[0] == 0)
            return 0;

        if (strcmp((char*)str_response, "WAIT") == 0)
        {
            ef3xfer_log_printf("Waiting...\n");
            waiting = 1;
        }
    }
    while (waiting);

    ef3xfer_log_printf("Running...\n");

    if (strcmp((char*)str_response, "ETYP") == 0)
    {
        ef3xfer_log_printf("(%s) Client doesn't support this file type or action.\n", str_response);
        return 0;
    }
    else if (strcmp((char*)str_response, "LOAD") == 0)
    {
        ef3xfer_log_printf("(%s) Start to send data.\n", str_response);
        return 1;
    }
    else if (strcmp((char*)str_response, "DONE") == 0)
    {
        ef3xfer_log_printf("(%s) Done.\n", str_response);
        return 1;
    }
    else
    {
        ef3xfer_log_printf("Unknown response: \"%s\"\n", str_response);
        return 0;
    }


    return 0;
}


/*****************************************************************************/
/**
 * Is called automatically from ef3xfer_read_from_ftdi and
 * ef3xfer_write_to_ftdi.
 */
int connect_ftdi(void)
{
    int ret;

    if (m_ftdi_connected)
        return 1;

    if (ftdi_init(&m_ftdic) < 0)
    {
        ef3xfer_log_printf("Failed to initialize FTDI library\n");
        return 0;
    }

    if ((ret = ftdi_usb_open(&m_ftdic, 0x0403, 0x8738)) < 0)
    {
        ef3xfer_log_printf("Unable to open ftdi device: %d (%s)\n", ret,
                ftdi_get_error_string(&m_ftdic));
        return 0;
    }

    ftdi_usb_reset(&m_ftdic);
    ftdi_usb_purge_buffers(&m_ftdic);

    m_ftdi_connected = 1;
    return 1;
}


/*****************************************************************************/
/**
 *
 */
static int send_command(const char* p_str_request)
{
    int           ret;
    unsigned char str_response[8];
    size_t        size_request;

    size_request = strlen(p_str_request) + 1;

    ef3xfer_log_printf("Send command: %s\n", p_str_request);
    // Send request
    ret = ef3xfer_write_to_ftdi(p_str_request, size_request);

    if (ret != size_request)
    {
        ef3xfer_log_printf("Write failed: %d (%s - %s)\n", ret, ftdi_get_error_string(&m_ftdic),
                ret < 0 ? strerror(-ret) : "unknown cause");
        return 0;
    }
    return 1;
}


/*****************************************************************************/
/**
 * Try to receive a response. Return the response (0-terminated) or an empty
 * string of there was no response.
 */
static void receive_response(unsigned char* p_resp,
                             int timeout_secs)
{
    int  ret, retry, i;

    p_resp[0] = 0;
    retry = timeout_secs * 100;
    do
    {
        ef3xfer_msleep(10);
        ret = ef3xfer_read_from_ftdi(p_resp, EF3XFER_RESP_SIZE);
        if (ret)
        {
            p_resp[ret] = 0;
            ef3xfer_log_printf("Got response: \"%s\".\n", (char*) p_resp);
            return;
        }
    }
    while (ret == 0 && --retry);

    ef3xfer_log_printf("Time out.\n", ret, retry);
    p_resp[0] = 0;
}


/*****************************************************************************/
/**
 *
 */
static void ef3xfer_msleep(unsigned msecs)
{
    usleep(1000 * msecs);
}

