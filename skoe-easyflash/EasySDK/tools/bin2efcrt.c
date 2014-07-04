/*
 * EasyProg - bin2efcrt.c - Convert binary to EasyFlash CRT
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

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

// Cartridge type of EasyFlash
#define CARTRIDGE_EASYFLASH          32

// max supported cartridge size (2 * 512 KiB)
#define EF_MAX_CART_SIZE (2 * 512 * 1024)

// Reference: http://ist.uwaterloo.ca/~schepers/formats/CRT.TXT
typedef struct CartHeader_s
{
    // Cartridge signature "C64 CARTRIDGE" (padded with space chars)
    char signature[16];

    // File header length  ($00000040,  high/low)
    uint8_t headerLen[4];

    // Cartridge version (high/low, presently 0x0100)
    uint8_t version[2];

    // Cartridge hardware type (2 bytes, high/low)
    uint8_t type[2];

    // Cartridge port EXROM line status (1 = high)
    uint8_t exromLine;

    // Cartridge port GAME line status (1 = high)
    uint8_t gameLine;

    // Reserved for future use (6 bytes)
    uint8_t reserved[6];

    // 32-byte cartridge name (uppercase,  padded with 0)
    char name[32];
} CartHeader;

typedef struct BankHeader_s
{
    // Contained ROM signature "CHIP"
    char signature[4];

    // Total packet length, ROM image size + header (4 bytes, high/low format)
    uint8_t packetLen[4];

    // Chip type: 0 ROM, 1 RAM, 2 Flash, (2 bytes, high/low format)
    uint8_t chipType[2];

    // Bank number (2 bytes, high/low format)
    uint8_t bank[2];

    // Load address (2 bytes, high/low format)
    uint8_t loadAddr[2];

    // ROM image size (2 bytes, high/low format, typically $2000 or $4000)
    uint8_t romLen[2];
} BankHeader;

/******************************************************************************/
/**
 * Print help text and exit(1).
 */
static void usage(const char* pStrProgName)
{
    puts("Name:");
    puts("\tbin2efcrt - Convert a binary file to an EasyFlash CRT file.");
    puts("Synopsis:");
    printf("\t%s <INFILE> <OUTFILE>\n", pStrProgName);
    puts("Binary file layout:");
    puts("\tLOROM and HIROM banks alternating, starting at bank 0");
    puts("\t\t                 | L | H ");
    puts("\t\t              ---|---|---");
    puts("\t\t               0 | A | B ");
    puts("\t\t ABCDEF... =>  1 | C | D ");
    puts("\t\t               2 | E | F ");
    puts("\t\t                  ...\n");

    exit(1);
}

/******************************************************************************/
/**
 * Read the input file. Print an error message and exit if there are errors.
 *
 * pBuffer must point to memory of size: (EF_MAX_CART_SIZE + 1)
 * We allocate one byte more to find out if a file is too large in a simple and
 * portable way.
 *
 * Return the number of bytes read.
 */
static size_t readInputFile(uint8_t* pBuffer, const char* pStrFileName)
{
    FILE* pFile;
    size_t size;

    pFile = fopen(pStrFileName, "rb");
    if (pFile == NULL)
    {
        fprintf(stderr, "Cannot open \"%s\" for reading\n", pStrFileName);
        exit(10);
    }

    size = fread(pBuffer, 1, EF_MAX_CART_SIZE + 1, pFile);
    fclose(pFile);
    if (size == 0)
    {
        fprintf(stderr, "Error reading \"%s\"\n", pStrFileName);
        exit(11);
    }

    if (size > EF_MAX_CART_SIZE)
    {
        fprintf(stderr, "File \"%s\" too large\n", pStrFileName);
        exit(12);
    }

    return size;
}

/******************************************************************************/
/**
 * Write an EasyFlash CRT header with the given information.
 * If there's an error, print a message and exit.
 */
static void writeCartHeader(FILE* pFile)
{
    CartHeader header = {};

    // Cartridge signature "C64 CARTRIDGE" (padded with space chars)
    memcpy(header.signature, "C64 CARTRIDGE   ", 16);

    // File header length  ($00000040,  high/low)
    header.headerLen[3] = sizeof(header);

    // Cartridge version (high/low, presently 0x0100)
    header.version[0] = 1;

    // Cartridge hardware type (2 bytes, high/low)
    header.type[1] = CARTRIDGE_EASYFLASH;

    // Cartridge port EXROM line status (1 = high)
    header.exromLine = 1;

    // Cartridge port GAME line status (1 = high)
    header.gameLine = 0;

    // 32-byte cartridge name (uppercase,  padded with 0)
    strcpy(header.name, "EASYFLASH");

    if (fwrite(&header, sizeof(header), 1, pFile) != 1)
    {
        fprintf(stderr, "Error writing CRT header\n");
        exit(30);
    }
}

/******************************************************************************/
/**
 * Write a CRT CHIP header with the given information.
 * If there's an error, print a message and exit.
 *
 */
static void writeChipHeader(FILE* pFile, unsigned nBank, unsigned nAddr,
                            unsigned size)
{
    BankHeader header = {};

    // Contained ROM signature "CHIP"
    memcpy(header.signature, "CHIP", 4);

    // Total packet length, ROM image size + header (4 bytes, high/low format)
    header.packetLen[2] = (size + sizeof(header)) / 256;
    header.packetLen[3] = (size + sizeof(header)) % 256;

    // Chip type: 0 - ROM, 1 - RAM, no ROM data, 2 - Flash ROM
    header.chipType[1] = 2;

    // Bank number (2 bytes, high/low format)
    header.bank[0] = nBank / 256;
    header.bank[1] = nBank % 256;

    // Load address (2 bytes, high/low format)
    header.loadAddr[0] = nAddr / 256;
    header.loadAddr[1] = nAddr % 256;

    // ROM image size (2 bytes, high/low format, typically $2000 or $4000)
    header.romLen[0] = size / 256;
    header.romLen[1] = size % 256;

    if (fwrite(&header, sizeof(header), 1, pFile) != 1)
    {
        fprintf(stderr, "Error writing CRT CHIP header\n");
        exit(31);
    }
}

/******************************************************************************/
/**
 * Write the given buffer to a CRT image file. The buffer contains a linear
 * layout.
 */
static void writeCRTLinearLayout(const char* pStrFileName,
                                 const uint8_t* pBuffer, size_t size)
{
    FILE* pFile;
    size_t nRemaining;
    size_t sizeBank;
    int nBank;
    int nChip;

    pFile = fopen(pStrFileName, "wb");
    if (pFile == NULL)
    {
        fprintf(stderr, "Cannot open \"%s\" for writing\n", pStrFileName);
        exit(20);
    }

    writeCartHeader(pFile);

    nBank = 0;
    nChip = 0;
    nRemaining = size;
    while (nRemaining)
    {
        if (nRemaining > 0x2000)
            sizeBank = 0x2000;
        else
            sizeBank = nRemaining;

        writeChipHeader(pFile, nBank, nChip ? 0xA000 : 0x8000, sizeBank);

        if (fwrite(pBuffer, 1, sizeBank, pFile) != sizeBank)
        {
            fprintf(stderr, "Error writing data\n");
            exit(21);
        }

        if (nChip)
        {
            nChip = 0;
            ++nBank;
        }
        else
        {
            ++nChip;
        }

        pBuffer += sizeBank;
        nRemaining -= sizeBank;
    }
    fclose(pFile);
}

/******************************************************************************/
/**
 * Do it.
 */
int main(int argc, char** argv)
{
    size_t size;
    uint8_t* pBuffer;

    if (argc != 3)
        usage(argv[0]);

    pBuffer = malloc(EF_MAX_CART_SIZE + 1);
    if (pBuffer == NULL)
    {
        fprintf(stderr, "Out of memory\n");
        return 2;
    }
    size = readInputFile(pBuffer, argv[1]);

    writeCRTLinearLayout(argv[2], pBuffer, size);

    return 0;
}
