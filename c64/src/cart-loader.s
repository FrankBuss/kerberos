.include "regs.inc"

.import         __LOADER_LOAD__

CINT   = $ff81
IOINIT = $ff84
RAMTAS = $ff87
RESTOR = $ff8a

.segment "CODE"

		.addr cold_start
		.addr cold_start
		.byte $c3, $c2, $cd, $38, $30  ; "CBM80"

cold_start:	sei

		; disable screen and black
		lda #0
		sta $d011
		sta $d020
		sta $d021
		
		; SID reset
		ldx #23
sidReset:	sta $d400,x
		dex
		bpl sidReset		

		; KERNAL reset routine
		jsr $fda3		; IOINIT - Init CIA chips

		; faster RANTAM without memory test
		lda #$00
		sta $0283
		tay
rantam2:	sta $0002,y
		sta $0200,y
		sta $0300,y
		iny
		bne rantam2
		ldx #$3c
		ldy #$03
		stx $b2
		sty $b3
		lda #$a0
		sta $c2
		sta $0284
		lda #$08
		sta $0282
		lda #$04
		sta $0288

		; copy RAM loader to datasette buffer
		ldx #0
copy:		lda __LOADER_LOAD__,x
		sta loaderStart,x
		inx
		cpx #loaderEnd-loaderStart
		bne copy
		
		; load program from ROM and start it
		jmp loaderStart

.segment "ID"
		.byte 75, 69, 82, 66, 69, 82, 79, 83, 32, 77, 69, 78, 85, 32, 73, 68
		
.segment "LOADER"

prg = $2d
prgEnd = menuEnd - menuStart + $0801

loaderStart:
		; disable cartridge
		lda #(CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH)
		sta CART_CONTROL
		
		; disable MIDI
		lda #0
		sta MIDI_CONFIG
		
		; disable RAM
		sta CART_CONFIG

		jsr $fd15		; RESTOR - Init KERNAL RAM vectors
		jsr $ff5b		; CINT   - Init VIC and screen editor

		lda #0
		sta $d020
		sta $d021

		cli			; Re-enable IRQ interrupts

		; BASIC reset routine
		jsr $e453		; Init BASIC RAM vectors
		jsr $e3bf		; Main BASIC RAM Init routine
		jsr $a644		; NEW command
		ldx #$fb
		txs			; Reduce stack pointer for BASIC

		; enable cartridge in $8000
		lda #(CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW)
		sta CART_CONTROL
		
		; copy program from ROM
		ldx #(>(menuEnd - menuStart))+1
		lda #0
		sta bank
		sta FLASH_ADDRESS_EXTENSION
		ldy #0
copyRom1:	lda menuStart,y
copyRom2:	sta $0801,y
		iny
		bne copyRom1
		inc copyRom2+2
		inc copyRom1+2
		lda copyRom1+2
		cmp #$a0
		bne copyRom3
		lda #$80
		sta copyRom1+2
		inc bank
		lda bank
		sta FLASH_ADDRESS_EXTENSION
copyRom3:	dex
		bne copyRom1
		lda #<prgEnd
		sta prg
		lda #>prgEnd
		sta prg+1

		; disable cartridge
		lda #(CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH)
		sta CART_CONTROL

		; start as BASIC program
		jsr $a663		; CLR
		cli
		jmp $a7ae		; jump to basic RUN command
		
bank:		.res 1

loaderEnd:

.segment "MENU"
menuStart:	.incbin "menu.prg", 2
menuEnd:
