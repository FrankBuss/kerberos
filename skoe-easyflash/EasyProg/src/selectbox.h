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

#ifndef SELECTBOX_H_
#define SELECTBOX_H_

#include <stdint.h>

typedef struct SelectBoxEntry_s {
    char          label[17];     /* Label in PETSCII, 0-terminated */
    void*         cookie;
} SelectBoxEntry;

uint8_t __fastcall__ selectBox(const SelectBoxEntry* pEntries,
                               const char* pStrWhatToSelect);


#endif /* SELECTBOX_H_ */
