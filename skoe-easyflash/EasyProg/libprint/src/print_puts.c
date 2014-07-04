/*
 * print_puts.c
 *
 *  Created on: 17.03.2011
 *      Author: skoe
 */

#include "print.h"

/*******************************************************************************
 * Print the given string.
 *
 ******************************************************************************/
void __fastcall__ print_puts(const char* text)
{
    char ch;

    while ((ch = *text++))
    {
        print_putc(ch);
    }
}
