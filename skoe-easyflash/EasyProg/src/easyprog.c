/*
 * EasyProg - easyprog.c - The main module
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

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <conio.h>
#include <stdlib.h>
#include <cbm.h>

#include <ef3usb.h>

#include "easyprog.h"
#include "autoinit.h"
#include "cart.h"
#include "screen.h"
#include "eapiglue.h"
#include "flash.h"
#include "texts.h"
#include "hex.h"
#include "progress.h"
#include "timer.h"
#include "write.h"
#include "torturetest.h"
#include "filedlg.h"
#include "slots.h"
#include "sprites.h"
#include "usbtest.h"
#include "util.h"
#include "../../c64/src/regs.h"

#undef SHOW_HEAP_FREE

/******************************************************************************/
static void showAbout(void);
static void toggleFastLoader(void);
static uint8_t returnTrue(void);
static uint8_t haveValidFlash(void);
static uint8_t isEF3(void);
static void updateFastLoaderText();

/******************************************************************************/


// Low/High flash chip manufacturer/device ID
static uint8_t nManufacturerId;
static uint8_t nDeviceId;
static uint8_t nBanks;
static const char* pStrFlashDriver = "";


uint8_t g_bFastLoaderEnabled;

char g_strCartName[EF_CART_NAME_LEN + 1];

/******************************************************************************/
/* Static variables */

// String describes the current action
static char strStatus[31];
static char strFastLoader[30];
static char strMemSize[24];

/******************************************************************************/

// forward declarations
extern ScreenMenu menuMain;
extern ScreenMenu menuOptions;
extern ScreenMenu menuExpert;
extern ScreenMenu menuHelp;


ScreenMenu menuMain =
{
    1, 2,
    0,
    &menuHelp,
    &menuOptions,
    {
        {
            "&Write CRT to flash",
            checkWriteCRTImage,
            haveValidFlash,
            0
        },
        {
            "Write &KERNAL to flash",
            checkWriteKERNALImage,
            isEF3,
            0
        },
        {
            "Write A&R/RR/NP to flash",
            checkWriteARImage,
            isEF3,
            0
        },
        {
            "Write SS&5 to flash",
            checkWriteSS5Image,
            isEF3,
            0
        },
        {
            "Erase &all",
            checkEraseAll,
            returnTrue, //ifHaveValidFlash,
            0
        },
        {
            "Erase &slot",
            checkEraseSlot,
            isEF3,
            0
        },
        {
            "Erase KERNAL",
            checkEraseKERNAL,
            isEF3,
            0
        },
        {
            "Erase AR/RR/NP",
            checkEraseAR,
            isEF3,
            0
        },
        {
            "Erase SS5",
            checkEraseSS5,
            isEF3,
            0
        },
        { NULL, NULL, 0, 0 }
    }
};


ScreenMenu menuOptions =
{
    7, 2,
    0,
    &menuMain,
    &menuExpert,
    {
        {
            strFastLoader,
            toggleFastLoader,
            returnTrue,
            SCREEN_MENU_ENTRY_FLAG_KEEP
        },
        { NULL, NULL, 0 }
    }
};


ScreenMenu menuExpert =
{
    16, 2,
    0,
    &menuOptions,
    &menuHelp,
    {
        {
            "&Check flash type",
            (void (*)(void)) checkFlashType,
            returnTrue,
            0
        },
        {
            "Write BIN to &LOROM",
            checkWriteLOROMImage,
            returnTrue, //ifHaveValidFlash,
            0
        },
        {
            "Write BIN to &HIROM",
            checkWriteHIROMImage,
            returnTrue, //ifHaveValidFlash,
            0
        },
        {
            "&Torture test",
            tortureTestComplete,
            returnTrue, //ifHaveValidFlash,
            0
        },
        {
            "&Read torture test",
            tortureTestRead,
            returnTrue, //ifHaveValidFlash,
            0
        },
        {
            "R&AM test",
            tortureTestRAM,
            returnTrue,
            0
        },
        {
            "US&B test",
            usbTest,
            isEF3,
            0
        },
        {
            "He&x viewer",
            hexViewer,
            returnTrue, //ifHaveValidFlash,
            0
        },
        {
            "&Edit directory",
            slotsEditDirectory,
            isEF3,
            0
        },
        {
            "A&uto test + init",
            autoInit,
            returnTrue,
            0
        },
        { NULL, NULL, 0, 0 }
    }
};

ScreenMenu menuHelp =
{
    24, 2,
    0,
    &menuExpert,
    &menuMain,
    {
        {
            "&About",
            showAbout,
            returnTrue,
            0
        },
        { NULL, NULL, 0, 0 }
    }
};


/******************************************************************************/
/**
 * Show or update a box with the current action.
 */
static void refreshStatusLine(void)
{
    gotoxy (1, 23);
    cputs(strStatus);
    cclear(sizeof(strStatus) - 2 - wherex());
}


/******************************************************************************/
/**
 * Show or refresh the Screen which reports the Flash IDs.
 */
void refreshMainScreen(void)
{
    screenPrintFrame();

    // menu entries
    gotoxy (1, 1);
    textcolor(COLOR_EXTRA);
    cputc('M');
    textcolor(COLOR_FOREGROUND);
    cputs("enu  ");

    textcolor(COLOR_EXTRA);
    cputc('O');
    textcolor(COLOR_FOREGROUND);
    cputs("ptions  ");

    textcolor(COLOR_EXTRA);
    cputc('E');
    textcolor(COLOR_FOREGROUND);
    cputs("xpert  ");

    textcolor(COLOR_EXTRA);
    cputc('H');
    textcolor(COLOR_FOREGROUND);
    cputs("elp");

    textcolor(COLOR_LIGHTFRAME);
    screenPrintBox(16, 3, 23, 13);
    screenPrintSepLine(16, 38, 5);
    screenPrintSepLine(16, 38, 7);
    screenPrintSepLine(16, 38, 9);
    screenPrintSepLine(16, 38, 11);
    screenPrintSepLine(16, 38, 13);
    textcolor(COLOR_FOREGROUND);

    gotoxy(6, 4);
    cputs("File Name:");
    gotox(17);
    cputs(g_strFileName);

    gotoxy(7, 6);
    cputs("CRT Name:");
    gotox(17);
    cputs(g_strCartName);

    gotoxy(7, 8);
    cputs("CRT Type:");
    gotox(17);
    cputs(aStrInternalCartTypeName[internalCartType]);

    gotoxy(3, 10);
    cputs("Flash Driver:");
    gotox(17);
    cputs(pStrFlashDriver);

    gotoxy(10, 12);
    cputs("Slots:");
    gotox(17);
    cputs(strMemSize);

    gotoxy(2, 14);
    cputs("Selected Slot:");
    gotox(17);
    if (g_nSlots > 1)
    {
        utilStr[0] = '\0';
        utilAppendDecimal(g_nSelectedSlot);
        cputs(utilStr);
    }
    else
        cputc('0');

    refreshElapsedTime();
    progressShow();
    refreshStatusLine();
#ifdef SHOW_HEAP_FREE
    strcpy(utilStr, "Heap: blk ");
    utilAppendDecimal(_heapmaxavail());
    utilAppendStr(", all ");
    utilAppendDecimal(_heapmemavail());
    gotoxy(0, 0);
    cputs(utilStr);
#endif
}


/******************************************************************************/
/**
 * Update the text strMemSize according to nSlots and nBanks.
 */
static void updateMemSizeText(void)
{
    utilStr[0] = '\0';
    utilAppendDecimal(g_nSlots);
    utilAppendStr(" * ");
    utilAppendDecimal(nBanks * 16);
    utilAppendStr(" KiByte");
    strcpy(strMemSize, utilStr);
}


/******************************************************************************/
/**
 */
static void leadingZero(uint16_t v)
{
    utilStr[0] = '\0';
    if (v < 10)
    {
        utilStr[0] = '0';
        utilStr[1] = '\0';
    }
}


/******************************************************************************/
/**
 * Refresh the elapsed time value.
 */
void refreshElapsedTime(void)
{
    uint16_t t;

    t = timerGet();
    gotoxy(34, 23);
    leadingZero(t >> 8);
    utilAppendDecimal(t >> 8);
    cputs(utilStr);
    cputc(':');
    leadingZero(t & 0xff);
    utilAppendDecimal(t & 0xff);
    cputs(utilStr);
}


/******************************************************************************/
/**
 * Read Flash manufacturer and device IDs, print then on the screen.
 * If they are not okay, print an error message and return 0.
 * If everything is okay, return 1.
 */
uint8_t checkFlashType(void)
{
    uint8_t* pDriver;
    uint8_t  bDriverFound = 0;

    pDriver = aEAPIDrivers[0];
    while (*pDriver)
    {
        memcpy(EAPI_LOAD_TO, pDriver, EAPI_SIZE);

        nBanks = eapiInit(&nManufacturerId, &nDeviceId);

        if (nBanks > 0)
        {
            bDriverFound = 1;
            break;
        }

        /* if we are here, there is an error */
        switch (nDeviceId)
        {
        case EAPI_ERR_RAM:
            screenPrintSimpleDialog(apStrBadRAM);
            goto failed;

        case EAPI_ERR_ROML_PROTECTED:
            screenPrintSimpleDialog(apStrROMLProtected);
            goto failed;

        case EAPI_ERR_ROMH_PROTECTED:
            screenPrintSimpleDialog(apStrROMHProtected);
            goto failed;
        }
        pDriver += EAPI_SIZE;
    }

    if (bDriverFound)
    {
        pStrFlashDriver = EAPI_DRIVER_NAME;
        g_nSlots = 1;
        if (nBanks < 64)
        {
            g_nSlots = nBanks;
            nBanks = 64;
            eapiSetSlot(g_nSelectedSlot);
        }
        updateMemSizeText();
        refreshMainScreen();
        return 1;
    }
    else
    {
        screenPrintSimpleDialog(apStrWrongFlash);
    }

failed:
    pStrFlashDriver = "(failed)";
    refreshMainScreen();
    nManufacturerId = nDeviceId = 0;
    g_nSlots = g_nSelectedSlot = 0;
    return 0;
}


/******************************************************************************/
/**
 * Always return 1.
 */
static uint8_t returnTrue(void)
{
   return 1;
}


/******************************************************************************/
/**
 * Return non-0 if the flash is okay and we have a driver which supports it.
 */
static uint8_t haveValidFlash(void)
{
    return nManufacturerId | nDeviceId;
}

/******************************************************************************/
/**
 * Return non-0 if the current device has KERNALs like the EF3.
 */
static uint8_t isEF3(void)
{
    return nManufacturerId == FLASH_MX29LV640EB_MFR_ID &&
           nDeviceId == FLASH_MX29LV640EB_DEV_ID;
}

/******************************************************************************/
/**
 * Check if the RAM at $DF00 is okay.
 * If it is not okay, print an error message.
 */
static void checkRAM(void)
{
    if (!tortureTestCheckRAM())
    {
        screenPrintSimpleDialog(apStrBadRAM);
        refreshMainScreen();
    }
}


/******************************************************************************/
/**
 * Show the about dialog.
 */
static void showAbout(void)
{
    spritesShow();
    screenPrintSimpleDialog(apStrAbout);
    spritesOn(0);
}


/******************************************************************************/
/**
 * Toggle the fast loader setting.
 */
static void toggleFastLoader(void)
{
    g_bFastLoaderEnabled = !g_bFastLoaderEnabled;
    updateFastLoaderText();
}


/******************************************************************************/
/**
 * Set the status text and update the display.
 */
void __fastcall__ setStatus(const char* pStrStatus)
{
    strncpy(strStatus, pStrStatus, sizeof(strStatus - 1));
    strStatus[sizeof(strStatus) - 1] = '\0';
    refreshStatusLine();
}


/******************************************************************************/
/**
 * Execute an action according to the given menu ID.
 */
static void __fastcall__ execMenu(ScreenMenu* pMenu)
{
    screenDoMenu(pMenu);
    refreshMainScreen();
}


/******************************************************************************/
/**
 * Update the "Fast loader enabled:    " text.
 */
static void updateFastLoaderText()
{
    char* pStr;

    strcpy(strFastLoader, "&Fastloader enabled: ");
    pStr = g_bFastLoaderEnabled ? "Yes" : "No";
    strcat(strFastLoader, pStr);
}


/******************************************************************************/
/**
 * Refresh the elapsed time value.
 */
void resetCartInfo(void)
{
    g_strFileName[0] =
    g_strCartName[0] = '\0';
    internalCartType = INTERNAL_CART_TYPE_NONE;
}


/******************************************************************************/
/**
 * Refresh the elapsed time value.
 */
void execUSBCmd(const char* pStrUSBCmd)
{
    if (strcmp(pStrUSBCmd, "crt") == 0)
    {
        /*if (screenPrintDialog(apStrFlashFromUSB, BUTTON_ENTER | BUTTON_STOP) ==
                BUTTON_ENTER)*/
        {
            checkWriteCRTImageFromUSB();
            refreshMainScreen();
        }
        /*else
        {
            ef3usb_send_str("stop");
        }*/
    }
    else
    {
        ef3usb_send_str("btyp");
    }
}


/******************************************************************************/
/**
 *
 */
int main(void)
{
    char key;
    const char* pStrUSBCmd;

    // disable MIDI
    MIDI_CONFIG = 0;

    // set EXROM=1 and GAME=1
    CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;

    // enable EasyFlash mode and enable RAM
    CART_CONFIG = CART_CONFIG_EASYFLASH_ON | CART_CONFIG_RAM_ON;

    // first RAM page
    RAM_ADDRESS_EXTENSION = 0;

    // address bit 20 = 1
    ADDRESS_EXTENSION2 = ADDRESS_EXTENSION2_FLASH_A20;

    timerInitTOD();
    screenInit();
    progressInit();

    debug_init();
    debug_puts("\r\nEasyProg debug output\r\n");

    resetCartInfo();

    g_nDrive = *(uint8_t*)0xba;
    if (g_nDrive < 8)
        g_nDrive = 8;

    g_bFastLoaderEnabled = 1;
    updateFastLoaderText();

    refreshMainScreen();
    showAbout();
    refreshMainScreen();

    checkFlashType();

    checkRAM();

    for (;;)
    {
        setStatus("Ready. Press <m> for Menu.");

        if (kbhit())
        {
            key = cgetc();
            switch (key)
            {
            case 'm':
                execMenu(&menuMain);
                break;

            case 'o':
                execMenu(&menuOptions);
                break;

            case 'e':
                execMenu(&menuExpert);
                break;

            case 'h':
                execMenu(&menuHelp);
                break;
            }
        }
        else if (isEF3())
        {
            pStrUSBCmd = ef3usb_check_cmd();
            if (pStrUSBCmd)
            {
                execUSBCmd(pStrUSBCmd);
            }
        }
    }
    return 0;
}
