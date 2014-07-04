.print ">file.asm"

F_LAUNCH_FILE:{

	jsr F_LAST_CONFIG_WRITE

	/*
	** CARTRIDGE IS ACTIVE
	** DATA in $02-$7fff
	**
	** EXTRACT DATA
	**
	** COPY ALL REQUIRED TO $df00-$dffb
	*/

	jsr F_RESET_GRAPHICS

	:copy_to_df00 FILE_EXT1_START ; FILE_EXT1_END - FILE_EXT1_START

	// copy bank,offset,size,loadaddr,name (part 1)
	ldy #O_DIR_BANK
!loop:
	lda (ZP_ENTRY), y
	sta P_BOSLN-O_DIR_BANK, y
	iny
	cpy #V_DIR_SIZE
	bne !loop-
	
	// create interger of loadaddr
	// convert bin->bcd
	:mov16 P_BOSLN-O_DIR_BANK + O_DIR_LOADADDR ; P_BINBCD_IN
	jsr F_BINBCD_16BIT
	// convert bcd->petscii
	ldx #$00
	lda P_BINBCD_OUT+2
	jsr F_BCDIFY_LOWER_BUF
	lda P_BINBCD_OUT+1
	jsr F_BCDIFY_BUF
	lda P_BINBCD_OUT+0
	jsr F_BCDIFY_BUF
	// srtip leading spaces
	ldx #0
!loop:
	lda P_BUFFER,x
	cmp #$30
	bne !skip+
	:mov #$20 ; P_BUFFER,x
	inx
	cpy #4
	bne !loop-
!skip:
	// copy to save place
	ldx #4
!loop:
	lda P_BUFFER,x
	sta P_SYS_NUMBERS,x
	dex
	bpl !loop-
	
	/*
	** DO A PARTIAL RESET (EVERYTHING EXCEPT I/O IS LOST)
	*/
	
	jmp DO_PARTIAL_RESET
BACK_FROM_PARTIAL_RESET:

	/*
	** SETUP A HOOK IN THE CHRIN VECTOR
	*/

	// change CHRIN vector
	lda $324
	sta SMC_RESTORE_LOWER+1
	lda $325
	sta SMC_RESTORE_UPPER+1

	// add our vector
	:mov16 #RESET_TRAP ; $324

	/*
	** DETECT A C64GS KERNAL, IF SO CREATE A SECOND TRAP (CHROUT VECTOR)
	*/
	
	:if16 $e449 ; EQ ; #$f72e ; ENDIF ; !endif+
		lda $326
		sta SMC_RESTORE_CHROUT_LOWER+1
		lda $327
		sta SMC_RESTORE_CHROUT_UPPER+1
		
		:mov16 #CHROUT_TRAP ; $326
	!endif:
	
	/*
	** DO THE REST OF THE RESET
	*/

	// continue reset-routine
	jmp GO_RESET
	
	/*
	** BACK IN CARTRIDGE
	*/


FILE_COPIER:
	// display >LOADING "xxx",EF,1<

	ldy #0
!loop:
	lda loading_1, y
	jsr $ffd2
	iny
	cpy #[loading_1_end - loading_1]
	bne !loop-

	ldy #0
!loop:
	lda P_BOSLN-O_DIR_BANK + O_DIR_UNAME, y
	beq !skip+
	jsr $ffd2
	iny
	cpy #16
	bne !loop-
!skip:

	ldy #0
!loop:
	lda loading_2, y
	jsr $ffd2
	iny
	cpy #[loading_2_end - loading_2]
	bne !loop-

	.const ZP_BANK = $ba
	.const ZP_SIZE = $07 // $08 - Temporary Integer during OR/AND
	.const ZP_SRC = $b7 // $b8
	.const ZP_DST = $ae // $af

	// copy bank
	:mov P_BOSLN-O_DIR_BANK + O_DIR_BANK ; ZP_BANK
	
	// copy size-2 
	:sub16 P_BOSLN-O_DIR_BANK + O_DIR_SIZE ; #2 ; ZP_SIZE
	// (dont load the laod address)
	
	// copy offset whithin first bank
	:add16 P_BOSLN-O_DIR_BANK + O_DIR_OFFSET ; #2 ; ZP_SRC
	// add 2 (don't load the loadaddress)

	// if the offset is now >= $4000 switch to next bank
	:if ZP_SRC+1 ; EQ ; #$40 ; ENDIF ; !endif+
		lda #$00
		sta ZP_SRC+1
		inc ZP_BANK
	!endif:
	// make offset ($0000-$3fff) to point into real address ($8000-$bfff)
	:add ZP_SRC+1 ; #$80
	
	// copy dst address
	:mov16 P_BOSLN-O_DIR_BANK + O_DIR_LOADADDR ; ZP_DST

	:if16 ZP_DST ; LE ; #$0801 ; ELSE ; !else+
		// LOAD ADDR $200-$0801 -> run
		lda #$52
		sta $277
		lda #$55
		sta $278
		lda #$4e
		sta $279
		lda #$0d
		sta $27a
		lda #$04
		sta $c6
		jmp !endif+
	!else:
		lda #$53
		sta $277
		lda #$59
		sta $278
		lda #$53
		sta $279
		
		ldx #4
	!loop:
		lda P_SYS_NUMBERS, x
		sta $27a, x
		dex
		bpl !loop-
		lda #$08
		sta $c6
	
	!endif:


	// update size (for faked start < 0)
	:add16_8 ZP_SIZE ; ZP_SRC
	
	// lower source -> y ; copy always block-wise
	:sub16_8 ZP_DST ; ZP_SRC
	ldy ZP_SRC
	:mov #0 ; ZP_SRC
	
	:if ZP_SIZE+1 ; NE ; #$00 ; JMP ; COPY_FILE
	sty smc_limit+1
	jmp COPY_FILE_LESS_THEN_ONE_PAGE

	/*
	** CART IS FILE (AND NO LONGER EASYLOADER)
	** COPY THE REQUIRED PROG
	*/

loading_1:
	.byte $91
	.text "LOADING "
	.byte $22
loading_1_end:
loading_2:
	.byte $22
	.text ",EF,1"
	.byte $0d
	.text "READY."
	.byte $0d, $0d
loading_2_end:


	FILE_EXT1_START:
	.pseudopc $df00 {
	DO_PARTIAL_RESET:
		/*
			PARTIAL RESET
		*/

		// disable rom 
		lda #MODE_RAM
		sta IO_MODE

		// do a partial reset
		ldx #$ff
		txs
		ldx #$05
		stx $d016
		jsr $fda3
		jsr $fd50
		jsr $fd15
		jsr $ff5b

		// enable rom 
		lda #MODE_16k
		sta IO_MODE
		
		jmp BACK_FROM_PARTIAL_RESET
	
		/*
			RESET, PART 2
		*/

	GO_RESET:
		:mov #MODE_RAM ; IO_MODE
		jmp $fcfe

	/*
	** ONLY USED WITH C64GS KERNAL:
	**		RESTORE CHROUT VECTOR
	**		SET $302 VECTOR TO BASIC (INSTEAD OF ANIMATION LOOP)
	**		REQUIRES 27 BYTES OF RAM
	*/
	
	CHROUT_TRAP:
		sei
		pha
		
	SMC_RESTORE_CHROUT_LOWER:
		lda #$00
		sta $326
	SMC_RESTORE_CHROUT_UPPER:
		lda #$00
		sta $327
		
		:mov16 #$a483 ; $0302
		
		pla
		cli
		jmp ($326)

	/*
	** RESET IS DONE
	** RESTORE VECTOR
	** JUMP BACK IN CARTRIDGE
	*/

	RESET_TRAP:
		// restore A,X,Y
		sei
		pha
		txa
		pha
		tya
		pha

		// restore_vector (by self-modifying-code)
	SMC_RESTORE_LOWER:
		lda #$00
		sta $324
	SMC_RESTORE_UPPER:
		lda #$00
		sta $325
	
		// activate easyloader programm
		lda #MODE_16k
		sta IO_MODE
		
		// jump back to program
		jmp FILE_COPIER
	// DATA
	P_BOSLN:
		.fill 25, 0
	P_SYS_NUMBERS:
		.fill 5, 0
		
	/*
		fo the file-copy
	*/
		
	add_bank:
		:mov #$80 ; ZP_SRC+1
		inc ZP_BANK
	COPY_FILE:
		lda ZP_BANK
		sta $de00
	!loop:
		lda (ZP_SRC), y
		sta (ZP_DST), y
		iny
		bne !loop-
		inc ZP_DST+1
		inc ZP_SRC+1
		dec ZP_SIZE+1
		beq !skip+
		:if ZP_SRC+1 ; EQ ; #$c0 ; add_bank
		jmp !loop-
		
	!skip:
		:if ZP_SRC+1 ; EQ ; #$c0 ; ENDIF ; !endif+
			:mov #$80 ; ZP_SRC+1
			inc ZP_BANK
	COPY_FILE_LESS_THEN_ONE_PAGE:
			lda ZP_BANK
			sta $de00
		!endif:
		ldy ZP_SIZE
		beq !skip+
	!loop:
		dey
		lda (ZP_SRC), y
		sta (ZP_DST), y
	smc_limit:
		cpy #$00
		bne !loop-

	!skip:

		// setup end of program
		:mov16 #$0801 ; $2b
		:add16_8 ZP_DST ; ZP_SIZE ; $2d
		:mov16 $2d ; $2f
		:mov16 $2d ; $31
		:mov16 $2d ; $ae

	/*
	** DISABLE CART, RESTORE REGS, JUMP TO THE REAL CHRIN
	*/

		// disable cart
		:mov #MODE_RAM ; IO_MODE
		
		// write $08 in $ba (last used drive)
		:mov #$08 ; $ba
		
		// restore A,X,Y
		pla
		tay
		pla
		tax
		pla
		
		cli
		jmp ($324)

	}
	FILE_EXT1_END:
}
