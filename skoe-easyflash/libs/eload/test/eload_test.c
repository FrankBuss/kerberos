/*
 * ELoad
 *
 * (c) 2011 Thomas Giesel
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


#include <string.h>
#include <unistd.h>
#include <6502.h>
#include <cbm.h>
#include <c64.h>
#include <conio.h> /* for input (keyboard) only */
#include <stdio.h> /* for output only */

#include "eload.h"

static uint8_t status[3];
static uint8_t block[256];
static uint8_t gcr[325];

// from gcr.s:
void __fastcall__ convert_block_to_gcr(uint8_t* p_dst, uint8_t* p_src);


static uint8_t get_drive_number(void)
{
    int drv;

    //puts("Enter drive number: ");
    //cursor(1);
    //cscanf("%d", &drv);
    //cursor(0);
    //puts("\n");
    drv = 8;

    return drv;
}


static void wait_key(void)
{
    while (kbhit())
        cgetc();
    puts("\n\npress a key");
    cgetc();
}




static unsigned init_eload(void)
{
    unsigned type;
    uint8_t drv;

    drv = get_drive_number();

    type = eload_set_drive_check_fastload(drv);
    printf("\n\nDrive type found: 0x%02x\n", type);
    if (type == 0)
    {
        puts("\nDevice not present");
    }
    return type;
}


static uint8_t sectors_on_track(uint8_t t)
{
    if (t >= 31)
        return 17;
    else if (t >= 24)
        return 18;
    else if (t >= 18)
        return 19;

    return 21;
}

/* write the current GCR sector to the whole disk */
static void write_all_sectors(void)
{
    uint8_t t, s, lim, rest, interleave;

    // disable VIC-II DMA
    VIC.ctrl1 &= 0xef;
    while (VIC.rasterline != 255)
    {}

    for (t = 1; t < 36; ++t)
    {
        interleave = 4;
        lim = sectors_on_track(t);

        for (s = 0; s < lim; ++s)
        {
            /* fixme: hier fehlt was! Interleave! */

            eload_write_sector_nodma((t << 8) | s, gcr);
            eload_recv_block(status, 3);
        }
    }

    // enable VIC-II DMA
    VIC.ctrl1 |= 0x10;
}

static void test_write_sector(void)
{
    unsigned i;

    if (init_eload() == 0)
        return;

    for (i = 0; i < 256; ++i)
    {
        block[i] = i;
    }
    convert_block_to_gcr(gcr, block);

    eload_prepare_drive();
    write_all_sectors();
    eload_close();
}



static void test_read_sector(void)
{
    static uint8_t block[256];
    static uint8_t gcr[325];
    uint8_t t, s, lim, rest, interleave;
    unsigned i;

    if (init_eload() == 0)
        return;

    // disable VIC-II DMA
    SEI();
    VIC.ctrl1 &= 0xef;
    while (VIC.rasterline != 255)
    {}

    eload_prepare_drive();

    for (t = 1; t < 36; ++t)
    {
        interleave = 4;
        lim = sectors_on_track(t);

        s = 0;
        for (rest = lim; rest; --rest)
        {
            /* fixme: hier fehlt was! */
            s += interleave;

            if (s >= lim)
                s = s - lim;

            // todo
            // eload_read_gcr_sector((t << 8) | s);
            eload_recv_block(status, 3);
            if (status[0] == DISK_STATUS_OK)
            {
                // todo eload_recv_gcr_sector_nodma(gcr);
            }
        }
    }

    // enable VIC-II DMA
    VIC.ctrl1 |= 0x10;
    CLI();

    eload_close();
}


static void test_format(void)
{
    if (init_eload() == 0)
        return;

    eload_prepare_drive();

    puts("formatting...");
    eload_format(40, 0x1234);
    eload_recv_block(status, 3);
    printf("result: %d, %d\n", status[0],
           status[1] | (status[2] << 8));

    eload_close();
    wait_key();
}


static void test_checksums(void)
{
    uint8_t n_track;
    unsigned i, pos, pass;

    if (init_eload() == 0)
        return;

    eload_prepare_drive();

    for (i = 0; i < 256; ++i)
    {
        block[i] = 0;
    }
    convert_block_to_gcr(gcr, block);

    eload_format(35, 0x1234);
    eload_recv_block(status, 3);

    write_all_sectors();

    for (pass = 1; pass < 10; ++pass)
    {
        printf("Verify pass %d\n", pass);
        for (n_track = 1; n_track <= 35; ++n_track)
        {
            eload_checksum(n_track);
            eload_recv_block(status, 3);
            if (status[0] == DISK_STATUS_OK)
            {
                eload_recv_block(block, 0);
                for (pos = 10; pos < 21 * 12 + 10; pos += 12)
                {
                    if (block[pos] != 0xcd || block[pos + 1] != 0x40)
                    {
                        printf("Track %d, pos %d: %02x %02x\n",
                                n_track, pos,
                                block[pos], block[pos + 1]);
                    }
                }
            }
            else
                printf("Error received\n");
        }
    }
    wait_key();
}


int main(void)
{
    uint8_t key;

    do
    {
        putchar(147); // clr
        puts("\nELoad Test Program\n");
        puts(" F : Low level format (no directory)");
        puts(" W : Write sectors");
        puts(" R : Read sectors");
        puts(" C : Checksums");

        key = cgetc();
        if (key == 'w')
            test_write_sector();
        if (key == 'r')
            test_read_sector();
        if (key == 'c')
            test_checksums();
        else if (key == 'f')
            test_format();

    } while (key != CH_STOP);

    return 0;
}
