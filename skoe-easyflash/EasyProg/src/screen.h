
#ifndef SCREEN_H_
#define SCREEN_H_

#include <c64.h>
#include <stdint.h>

#define COLOR_BACKGROUND COLOR_LIGHTBLUE
#define COLOR_LIGHTFRAME COLOR_GRAY1
#define COLOR_FOREGROUND COLOR_BLACK
#define COLOR_EXTRA      COLOR_YELLOW

#define BUTTON_ENTER     0x01
#define BUTTON_STOP      0x02

#define KEY_REPEAT_DEFAULT  0x00
#define KEY_REPEAT_NONE     0x40
#define KEY_REPEAT_ALL      0x80

/** Maximal number of menu entries, including termination entry */
#define SCREEN_MAX_MENU_ENTRIES 12

/** Update the screen but don't close the menu entry if this has been selected */
#define SCREEN_MENU_ENTRY_FLAG_KEEP 1

/**
 * This type describes an entry in a menu.
 */
typedef struct ScreenMenuEntry_s
{
    const char* pStrLabel;
    void (*pFunction)(void);
    uint8_t (*pCheckFunction)(void);
    uint8_t flags;
}
ScreenMenuEntry;

/**
 * This types describes a menu. It has some properties and some entries.
 */
typedef struct ScreenMenu_s
{
    uint8_t x;

    uint8_t y;

    /** Index of selected entry */
    uint8_t nSelected;

    /** Point to the next menu. This is shown if the user presses '<=' */
    struct ScreenMenu_s* pPrevMenu;

    /** Point to the next menu. This is shown if the user presses '=>' */
    struct ScreenMenu_s* pNextMenu;

    /**
     * This array has a variable number of entries. The last entry
     * (terminator) has all fields set to zero.
     */
    ScreenMenuEntry entries[SCREEN_MAX_MENU_ENTRIES];
}
ScreenMenu;

void screenInit(void);
uint8_t __fastcall__ screenSetKeyRepeat(uint8_t val);
void screenBing(void);
void __fastcall__ screenPrintHex2(uint8_t n);
void __fastcall__ screenPrintHex4(uint16_t n);
void __fastcall__ screenGotoXYLH(uint16_t yx);
void screenPrintFrame(void);
void screenPrintBox(uint8_t x, uint8_t y, uint8_t w, uint8_t h);
void screenPrintBorder(uint8_t x, uint8_t y, uint8_t w, uint8_t h);
void __fastcall__ screenPrintTopLine(uint8_t xStart, uint8_t xEnd, uint8_t y);
void __fastcall__ screenPrintSepLine(uint8_t xStart, uint8_t xEnd, uint8_t y);
void __fastcall__ screenPrintBottomLine(uint8_t xStart, uint8_t xEnd, uint8_t y);
uint8_t __fastcall__ screenPrintDialog(const char* apStrLines[], uint8_t flags);
void __fastcall__ screenPrintSimpleDialog(const char* apStrLines[]);
uint8_t __fastcall__ screenPrintTwoLinesDialog(const char* p1, const char* p2);
uint8_t __fastcall__ screenAskEraseDialog(void);
uint8_t __fastcall__ screenWaitKey(uint8_t flags);
uint8_t __fastcall__ screenIsStopPressed(void);
const char* __fastcall__ screenReadInput(const char* pStrTitle,
                                         const char* pStrDefault);
void __fastcall__ screenDoMenu(ScreenMenu* pMenu);
void screenShowSprites(void);

#endif /* SCREEN_H_ */
