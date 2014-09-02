#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <conio.h>
#include <stdlib.h>
#include <cbm.h>

#include "util.h"
#include "midi.h"
#include "regs.h"
#include "menu.h"

uint8_t* g_ram = (uint8_t*) 0xdf00;
uint8_t g_isC128 = 0;

void flashProgram()
{
	uint16_t i;
	uint16_t id = flashReadId();
	uint32_t start = 0;
	uint32_t flash = 0;
	uint16_t size = 0;
	uint8_t blocks = 0;
	uint8_t ramBank = 1;
	uint8_t* adr;
	
	clrscr();
	cprintf("flash id: 0x%04x\r\n", id);
	if (id != 0xbfc8) {
		cputs("wrong flash id\r\n");
		anyKey();
		return;
	}
	cputs("flash id ok\r\n");

	cputs("flash program...\r\n");
	ramSetBank(0);
	size = g_ram[0] | (g_ram[1] << 8);
	start = g_ram[2] | (g_ram[3] << 8) | (((uint32_t)g_ram[4]) << 16) | (((uint32_t)g_ram[5]) << 24);
	flash = start;
	blocks = (size + 255) >> 8;
	for (i = 0; i < blocks; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 / blocks);
		
		// load RAM to block
		ramSetBank(ramBank);
		memcpy(g_blockBuffer, g_ram, 256);

		// set 8 kb bank
		flashSetBank(flash >> 13);
		
		// calculate addr within bank
		adr = (uint8_t*) ((flash & 0x1fff) + 0x8000);

		// erase sector every 4 kb
		if ((flash & 0xfff) == 0) flashEraseSector(adr);
			
		// write 256 block
		flashWrite256Block(adr);

		// next 256 block
		flash += 0x100;
		ramBank++;
	}

	gotox(0);
	cputs("flash program verify...\r\n");
	flash = start;
	ramBank = 1;
	for (i = 0; i < blocks; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 / blocks);
		
		// load RAM to block
		ramSetBank(ramBank);
		memcpy(g_blockBuffer, g_ram, 256);
		
		// set 8 kb bank
		flashSetBank(flash >> 13);
		
		// calculate addr within bank
		adr = (uint8_t*) ((flash & 0x1fff) + 0x8000);

		// compare
		if (flashCompare256Block(adr)) {
			gotox(0);
			cprintf("flash error, bank: %i\r\n", i);
			anyKey();
			return;
		}

		// next 256 block
		flash += 0x100;
		ramBank++;
	}

	gotox(0);
	cputs("flash program ok\r\n");
	anyKey();
}

static uint8_t g_receivedBytes;
static uint8_t g_b;
static uint8_t g_b0;
static uint8_t g_b1;

uint8_t midiWaitAndReceiveByte()
{
	while (!midiByteReceived());
	return midiReadByte();
}

uint8_t midiNextByte(void)
{
	g_b = midiWaitAndReceiveByte();
	if (g_receivedBytes == 0) {
		g_b0 = g_b;
		g_b1 = midiWaitAndReceiveByte();
		if (g_b0 & 2) {
			g_b1 |= 0x80;
		}
		if (g_b0 & 0x4) {
			// two bytes
			g_receivedBytes++;
		} else {
			// one byte, ignore second byte
			midiWaitAndReceiveByte();
		}
	} else {
		// second byte
		g_receivedBytes = 0;
		if (g_b0 & 1) {
			g_b |= 0x80;
		}
		g_b1 = g_b;
	}
	return g_b1;
}

void receiveMidiFile(void)
{
	uint8_t type;
	uint32_t start;
	clrscr();
	midiInit();
	g_receivedBytes = 0;
	cputs("waiting for file, press key to cancel...\r\n");
	for (;;) {
		if (kbhit()) {
			cgetc();
			return;
		} else if (midiByteReceived()) {
			g_b = midiReadByte();
			if (g_b == 0x8c) {
				g_receivedBytes = 0;
			}
			if (g_receivedBytes == 2) {
				if (g_b0 = 0x8c && g_b == 0) {
					type = g_b1;
					break;
				}
			}
			g_b0 = g_b1;
			g_b1 = g_b;
			g_receivedBytes++;
		}
	}

	disableInterrupts();
	ramSetBank(0);
	loadProgram();
	ramSetBank(0);
	cprintf("program size: %i\r\n", g_ram[0] | (g_ram[1] << 8));
	start = g_ram[2] | (g_ram[3] << 8) | (((uint32_t)g_ram[4]) << 16) | (((uint32_t)g_ram[5]) << 24);
	cprintf("program start: 0x%04x\r\n", g_ram[2] | (g_ram[3] << 8));
	switch (type) {
		case 1:
			cputs("program loaded, starting...\r\n");
			startProgram();
			break;
		case 2:
			cputs("file loaded, flashing...\r\n");
			flashProgram();
			break;
	}
}

// flash memory layout:
// 8 slots, slot 0 = menu, slot 1-7 = user PRGs
// slot format:
// magic non-empty byte marker: 0x42
// 249 bytes ASCII filename, zero terminated
// 2 bytes CRC16 checksum of PRG start, length and data
// 2 bytes length of PRG data
// 2 bytes PRG start
// PRG data (starting at 0x100 for each slot)
void startProgramInSlot(void)
{
	uint8_t i;
	uint8_t j;
	uint8_t* adr;
	clrscr();
	
	cputs("Start program with number key:\r\n");
	disableInterrupts();

	// enable ROM at $8000	
	CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW;
	
	for (i = 1; i < 11; i++) {
		// 64 kb per slot
		FLASH_ADDRESS_EXTENSION = i * 8;
		adr = (uint8_t*) 0x8000;
		cprintf("%i: ", i == 10 ? 0 : i);
		if (adr[0] == 0x42) {
			for (j = 1; j < 32; j++) {
				uint8_t b = adr[j];
				if (b == 0) break;
				cputc(ascii2petscii(b));
			}
			cputs("\r\n");
		} else {
			cputs("[empty]\r\n");
		}
	}
	cputs("\x1f: back\r\n");

	// disable ROM at $8000	
	CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;
	
	enableInterrupts();

	for (;;) {
		if (kbhit()) {
			int key = cgetc();
			if (key == LEFT_ARROW_KEY) {
				return;
			}
			key -= '0';
			if (key >= 0 && key <= 9) {
				if (key == 0) key = 10;
				
				// clear MIDI interrupts
				midiIrqNmiTest();

				disableInterrupts();
			
				// enable ROM at $8000	
				CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW;
				
				FLASH_ADDRESS_EXTENSION = key * 8;
				adr = (uint8_t*) 0x8000;
				if (adr[0] == 0x42 || 1) {
					cputs("starting program\r\n");
					flashSetBank(key * 8);
					startProgramFromRom();
				}
			
				// disable ROM at $8000	
				CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;
				
				enableInterrupts();
			}
		}
	}
}

void toBasic()
{
	clrscr();
	
	cputs("back to BASIC\r\n");

	// CPLD generated reset for starting c64, with disabled cartridge
	anyKey();
	CART_CONFIG = 0;
	CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH | CART_CONTROL_RESET_GENERATE;
	while (1);
}

int main(void)
{
	g_isC128 = isC128();
	
	bgcolor(BACKGROUND_COLOR);
	bordercolor(BACKGROUND_COLOR);
	textcolor(TEXT_COLOR);
	gotoxy(0, 0);
	textcolor(1);
	
	for (;;) {
		// disable MIDI
		MIDI_CONFIG = 0;
	
		// standard mode
		CART_CONFIG = 0;
	
		// /GAME high, /EXROM low
		CART_CONTROL = CART_CONTROL_EXROM_LOW | CART_CONTROL_GAME_HIGH;
		
		clrscr();
		if (g_isC128) cputs("C128 computer detected\r\n");
		cputs("Menu V0.7\r\n\r\n");
		cputs("e: start EasyFlash\r\n");
		cputs("r: receive MIDI file\r\n");
		cputs("s: start program\r\n");
		cputs("b: back to BASIC\r\n");
		cputs("t: tests\r\n");
		cputs("\r\n");
		while (!kbhit());
		switch (cgetc()) {
			case 'e':
				startEasyFlash();
				break;
			case 'r':
				receiveMidiFile();
				break;
			case 's':
				startProgramInSlot();
				break;
			case 'b':
				toBasic();
				break;
			case 't':
				testMenu();
				break;
		}
	}
	return 0;
}
