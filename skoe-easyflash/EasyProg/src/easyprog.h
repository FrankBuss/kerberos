/*
 * EasyProg - easyprog.h - The main module
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
#ifndef EASYPROG_H_
#define EASYPROG_H_

#include <stdint.h>


#ifdef EFDEBUG
#  include "print.h"
#  define debug_init()        print_init()
#  define debug_puts(x)       print_puts(x)
#  define debug_putc(x)       print_putc(x)
#  define debug_crlf()        print_crlf()
#  define debug_hex_digit(x)  print_hex_digit(x)
#  define debug_hex_padded(x,y) print_hex_padded(x,y)
#else
#  define debug_init()        do {} while(0)
#  define debug_puts(x)       do {} while(0)
#  define debug_putc(x)       do {} while(0)
#  define debug_crlf()        do {} while(0)
#  define debug_hex_digit(x)  do {} while(0)
#  define debug_hex_padded(x,y) do {} while(0)
#endif

// If this flag is set in a menu entry, it needs a known flash type
#define EASYPROG_MENU_FLAG_NEEDS_FLASH 1

#define EF_CART_NAME_LEN 16

extern uint8_t g_bFastLoaderEnabled;
extern char g_strCartName[EF_CART_NAME_LEN + 1];


uint8_t checkFlashType(void);
void __fastcall__ setStatus(const char* pStrStatus);
void refreshMainScreen(void);
void refreshElapsedTime(void);
void resetCartInfo(void);

#endif /* EASYPROG_H_ */
