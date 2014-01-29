// a C64 synthesizer program to play the SID with an external MIDI keyboard
// and a DATEL MIDI interface

// testing in VICE: Connect your MIDI keyboard to the computer,
// open "Settings->Cartridge/IO settings->MIDI settings",
// enable MIDI emulation and set "DATEL" for "MIDI type",
// and select your MIDI-keyboard at "MIDI-In device"

// compile command line: java -jar "C:\Program Files (x86)\kickassembler\KickAss.jar" synthesizer-test.asm
// Kick Assembler: http://www.theweb.dk/KickAssembler/Main.php

.pc = $0801
		.byte $0f, $08, $dd, $07, $9e, $20, $bd, $28, $37, $2e, $36, $34, $29, $00, $00
		.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

// this module
.var midiMessage = $59
.var lastWaveform = $5a

// MIDI module
// private addresses
.var midiControl = $64
.var midiStatus = $66
.var midiTx = $68
.var midiRx = $6a
.var keyTestIndex = $6f
.var keyPressedIntern = $70
.var shiftPressed = $72
.var midiRingbuffer = $0400
// public addresses
.var midiRingbufferReadIndex = $6c
.var midiRingbufferWriteIndex = $6d
.var midiInterfaceType = $6e
.var keyPressed = $71

start:
		// switch to lowercase mode
		lda #23
		sta $d018

		// clear screen and show info
		ldx #0
		stx $d020
		stx $d021
!:		lda #32
		sta $0400,x
		sta $0400+250,x
		sta $0400+500,x
		sta $0400+750,x
		lda #14
		sta $d800,x
		sta $d800+250,x
		sta $d800+500,x
		sta $d800+750,x
		inx
		cpx #250
		bne !-
		ldx #0
!:		lda info,x
		sta $0400+10*40,x
		inx
		cpx #80
		bne !-

		// init SID
		lda #0
		ldx #0
initSid:	sta $d400,x
		inx
		cpx #25
		bne initSid
		lda #15
		sta $d418
		lda #1
		sta $d403

		// init MIDI and enable all interrupts
		lda #3
		jsr midiInit

		// get next MIDI byte
check:		jsr midiRead
		beq check
		
		// check if a message byte was received
		ldx midiMessage
		bne messageContent

		// wait for MIDI message
		tay
		and #$80
		beq check
		sty midiMessage
		jmp check
		

		// next byte of message is in A, message in X
messageContent:	
		tay
		lda #0
		sta midiMessage
		txa
		and #$f0
		cmp #$90
		beq noteOn
		cmp #$80
		beq noteOff
		jmp check

		// note is in Y		
noteOn:
		// frequency
		lda FreqTablePalLo,y
		sta $d400
		lda FreqTablePalHi,y
		sta $d401
		
		// ADSR
		lda #$11
		sta $d405
		lda #$d6
		sta $d406
		
		// start noise (0x81), square (0x41), sawtooth (0x21) or triangle (0x11), based on channel
		txa
		and #$03
		tax
		lda #$10
!:		cpx #0
		beq !+
		asl
		dex
		jmp !-
!:		ora #1
		sta $d404
		sta lastWaveform
		
		jmp check

noteOff:
		// stop waveform
		lda lastWaveform
		and #$fe
		sta $d404

		jmp check

// http://codebase64.org/doku.php?id=base:pal_frequency_table
FreqTablePalLo:
	        //     C   C#  D   D#  E   F   F#  G   G#  A   A#  B
                .byte $17,$27,$39,$4b,$5f,$74,$8a,$a1,$ba,$d4,$f0,$0e  // 1
                .byte $2d,$4e,$71,$96,$be,$e8,$14,$43,$74,$a9,$e1,$1c  // 2
                .byte $5a,$9c,$e2,$2d,$7c,$cf,$28,$85,$e8,$52,$c1,$37  // 3
                .byte $b4,$39,$c5,$5a,$f7,$9e,$4f,$0a,$d1,$a3,$82,$6e  // 4
                .byte $68,$71,$8a,$b3,$ee,$3c,$9e,$15,$a2,$46,$04,$dc  // 5
                .byte $d0,$e2,$14,$67,$dd,$79,$3c,$29,$44,$8d,$08,$b8  // 6
                .byte $a1,$c5,$28,$cd,$ba,$f1,$78,$53,$87,$1a,$10,$71  // 7
                .byte $42,$89,$4f,$9b,$74,$e2,$f0,$a6,$0e,$33,$20,$ff  // 8

FreqTablePalHi:
		//     C   C#  D   D#  E   F   F#  G   G#  A   A#  B
                .byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$02  // 1
                .byte $02,$02,$02,$02,$02,$02,$03,$03,$03,$03,$03,$04  // 2
                .byte $04,$04,$04,$05,$05,$05,$06,$06,$06,$07,$07,$08  // 3
                .byte $08,$09,$09,$0a,$0a,$0b,$0c,$0d,$0d,$0e,$0f,$10  // 4
                .byte $11,$12,$13,$14,$15,$17,$18,$1a,$1b,$1d,$1f,$20  // 5
                .byte $22,$24,$27,$29,$2b,$2e,$31,$34,$37,$3a,$3e,$41  // 6
                .byte $45,$49,$4e,$52,$57,$5c,$62,$68,$6e,$75,$7c,$83  // 7
                .byte $8b,$93,$9c,$a5,$af,$b9,$c4,$d0,$dd,$ea,$f8,$ff  // 8
                
info:		.text "A simple sequencer, use MIDI channel 1-4"
		.text "for different waveforms.                "

		.import source "midi.asm"
