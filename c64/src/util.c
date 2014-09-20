#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <conio.h>
#include <stdlib.h>
#include <cbm.h>

#include "util.h"
#include "regs.h"

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
	enableInterrupts();
	
	// clear keyboard buffer
	while (kbhit()) cgetc();
	
	// wait for key
	cputs("press any key\r\n");
	while (!kbhit());
	cgetc();
}
