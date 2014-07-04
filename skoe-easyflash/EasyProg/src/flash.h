/*
 * flash.h
 *
 *  Created on: 21.05.2009
 *      Author: skoe
 */

#ifndef FLASH_H_
#define FLASH_H_

#include <stdint.h>

#define FLASH_MX29LV640EB_MFR_ID 0xc2
#define FLASH_MX29LV640EB_DEV_ID 0xcb

// This bit is set in 29F040 when algorithm is running
#define FLASH_ALG_RUNNING_BIT   0x08

// This bit is set when an algorithm times out (error)
#define FLASH_ALG_ERROR_BIT     0x20

// Number of banks erased at once
#define FLASH_BANKS_ERASE_AT_ONCE (64 / 8)

// max size of a multi-slot EF
#define FLASH_MAX_SLOTS 16

// Number of banks when using 2 * 512 kByte
#define FLASH_NUM_BANKS     64

// If this bit is set, a 8k sector is to be addressed instead of a 64k sector
// This is only supported by some devices and banks (e.g. EF3 KERNALs)
#define FLASH_8K_SECTOR_BIT   128

/// Mask to isolate the plain bank number
#define FLASH_BANK_MASK     (FLASH_NUM_BANKS - 1)

/// Address of Low ROM Chip
#define ROM0_BASE           ((uint8_t*) 0x8000)

/// Address of High ROM Chip
#define ROM1_BASE           ((uint8_t*) 0xA000)

/// Address of High ROM when being in Ultimax mode
#define ROM1_BASE_ULTIMAX   ((uint8_t*) 0xE000)

/// This structure contains an EasyFlash address 00:0:0000
typedef struct EasyFlashAddr_s
{
    uint8_t     nSlot;
    uint8_t     nBank;
    uint8_t     nChip;
    uint16_t    nOffset;
}
EasyFlashAddr;

uint8_t bankFromOffset(uint32_t offset);
uint8_t chipFromOffset(uint32_t offset);

uint8_t eraseSector(uint8_t nBank, uint8_t nChip);

uint8_t eraseSlot(void);

void __fastcall__ flashPrintVerifyError(EasyFlashAddr* pAddr,
                                        uint8_t nData,
                                        uint8_t nFlashVal);

uint8_t flashWrite(uint8_t nChip, uint16_t nOffset, uint8_t nVal);

uint8_t __fastcall__ flashWriteBlock(const EasyFlashAddr* pAddr);

uint8_t __fastcall__ flashVerifyBlock(const EasyFlashAddr* pAddr);

uint8_t flashWriteBankFromFile(uint8_t nBank, uint8_t nChip,
                                uint16_t nSize);

#endif /* FLASH_H_ */
