.print ">colors.asm"


F_INIT_COLORS:
	:mov16 #$d800 + 24*40 ; COL_DST_LO
	:mov #col_pattern>>8 ; COL_SRC_HI
	ldx #24
!loop:
	lda col_pattern, x
	sta COL_SRC_LO
	ldy #39
!loop2:
	lda (COL_SRC_LO),y
	sta (COL_DST_LO),y
	dey
	bpl !loop2-
	
	:sub16_8 COL_DST_LO ; #40
	
	dex
	bpl !loop-
	rts
	
F_CLEAR_COLORS: // clear the colors th the wait-box
	
	:mov16 #$d800 + 14*40 ; COL_DST_LO
	:mov16 #col_line_help ; COL_SRC_LO
	ldx #5
!loop:
	ldy #39
!loop2:
	lda (COL_SRC_LO),y
	sta (COL_DST_LO),y
	dey
	bpl !loop2-
	
	:sub16_8 COL_DST_LO ; #40
	
	dex
	bpl !loop-
	rts
	


