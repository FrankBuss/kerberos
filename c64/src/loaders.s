.importzp       sp, sreg, regsave
.importzp       ptr1, ptr2, ptr3, ptr4
.importzp       tmp1, tmp2, tmp3, tmp4

.import         popax
.import         popa
.import         pushax
.import         __LOADER_LOAD__
.import         __ROMLOADER_LOAD__
.import         __TRAMPOLINE_LOAD__
.import         __TRAMPOLINE_RUN__
.import         D_CHROUT

.include "regs.inc"

prg = $2d

CHROUT = $ffd2

.segment "TRAMPOLINE"
trampolineStart:
T_CHROUT:	php
		inc $d020
		plp
		jmp $f1ca
		
		jsr enableRom
		jsr D_CHROUT
		jmp disableRom
		jsr enableRom
		jsr $8000
		jmp disableRom
		jsr enableRom
		jsr $8000
		jmp disableRom
		jsr enableRom
		jsr $8000
		jmp disableRom
enableRom:	sta accuBackup
		php
		pla
		sta statusBackup
		sei
		; enable cartridge ROM at $8000
		lda #CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW | CART_CONTROL_LED1_ON | CART_CONTROL_LED2_ON
		sta CART_CONTROL
		lda #0
		sta CART_CONFIG
		lda #4
		sta FLASH_ADDRESS_EXTENSION
		lda #0
		sta ADDRESS_EXTENSION2
		rts
disableRom:	; restore current slot settings
T_CART_CONTROL:	lda #0
		sta CART_CONTROL
T_CART_CONFIG:	lda #0
		sta CART_CONFIG
T_FLASH_ADDRESS_EXTENSION: lda #0
		sta FLASH_ADDRESS_EXTENSION
T_ADDRESS_EXTENSION2: lda #0
		sta ADDRESS_EXTENSION2
		lda statusBackup
		pha
		plp
		lda accuBackup
		rts

accuBackup:	.res 1
statusBackup:	.res 1


.segment "LOWCODE"

.export _cartridgeDiskTest
_cartridgeDiskTest:
		; copy trampoline code to $0000 in SRAM
		ldx #0
		stx RAM_ADDRESS_EXTENSION
		stx ADDRESS_EXTENSION2
c0:		lda __TRAMPOLINE_LOAD__,x
		sta __TRAMPOLINE_RUN__,x
		inx
		bne c0

		; copy KERNAL and BASIC to RAM
		ldy #$20
c1:		ldx #0
c2:		lda $e000,x
c3:		sta $e000,x
c4:		lda $a000,x
c5:		sta $a000,x
		dex
		bne c2
		inc c2+2
		inc c3+2
		inc c4+2
		inc c5+2
		dey
		bne c1
		
		; patch jump table ($4c = absolute jmp instead of indirect jmp)
		ldx #$4c
		stx CHROUT
		lda #<T_CHROUT
		sta CHROUT+1
		lda #>T_CHROUT
		sta CHROUT+2
		
		; enable KERNAL in RAM for testing
		lda #$35
		sta 1
		
		rts


; =============================================================================
;
; Read a program from SRAM (starting at 0x10000) and start it.
; The header in the first bank has the same format as a flash slot header.
;
; void __fastcall__ startProgram(void);
;
; parameters:
;       -
;
; return:
;       -
;
; =============================================================================
.export _startProgram
_startProgram:
		sei

		; disable cartridge and MIDI
		lda #CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH
		sta CART_CONTROL
		lda #0
		sta CART_CONFIG
		sta MIDI_CONFIG

		; select program header at 0x10000 in SRAM
		lda #ADDRESS_EXTENSION2_RAM_A16
		sta ADDRESS_EXTENSION2
		ldx #0
		stx RAM_ADDRESS_EXTENSION

		; setup cartridge config and patch trampoline code
		lda CART_CONTROL + $0100
		sta CART_CONTROL
		; sta T_CART_CONTROL+1-__TRAMPOLINE_RUN__+__TRAMPOLINE_LOAD__
		lda CART_CONFIG + $0100
		sta CART_CONFIG
		; sta T_CART_CONFIG+1-__TRAMPOLINE_RUN__+__TRAMPOLINE_LOAD__
		lda FLASH_ADDRESS_EXTENSION + $0100
		; sta T_FLASH_ADDRESS_EXTENSION+1-__TRAMPOLINE_RUN__+__TRAMPOLINE_LOAD__
		lda ADDRESS_EXTENSION2 + $0100
		; sta T_ADDRESS_EXTENSION2+1-__TRAMPOLINE_RUN__+__TRAMPOLINE_LOAD__

		; copy trampoline code to $0000 in SRAM
		ldx #0
		stx RAM_ADDRESS_EXTENSION
		stx ADDRESS_EXTENSION2
copyTrampoline:	lda __TRAMPOLINE_LOAD__,x
		sta __TRAMPOLINE_RUN__,x
		inx
		bne copyTrampoline

		; select program header at 0x10000 in SRAM
		lda #ADDRESS_EXTENSION2_RAM_A16
		sta ADDRESS_EXTENSION2

		ldx #$fb
		txs

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

		sei
		ldx #$fb
		txs

		; copy RAM loader to datasette buffer
		ldx #0
copy2:		lda __LOADER_LOAD__,x
		sta loaderStart,x
		inx
		cpx #loaderEnd-loaderStart
		bne copy2
		
		; copy regs
		ldx #ADDRESS_EXTENSION2_RAM_A16
		stx ADDRESS_EXTENSION2
		ldx #0
		stx RAM_ADDRESS_EXTENSION
saveRegs:	lda $df39,x
		sta regs,x
		inx
		cpx #7
		bne saveRegs

		; select SRAM bank at $10000
		ldx #0
		stx RAM_ADDRESS_EXTENSION

		; load program from RAM and start it
		jmp loadRamPrg		

flashBank:
		.res 1


.segment "LOADER"

prgCounter = $5e
bank = $60
prgLoad = $df40
prgStart = $df42
prgLength = $df44

loaderStart:
		; copy program from RAM and start it
loadRamPrg:	lda prgLoad
		bne loadRamPrg2
		lda prgLoad+1
		beq skipCopy		; special case: skip SRAM copy, if load address is 0
loadRamPrg2:	lda prgCounter
		pha
		lda prgCounter+1
		pha
		lda bank
		pha
		lda prgLength
		sta prgCounter
		lda prgLength+1
		sta prgCounter+1
		lda prgLoad
		sta prg
		lda prgLoad+1
		sta prg+1
		lda #1
		sta bank
		sta RAM_ADDRESS_EXTENSION
		ldy #0
copyRom1:	ldx #$35		; all RAM, and IO
		stx 1
		lda $df00,y
		ldx #$30		; RAM only
		stx 1
		sta (prg),y
		ldx #$37		; default
		stx 1
		dec prgCounter
		bne copyRom2
		dec prgCounter+1
		lda prgCounter+1
		cmp #$ff
		beq copyRomEnd
copyRom2:	iny
		bne copyRom1
		inc prg+1
		inc bank
		lda bank
		sta RAM_ADDRESS_EXTENSION
		bne copyRom1		; unconditional jump
copyRomEnd:	sty prg
		clc
		lda #2
		adc prg
		sta prg
		bcc copyRomEnd2
		inc prg+1
copyRomEnd2:	pla
		sta bank
		pla
		sta prgCounter+1
		pla
		sta prgCounter
		
		; program starts with SRAM bank $0000 activated
skipCopy:	ldx #0
		stx RAM_ADDRESS_EXTENSION
		
		; start program (start address 0 = BASIC RUN)
		lda prgStart
		bne startAsm
		lda prgStart+1
		bne startAsm
		
		; start as BASIC program
		jsr loadRegs
		cli
		jsr $a663		; CLR
		jmp $a7ae		; jump to basic RUN command
		
		; start as assembler program
startAsm:	lda prgStart
		sta prgJmp
		lda prgStart+1
		sta prgJmp+1
		jsr loadRegs
		cli
prgJmp = * + 1
		jmp $8000

loadRegs:	ldx #0
loadRegs2:	lda regs,x
		sta $de39,x
		inx
		cpx #7
		bne loadRegs2	
		rts

regs:		.res 7
		
loaderEnd:

.if loaderEnd - loaderStart > 255
.error "loader too big!"
.endif

.segment "CART128"
.export _cart128Start
.export _cart128End
_cart128Start:	.incbin "c128-cart.bin"
c128loaderEnd:
_cart128End:

.if _cart128Start - _cart128End > 255
.error "C128 loader too big!"
.endif
