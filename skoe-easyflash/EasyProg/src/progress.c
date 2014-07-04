/*
 * EasyProg - progress.c - The progress display area
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
#include <string.h>
#include <conio.h>

#include "flash.h"
#include "slots.h"
#include "screen.h"
#include "progress.h"

/******************************************************************************/
/* Static variables */

// Array with the state of all banks on high and low flash.
char m_aBlockStates[FLASH_MAX_SLOTS][2][FLASH_NUM_BANKS];

/******************************************************************************/
/**
 * Set the state of all blocks to "untouched".
 */
void progressInit(void)
{
    memset(m_aBlockStates, PROGRESS_UNTOUCHED, sizeof(m_aBlockStates));
}

/******************************************************************************/
/**
 * Show the progress display area including box etc.
 */
void progressShow(void)
{
    uint8_t  y = 16;

    textcolor(COLOR_LIGHTFRAME);
    screenPrintBox(5, y++, PROGRESS_BANKS_PER_LINE + 2,
                   2 * FLASH_NUM_BANKS / PROGRESS_BANKS_PER_LINE + 2);
    textcolor(COLOR_FOREGROUND);

    cputsxy(2, y, "Lo:");
    cputsxy(2, y + 2, "Hi:");
    progressUpdateDisplay();
}


/******************************************************************************/
/**
 * Set the state of a single bank. The display is updated automatically.
 * Only the bits in FLASH_BANK_MASK are used.
 */
void __fastcall__ progressSetBankState(const EasyFlashAddr* pAddr,
                                       uint8_t state)
{
    int8_t nBank = pAddr->nBank & FLASH_BANK_MASK;

    if (pAddr->nChip < 2)
    {
        m_aBlockStates[g_nSelectedSlot][pAddr->nChip][nBank] =
                state;
        progressDisplayBank(nBank, pAddr->nChip, state);
    }
}



/******************************************************************************/
/**
 * Set the state of a several banks. The display is updated automatically.
 * Only the bits in FLASH_BANK_MASK are used.
 */
void __fastcall__ progressSetMultipleBanksState(uint8_t nBank, uint8_t nChip,
                                                uint8_t nBankCount,
                                                uint8_t state)
{
    uint8_t i;
    for (i = nBank; i < nBank + nBankCount; ++i)
    {
        if (nChip < 2)
        {
            m_aBlockStates[g_nSelectedSlot][nChip][i & FLASH_BANK_MASK] =
                    state;
        }
    }
    progressUpdateDisplay();
}


/******************************************************************************/
/**
 * Get the state of the bank which contains the given address.
 * Only the bits in FLASH_BANK_MASK are used.
 */
uint8_t __fastcall__ progressGetStateAt(uint8_t nBank, uint8_t nChip)
{
    if (nChip < 2)
    {
        return m_aBlockStates[g_nSelectedSlot][nChip][nBank & FLASH_BANK_MASK];
    }
    return PROGRESS_UNTOUCHED;
}
