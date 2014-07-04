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
#include <stdint.h>

#include <ftdi.h>

#include "ef3xfer.h"
#include "ef3xfer_internal.h"

static int test_sequence(void);
static int check_usb_with_value(uint8_t val);


/*****************************************************************************/
/**
 *
 */
int ef3xfer_usb_test(void)
{
    int     success;

    success = run_usb_test();

    if (success)
    {
        ef3xfer_log_printf("\nOK\n\n");
        return 0;
    }
    else
    {
        ef3xfer_log_printf("\nFailed\n\n");
        return 1;
    }
}


/*****************************************************************************/
/**
 *
 */
int run_usb_test()
{
    int     test_loop, success;

    ef3xfer_log_printf("Testing...\n");
    for (test_loop = 0; test_loop < 100; ++test_loop)
    {
        success = test_sequence();
        if (!success)
            return 0;

        ef3xfer_log_progress(test_loop + 1, 0);
    }
    return success;
}


/*****************************************************************************/
/**
 *
 */
static int test_sequence(void)
{
    uint8_t val;
    int bit;
    int success;

    val = 0x01;
    for (bit = 0; bit < 8; ++bit)
    {
        success = check_usb_with_value(val);
        if (!success)
            return 0;
        val <<= 1;
    }
    val = 0xfe;
    for (bit = 0; bit < 8; ++bit)
    {
        success = check_usb_with_value(val);
        if (!success)
            return 0;
        val = (val << 1) | 1;
    }
    return bit;
}


/*****************************************************************************/
/**
 *
 */
static int check_usb_with_value(uint8_t val)
{
    uint8_t ret_val;
    int ret;

    ret = ef3xfer_write_to_ftdi(&val, 1);
    if (ret != 1)
        return 0;

    ret = ef3xfer_read_from_ftdi(&ret_val, 1);
    if (ret != 1)
        return 0;

    if (ret_val != val)
    {
        ef3xfer_log_printf("Error: Sent 0x%02x but received 0x%02x\n",
                val, ret_val);
        return 0;
    }
    return 1;
}

