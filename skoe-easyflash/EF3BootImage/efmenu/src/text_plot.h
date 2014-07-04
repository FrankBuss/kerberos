
#ifndef _TEXT_PLOT_H_
#define _TEXT_PLOT_H_

#include <stdint.h>
#include <c64.h>

void __fastcall__ text_plot_puts(
        uint8_t x_pos, uint8_t x_offset, uint8_t y_pos,
        const char* str);

void __fastcall__ text_set_line_color(
        uint8_t x_pos, uint8_t y_pos, uint8_t color);

/* Used internally only: */
void __fastcall__ text_plot_str(const char* str);
void __fastcall__ text_fill_line_color(uint16_t len_col);

#endif
