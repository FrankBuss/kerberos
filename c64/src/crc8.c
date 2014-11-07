#include "crc8.h"
#include "util.h"

uint8_t g_crc;

void crc8Init(void)
{
	g_crc = 0xff;
}

void crc8Update(uint8_t data)
{
	g_crc = g_crc8Table[data ^ g_crc];
}

uint8_t crc8Get(void)
{
	return g_crc;
}
