
#ifndef EAPIGLUE_H
#define EAPIGLUE_H

#include <stdint.h>

#define EAPI_ERR_RAM                1
#define EAPI_ERR_ROML               2
#define EAPI_ERR_ROMH               3
#define EAPI_ERR_ROML_PROTECTED     4
#define EAPI_ERR_ROMH_PROTECTED     5

#define EAPI_LOAD_TO ((uint8_t*)0xc000)
#define EAPI_DRIVER_NAME ((const char*)0xc000 + 4)
#define EAPI_SIZE 0x300

uint8_t  efShowROM(void* addr);
uint8_t  efHideROM(void* addr);
uint8_t __fastcall__ efPeekCartROM(void* addr);
void* __fastcall__ efCopyCartROM(void* dest, const void* src, size_t count);
uint16_t __fastcall__ efVerifyFlash(uint8_t* pFlash);

uint8_t __fastcall__ eapiInit(uint8_t* pManufacturerId, uint8_t* pDeviceId);
uint8_t eapiReInit(void);
uint8_t __fastcall__ eapiGetBank(void);
void __fastcall__ eapiSetBank(uint8_t nBank);
uint8_t __fastcall__ eapiSectorErase(uint8_t* pBase);
//uint8_t __fastcall__ eapiWriteFlash(uint8_t* pAddr, uint8_t nVal);
uint8_t __fastcall__ eapiGlueWriteBlock(uint8_t* pDst);
uint8_t __fastcall__ eapiGetSlot(void);
void __fastcall__ eapiSetSlot(uint8_t nSlot);

extern uint8_t aEAPIDrivers[][EAPI_SIZE];

extern uint8_t _BLOCK_BUFFER_START__;
#define BLOCK_BUFFER (&_BLOCK_BUFFER_START__)

#endif
