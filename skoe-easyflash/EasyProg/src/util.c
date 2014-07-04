/*
 * EasyProg - util.c
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

#include <cbm.h>
#include <string.h>
#include <conio.h>
#include <stdio.h>

#include <ef3usb.h>

#include "util.h"
#include "flash.h"
#include "filedlg.h"
#include "screen.h"
#include "texts.h"
#include "easyprog.h"
#include "eload.h"
#include "timer.h"
#include "slots.h"


// globally visible string buffer for functions used here
char utilStr[UTIL_STR_SIZE];

// points to utilRead function to be used to read bytes from file
unsigned int __fastcall__ (*utilRead)(void* buffer, unsigned int size);


/******************************************************************************/
/** Local data */

// This header is read by utilCheckFileHeader which is called by utilOpenFile.
// It can be used to identify the file type.
static union
{
    char            data[16];
    EasySplitHeader easySplitHeader;
} m_uFileHeader;

// Number of current split file (0...)
static uint8_t nCurrentPart;

// ID of current split file
static uint16_t nCurrentFileId;

static const char aEasySplitSignature[8] =
{
        0x65, 0x61, 0x73, 0x79, 0x73, 0x70, 0x6c, 0x74
};

static uint8_t bUseUSB;

/******************************************************************************/
/* prototypes */
static uint8_t utilCheckFileHeader(void);
static uint8_t __fastcall__ utilOpenEasySplitFile(uint8_t nPart);
static uint8_t utilOpenELoadFile(void);
static void utilComplainWrongPart(uint8_t nPart);


/******************************************************************************/
/**
 * Open the file for read access. Check if the file is compressed and select
 * the right read functions.
 *
 * nPart is the part number for split files. If this is 0 the file may be not
 * split or it may be the first part of a split file. Otherwise it must be the
 * right split file > 0.
 *
 * If nPart is UTIL_USE_USB the file will be read from USB, in this case no
 * splitting is allowed.
 *
 * OPEN_FILE_OK, OPEN_FILE_ERR, OPEN_FILE_WRONG
 */
uint8_t utilOpenFile(uint8_t nPart)
{
    uint8_t type;

    if (nPart == UTIL_USE_USB)
    {
        ef3usb_send_str("load");
        utilRead = ef3usb_fread;
        bUseUSB = 1;
        return OPEN_FILE_OK;
    }
    bUseUSB = 0;

    if (g_bFastLoaderEnabled)
        eload_set_drive_check_fastload(g_nDrive);
    else
        eload_set_drive_disable_fastload(g_nDrive);

    // this reads m_uFileHeader and returns the type detected
    type = utilCheckFileHeader();
    if (type == OPEN_FILE_ERR)
        return type;

    if (nPart == 0)
    {
        // it may be a split file part 1 or a plain file
        if (type == OPEN_FILE_TYPE_ESPLIT)
        {
            return utilOpenEasySplitFile(nPart);
        }
        else
        {
            // plain file
            utilRead = eload_read;
            return utilOpenELoadFile();
        }
    }
    else
    {
         if (type != OPEN_FILE_TYPE_ESPLIT)
         {
             screenPrintSimpleDialog(apStrFileNoEasySplit);
             return OPEN_FILE_WRONG;
         }
         return utilOpenEasySplitFile(nPart);
    }

    return OPEN_FILE_OK;
}


/******************************************************************************/
/**
 *
 */
void utilCloseFile(void)
{
    if (bUseUSB)
        ef3usb_fclose();
    else
        eload_close();
}

/******************************************************************************/
/**
 * Return 1 if a good file has been selected, 0 otherwise.
 */
uint8_t utilAskForNextFile(void)
{
    static char str[3];
    uint8_t     ret;

    eload_close();
    timerStop();

    ++nCurrentPart;
    utilStr[0] = '\0';
    utilAppendHex2(nCurrentPart + 1);
    // Must copy this, because fileDlg uses utilStr
    strcpy(str, utilStr);

    do
    {
        do
        {
            screenBing();
            refreshMainScreen();
            ret = fileDlg(str);

            if (!ret)
            {
                ret = screenPrintTwoLinesDialog("If you really want",
                                                "to abort, press <Stop>.");
                if (ret == BUTTON_STOP)
                    return 0;
            }
        }
        while (!ret);

        ret = utilOpenFile(nCurrentPart);
    }
    while (ret != OPEN_FILE_OK);

    timerCont();
    refreshMainScreen();
    return 1;
}


/******************************************************************************/
/**
 *
 */
void __fastcall__ utilAppendFlashAddr(const EasyFlashAddr* pAddr)
{
    if (g_nSlots > 1)
    {
        utilAppendHex2(pAddr->nSlot);
        utilAppendChar(':');
    }
    utilAppendHex2(pAddr->nBank & FLASH_BANK_MASK);
    utilAppendChar(':');
    utilAppendHex1(pAddr->nChip);
    utilAppendChar(':');
    utilAppendHex2(pAddr->nOffset >> 8);
    utilAppendHex2(pAddr->nOffset);
}


/******************************************************************************/
/**
 *
 */
void __fastcall__ utilAppendDecimal(uint16_t n)
{
    uint8_t aNum[5];
    int8_t  i;

    // write number backwards
    if (n)
    {
        i = 0;
        while (n)
        {
            aNum[i++] = n % 10;
            n /= 10;
        }

        while (--i >= 0)
        {
            // slow!
            utilAppendChar('0' + aNum[i]);
        }
    }
    else
        utilAppendChar('0');
}

/******************************************************************************/
/**
 *
 */
void __fastcall__ utilAppendStr(const char* str)
{
    strcat(utilStr, str);
}


/******************************************************************************/
/**
 *
 * Open a file, take the name from g_strFileName. The directory is parsed
 * here to find out track and sector.
 *
 * return: OPEN_FILE_OK, OPEN_FILE_ERR
 */
static uint8_t utilOpenELoadFile(void)
{
    if (eload_open_read(g_strFileName) == 0)
        return OPEN_FILE_OK;
    else
        return OPEN_FILE_ERR;
}



/******************************************************************************/
/**
 * Open an EasySplit file. Only called from utilOpenFile. The caller checked
 * already that it has the right file type and filled m_uFileHeader.
 * The file will be re-opened here, possibly using a speeder. Therefore we
 * have to skip the header again.
 *
 * return:
 *      OPEN_FILE_OK     for OK
 *      OPEN_FILE_ERR    for an error or if it is not an EasySplit file
 *      OPEN_FILE_WRONG  if it is an EasySplit file, but the wrong part
 */
static uint8_t __fastcall__ utilOpenEasySplitFile(uint8_t nPart)
{
    uint8_t i;
    uint8_t rv;

    if (nPart != m_uFileHeader.easySplitHeader.part)
    {
        utilComplainWrongPart(nPart);
        return OPEN_FILE_WRONG;
    }
    if ((nPart != 0) &&
        (nCurrentFileId != *(uint16_t*)(m_uFileHeader.easySplitHeader.id)))
    {
        screenPrintDialog(apStrDifferentFile, BUTTON_ENTER);
        return OPEN_FILE_WRONG;
    }

    utilRead = utilReadEasySplitFile;
    rv = utilOpenELoadFile();
    if (rv != OPEN_FILE_OK)
        return rv;

    // skip the header again
    for (i = 0; i < sizeof(EasySplitHeader); ++i)
        eload_read_byte();

    if (nPart == 0)
    {
        nUtilExoBytesRemaining =
                *(uint32_t*)(m_uFileHeader.easySplitHeader.len);

        // the read function expects the two's complement - 1
        nUtilExoBytesRemaining = -nUtilExoBytesRemaining - 1;
        utilInitDecruncher();
        nCurrentFileId = *(uint16_t*)(m_uFileHeader.easySplitHeader.id);
    }

    nCurrentPart = nPart;
    return OPEN_FILE_OK;
}


/******************************************************************************/
/**
 * return:
 *          OPEN_FILE_ERR       file couldn't be opened
 *          OPEN_FILE_UNKNOWN   unknown file type
 *          OPEN_FILE_TYPE_     file type detected
 */
static uint8_t utilCheckFileHeader(void)
{
    uint8_t len;

    if (eload_open_read(g_strFileName) != 0)
        return OPEN_FILE_ERR;

    len = eload_read(&m_uFileHeader, sizeof(m_uFileHeader));
    eload_close();

    if (len != sizeof(m_uFileHeader))
        return OPEN_FILE_UNKNOWN;

    if (memcmp(m_uFileHeader.easySplitHeader.magic,
               aEasySplitSignature, sizeof(aEasySplitSignature)) == 0)
        return OPEN_FILE_TYPE_ESPLIT;

    return OPEN_FILE_UNKNOWN;
}


/******************************************************************************/
/**
 */
static void utilComplainWrongPart(uint8_t nPart)
{
    const char* apStr[3];

    strcpy(utilStr, "This is not part ");
    utilAppendHex2(nPart + 1);
    utilAppendChar('.');
    apStr[0] = utilStr;
    apStr[1] = "Select the right part.";
    apStr[2] = NULL;

    screenPrintDialog(apStr, BUTTON_ENTER);
}

