.print ">scan.asm"

F_SCAN_DIR:{

	.var FILESYSTEM_START_ADDR = $a000

	.if(EASYLOADER_BANK != EASYFILESYSTEM_BANK){
		.eval FILESYSTEM_START_ADDR = $6800

		// copy read-addr routine to $df00
		:copy_to_df00 COPY_FILESYSTEM_START ; COPY_FILESYSTEM_END - COPY_FILESYSTEM_START

		// copy the directory
		jsr F_COPY_FILESYSTEM
	}

	// copy read-addr routine to $df00
	:copy_to_df00 READ_LOADADDR_START ; READ_LOADADDR_END - READ_LOADADDR_START

	:mov16 #[FILESYSTEM_START_ADDR - V_EFS_SIZE] ; ZP_EFS_ENTRY
	:mov16 #P_DIR ; ZP_ENTRY
	:mov #0 ; P_NUM_DIR_ENTRIES
	:mov #0 ; P_SCREENSAVER_BANK // no screensaver for now

big_loop:
	:add16_8 ZP_EFS_ENTRY ; #V_EFS_SIZE
	
	// copy TYPE,BANK,OFFSET,SIZE to BUFFER (maybe not used...)
	// parts of the DIR name is scrambled
	ldy #V_EFS_SIZE - 1
!loop:
	lda (ZP_EFS_ENTRY), y
	sta P_DIR_BUFFER + O_DIR_TYPE - O_EFS_TYPE, y
	dey
	bpl !loop-

	// check for screen saver
			ldy #$00
		!loop:
			// check a char
			lda (ZP_EFS_ENTRY), y
			cmp screen_saver, y
			bne !no_saver+
			
			iny
			cpy #[screen_saver_end - screen_saver]
			bne !loop-			

		// found screen saver!
		ldy #$80
		lda P_DIR_BUFFER + O_DIR_TYPE
		and #O_EFST_MASK
		cmp #O_EFST_8KULTCRT
		bne !skip+
		ldy #$a0
	!skip:
		and #$10 // check for crt
		beq !no_saver+
		sty P_SCREENSAVER_OFS
		lda P_DIR_BUFFER + O_DIR_BANK
		sta P_SCREENSAVER_BANK

!no_saver:
	
	// switch by type
	lda P_DIR_BUFFER + O_DIR_TYPE
	bmi maybe_hidden // negative number -> bit 7 set -> hidden file
	and #O_EFST_MASK
	:if A ; EQ ; #O_EFST_END ; JMP ; return // $1f -> EOF
	:if A ; EQ ; #O_EFST_FILE ; file
	:if A ; EQ ; #O_EFST_8KCRT ; rom8
	:if A ; EQ ; #O_EFST_16KCRT ; rom16
	:if A ; EQ ; #O_EFST_8KULTCRT ; romu8
	:if A ; EQ ; #O_EFST_16KULTCRT ; romu16
	jmp big_loop // 0 or unknown entry -> try next

maybe_hidden:
	and #O_EFST_MASK
	:if A ; EQ ; #O_EFST_END ; JMP ; return // $1f -> EOF
	jmp big_loop // is a hidden file	

rom8:
	lda #MODE_8k // set game/exrom correctly + $20 for overwrite jumper
	jmp romicon

rom16:
	lda #MODE_16k // set game/exrom correctly + $20 for overwrite jumper
	jmp romicon

romu8:
romu16:
	lda #MODE_ULT // set game/exrom correctly + $20 for overwrite jumper
	jmp romicon

file:
	// get offset whithin first bank
	lda P_DIR_BUFFER + O_DIR_OFFSET+0
	sta ZP_SCAN_SIZETEXT+0
	lda P_DIR_BUFFER + O_DIR_OFFSET+1
	clc
	adc #$80
	sta ZP_SCAN_SIZETEXT+1

	// get bank
	lda P_DIR_BUFFER + O_DIR_BANK
	// read start-addr
	jsr F_READ_LOADADDR

	// check for a valid file
	:if P_DIR_BUFFER + O_DIR_SIZE+2 ; NE ; #$00 ; not_loadable // size >64k
	:if16 P_DIR_BUFFER + O_DIR_LOADADDR+1 ; LT ; #$01 ; not_loadable // loadaddr < $0100
	:sub16 P_DIR_BUFFER + O_DIR_LOADADDR ; #3 ; ZP_SCAN_SIZETEXT
	:add16 ZP_SCAN_SIZETEXT ; P_DIR_BUFFER + O_DIR_SIZE
	bcs not_loadable // laodaddr+size(minus 2 for laodaddr) > $ffff (future limit)
	:if ZP_SCAN_SIZETEXT+1 ; GE ; #$d0 ; not_loadable // >= $d000 (current limit)

	ldx #$7d
	jmp copyit

not_loadable:
	sta P_DIR_BUFFER+O_DIR_TYPE // 0 => type => not loadable
	ldx #$1f
	jmp copyit

romicon:
	// remember mode (8k,16k,ultimax)
	sta P_DIR_BUFFER + O_DIR_MODULE_MODE
	ldx #$7b
copyit:
	// copy icon (X) (part of the new name)
	stx P_DIR_BUFFER+0
	inx
	stx P_DIR_BUFFER+1


	// copy name
	ldy #O_EFS_TYPE-1
!loop:
	lda (ZP_EFS_ENTRY), y
	:if A ; EQ ; #$00 ; !ok+ // keep $00
	:if A ; LT ; #$20 ; !bad+ // $01-$1f => bad
	:if A ; EQ ; #$60 ; !bad+ // $60 => bad
	:if NOT ; A ; GT ; #$7a ; !ok+ // $7b-$ff => bad
!bad:
	lda #$2a // *
!ok:
	sta P_DIR_BUFFER+O_DIR_UNAME, y
	cmp #$00
	bne !skip+
	lda #$20
!skip:
	sta P_DIR_BUFFER+2, y
	dey
	bpl !loop-
	
	// create upper petscii name
	ldy #O_EFS_TYPE-1
!loop:
	lda P_DIR_BUFFER+O_DIR_UNAME, y
	:if A ; LT ; #$61 ; !skip+
	eor #$20
	sta P_DIR_BUFFER+O_DIR_UNAME, y
!skip:
	dey
	bpl !loop-
	
	ldx #18
	// a space
	lda #32
	sta P_DIR_BUFFER, x
	inx
	// size
	lda P_DIR_BUFFER + O_DIR_TYPE
	and #$10
	bne !at_least_xxxk+
	:if P_DIR_BUFFER + O_DIR_SIZE+2 ; NE ; #$00 ; !at_least_64k+
	:if16 P_DIR_BUFFER + O_DIR_SIZE ; LE ; #999 ; JMP ; show_bytes
	:if16 P_DIR_BUFFER + O_DIR_SIZE ; LE ; #[9.9*1024] ; JMP ; show_x_x_kbytes
!at_least_xxxk:
!at_least_64k:
	:if16 P_DIR_BUFFER + O_DIR_SIZE+1 ; LE ; #[[999*1024]>>8] ; JMP ; show_xxx_kbytes
	jmp show_x_x_mbytes
	
next_after_size:
	// end of line
	lda #$7f
	sta P_DIR_BUFFER, x

	// copy buffer
	ldy #V_DIR_SIZE-1
!loop:
	lda P_DIR_BUFFER, y
	sta (ZP_ENTRY), y
	dey
	bpl !loop-

	
	// next line
	:add16_8 ZP_ENTRY ; #V_DIR_SIZE
	inc P_NUM_DIR_ENTRIES
	jmp big_loop

return:
	// P_DRAW_LAST_START = max(0, P_NUM_DIR_ENTRIES-23)
	lda P_NUM_DIR_ENTRIES
	sec
	sbc #23
	bcs !skip+
	lda #0
!skip:
	sta P_DRAW_LAST_START

	// calc slider things
	jmp F_DRAW_PRECALC
	// return (thru rts in precalc)

show_bytes:
	:mov16 P_DIR_BUFFER + O_DIR_SIZE ; P_BINBCD_IN
	lda #$62
	jmp show_xxx
	
show_x_x_kbytes:
	:mov16 P_DIR_BUFFER + O_DIR_SIZE ; ZP_SCAN_SIZETEXT
	:asl16 ZP_SCAN_SIZETEXT
	:asl16 ZP_SCAN_SIZETEXT
	lda #$4b
	jmp show_x_x

show_xxx_kbytes:
	:mov16 P_DIR_BUFFER + O_DIR_SIZE+1 ; P_BINBCD_IN
	:lsr16 P_BINBCD_IN
	:lsr16 P_BINBCD_IN
	bcc !skip+
	// the last bit shifted down was set -> round
	:inc16 P_BINBCD_IN
!skip:
	lda #$4b
	jmp show_xxx

show_x_x_mbytes:
	:mov16 P_DIR_BUFFER + O_DIR_SIZE+1 ; ZP_SCAN_SIZETEXT
	lda #$4d
	jmp show_x_x



show_x_x:
	pha // keep unit
	:mov ZP_SCAN_SIZETEXT+1 ; P_BINBCD_IN
	lsr P_BINBCD_IN
	lsr P_BINBCD_IN
	lsr P_BINBCD_IN
	lsr P_BINBCD_IN

	// convert bin->dec
	jsr F_BINBCD_8BIT

	// display 1 digit
	lda P_BINBCD_OUT
	jsr F_BCDIFY_LOWER_BUF

	// display "."
	lda #$2e
	sta P_DIR_BUFFER, x
	inx

	// calculate the nachkommastelle
	lda ZP_SCAN_SIZETEXT+1
	and #$0f
	sta ZP_SCAN_SIZETEXT
	lsr
	lsr
	clc
	adc ZP_SCAN_SIZETEXT
	lsr
	jsr F_BCDIFY_LOWER_BUF
	
	// display unit
	pla
	sta P_DIR_BUFFER, x
	inx
	
	jmp next_after_size

show_xxx:
	pha // keep unit

	// convert bin->dec
	jsr F_BINBCD_10BIT

	// display 3 digits
	lda P_BINBCD_OUT+1
	jsr F_BCDIFY_LOWER_BUF
	lda P_BINBCD_OUT+0
	jsr F_BCDIFY_BUF
	
	// remove leading 0
	ldy #$fe
!loop:
	lda P_DIR_BUFFER+19-$fe, y
	cmp #$30
	bne !skip+
	lda #$20
	sta P_DIR_BUFFER+19-$fe, y
	iny
	bne !loop-
!skip:
	
	
	// display unit
	pla
	sta P_DIR_BUFFER, x
	inx
	
	jmp next_after_size

screen_saver:
	.byte $21, $45, $4c, $5f, $53, $43, $52, $45, $45, $4e, $2d, $53, $41, $56, $45, $52
screen_saver_end:

READ_LOADADDR_START:
.pseudopc $df00 {
F_READ_LOADADDR:
	sta $de00
	ldy #$00
	lda (ZP_SCAN_SIZETEXT), y
	sta P_DIR_BUFFER + O_DIR_LOADADDR+0
	iny
	lda (ZP_SCAN_SIZETEXT), y
	sta P_DIR_BUFFER + O_DIR_LOADADDR+1
	lda #EASYLOADER_BANK
	sta $de00
	rts
}
READ_LOADADDR_END:

.if(EASYLOADER_BANK != EASYFILESYSTEM_BANK){
COPY_FILESYSTEM_START:
.pseudopc $df00 {
F_COPY_FILESYSTEM:
	lda #EASYFILESYSTEM_BANK
	sta $de00

	ldx #$00
!loop:
smc_src:
	lda $a000, x
smc_dst:
	sta $6800, x
	inx
	bne !loop-
	inc smc_src+2
	inc smc_dst+2
	bpl !loop- // when src+2 ($60) is negatibe ($80) we are done

	lda #EASYLOADER_BANK
	sta $de00
	rts
}
COPY_FILESYSTEM_END:
}



}