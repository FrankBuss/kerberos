
#include <stdint.h>
#include <string.h>

#include <ef3usb.h>

extern void usbrx_prg(void);
extern void usbrx_key(void);


void usbrx(void)
{
    const char* p_str_cmd;

    p_str_cmd = ef3usb_check_cmd();

    if(p_str_cmd)
    {
        if (strcmp(p_str_cmd, "prg") == 0)
        {
            ef3usb_send_str("load");
            usbrx_prg();
        }
        if (strcmp(p_str_cmd, "key") == 0)
        {
            ef3usb_send_str("load");
            usbrx_key();
        }
        else
        {
            ef3usb_send_str("etyp");
        }
    }
}
