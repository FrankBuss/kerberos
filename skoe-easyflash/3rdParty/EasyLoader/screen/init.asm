.print ">init.asm"

F_INIT_SCREEN:{

	.var SRC = P_BINBCD_IN
	.var DST = P_BINBCD_OUT
	.var count = P_BINBCD_OUT+2
	
	:mov16 #screen_to_decode ; SRC
	:mov16 #start_screen_decode ; DST

big_loop:
	ldy #0
	lda (SRC), y
	beq return // 0 == end
	bmi copy // $80-$ff = copy 1 char x times
// pass trough
	tay // how many to copy
	tax // just remember
	:inc16 SRC
	dey
!loop:
	lda (SRC), y
	sta (DST), y
	dey
	bpl !loop-
	txa
	//
	clc
	adc SRC+0
	sta SRC+0
	bcc !skip+
	inc SRC+1
!skip:
	//
	txa
	//
	clc
	adc DST+0
	sta DST+0
	bcc !skip+
	inc DST+1
!skip:
	//
	jmp big_loop
	
copy:
	sta count // remember how often to copy
	iny
	lda (SRC), y
	ldx count // how often
	dey // y -> 0
!loop:
	sta (DST), y
	iny
	inx
	bne !loop-
	:inc16 SRC
	:inc16 SRC
	sec
	lda #0
	sbc count
	//
	clc
	adc DST+0
	sta DST+0
	bcc !skip+
	inc DST+1
!skip:
	//
	jmp big_loop

return:
	rts

screen_to_decode:
	.import binary "build/screen.bin"

}
