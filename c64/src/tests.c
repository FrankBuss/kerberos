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
#include "tests.h"

static uint8_t testRam()
{
	uint16_t i;

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
		if (fastCompare256(g_ram)) {
			gotox(0);
			cprintf("RAM error, bank: %i\r\n", i);
			enableInterrupts();
			return 0;
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
		if (fastCompare256(g_ram)) {
			gotox(0);
			cprintf("RAM error, bank: %i\r\n", i);
			enableInterrupts();
			return 0;
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
		if (fastCompare256(g_ram)) {
			gotox(0);
			cprintf("RAM error, bank: %i\r\n", i);
			enableInterrupts();
			return 0;
		}
	}

	gotox(0);
	cputs("RAM test ok\r\n");
	enableInterrupts();
	return 1;
}

static uint8_t testFlash()
{
	uint16_t i;
	uint8_t j;
	uint8_t* adr;
	uint16_t id;
	uint16_t lastBank = 0;
	disableInterrupts();
	id = flashReadId();
	enableInterrupts();

	cprintf("flash id: 0x%04x\r\n", id);
	if (id != 0xbfc8) {
		cputs("wrong flash id\r\n");
		enableInterrupts();
		return 0;
	}
	cputs("flash id ok\r\n");
	cputs("\r\n");
	lastBank = FLASH_BANKS;

	disableInterrupts();
	cputs("flash 0 test...\r\n");
	memset(g_blockBuffer, 0, 256);
	for (i = 0; i < lastBank; i++) {
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
	for (i = 0; i < lastBank; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 8);
		FLASH_ADDRESS_EXTENSION = i;
		adr = (uint8_t*) 0x8000;
		for (j = 0; j < 32; j++) {
			if (fastCompare256(adr)) {
				gotox(0);
				cprintf("flash error, bank: %i\r\n", i);
				enableInterrupts();
				return 0;
			}
			adr += 0x100;
		}
	}

	gotox(0);
	cputs("flash random test...\r\n");
	srand(1);
	for (i = 0; i < lastBank; i++) {
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
	for (i = 0; i < lastBank; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 8);
		FLASH_ADDRESS_EXTENSION = i;
		adr = (uint8_t*) 0x8000;
		adr = (uint8_t*) 0x8000;
		for (j = 0; j < 32; j++) {
			rand256Block();
			if (fastCompare256(adr)) {
				gotox(0);
				cprintf("flash error, bank: %i\r\n", i);
				enableInterrupts();
				return 0;
			}
			adr += 0x100;
		}
	}

	gotox(0);
	cputs("flash erase test...\r\n");
	for (i = 0; i < lastBank; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 8);
		flashSetBank(i);
		flashEraseSector((uint8_t*) 0x8000);
		flashEraseSector((uint8_t*) 0x9000);
	}

	gotox(0);
	cputs("flash erase verify...\r\n");
	memset(g_blockBuffer, 0xff, 256);
	for (i = 0; i < lastBank; i++) {
		gotox(0);
		cprintf("%i%%", i * 100 >> 8);
		FLASH_ADDRESS_EXTENSION = i;
		adr = (uint8_t*) 0x8000;
		for (j = 0; j < 32; j++) {
			if (fastCompare256(adr)) {
				gotox(0);
				cprintf("flash error, bank: %i\r\n", i);
				enableInterrupts();
				return 0;
			}
			adr += 0x100;
		}
	}

	gotox(0);
	cputs("flash test ok\r\n");
	return 1;
}

static uint8_t testRomAsRamCompare(uint8_t bank, const char* test)
{
	uint8_t* adr = (uint8_t*) (bank << 8);
	ramSetBank(bank);
	memcpy(g_blockBuffer, g_ram, 256);
	if (fastCompare256(adr)) {
		// standard mode
		CART_CONFIG = 0;
		CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;

		gotox(0);
		cprintf("RAM error in bank 0x%04x\r\n", bank);
		cprintf("test: %s\r\n", test);
		enableInterrupts();
		return 0;
	}
	return 1;
}

static uint8_t testRamAsRom()
{
	uint16_t i;

	disableInterrupts();
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
		CART_CONFIG = 0;
		CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;

		gotox(0);
		cprintf("%i%%", i * 100 >> 5);

		// enable special cartridge RAM as ROM mode
		CART_CONFIG = CART_CONFIG_RAM_AS_ROM_ON;
	
		// enable cartridge ROM at $8000 and $a000, which is mapped to the cartridge RAM
		CART_CONTROL = CART_CONTROL_GAME_LOW | CART_CONTROL_EXROM_LOW;

		// test normal cartridge areas
		if (!testRomAsRamCompare(i + 0x80, "0x8000, cartridge mode")) return 0;
		if (!testRomAsRamCompare(i + 0xa0, "0xa000, cartridge mode")) return 0;

		// standard mode
		ramSetBank(0xa0);
		CART_CONFIG = 0;
		CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;

		// enable special cartridge RAM as ROM mode and BASIC hack
		CART_CONFIG = CART_CONFIG_RAM_AS_ROM_ON | CART_CONFIG_BASIC_HACK_ON;
	
		// test BASIC
		if (!testRomAsRamCompare(i + 0xa0, "0xa000, BASIC hack")) return 0;

		// enable special cartridge RAM as ROM mode and KERNAL hack
		CART_CONFIG = CART_CONFIG_RAM_AS_ROM_ON | CART_CONFIG_KERNAL_HACK_ON;
	
		// test KERNAL
		if (!testRomAsRamCompare(i + 0xe0, "0xe000, KERNAL hack")) return 0;

		// C128 has no HIRAM hack
		if (!g_isC128) {
			// enable special cartridge RAM as ROM mode and KERNAL hack with HIRAM hack
			CART_CONFIG = CART_CONFIG_RAM_AS_ROM_ON | CART_CONFIG_KERNAL_HACK_ON | CART_CONFIG_HIRAM_HACK_ON;
		
			// trigger initial HIRAM detection and enable KERNAL
			*((uint8_t*) 1) = 0x37;
	
			// test KERNAL
			if (!testRomAsRamCompare(i + 0xe0, "0xe000, KERNAL/HIRAM hack, ROM")) return 0;
	
			// enable internal C64 RAM under KERNAL
			*((uint8_t*) 1) = 0x35;
	
			// test internal C64 RAM under KERNAL
			ramSetBank(0x100 + i);
			if (memcmp(g_ram, (uint8_t*) ((i + 0xe0) << 8), 256)) {
				*((uint8_t*) 1) = 0x37;
				CART_CONFIG = 0;
				CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;
				gotox(0);
				cprintf("KERNAL HIRAM hack RAM error\r\n");
				cprintf("bank: %i\r\n", i);
				enableInterrupts();
				return 0;
			}
	
			// default value
			*((uint8_t*) 1) = 0x37;
		}
	}
	
	// standard mode
	CART_CONFIG = 0;
	CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;

	gotox(0);
	cputs("RAM as ROM test ok\r\n");
	enableInterrupts();
	return 1;
}
