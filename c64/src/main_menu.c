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
#include "floppy.h"

extern void about(void);

uint8_t* g_vicBase = (uint8_t*) 0xd000;
uint8_t* g_sidBase = (uint8_t*) 0xd400;
uint8_t* g_ram = (uint8_t*) 0xdf00;
uint8_t g_isC128 = 0;
const char g_kerberosPrgSlotId[16] = KERBEROS_PRG_SLOT_ID;
int g_lastByte;

static uint8_t g_crc;
static uint8_t* adr;
static uint8_t receivedBytes;
static uint8_t flashBank;
static uint8_t startX;
static uint8_t startY;
static uint8_t drive;
static uint8_t number;
static uint16_t block;
static uint8_t track;
static uint8_t sector;

void crc8Init()
{
	g_crc = 0xff;
}

uint8_t crc8Update(uint8_t data)
{
	g_crc = g_crc8Table[data ^ g_crc];
	return g_crc;
}

static uint8_t isValidSlotId()
{
	return memcmp(g_kerberosPrgSlotId, (uint8_t*) 0x8000, 16) == 0;
}

static void copyRomReplacement(uint8_t* dst, uint8_t* src)
{
	uint8_t i;
	uint16_t ramBank;
	uint8_t* adr = (uint8_t*) 0x8000;
	FLASH_ADDRESS_EXTENSION = ((uint16_t) src) >> 13;
	ramBank = ((uint16_t) dst) >> 8;
	for (i = 0; i < 32; i++) {
		ramSetBank(ramBank);
		memcpy(g_ram, adr, 0x100);
		adr += 0x100;
		ramBank++;
	}
}

static void c128startProgramInSram()
{
	// CC65 bug? cart128Start doesn't work
	uint8_t* start = (uint8_t*) 0x8000;
	uint16_t size = ((uint16_t) cart128EndPtr) - ((uint16_t) start);
	uint16_t i;
	
	// copy 128 catridge code to RAM at $8000
	for (i = 0; i < size; i++) {
		uint16_t target = ((uint16_t) start) + i;
		if ((target & 0xff) == 0) {
			ramSetBank(target >> 8);
		}
		g_ram[target & 0xff] = cart128Load[i];
	}
	
	// CPLD generated reset for starting C128, with RAM as ROM enabled
	CART_CONFIG = CART_CONFIG_RAM_AS_ROM_ON;
	CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH | CART_CONTROL_RESET_GENERATE;
	while (1);
}

static void filterHiramHack(void)
{
	if (g_isC128) {
		g_ram[((uint16_t)(&CART_CONFIG)) - 0xde00] &= ~CART_CONFIG_HIRAM_HACK_ON;
	}
}

static void startProgramInSram(void)
{
	static uint8_t controlByte;
	static uint8_t i;
	clrscr();
	ramSetBank(256);
	controlByte = g_ram[0x30];
	for (i = 0; i < 32; i++) {
		uint8_t b = g_ram[i + 0x10];
		if (b == 0) break;
		cputc(ascii2petscii(b));
	}
	cprintf("\r\n\r\nload address: 0x%04x\r\n", g_ram[0x40] | (g_ram[0x41] << 8));
	cprintf("start address: 0x%04x\r\n", g_ram[0x42] | (g_ram[0x43] << 8));
	cprintf("length: %u\r\n", g_ram[0x44] | (g_ram[0x45] << 8));
	cprintf("MIDI_ADDRESS: %02x\r\n", g_ram[((uint16_t)(&MIDI_ADDRESS)) - 0xde00]);
	cprintf("MIDI_CONFIG: %02x\r\n", g_ram[((uint16_t)(&MIDI_CONFIG)) - 0xde00]);
	cprintf("CART_CONTROL: %02x\r\n", g_ram[((uint16_t)(&CART_CONTROL)) - 0xde00]);
	cprintf("CART_CONFIG: %02x\r\n", g_ram[((uint16_t)(&CART_CONFIG)) - 0xde00]);
	cprintf("FLASH_ADDRESS_EXTENSION: %02x\r\n", g_ram[((uint16_t)(&FLASH_ADDRESS_EXTENSION)) - 0xde00]);
	cprintf("RAM_ADDRESS_EXTENSION: %02x\r\n", g_ram[((uint16_t)(&RAM_ADDRESS_EXTENSION)) - 0xde00]);
	cprintf("ADDRESS_EXTENSION2: %02x\r\n", g_ram[((uint16_t)(&ADDRESS_EXTENSION2)) - 0xde00]);
	cputs("starting program...\r\n");

	// copy BASIC replacement
	if (controlByte & 2) copyRomReplacement((uint8_t*) 0xa000, (uint8_t*) 0xc000);

	// copy KERNAL replacement
	if (controlByte & 4) copyRomReplacement((uint8_t*) 0xe000, (uint8_t*) 0xe000);
		
	// copy global MIDI tru settings, if requested
	ramSetBank(256);
	if (controlByte & 8) {
		g_ram[((uint16_t)(&MIDI_CONFIG)) - 0xde00] &= ~(MIDI_CONFIG_THRU_IN_ON | MIDI_CONFIG_THRU_OUT_ON);
		if (getConfigValue(KERBEROS_CONFIG_MIDI_IN_THRU)) {
			g_ram[((uint16_t)(&MIDI_CONFIG)) - 0xde00] |= MIDI_CONFIG_THRU_IN_ON;
		}
		if (getConfigValue(KERBEROS_CONFIG_MIDI_OUT_THRU)) {
			g_ram[((uint16_t)(&MIDI_CONFIG)) - 0xde00] |= MIDI_CONFIG_THRU_OUT_ON;
		}
	}
	
	// filter HIRAM hack, if C128, because the hardware doesn't allow it
	filterHiramHack();
		
	// reset and start program in assembler
	if (controlByte & 1) {
		c128startProgramInSram();
	} else {
		// init cartridge disk (only possible for C64)
		if (controlByte & 16)
			initCartridgeDisk(
				getConfigValue(KERBEROS_CONFIG_DRIVE_1),
				getConfigValue(KERBEROS_CONFIG_DRIVE_2));
		ramSetBank(256);
		filterHiramHack();
		
		// start program
		startProgram();
	}
}

static void startProgramInSlot(uint8_t slot, uint8_t* controlBytesAndRegs)
{
	static uint8_t* adr;
	static uint8_t i;
	static uint8_t blocks;
	static uint16_t ramBank;
	static uint8_t flashBank;
	
	// clear MIDI interrupts
	midiIrqNmiTest();

	// enable ROM at $8000	
	CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW;
	
	// check for valid slot ID
	flashBank = (slot + 6) * 8;
	FLASH_ADDRESS_EXTENSION = flashBank;
	if (!isValidSlotId()) return;

	// copy header and PRG from flash to SRAM
	disableInterrupts();
	adr = (uint8_t*) 0x8000;
	cputs("loading program...\r\n");
	blocks = adr[0x45] + 2;
	ramBank = 256;
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
	ramSetBank(256);
	if (controlBytesAndRegs) {
		for (i = 0; i < 16; i++) {
			g_ram[i + 0x30] = controlBytesAndRegs[i];
		}
	}
	
	startProgramInSram();
}

// list slots
static void listSlots(void)
{
	static uint8_t i;
	static uint8_t j;
	static uint8_t* adr;
	clrscr();

	// enable ROM at $8000	
	CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW;
	
	for (i = 1; i < 26; i++) {
		// 64 kb per slot, starting at $70000
		FLASH_ADDRESS_EXTENSION = (i + 6) * 8;
		adr = (uint8_t*) 0x8000;
		if (i < 10) {
			cprintf("%i: ", i);
		} else {
			char c = 'A' + i - 10;
			cprintf("%c(%i): ", c, i);
		}
		if (isValidSlotId()) {
			for (j = 0; j < 32; j++) {
				uint8_t b = adr[j + 0x10];
				if (b == 0) break;
				cputc(ascii2petscii(b));
			}
			cputs("\r\n");
		} else {
			cputs("[empty]\r\n");
		}
	}
}

static void sendNoteOff(uint8_t channelBits, uint8_t note, uint8_t velocity)
{
	midiSendByte(0x80 | channelBits);
        midiSendByte(note);
        midiSendByte(velocity);
}

static void midiSendBytesWithFlags(uint8_t b1, int b2, uint8_t flags)
{
    uint8_t channel = 0;
    if (b1 & 0x80) {
        b1 &= 0x7f;
        channel |= 2;
    }
    if (b2 >= 0) {
        if (b2 & 0x80) {
            b2 &= 0x7f;
            channel |= 1;
        }
        channel |= 1 << 2;
    } else {
        b2 = 0;
    }
    sendNoteOff(channel | flags, b1, b2);
}

static void midiStartTransfer(uint8_t tag, uint8_t length)
{
    g_lastByte = -1;
    midiSendBytesWithFlags(tag, length, 1 << 3);
}

static void midiSendBytes(uint8_t b1, uint8_t b2)
{
    midiSendBytesWithFlags(b1, b2, 0);
}

static void midiSendByteNote(uint8_t byte)
{
    if (g_lastByte < 0) {
        g_lastByte = byte;
    } else {
        midiSendBytes(g_lastByte, byte);
        g_lastByte = -1;
    }
}

static void midiEndTransfer()
{
    if (g_lastByte >= 0) {
        midiSendBytes(g_lastByte, 0);
    }
}

static void midiSendCommand(uint8_t tag, int size, const uint8_t* data)
{
    // start file transfer
    size_t length = size;
    size_t i;
    if (length <= 1) {
        tag |= 0x80;
        if (length == 1) {
            length = data[0];
            size = 0;
        }
    } else {
        length--;
    }
    midiStartTransfer(tag, length);

    // init checksum
    crc8Init();
    crc8Update(tag);
    crc8Update(length);

    // send data
    for (i = 0; i < size; i++) {
        midiSendByteNote(data[i]);
        crc8Update(data[i]);
    }

    // send checksum
    midiSendByteNote(g_crc);

    // end file transfer
    midiEndTransfer();
}

void blockToTrackSector(uint16_t block, uint8_t* track, uint8_t* sector)
{
	static uint8_t trackStart[] = { 1, 18, 25, 31 };
	static uint8_t trackEnd[] = { 17, 24, 30, 40 };
	static uint8_t sectors[] = { 21, 19, 18, 17 };
	static uint8_t i;
	static uint8_t j;
	for (i = 0; i < 4; i++) {
		*track = trackStart[i];
		for (j = trackStart[i]; j <= trackEnd[i]; j++) {
			if (block < sectors[i]) {
				*sector = block;
				return;
			}
			(*track)++;
			block -= sectors[i];
		}
	}
}

void showTrackInfo()
{
	cprintf("drive: %s\r\n", drive == DRIVE_INTERNAL ? "cartridge" : "floppy");
	cprintf("number: %i\r\n", number);
	cprintf("block: %i\r\n", block);
	cprintf("track: %i\r\n", track);
	cprintf("sector: %i\r\n", sector);
}

void calculateCartridgeDiskAddress()
{
	flashBank = block >> 5;
	adr = (uint8_t*) (((block - (flashBank << 5)) << 8) + 0x8000);
	flashBank += 8;
	if (number == 1) flashBank += 24;
//	cprintf("adr: %04x\r\n", adr);
//	cprintf("bank: %i\r\n", flashBank);
}

void receiveMidiCommands(void)
{
	static uint8_t redrawScreen;
	static uint8_t b;
	static uint8_t b0;
	static uint8_t b1;
	static uint8_t tag;
	static uint8_t length;
	static uint8_t i;
	static uint8_t err;
	midiInit();
	showTitle("PC/Mac link");
	cputs("\x1f: back\r\n\r\n");
	startX = wherex();
	startY = wherey();
	fastScreenBackup();

	for (;;) {
		disableInterrupts();
		fastScreenRestore();
		gotoxy(startX, startY);
		redrawScreen = 0;
		
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
			
			// read data
			disableInterrupts();
			if (midiReadCommand(tag, length)) {
				cputs("\r\nchecksum error!\r\n");
				anyKey();
				return;
			}
			
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
						cprintf("flash bank: %i\r\n", flashBank);
						anyKey();
						return;
					}
					break;
					
				case MIDI_COMMAND_WRITE_FLASH_FROM_SRAM:
				{
					cputs("flashing menu\r\n");
					cputs("please wait\r\n");
					cputs("don't turn off the computer\r\n");
					flashBank = g_blockBuffer[0];
					length = g_blockBuffer[1];
					adr = (uint8_t*) 0x8000;
					for (i = 0; i < length; i++) {
						flashSetBank(flashBank);
						if (adr == (uint8_t*) 0x8000 || adr == (uint8_t*) 0x9000) {
							flashEraseSector(adr);
						}
						ramSetBank(i + 0x100);
						memcpy(g_blockBuffer, g_ram, 256);
						flashWrite256Block(adr);
						FLASH_ADDRESS_EXTENSION = flashBank;
						if (fastCompare256Ultimax(adr)) {
							// try again
							flashWrite256Block(adr);
							if (fastCompare256Ultimax(adr)) {
								cputs("\r\nflash write error!\r\n");
								cprintf("flash bank: %i\r\n", flashBank);
								cputs("please try flashing menu again\r\n");
								anyKey();
								return;
							}
						}
						adr += 0x100;
						if (adr == (uint8_t*) 0xa000) {
							cputs(".");
							flashBank++;
							adr = (uint8_t*) 0x8000;
						}
					}
					cputs("\r\nmenu flash ok\r\n");
					anyKey();
					FLASH_ADDRESS_EXTENSION = 0;
					CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW | CART_CONTROL_RESET_GENERATE;
					while (1);
					break;
				}
				
				case MIDI_COMMAND_COMPARE_FLASH:
					FLASH_ADDRESS_EXTENSION = flashBank;
					if (fastCompare256(adr)) {
						cputs("\r\nflash compare error!\r\n");
						cprintf("flash bank: %i\r\n", flashBank);
						anyKey();
						return;
					}
					break;

				case MIDI_COMMAND_WRITE_RAM:
					memcpy(adr, g_blockBuffer, length + 1);
					break;
				
				case MIDI_COMMAND_REDRAW_SCREEN:
					redrawScreen = 1;
					break;
				
				case MIDI_COMMAND_PRINT:
					cputs(g_blockBuffer);
					break;
				
				case MIDI_COMMAND_GOTOX:
					gotox(g_blockBuffer[0]);
					break;
				
				case MIDI_COMMAND_START_SLOT_PROGRAM:
					startProgramInSlot(g_blockBuffer[0], &g_blockBuffer[1]);
					break;
	
				case MIDI_COMMAND_START_SRAM_PROGRAM:
					ramSetBank(0);
					startProgramInSram();
					return;
					
				case MIDI_COMMAND_CHANGE_CONFIG:
					for (i == 0; i <= length; i += 2) {
						uint8_t key = g_blockBuffer[i];
						uint8_t value = g_blockBuffer[i + 1];
						setConfigValue(key, value);
					}
					if (saveConfigs()) {
						cputs("\r\nsettings saved\r\n");
					} else {
						cputs("\r\nflash write error!\r\n");
						anyKey();
						return;
					}
					break;

				case MIDI_COMMAND_LIST_SLOTS:
					listSlots();
					break;
				
				case MIDI_COMMAND_DRIVE_LOAD_BLOCK:
					drive = g_blockBuffer[0];
					number = g_blockBuffer[1];
					block = g_blockBuffer[2] | (g_blockBuffer[3] << 8);
					blockToTrackSector(block, &track, &sector);
					fastScreenRestore();
					gotoxy(startX, startY);
					cputs("read block\r\n");
					showTrackInfo();
					if (drive == DRIVE_INTERNAL) {
						calculateCartridgeDiskAddress();
						FLASH_ADDRESS_EXTENSION = flashBank;
						midiSendCommand(MIDI_COMMAND_DRIVE_BLOCK, 256, adr);
					} else {
						err = readBlock(number, track, sector, g_blockBuffer);
						if (err) {
							const char* errorText = _stroserror(err);
							cprintf("error: %s\r\n", errorText);
							midiSendCommand(MIDI_COMMAND_DRIVE_ERROR, strlen(errorText), errorText);
						} else {
							midiSendCommand(MIDI_COMMAND_DRIVE_BLOCK, 256, g_blockBuffer);
						}
					}
					break;

				case MIDI_COMMAND_DRIVE_SAVE_BLOCK:
					drive = g_blockBuffer[0];
					number = g_blockBuffer[1];
					block = g_blockBuffer[2] | (g_blockBuffer[3] << 8);
					break;

				case MIDI_COMMAND_DRIVE_BLOCK:
					blockToTrackSector(block, &track, &sector);
					fastScreenRestore();
					gotoxy(startX, startY);
					cputs("write block\r\n");
					showTrackInfo();
					if (drive == DRIVE_INTERNAL) {
						calculateCartridgeDiskAddress();
						flashSetBank(flashBank);
						if (adr == (uint8_t*) 0x8000 || adr == (uint8_t*) 0x9000) {
							flashEraseSector(adr);
						}
						flashWrite256Block(adr);
						FLASH_ADDRESS_EXTENSION = flashBank;
						if (fastCompare256(adr)) {
							const char* errorText = "flash write error!";
							cprintf("\r\n%s\r\n", errorText);
							cprintf("flash bank: %i\r\n", flashBank);
							midiSendCommand(MIDI_COMMAND_DRIVE_ERROR, strlen(errorText), errorText);
							return;
						} else {
							midiSendCommand(MIDI_COMMAND_DRIVE_ERROR, 0, 0);
						}
					} else {
						err = writeBlock(number, track, sector, g_blockBuffer);
						if (err) {
							const char* errorText = _stroserror(err);
							cprintf("error: %s\r\n", errorText);
							midiSendCommand(MIDI_COMMAND_DRIVE_ERROR, strlen(errorText), errorText);
						} else {
							midiSendCommand(MIDI_COMMAND_DRIVE_ERROR, 0, 0);
						}
					}
					break;
			}
			if (redrawScreen) break;
		}
	}
}

// show and start program from flash slot
void menuStartProgramInSlot(void)
{
	clrscr();
	disableInterrupts();

	listSlots();

	// disable ROM at $8000	
	CART_CONTROL = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;
	
	enableInterrupts();

	for (;;) {
		if (kbhit()) {
			int slot = 0;
			int key = cgetc();
			if (key == LEFT_ARROW_KEY) {
				return;
			}
			if (key >= '0' && key <= '9') {
				slot = key - '0';
			} else if (key >= 'a' && key <= 'p') {
				slot = key - 'a' + 10;
			}
			if (slot > 0 && slot <= 25) {
				startProgramInSlot(slot, NULL);
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
	textcolor(CAPTION_COLOR);
	cputs("Kerberos Menu V0.9 - ");
	cputs(subtitle);
	textcolor(TEXT_COLOR);
	cputs("\r\n\r\n");
}

extern void get_ts_addr(void);

int main(void)
{
	uint8_t i;
	*((uint8_t*)1) = 55;
	g_isC128 = isC128();
	loadConfigs();
	//startProgram();

	//get_ts_addr();
/*	
	i = readBlock(8, 18, 0, g_blockBuffer);
	if (i) {
		cputs("floppyReadBlock error\r\n");
		cputs(_stroserror(i));
		cputs("\r\n");
	} else {
		cputs("floppyReadBlock ok\r\n");
		for (i = 0; i < 16; i++) cputc(g_blockBuffer[i + 0x90]);
	}

	*((uint8_t*)1) = 55;
	return 0;
	*/


	i = getConfigValue(KERBEROS_CONFIG_AUTOSTART_SLOT);
	if (i) {
		uint8_t start = 1;
		if (kbhit()) {
			if (cgetc() == 'm') {
				start = 0;
			}
		}
		if (start) {
			FLASH_ADDRESS_EXTENSION = (i + 6) * 8;
			if (isValidSlotId()) {
				startProgramInSlot(i, NULL);
			}
		}
	}
	
	for (;;) {
		for (i = 0; i < 24; i++) g_sidBase[i] = 0;
		g_vicBase[0x15] = 0;
		bgcolor(BACKGROUND_COLOR);
		bordercolor(BACKGROUND_COLOR);
		textcolor(TEXT_COLOR);
		gotoxy(0, 0);

		// disable MIDI
		MIDI_CONFIG = 0;
	
		// standard mode
		CART_CONFIG = 0;
	
		// /GAME high, /EXROM low
		CART_CONTROL = CART_CONTROL_EXROM_LOW | CART_CONTROL_GAME_HIGH;

		showTitle("main menu");
		cputs("s: start program\r\n");
		cputs("f: file/settings transfer from PC/Mac\r\n");
		cputs("e: EasyFlash start\r\n");
		cputs("b: back to BASIC\r\n");
		cputs("t: tests\r\n");
		cputs("c: credits\r\n");
		cputs("\r\n");
		while (!kbhit());
		switch (cgetc()) {
			case 'e':
				startEasyFlash();
				break;
			case 'f':
				receiveMidiCommands();
				break;
			case 's':
				menuStartProgramInSlot();
				break;
			case 'b':
				toBasic();
				break;
			case 't':
				testMenu();
				break;
			case 'c':
				about();
				break;
		}
	}
	return 0;
}
