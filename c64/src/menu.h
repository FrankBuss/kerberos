#ifndef MENU_H
#define MENU_H

#include <stdint.h>

// number of 8 k flash banks
#define FLASH_BANKS 256

// menu colors
#define BACKGROUND_COLOR 0
#define TEXT_COLOR 14
#define CAPTION_COLOR 1

// back key
#define LEFT_ARROW_KEY 0x5f

// global variables
extern uint8_t* g_ram;
extern uint8_t g_isC128;

// functions
void testMenu(void);


#endif
