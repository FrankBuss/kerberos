#ifndef CRC8_H
#define CRC8_H

#include <stdint.h>

void crc8Init(void);

void crc8Update(uint8_t data);

uint8_t crc8Get(void);

#endif
