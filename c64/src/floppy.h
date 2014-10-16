#ifndef FLOPPY_H
#define FLOPPY_H

#include <stdint.h>

// read a 256 bytes block from the specified device
// returns 0 if successful, otherwise _stroserror returns a clear text description of the error
uint8_t readBlock(uint8_t device, uint8_t track, uint8_t sector, uint8_t* data);

// write a 256 bytes block to the specified device
// returns 0 if successful, otherwise _stroserror returns a clear text description of the error
uint8_t writeBlock(uint8_t device, uint8_t track, uint8_t sector, uint8_t* data);

#endif
