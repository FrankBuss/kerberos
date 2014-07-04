/*
 * EasyProg
 *
 * (c) 2009 - 2011 Thomas Giesel
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

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <string.h>

#include "util.h"
#include "screen.h"
#include "selectbox.h"

#define SELECTBOX_X 6
#define SELECTBOX_W 26

static const SelectBoxEntry* pEntries;
static uint8_t yPosition;
static uint8_t nSelection;
static uint8_t nEntries;

/******************************************************************************/
/**
 * Print/Update the headline
 */
static void __fastcall__ selectBoxHeadline(const char* pStrWhatToSelect)
{
    strcpy(utilStr, "Select ");
    utilAppendStr(pStrWhatToSelect);
    cputsxy(SELECTBOX_X + 1, yPosition + 1, utilStr);
}

/******************************************************************************/
/**
 * Print/Update the frame
 */
static void selectBoxPrintFrame(uint8_t nEntries)
{
    screenPrintBox(SELECTBOX_X, yPosition, SELECTBOX_W, nEntries + 6);
    screenPrintSepLine(SELECTBOX_X, SELECTBOX_X + SELECTBOX_W - 1, yPosition + 2);
    screenPrintSepLine(SELECTBOX_X, SELECTBOX_X + SELECTBOX_W - 1, yPosition + nEntries + 6 - 3);
    cputsxy(SELECTBOX_X + 1, yPosition + nEntries + 6 - 2, "Up/Down/Enter/Stop");
}

/******************************************************************************/
/**
 */
static void __fastcall__ selectBoxPrintEntry(uint8_t nEntry)
{
    const SelectBoxEntry* pEntry;

    pEntry = pEntries + nEntry;
    gotoxy(SELECTBOX_X + 1, yPosition + 3 + nEntry);

    if (nEntry == nSelection)
        revers(1);

    // clear line
    cclear(SELECTBOX_W - 2);

    // name
    gotox(SELECTBOX_X + 2);
    cputs(pEntry->label);

    revers(0);
}



/******************************************************************************/
/**
 * Let the user select an entry. Return the entry number.
 * Return 0xff if the user canceled the selection.
 */
uint8_t __fastcall__ selectBox(const SelectBoxEntry* p,
                               const char* pStrWhatToSelect)
{
    unsigned char n, nOldSelection;
    char key;
    uint8_t bRefresh;
    const SelectBoxEntry* pEntry;

    pEntries = p;
    pEntry = pEntries;
    nEntries = 0;
    while (pEntry->label[0])
    {
        ++nEntries;
        ++pEntry;
    }

    yPosition = 9 - nEntries / 2;

    selectBoxPrintFrame(nEntries);
    selectBoxHeadline(pStrWhatToSelect);

    bRefresh = 1;
    nSelection = 0;

    for (n = 0; n < nEntries; ++n)
    {
        selectBoxPrintEntry(n);
    }

    for (;;)
    {
        if (bRefresh)
        {
            // only refresh the two lines which have changed
            selectBoxPrintEntry(nOldSelection);
            selectBoxPrintEntry(nSelection);
            bRefresh = 0;
        }

        nOldSelection = nSelection;
        key = cgetc();
        switch (key)
        {
        case CH_CURS_UP:
            if (nSelection)
            {
                --nSelection;
                bRefresh = 1;
            }
            break;

        case CH_CURS_DOWN:
            if (nSelection + 1 < nEntries)
            {
                ++nSelection;
                bRefresh = 1;
            }
            break;

        case CH_ENTER:
            return nSelection;

        case CH_STOP:
            return 0xff;
        }
    }
}
