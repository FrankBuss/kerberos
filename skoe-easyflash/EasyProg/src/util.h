
#ifndef UTIL_H
#define UTIL_H

#include <stdint.h>
#include "flash.h"

#define UTIL_GLOBAL_READ_LFN 2

#define UTIL_STR_SIZE 80

#define UTIL_USE_USB 254

// return values for utilOpenFile
#define OPEN_FILE_OK        0
#define OPEN_FILE_ERR       1
#define OPEN_FILE_WRONG     2
#define OPEN_FILE_UNKNOWN   3
// used internally:
#define OPEN_FILE_TYPE_ESPLIT  8
#define OPEN_FILE_TYPE_CRT     9
#define OPEN_FILE_TYPE_PRG    10

void __fastcall__ utilAppendHex1(uint8_t n);
void __fastcall__ utilAppendHex2(uint8_t n);
void __fastcall__ utilAppendChar(char c);
void __fastcall__ utilAppendStr(const char* str);

void __fastcall__ utilAppendFlashAddr(const EasyFlashAddr* pAddr);
void __fastcall__ utilAppendDecimal(uint16_t n);

void utilOpenFileFromUSB(void);

uint8_t utilOpenFile(uint8_t nPart);
void utilCloseFile(void);

void utilReadSelectNormalFile(void);
unsigned int __fastcall__ utilKernalRead(void* buffer,
                                         unsigned int size);


/* private */ void utilInitDecruncher(void);
/* private */ unsigned int __fastcall__ utilReadEasySplitFile(void* buffer, unsigned int size);


extern unsigned int __fastcall__ (*utilRead)(void* buffer,
                                             unsigned int size);
extern int32_t nUtilExoBytesRemaining;

extern const uint8_t* pFallbackDriverStart;
extern const uint8_t* pFallbackDriverEnd;

extern char utilStr[UTIL_STR_SIZE];

typedef struct EasySplitHeader_s
{
    char    magic[8];   /* PETSCII EASYSPLT (hex 65 61 73 79 73 70 6c 74) */
    uint8_t len[4];     /* uncompressed file size (little endian) */
    uint8_t id[2];      /* 16 bit file ID, must be constant in all parts
                         * which belong to one file. May be a random value,
                         * a checksum or whatever. */
    uint8_t part;       /* Number of this file (0 = 01, 1 = 02...) */
    uint8_t total;      /* Total number of files */
}
EasySplitHeader;

#endif
