/*
 * EasyProg - easyprog.c - The main module
 *
 * (c) 2009 - 2012 Thomas Giesel
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

#include <string.h>

#include "screen.h"
#include "autoinit.h"
#include "filedlg.h"
#include "torturetest.h"
#include "write.h"
#include "util.h"
#include "slots.h"

void autoInit(void)
{
    uint8_t nSlot;

    if (screenAskEraseDialog() != BUTTON_ENTER)
        return;

    tortureTestAuto();
    eraseAll();

    for (nSlot = 0; nSlot < g_nSlots; ++nSlot)
    {
        /* create file name, e.g. auto-0.crt */
        strcpy(utilStr, "auto-");
        utilAppendDecimal(nSlot);
        utilAppendStr(".crt");
        strcpy(g_strFileName, utilStr);
        autoWriteCRTImage(nSlot);
    }
}
