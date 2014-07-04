/**/
/*   ZEROPAGE VARS  */
/**/

.pc = $02 "zpvars" virtual

/*
   colors.asm
*/

COL_SRC_LO:
	.fill 1, 0
COL_SRC_HI:
	.fill 1, 0
COL_DST_LO:
	.fill 1, 0
COL_DST_HI:
	.fill 1, 0

/*
	draw.asm
*/

P_DRAW_START:
	.fill 1, 0
P_DRAW_LAST_START:
	.fill 1, 0
P_DRAW_OFFSET:
	.fill 1, 0
P_DRAW_LINES_DIR:
	.fill 1, 0
ZP_DRAW_PTR:
	.fill 2, 0
P_DRAW_SLIDER_SIZE:
	.fill 1, 0
P_DRAW_SLIDER_FAC:
	.fill 2, 0

/*
    somewhere
*/

ZP_ENTRY:
	.fill 2, 0

/*
	scan.asm
*/

P_NUM_DIR_ENTRIES:
	.fill 1, 0
P_BUFFER:
P_DIR_BUFFER:
	.fill V_DIR_SIZE, 0
ZP_SCAN_SIZETEXT:
	.fill 2, 0
ZP_EFS_ENTRY:
	.fill 2, 0

/*
	input.asm
*/

ZP_INPUT_KEYTABLE:
	.fill 2, 0
ZP_INPUT_LAST_CHAR:
	.fill 1, 0
ZP_INPUT_MATRIX:
	.fill 1, 0

/*
	menu.asm
*/

P_SCREENSAVER_COUNTER:
	.fill 2, 0
P_SCREENSAVER_BANK:
	.fill 1, 0
P_SCREENSAVER_OFS:
	.fill 1, 0

/*
    tools.asm
*/

P_GEN_BUFFER:
	.fill 3, 0
P_BINBCD_IN:
	.fill 2, 0
P_BINBCD_OUT:
	.fill 3, 0
P_LED_STATE:
	.fill 1, 0

/*
    search.asm
*/

.const V_SEARCH_MAX_CHAR = 9

P_SEARCH_POS:
	.fill 1, 0
P_SEARCH_START:
	.fill 1+V_SEARCH_MAX_CHAR, 0
P_SEARCH_COUNT:
	.fill 1+V_SEARCH_MAX_CHAR, 0
P_SEARCH_ACTIVE:
	.fill 1, 0


/**/
/*   OTHER VARS  */
/**/

// free space $2800 til P_DIR

/*
	scan.asm
*/

.const P_DIR = $4e00 // til $7fff (256 * V_DIR_SIZE)
