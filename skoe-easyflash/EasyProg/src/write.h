/*
 * EasyProg - write.h - Write cartridge image to flash
 *
 * (c) 2009 Thomas Giesel
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 *
 * Thomas Giesel skoe@directbox.com
 */
#ifndef WRITE_H_
#define WRITE_H_

// I/O address used to select the bank
#define EASYFLASH_IO_BANK           0xde00

// I/O address for enabling memory configuration, /GAME and /EXROM states
#define EASYFLASH_IO_CONTROL        0xde02

// Bit for Expansion Port /GAME line (1 = low)
#define EASYFLASH_IO_BIT_GAME       0x01

// Bit for Expansion Port /EXROM line (1 = low)
#define EASYFLASH_IO_BIT_EXROM      0x02

// Bit for memory control (1 = enabled)
#define EASYFLASH_IO_BIT_MEMCTRL    0x04

// Bit for status LED (1 = on)
#define EASYFLASH_IO_BIT_LED        0x80

// Control register value for 8k cartridges
#define EASYFLASH_IO_8K  (EASYFLASH_IO_BIT_MEMCTRL | EASYFLASH_IO_BIT_EXROM)

// Control register value for 8k cartridges
#define EASYFLASH_IO_16K (EASYFLASH_IO_BIT_MEMCTRL | EASYFLASH_IO_BIT_EXROM | EASYFLASH_IO_BIT_GAME)

// Control register value for Ultimax cartridges
#define EASYFLASH_IO_ULTIMAX (EASYFLASH_IO_BIT_MEMCTRL | EASYFLASH_IO_BIT_GAME)

uint8_t autoWriteCRTImage(uint8_t nSlot);
void checkWriteCRTImage(void);
void checkWriteCRTImageFromUSB(void);
void checkWriteLOROMImage(void);
void checkWriteHIROMImage(void);
void checkWriteKERNALImage(void);
void checkWriteARImage(void);
void checkWriteSS5Image(void);
void eraseAll(void);
void checkEraseAll(void);
void checkEraseSlot(void);
void checkEraseKERNAL(void);
void checkEraseAR(void);
void checkEraseSS5(void);

#endif /* WRITE_H_ */
