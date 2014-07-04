

#ifndef SPRITES_H_
#define SPRITES_H_

// size of memory used by the sprites for the startup screen
#define STARTUP_SPRITES_SIZE (7 * 64)

extern uint8_t* pSprites;
void spritesShow(void);
uint8_t __fastcall__ spritesOn(uint8_t on);

#endif /* SPRITES_H_ */
