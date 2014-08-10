#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <conio.h>
#include <stdlib.h>
#include <cbm.h>

#include "utilasm.h"
#include "midi.h"
#include "regs.h"

uint8_t* g_vicBase = (uint8_t*) 0xd000;
uint8_t* g_spritePointers = (uint8_t*) 0x7f8;
uint8_t* g_screenRam = (uint8_t*) 0x0400;
uint8_t* g_colorRam = (uint8_t*) 0xd800;

#define BACKGROUND_COLOR 5
#define TEXT_COLOR 0
#define CAPTION_COLOR 1

#define SPRITE_LOGO_X 130
#define SPRITE_LOGO_Y 50

#define SPRITE_QR_X 15
#define SPRITE_QR_Y 169

void startProgramInSlot(uint8_t slot)
{
	uint16_t i = 0;
	
	cputs("starting program...");

	// clear MIDI interrupts
	midiIrqNmiTest();

	disableInterrupts();

	// enable ROM at $8000	
	CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW;

	FLASH_ADDRESS_EXTENSION = slot * 8;
	flashSetBank(slot * 8);
	startProgramFromRom();
}

void initMidiDatel(void)
{
	MIDI_CONFIG = MIDI_CONFIG_IRQ_ON | MIDI_CONFIG_CLOCK_2_MHZ | MIDI_CONFIG_ENABLE_ON;
	MIDI_ADDRESS = 0x46;
}

int main(void)
{
	uint8_t i;
	uint8_t y;

	// standard mode
	CART_CONFIG = 0;
	
	// /GAME high, /EXROM low
	CART_CONTROL = CART_CONTROL_EXROM_LOW | CART_CONTROL_GAME_HIGH;
	
	clrscr();
	bgcolor(BACKGROUND_COLOR);
	bordercolor(BACKGROUND_COLOR);
	textcolor(TEXT_COLOR);
	gotoxy(13, 24);
	
	cputs("www.frank-buss.de/kerberos\r\n");

	// set sprite pointers (starting at 0x2000)
	for (i = 0; i < 8; i++) g_spritePointers[i] = 128 + i;
	
	// set y-positions
	for (i = 0; i < 4; i++) {
		g_vicBase[i * 2 + 1] = SPRITE_LOGO_Y;
	}
	
	// set logo x-positions
	g_vicBase[0] = SPRITE_LOGO_X;
	g_vicBase[2] = SPRITE_LOGO_X + 48;
	g_vicBase[4] = SPRITE_LOGO_X;
	g_vicBase[6] = SPRITE_LOGO_X + 48;
	
	// set QR positions
	g_vicBase[0x10] = 0xf0;
	g_vicBase[8] = SPRITE_QR_X;
	g_vicBase[9] = SPRITE_QR_Y;
	g_vicBase[10] = SPRITE_QR_X + 48;
	g_vicBase[11] = SPRITE_QR_Y;
	g_vicBase[12] = SPRITE_QR_X;
	g_vicBase[13] = SPRITE_QR_Y + 42;
	g_vicBase[14] = SPRITE_QR_X + 48;
	g_vicBase[15] = SPRITE_QR_Y + 42;
	
	// QR background
	for (y = 14; y < 23; y++) {
		for (i = 0; i < 9; i++) {
			uint16_t pos = i + 30 + y * 40;
			g_screenRam[pos] = 128 + 32;
			g_colorRam[pos] = 1;
		}
	}
	
	// first 2 sprites in black
	g_vicBase[0x27] = 0;
	g_vicBase[0x28] = 0;
	
	// second 2 sprites in orange
	g_vicBase[0x29] = 8;
	g_vicBase[0x2a] = 8;
	
	// QR sprites in black
	g_vicBase[0x2b] = 0;
	g_vicBase[0x2c] = 0;
	g_vicBase[0x2d] = 0;
	g_vicBase[0x2e] = 0;

	// double size
	g_vicBase[0x17] = 0xff;
	g_vicBase[0x1d] = 0xff;
	
	// enable sprites
	g_vicBase[0x15] = 0xff;
	
	textcolor(TEXT_COLOR);
	gotoxy(0, 6);
	cputs("-= C64/C128 MIDI and flash cartridge =-\r\n");
	cputs("\r\n");
	cputs("Press a number:\r\n");
	cputs("\r\n");
	textcolor(CAPTION_COLOR);
	cputs("0: Prince of Persia (EasyFlash mode)\r\n");
	cputs("1: Tetris\r\n");
	cputs("2: Joe Gunn\r\n");
	cputs("3: Flappy Bird\r\n");
	cputs("\r\n");
	cputs("4: Cynthcart\r\n");
	cputs("5: Steinberg Pro 16\r\n");
	cputs("6: SID Wizard\r\n");
	cputs("7: MIDI demo program\r\n");
	cputs("\r\n");
	cputs("8: C64 BASIC\r\n");
	cputs("9: C128 BASIC\r\n");
	while (1) {
		while (!kbhit());
		switch (cgetc()) {
			case '0':
				startEasyFlash();
				break;
			case '1':
				startProgramInSlot(3);
				break;
			case '2':
				startProgramInSlot(1);
				break;
			case '3':
				startProgramInSlot(2);
				break;
			case '4':
				initMidiDatel();
				startProgramInSlot(4);
				break;
			case '5':
				initMidiDatel();
				startProgramInSlot(5);
				break;
			case '6':
				initMidiDatel();
				startProgramInSlot(6);
				break;
			case '7':
				startProgramInSlot(7);
				break;
			case '8':
				CART_CONFIG = 0;
				CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;
				__asm__("jmp ($fffc)");
				break;
			case '9':
				CART_CONFIG = 0;
				CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH | CART_CONTROL_RESET_GENERATE;
				while (1);
				break;
		}
	}

	return 0;
}
