/*
 * EasyProg - texts.c - Texts
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

#include "texts.h"


const char* apStrLowHigh[] =
{
        "Low",
        "High"
};

const char* apStrAbout[] =
{
        "",
        "",
        "",
        "Version " EFVERSION,
        "",
        "(C) Thomas 'skoe' Giesel",
        "under zlib license",
        "",
        "(compiled: " __DATE__ " " __TIME__ ")",
        NULL
};

const char* apStrUnsupportedCRTType[] =
{
        "Sorry, this CRT file type",
        "is not supported.",
        NULL
};

const char* apStrUnsupportedCRTData[] =
{
        "Sorry, this CRT file contains",
        "unsupported chip data.",
        NULL
};

const char* apStrFileTooShort[] =
{
        "This file seems to be",
        "too short.",
        NULL
};

const char* apStrFileNoEasySplit[] =
{
        "This is not an EasySplit file",
        "or it is damaged.",
        NULL
};

const char* apStrWrongFlash[] =
{
        "A flash chip does not work",
        "or is not supported by the",
        "EasyAPI flash driver.",
        NULL
};

const char* apStrBadRAM[] =
{
        "There is no EasyFlash attached",
        "or the cartridge RAM at $DF00",
        "does not work correctly.",
        NULL
};

const char* apStrROMLProtected[] =
{
        "The ROML flash chip is",
        "write protected. It can be",
        "unlocked with programming",
        "equipment only.",
        NULL
};

const char* apStrROMHProtected[] =
{
        "The ROMH flash chip is",
        "write protected. It can be",
        "unlocked with programming",
        "equipment only.",
        NULL
};

const char* apStrAskErase[] =
{
        "This will erase the current",
        "flash content! Are you sure?",
        "Press <Stop> to cancel,",
        "<Enter> to continue.",
        NULL
};

const char* apStrSlot0[] =
{
        "Slot 0 usually contains the",
        "system menu. Are you sure",
        "that you want to overwrite it?",
        "Press <Stop> to cancel,",
        "<Enter> to continue.",
        NULL
};

const char* apStrSlot0NoDir[] =
{
        "This entry cannot",
        "be modified.",
        NULL
};

const char* apStrEraseFailed[] =
{
        "Flash erase failed,",
        "check your hardware.",
        NULL
};

const char* apStrFlashWriteFailed[] =
{
        "Write to flash failed,",
        "check your hardware.",
        NULL
};

const char* apStrFileOpenError[] =
{
        "Cannot open this file.",
        NULL
};

const char* apStrOutOfMemory[] =
{
        "Out of memory.",
        NULL
};

const char* apStrHeaderReadError[] =
{
        "Failed to read the cartridge",
        "header. The file seems to",
        "have a wrong type or may",
        "be damaged.",
        NULL
};

const char* apStrChipReadError[] =
{
        "Failed to read cartridge",
        "data. The file seems to",
        "have a wrong type or may",
        "be damaged.",
        NULL
};

const char* apStrWriteComplete[] =
{
        "Congratulations!",
        "Writing to flash completed.",
        NULL
};

const char* apStrEAPIInvalid[] =
{
        "The EasyAPI driver on",
        "disk is invalid.",
        NULL
};

const char* pStrTestFailed = "Test failed";

const char* apStrDirFull[] =
{
        "There are too many entries",
        "in this directory. Some",
        "may be missing.",
        NULL
};

const char* apStrTestEndless[] =
{
        "This test runs endlessly.",
        "It will show a message",
        "if a problem occurs.",
        "After loop 0 the test has passed.",
        "You can cancel it with <Stop>.",
        NULL
};

const char* apStrDifferentFile[] =
{
        "This part doesn't fit to",
        "the previous parts of the",
        "file.",
        NULL
};

/*
const char* apStrFlashFromUSB[] =
{
        "Do you want to write",
        "a cartridge file from USB?",
        NULL
};
*/
