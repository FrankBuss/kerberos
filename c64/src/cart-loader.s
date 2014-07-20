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

		; copy RAM loader to datasette buffer
		ldx #0
copy:		lda __LOADER_LOAD__,x
		sta loaderStart,x
		inx
		cpx #loaderEnd-loaderStart
		bne copy
		
		; load program from ROM and start it
		jmp loaderStart
		
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

		; KERNAL reset routine
		jsr $fda3		; IOINIT - Init CIA chips
		jsr $fd50		; RANTAM - Clear/test system RAM
		jsr $fd15		; RESTOR - Init KERNAL RAM vectors
		jsr $ff5b		; CINT   - Init VIC and screen editor
		cli			; Re-enable IRQ interrupts

		; BASIC reset routine
		jsr $e453		; Init BASIC RAM vectors
		jsr $e3bf		; Main BASIC RAM Init routine
		jsr $e422		; Power-up message / NEW command
		ldx #$fb
		txs			; Reduce stack pointer for BASIC

		; enable cartridge in $8000
		lda #(CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW)
		sta CART_CONTROL

		; copy program from ROM
		ldx #(>(menuEnd - menuStart))+1
		lda #0
		sta bank
		sta ADDRESS_EXTENSION
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
		sta ADDRESS_EXTENSION
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
