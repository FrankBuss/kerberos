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
	uint16_t id = 0;
	clrscr();
	bgcolor(BACKGROUND_COLOR);
	bordercolor(BACKGROUND_COLOR);
	textcolor(TEXT_COLOR);
	gotoxy(0, 0);
	textcolor(1);
	
	while (1) {
		id = flashReadId();
		gotoxy(0, 0);
		cprintf("flash id: 0x%04x\r\n", id);
	}

	return 0;
}
