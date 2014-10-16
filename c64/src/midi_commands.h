#ifndef MIDI_COMMANDS_H
#define MIDI_COMMANDS_H

// word: set current address for flash or SRAM access (physical address, both starting at 0)
#define MIDI_COMMAND_SET_ADDRESS 0x01

// word: set current RAM bank
#define MIDI_COMMAND_SET_RAM_BANK 0x02

// byte: set current flash bank				
#define MIDI_COMMAND_SET_FLASH_BANK 0x03

// no data, use current address
#define MIDI_COMMAND_ERASE_FLASH_SECTOR 0x04

// data: 256 bytes, to be written to the flash at the current address
#define MIDI_COMMAND_WRITE_FLASH 0x05

// data: 256 bytes, to be compared to the flash at the current address
#define MIDI_COMMAND_COMPARE_FLASH 0x06

// data: up to 256 bytes, to be written to the current address in RAM (not under IO area)
#define MIDI_COMMAND_WRITE_RAM 0x07

// no data
#define MIDI_COMMAND_REDRAW_SCREEN 0x08

// data: ASCIIZ text which is printed
#define MIDI_COMMAND_PRINT 0x09

// data: one byte, move cursor to specified X position
#define MIDI_COMMAND_GOTOX 0x0a

// data: up to 256 bytes. No operation, for delays.
#define MIDI_COMMAND_NOP 0x0b

// data: slot number. Starts the program in the specified slot.
#define MIDI_COMMAND_START_SLOT_PROGRAM 0x0c

// no data. Reset, copy the program from SRAM and start. Header information in first SRAM block (256 bytes) is the same as in the first block of a slot.
#define MIDI_COMMAND_START_SRAM_PROGRAM 0x0d

// key/value pairs, 2 bytes each. Change config values.
#define MIDI_COMMAND_CHANGE_CONFIG 0x0e

// no data. Show all slots on the C64.
#define MIDI_COMMAND_LIST_SLOTS 0x0f

// data: flash start bank and number of blocks to write, copied from SRAM starting at 0x10000 (for menu update)
#define MIDI_COMMAND_WRITE_FLASH_FROM_SRAM 0x10

// data: type (see below), drive number, low byte block number, high byte block number to load. Sends a MIDI_COMMAND_DRIVE_BLOCK or MIDI_COMMAND_DRIVE_ERROR back.
#define MIDI_COMMAND_DRIVE_LOAD_BLOCK 0x11
#define DRIVE_INTERNAL 1
#define DRIVE_IEC 2

// data: type (see above), drive number, low byte block number, high byte block number to save.
// Next command has to be a MIDI_COMMAND_DRIVE_BLOCK with the data to send.
// Sends a MIDI_COMMAND_DRIVE_ERROR back with an empty string, if ok, otherwise with an error message.
#define MIDI_COMMAND_DRIVE_SAVE_BLOCK 0x12

// data: 256 bytes for the requested block from the C64 after a MIDI_COMMAND_DRIVE_LOAD_BLOCK, or from the PC after a MIDI_COMMAND_DRIVE_SAVE_BLOCK
#define MIDI_COMMAND_DRIVE_BLOCK 0x13

// data: error message in PETSCII, empty string for no error
#define MIDI_COMMAND_DRIVE_ERROR 0x14

#endif
