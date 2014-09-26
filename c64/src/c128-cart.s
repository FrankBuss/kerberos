.include "regs.inc"

.import         __LOADER_LOAD__

prgCounter = $5e
bank = $60
prgLoad = $df40
prgStart = $df42
prgLength = $df44

.segment "CODE"
		; recommended format from "C128 Programmer's Reference Guide", page 409
		sei
		jmp startup
		nop
		nop
		.byte 2  ; ID 2 instead of 1, for autostart cartridge after BASIC init
		.byte $43, $42, $4d  ; "cbm"

startup:	sei

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

loaderStart:
		; standard MMU setting with KERNAL, BASIC and IO
		lda #0
		sta $ff00
		
		; Kerberos SRAM bank at $10000
		sta RAM_ADDRESS_EXTENSION
		lda #1
		sta ADDRESS_EXTENSION2

		; copy program from RAM and start it
loadRamPrg:	lda prgLoad
		bne loadRamPrg2
		lda prgLoad+1
		beq skipCopy		; special case: skip SRAM copy, if load address is 0
loadRamPrg2:	lda prg
		pha
		lda prg+1
		pha
		lda prgCounter
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
copyRom1:	lda $df00,y
		sta (prg),y
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
copyRomEnd:	pla
		sta bank
		pla
		sta prgCounter+1
		pla
		sta prgCounter
		pla
		sta prg+1
		pla
		sta prg
		
		; select bank at $10000 and save regs from SRAM
skipCopy:	ldx #0
		stx RAM_ADDRESS_EXTENSION
saveRegs:	lda $df39,x
		sta regs,x
		inx
		cpx #7
		bne saveRegs
		
		; start program (start address 0 = BASIC RUN)
		lda prgStart
		bne startAsm
		lda prgStart+1
		bne startAsm
		
		; start as BASIC program
		jsr loadRegs
		cli
		jmp $5aa6	; jump to basic RUN command
		
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

regs:	.res 7
		
loaderEnd:

.if loaderEnd - loaderStart > 255
.error "loader too big!"
.endif
