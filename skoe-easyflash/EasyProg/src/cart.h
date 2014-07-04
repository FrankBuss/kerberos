
#ifndef CART_H
#define CART_H

#include <stdint.h>

#define CART_RV_ERR  0
#define CART_RV_OK   1
#define CART_RV_EOF  2

// Reference: http://ist.uwaterloo.ca/~schepers/formats/CRT.TXT
typedef struct CartHeader_s
{
    // Cartridge signature "C64 CARTRIDGE" (padded with space chars)
    char signature[16];

    // File header length  ($00000040,  high/low)
    uint8_t headerLen[4];

    // Cartridge version (high/low, presently 01.00)
    uint8_t version[2];

    // Cartridge hardware type ($0000, high/low)
    uint8_t type[2];

    // Cartridge port EXROM line status (1 = active)
    uint8_t exromLine;

    // Cartridge port GAME line status (1 = active)
    uint8_t gameLine;

    // Reserved for future use (6 bytes)
    uint8_t reserved[6];

    // 32-byte cartridge name (uppercase,  padded with 0)
    char name[32];
}
CartHeader;


typedef struct BankHeader_s
{
    // Contained ROM signature "CHIP"
    char signature[4];

    // Total packet length, ROM image size + header (high/low format)
    uint8_t packetLen[4];

    // Chip type: 0 - ROM, 1 - RAM, no ROM data, 2 - Flash ROM
    uint8_t chipType[2];

    // Bank number ($0000 - normal cartridge) (?)
    uint8_t bank[2];

    // Starting load address (high/low format) (?)
    uint8_t loadAddr[2];

    // ROM image size (high/low format, typically $2000 or $4000)
    uint8_t romLen[2];
}
BankHeader;


typedef struct CartChip_s
{
    BankHeader header;

    // For a linked list of several chips
    struct CartChip_s* pNext;

    // Points to the chip data, size is contained in header
    uint8_t* pData;
}
CartChip;

// "C64 CARTRIDGE   "
#define CART_SIGNATURE { 0x43, 0x36, 0x34, 0x20, 0x43, 0x41, 0x52, 0x54, 0x52, 0x49, 0x44, 0x47, 0x45, 0x20, 0x20, 0x20 }
#define CHIP_SIGNATURE { 0x43, 0x48, 0x49, 0x50 }

// These are the cartridge types from the file header
#define CART_TYPE_NORMAL           0
#define CART_TYPE_OCEAN1           5
#define CART_TYPE_EASYFLASH       32
#define CART_TYPE_EASYFLASH_XBANK 33
#define CART_TYPE_EASYFLASH_TMP   42 // <= remove me!

// These are detailed cartridge types, only used in this software
// Keep in sync with aStrInternalCartTypeName!
#define INTERNAL_CART_TYPE_NONE            0
#define INTERNAL_CART_TYPE_UNKNOWN         1
#define INTERNAL_CART_TYPE_NORMAL_8K       2
#define INTERNAL_CART_TYPE_NORMAL_16K      3
#define INTERNAL_CART_TYPE_ULTIMAX         4
#define INTERNAL_CART_TYPE_OCEAN1          5
#define INTERNAL_CART_TYPE_EASYFLASH       6
#define INTERNAL_CART_TYPE_EASYFLASH_XBANK 7

// global variables to make the code more compact on cc65
extern uint8_t      internalCartType;
extern CartHeader   cartHeader;
extern uint8_t      nChips;
extern uint32_t     nCartBytes;
extern uint8_t      nXbankConfig;
extern const char*  aStrInternalCartTypeName[];
extern const char   strCartSignature[16];
extern const char   strChipSignature[4];

uint8_t readCartHeader();
void printCartInfo(void);
uint8_t __fastcall__ readNextBankHeader(BankHeader* pBankHeader);

#endif // CART_H
