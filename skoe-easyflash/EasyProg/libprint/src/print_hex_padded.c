/*
 * print_puts.c
 *
 *  Created on: 17.03.2011
 *      Author: skoe
 */

#include "print.h"

/*******************************************************************************
 * Print the given number in hex format. Fill up leading '0' on the left side
 * to get at least size digits.
 * If more then size digits are needed, use more.
 *
 ******************************************************************************/
void __fastcall__ print_hex_padded(uint8_t size, uint16_t num)
{
    uint8_t i;
    uint16_t tmp;

    // always print at least one digit
    if (size < 1)
        size = 1;

    for (i = 4; i != 0; i--)
    {
        tmp = (num & 0xf000) >> 12;

        if (tmp || i <= size)
        {
            print_hex_digit(tmp);

            // a digit != 0 was found, print all digits from now
            size = i;
        }

        num <<= 4;
    }
}
