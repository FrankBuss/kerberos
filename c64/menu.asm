// sample C64 program to receive files over MIDI
// with a Namesoft MIDI interface

// testing in VICE: short MIDI-Out to MIDI-In to an USB device on your computer,
// open "Settings->Cartridge/IO settings->MIDI settings",
// enable MIDI emulation and set "Namesoft" for "MIDI type",
// and select your MIDI-In device at "MIDI-In device"
// Then this program, and then the Qt file transfer program

// compile command line: java -jar "C:\Program Files (x86)\kickassembler\KickAss.jar" -binfile filetransfer.asm
// convert to CRT file in Magic Desk format: "C:\Program Files\WinVICE-2.4-x64\cartconv" -t md -i filetransfer.bin -o filetranser.crt
// Kick Assembler: http://www.theweb.dk/KickAssembler/Main.php

// flash memory layout:
// 8 slots, slot 0 = menu, slot 1-7 = user PRGs
// slot format:
// magic non-empty byte marker: 0x42
// 249 bytes ASCII filename, zero terminated
// 2 bytes CRC16 checksum of PRG start, length and data
// 2 bytes length of PRG data
// 2 bytes PRG start
// PRG data (stating at 0x100 for each slot)

// number of 8k blocks per slot
.var slotBlockCount = 4

.var bankswitchRegister = $df00

// 192 bytes datasette buffer, for routines which need to run from RAM
.var datasetteBuffer = $033C

// RAM for init routines
.var initRAM = $c000

// screen positions
.var prgPos = $0451
.var statusPos = $0479
.var filenamePos = $04f1
.var slotPos = $056c
.var midiRingbuffer = $0749


// variables in zero page

.var prg = $2d

// main module
.var zeropageStart = $57
.var midiMessage = $59
.var dataCount = $5a
.var data0 = $5b
.var data1 = $5c
.var filenameIndex = $5d
.var prgLength = $5e
.var bank = $60
.var src = $61
.var slot = $63

// MIDI module
// private addresses
.var midiControl = $64
.var midiStatus = $66
.var midiTx = $68
.var midiRx = $6a
.var keyTestIndex = $6f
.var keyPressedIntern = $70
// public addresses
.var midiRingbufferReadIndex = $6c
.var midiRingbufferWriteIndex = $6d
.var midiInterfaceType = $6e
.var keyPressed = $71

.var x_tmp = $6c
.var pos = $6d

.var zeropageEnd = $72

.var prgStart = $fb
.var prgEnd = $fd



.pc = $8000
		.word start
		.word start
		.byte $c3, $c2, $cd, $38, $30  // cbm80

start:		stx $d016		// Turn on VIC for PAL / NTSC check
		
		// copy init functions to RAM
		ldx #0
!:		lda initRoutines,x
		sta initRAM,x
		inx
		cpx #initRoutinesEnd-initRoutines
		bne !-
		
		// initialization, jumps back to start2
		jmp init

		// save zeropage
start2:		sei
		ldx #0
!:		lda zeropageStart,x
		sta zeropageBackup,x
		inx
		cpx #zeropageEnd-zeropageStart+1
		bne !-

		// copy RAM routines
		ldx #0
!:		lda ramRoutines,x
		sta datasetteBuffer,x
		inx
		cpx #ramRoutinesEnd-ramRoutines
		bne !-

		// switch to lowercase mode
		lda #23
		sta $d018
		
		// init MIDI and enable all interrupts
		lda #3
		jsr midiInit
		
		// wait for note-off message or key press
check:		jsr midiCanRead
		bne readMidi
		lda keyPressed
		cmp #$ff
		beq check
		cmp #8
		bpl check
		// jsr print_hex
		
		// wait for key release
!:		ldx keyPressed
		cpx #$ff
		bne !-
		
		// 0: reset to basic
		cmp #0
		bne flashPrg
		jmp basicReset

		// load program from flash and start
flashPrg:	tax
		lda #0
!:		clc
		adc #slotBlockCount
		dex
		bne !-
		sta bank
		
		jsr showTransferStarted

		jmp loadFlashPrg

readMidi:	jsr midiRead
		tay
		and #$f0
		cmp #$80
		bne check
		
		// test if transfer start bit is set
		tya
		and #1<<3
		beq check
		
		// ignore next two bytes (TODO: check type)
		jsr midiRead
		jsr midiRead
		
		// init transfer variables
		lda #0
		sta dataCount
		
		// disable interrupts during transfer
		// sei
		
/*
		// show message
		ldx #37
!:		lda backToMenuText,x
		sta prgPos,x
		lda #3
		sta prgPos-$0400+$d800,x
		dex
		bpl !-
*/
		
		// read filename
		ldx #0
		stx filenameIndex
readFilename:	jsr readByte
		cmp #0
		beq !+
		tax
		lda ascii2Screencode,x
		ldx filenameIndex
		sta filenamePos,x
		inc filenameIndex
		jmp readFilename
		
		// clear basic
		ldx #0
		txa
!:		sta $0800,x
		dex
		bne !-
		
		// read program length
!:		jsr readByte
		sta prgLength
		jsr readByte
		sta prgLength+1
		
		// read program start
		jsr readByte
		sta prgStart
		sta prg
		jsr readByte
		sta prgStart+1
		sta prg+1
		
		// calculate program end
		lda prgStart
		clc
		adc prgLength
		sta prgEnd
		lda prgStart+1
		adc prgLength+1
		sta prgEnd+1
		
		jsr showTransferStarted
		
		// read program
readProgram:	jsr readByte
		ldy #0
		sta (prg),y
		inc prg
		bne !+
		inc prg+1
!:		lda prg+1
		cmp prgEnd+1
		bne readProgram
		lda prg
		cmp prgEnd
		bne readProgram
		
		// read checksum
		jsr readByte
		jsr readByte
		
		// TODO: test checksum
		
		jsr showTransferEnd
		
		// start program
		jmp startProgram
		
		// read MIDI message, decode bytes and return next byte
readByte:	lda dataCount
		bne nextByte
		jsr midiRead
		sta midiMessage
		jsr midiRead
		sta data1
		jsr midiRead
		sta data0
		lda midiMessage
		and #2
		beq !+
		lda data1
		ora #$80
		sta data1
!:		lda midiMessage
		and #1
		beq !+
		lda data0
		ora #$80
		sta data0
!:		lda #2
		sta dataCount
nextByte:	dec dataCount
		ldx dataCount
		lda data0,x
		rts

print_hex:	stx x_tmp
		pha
		lsr
		lsr
		lsr
		lsr
		jsr print_digit
		pla
		and #$f
		jsr print_digit
		ldx pos
		lda #32
		sta $0400,x
		inc pos
		ldx x_tmp
		rts

print_digit:	tax
		lda digits,x
		ldx pos
		sta $0400,x
		inc pos
		rts

digits:		.text "0123456789abcdef"
		
initRoutines:
.pseudopc initRAM {
init:		sei

		// turn module ROM off
		lda #$80
		sta bankswitchRegister

		// KERNAL reset routine
		jsr $fda3		// IOINIT - Init CIA chips
		jsr $fd50		// RANTAM - Clear/test system RAM
		lda #$a0
		sta $0284		// ignore cartridge ROM for end of detected RAM for BASIC
		jsr $fd15		// RESTOR - Init KERNAL RAM vectors
		jsr $ff5b		// CINT   - Init VIC and screen editor
		cli			// Re-enable IRQ interrupts

		// BASIC reset routine
		jsr $e453		// Init BASIC RAM vectors
		jsr $e3bf		// Main BASIC RAM Init routine
		jsr $e422		// Power-up message / NEW command
		ldx #$fb
		txs			// Reduce stack pointer for BASIC

		// turn module ROM off
		lda #0
		sta bankswitchRegister

		// show screen
		jsr showStartscreen
		
		// show slots
		
		// slot filename text position
		lda #<slotPos
		sta src
		lda #>slotPos
		sta src+1
		
		// switch bank to first slot
		lda #slotBlockCount
		sta bankswitchRegister
		
		// number of slots (first slot reserved for menu)
		lda #8
		sta slot
		
		// test for magic byte, otherwise the slot is empty
slotTest:	lda bank
		sta bankswitchRegister
		lda $8000
		cmp #$42
		bne nextSlot
		
		// clear line
		lda #32
		ldy #0
!:		sta (src),y
		iny
		cpy #35
		bne !-
		
		// show filename
		lda #32
		ldy #0
!:		lda bank
		sta bankswitchRegister
		lda $8001,y
		tax
		lda #0
		sta bankswitchRegister
		lda ascii2Screencode,x
		sta (src),y
		beq nextSlot
		iny
		cpy #35
		bne !-
		
nextSlot:	lda src
		clc
		adc #40
		sta src
		lda src+1
		adc #0
		sta src+1

		lda #slotBlockCount
		clc
		adc bank
		sta bank
		
		dec slot
		bne slotTest
		
		// back to bank 0 for menu
		lda #0
		sta bankswitchRegister
		
		jmp start2
.if (*>=initRAM+255) .error "overflow"
}
initRoutinesEnd:

ramRoutines:
.pseudopc datasetteBuffer {
startProgram:
		// disable MIDI, restore original interrupt pointers and enable interrupts
		jsr midiRelease
		
		// restoreZeropage
		ldx #0
!:		lda zeropageBackup,x
		sta zeropageStart,x
		inx
		cpx #zeropageEnd-zeropageStart+1
		bne !-

		// turn module off
		lda #$80
		sta bankswitchRegister
		lda prgStart
		beq testHigh
		cmp #$01
		bne !+
testHigh:	lda prgStart+1
		cmp #$08
		bne !+
		
		// if it starts at $0801 or $0800, then start as BASIC program
		jsr $A663		// CLR
		cli
		lda #0
		sta prgStart
		sta prgStart+1
		sta prgEnd
		sta prgEnd+1
		jmp $a7ae		// jump to basic RUN command
		
		// start as assembler program
!:		jmp (prgStart)
		
basicReset:	// turn module off
		lda #$80
		sta bankswitchRegister

		// reset
		jmp $fce2

		// copy program from flash bank to RAM and start it
loadFlashPrg:	jsr midiRelease
		sei
		lda bank
		sta bankswitchRegister
		lda $80fc
		sta prgLength
		lda $80fd
		sta prgLength+1
		lda $80fe
		sta prg
		sta prgStart
		lda $80ff
		sta prg+1
		sta prgStart+1
		lda #0
		sta src
		lda #$81
		sta src+1
		ldx #0
copyRom1:	lda (src,x)
		sta (prg,x)
		inc src
		bne copyRom2
		inc src + 1
		lda src + 1
		cmp #$a0
		bne copyRom2
		lda #$80
		sta src + 1
		inc bank
		lda bank
		sta bankswitchRegister
copyRom2:	inc prg
		bne copyRom3
		inc prg + 1
copyRom3:	dec prgLength
		bne copyRom1
		dec prgLength + 1
		lda prgLength + 1
		cmp #$ff
		bne copyRom1
		lda #0
		sta bankswitchRegister
		jsr showTransferEnd
		jmp startProgram

zeropageBackup:

.if (*>=datasetteBuffer+zeropageEnd-zeropageStart+1+192) .error "overflow"
}
ramRoutinesEnd:

showTransferEnd:
		ldx #37
!:		lda statusTransferEnd,x
		sta statusPos,x
		dex
		bpl !-
		rts

showTransferStarted:
		ldx #37
!:		lda statusTransferStarted,x
		sta statusPos,x
		dex
		bpl !-
		rts

statusTransferStarted:
		.text "Transfer started                      "

statusTransferEnd:
		.text "Transfer done, starting program...    "
		
backToMenuText:
		.text "Back to menu                          "
		
		.import source "startscreen.asm"

		// http://www.c64-wiki.de/index.php/PETSCII-Tabelle
		.align $100
ascii2Screencode:
                .byte 32, 32, 32, 32, 32, 32, 32, 32
                .byte 32, 32, 32, 32, 32, 32, 32, 32
                .byte 32, 32, 32, 32, 32, 32, 32, 32
                .byte 32, 32, 32, 32, 32, 32, 32, 32
                .byte 32, 33, 34, 35, 36, 37, 38, 39
                .byte 40, 41, 42, 43, 44, 45, 46, 47
                .byte 48, 49, 50, 51, 52, 53, 54, 55
                .byte 56, 57, 58, 59, 60, 61, 62, 63
                .byte 0, 65, 66, 67, 68, 69, 70, 71
                .byte 72, 73, 74, 75, 76, 77, 78, 79
                .byte 80, 81, 82, 83, 84, 85, 86, 87
                .byte 88, 89, 90, 27, 28, 29, 30, 31
                .byte 64, 1, 2, 3, 4, 5, 6, 7
                .byte 8, 9, 10, 11, 12, 13, 14, 15
                .byte 16, 17, 18, 19, 20, 21, 22, 23
                .byte 24, 25, 26, 91, 92, 93, 94, 95
                .byte 32, 32, 32, 32, 32, 32, 32, 32
                .byte 32, 32, 32, 32, 32, 32, 32, 32
                .byte 32, 32, 32, 32, 32, 32, 32, 32
                .byte 32, 32, 32, 32, 32, 32, 32, 32
                .byte 96, 97, 98, 99, 100, 101, 102, 103
                .byte 104, 105, 106, 107, 108, 109, 110, 111
                .byte 112, 113, 114, 115, 116, 117, 118, 119
                .byte 120, 121, 122, 123, 124, 125, 126, 127
                .byte 64, 65, 66, 67, 68, 69, 70, 71
                .byte 72, 73, 74, 75, 76, 77, 78, 79
                .byte 80, 81, 82, 83, 84, 85, 86, 87
                .byte 88, 89, 90, 91, 92, 93, 94, 95
                .byte 96, 97, 98, 99, 100, 101, 102, 103
                .byte 104, 105, 106, 107, 108, 109, 110, 111
                .byte 112, 113, 114, 115, 116, 117, 118, 119
                .byte 120, 121, 122, 123, 124, 125, 126, 94

		.import source "midi.asm"

.if (*>=$a000) .error "overflow"

end:
//	.fill 32768+$8000-*, 0
	.fill 8192+$8000-*, 0
