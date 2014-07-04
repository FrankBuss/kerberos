.print ">basic.asm"

F_BASIC:{
	
	jsr F_LAST_CONFIG_WRITE

	// set screen $20
	lda #$20
	ldx #$00
!loop:
	.for(var i=0; i<4; i++){
		sta $0400+i*$100, x
	}
	dex
	bne !loop-

	ldx #[F_BASIC_SUB_end - F_BASIC_SUB_beginn]-1
!loop:
	lda F_BASIC_SUB_beginn, x
	sta $02, x
	dex
	bpl !loop-

	jmp $02

F_BASIC_SUB_beginn:{
	lda #MODE_RAM
	sta IO_MODE
	jmp ($fffc)
}
F_BASIC_SUB_end:

}
