/*
 * EasyProg - text_plot.c - Text Plotter
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


#include <stdint.h>
#include <string.h>
#include <c64.h>
#include "memcfg.h"
#include "text_plot.h"

/* These are also used by text_plot_asm */
uint16_t text_plot_x;
uint8_t* text_plot_addr;


/******************************************************************************/
/**
 * Plot the given 0-terminated string into the bitmap at x_pos/y_pos.
 *
 * No clipping is performed.
 * x_pos/y_pos are the upper left-hand corner of the first character in block
 * coordinates. x_offset is an additional pixel offset 0..7 which is added to
 * the X-Position.
 */
void __fastcall__ text_plot_puts(
        uint8_t x_pos, uint8_t x_offset, uint8_t y_pos,
        const char* str)
{
    text_plot_x = 8 * x_pos + x_offset;
    text_plot_addr = P_GFX_BITMAP + y_pos * 320 + x_pos * 8;
    text_plot_str(str);
}

/******************************************************************************/
/**
 * Set the color of 16 blocks at position x/y.
 */
void __fastcall__ text_set_line_color(
        uint8_t x_pos, uint8_t y_pos, uint8_t color)
{
    text_plot_addr = P_GFX_COLOR + y_pos * 40 + x_pos;
    text_fill_line_color((16 << 8) | color);
}

