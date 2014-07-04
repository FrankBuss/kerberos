
#ifndef TORTURETEST_H_
#define TORTURETEST_H_

#include <stdint.h>
#include "flash.h"

void __fastcall__ tortureTestFillBuffer(const EasyFlashAddr* pAddr);
uint16_t __fastcall__ tortureTestBanking(void);
uint8_t __fastcall__ tortureTestCheckRAM(void);

void tortureTestAuto(void);
void tortureTestComplete(void);
void tortureTestRead(void);
void tortureTestRAM(void);

#endif /* TORTURETEST_H_ */
