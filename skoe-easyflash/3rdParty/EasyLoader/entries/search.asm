.print ">search.asm"

.const debug_search = false
.const debug_search_counts = false

F_SEARCH_INIT:{
	:mov #0 ; P_SEARCH_POS
	:mov #0 ; P_SEARCH_START
	ldx P_NUM_DIR_ENTRIES
	stx P_SEARCH_COUNT
	// search is inactive
	:mov #$1 ; P_SEARCH_ACTIVE
	rts
}

.const P_SEARCH_SCREEN_OUT = $0400 + 6*40 + 28
.const P_SEARCH_COLOR_OUT = $d800 + 6*40 + 28

F_SEARCH_START:{
	ldx P_SEARCH_POS
	jmp F_SEARCH_DRAW
}

F_SEARCH_KEY:{
	.const char = P_BINBCD_OUT+0
	.const start = P_BINBCD_OUT+1
	.const count = P_BINBCD_OUT+2
	.const max_count = P_BINBCD_IN+0

	// laod pos
	ldx P_SEARCH_POS
	// check for 16 chars
	cpx #V_SEARCH_MAX_CHAR
	bne !skip+
	rts
!skip:
	// fine
	// store them
	sta char
	sta P_SEARCH_SCREEN_OUT, x
	lda #WHITE
	sta P_SEARCH_COLOR_OUT, x
	lda P_SEARCH_START, x
	sta start
	lda P_SEARCH_COUNT, x
	sta count
	sta max_count
	// inc to next pos
	inx
	stx P_SEARCH_POS
	
	// if the prev. search narrows it to one -> we're done
	lda count
	cmp #1
	beq done
	
	// ok, search for the first and last occ. whithin the specified entries

	// abslute first entry
	:mov16 #P_DIR - V_DIR_SIZE ; ZP_ENTRY
	// go to the start offset
	ldx start
	beq !skip+
!loop:
	:add16_8 ZP_ENTRY ; #V_DIR_SIZE
	dex
	bne !loop-
!skip:
	
	// setup filename-position
	:add P_SEARCH_POS ; #O_DIR_UNAME-1 ; A
	tay
	
	// correct count
	dec start
	
search_start:
	// go to next entry
	:add16_8 ZP_ENTRY ; #V_DIR_SIZE
	inc start

	// find first entry whith that char
	lda (ZP_ENTRY), y
	cmp char
	bcc next_line // match too low
	beq search_end_init // found a char
	bne not_found // didn't found the char
	
next_line:
	// decrement max counter
	dec max_count
	// if not empty -> try next line
	bne search_start
not_found:
	// entry not found!
	dec max_count
	bne error_last_file
	dec max_count
	bne error_last_file
error_next_file:
	// jump to the next file
	inc start
error_last_file:
	// we're already on the last line: don't advance
	:mov #1 ; count
	jmp done

search_end_init:
	:mov #0 ; count
search_end:
	// go to next entry
	:add16_8 ZP_ENTRY ; #V_DIR_SIZE
	inc count

	// find first entry whith that char
	lda (ZP_ENTRY), y
	cmp char
//	bcc next_line // match too low -- can't happen
	bne done // didn't found the char
//	beq next_line_end // found a char
	
next_line_end:
	dec max_count
	beq done
	bne search_end
	
done:
	ldx P_SEARCH_POS
	:mov start ; P_SEARCH_START, x
	sta P_DRAW_OFFSET
	:mov count ; P_SEARCH_COUNT, x
}

F_SEARCH_DRAW:{
	// draw search box (not the contents
	lda #$60
	sta P_SEARCH_SCREEN_OUT, x
	lda #CYAN
	sta P_SEARCH_COLOR_OUT, x
	ldx #12
!loop:
	lda line1, x
	sta $0400 + 5*40 + 26, x
	lda #$82
	sta $0400 + 7*40 + 26, x
	lda #CYAN
	sta $d800 + 5*40 + 26, x
	sta $d800 + 7*40 + 26, x
	dex
	bpl !loop-
	lda #$80
	sta $0400 + 6*40 + 26 + 0
	lda #$84
	sta $0400 + 6*40 + 26 + 12
	lda #CYAN
	sta $d800 + 6*40 + 26 + 0
	sta $d800 + 6*40 + 26 + 12
	lda #$81
	sta $0400 + 7*40 + 26 + 0
	lda #$83
	sta $0400 + 7*40 + 26 + 12
	// >
	lda #$3e
	sta $0400 + 6*40 + 26 + 1
	lda #WHITE
	sta $d800 + 6*40 + 26 + 1
	
	// search is active
	:mov #$0 ; P_SEARCH_ACTIVE
	
	// draw screen
	:mov #0 ; P_DRAW_START
.if(debug_search){
	jsr deb_sea
}
	jmp F_DRAW // includes rts

line1:
	.byte $00, $f3, $c5, $c1, $d2, $c3, $c8, $a0, $01, $01, $01, $01, $02
}

F_SEARCH_DEL:{
	dec P_SEARCH_POS
//	beq F_SEARCH_RESET
	bmi F_SEARCH_RESET
	ldx P_SEARCH_POS
	lda #$60
	sta P_SEARCH_SCREEN_OUT, x
	lda #CYAN
	sta P_SEARCH_COLOR_OUT, x
	lda #$20
	sta P_SEARCH_SCREEN_OUT+1, x
	:mov P_SEARCH_START, x ; P_DRAW_OFFSET
	:mov #0 ; P_DRAW_START
.if(debug_search){
	jsr deb_sea
}
	jmp F_DRAW // includes rts
}

F_SEARCH_RESET:{
	// search is inactive
	:mov #$1 ; P_SEARCH_ACTIVE

	:mov #0 ; P_SEARCH_POS
	ldx #12
!loop:
	lda line1, x
	sta $0400 + 5*40 + 26, x
	lda line2, x
	sta $0400 + 6*40 + 26, x
	lda line3, x
	sta $0400 + 7*40 + 26, x
	lda #LIGHT_BLUE
	sta $d800 + 5*40 + 26, x
	sta $d800 + 6*40 + 26, x
	sta $d800 + 7*40 + 26, x
	dex
	bpl !loop-
	rts
	
	
line1:
	.fill 13, the_complete_start_screen.get(5*40 + 26 + i)
line2:
	.fill 13, the_complete_start_screen.get(6*40 + 26 + i)
line3:
	.fill 13, the_complete_start_screen.get(7*40 + 26 + i)
}

.if(debug_search){
	.const count = P_BINBCD_OUT+2
	.const max_count = P_BINBCD_IN+0

deb_sea:{
	ldx #0
.if(debug_search_counts){
	lda max_count
	pha
	lda count
	sta P_BINBCD_IN
	jsr F_BINBCD_8BIT
	lda P_BINBCD_OUT+1
	jsr F_BCDIFY_BUF
	lda P_BINBCD_OUT+0
	jsr F_BCDIFY_BUF

	lda #$82
	sta P_DIR_BUFFER, x
	inx

	pla

	sta P_BINBCD_IN
	jsr F_BINBCD_8BIT
	lda P_BINBCD_OUT+1
	jsr F_BCDIFY_BUF
	lda P_BINBCD_OUT+0
	jsr F_BCDIFY_BUF

	lda #$82
	sta P_DIR_BUFFER, x
	inx

}

	ldy P_SEARCH_POS
	lda P_SEARCH_START, y

	sta P_BINBCD_IN
	jsr F_BINBCD_8BIT
	lda P_BINBCD_OUT+1
	jsr F_BCDIFY_BUF
	lda P_BINBCD_OUT+0
	jsr F_BCDIFY_BUF

	lda #$82
	sta P_DIR_BUFFER, x
	inx

	ldy P_SEARCH_POS
	lda P_SEARCH_COUNT, y

	sta P_BINBCD_IN
	jsr F_BINBCD_8BIT
	lda P_BINBCD_OUT+1
	jsr F_BCDIFY_BUF
	lda P_BINBCD_OUT+0
	jsr F_BCDIFY_BUF
	
	dex
!loop:
	lda P_DIR_BUFFER, x
	.if(debug_search_counts){
		sta $0400+24*40+16, x
	}else{
		sta $0400+24*40+30, x
	}
	dex
	bpl !loop-
	rts
}
}
