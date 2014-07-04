/*
 * (c) 2010 Thomas Giesel
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

#include <stdint.h>
#include <stddef.h>
#include <string.h>
#include <conio.h>
#include <stdlib.h>
#include <c64.h>

#include <ef3usb.h>

#include "text_plot.h"
#include "memcfg.h"
#include "efmenu.h"

// from gfx.s
extern const uint8_t* bitmap;
extern const uint8_t* colmap;
extern const uint8_t* attrib;
extern uint8_t background;


#define N_MENU_PAGES 2

static const char* m_pEFSignature = "EF-Directory V1:";

static efmenu_entry_t kernal_menu[] =
{
        { '1',  0,  0,  0,  MODE_KERNAL,    "1", "Empty", "" },
        { '2',  0,  1,  0,  MODE_KERNAL,    "2", "Empty", "" },
        { '3',  0,  2,  0,  MODE_KERNAL,    "3", "Empty", "" },
        { '4',  0,  3,  0,  MODE_KERNAL,    "4", "Empty", "" },
        { '5',  0,  4,  0,  MODE_KERNAL,    "5", "Empty", "" },
        { '6',  0,  5,  0,  MODE_KERNAL,    "6", "Empty", "" },
        { '7',  0,  6,  0,  MODE_KERNAL,    "7", "Empty", "" },
        { '8',  0,  7,  0,  MODE_KERNAL,    "8", "Empty", "" },
        { 0, 0, 0, 0, 0, "", "", "" }
};

static efmenu_entry_t ef_menu[] =
{
        { 'a',  1,  0,  1,  MODE_EF,    "A", "EF Slot 1", "" },
        { 'b',  2,  0,  1,  MODE_EF,    "B", "EF Slot 2", "" },
        { 'c',  3,  0,  1,  MODE_EF,    "C", "EF Slot 3", "" },
        { 'd',  4,  0,  1,  MODE_EF,    "D", "EF Slot 4", "" },
        { 'e',  5,  0,  1,  MODE_EF,    "E", "EF Slot 5", "" },
        { 'f',  6,  0,  1,  MODE_EF,    "F", "EF Slot 6", "" },
        { 'g',  7,  0,  1,  MODE_EF,    "G", "EF Slot 7", "" },
        { 0, 0, 0, 0, 0, "", "", "" }
};

/* key 0 => end, key 0xff => not selectable */
static efmenu_entry_t special_menu[] =
{
        { 'r',  0,  0x10, 1,  MODE_AR,           "R", "Replay Slot 1",    "" },
        { 'y',  0,  0x18, 1,  MODE_AR,           "Y", "Replay Slot 2",    "" },
        { 's',  0,  0x20, 1,  MODE_SS5,          "S", "Super Snapshot 5", "" },
        { 'p',  0,  9,    1,  MODE_EF_NO_RESET,  "P", "EasyProg",         "crt" },
        { 0xff, 0,  0,    0,  MODE_EF,           "",  "",                 "" },
        { ' ',  0,  0,    0,  MODE_NEXT_PAGE,    "",  "<SPACE> for more","" },
        { 0, 0, 0, 0, 0, "", "", "" }
};

static efmenu_entry_t dummy_menu[] =
{
        { 0xff, 0,  0x0b,   1,  MODE_EF,           "?", "USB Tool",         "prg" },
        { 0, 0, 0, 0, 0, "", "", "" }
};

static efmenu_entry_t page1_menu[] =
{
        { 'v', 0, 0, 0,  MODE_SHOW_VERSION, "V", "Show Versions",    "" },
        { 'k', 0, 0, 1,  MODE_KILL,         "K", "Kill Cartridge",   "" },
        { 'z', 0, 0, 1,  MODE_GO128,        "Z", "To C128 Mode",     "" },
        { 0, 0, 0, 0, 0, "", "", "" }
};

static efmenu_t all_menus[] =
{
        { 0,   2,  2, 10, kernal_menu },
        { 0,   2, 15,  8, special_menu },
        { 0,  22, 13,  9, ef_menu },
        { 1,   2, 15,  8, page1_menu },
        { 2,   0,  0,  0, dummy_menu },
        { 0,   0,  0,  0, NULL }
};

/* This is the currently selected menu index in all_menus */
static uint8_t n_current_menu;

/* This is the currently selected menu entry index in current menu */
static uint8_t n_current_entry;

/* Currently active menu page */
static uint8_t n_current_page;

/******************************************************************************/
static void show_version(void);
static void version_display_loop(void);
uint8_t menu_entry_is_valid(const efmenu_entry_t* entry);
static uint8_t current_entry_is_selectable(void);
static void erase_text_areas(uint8_t colors);
static void fill_directory(void);

/******************************************************************************/
/**
 *
 */
static efmenu_entry_t* get_current_menu_entry(void)
{
    return all_menus[n_current_menu].pp_entries + n_current_entry;
}


/******************************************************************************/
/**
 * Set n_current_menu/n_current_entry to the previous menu entry
 * ("joystick up").
 */
static void select_prev_entry()
{
    efmenu_entry_t* p;

    do
    {
        if (n_current_entry == 0)
        {
            // prev menu
            if (n_current_menu == 0)
            {
                // last menu
                while (all_menus[n_current_menu + 1].pp_entries)
                    ++n_current_menu;
            }
            else
                --n_current_menu;

            p = all_menus[n_current_menu].pp_entries;
            // last entry
            while (p[n_current_entry + 1].key)
                ++n_current_entry;
        }
        else
            --n_current_entry;
    }
    while (!current_entry_is_selectable());

    n_current_page = all_menus[n_current_menu].n_page;
}


/******************************************************************************/
/**
 * Set n_current_menu/n_current_entry to the previous menu entry
 * ("joystick down").
 */
static void select_next_entry()
{
    do
    {
        ++n_current_entry;
        if (!all_menus[n_current_menu].pp_entries[n_current_entry].key)
        {
            n_current_entry = 0;
            ++n_current_menu;
            if (!all_menus[n_current_menu].pp_entries)
                n_current_menu = 0;
        }
    }
    while (!current_entry_is_selectable());

    n_current_page = all_menus[n_current_menu].n_page;
}


/******************************************************************************/
/**
 */
static void select_next_page(void)
{
    uint8_t new_page;

    new_page = n_current_page + 1;
    if (new_page >= N_MENU_PAGES)
        new_page = 0;

    /* evil implementation: select an entry from that page */
    while (n_current_page != new_page)
        select_next_entry();

    n_current_page = new_page;
}


/******************************************************************************/
/**
 */
static void select_prev_menu(void)
{
    uint8_t n_old, watchdog;

    n_old = n_current_menu;
    watchdog = 0;
    do
    {
        select_prev_entry();
    }
    while (n_old == n_current_menu && ++watchdog != 0);
}


/******************************************************************************/
/**
 */
static void select_next_menu(void)
{
    uint8_t n_old, watchdog;

    n_old = n_current_menu;
    watchdog = 0;
    do
    {
        select_next_entry();
    }
    while (n_old == n_current_menu && ++watchdog != 0);
}


/******************************************************************************/
/**
 * Return 1 if the entry is valid. This is the case if it contains a mode
 * which always works or if at least one of the last 4 bytes in the ROM
 * location is not empty and does not contain the torture test pattern.
 *
 * Empty pattern:         ff ff ff ff
 * Torture test pattern:  03 02 01 00
 */
uint8_t menu_entry_is_valid(const efmenu_entry_t* entry)
{
    uint8_t* p;
    uint8_t  i;

    if (entry->mode == MODE_EF_NO_RESET ||
        entry->mode == MODE_KILL ||
        entry->mode == MODE_SHOW_VERSION ||
        entry->mode == MODE_NEXT_PAGE)
        return 1;

    if (is_c128())
    {
        if (entry->mode == MODE_KERNAL)
            return 0;
    }
    else
    {
        if (entry->mode == MODE_GO128)
            return 0;
    }

    set_slot(entry->slot);
    set_bank(entry->bank);

    if (entry->chip == 0)
        p = (uint8_t*) (0x8000 + 0x2000 - 4);
    else
        p = (uint8_t*) (0xa000 + 0x2000 - 4);

    for (i = 0; i != 4; ++i)
    {
        if ((p[i] != 0xff) &&
            (p[i] != 3 - i))
        {
            return 1;
        }
    }
    return 0;
}


/******************************************************************************/
/**
 */
static uint8_t current_entry_is_selectable(void)
{
    efmenu_entry_t* p = get_current_menu_entry();
    return menu_entry_is_valid(p) && (p->key != 0xff);
}

/******************************************************************************/
/**
 * If full_update is not set, only the colors are updated.
 */
static void show_menu(uint8_t n_page, uint8_t full_update)
{
    uint8_t y, color;
    efmenu_t* menu;
    efmenu_entry_t* entry;

    if (full_update)
    {
        erase_text_areas(COLOR_GRAY2 << 4 | COLOR_GRAY3);
        fill_directory();
    }

    menu = all_menus;
    while (menu->pp_entries)
    {
        if (menu->n_max_entries && menu->n_page == n_page) /* hidden otherwise */
        {
            y = menu->y_pos + 1;

            entry = menu->pp_entries;
            while (entry->key)
            {
                if (full_update)
                {
                    text_plot_puts(menu->x_pos,     4, y, entry->label);
                    text_plot_puts(menu->x_pos + 2, 0, y, entry->name);
                }

                if (entry == get_current_menu_entry())
                    color = COLOR_BLACK << 4 | COLOR_YELLOW;
                else if (menu_entry_is_valid(entry))
                    color = COLOR_BLACK << 4 | COLOR_GRAY3;
                else
                    color = COLOR_GRAY2 << 4 | COLOR_GRAY3;
                text_set_line_color(menu->x_pos, y, color);

                ++y;
                ++entry;
            }
        }
        ++menu;
    }
}


/******************************************************************************/
/**
 */
static void __fastcall__ start_menu_entry(const efmenu_entry_t* entry)
{
    // Wait until the key is released
    wait_for_no_key();

    set_slot(entry->slot);

    if (entry->mode == MODE_EF_NO_RESET)
    {
        // PONR
        start_program(entry->bank);
    }
    else if (entry->mode == MODE_SHOW_VERSION)
    {
        version_display_loop();
    }
    else if (entry->mode == MODE_NEXT_PAGE)
    {
        select_next_page();
    }
    else
    {
        // PONR
        set_bank_change_mode(entry->bank, entry->mode);
    }
}


/******************************************************************************/
/**
 * return 1 if something was started, 0 if not
 */
static uint8_t __fastcall__ start_menu_entry_ex(uint8_t key, const char* type)
{
    const efmenu_t* menu;
    const efmenu_entry_t* entry;

    if (key == CH_ENTER)
    {
        entry = get_current_menu_entry();
        start_menu_entry(entry);
        return 1;
    }

    menu = all_menus;
    while (menu->pp_entries)
    {
        entry = menu->pp_entries;
        while (entry->key)
        {
            if (menu_entry_is_valid(entry))
            {
                if (key  && entry->key == key)
                {
                    start_menu_entry(entry);
                    return 1;
                }
                if (type && strcmp(entry->type, type) == 0)
                {
                    ef3usb_send_str("wait");
                    start_menu_entry(entry);
                    return 1;
                }
            }
            ++entry;
        }
        ++menu;
    }
    return 0;
}


/******************************************************************************/
/**
 */
static void poll_usb(void)
{
    const char* pType;

    pType = ef3usb_check_cmd();
    if (pType)
    {
        if (strcmp(pType, "rst") == 0)
        {
            /* means: reset to menu, nothing to do here */
            ef3usb_send_str("done");
            return;
        }
        else
            start_menu_entry_ex(0, pType);
    }
}


/******************************************************************************/
/**
 */
static void show_version(void)
{
    uint16_t x;
    uint8_t  y;
    static char str_version[6];
    uint8_t vcode = EF3_CPLD_VERSION;

    erase_text_areas(COLOR_BLACK << 4 | COLOR_GRAY3);
    x = all_menus[0].x_pos + 1;
    y = all_menus[0].y_pos + 1;

    text_plot_puts(x, 0, y, "CPLD Core Version:");
    y += 3;
    text_plot_puts(x, 0, y, "Menu Version:");
    y += 4;
    text_plot_puts(x, 0, y, "Press <Run/Stop>");

    if (vcode != EF3_OLD_VERSION)
    {
        str_version[0] = '0' + ((vcode >> 6) & 3);
        str_version[1] = '.';
        str_version[2] = '0' + ((vcode >> 3) & 7);
        str_version[3] = '.';
        str_version[4] = '0' + (vcode & 7);
    }
    else
        strcpy(str_version, "0.x.x");
    y = all_menus[0].y_pos + 2;
    x += 6;
    text_plot_puts(x, 0, y, str_version);
    y += 3;
    text_plot_puts(x, 0, y, EFVERSION);
}


/******************************************************************************/
/**
 */
static void version_display_loop(void)
{
    uint8_t key;

    show_version();
    do
    {
        if (kbhit())
        {
            key = cgetc();
            if (key == CH_STOP || key == CH_ENTER)
                return;
        }

        poll_usb();
    }
    while (1);
}


/******************************************************************************/
/**
 */
static void main_loop(void)
{
    uint8_t key, update, full_update, n_old_page;

    do
    {
        update = full_update = 0;
        n_old_page = n_current_page;
        if (kbhit())
        {
            key = cgetc();
            switch (key)
            {
            case CH_CURS_UP:
                select_prev_entry();
                update = 1;
                break;

            case CH_CURS_DOWN:
                select_next_entry();
                update = 1;
                break;

            case CH_CURS_LEFT:
                select_prev_menu();
                update = 1;
                break;

            case CH_CURS_RIGHT:
                select_next_menu();
                update = 1;
                break;

            default:
                if (start_menu_entry_ex(key, NULL))
                    full_update = 1;
                break;
            }
        }

        if (n_current_page != n_old_page)
            full_update = 1;

        update |= full_update;

        if (update)
            show_menu(n_current_page, full_update);

        poll_usb();
    }
    while (1);
}


/******************************************************************************/
/**
 */
static void erase_text_areas(uint8_t colors)
{
    uint8_t  n;
	uint16_t offset;

    const efmenu_t* menu;

    menu = all_menus;
    while (menu->pp_entries)
    {
        offset = menu->y_pos * 320 + menu->x_pos * 8;

        for (n = 0; n != menu->n_max_entries; ++n)
        {
            memset(P_GFX_BITMAP + offset, 0, 16 * 8);
            offset += 320;
            text_set_line_color(menu->x_pos, menu->y_pos + n, colors);
        }
        ++menu;
    }
}


/******************************************************************************/
/**
 * Read the directory from the cartridge to our menu structures.
 * Return immediately if the signature cannot be found.
 */
static void fill_directory(void)
{
    const efmenu_dir_t* p_dir = (efmenu_dir_t*)0x8000;
    int i;
    efmenu_entry_t* p_entry;
    char*           p_name;

    set_slot(EF_DIR_SLOT);
    set_bank(EF_DIR_BANK);

    if (memcmp(p_dir->signature, m_pEFSignature, sizeof(p_dir->signature)))
        return;

    // we show slot 1 to 7 only
    p_name  = p_dir->slots[1];
    p_entry = ef_menu;
    for (i = 0; i < 7; ++i)
    {
        memcpy(p_entry->name, p_name, sizeof(p_dir->slots[0]));
        ++p_entry;
        p_name += sizeof(p_dir->slots[0]);
        p_entry->name[sizeof(ef_menu[0].name) - 1] = '\0';
    }

    // and KERNAL 1 to 8
    p_name  = p_dir->kernals[0];
    p_entry = kernal_menu;
    for (i = 0; i < 8; ++i)
    {
        memcpy(p_entry->name, p_name, sizeof(p_dir->kernals[0]));
        ++p_entry;
        p_name += sizeof(p_dir->slots[0]);
        p_entry->name[sizeof(kernal_menu[0].name) - 1] = '\0';
    }
}


/******************************************************************************/
/**
 */
static void init_screen(void)
{
    VIC.bordercolor = COLOR_BLUE;

    /* set VIC base address to $4000 */
    CIA2.pra = 0x14 + 2;
    CIA2.ddra = 0x3f;

    /* video offset $1c00, bitmap offset = $2000 */
    VIC.addr = 0x78;

    /* Bitmap mode */
    VIC.ctrl1 = 0xbb;

    // copy bitmap at $A000 from ROM to RAM => VIC can see it
    // copy colors to $8400
    memcpy(P_GFX_BITMAP, bitmap, 8000);
    memcpy(P_GFX_COLOR, colmap, 1000);
}

void initNMI(void);

/******************************************************************************/
/**
 */
int main(void)
{
    init_screen();

    n_current_menu = 2; /* EasyFlash menu index in all_menus */
    n_current_entry = 0;

    /* make sure a valid entry is selected and n_current_page initialized */
    select_next_entry();
    select_prev_entry();

    show_menu(n_current_page, 1);
    joy_init_irq();

#if 0
    set_bank(0x0f);
    memcpy((void*)0x8000, (void*)0x8000, 0x2000);
    // copy KERNAL to RAM
    memcpy((void*)0xe000, (void*)0xe000, 0x2000);
    initNMI();
#endif

    main_loop();

    return 0;
}
