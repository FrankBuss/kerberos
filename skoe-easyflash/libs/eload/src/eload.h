/*
 * eload.h
 */

#ifndef ELOAD_H_
#define ELOAD_H_

#include <stdint.h>

/* These error codes are the same as the ones for 1541 job codes */
#define DISK_STATUS_OK               0x01 /* Everything OK */
#define DISK_STATUS_HEADER_NOT_FOUND 0x02 /* Header block not found */
#define DISK_STATUS_SYNC_NOT_FOUND   0x03 /* SYNC not found */
#define DISK_STATUS_DATA_NOT_FOUND   0x04 /* Data block not found */
#define DISK_STATUS_DATA_CHK_ERR     0x05 /* Checksum error in data block */
#define DISK_STATUS_VERIFY_ERR       0x07 /* Verify error */
#define DISK_STATUS_WRITE_PROTECTED  0x08 /* Disk write protected */
#define DISK_STATUS_HEADER_CHK_ERR   0x09 /* Checksum error in header block */
#define DISK_STATUS_ID_MISMATCH      0x0b /* ID mismatch */
#define DISK_STATUS_NO_DISK          0x0f /* Disk not inserted */
/* Additional error codes */
#define DISK_STATUS_ADDITIONAL_ERRORS 0x80 /* Marker */
#define DISK_STATUS_DRV_WRONG        0xfd /* Drive type not supported */
#define DISK_STATUS_DRV_NOT_FOUND    0xfe /* Drive not found */
#define DISK_STATUS_UNKNOWN          0xff

/**
 * Set the device number for the drive to be used, and check the drive type.
 * The drive number and the drive type are stored internally.
 *
 * Return the drive type (see drivetype.s).
 */
int  __fastcall__ eload_set_drive_check_fastload(uint8_t dev);

/**
 * Set the device number for the drive to be used and set its type to
 * "unknown". This disables the fast loader.
 * The drive number and the drive type are stored internally.
 */
void __fastcall__ eload_set_drive_disable_fastload(uint8_t dev);


/**
 * Check if the current drive is accelerated. If no acceleration is
 * supported, the other functions will use KERNAL calls automatically.
 * eload_set_drive_* must have been called before.
 */
int eload_drive_is_fast(void);


int __fastcall__ eload_open_read(const char* name);
int eload_read_byte(void);
unsigned int __fastcall__ eload_read(void* buffer, unsigned int size);

/**
 * Receive a block of data.
 */
void __fastcall__ eload_recv_block(uint8_t* addr, uint8_t size);

/**
 * Receive the status bytes for the previous asynchronous job, e.g. for
 * eload_write_sector. status must point to 4 bytes of memory.
 */
void __fastcall__ eload_recv_status(uint8_t* status);

/**
 * Close the current file and cancel the drive code, if any.
 */
void eload_close(void);


/**
 * Prepare the drive to be used. This function uploads the drive code
 * if needed. It does nothing if the current drive doesn't support
 * acceleration or if it doesn't need drive code.
 * eload_set_drive_* must have been called before.
 */
void eload_prepare_drive(void);

void __fastcall__ eload_write_sector(unsigned ts, uint8_t* block);
void __fastcall__ eload_write_sector_nodma(unsigned ts, uint8_t* block);
void __fastcall__ eload_format(uint8_t n_tracks, uint16_t id);
void __fastcall__ eload_checksum(uint8_t n_track);

#endif /* ELOAD_H_ */
