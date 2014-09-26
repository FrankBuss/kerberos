#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <conio.h>
#include <stdlib.h>
#include <cbm.h>

#include "util.h"
#include "regs.h"

uint8_t* g_vicBase = (uint8_t*) 0xd000;
uint8_t* g_sidBase = (uint8_t*) 0xd400;
uint8_t* g_spritePointers = (uint8_t*) 0x7f8;
uint8_t* g_screenRam = (uint8_t*) 0x0400;
uint8_t* g_colorRam = (uint8_t*) 0xd800;

void __fastcall__ musicInit(void);
void __fastcall__ musicPlay(void);
void __fastcall__ waitVsync(void);

#define BACKGROUND_COLOR 5
#define TEXT_COLOR 0
#define CAPTION_COLOR 0

#define SPRITE_LOGO_X 130
#define SPRITE_LOGO_Y 50

/*
import math
cycle=56
ampl=50
[int(math.sin(i/cycle*2*math.pi)*ampl+0.5) for i in range(cycle)]
*/
int sin[] = {
	0, 6, 11, 17, 22, 27, 31, 35, 39, 42, 45, 47, 49, 50, 50,
	50, 49, 47, 45, 42, 39, 35, 31, 27, 22, 17, 11, 6, 0, -5,
	-10, -16, -21, -26, -30, -34, -38, -41, -44, -46, -48, -49,
	-49, -49, -48, -46, -44, -41, -38, -34, -30, -26, -21, -16,
	-10, -5
};

void about(void)
{
	static uint8_t i;
	static uint8_t sinIndex;
	static uint16_t x;
	static uint8_t t;
	static uint8_t color;
	static uint8_t j;
	static uint8_t restartCounter;
	static uint8_t* adr;
	
	// standard mode, disable MIDI
	CART_CONFIG = 0;
	CART_CONTROL = CART_CONTROL_EXROM_LOW | CART_CONTROL_GAME_HIGH;
	MIDI_CONFIG = 0;
	
	clrscr();
	bgcolor(BACKGROUND_COLOR);
	bordercolor(BACKGROUND_COLOR);
	textcolor(TEXT_COLOR);
	gotoxy(13, 24);
	
	cputs("www.frank-buss.de/kerberos\r\n");

	// set sprite pointers (starting at 0x2600)
	for (i = 0; i < 4; i++) g_spritePointers[i] = 152 + i;
	
	// set y-positions
	for (i = 0; i < 4; i++) {
		g_vicBase[i * 2 + 1] = SPRITE_LOGO_Y;
	}
	
	// set logo x-positions
	g_vicBase[0] = SPRITE_LOGO_X;
	g_vicBase[2] = SPRITE_LOGO_X + 48;
	g_vicBase[4] = SPRITE_LOGO_X;
	g_vicBase[6] = SPRITE_LOGO_X + 48;
	
	// first 2 sprites in black
	g_vicBase[0x27] = 0;
	g_vicBase[0x28] = 0;
	
	// second 2 sprites in orange
	g_vicBase[0x29] = 8;
	g_vicBase[0x2a] = 8;
	
	// double size
	g_vicBase[0x17] = 0x0f;
	g_vicBase[0x1d] = 0x0f;
	
	// enable sprites
	g_vicBase[0x15] = 0x0f;
	
	textcolor(TEXT_COLOR);
	gotoxy(0, 6);
	cputs("-= C64/C128 MIDI and flash cartridge =-\r\n");
	cputs("\r\n");
	cputs("   developer: Frank Buss\r\n");
	cputs("   Cynthcart: Paul Slocum\r\n");
	cputs("beta testers: Gert Borovcak\r\n");
	cputs("              Marcel Andre\r\n");
	cputs(" top backers: Benjamin Schneider\r\n");
	cputs("              Bram Crul\r\n");
	cputs("              Dirk Jagdmann\r\n");
	cputs("              freQvibez/Offence!\r\n");
	cputs("              Mads Troest\r\n");
	cputs("              Matt Shively\r\n");
	cputs("              Remute (www.remute.org)\r\n");
	cputs("              Robert Bernardo\r\n");
	cputs("              Ziili/EXT\r\n");
	cputs("  this music: Vomitoxin by Svetlana\r\n");

	musicInit();
	sinIndex = 0;
	t = 0;
	color = 0;
	j = 0;
	restartCounter = 0;
	while (1) {
		x = SPRITE_LOGO_X + sin[sinIndex];
		sinIndex++;
		if (sinIndex == 56) {
			sinIndex = 0;
			t = t + 1;
			if (t == 5) {
				color = 55;
				t = 0;
			}
			restartCounter++;
			if (restartCounter == 83) {
				restartCounter = 0;
				musicInit();
			}
		}

		//__asm__ ("inc $d020");
		musicPlay();
		waitVsync();
		//__asm__ ("dec $d020");
		g_vicBase[0] = x;
		g_vicBase[2] = x + 48;
		g_vicBase[4] = x;
		g_vicBase[6] = x + 48;
		if (color > 0) {
			j = color >> 1;
			if (j > 24) j = 24;
			adr = (uint8_t*) (0xd800 + 40 * j);
			for (i = 0; i < 40; i++) {
				adr[i] = 1;
				if (j < 24) adr[i + 40] = 0;
			}
			if (j > 1 && j < 5) {
				g_vicBase[0x27] = 1;
				g_vicBase[0x28] = 1;
			} else {
				g_vicBase[0x27] = 0;
				g_vicBase[0x28] = 0;
			}
			color--;
		}
		if (kbhit()) {
			for (i = 0; i < 24; i++) g_sidBase[i] = 0;
			g_vicBase[0x15] = 0;
			return;
		}
	}
		
}
