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
#include <string.h>
#include <stdlib.h>
#include <stdint.h>

#include <ftdi.h>

#include "ef3xfer.h"
#include "ef3xfer_internal.h"

#define D64_MAX_TRACKS  40 /* 1..40 */
#define D64_MAX_SECTORS 21 /* 0..20 */

#define D64_SIZE_35_TRACKS 174848
#define D64_SIZE_40_TRACKS 196608

#define D64_BUFFER_SIZE (D64_SIZE_40_TRACKS + 1)

#define GCR_BPS 325

#define USB_STATUS_MAGIC             0x52

/* These error codes are the same as the ones for 1541 job codes */
#define DISK_STATUS_OK               0x01 /* Everything OK */
#define DISK_STATUS_HEADER_NOT_FOUND 0x02 /* Header block not found */
#define DISK_STATUS_SYNC_NOT_FOUND   0x03 /* SYNC not found */
#define DISK_STATUS_DATA_NOT_FOUND   0x04 /* Data block not found */
#define DISK_STATUS_DATA_CHK_ERR     0x05 /* Checksum error in data block */
#define DISK_STATUS_VERIFY_ERR       0x07 /* Verify error */
#define DISK_STATUS_WRITE_PROTECTED  0x08 /* Disk write protected */
#define DISK_STATUS_HEADER_CHK_ERR   0x09 /* Checksum error in header block */
#define DISK_STATUS_ID_MISMATCH      0x0b /* Id mismatch */
#define DISK_STATUS_NO_DISK          0x0f /* Disk not inserted */
/* Additional error codes */
#define DISK_STATUS_ADDITIONAL_ERRORS 0x80 /* Marker */
#define DISK_STATUS_DRV_WRONG        0xfd /* Drive type not supported */
#define DISK_STATUS_DRV_NOT_FOUND    0xfe /* Drive not found */
#define DISK_STATUS_UNKNOWN          0xff


extern const unsigned char d64writer[];
extern int d64writer_size;


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
    union
    {
        transfer_disk_ts_t  ts;
        uint16_t            data16;
    } data;
} transfer_disk_status_t;

static const uint8_t a_sectors_per_track[D64_MAX_TRACKS] =
{
        21, 21, 21, 21, 21,   21, 21, 21, 21, 21,     /*  1 .. 10 */
        21, 21, 21, 21, 21,   21, 21, 19, 19, 19,     /* 11 .. 20 */
        19, 19, 19, 19, 18,   18, 18, 18, 18, 18,     /* 21 .. 30 */
        17, 17, 17, 17, 17,   17, 17, 17, 17, 17      /* 31 .. 40 */
};

static const uint16_t a_track_offset_in_d64[D64_MAX_TRACKS] =
{
          0,  21,  42,  63,  84,    105, 126, 147, 168, 189, /*  1 .. 10 */
        210, 231, 252, 273, 294,    315, 336, 357, 376, 395, /* 11 .. 20 */
        414, 433, 452, 471, 490,    508, 526, 544, 562, 580, /* 21 .. 30 */
        598, 615, 632, 649, 666,    683, 700, 717, 734, 751  /* 31 .. 40 */
};

/* Conversion BIN => GCR */
static const uint8_t bin_to_gcr[16] =
{
    0x0a, 0x0b, 0x12, 0x13,
    0x0e, 0x0f, 0x16, 0x17,
    0x09, 0x19, 0x1a, 0x1b,
    0x0d, 0x1d, 0x1e, 0x15
};

/* Conversion GCR => BIN (0xff = invalid code) */
static const uint8_t gcr_to_bin[32] =
{
    0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff,
    0xff, 0x08, 0x00, 0x01,
    0xff, 0x0c, 0x04, 0x05,
    0xff, 0xff, 0x02, 0x03,
    0xff, 0x0f, 0x06, 0x07,
    0xff, 0x09, 0x0a, 0x0b,
    0xff, 0x0d, 0x0e, 0xff
};

/*****************************************************************************/
/**
 * Convert 4 bytes of binary data from src to 5 bytes of GCR data to dst.
 */
static void drive_gcr_encode(uint8_t* dst, const uint8_t* src)
{
    uint32_t o, i;

    // aaaa bbbb => oo ooop pppp
    i  = src[0];
    o  = bin_to_gcr[i >> 4] << 5;
    o |= bin_to_gcr[i & 0xf];
    dst[0] = o >> 2;
    o <<= 10;
    // cccc dddd => ppqq qqqr rrrr
    i  = src[1];
    o |= bin_to_gcr[i >> 4] << 5;
    o |= bin_to_gcr[i & 0xf];
    dst[1] = o >> 4;
    o <<= 10;
    // eeee ffff => rr rrss ssst tttt
    i  = src[2];
    o |= bin_to_gcr[i >> 4] << 5;
    o |= bin_to_gcr[i & 0xf];
    dst[2] = o >> 6;
    o <<= 10;
    // gggg hhhh => sttt ttuu uuuv vvvv
    i  = src[3];
    o |= bin_to_gcr[i >> 4] << 5;
    o |= bin_to_gcr[i & 0xf];
    dst[3] = o >> 8;
    dst[4] = o;
}


/*****************************************************************************/
/**
 * Convert 5 bytes of GCR data from src to 4 bytes binary to dst.
 */
static void drive_gcr_decode(uint8_t* dst, const uint8_t* src)
{
    uint32_t o, i;

    // oooo oppp => aaaa ....
    i  = src[0];
    o  = gcr_to_bin[i >> 3] << 4;
    // ppp ppqq qqqr => .... bbbb
    i  = (i & 0x07) << 8 | src[1];
    o |= gcr_to_bin[i >> 6];
    dst[0] = o;
    // qq qqqr => cccc ....
    o  = gcr_to_bin[(i >> 1) & 0x1f] << 4;
    // r rrrr ssss => .... dddd
    i  = (i & 0x01) << 8 | src[2];
    o |= gcr_to_bin[(i >> 4)];
    dst[1] = o;
    // ssss sttt ttuu => eeee ffff
    i  = (i & 0x0f) << 8 | src[3];
    o  = gcr_to_bin[i >> 7] << 4;
    o |= gcr_to_bin[(i >> 2) & 0x1f];
    dst[2] = o;
    // uu uuuv vvvv => gggg hhhh
    i  = (i & 0x03) << 8 | src[4];
    o  = gcr_to_bin[i >> 5] << 4;
    o |= gcr_to_bin[i & 0x1f];
    dst[3] = o;
}


/*****************************************************************************/
/**
 * Report the progress in percent.
 *
 * phase        0 = 0%
 *              1 = format (track information ignored) ~ 10 seconds
 *              2 = write (plus track info) ~ 30 seconds
 *              3 = verify (plus track info) ~ 10 seconds
 * n_tracks     total number of tracks 35+
 * n_track      current track 1..35+
 */
static void progress(int phase, int n_tracks, int n_track)
{
    int percent;

    --n_tracks;
    --n_track;

    switch (phase)
    {
    case 0:
        percent = 0;
        break;

    case 1: /* format = 20% */
        percent = 5; /* mhh */
        break;

    case 2: /* write = 60% */
        percent = (int)(20.0 + (double)n_track * 60.0 / (double)(n_tracks));
        break;

    default: /* verify = 20% */
        percent = (int)(80.0 + (double)n_track * 20.0 / (double)(n_tracks));
        break;
    }
    ef3xfer_log_progress(percent, 1);
}


/*****************************************************************************/
/**
 * Calculate and return an EOR checksum of the given data.
 *
 */
static unsigned drive_checksum(const uint8_t* p_data, unsigned len)
{
    unsigned i, sum;
    sum = 0;
    for (i = 0; i < len; ++i)
    {
        sum ^= p_data[i];
    }
    return sum;
}


/*****************************************************************************/
/**
 * Convert a binary sector of 256 bytes to a GCR encoded sector.
 *
 * dst          Target for encoded sector data
 * src          binary sector data, 256 bytes
 * track        track number, 0-based
 * sector       sector
 */
static void encode_sector_to_gcr(uint8_t* p_dst,
                                 const uint8_t* p_src)
{
    unsigned n_in, n_out;
    uint8_t bin[8];

    n_in = 0;
    n_out = 0;
#if 0
    // create header sync
    memset(p_dst, 0xff, SECTOR_LEN_HEADER_SYNC);
    p_dst += SECTOR_LEN_HEADER_SYNC;

    // create header
    bin[0] = 0x08; // header
    bin[2] = n_sector;
    bin[3] = n_track + 1;
    bin[4] = 0x58; // id 2
    bin[5] = 0x5a; // id 1
    bin[6] = 0x0f; // off byte
    bin[7] = 0x0f; // off byte
    bin[1] = drive_checksum(bin + 2, 4);
    drive_gcr_encode(p_dst, bin);
    p_dst += 5;
    drive_gcr_encode(p_dst, bin + 4);
    p_dst += 5;

    // create header gap
    memset(p_dst, 0x55, SECTOR_LEN_HEADER_GAP);
    p_dst += SECTOR_LEN_HEADER_GAP;

    // create data sync
    memset(p_dst, 0xff, SECTOR_LEN_DATA_SYNC);
    p_dst += SECTOR_LEN_DATA_SYNC;
#endif

    // first 3 bytes of src data come to this GCR block
    bin[0] = 0x07;    // data block ID
    bin[1] = p_src[n_in++];
    bin[2] = p_src[n_in++];
    bin[3] = p_src[n_in++];
    drive_gcr_encode(p_dst + n_out, bin);
    n_out += 5;

    // 253 bytes left, convert next 63 * 4 = 252 bytes => up to byte 0xff
    while (n_in < 0xff)
    {
        drive_gcr_encode(p_dst + n_out, p_src + n_in);
        n_in += 4;
        n_out += 5;
    }

    // last data byte goes to this GCR-block
    bin[0] = p_src[n_in];
    bin[1] = drive_checksum(p_src, 256);
    bin[2] = 0;
    bin[3] = 0;
    drive_gcr_encode(p_dst + n_out, bin);
    n_out += 5;

#if 0
    // create tail gap
    memset(p_dst, 0xff, SECTOR_LEN_TAIL_GAP);
    p_dst += SECTOR_LEN_TAIL_GAP;
#endif
}


static const char* err_to_str(int i)
{
    switch (i)
    {
    case DISK_STATUS_OK:
        return "OK";
    case DISK_STATUS_HEADER_NOT_FOUND:
        return "Header block not found";
    case DISK_STATUS_SYNC_NOT_FOUND:
        return "SYNC not found";
    case DISK_STATUS_DATA_NOT_FOUND:
        return "Data block not found";
    case DISK_STATUS_DATA_CHK_ERR:
        return "Checksum error in data block";
    case DISK_STATUS_VERIFY_ERR:
        return "Verify error";
    case DISK_STATUS_WRITE_PROTECTED:
        return "Disk write protected";
    case DISK_STATUS_HEADER_CHK_ERR:
        return "Checksum error in header block";
    case DISK_STATUS_ID_MISMATCH:
        return "ID mismatch";
    case DISK_STATUS_NO_DISK:
        return "Disk not inserted";
    case DISK_STATUS_DRV_WRONG:
        return "Drive type not supported";
    case DISK_STATUS_DRV_NOT_FOUND:
        return "Drive not found";
    default:
        return "Unknown error";
    }
}


/*****************************************************************************/
/**
 *
 */
static int get_num_tracks(long file_size)
{
    if (file_size == D64_SIZE_35_TRACKS)
        return 35;
    else if (file_size == D64_SIZE_40_TRACKS)
        return 40;

    ef3xfer_log_printf(
            "*** Error: Only d64 files with 35 or 40 tracks w/o error info "
            "are supported currently (but I got %d bytes).\n", file_size);
    return 0;
}

/*****************************************************************************/
/**
 *
 */
static int check_c64_response(transfer_disk_status_t* p_st)
{

    /* read the status from C-64 */
    if (!ef3xfer_read_from_ftdi(p_st, sizeof(*p_st)))
    {
        return 0;
    }

    if (p_st->magic == 0)
    {
        ef3xfer_log_printf("\nClose request received.\n");
        return 0;
    }

    if (p_st->magic != USB_STATUS_MAGIC)
    {
        ef3xfer_log_printf("\nInvalid data from C-64.\n");
        return 0;
    }

    if (p_st->status != DISK_STATUS_OK)
    {
        if (p_st->status < DISK_STATUS_ADDITIONAL_ERRORS)
        {
            ef3xfer_log_printf("\n*** %s at %d:%d\n",
                               err_to_str(p_st->status),
                               p_st->data.ts.track,
                               p_st->data.ts.sector);
        }
        else
        {
            ef3xfer_log_printf("\n*** %s\n",
                               err_to_str(p_st->status));
        }
        return 0;
    }

    return 1;
}

/*****************************************************************************/
/**
 *
 */
static int send_d64(uint8_t* p_buffer,
                    int n_num_tracks)
{
    transfer_disk_status_t st;
    transfer_disk_ts_t ts;
    uint8_t gcr[GCR_BPS];
    uint8_t a_sector_state[D64_MAX_SECTORS];
    long    offset;
    int     n_sectors_left, n_sectors, n_interleave, i;
    int     b_first_sector;

    ef3xfer_log_printf("Writing...    ");
    n_interleave = 4;
    b_first_sector = 1;
    for (ts.track = 1; ts.track <= n_num_tracks; ++ts.track)
    {
        ef3xfer_log_printf("%d", ts.track % 10);
        progress(2, n_num_tracks, ts.track);

        n_sectors_left = a_sectors_per_track[ts.track - 1];
        n_sectors = n_sectors_left;

        /* Send sectors, one by one */
        memset(a_sector_state, 0, sizeof(a_sector_state));
        ts.sector = 0;
        while (n_sectors_left)
        {
            /* Search next untransferred sector */
            ts.sector = (ts.sector + n_interleave) % n_sectors;
            while (a_sector_state[ts.sector])
                ts.sector = (ts.sector + 1) % n_sectors;

            offset = (a_track_offset_in_d64[ts.track - 1] + ts.sector) * 256;

            encode_sector_to_gcr(gcr, p_buffer + offset);

            /* Send track and sector numbers */
            if (!ef3xfer_write_to_ftdi(&ts, sizeof(ts)))
                return 0;

            if (!ef3xfer_write_to_ftdi(gcr, GCR_BPS))
                return 0;

            /* no response after the 1st sector has been sent */
            if (!b_first_sector)
                if (!check_c64_response(&st))
                    return 0;
            b_first_sector = 0;

            a_sector_state[ts.sector] = 1;
            --n_sectors_left;
        }
    }
    ef3xfer_log_printf("\n");

    /* track == 0 => end mark */
    ts.track = 0;
    if (!ef3xfer_write_to_ftdi(&ts, sizeof(ts)))
        return 0;

    /* this is the response for the last sector written */
    return check_c64_response(&st);
}


/*****************************************************************************/
/**
 * checksums has 12 bytes for each sector: 10 bytes GCR header and 2 bytes
 * Fletcher16 checksum over the data block GCR data.
 * This function converts the 10 bytes GCR header data to 8 bytes binary
 * header data in-place.
 *
 */
static void decode_headers_in_checksums(uint8_t checksums[D64_MAX_SECTORS][12])
{
    int n_sector;

    for (n_sector = 0; n_sector < D64_MAX_SECTORS; n_sector++)
    {
        drive_gcr_decode(checksums[n_sector], checksums[n_sector]);
        drive_gcr_decode(checksums[n_sector] + 4, checksums[n_sector] + 5);
    }
}

/*****************************************************************************/
/**
 *
 */
static int check_headers(uint8_t checksums[D64_MAX_SECTORS][12],
                          int n_track, const uint8_t disk_id[2])
{
    int n_sec, i;
    uint8_t eor;
    int n_sectors = a_sectors_per_track[n_track - 1];
    uint8_t* p_header;

    for (n_sec = 0; n_sec < n_sectors; ++n_sec)
    {
        for (i = 0; i < n_sectors; ++i)
        {
            if (checksums[i][2] == n_sec)
            {
                p_header = checksums[i];
                /*ef3xfer_log_printf("%02x %02x %02x %02x  %02x %02x %02x %02x",
                        checksums[i][0], checksums[i][1], checksums[i][2], checksums[i][3],
                        checksums[i][4], checksums[i][5], checksums[i][6], checksums[i][7]);
                ef3xfer_log_printf("\n");*/
                eor = p_header[2] ^ p_header[3] ^ p_header[4] ^ p_header[5];
                if (p_header[0] != 0x08 || /* header ID */
                    p_header[1] != eor ||  /* header checksum */
                    p_header[3] != n_track ||
                    p_header[4] != disk_id[1] ||
                    p_header[5] != disk_id[0])
                {
                    ef3xfer_log_printf("*** Error: Header %d:%d bad\n",
                            n_track, n_sec);
                    return 0;
                }

                break;
            }
        }
        if (i == n_sectors)
        {
            ef3xfer_log_printf("*** Error: Header %d:%d not found\n",
                    n_track, n_sec);
            return 0;
        }
    }
    return 1;
}

/*****************************************************************************/
/**
 *
 */
static int check_checksums(uint8_t* p_buffer,
                           uint8_t checksums[D64_MAX_SECTORS][12],
                           int n_track, const uint8_t disk_id[2])
{
    uint8_t gcr[GCR_BPS];
    long    offset;
    int     n_sec, i, k;
    unsigned lo, hi, carry;
    int     n_sectors = a_sectors_per_track[n_track - 1];
    uint8_t* p_header;

    for (i = 0; i < n_sectors; ++i)
    {
        n_sec = checksums[i][2];

        offset = (a_track_offset_in_d64[n_track - 1] + n_sec) * 256;
        encode_sector_to_gcr(gcr, p_buffer + offset);

        lo = hi = carry = 0;
        for (k = 0; k < GCR_BPS; ++k)
        {
            lo ^= gcr[k];

            /* quite verbose, heh? */
            hi = (hi + 1) & 0xff;
            hi = (hi << 1) | carry;
            carry = hi >> 8;
            hi &= 0xff;

            lo = (lo << 1) | carry;
            carry = lo >> 8;
            lo &= 0xff;
        }

        if (checksums[i][10] != lo && checksums[i][11] != hi)
        {
            ef3xfer_log_printf("\n*** Error: Verification failed at %d:%d\n",
                n_track, n_sec);
            return 0;
        }
    }
    return 1;
}


/*****************************************************************************/
/**
 *
 */
static void dump_checksums(int n_track, uint8_t checksums[D64_MAX_SECTORS][12])
{
#ifdef DUMP_CHECKSUMS
    int s, i, n_sectors;
    uint8_t* p;

    n_sectors = a_sectors_per_track[n_track - 1];
    ef3xfer_log_printf("\nTrack %d:\n", n_track);
    for (s = 0; s < n_sectors; ++s)
    {
        p = checksums[s];
        ef3xfer_log_printf("%02d: i%02x e%02x s%02x t%02x %02x %02x  %02x %02x %02x %02x   %02x %02x\n",
                s,
                p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8], p[9],
                p[10], p[11]);
    }
#endif
}


/*****************************************************************************/
/**
 *
 */
static int verify_d64(uint8_t* p_buffer,
                      int n_num_tracks, const uint8_t disk_id[2])
{
    transfer_disk_status_t st;
    transfer_disk_ts_t ts;
    uint8_t s;
    uint8_t checksums[D64_MAX_SECTORS][12];

    ef3xfer_log_printf("Verifying...  ");
    for (ts.track = 1; ts.track <= n_num_tracks; ++ts.track)
    {
        ef3xfer_log_printf("%d", ts.track % 10);
        progress(3, n_num_tracks, ts.track);

        if (check_c64_response(&st))
        {
            ef3xfer_read_from_ftdi(checksums, 256);
            decode_headers_in_checksums(checksums);
            dump_checksums(ts.track, checksums);
            if (!check_headers(checksums, ts.track, disk_id) ||
                !check_checksums(p_buffer, checksums, ts.track, disk_id))
            {
                s = 0;
                ef3xfer_write_to_ftdi(&s, 1);
                return 0;
            }
            s = 1;
            ef3xfer_write_to_ftdi(&s, 1);
        }
    }
    ef3xfer_log_printf("\n");

    return 1;
}


/*****************************************************************************/
/**
 *
 */
int ef3xfer_d64_write(const char* p_filename, int drv, int do_format)
{
    transfer_disk_status_t st;
    uint8_t     options[4];
    uint8_t     disk_id[2];
    uint8_t*    p_buffer = NULL;
    int         n_tracks;
    long        file_size;
    int         ret = 0; // <= error
    FILE*       fp = NULL;

    progress(0, 0, 0);

    fp = fopen(p_filename, "rb");
    if (fp == NULL)
    {
        ef3xfer_log_printf("*** Error: Cannot open %s for reading\n",
                p_filename);
        goto cleanup_and_ret;
    }

    /* this may fail if the d64 writer runs already */
    ef3xfer_transfer_prg_mem(d64writer, d64writer_size);

    p_buffer = malloc(D64_BUFFER_SIZE);
    if (!p_buffer || !ef3xfer_do_handshake("D64"))
        goto cleanup_and_ret;

    file_size = fread(p_buffer, 1, D64_BUFFER_SIZE, fp);

    n_tracks = get_num_tracks(file_size);
    if (!n_tracks)
        goto cleanup_and_ret;
    ef3xfer_log_printf("Tracks: %d\n", n_tracks);

    /* take disk ID from 18/0 */
    disk_id[0] = p_buffer[a_track_offset_in_d64[17] * 256 + 0xa2];
    disk_id[1] = p_buffer[a_track_offset_in_d64[17] * 256 + 0xa3];

    /* options for D64 write = drive number, do_format, n_tracks, 0 */
    memset(options, 0, sizeof(options));
    options[0] = drv;
    options[1] = do_format ? n_tracks : 0;
    options[2] = disk_id[0];
    options[3] = disk_id[1];
    if (!ef3xfer_write_to_ftdi(options, sizeof(options)))
        goto cleanup_and_ret;

    if (do_format)
    {
        ef3xfer_log_printf("Formatting... ");
        progress(1, 0, 0);

        if (!check_c64_response(&st))
            goto cleanup_and_ret;

        ef3xfer_log_printf("OK, %d raw bytes on zone 1 (%.1f rpm), ID %02x %02x\n",
                st.data.data16,
                (double)st.data.data16 / 7692.0 * 300.0,
                disk_id[0], disk_id[1]);
    }

    ret = send_d64(p_buffer, n_tracks);
    if (ret)
        ret = verify_d64(p_buffer, n_tracks, disk_id);

    if (ret)
        ef3xfer_log_printf("OK\n");

cleanup_and_ret:
    if (fp)
        fclose(fp);
    if (p_buffer)
        free(p_buffer);
    ef3xfer_disconnect_ftdi();

    return ret;
}
