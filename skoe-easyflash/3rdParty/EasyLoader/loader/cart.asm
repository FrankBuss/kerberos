.print ">cart.asm"

F_LAUNCH_CRT:{

	jsr F_RESET_GRAPHICS

	ldy #O_DIR_BANK
	lda (ZP_ENTRY), y
	sta $1fe
	ldy #O_DIR_MODULE_MODE
	lda (ZP_ENTRY), y
	sta $1ff

}

F_LAUNCH_CRT_PART2:{

	jsr F_LAST_CONFIG_WRITE

	// fill memory as before!!!
	lda #0
	tax
!loop:
	sta $00, x
	.byte $9d, $fe, $00 // == sta $00fe, x (which is not sta $fe, x)
//	sta $0100, x
	inx
	bne !loop-
/*	
	ldx #63
!loop:
	lda #0
	.for(var i=$200; i<$8000; i=i+128){
		sta i,x
	}
	lda #$ff
	.for(var i=$240; i<$8000; i=i+128){
		sta i,x
	}
	dex
	bmi !skip+
	jmp !loop-
!skip:

*/


//	:mov #$00 ; $00

	// copy launch prog	
	ldy #[LCOPY_END - LCOPY_START]-1
!loop:
	lda LCOPY_START, y
	sta $1fe-[LCOPY_END - LCOPY_START], y
	dey
	bpl !loop-
	
	ldx #$fd
	txs
	
	jmp $1fe-[LCOPY_END - LCOPY_START]	

LCOPY_START:
{
	// this code may be placed everywhere!
//	lda #$01
//	bne *
	// switch bank ($8000-$ffff is now undefined!!)
	pla
	sta $de00
	sta $df00
	lda #$00
	sta $df01
	pla
	sta IO_MODE

	// jump to reset routine
	jmp ($fffc)
}
LCOPY_END:

}	
