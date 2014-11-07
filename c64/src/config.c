#include <stdio.h>
#include <string.h>

#include "regs.h"
#include "config.h"
#include "util.h"
#include "crc8.h"

static uint8_t g_configs[256];

static uint8_t calculateChecksum()
{
	uint8_t i;
	crc8Init();
	for (i = 0; i < 255; i++) crc8Update(g_configs[i]);
	return crc8Get();
}

void loadConfigs(void)
{
	uint8_t checksum;
	uint8_t i;
	
	// standard mode
	CART_CONFIG = 0;
	
	// /GAME high, /EXROM low
	CART_CONTROL = CART_CONTROL_EXROM_LOW | CART_CONTROL_GAME_HIGH;

	// settings start at 0xb000 in flash, flash bank 5 maps 0xa000-0xbfff to 0x8000-0x9fff
	FLASH_ADDRESS_EXTENSION = 5;
	memcpy(g_configs, (uint8_t*) 0x9000, 0x100);
	
	// if wrong checksum, use defaults
	checksum = calculateChecksum();
	if (checksum != g_configs[255]) {
		for (i = 0; i < 255; i++) g_configs[i] = 255;
	}
}

uint8_t saveConfigs(void)
{
	uint8_t* adr = (uint8_t*) 0x9000;
	g_configs[255] = calculateChecksum();
	flashSetBank(5);
	flashEraseSector(adr);
	memcpy(g_blockBuffer, g_configs, 0x100);
	flashWrite256Block(adr);
	FLASH_ADDRESS_EXTENSION = 5;
	return fastCompare256(adr) == 0;
}

uint8_t getConfigValue(uint8_t key)
{
	uint8_t i = 0;
	for (i = 0; i < 253; i += 2) {
		uint8_t k = g_configs[i];
		if (k == 0xff) {
			switch (key) {
				case KERBEROS_CONFIG_MIDI_IN_THRU:
					return 1;
				case KERBEROS_CONFIG_MIDI_OUT_THRU:
					return 0;
				case KERBEROS_CONFIG_AUTOSTART_SLOT:
					return 0;
				case KERBEROS_CONFIG_DRIVE_1:
					return 9;
				case KERBEROS_CONFIG_DRIVE_2:
					return 10;
			}
			return 0;
		}
		if (k == key) {
			return g_configs[i + 1];
		}
	}
	return 0;
}

void setConfigValue(uint8_t key, uint8_t value)
{
	uint8_t i = 0;
	for (i = 0; i < 253; i += 2) {
		uint8_t k = g_configs[i];
		if (k == 0xff) {
			g_configs[i] = key;
			g_configs[i + 1] = value;
			break;
		}
		if (k == key) {
			g_configs[i + 1] = value;
			break;
		}
	}
}
