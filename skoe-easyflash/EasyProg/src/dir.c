/*
 * EasyProg - dir.c - Directory loader
 *
 * (c) 2009 Thomas Giesel
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

#include <cbm.h>
#include <conio.h>
#include <string.h>
#include <stdint.h>
#include "dir.h"

/******************************************************************************/
/**
 * Open the directory file and redirect input to this file if there was no
 * error.
 *
 */
uint8_t __fastcall__ dirOpen(uint8_t lfn, uint8_t device)
{
    if (!cbm_open(lfn, device, CBM_READ, "$"))
    {
        if (cbm_k_chkin(lfn) == 0)
        {
            /* Ignore start address */
            cbm_k_basin();
            cbm_k_basin();
            if (cbm_k_readst())
            {
                dirClose(lfn);
                return 1;
            }

            return 0;
        }
    }
    dirClose(lfn);
    return 1;
}

/******************************************************************************/
/**
 * Load directory header. RVS_ON has been found already, so search for " first.
 * then read up to incl. terminating 0 and return the entry.
 *
 * Return 1 in case of an error, 0 for okay
 */
static uint8_t __fastcall__ dirReadEntryInternal(DirEntry* pEntry, uint8_t bIsHeader)
{
    uint8_t byte, i, j;
    uint8_t state;

    /* states:   0 "  1  " 2 */

    /* first quote read already if this is not the header */
    state = bIsHeader ?  0 : 1;

    i = j = 0;

    for (;;)
    {
        byte = cbm_k_basin();

        if (cbm_k_readst())
            return 1;

        if (!byte)
        {
            if (state == 2)
                /* normal EOL */
                break;
            else
                /* abnormal EOL */
                return 1;
        }
        else if (byte == '\"')
        {
            if (state == 0)
                state = 1;  /* enter quotes */
            else if (state == 1)
                state = 2;  /* leave quotes */
            else
                return 1;   /* third quote?! */
        }
        else if (state == 1 && i < sizeof(pEntry->name) - 1)
        {
            pEntry->name[i++] = byte;
        }
        else if (state == 2 && j < sizeof(pEntry->type) - 1 && byte != ' ')
        {
            pEntry->type[j++] = byte;
        }
    }

    pEntry->name[i] = '\0';
    pEntry->type[j] = '\0';
    return 0;
}


/******************************************************************************/
/**
 * Read an entry from the directory. The first entry may be the disk title,
 * its type will be set to "***". The input must be redirected to the open
 * file already.
 *
 * Return 0 if it has been read. 1 for errors, 2 for EOF.
 */
uint8_t __fastcall__ dirReadEntry(DirEntry* pEntry)
{
    uint8_t byte;
    uint8_t rv;

    rv = 1;

    if (!cbm_k_readst())
    {
        /* skip 2 bytes, next basic line pointer */
        cbm_k_basin();
        cbm_k_basin();

        /* File-size */
        pEntry->size  =  cbm_k_basin();
        pEntry->size |= ((cbm_k_basin()) << 8);

        /* search for "blocks free", an entry, header or EOL */
        for(;;)
        {
            byte = cbm_k_basin();
            if (cbm_k_readst())
                goto ret_val;

            /* "B" BLOCKS FREE. */
            if (byte == 'b')
            {
                /* Read until end, careless callers may call us again */
                while (!cbm_k_readst())
                    cbm_k_basin();

                rv = 2; /* EOF */
                goto ret_val;
            }
            else if (byte == '\"')
            {
                /* Read real entry */
                rv = dirReadEntryInternal(pEntry, 0);
                goto ret_val;
            }
            else if (byte == 0x12)
            {
                /* RVS_ON => header */
                rv = dirReadEntryInternal(pEntry, 1);
                strcpy(pEntry->type, "***");
                goto ret_val;
            }
            else if (!byte)
                /* end of line - shouldn't be here */
                goto ret_val;
        }
    }

ret_val:
    return rv;
}


/******************************************************************************/
/**
 * Restore the default input and close the directory file.
 */
void __fastcall__ dirClose(uint8_t lfn)
{
    cbm_close(lfn);
    cbm_k_clrch();
}


