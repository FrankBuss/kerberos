// sample C64 MIDI out test with a DATEL MIDI interface

// compile command line: java -jar "C:\Program Files (x86)\kickassembler\KickAss.jar" midi-out-test.asm
// Kick Assembler: http://www.theweb.dk/KickAssembler/Main.php

.pc = $0801
		.byte $0f, $08, $dd, $07, $9e, $20, $bd, $28, $37, $2e, $36, $34, $29, $00, $00
		.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00

.var midiControl = $de04
.var midiStatus = $de06
.var midiTx = $de05
.var midiRx = $de07

.var ringbuffer = $0400
.var ringbufferReadIndex = $57
.var ringbufferWriteIndex = $58
.var midiMessage = $59
.var lastWaveform = $5a

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
		
		// setup UART, without interrupt
		lda #$16
		sta midiControl
		
send_loop:	lda #60
		ldx #100
		jsr note_on

		lda #64
		ldx #100
		jsr note_on

		lda #67
		ldx #100
		jsr note_on

		jsr delay
		jsr delay
		jsr delay
		jsr delay
		jsr delay
		jsr delay
		jsr delay

		lda #60
		ldx #0
		jsr note_off

		lda #64
		ldx #0
		jsr note_off

		lda #67
		ldx #0
		jsr note_off

		jsr delay
		jsr delay
		jsr delay
		jsr delay
		jsr delay
		jsr delay
		jsr delay
		jsr delay
		jsr delay
		jsr delay
		jsr delay

		jmp send_loop

		// send note-on, note in accu with velocity in X, on channel 0
note_on:	ldy #$90
		jmp note_on_off

		// send note-off, note in accu with velocity in X, on channel 0
note_off:	ldy #$80
		jmp note_on_off

		// send note-on or note-off, note in accu with velocity in X, on channel 0, note-on/off in Y
note_on_off:	pha
		tya
		jsr send_byte
		pla
		jsr send_byte
		txa
		jmp send_byte
	
		// wait some 0.2 seconds
delay:		ldx #100
delay2:		ldy #0
delay3:		dey
		bne delay3
		dex
		bne delay2
		rts

		// send byte in accu to UART and wait for transmit end
send_byte:	sta midiTx
!:		lda midiStatus
		and #2
		beq !-
		rts
                
info:		.text "MIDI-Out test                           "
		.text "sends note-on and note-off messages     "
