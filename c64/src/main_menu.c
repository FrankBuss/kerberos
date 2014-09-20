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
#include "midi_commands.h"

uint8_t* g_ram = (uint8_t*) 0xdf00;
uint8_t g_isC128 = 0;

static void startProgramInSlot(uint8_t slot)
{
	static uint8_t* adr;
	static uint8_t i;
	static uint8_t blocks;
	static uint8_t ramBank;
	static uint8_t flashBank;
	
	// clear MIDI interrupts
	midiIrqNmiTest();

	disableInterrupts();

	// enable ROM at $8000	
	CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW;
	
	FLASH_ADDRESS_EXTENSION = slot * 8;
	adr = (uint8_t*) 0x8000;
	if (adr[0] == 0x42 || 1) {
		cprintf("program size: %i\r\n", adr[0xfc] | (adr[0xfd] << 8));
		cprintf("program start: 0x%04x\r\n", adr[0xfe] | (adr[0xff] << 8));
		cputs("starting program\r\n");
		blocks = adr[0xfd] + 1;
		ramSetBank(0);
		g_ram[0] = adr[0xfc];
		g_ram[1] = adr[0xfd];
		g_ram[2] = adr[0xfe];
		g_ram[3] = adr[0xff];
		ramBank = 1;
		flashBank = slot * 8;
		adr += 256;
		for (i = 0; i < blocks; i++) {
			ramSetBank(ramBank);
			FLASH_ADDRESS_EXTENSION = flashBank;
			memcpy(g_ram, adr, 256);
			adr += 256;
			if (adr == (uint8_t*) 0xa000) {
				adr = (uint8_t*) 0x8000;
				flashBank++;
			}
			ramBank++;
		}
		startProgram();
	}

	// disable ROM at $8000	
	CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;
	
	enableInterrupts();
}

void receiveMidiCommands(void)
{
	static uint8_t b;
	static uint8_t b0;
	static uint8_t b1;
	static uint8_t tag;
	static uint8_t length;
	static uint8_t* adr;
	static uint8_t receivedBytes;
	static uint8_t flashBank;
	showTitle("PC/Mac link");
	cputs("\x1f: back\r\n");
	midiInit();
	
	for (;;) {
		receivedBytes = 0;
		enableInterrupts();
		for (;;) {
			if (kbhit()) {
				cgetc();
				return;
			} else if (midiByteReceived()) {
				b = midiReadByte();
				if ((b & 0xfc) == 0x8c) {
					receivedBytes = 0;
				}
				if (receivedBytes == 2) {
					if ((b0 & 0xfc) == 0x8c) {
						tag = b1;
						length = b;
						if (b0 & 2) tag |= 0x80;
						if (b0 & 1) length |= 0x80;
						break;
					}
				}
				b0 = b1;
				b1 = b;
				receivedBytes++;
			}
		}
		//cprintf("tag: %02x, length: %02x\r\n", tag, length);
		
		// read data
		disableInterrupts();
		if (midiReadCommand(tag, length)) {
			cputs("\r\nchecksum error!\r\n");
			anyKey();
			return;
		}
		//cprintf("read ok\r\n");
		
		// evaluate command
		switch (tag & 0x7f) {
			case MIDI_COMMAND_SET_ADDRESS:
				adr = (uint8_t*) (g_blockBuffer[0] | (g_blockBuffer[1] << 8));
				break;
				
			case MIDI_COMMAND_SET_RAM_BANK:
				ramSetBank(g_blockBuffer[0] | (g_blockBuffer[1] << 8));
				break;
				
			case MIDI_COMMAND_SET_FLASH_BANK:
				flashBank = g_blockBuffer[0];
				flashSetBank(flashBank);
				break;
				
			case MIDI_COMMAND_ERASE_FLASH_SECTOR:
				flashEraseSector(adr);
				break;

			case MIDI_COMMAND_WRITE_FLASH:
				flashWrite256Block(adr);
				FLASH_ADDRESS_EXTENSION = flashBank;
				if (fastCompare256(adr)) {
					cputs("\r\nflash write error!\r\n");
					anyKey();
					return;
				}
				break;

			case MIDI_COMMAND_WRITE_RAM:
				memcpy(adr, g_blockBuffer, length + 1);
				break;
			
			case MIDI_COMMAND_CLEAR_SCREEN:
				clrscr();
				break;
			
			case MIDI_COMMAND_PRINT:
				cputs(g_blockBuffer);
				break;
			
			case MIDI_COMMAND_GOTOX:
				gotox(g_blockBuffer[0]);
				break;
			
			case MIDI_COMMAND_START_SLOT_PROGRAM:
				startProgramInSlot(g_blockBuffer[0]);
				break;

			case MIDI_COMMAND_EXIT:
				anyKey();
				return;

			case MIDI_COMMAND_START_SRAM_PROGRAM:
				ramSetBank(0);
				cprintf("program size: %i\r\n", g_ram[0] | (g_ram[1] << 8));
				cprintf("program start: 0x%04x\r\n", g_ram[2] | (g_ram[3] << 8));
				cputs("starting program\r\n");
				startProgram();
				return;
		}
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
void menuStartProgramInSlot(void)
{
	static uint8_t i;
	static uint8_t j;
	static uint8_t* adr;
	showTitle("start program");
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
				startProgramInSlot(key);
			}
		}
	}
}

void toBasic()
{
	showTitle("back to BASIC");

	// CPLD generated reset for starting c64, with disabled cartridge
	CART_CONFIG = 0;
	CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH | CART_CONTROL_RESET_GENERATE;
	while (1);
}

void showTitle(char* subtitle)
{
	clrscr();
	cputs("Kerberos Menu V0.7 - ");
	cputs(subtitle);
	cputs("\r\n\r\n");
}

int main(void)
{
	*((uint8_t*)1) = 55;
	
	g_isC128 = isC128();
	
	bgcolor(BACKGROUND_COLOR);
	bordercolor(BACKGROUND_COLOR);
	textcolor(TEXT_COLOR);
	gotoxy(0, 0);
	
	for (;;) {
		// disable MIDI
		MIDI_CONFIG = 0;
	
		// standard mode
		CART_CONFIG = 0;
	
		// /GAME high, /EXROM low
		CART_CONTROL = CART_CONTROL_EXROM_LOW | CART_CONTROL_GAME_HIGH;
		
		showTitle("main menu");
		cputs("e: EasyFlash start\r\n");
		cputs("c: connect to PC/Mac over MIDI\r\n");
		cputs("p: program start\r\n");
		cputs("b: back to BASIC\r\n");
		cputs("t: tests\r\n");
		cputs("\r\n");
		if (g_isC128) cputs("C128 computer detected\r\n");
		while (!kbhit());
		switch (cgetc()) {
			case 'e':
				startEasyFlash();
				break;
			case 'c':
				receiveMidiCommands();
				break;
			case 'p':
				menuStartProgramInSlot();
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
