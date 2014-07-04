.print ">draw.asm"

F_DRAW:{

	.const debug = false

	.const KEEP_CLEAR = 5
	.const PAGE_SCROLL = 15
	
	.var P_BOLD_LINE = P_BINBCD_IN
	
	// check for correct values

	:if P_NUM_DIR_ENTRIES ; LT ; #23 ; ELSE ; multi_page
		// ONE PAGE!
		
		// we're always on page 0 (single page mode)
		:mov #0 ; P_DRAW_START
		
		lda P_DRAW_OFFSET
		bpl !else+
			// offset < 0 -> make 0 (first entry)
			:mov #0 ; P_DRAW_OFFSET
			beq !endif+
		!else:
			// offset >= 0
			:if A ; GE ; P_NUM_DIR_ENTRIES ; ENDIF ; !endif+
				// offset > #enties -> make last entry
				lda P_NUM_DIR_ENTRIES
				sta P_DRAW_OFFSET
				dec P_DRAW_OFFSET
		!endif:
		
		jmp end_check
	multi_page:

	!while:
		// while P_DRAW_OFFSET < 0
		lda P_DRAW_OFFSET
		bpl !end_while+
		// P_DRAW_OFFSET+=23
		clc
		adc #23
		sta P_DRAW_OFFSET
		// P_DRAW_START-=23
		lda P_DRAW_START
		sec
		sbc #PAGE_SCROLL
		sta P_DRAW_START
		bcs !while-
		// if P_DRAW_START < 0
		lda #0
		sta P_DRAW_START
		sta P_DRAW_OFFSET
	!end_while:

.if(debug){
	ldx #0*6
	lda P_DRAW_OFFSET
	sta P_BINBCD_IN
	jsr F_BINBCD_8BIT
	lda P_BINBCD_OUT
	jsr F_BCDIFY_BUF
	lda #$40
	sta P_DIR_BUFFER,x
	inx
	lda P_DRAW_START
	sta P_BINBCD_IN
	jsr F_BINBCD_8BIT
	lda P_BINBCD_OUT
	jsr F_BCDIFY_BUF
	lda #$20
	sta P_DIR_BUFFER,x
	inx
}
	
	!while:
		// while P_DRAW_OFFSET >= 23
		lda P_DRAW_OFFSET
		:if A ; LT ; #23 ; !end_while+
		// P_DRAW_OFFSET-=23
		sec
		sbc #PAGE_SCROLL
		sta P_DRAW_OFFSET
		// P_DRAW_START+=23
		lda P_DRAW_START
		clc
		adc #PAGE_SCROLL
		sta P_DRAW_START
		bcc !while-
		// if P_DRAW_START > 255
		:mov P_DRAW_LAST_START ; P_DRAW_START
		:mov #22 ; P_DRAW_OFFSET
	!end_while:

.if(debug){
	ldx #1*6
	lda P_DRAW_OFFSET
	sta P_BINBCD_IN
	jsr F_BINBCD_8BIT
	lda P_BINBCD_OUT
	jsr F_BCDIFY_BUF
	lda #$40
	sta P_DIR_BUFFER,x
	inx
	lda P_DRAW_START
	sta P_BINBCD_IN
	jsr F_BINBCD_8BIT
	lda P_BINBCD_OUT
	jsr F_BCDIFY_BUF
	lda #$20
	sta P_DIR_BUFFER,x
	inx
}

		// if P_DRAW_START > last start
		:if P_DRAW_START ; GT ; P_DRAW_LAST_START ; ENDIF ; !endif+
			:sub P_DRAW_LAST_START ; P_DRAW_START ; P_DRAW_START
			:sub P_DRAW_OFFSET ; P_DRAW_START ; A
			:if A ; GE ; #23 ; ENDIF ; !endif2+
				lda #22
			!endif2:
			sta P_DRAW_OFFSET
			:mov P_DRAW_LAST_START ; P_DRAW_START
		!endif:

.if(debug){
	ldx #2*6
	lda P_DRAW_OFFSET
	sta P_BINBCD_IN
	jsr F_BINBCD_8BIT
	lda P_BINBCD_OUT
	jsr F_BCDIFY_BUF
	lda #$40
	sta P_DIR_BUFFER,x
	inx
	lda P_DRAW_START
	sta P_BINBCD_IN
	jsr F_BINBCD_8BIT
	lda P_BINBCD_OUT
	jsr F_BCDIFY_BUF
	lda #$20
	sta P_DIR_BUFFER,x
	inx
}
		
	!while:
		:if P_DRAW_OFFSET ; GE ; #KEEP_CLEAR ; !end_while+
		:if P_DRAW_START ; EQ ; #0 ; !end_while+
		inc P_DRAW_OFFSET
		dec P_DRAW_START
		jmp !while-
	!end_while:

.if(debug){
	ldx #3*6
	lda P_DRAW_OFFSET
	sta P_BINBCD_IN
	jsr F_BINBCD_8BIT
	lda P_BINBCD_OUT
	jsr F_BCDIFY_BUF
	lda #$40
	sta P_DIR_BUFFER,x
	inx
	lda P_DRAW_START
	sta P_BINBCD_IN
	jsr F_BINBCD_8BIT
	lda P_BINBCD_OUT
	jsr F_BCDIFY_BUF
	lda #$20
	sta P_DIR_BUFFER,x
	inx
}
		
	!while:
		:if P_DRAW_OFFSET ; LT ; #23-KEEP_CLEAR ; !end_while+
		:if P_DRAW_START ; EQ ; P_DRAW_LAST_START ; !end_while+
		dec P_DRAW_OFFSET
		inc P_DRAW_START
		jmp !while-
	!end_while:
	
.if(debug){
	ldx #4*6
	lda P_DRAW_OFFSET
	sta P_BINBCD_IN
	jsr F_BINBCD_8BIT
	lda P_BINBCD_OUT
	jsr F_BCDIFY_BUF
	lda #$40
	sta P_DIR_BUFFER,x
	inx
	lda P_DRAW_START
	sta P_BINBCD_IN
	jsr F_BINBCD_8BIT
	lda P_BINBCD_OUT
	jsr F_BCDIFY_BUF
	lda #$20
	sta P_DIR_BUFFER,x

!loop:
	lda P_DIR_BUFFER,x
	sta $0400 + 24*40 + 1, x
	dex
	bpl !loop-
	
}
	
	
	end_check:


	
	:mov16 #P_DIR ; ZP_ENTRY
	:mov16 #$0400+40+1 ; ZP_DRAW_PTR
	:mov P_DRAW_OFFSET ; P_BOLD_LINE

	ldx P_DRAW_START
	beq !skip+
!loop:
	:add16_8 ZP_ENTRY ; #V_DIR_SIZE
	dex
	bne !loop-
!skip:

	lda P_NUM_DIR_ENTRIES
	bne !skip+
	// zero entries
	ldx #22
	jmp draw_empty
!skip:
	:sub A ; P_DRAW_START
	:if A ; Gx ; #23 ; ENDIF ; !endif+
		lda #23
	!endif:
	sta P_DRAW_LINES_DIR
	tax
	dex

!bigloop:
	
	// draw a line
	ldy #O_DIR_TYPE-1
	
	lda P_BOLD_LINE
	beq !bold+

!loop:
	lda (ZP_ENTRY), y
	sta (ZP_DRAW_PTR), y
	dey
	bpl !loop-
	bmi !next+

!bold:
!loop:
	lda (ZP_ENTRY), y
	eor #$80
	sta (ZP_DRAW_PTR), y
	dey
	bpl !loop-

!next:	
	dec P_BOLD_LINE
	
	:add16_8 ZP_ENTRY ; #V_DIR_SIZE
	:add16_8 ZP_DRAW_PTR ; #40

	dex
	bpl !bigloop-
	
	// draw empty
	lda #23
	:sub A ; P_DRAW_LINES_DIR
	beq finish
	tax
	dex

draw_empty:
!bigloop:
	
	// draw a line
	ldy #O_DIR_TYPE-1
	lda #32
!loop:
	sta (ZP_DRAW_PTR), y
	dey
	bpl !loop-

	:add16_8 ZP_DRAW_PTR ; #40
	
	dex
	bpl !bigloop-

finish:

	/*
	** SLIDER!
	*/

	.const before_slider = P_BUFFER+6
	.const after_slider = P_BUFFER+7
	
	// init ptr to screen+colmem
	:mov16 #$400+40+25 ; ZP_ENTRY
	:mov16 #$d800+40+25 ; COL_SRC_LO

	// check waether to draw a slider
	lda P_DRAW_SLIDER_SIZE
	bne has_slider

	// no slider!
	:mov #23 ; after_slider
	ldy #0
	jmp last_part

has_slider:

	// calc position of slider
	.const src1 = P_BUFFER+0
	.const src2 = P_BUFFER+2
	.const dst = P_BUFFER+4

	:mov16 P_DRAW_SLIDER_FAC ; src1

	:mov P_DRAW_START ; src2

	:mul16_8 src1 ; src2 ; dst

	ldx dst+1
	lda dst+0
	bpl !skip+
	inx
!skip:
	stx before_slider
	// middle = size
	lda #23
	sec
	sbc P_DRAW_SLIDER_SIZE
	sbc before_slider
	sta after_slider

	ldy #0
	
	// draw 'before_slider'
	
	ldx before_slider
	beq middle_part
	
!loop:
	:mov #$84 ; (ZP_ENTRY), y
	:mov #color_slider_off ; (COL_SRC_LO), y
	jsr f_next_line
	dex
	bne !loop-

middle_part:	
	
	// draw top thing
	:mov #$03 ; (ZP_ENTRY), y
	:mov #color_slider_on ; (COL_SRC_LO), y
	jsr f_next_line

	// draw middle thing (if needed)
	ldx P_DRAW_SLIDER_SIZE
	dex
	dex
	beq !skip+
!loop:
	:mov #$04 ; (ZP_ENTRY), y
	:mov #color_slider_on ; (COL_SRC_LO), y
	jsr f_next_line
	dex
	bne !loop-
!skip:
	// draw bottom thing
	:mov #$05 ; (ZP_ENTRY), y
	:mov #color_slider_on ; (COL_SRC_LO), y
	jsr f_next_line

last_part:

	// draw 'after_slider'
	ldx after_slider
	beq return
	
!loop:
	:mov #$84 ; (ZP_ENTRY), y
	:mov #color_slider_off ; (COL_SRC_LO), y
	jsr f_next_line
	dex
	bne !loop-

	
return:	
	rts
	
f_next_line:
	:add16_8 ZP_ENTRY ; #40
	:add16_8 COL_SRC_LO ; #40
	rts
}

F_DRAW_PRECALC:{
	:if P_NUM_DIR_ENTRIES ; LE ; #23 ; ELSE ; !skip+
	// we have <= 23 enties -> single page
	:mov #0 ; P_DRAW_SLIDER_SIZE
	rts
!skip:
	// more than a page
	.const src1 = P_BUFFER+0
	.const src2 = P_BUFFER+2
	.const rem = P_BUFFER+4
	// calc size
	:mov16 #23*23 ; src1
	:mov P_NUM_DIR_ENTRIES ; src2+0
	:mov #0 ; src2+1
	// will destory first byte of P_DRAW_SLIDER_FAC (will be clac'ed later)
	:div16_round src1 ; src2 ; P_DRAW_SLIDER_SIZE ; rem ; X
	// basic checks: size soulf be 2-22
	:if P_DRAW_SLIDER_SIZE ; LT ; #2 ; ELSE ; !else+
		// size < 2 -> make it two
		:mov #2 ; P_DRAW_SLIDER_SIZE
		jmp !endif+
	!else: :if P_DRAW_SLIDER_SIZE ; GT ; #22 ; ENDIF ; !endif+
		:mov #22 ; P_DRAW_SLIDER_SIZE
	!endif:

	// calc factor
	:mov #0 ; src1+0
	:sub #23 ; P_DRAW_SLIDER_SIZE ; [P_BUFFER+1]
	:mov P_DRAW_LAST_START ; src2+0
	:mov #0 ; src2+1
	:div16_round src1 ; src2 ; P_DRAW_SLIDER_FAC ; rem ; X
	
	rts
}