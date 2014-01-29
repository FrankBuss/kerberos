// program to program the flash
// at the end of this program, the flash target address is stored (three bytes) and then the program size (two bytes), all little endian
// then the flash content follows
// compile command line: java -jar "C:\Program Files (x86)\kickassembler\KickAss.jar" flash-test.asm
// Kick Assembler: http://www.theweb.dk/KickAssembler/Main.php

.pc = $0900

.var errorCount = $39
.var program_src = $3a
.var program_dst = $3c
.var tmp1 = $3f
.var tmp2 = $40
.var tmp3 = $41
.var flashBank = $42
.var flashHigh = $43
.var flashLow = $44
.var programCount = $45

.var basic_write_byte = $e716

start:
		// clear screen (same as BRK, but without basic warm start)
		jsr $FD15
		jsr $FDA3
		jsr $E518
		lda #0
		sta $d020
		sta $d021
		
		// show some message
		lda #<detectingFlashMessage
		ldx #>detectingFlashMessage
		jsr printString
		
		// disable IRQ
		sei
		
		// screen blank
		lda #0
		sta $d011
		jsr wait_300_ms
		
		// init error counter
		lda #0
		sta errorCount

		// init program counter
		sta programCount
		sta programCount+1

		// check flash ID
		jsr flashReadId
		lda #$80
		sta $df00			// turn off Ultimax mode and disable module
		cpx #$bf
		bne flashDetectionError
		cpy #$b7
		beq flashOk
flashDetectionError:		
		// show error message
		lda #<noFlashDetectedMessage
		ldx #>noFlashDetectedMessage
		jsr printString
		lda #$9b
		sta $d011
!:		jmp !-
		
flashOk:	// show ok message
		lda #<flashDetectedMessage
		ldx #>flashDetectedMessage
		jsr printString

/*
		// debug output flash contents
		lda end
		sta program_dst
		lda end+1
		sta program_dst+1
		lda end+2
		sta program_dst+2
		jsr flashConvertAdr
		ldx #0
out_test:	txa
		pha
		jsr flashReadByte
		tay
		lda #$80
		sta $df00			// turn off Ultimax mode and disable module
		pla
		pha
		tax
		tya
//		sta $0400,x
		jsr print_hex
		inc flashLow
		inc program_dst
		bne !+
		inc program_dst+1
		bne !+
		inc program_dst+2
!:		lda program_dst+1
		pla
		tax
		inx
		cpx #40
		bne out_test
		lda #0
		sta $df00
		lda #$9b
		sta $d011
 !:		jmp !-
*/


		// erase flash
		//jsr flash_erase

//!:		inc $d020
//		jmp !-

		// program flash
		
		// source
		lda #<[end+5]
		sta program_src
		lda #>[end+5]
		sta program_src+1
		
		// destination
		lda end
		sta program_dst
		lda end+1
		sta program_dst+1
		lda end+2
		sta program_dst+2
		jsr flashConvertAdr
		
program_loop:	// erase sector: two 4k sectors for each 8k bank
		lda flashLow
		bne !+
		lda flashHigh
		and #$f
		bne !+
		jsr flashSectorErase

		// program next byte
!:		lda #$80
		sta $df00			// turn off Ultimax mode and disable module
		ldy #0
		//inc $d020
		lda (program_src),y
		jsr flashProgramByte
		
		// if too many write errors, abort
		cpx #$ff
		beq fatalError
		txa
		
		// otherwise add error count
		clc
		adc errorCount
		sta errorCount
		
		// next byte address
		inc program_src
		bne !+
		inc program_src+1
!:		inc flashLow
		bne !+
		inc flashHigh
		lda flashHigh
		cmp #$a0
		bne !+
		inc flashBank
		lda #$80
		sta flashHigh
		
		// test for program end
!:		inc programCount
		bne !+
		inc programCount+1
!:		lda programCount
		cmp end+3
		bne program_loop
		lda programCount+1
		cmp end+4
		bne program_loop

		// programming end, show number of errors
		jsr flash_end
		lda #<flashOkMessage
		ldx #>flashOkMessage
		jsr printString
		lda errorCount
		jsr print_hex
!:		jmp !-

		// flash write error, TODO: show message with flash address
fatalError:	jsr flash_end
		lda #<flashWriteFailedMessage
		ldx #>flashWriteFailedMessage
		jsr printString
!:		jmp !-

		.import source "flash-lib.asm"

		// turn off Ultimax mode and disable module
flash_end:	sei
		lda #$80
		sta $df00

		// show screen
		lda #$9b
		sta $d011
		//lda #0
		//sta $d020
		rts

print_hex:	ldx #$80
		stx $df00
		pha
		lsr
		lsr
		lsr
		lsr
		jsr print_digit
		pla
		and #$f
		jsr print_digit
		lda #32
		jsr basic_write_byte
		sei
		rts

print_digit:	tax
		lda digits,x
		jmp basic_write_byte
		
		// prints a null terminated string in accu/x (accu=low byte of the address)
printString:	ldy #$80
		sty $df00
		sta tmp1
		stx tmp2
		ldy #0
!:		lda (tmp1),y
		beq !+
		jsr basic_write_byte
		iny
		bne !-
!:		sei
		rts

digits:		.text "0123456789ABCDEF"

detectingFlashMessage:
		.text "DETECTING FLASH: " .byte 0

flashDetectedMessage:
		.text "SST39SF040 (512 KB)" .byte $0d, 0

noFlashDetectedMessage:
		.text "NO FLASH DETECTED" .byte $0d, 0

flashWriteFailedMessage:
		.text "FLASH WRITE FAILED" .byte $0d, 0

flashOkMessage:
		.text "FLASH WRITE OK" .byte $0d
		.text "WRITE ERRORS (CORRECTED): " .byte 0

end:
