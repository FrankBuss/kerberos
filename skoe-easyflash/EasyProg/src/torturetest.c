/*
 * EasyProg - torturetest.c - Torture Test
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

#include <conio.h>
#include <string.h>
#include <stdio.h>

#include "screen.h"
#include "texts.h"
#include "easyprog.h"
#include "torturetest.h"
#include "flash.h"
#include "eapiglue.h"
#include "slots.h"
#include "util.h"

/*
 * The cartridge test works like this:
 * - Each bank (8 KiB) is filled with a special pattern:
 *   1k slot number
 *   1k bank number / chip number
 *   2k 0xaa
 *   2k 0x55
 *   1k 0x00 - 0xff (repeated)
 *   1k 0xff - 0x00 (repeated)
 */

/******************************************************************************/
/**
 * Write the test data to the cartridge.
 *
 * return 1 for success, 0 for failure/stop
 */
static uint8_t tortureTestWriteData(void)
{
    EasyFlashAddr addr;

    for (addr.nSlot = 0; addr.nSlot < g_nSlots; ++addr.nSlot)
    {
        slotSelect(addr.nSlot); // also refreshes the screen

        for (addr.nBank = 0; addr.nBank < FLASH_NUM_BANKS; ++addr.nBank)
        {
            for (addr.nChip = 0; addr.nChip < 2; ++addr.nChip)
            {
                for (addr.nOffset = 0; addr.nOffset < 0x2000; addr.nOffset += 256)
                {
                    tortureTestFillBuffer(&addr);

                    if (!flashWriteBlock(&addr))
                    {
                        return 0;
                    }

                    if (screenIsStopPressed())
                        return 0;
                }
            }
        }
    }

    return 1;
}

/******************************************************************************/
/**
 * Verify the test data on the cartridge on all banks. The slot number
 * must have been set and activated already.
 *
 * return 1 for success, 0 for failure/stop
 */
static uint8_t tortureTestVerify(void)
{
    EasyFlashAddr   addr;

    addr.nSlot = g_nSelectedSlot;

    debug_puts("tortureTestVerify\r\n");

    for (addr.nBank = 0; addr.nBank < FLASH_NUM_BANKS; ++addr.nBank)
    {
        debug_puts("bank: ");
        debug_hex_padded(2, addr.nBank);
        debug_crlf();

        for (addr.nChip = 0; addr.nChip < 2; ++addr.nChip)
        {
            debug_puts("chip: ");
            debug_hex_digit(addr.nChip);
            debug_crlf();

            for (addr.nOffset = 0; addr.nOffset < 0x2000; addr.nOffset += 256)
            {
                debug_puts("offset: ");
                debug_hex_padded(4, addr.nOffset);
                debug_crlf();

                tortureTestFillBuffer(&addr);

                if (!flashVerifyBlock(&addr))
                    return 0;
            }
            if (screenIsStopPressed())
                return 0;
        }
    }

    return 1;
}


/******************************************************************************/
/**
 * Read the chip IDs 256 times (which includes writing to flash).
 *
 * return 1 for success, 0 for failure
 */
static uint8_t tortureTestFlashIds(void)
{
    uint8_t nLoop;

    nLoop = 0;
    do
    {
        if (!eapiReInit())
        {
            screenPrintTwoLinesDialog(pStrTestFailed, "(Init)");
            return 0;
        }
    }
    while(++nLoop);

    return 1;
}

/******************************************************************************/
/**
 * Start the torture test. If bComplete != 0, the test data is written to the
 * flash memory first.
 */
static void tortureTest(uint8_t bComplete, uint8_t bAutoTest)
{
    uint16_t rv;
    uint16_t nLoop, nSlot;

    if (bComplete && !bAutoTest)
    {
    	if (screenAskEraseDialog() != BUTTON_ENTER)
    		return;
    }

    if (!bAutoTest)
        screenPrintSimpleDialog(apStrTestEndless);

    refreshMainScreen();

    if (!tortureTestFlashIds())
        return;

    if (bComplete)
    	if (!tortureTestWriteData())
    	    return;

    for (nLoop = 0; !bAutoTest; ++nLoop)
    {
        strcpy(utilStr, "Test loop ");
        utilAppendDecimal(nLoop);
        if (nLoop > 0)
        {
            strcat(utilStr, " - loop ");
            utilAppendDecimal(nLoop - 1);
            strcat(utilStr, " ok");
        }
        setStatus(utilStr);

        rv = tortureTestBanking();
        if (rv != 0)
        {
            strcpy(utilStr, "Bank test error: set ");
            utilAppendHex2(rv >> 8);
            utilAppendStr(" != read ");
            utilAppendHex2(rv & 0xff);

            screenPrintTwoLinesDialog(pStrTestFailed, utilStr);
            return;
        }

        if (!tortureTestCheckRAM())
        {
            screenPrintSimpleDialog(apStrBadRAM);
            return;
        }

        if (!tortureTestFlashIds())
            return;

        for (nSlot = 0; nSlot < g_nSlots; ++nSlot)
        {
            slotSelect(nSlot); // also refreshes the screen

            if (!tortureTestVerify())
                return;
        }
    }
}

/******************************************************************************/
/**
 */
void tortureTestAuto(void)
{
    tortureTest(1, 1);
}

/******************************************************************************/
/**
 */
void tortureTestComplete(void)
{
	tortureTest(1, 0);
}

/******************************************************************************/
/**
 */
void tortureTestRead(void)
{
	tortureTest(0, 0);
}

/******************************************************************************/
/**
 */
void tortureTestRAM(void)
{
    uint16_t nLoop;

    screenPrintSimpleDialog(apStrTestEndless);

    for (nLoop = 0; ; ++nLoop)
    {
        strcpy(utilStr, "RAM test loop ");
        utilAppendDecimal(nLoop);
        setStatus(utilStr);

        if (!tortureTestCheckRAM())
        {
            screenPrintSimpleDialog(apStrBadRAM);
            refreshMainScreen();
        }

        if (screenIsStopPressed())
            return;
    }
}
