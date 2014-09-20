#ifndef UTIL_H
#define UTIL_H

#include <stdint.h>


// util.c

void ramSetBank(uint16_t bank);
void anyKey();


// util_asm.s

uint8_t __fastcall__ isC128(void);
uint8_t __fastcall__ midiReadCommand(uint8_t tag, uint8_t length);
void __fastcall__ loadProgram(uint8_t flash);
void __fastcall__ startProgram(void);
uint8_t __fastcall__ ascii2petscii(uint8_t ascii);
void __fastcall__ disableInterrupts(void);
void __fastcall__ enableInterrupts(void);
void __fastcall__ startEasyFlash(void);
void __fastcall__ rand256Block(void);
void __fastcall__ flashSetBank(uint8_t bank);
void __fastcall__ flashEraseSector(uint8_t* address);
void __fastcall__ flashWrite256Block(uint8_t* address);
uint16_t __fastcall__ flashReadId(void);
uint8_t __fastcall__ fastCompare256(uint8_t* address);

extern uint8_t _BLOCK_BUFFER_START__;
#define g_blockBuffer (&_BLOCK_BUFFER_START__)

extern uint8_t _CART128_LOAD__;
#define cart128Load (&_CART128_LOAD__)

extern uint8_t cart128Start;
#define cart128StartPtr (&cart128Start)

extern uint8_t cart128End;
#define cart128EndPtr (&cart128End)

#endif
