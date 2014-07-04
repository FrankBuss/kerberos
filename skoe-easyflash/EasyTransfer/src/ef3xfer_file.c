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

#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>

#include <ftdi.h>

#include "ef3xfer.h"
#include "ef3xfer_internal.h"
#include "str_to_key.h"

static int send_file(FILE* fp);
static int send_data(const unsigned char* p_data, int size);


/*****************************************************************************/
/*
 * Return 1 on success, 0 otherwise.
 */
int ef3xfer_raw_send(const char* p_filename)
{
    FILE*         fp;
    size_t        i, size;
    uint8_t*      p;
    uint8_t       buffer[256];

    if (p_filename == NULL)
    {
        ef3xfer_log_printf("Missing file name.\n");
        return 0;
    }

    ef3xfer_log_printf("Send raw file:  %s\n", p_filename);

    fp = fopen(p_filename, "rb");
    if (fp == NULL)
    {
        ef3xfer_log_printf("Error: Cannot open %s for reading\n", p_filename);
        return 0;
    }

    do
    {
        size = fread(buffer, 1, sizeof(buffer), fp);
        printf("\n%d\n", (int) size);
        if (size)
        {
            if (ef3xfer_write_to_ftdi(buffer, size) != size)
                goto close_and_err;
        }
    }
    while (size);

    ef3xfer_disconnect_ftdi();
    fclose(fp);
    ef3xfer_log_printf("\nOK\n\n");
    return 1;

close_and_err:
    ef3xfer_disconnect_ftdi();
    fclose(fp);
    return 0;
}

/*****************************************************************************/
int ef3xfer_transfer_crt(const char* p_filename)
{
    FILE*         fp;
    size_t        i, size;
    uint8_t*      p;
    uint8_t       start[2];

    if (p_filename == NULL)
    {
        ef3xfer_log_printf("Missing file name.\n");
        return 0;
    }

    ef3xfer_log_printf("Send CRT file:  %s\n", p_filename);

    fp = fopen(p_filename, "rb");
    if (fp == NULL)
    {
        ef3xfer_log_printf("Error: Cannot open %s for reading\n", p_filename);
        return 0;
    }

    if (!ef3xfer_do_handshake("CRT"))
        goto close_and_err;

    if (!send_file(fp))
        goto close_and_err;

    ef3xfer_disconnect_ftdi();
    fclose(fp);
    ef3xfer_log_printf("\nOK\n\n");
    return 1;

close_and_err:
    ef3xfer_disconnect_ftdi();
    fclose(fp);
    return 0;
}


/*****************************************************************************/
int ef3xfer_transfer_prg(const char* p_filename)
{
    FILE*         fp;
    size_t        i, size;
    uint8_t*      p;

    if (p_filename == NULL)
    {
        ef3xfer_log_printf("Missing file name.\n");
        return 0;
    }

    ef3xfer_log_printf("Send PRG file:  %s\n", p_filename);

    fp = fopen(p_filename, "rb");
    if (fp == NULL)
    {
        ef3xfer_log_printf("Error: Cannot open %s for reading\n", p_filename);
        return 0;
    }

    if (!ef3xfer_do_handshake("PRG"))
        goto close_and_err;

    if (!send_file(fp))
        goto close_and_err;

    ef3xfer_disconnect_ftdi();
    fclose(fp);
    ef3xfer_log_printf("\nOK\n\n");
    return 1;

close_and_err:
    ef3xfer_disconnect_ftdi();
    fclose(fp);
    return 0;
}


/*****************************************************************************/
int ef3xfer_transfer_prg_mem(const unsigned char* p_prg, int size)
{
    ef3xfer_log_printf("Send PRG\n");

    if (!ef3xfer_do_handshake("PRG"))
        goto close_and_err;

    if (!send_data(p_prg, size))
        goto close_and_err;

    ef3xfer_disconnect_ftdi();
    ef3xfer_log_printf("\nOK\n\n");
    return 1;

close_and_err:
    ef3xfer_disconnect_ftdi();
    return 0;
}




/*****************************************************************************/
/**
 *
 */
static int send_file(FILE* fp)
{
    static unsigned char a_buffer[0x10000]; /* <= yay! */
    unsigned char a_buffer_size[2];
    int           n_bytes_req;
    long          size_file;
    int           ret, count, rest;

    /* todo: use fstat */
    fseek(fp, 0, SEEK_END);
    size_file = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    do
    {
        /* read the number of bytes requested by the client (0..256) */
        if (!ef3xfer_read_from_ftdi(a_buffer_size, 2))
        {
            return 0;
        }
        n_bytes_req = a_buffer_size[0] + a_buffer_size[1] * 256;

        if (n_bytes_req > 0)
        {
            if (feof(fp))
                count = 0;
            else
                count = fread(a_buffer, 1, n_bytes_req, fp);

            // todo: error checks

            a_buffer_size[0] = count & 0xff;
            a_buffer_size[1] = count >> 8;
            // send length indication
            ret = ef3xfer_write_to_ftdi(a_buffer_size, 2);
            if (ret != 2)
            {
                return 0;
            }
            // send payload
            ret = ef3xfer_write_to_ftdi(a_buffer, count);
            if (ret != count)
            {
                return 0;
            }
        }
        // todo: check overhead
        ef3xfer_log_progress((int)(100 * (ftell(fp) + 1) / size_file), 0);
    }
    while (n_bytes_req > 0);

    return 1;
}


/*****************************************************************************/
/**
 *
 */
static int send_data(const unsigned char* p_data, int size)
{
    const unsigned char* p;
    unsigned char a_buffer_size[2];
    int           n_bytes_req;
    int           ret, count, rest;

    rest = size;
    p = p_data;
    do
    {
        /* read the number of bytes requested by the client (0..256) */
        if (!ef3xfer_read_from_ftdi(a_buffer_size, 2))
        {
            return 0;
        }
        n_bytes_req = a_buffer_size[0] + a_buffer_size[1] * 256;

        if (n_bytes_req > 0)
        {
            if (n_bytes_req < rest)
                count = n_bytes_req;
            else
                count = rest;

            a_buffer_size[0] = count & 0xff;
            a_buffer_size[1] = count >> 8;
            // send length indication
            ret = ef3xfer_write_to_ftdi(a_buffer_size, 2);
            if (ret != 2)
            {
                return 0;
            }
            // send payload
            ret = ef3xfer_write_to_ftdi(p, count);
            if (ret != count)
            {
                return 0;
            }
            p += count;
            rest -= count;
        }
        // todo: check overhead
        ef3xfer_log_progress((int)(100 * ((size - rest) + 1) / size), 0);
    }
    while (n_bytes_req > 0);

    return 1;
}



