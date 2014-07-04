
.const MODE_RAM = $04
.const MODE_16k = $07
.const MODE_8k  = $06
.const MODE_ULT = $05

.const IO_MODE = $de02

/*
**
**	INCLUDE DEFINITIONS, MACROS & CO
**
*/

.import source "helper/commands.asm"
.import source "helper/commands8.asm"
.import source "helper/commands16.asm"
.import source "helper/macros.asm"

.import source "const.asm"

.import source "vars.asm"

.import source "build/screen.asm"

/*
**
**  THE START OF THE MODULE
**
*/

.pc = EASYLOADER_STARTADDRESS "Jump Address"
	.word F_START

/*
**
**  ROUTINES
**
*/

.pc = * "Subs"

.import source "entries/draw.asm"
.import source "entries/scan.asm"
.import source "entries/search.asm"
.import source "entries/sort.asm"

.import source "helper/tools.asm"

.import source "loader/common.asm"
.import source "loader/basic.asm"
.import source "loader/cart.asm"
.import source "loader/file.asm"

.import source "screen/colors.asm"
.import source "screen/init.asm"

.import source "ui/input.asm"
.import source "ui/last_config.asm"
.import source "ui/menu.asm"

.pc = * "Start"
F_START:
	
	// init basics!!
	sei
	ldx #$ff
	txs
	cld
	stx $8004 // no CBM80
	:mov #$e7 ; $01
	:mov #$2f ; $00

	// check for /^boot(.crt)?$/
	jsr F_LAST_CONFIG_READ

	// init SID
	ldx #$19-1
	lda #$00
!loop:
	sta $d400, x
	dex
	bpl !loop-

	// init VIC2
	ldx #[ini_d000_end-ini_d000]-1
!loop:
	lda ini_d000, x
	sta $d000, x
	dex
	bpl !loop-

	// init CIA1/2
	ldx #[ini_dc00_dd00_end-ini_dc00_dd00]-1
!loop:
	lda ini_dc00_dd00, x
	sta $dc00, x
	sta $dd00, x
	dex
	bpl !loop-

	jsr F_INIT_SCREEN

	ldx #0
!loop:
	.for(var i=0; i<8; i++){
		lda CHARSET + i*$0100, x
		sta $2000 + i*$0100, x
	}
	inx
	bne !loop-

	jsr F_INIT_COLORS

	:mov #$9b ; $d011
	:mov #$ff ; $d015

	:mov #MODE_16k ; P_LED_STATE
	
	jsr F_SCAN_DIR
	jsr F_SORT
	jsr F_SEARCH_INIT
	
	jsr F_CLEAR_COLORS

	jsr F_DRAW

	jmp F_MENU

.pc = * "init-data"


ini_d000:
{

	// sprite data
	.const left_pos = $e9
	.const top_pos = $40
	
	.byte left_pos+0*24, top_pos, left_pos+1*24, top_pos, left_pos+2*24, top_pos, left_pos+3*24, top_pos
	.byte left_pos+5*8, top_pos, left_pos+5*8, top_pos, left_pos+5*8-4, top_pos+20*8, left_pos+5*8-4, top_pos+20*8

	.byte $fe, $8b, $37, $00, $00, $00, $08, $00
	.byte $19, $71, $f0, $00, $00, $00, $00, $00
	.byte $f0, $f0, $f0, $f0, $f0, $f0, $f0
	.byte $fc, $fc, $fc, $fc, $f8, $f9, $f8, $f9
}
ini_d000_end:

ini_dc00_dd00:
	.byte $ff, $ff, $00, $00, $ff, $ff, $ff, $ff, $00, $00, $00, $01, $00, $00, $00, $00
ini_dc00_dd00_end:


.pc = [EASYLOADER_STARTADDRESS + $1800] "FONT"
CHARSET:
	:CharSet("graphics/easyloader_font.png")
