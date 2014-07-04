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
#include <string.h>

#include <ftdi.h>

#include "ef3xfer.h"
#include "ef3xfer_internal.h"

/* function pointers which can be overridden from external apps */
static void (*log_str)(const char* str);
static void (*log_progress)(int percent, int b_gui_only);

/*****************************************************************************/
void ef3xfer_set_callbacks(
        void (*custom_log_str)(const char* str),
        void (*custom_log_progress)(int percent, int b_gui_only))
{
    log_str      = custom_log_str;
    log_progress = custom_log_progress;
}


/*****************************************************************************/
/*
 */
void ef3xfer_log_ftdi_error(int reason, struct ftdi_context *p_ftdic)
{
    const char* p_str_cause;

    if (reason < 0)
        p_str_cause = strerror(-reason);
    else
        p_str_cause = "unknown cause";

    ef3xfer_log_printf("USB operation failed: %d (%s - %s)\n", reason,
            ftdi_get_error_string(p_ftdic),
            p_str_cause);
}


/*****************************************************************************/
/**
 *
 */
void ef3xfer_log_printf(const char* p_str_format, ...)
{
    va_list args;
    char str[200];

    va_start(args, p_str_format);
    vsnprintf(str, sizeof(str) - 1, p_str_format, args);
    va_end(args);

    str[sizeof(str) - 1] = '\0';
    log_str(str);
}


/*****************************************************************************/
/**
 *
 */
void ef3xfer_log_progress(int percent, int b_gui_only)
{
    log_progress(percent, b_gui_only);
}


