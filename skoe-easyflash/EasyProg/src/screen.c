/*
 * EasyProg - screen.c - Functions for the screen
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

#include <c64.h>
#include <stdint.h>
#include <conio.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "screen.h"
#include "texts.h"
#include "sprites.h"
#include "util.h"

#include "easyprog.h"

const char* pStrHexDigits = "0123456789ABCDEF";

/* Menu currently shown or NULL */
static ScreenMenu* pCurrentMenu;

/******************************************************************************/
/**
 * Return 1 if the menu entry has the shortcut 'key', 0 otherwise.
 */
static uint8_t screenMenuEntryHasShortcut(const ScreenMenuEntry* pEntry, char key)
{
    const char* p;
    char c, next;

    p = pEntry->pStrLabel;
    c = *p;
    while (c)
    {
        ++p;
        next = *p;
        if (c == '&' && key == tolower(next))
            return 1;
        c = next;
    }
    return 0;
}


/******************************************************************************/
/**
 * Show or update pCurrentMenu.
 *
 * Return the number of entries in the menu.
 */
static uint8_t screenPrintCurrentMenu(void)
{
    uint8_t nEntry, nEntries;
    uint8_t tmp;
    uint8_t len;
    uint8_t x, y, textColor;
    char    c;
    const ScreenMenuEntry* pEntry;
    const char* pStr;
    const char* p;

    // calculate length of longest entry
    len = 2;
    nEntries = 0;
    pEntry = pCurrentMenu->entries;
    while ((pStr = pEntry->pStrLabel) != NULL)
    {
        tmp = strlen(pStr);
        if (tmp > len)
            len = tmp;
        ++nEntries;
        ++pEntry;
    }

    /* hack: only 1 more instead of 2 because of the '&' in each entry */
    len += 1;

    x = pCurrentMenu->x;
    y = pCurrentMenu->y;

    screenPrintBorder(x, y, len + 2, nEntries + 2);

    ++x;

    pEntry = pCurrentMenu->entries;
    for (nEntry = 0; nEntry != nEntries; ++nEntry)
    {
        gotoxy(x, ++y);

        pStr      = pEntry->pStrLabel;
        textColor = pEntry->pCheckFunction() ?
            COLOR_FOREGROUND : COLOR_GRAY1;
        textcolor(textColor);

        if (nEntry == pCurrentMenu->nSelected)
            revers(1);

        cputc(' ');

        p = pStr;
        while ((c = *p) != 0)
        {
            if (c == '&')
            {
                textcolor(COLOR_EXTRA);
            }
            else
            {
                cputc(c);
                textcolor(textColor);
            }
            ++p;
        }
        cclear(len + x - wherex());

        revers(0);
        ++pEntry;
    }
    textcolor(COLOR_FOREGROUND);
    return nEntries;
}


/******************************************************************************/
/**
 * Initialize the screen. Set up colors and clear it.
 */
void screenInit(void)
{
    bgcolor(COLOR_BACKGROUND);
    bordercolor(COLOR_BACKGROUND);
    textcolor(COLOR_FOREGROUND);
    clrscr();
}


/******************************************************************************/
/**
 */
void screenBing(void)
{
    uint16_t f;

    SID.amp = 0x0f;

    // switch of prev. tone, init some values
    memset(&(SID.v1), 0, 3 * sizeof(SID.v1));

    SID.v1.ad =
    SID.v2.ad = 0x08;

    SID.v2.freq = 0x3900;

    SID.v1.ctrl =
    SID.v2.ctrl = 0x11;

    for (f = 0x3800; f != 0x4400; ++f)
        SID.v1.freq = f;

    memset(&(SID.v1), 0, 3 * sizeof(SID.v1));
}


/******************************************************************************/
/**
 * Print a free line at y between xStart and xEnd (incl).
 *
 * ++++++++
 * +      + <= This one
 * ++++++++
 * +      +
 * ++++++++
 */
void screenPrintFreeLine(uint8_t xStart, uint8_t xEnd, uint8_t y)
{
    cputcxy(xStart, y, 0x7d);
    cclear(xEnd - xStart - 1);
    cputc(0x7d);
}


/******************************************************************************/
/**
 * Draw the big screen and the screen divisions.
 */
void screenPrintFrame(void)
{
    uint8_t y;

    // Top line
    screenPrintTopLine(0, 39, 0);
    // 1 text line
    screenPrintFreeLine(0, 39, 1);
    // separation line
    screenPrintSepLine(0, 39, 2);

    // some free lines
    for (y = 3; y < 22; ++y)
        screenPrintFreeLine(0, 39, y);
    // separation line
    screenPrintSepLine(0, 39, 22);
    // 1 text line
    screenPrintFreeLine(0, 39, 23);
    // Bottom line
    screenPrintBottomLine(0, 39, 24);
}


/******************************************************************************/
/**
 * Draw an empty box.
 *
 * The size is incl. border
 */
void screenPrintBorder(uint8_t x, uint8_t y, uint8_t w, uint8_t h)
{
    uint8_t i, x_end;

    --w;
    x_end = x + w;

    // Top line
    screenPrintTopLine(x, x_end, y);

    for (i = h - 2; i; --i)
    {
        ++y;
        cputcxy(x,     y, 0x7d);
        gotox(x_end);
        cputc(0x7d);
    }

    // Bottom line
    screenPrintBottomLine(x, x_end, ++y);
}


/******************************************************************************/
/**
 * Draw a filled empty box.
 *
 * The size is incl. border
 */
void screenPrintBox(uint8_t x, uint8_t y, uint8_t w, uint8_t h)
{
    uint8_t i;

    screenPrintBorder(x, y, w, h);

    w -= 2;
    ++x;

    for (i = h - 2; i; --i)
    {
        gotoxy(x, ++y);
        cclear(w);
    }
}


/******************************************************************************/
/**
 * Print a Button with a label. x/y is the upper left corner.
 */
void screenPrintButton(uint8_t x, uint8_t y, const char* pStrLabel)
{
    uint8_t len;
    uint8_t xEnd;

    len = strlen(pStrLabel);
    xEnd = x + len + 1;

    screenPrintTopLine(x, xEnd, y++);

    cputcxy(x, y++, 0x7d);
    cputs(pStrLabel);
    cputc(0x7d);

    screenPrintBottomLine(x, xEnd, y);
}


/******************************************************************************/
/**
 * Show and handle the menu and execute the menu item is one was selected.
 */
void __fastcall__ screenDoMenu(ScreenMenu* pMenu)
{
    uint8_t nEntry, nEntries;
    uint8_t nSelected;
    char key;
    ScreenMenuEntry* pEntries;
    ScreenMenuEntry* pEntry;

    pCurrentMenu = pMenu;
    nSelected = 0;

    do
    {
        pCurrentMenu->nSelected = nSelected;
        pEntries = pCurrentMenu->entries;
        nEntries = screenPrintCurrentMenu();
        key = cgetc();

        switch (key)
        {
        case CH_CURS_UP:
            if (nSelected)
                --nSelected;
            else
                nSelected = nEntries - 1;
            break;

        case CH_CURS_DOWN:
            if (++nSelected == nEntries)
                nSelected = 0;
            break;

        case CH_CURS_RIGHT:
            if (pCurrentMenu->pNextMenu)
            {
                pCurrentMenu = pCurrentMenu->pNextMenu;
                refreshMainScreen();
                nEntries = screenPrintCurrentMenu();
                nSelected = 0;
            }
            break;

        case CH_CURS_LEFT:
            if (pCurrentMenu->pPrevMenu)
            {
                pCurrentMenu = pCurrentMenu->pPrevMenu;
                refreshMainScreen();
                nEntries = screenPrintCurrentMenu();
                nSelected = 0;
            }
            break;

        case CH_ENTER:
        case ' ':
            pEntry = pEntries + nSelected;
            if (pEntry->pCheckFunction())
            {
                pEntry->pFunction();
                if (pEntry->flags & SCREEN_MENU_ENTRY_FLAG_KEEP)
                {
                    // refresh, because the length may have changed
                    refreshMainScreen();
                    screenPrintCurrentMenu();
                }
                else
                    return;
            }
            break;

        default:
            /* all other keys may be shortcuts */
            for (nEntry = 0; nEntry != nEntries; ++nEntry)
            {
                if (screenMenuEntryHasShortcut(pCurrentMenu->entries + nEntry, key) &&
                        pEntries[nEntry].pCheckFunction())
                {
                    pCurrentMenu->nSelected = nEntry;
                    // update immediately to show the effect to the user
                    screenPrintCurrentMenu();
                    pEntries[nEntry].pFunction();
                    return;
                }
            }
        }
    } while (key != CH_STOP && key != CH_BTEE);
}

/******************************************************************************/
/**
 * Print a dialog with some text lines and wait for a key if a flag is set.
 * The array of lines apStrLines must be terminated with a NULL pointer.
 *
 * flags            may contain BUTTON_ENTER and/or BUTTON_STOP.
 * return           the button which has been pressed
 */
uint8_t __fastcall__ screenPrintDialog(const char* apStrLines[], uint8_t flags)
{
    uint8_t y, t;
    uint8_t nLines;
    uint8_t nLongestLength = 1;
    uint8_t xStart, xEnd, yStart, yEnd;

    for (y = 0; apStrLines[y]; ++y)
    {
        t = strlen(apStrLines[y]);
        if (t > nLongestLength)
            nLongestLength = t;
    }
    nLines = y;

    if (nLongestLength > 38)
        nLongestLength = 38;

    nLongestLength += 2;
    xStart = 20 - nLongestLength / 2;
    xEnd = 20 + nLongestLength / 2;
    yStart = 7 - nLines / 2;
    yEnd = 7 + nLines / 2 + 9;

    // Top line
    y = yStart;
    screenPrintTopLine(xStart, xEnd, y);
    screenPrintFreeLine(xStart, xEnd, ++y);
    cputsxy(xStart + 1, y, "EasyProg");
    screenPrintSepLine(xStart, xEnd, ++y);

    // some lines
    for (++y; y < yEnd; ++y)
        screenPrintFreeLine(xStart, xEnd, y);
    // Bottom line
    screenPrintBottomLine(xStart, xEnd, y);

    // Write the text lines
    yStart += 4;
    ++xStart;
    for (y = 0; y < nLines; ++y)
    {
        t = strlen(apStrLines[y]);
        if (t > 38)
            continue;

        cputsxy(xStart, yStart++, apStrLines[y]);
    }

    y = yEnd - 3;
    if (flags & BUTTON_ENTER)
        screenPrintButton(xEnd - 7, yEnd - 3, "Enter");

    if (flags & BUTTON_STOP)
        screenPrintButton(xStart, yEnd - 3, "Stop");

    screenBing();

    if (flags)
        return screenWaitKey(flags);

    return 0;
}


/******************************************************************************/
/**
 * Print a dialog with some text lines and wait for <Enter>.
 * The array of lines apStrLines must be terminated with a NULL pointer.
 */
void __fastcall__ screenPrintSimpleDialog(const char* apStrLines[])
{
    screenPrintDialog(apStrLines, BUTTON_ENTER);
}


/******************************************************************************/
/**
 * Print a dialog with two text lines and wait for <Stop> or <Enter>.
 *
 * return           the button which has been pressed
 */
uint8_t __fastcall__ screenPrintTwoLinesDialog(const char* p1, const char* p2)
{
    const char* apStrLines[3];
    apStrLines[0] = p1;
    apStrLines[1] = p2;
    apStrLines[2] = NULL;
    return screenPrintDialog(apStrLines, BUTTON_ENTER | BUTTON_STOP);
}


/******************************************************************************/
/**
 * Print a dialog to ask whether it is okay to erase the flash.
 * Wait for <Stop> or <Enter>.
 *
 * return           the button which has been pressed
 */
uint8_t __fastcall__ screenAskEraseDialog(void)
{
    return screenPrintDialog(apStrAskErase, BUTTON_ENTER | BUTTON_STOP);
}


/******************************************************************************/
/**
 * Wait until one of the keys has been pressed.
 *
 * flags        contains the keys allowed: BUTTON_ENTER and/or BUTTON_STOP
 * return       BUTTON_ENTER or BUTTON_STOP
 */
uint8_t __fastcall__ screenWaitKey(uint8_t flags)
{
    char key;

    for (;;)
    {
        key = cgetc();

        if ((flags & BUTTON_ENTER) && key == CH_ENTER)
            return BUTTON_ENTER;

        if ((flags & BUTTON_STOP) && key == CH_STOP)
            return BUTTON_STOP;
    }
}


/******************************************************************************/
/**
 */
uint8_t __fastcall__ screenIsStopPressed(void)
{
    if (kbhit() && cgetc() == CH_STOP)
        return 1;
    return 0;
}


/******************************************************************************/
/**
 * Return the string entered. The maximal length of the string is
 * FILENAME_MAX, i.e. 16+1.
 */
const char* __fastcall__ screenReadInput(const char* pStrTitle,
                                         const char* pStrDefault)
{
    uint8_t len;
    static char strInput[FILENAME_MAX];
    char c;

    screenBing();
    strcpy(strInput, pStrDefault);
    len = strlen(strInput);

    screenPrintBox(2, 6, 36, 12);
    screenPrintSepLine(2, 37, 8);

    cputsxy(3, 7, pStrTitle);

    // the input field
    textcolor(COLOR_LIGHTFRAME);
    screenPrintBox(4, 10, 32, 3);
    textcolor(COLOR_FOREGROUND);

    screenPrintButton(30, 14, "Enter");

    cursor(1);
    do
    {
        cputsxy(5, 11, strInput);
        cputc(' ');
        gotox(5 + len);

        c = cgetc();
        if (len < sizeof(strInput) - 1 &&
                ((c >=  32 && c < 128) ||
                 (c >= 192 && c < 224))
           )
        {
            strInput[len++] = c;
            strInput[len]   = '\0';
        }
        else if (c == CH_DEL)
        {
            if (len)
                strInput[--len] = '\0';
        }
    } while (c != CH_ENTER);

    cursor(0);
    refreshMainScreen();

    return strInput;
}
