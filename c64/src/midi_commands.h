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

// data: up to 256 bytes, to be written to the current address in RAM (not under IO area)
#define MIDI_COMMAND_WRITE_RAM 0x06

// no data
#define MIDI_COMMAND_REDRAW_SCREEN 0x07

// data: ASCIIZ text which is printed
#define MIDI_COMMAND_PRINT 0x08

// data: one byte, move cursor to specified X position
#define MIDI_COMMAND_GOTOX 0x09

// data: one byte for the slot. Causes the C64 to wait for Y/N. If Y is pressed, then the program in the specified slot is started, otherwise the transfer menu is exited.
#define MIDI_COMMAND_START_SLOT_PROGRAM 0x0a

// waits for a key and returns the transfer menu
#define MIDI_COMMAND_EXIT 0x0b

// data: up to 256 bytes. No operation, for delays.
#define MIDI_COMMAND_NOP 0x0c

// no data. Reset, copy the program from SRAM and start.
#define MIDI_COMMAND_START_SRAM_PROGRAM 0x0d

#endif
