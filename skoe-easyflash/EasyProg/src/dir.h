
#ifndef DIR_H
#define DIR_H

#include <cbm.h>

typedef struct DirEntry_s {
    char          name[17];     /* File name in PETSCII, limited to 16 chars */
    char          type[4];
    unsigned int  size;         /* Size in 254 byte blocks */
} DirEntry;

unsigned char __fastcall__ dirOpen(uint8_t lfn, uint8_t device);
unsigned char __fastcall__ dirReadEntry (DirEntry* pEntry);
void __fastcall__ dirClose(uint8_t lfn);

#endif
