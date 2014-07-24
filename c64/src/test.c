#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <conio.h>
#include <stdlib.h>
#include <cbm.h>

#include "utilasm.h"
#include "midi.h"
#include "regs.h"

#define BACKGROUND_COLOR 0
#define TEXT_COLOR 14
#define CAPTION_COLOR 1

int main(void)
{
	uint16_t i = 0;
	clrscr();
	bgcolor(BACKGROUND_COLOR);
	bordercolor(BACKGROUND_COLOR);
	textcolor(TEXT_COLOR);
	gotoxy(0, 0);
	textcolor(1);
	
	cputs("HIRAM test\r\n");

	// enable special cartridge RAM as ROM mode and KERNAL hack
	CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;
	CART_CONFIG = CART_CONFIG_RAM_ON | CART_CONFIG_RAM_AS_ROM_ON | CART_CONFIG_KERNAL_HACK_ON;
	
	while (1) {
		disableInterrupts();
		*((uint8_t*) 1) = 0x35;
		i += *((uint8_t*) 0xe000);
		*((uint8_t*) 1) = 0x37;
		enableInterrupts();
		gotox(0);
		cprintf("%i", i);
	}

	return 0;
}
