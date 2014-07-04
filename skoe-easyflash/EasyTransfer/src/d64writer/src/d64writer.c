/*
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
#include <stdint.h>
#include <string.h>

#include <ef3usb.h>

#include "d64writer.h"

int main(void)
{
    const char* p_str_cmd;

    puts("D64 writer started");

    for (;;)
    {
        puts("\nWaiting for command from USB...");
        do
        {
            p_str_cmd = ef3usb_check_cmd();
        }
        while (p_str_cmd == NULL);
        printf("Command: %s\n", p_str_cmd);

        if (strcmp(p_str_cmd, "d64") == 0)
        {
            write_disk_d64();
        }
        else
        {
            ef3usb_send_str("etyp");
        }
    }

    return 0;
}
