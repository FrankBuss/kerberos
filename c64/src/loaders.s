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

.import 	openCallback
.import 	closeCallback
.import 	chkinCallback
.import 	chkoutCallback
.import 	chrinCallback
.import 	chroutCallback
.import 	getinCallback
.import		loadCallback

.import		driveNumber1
.import		driveNumber2


.include "regs.inc"

prg = $2d
prgCounter = $5e
bank = $60
prgLoad = $df40
prgStart = $df42
prgLength = $df44

.segment "LOWCODE"

; void __fastcall__ initCartridgeDisk(uint8_t driveNumber1, uint8_t driveNumber2)
.export _initCartridgeDisk
_initCartridgeDisk:
		pha
		
		; copy trampoline code to $0000 in SRAM
		ldx #0
		stx RAM_ADDRESS_EXTENSION
		stx ADDRESS_EXTENSION2
c0:		lda __TRAMPOLINE_LOAD__,x
		sta __TRAMPOLINE_RUN__,x
		inx
		bne c0
		
		; set drive numbers
		jsr popa
		sta driveNumber1		
		pla
		sta driveNumber2

		; copy KERNAL to SRAM
		lda #$e0
		sta bank
		ldy #$20
c1:		ldx #0
		lda bank
		sta RAM_ADDRESS_EXTENSION
		inc $d020
c2:		lda $e000,x
		sta $df00,x
		dex
		bne c2
		inc c2+2
		inc bank
		dey
		bne c1

		; disable cartridge
		lda #0
		sta CART_CONFIG
		lda #CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH
		sta CART_CONTROL

		; copy cartridge disk implementation to SRAM
		lda #$80
		sta bank
		ldy #$20
c3:		ldx #0
		lda bank
		sta RAM_ADDRESS_EXTENSION
c4:		lda $8000,x
		sta $df00,x
		dex
		bne c4
		inc c4+2
		inc bank
		dey
		bne c3
		
		; patch jump table ($4c = absolute jmp instead of indirect jmp)
        .macro  patchKernal addr, callback
        	lda #$4c
        	sta addr + $df00
        	lda #<callback
        	sta addr + $df01
        	lda #>callback
        	sta addr + $df02
        .endmacro
        	lda #$ff
		sta RAM_ADDRESS_EXTENSION
        	patchKernal $c0, openCallback
        	patchKernal $c3, closeCallback
        	patchKernal $c6, chkinCallback
        	patchKernal $c9, chkoutCallback
        	patchKernal $cf, chrinCallback
        	patchKernal $d2, chroutCallback
        	patchKernal $d5, loadCallback
        	patchKernal $e4, getinCallback

		; update slot header settings to reset with KERNAL hack
		lda #ADDRESS_EXTENSION2_RAM_A16
		sta ADDRESS_EXTENSION2
		lda #0
		sta RAM_ADDRESS_EXTENSION
		
		lda #CART_CONFIG_RAM_AS_ROM_ON | CART_CONFIG_KERNAL_HACK_ON | CART_CONFIG_HIRAM_HACK_ON
		sta CART_CONFIG+$100
		lda #CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH
		sta CART_CONTROL+$100
		lda #4
		sta FLASH_ADDRESS_EXTENSION+$100
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
		lda #0
		sta RAM_ADDRESS_EXTENSION

		; setup cartridge config
		lda CART_CONTROL + $0100
		sta CART_CONTROL
		lda CART_CONFIG + $0100
		sta CART_CONFIG

		; select program header at 0x0000 in SRAM, for the trampoline code, in case the cartridge disk is enabled
		lda #0
		sta ADDRESS_EXTENSION2
		sta RAM_ADDRESS_EXTENSION

		; clear CPU stack
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
		
		; select program header at 0x10000 in SRAM
		lda #ADDRESS_EXTENSION2_RAM_A16
		sta ADDRESS_EXTENSION2
		lda #0
		sta RAM_ADDRESS_EXTENSION

		; copy regs
		ldx #0
saveRegs:	lda $df39,x
		sta regs,x
		inx
		cpx #7
		bne saveRegs

		; load program from RAM and start it
		jmp loadRamPrg		

flashBank:
		.res 1


.segment "LOADER"

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
		
		; select SRAM bank $10000 to get the program address
skipCopy:	lda #ADDRESS_EXTENSION2_RAM_A16
		sta ADDRESS_EXTENSION2
		lda #0
		sta RAM_ADDRESS_EXTENSION

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

loadRegs:	; select SRAM bank at $0000 (with trampoline code, if the cartridge disk is enabled) for starting the program
		lda #0
		sta ADDRESS_EXTENSION2
		sta RAM_ADDRESS_EXTENSION
		ldx #0
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

