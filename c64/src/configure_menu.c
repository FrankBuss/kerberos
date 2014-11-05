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
#include "kerberos.h"
#include "config.h"

static void incrementDiskNumber(uint8_t id)
{
	uint8_t number = getConfigValue(id);
	number++;
	if (number == 12) number = 8;
	setConfigValue(id, number);
}

void configureSettings(void)
{
	uint8_t slot;
	for (;;) {
		showTitle("Configure Settings");
		cprintf("I: Mirror MIDI in to MIDI thru: %s\r\n", getConfigValue(KERBEROS_CONFIG_MIDI_IN_THRU) ? "on" : "off");
		cprintf("O: Mirror MIDI out to MIDI thru: %s\r\n", getConfigValue(KERBEROS_CONFIG_MIDI_OUT_THRU) ? "on" : "off");
		cprintf("1: Cartridge disk 1 drive number: %i\r\n", getConfigValue(KERBEROS_CONFIG_DRIVE_1));
		cprintf("2: Cartridge disk 2 drive number: %i\r\n", getConfigValue(KERBEROS_CONFIG_DRIVE_2));
		cprintf("A: Autostart slot (0=off): %i\r\n", getConfigValue(KERBEROS_CONFIG_AUTOSTART_SLOT));
		cputs("\r\n");
		cputs("S: Save and back\r\n");
		cputs("\x1f: Back without save\r\n");
		cputs("\r\n");
		cputs("Note: to start the menu when autostart\r\n");
		cputs("is active, hold down \"M\" and press the\r\n");
		cputs("reset button.\r\n");
		while (!kbhit());
		switch (cgetc()) {
			case 'i':
				setConfigValue(KERBEROS_CONFIG_MIDI_IN_THRU, !getConfigValue(KERBEROS_CONFIG_MIDI_IN_THRU));
				break;
			case 'o':
				setConfigValue(KERBEROS_CONFIG_MIDI_OUT_THRU, !getConfigValue(KERBEROS_CONFIG_MIDI_OUT_THRU));
				break;
			case '1':
				incrementDiskNumber(KERBEROS_CONFIG_DRIVE_1);
				break;
			case '2':
				incrementDiskNumber(KERBEROS_CONFIG_DRIVE_2);
				break;
			case 'a':
				slot = getConfigValue(KERBEROS_CONFIG_AUTOSTART_SLOT);
				slot++;
				if (slot == 26) slot = 0;
				setConfigValue(KERBEROS_CONFIG_AUTOSTART_SLOT, slot);
				break;
			case '0':
				setConfigValue(KERBEROS_CONFIG_AUTOSTART_SLOT, 0);
				break;
			case 's':
				saveConfigs();
				return;
			case LEFT_ARROW_KEY:
				loadConfigs();
				return;
		}
	}
}
