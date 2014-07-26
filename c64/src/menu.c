#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <conio.h>
#include <stdlib.h>
#include <cbm.h>

#include "utilasm.h"
#include "midi.h"
#include "regs.h"

#define FLASH_BANKS 256

#define BACKGROUND_COLOR 0
#define TEXT_COLOR 14
#define CAPTION_COLOR 1

#define LEFT_ARROW_KEY 0x5f

uint8_t* g_ram = (uint8_t*) 0xdf00;

uint8_t g_isC128 = 0;

void ramSetBank(uint16_t bank)
{
	// A16
	uint8_t control = 0;
	if (bank & 256) control |= ADDRESS_EXTENSION2_RAM_A16;
	ADDRESS_EXTENSION2 = control;
	
	// A15..A8
	RAM_ADDRESS_EXTENSION = bank & 0xff;
}

void anyKey()
{
	// clear keyboard buffer
	while (kbhit()) cgetc();
	
	// wait for key
	cputs("press any key\r\n");
	while (!kbhit());
	cgetc();
}

void testRam()
{
	uint16_t i;

	clrscr();
	cputs("RAM 0xff test...\r\n");
	memset(g_blockBuffer, 0xff, 256);
	for (i = 0; i < 512; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 9);
		ramSetBank(i);
		memcpy(g_ram, g_blockBuffer, 256);
	}
	
	gotox(0);
	cputs("RAM 0xff verify...\r\n");
	srand(1);
	for (i = 0; i < 512; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 9);
		ramSetBank(i);
		if (memcmp(g_ram, g_blockBuffer, 256)) {
			gotox(0);
			cprintf("RAM error, bank: %i\r\n", i);
			anyKey();
			return;
		}
	}

	gotox(0);
	cputs("RAM random test...\r\n");
	srand(1);
	for (i = 0; i < 512; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 9);
		ramSetBank(i);
		rand256Block();
		memcpy(g_ram, g_blockBuffer, 256);
	}
	
	gotox(0);
	cputs("RAM random verify...\r\n");
	srand(1);
	for (i = 0; i < 512; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 9);
		ramSetBank(i);
		rand256Block();
		if (memcmp(g_ram, g_blockBuffer, 256)) {
			gotox(0);
			cprintf("RAM error, bank: %i\r\n", i);
			anyKey();
			return;
		}
	}

	gotox(0);
	cputs("RAM 0 test...\r\n");
	memset(g_blockBuffer, 0, 256);
	for (i = 0; i < 512; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 9);
		ramSetBank(i);
		memcpy(g_ram, g_blockBuffer, 256);
	}
	
	gotox(0);
	cputs("RAM 0 verify...\r\n");
	srand(1);
	for (i = 0; i < 512; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 9);
		ramSetBank(i);
		if (memcmp(g_ram, g_blockBuffer, 256)) {
			gotox(0);
			cprintf("RAM error, bank: %i\r\n", i);
			anyKey();
			return;
		}
	}

	gotox(0);
	cputs("RAM test ok\r\n");
	anyKey();
}

void testFlash()
{
	uint16_t i;
	uint8_t j;
	uint8_t* adr;
	uint16_t id = flashReadId();
	clrscr();
	cprintf("flash id: 0x%04x\r\n", id);
	if (id != 0xbfc8) {
		cputs("wrong flash id\r\n");
		anyKey();
		return;
	}
	cputs("flash id ok\r\n");

	gotox(0);
	cputs("flash 0 test...\r\n");
	memset(g_blockBuffer, 0, 256);
	for (i = 0; i < FLASH_BANKS; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 8);
		flashSetBank(i);
		adr = (uint8_t*) 0x8000;
		flashEraseSector(adr);
		for (j = 0; j < 16; j++) {
			flashWrite256Block(adr);
			adr += 0x100;
		}
		flashEraseSector(adr);
		for (j = 0; j < 16; j++) {
			flashWrite256Block(adr);
			adr += 0x100;
		}
	}

	gotox(0);
	cputs("flash 0 verify...\r\n");
	for (i = 0; i < FLASH_BANKS; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 8);
		flashSetBank(i);
		adr = (uint8_t*) 0x8000;
		for (j = 0; j < 32; j++) {
			if (flashCompare256Block(adr)) {
				gotox(0);
				cprintf("flash error, bank: %i\r\n", i);
				anyKey();
				return;
			}
			adr += 0x100;
		}
	}

	gotox(0);
	cputs("flash random test...\r\n");
	srand(1);
	for (i = 0; i < FLASH_BANKS; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 8);
		flashSetBank(i);
		adr = (uint8_t*) 0x8000;
		flashEraseSector(adr);
		for (j = 0; j < 16; j++) {
			rand256Block();
			flashWrite256Block(adr);
			adr += 0x100;
		}
		flashEraseSector(adr);
		for (j = 0; j < 16; j++) {
			rand256Block();
			flashWrite256Block(adr);
			adr += 0x100;
		}
	}

	gotox(0);
	cputs("flash random verify...\r\n");
	srand(1);
	for (i = 0; i < FLASH_BANKS; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 8);
		flashSetBank(i);
		adr = (uint8_t*) 0x8000;
		for (j = 0; j < 32; j++) {
			rand256Block();
			if (flashCompare256Block(adr)) {
				gotox(0);
				cprintf("flash error, bank: %i\r\n", i);
				anyKey();
				return;
			}
			adr += 0x100;
		}
	}

	gotox(0);
	cputs("flash erase test...\r\n");
	for (i = 0; i < FLASH_BANKS; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 8);
		flashSetBank(i);
		flashEraseSector((uint8_t*) 0x8000);
		flashEraseSector((uint8_t*) 0x9000);
	}

	gotox(0);
	cputs("flash erase verify...\r\n");
	memset(g_blockBuffer, 0xff, 256);
	for (i = 0; i < FLASH_BANKS; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 8);
		flashSetBank(i);
		adr = (uint8_t*) 0x8000;
		for (j = 0; j < 32; j++) {
			if (flashCompare256Block(adr)) {
				gotox(0);
				cprintf("flash error, bank: %i\r\n", i);
				anyKey();
				return;
			}
			adr += 0x100;
		}
	}

	gotox(0);
	cputs("flash test ok\r\n");
	anyKey();
}

void testMidi()
{
	uint8_t midiThruOut = 0;
	uint8_t midiThruIn = 0;
	uint8_t config = 0;
	clrscr();
	if (!midiIrqNmiTest()) {
		cputs("MIDI IRQ not working\r\n");
		anyKey();
		return;
	}
	midiInit();
	
	cputs("MIDI menu\r\n");
	cputs("n: send note on\r\n");
	cputs("f: send note off\r\n");
	cputs("i: MIDI thru in setting\r\n");
	cputs("o: MIDI thru out setting\r\n");
	cputs("\x1f: back\r\n");
	cputs("\r\n");

	for (;;) {
		config = MIDI_CONFIG_ENABLE_ON | MIDI_CONFIG_NMI_ON;
		if (midiThruIn) config |= MIDI_CONFIG_THRU_IN_ON;
		if (midiThruOut) config |= MIDI_CONFIG_THRU_OUT_ON;
		MIDI_CONFIG = config;

		if (kbhit()) {
			switch (cgetc()) {
				case 'n':
					// note on, note 60, velocity 100
					cputs("sending note on\r\n");
					midiSendByte(0x90);
					midiSendByte(60);
					midiSendByte(100);
					break;
				
				case 'f':
					// note off
					cputs("sending note off\r\n");
					midiSendByte(0x80);
					midiSendByte(60);
					midiSendByte(0);
					break;
				
				case 'i':
					midiThruIn = !midiThruIn;
					cprintf("MIDI thru in setting: %s\r\n", midiThruIn ? "on" : "off");
					break;

				case 'o':
					midiThruOut = !midiThruOut;
					cprintf("MIDI thru out setting: %s\r\n", midiThruOut ? "on" : "off");
					break;

				case LEFT_ARROW_KEY:  // left arrow
					return;
			}
		} else if (midiByteReceived()) {
			cprintf("MIDI-in: %02x\r\n", midiReadByte());
		}
	}
}

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

uint8_t testRomAsRamCompare(uint8_t bank, const char* test)
{
	uint8_t* adr = (uint8_t*) (bank << 8);
	ramSetBank(bank);
	memcpy(g_blockBuffer, g_ram, 256);
	if (memcmp(adr, g_blockBuffer, 256)) {
		// standard mode
		CART_CONFIG = CART_CONFIG_RAM_ON;
		CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;

		gotox(0);
		cprintf("RAM error in bank 0x%02x\r\n", bank);
		cprintf("test: %s\r\n", test);
		enableInterrupts();
		anyKey();
		return 0;
	}
	return 1;
}

void testRamAsRom()
{
	uint16_t i;

	disableInterrupts();
	clrscr();
	cputs("write random data in RAM...\r\n");
	
	// fill external RAM for ROM hack test
	srand(1);
	for (i = 0; i < 256; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 8);
		rand256Block();
		ramSetBank(i);
		memcpy(g_ram, g_blockBuffer, 256);
	}

	// fill external RAM and copy to internal C64 RAM for HIRAM test
	for (i = 0; i < 32; i++) {
		rand256Block();
		ramSetBank(i + 0x100);
		memcpy(g_ram, g_blockBuffer, 256);
		memcpy((uint8_t*) ((i + 0xe0) << 8), g_blockBuffer, 256);
	}

	gotox(0);
	cputs("verify...\r\n");
	for (i = 0; i < 32; i++) {
		// standard mode
		CART_CONFIG = CART_CONFIG_RAM_ON;
		CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;

		gotox(0);
		cprintf("%i%%", i * 100 >> 5);

		// enable special cartridge RAM as ROM mode
		CART_CONFIG = CART_CONFIG_RAM_ON | CART_CONFIG_RAM_AS_ROM_ON;
	
		// enable cartridge ROM at $8000 and $a000, which is mapped to the cartridge RAM
		CART_CONTROL = CART_CONTROL_GAME_LOW | CART_CONTROL_EXROM_LOW;

		// test normal cartridge areas
		if (!testRomAsRamCompare(i + 0x80, "0x8000, cartridge mode")) return;
		if (!testRomAsRamCompare(i + 0xa0, "0xa000, cartridge mode")) return;

		// standard mode
		ramSetBank(0xa0);
		CART_CONFIG = CART_CONFIG_RAM_ON;
		CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;

		// enable special cartridge RAM as ROM mode and BASIC hack
		CART_CONFIG = CART_CONFIG_RAM_ON | CART_CONFIG_RAM_AS_ROM_ON | CART_CONFIG_BASIC_HACK_ON;
	
		// test BASIC
		if (!testRomAsRamCompare(i + 0xa0, "0xa000, BASIC hack")) return;

		// enable special cartridge RAM as ROM mode and KERNAL hack
		CART_CONFIG = CART_CONFIG_RAM_ON | CART_CONFIG_RAM_AS_ROM_ON | CART_CONFIG_KERNAL_HACK_ON;
	
		// test KERNAL
		if (!testRomAsRamCompare(i + 0xe0, "0xe000, KERNAL hack")) return;

		// C128 has no HIRAM hack
		if (!g_isC128) {
			// enable special cartridge RAM as ROM mode and KERNAL hack with HIRAM hack
			CART_CONFIG = CART_CONFIG_RAM_ON | CART_CONFIG_RAM_AS_ROM_ON | CART_CONFIG_KERNAL_HACK_ON | CART_CONFIG_HIGHRAM_HACK_ON;
		
			// trigger initial highram detection and enable KERNAL
			*((uint8_t*) 1) = 0x37;
	
			// test KERNAL
			if (!testRomAsRamCompare(i + 0xe0, "0xe000, KERNAL/HIRAM hack, ROM")) return;
	
			// enable internal C64 RAM under KERNAL
			*((uint8_t*) 1) = 0x35;
	
			// test internal C64 RAM under KERNAL
			ramSetBank(0x100 + i);
			if (memcmp(g_ram, (uint8_t*) ((i + 0xe0) << 8), 256)) {
				*((uint8_t*) 1) = 0x37;
				CART_CONFIG = CART_CONFIG_RAM_ON;
				CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;
				enableInterrupts();
				gotox(0);
				cprintf("KERNAL HIGHRAM hack RAM error\r\n");
				cprintf("bank: %i\r\n", i);
				anyKey();
				return;
			}
	
			// default value
			*((uint8_t*) 1) = 0x37;
		}
	}
	
	// standard mode
	CART_CONFIG = CART_CONFIG_RAM_ON;
	CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;

	gotox(0);
	cputs("RAM as ROM test ok\r\n");
	enableInterrupts();
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
	
	for (i = 1; i < 8; i++) {
		// 64 kb per slot
		FLASH_ADDRESS_EXTENSION = i * 8;
		adr = (uint8_t*) 0x8000;
		cprintf("%i: ", i);
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
			uint8_t key = cgetc();
			if (key == LEFT_ARROW_KEY) {
				return;
			}
			key -= '0';
			if (key >= 1 && key <= 7) {
				disableInterrupts();
			
				// enable ROM at $8000	
				CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW;
				
				FLASH_ADDRESS_EXTENSION = key * 8;
				adr = (uint8_t*) 0x8000;
				if (adr[0] == 0x42 || 1) {
					cputs("starting program\r\n");
					flashSetBank(key * 8);
/*					cprintf("$80fc: %02x\r\n", adr[0xfc]);
					cprintf("$80fd: %02x\r\n", adr[0xfd]);
					cprintf("$80fe: %02x\r\n", adr[0xfe]);
					cprintf("$80ff: %02x\r\n", adr[0xff]);
					anyKey();*/
					startProgramFromRom();
				}
			
				// disable ROM at $8000	
				CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;
				
				enableInterrupts();
			}
		}
	}
}

void c128Test()
{
	// CC65 bug? cart128Start doesn't work
	uint8_t* start = (uint8_t*) 0x8000;
	uint16_t size = ((uint16_t) cart128EndPtr) - ((uint16_t) start);
	uint16_t i;
	
	clrscr();
	
	cputs("C128 test...\r\n");

	// clear id for the two autostart ROMs in RAM
	memset(g_blockBuffer, 0xff, 256);
	ramSetBank(0x80);
	memcpy(g_ram, g_blockBuffer, 256);
	ramSetBank(0xc0);
	memcpy(g_ram, g_blockBuffer, 256);

	// copy 128 catridge code to RAM at $8000
	cputs("copy cartridge code and start C128...\r\n");
	for (i = 0; i < size; i++) {
		uint16_t target = ((uint16_t) start) + i;
		if ((target & 0xff) == 0) {
			ramSetBank(target >> 8);
		}
		g_ram[target & 0xff] = cart128Load[i];
	}
	
	// CPLD generated reset for starting C128, with RAM as ROM enabled
	anyKey();
	CART_CONFIG = CART_CONFIG_RAM_ON | CART_CONFIG_RAM_AS_ROM_ON;
	CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH | CART_CONTROL_RESET_GENERATE;
	while (1);
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
	
		// enable RAM
		CART_CONFIG = CART_CONFIG_RAM_ON;
	
		// /GAME high, /EXROM low
		CART_CONTROL = CART_CONTROL_EXROM_LOW | CART_CONTROL_GAME_HIGH;
		
		clrscr();
		if (g_isC128) cputs("C128 computer detected\r\n");
		cputs("Menu V0.6\r\n");
		cputs("r: ram test\r\n");
		cputs("f: flash test\r\n");
		cputs("m: MIDI test\r\n");
		cputs("o: RAM as ROM tests\r\n");
		cputs("e: start EasyFlash\r\n");
		cputs("v: receive MIDI file\r\n");
		cputs("s: start program\r\n");
		if (g_isC128) cputs("8: C128 test\r\n");
		cputs("b: back to BASIC\r\n");
		cputs("\r\n");
		while (!kbhit());
		switch (cgetc()) {
			case 'r':
				testRam();
				break;
			case 'f':
				testFlash();
				break;
			case 'm':
				testMidi();
				break;
			case 'o':
				testRamAsRom();
				break;
			case 'e':
				startEasyFlash();
				break;
			case 'v':
				receiveMidiFile();
				break;
			case 's':
				startProgramInSlot();
				break;
			case '8':
				c128Test();
				break;
			case 'b':
				toBasic();
				break;
		}
	}
	return 0;
}
