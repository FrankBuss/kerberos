
#ifndef MEMCFG_H
#define MEMCFG_H

#define P_VIC_BASE      ((uint8_t*)0x4000)
#define P_GFX_COLOR     ((uint8_t*)0x5C00)
#define P_GFX_BITMAP    ((uint8_t*)0x6000)
//#define P_WND_SPRITES   ((uint8_t*)0x6800)

#define P_SPR_PTRS      (GFX_COLOR + 0x3f8)

#endif
