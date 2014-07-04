
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include <ef3usb.h>

#include "prgstart.h"


int main(void)
{
    const char* p_str_cmd;

    puts("PRG starter");

    for (;;)
    {
        puts("\nWaiting for command from USB...");
        do
        {
            p_str_cmd = ef3usb_check_cmd();
        }
        while (p_str_cmd == NULL);
        printf("Command: %s\n", p_str_cmd);

        if (strcmp(p_str_cmd, "prg") == 0)
        {
            ef3usb_send_str("load");
            puts("Loading");
            usbtool_prg_load_and_run();
        }
        else
        {
            /* todo: reset */
            ef3usb_send_str("etyp");
        }
    }

    return 0;
}
