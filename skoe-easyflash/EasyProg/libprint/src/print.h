/*
 * print.h
 *
 *  Created on: 17.03.2011
 *      Author: skoe
 */

#ifndef PRINT_H_
#define PRINT_H_

#include <stdint.h>

void print_init(void);
void __fastcall__ print_putc(uint8_t c);
void __fastcall__ print_puts(const char* text);
void print_crlf(void);
void __fastcall__ print_hex_digit(uint8_t val);
void __fastcall__ print_hex_padded(uint8_t size, uint16_t num);

#endif /* PRINT_H_ */
