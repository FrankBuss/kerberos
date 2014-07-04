.print ">menu.asm"

F_MENU:{
	jsr F_INPUT_INIT
	
main_loop:
	// reset screensaver (after a keystroke)
	lda #$00
	sta P_SCREENSAVER_COUNTER+0
	sta P_SCREENSAVER_COUNTER+1
main_loop2:
	// inc screensaver
	:inc16 P_SCREENSAVER_COUNTER
	:if P_SCREENSAVER_COUNTER+1 ; GE ; #180 ; JMP ; start_saver
	jsr F_INPUT_GETKEY
	beq main_loop2

	:if A ; EQ ; #V_KEY_F2 ; JMP ; F_BASIC

	// if no enties -> don't move
	ldx P_NUM_DIR_ENTRIES
	beq main_loop

	:if A ; EQ ; #V_KEY_CUP ; move_up
	:if A ; EQ ; #V_KEY_CDOWN ; move_down
	:if A ; EQ ; #V_KEY_CLEFT ; JMP ; page_up
	:if A ; EQ ; #V_KEY_CRIGHT ; page_down
	:if A ; EQ ; #V_KEY_RETURN ; JSR ; F_LAUNCH // may returns
	:if A ; EQ ; #V_KEY_DEL ; JSR ; F_SEARCH_DEL
	:if A ; EQ ; #V_KEY_CLR ; JSR ; F_SEARCH_RESET
	
	ldx P_SEARCH_ACTIVE
	bne !else2+
		// search box is active.
		// get almost all keys into search
	
		// every printable char (except uppercse and control chars)
		:if A ; GE ; #$20 ; ENDIF ; !endif+
			:if A ; LE ; #$5a ; JSR ; F_SEARCH_KEY
		!endif:
		jmp !endif2+
	!else2:
		// seauch box is inactive.
		// only 0..9 and a..z and / (prints no char) will trigger search

		// key 0..9
		:if A ; GE ; #$30 ; ENDIF ; !endif+
			:if A ; LE ; #$39 ; JSR ; F_SEARCH_KEY
		!endif:
		// key a..z
		:if A ; GE ; #$41 ; ENDIF ; !endif+
			:if A ; LE ; #$5a ; JSR ; F_SEARCH_KEY
		!endif:
		:if A ; EQ ; #$2f ; JSR ; F_SEARCH_START
		:if A ; EQ ; #$3f ; JMP ; show_version
			
	!endif2:
	
	jmp main_loop

move_up:
	dec P_DRAW_OFFSET
	jmp draw_screen

move_down:
	inc P_DRAW_OFFSET
	jmp draw_screen

page_up:
	:sub P_DRAW_OFFSET ; #23
	jmp draw_screen

page_down:
	:add P_DRAW_OFFSET ; #23
//	jmp draw_screen

draw_screen:
	lda P_SEARCH_POS
	beq !skip+
	jsr F_SEARCH_RESET
!skip:
	jsr F_DRAW
	jmp main_loop

/*
	version info	
*/

show_version:
	ldx #12
!loop:
	lda ts, x
	sta $0400 + 24*40 + 26, x
	dex
	bpl !loop-
	
!loop:
	jsr F_GETIN
	cmp #$3f
	beq !loop-
	
	ldx #12
	lda #$82
!loop:
	sta $0400 + 24*40 + 26, x
	dex
	bpl !loop-
	
	jmp main_loop
	
ts:
	.import binary "build/ts.txt"

/*
	screen saver
*/

start_saver:
	// copy boot-code
	:copy_to_df00 COPY_STARTSAVER_START ; COPY_STARTSAVER_END - COPY_STARTSAVER_START
	// do boot
	jmp $df00

COPY_STARTSAVER_START:
.pseudopc $df00 {
	// load bank
	lda P_SCREENSAVER_BANK
	beq !no_saver+

	// store bank (lower 8bit)
	sta $de00
	sta $df00

	// store bank (higher 8bit)
	lda #$00
	sta $df01

	// load and use offset
	lda P_SCREENSAVER_OFS
	sta smc_jsr+2
smc_jsr:
	jsr $0000 // upper byte will be filled with P_SCREENSAVER_OFS
	
	lda #EASYLOADER_BANK
	sta $de00
!no_saver:
	jmp main_loop
}
COPY_STARTSAVER_END:

}
