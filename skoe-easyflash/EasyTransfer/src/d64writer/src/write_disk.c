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
#include <conio.h>
#include <stdint.h>
#include <string.h>
#include <c64.h>

#include <ef3usb.h>
#include <eload.h>

#include "d64writer.h"

#define D64_MAX_SECTORS 21 /* 0..20 */
#define GCR_BPS 325

#define USB_STATUS_MAGIC            0x52

/* buffers used in this module */
static uint8_t options[4];
static uint8_t status[3];
static uint8_t a_data_buffer[GCR_BPS];

typedef struct transfer_disk_ts_s
{
    uint8_t track;
    uint8_t sector;
}
transfer_disk_ts_t;

typedef struct transfer_disk_status_s
{
    uint8_t             magic;
    uint8_t             status;
    transfer_disk_ts_t  ts;
} transfer_disk_status_t;


/******************************************************************************/
/**
 *
 */
static void __fastcall__ send_status(uint8_t status,
                                     uint8_t n_track,
                                     uint8_t n_sector)
{
    static transfer_disk_status_t st;

    if (status != DISK_STATUS_OK)
        printf("Error %d at %d:%d\n", status, n_track, n_sector);

    st.magic = USB_STATUS_MAGIC;
    st.status = status;
    st.ts.track = n_track;
    st.ts.sector = n_sector;

    ef3usb_send_data(&st, sizeof(st));
}

/******************************************************************************/
/**
 *
 */
static uint8_t init_eload(uint8_t drv)
{
    unsigned type;

    type = eload_set_drive_check_fastload(drv);
    if (!type)
    {
        send_status(DISK_STATUS_DRV_NOT_FOUND, 0, 0);
        printf("Device %d not present\n", drv);
    }
    else if (type != 2)
    {
        send_status(DISK_STATUS_DRV_WRONG, 0, 0);
        printf("Wrong drive type for d64 writer (%d)\n", type);
        type = 0;
    }
    return type;
}


/******************************************************************************/
/**
 * status returned in status[0]
 *
 */
static void format(uint8_t n_tracks, uint8_t id1, uint8_t id2)
{
    printf("Formatting...");
    gotox(20);
    eload_format(n_tracks, (id1 | id2 << 8));
    eload_recv_block(status, 3);
    if (status[0] == DISK_STATUS_OK)
        puts("OK");

    /* Send status and bytes per track */
    send_status(status[0], status[1], status[2]);
}

/******************************************************************************/
/**
 *
 */
static void write_d64(void)
{
    static transfer_disk_ts_t ts;
    static transfer_disk_ts_t prev_ts;
    uint8_t b_first_sector;

    printf("Writing...");
    gotox(20);

    // disable VIC-II DMA
    VIC.ctrl1 &= 0xef;
    while (VIC.rasterline != 255)
    {}

    /* download current sector while previous sector is being written to disk */
    b_first_sector = 1;
    status[0] = DISK_STATUS_UNKNOWN;
    do
    {
        /* Receive sector */
        ef3usb_receive_data(&ts, sizeof(ts));
        if (ts.track != 0) /* track == 0 => end */
        {
            ef3usb_receive_data(a_data_buffer, GCR_BPS);
        }

        /* Send status for last sector written, if any */
        if (!b_first_sector)
        {
            eload_recv_status(status);
            send_status(status[0], prev_ts.track, prev_ts.sector);
            if (status[0] != DISK_STATUS_OK)
                break;
        }
        b_first_sector = 0;

        /* Write sector, if any */
        if (ts.track)
        {
            eload_write_sector_nodma((ts.track << 8) | ts.sector, a_data_buffer);
        }
        prev_ts = ts;
    }
    while (prev_ts.track);

    // enable VIC-II DMA
    VIC.ctrl1 |= 0x10;
    puts("OK");
}

/******************************************************************************/
/**
 *
 */
static void verify(uint8_t n_tracks)
{
    uint8_t n_track;
    uint8_t result;

    printf("Verifying...");
    gotox(20);

    for (n_track = 1; n_track <= n_tracks; ++n_track)
    {
        eload_checksum(n_track);
        eload_recv_block(status, 3);
        send_status(status[0], status[1], status[2]);

        if (status[0] == DISK_STATUS_OK)
        {
            eload_recv_block(a_data_buffer, 0);
            ef3usb_send_data(a_data_buffer, 256);
            ef3usb_receive_data(&result, 1);
            if (!result)
                goto err;
        }
        else
            goto err;
    }
    puts("OK");
    return;
err:
    printf("Failed\n");
}


/******************************************************************************/
/**
 * Write a d64 image to disk.
 *
 * The main program got the start command over USB already.
 */
void write_disk_d64(void)
{
    puts("\nD64 writer started");
    ef3usb_send_str("load");

    ef3usb_receive_data(options, sizeof(options));
    /*printf("Options: %02x %02x %02x %02x\n",
            options[0], options[1], options[2], options[3]);*/

    if (init_eload(options[0]) == 0)
        return;

    printf("Preparing drive...");
    eload_prepare_drive();
    gotox(20);
    puts("OK");

    if (options[1]) /* Number of tracks to be formatted */
    {
        format(options[1], options[2], options[3]);
        if (status[0] != DISK_STATUS_OK)
            goto end;
    }

    write_d64();
    if (status[0] != DISK_STATUS_OK)
        goto end;

    verify(options[1]); /* number of tracks */

end:
    eload_close();
}
