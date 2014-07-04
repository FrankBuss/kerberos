/*
 * EasyProg - progress.h - The progress display area
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


#ifndef PROGRESS_H_
#define PROGRESS_H_

#include "flash.h"

#define PROGRESS_UNTOUCHED  0x2e // '.'
#define PROGRESS_ERASING    0x45 // 'E'
#define PROGRESS_READING    0x52 // 'R' /* from file */
#define PROGRESS_WRITING    0x57 // 'W'
#define PROGRESS_VERIFYING  0x56 // 'V'
#define PROGRESS_ERASED     0x2d // '-'
#define PROGRESS_PROGRAMMED 0x50 // 'P'

// That many banks are displayed in one screen line
#define PROGRESS_BANKS_PER_LINE 32

void progressInit(void);
void progressShow(void);
void progressUpdateDisplay(void);

void __fastcall__ progressDisplayBank(uint8_t nBank, uint8_t nChip,
                                      uint8_t state);

void __fastcall__ progressSetBankState(const EasyFlashAddr* pAddr,
                                       uint8_t state);

void __fastcall__ progressSetMultipleBanksState(uint8_t nBank, uint8_t nChip,
                                                uint8_t nBankCount,
                                                uint8_t state);

uint8_t __fastcall__ progressGetStateAt(uint8_t nBank, uint8_t nChip);


#endif /* PROGRESS_H_ */
