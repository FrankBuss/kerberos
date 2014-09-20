.importzp       sp, sreg, regsave
.importzp       ptr1, ptr2, ptr3, ptr4
.importzp       tmp1, tmp2, tmp3, tmp4

.import         popax
.import         popa
.import         pushax
.import		_midiWaitAndReadByte
.import         _rand
.import         __BLOCK_BUFFER_START__
.import         __LOADER_LOAD__
.import         __ROMLOADER_LOAD__

.include "regs.inc"

prg = $2d


.segment "LOWCODE"

; =============================================================================
;
; Enable EasyFlash mode and reset.
;
; void __fastcall__ startEasyFlash(void);
;
; parameters:
;       -
;
; return:
;       -
;
; =============================================================================
.export _startEasyFlash
_startEasyFlash:
		; disable normal IRQ
		sei
		
		; disable MIDI
		lda #0
		sta MIDI_CONFIG
		
		; first bank
		lda #0
		sta FLASH_ADDRESS_EXTENSION
		sta RAM_ADDRESS_EXTENSION
		
		; enable A20 for second mb of flash
		lda #ADDRESS_EXTENSION2_FLASH_A20
		sta ADDRESS_EXTENSION2
		
		; enable Ultimax mode
		lda #(CART_CONTROL_GAME_LOW | CART_CONTROL_EXROM_HIGH)
		sta CART_CONTROL
		
		; enable EasyFlash mode and RAM
		lda #(CART_CONFIG_EASYFLASH_ON)
		sta CART_CONFIG
		
		; reset
		jmp ($fffc)


.segment "CODE"

ascii2petsciiTable:
		.byte 0, 1, 2, 3, 4, 5, 6, 7
		.byte 8, 9, 10, 11, 12, 13, 14, 15
		.byte 16, 17, 18, 19, 20, 21, 22, 23
		.byte 24, 25, 26, 27, 28, 29, 30, 31
		.byte 32, 33, 34, 35, 36, 37, 38, 39
		.byte 40, 41, 42, 43, 44, 45, 46, 47
		.byte 48, 49, 50, 51, 52, 53, 54, 55
		.byte 56, 57, 58, 59, 60, 61, 62, 63
		.byte 64, 97, 98, 99, 100, 101, 102, 103
		.byte 104, 105, 106, 107, 108, 109, 110, 111
		.byte 112, 113, 114, 115, 116, 117, 118, 119
		.byte 120, 121, 122, 91, 92, 93, 94, 95
		.byte 96, 65, 66, 67, 68, 69, 70, 71
		.byte 72, 73, 74, 75, 76, 77, 78, 79
		.byte 80, 81, 82, 83, 84, 85, 86, 87
		.byte 88, 89, 90, 123, 124, 125, 126, 127
		.byte 128, 129, 130, 131, 132, 133, 134, 135
		.byte 136, 137, 138, 139, 140, 141, 142, 143
		.byte 144, 145, 146, 147, 148, 149, 150, 151
		.byte 152, 153, 154, 155, 156, 157, 158, 159
		.byte 160, 161, 162, 163, 164, 165, 166, 167
		.byte 168, 169, 170, 171, 172, 173, 174, 175
		.byte 176, 177, 178, 179, 180, 181, 182, 183
		.byte 184, 185, 186, 187, 188, 189, 190, 191
		.byte 192, 193, 194, 195, 196, 197, 198, 199
		.byte 200, 201, 202, 203, 204, 205, 206, 207
		.byte 208, 209, 210, 211, 212, 213, 214, 215
		.byte 216, 217, 218, 219, 220, 221, 222, 223
		.byte 224, 225, 226, 227, 228, 229, 230, 231
		.byte 232, 233, 234, 235, 236, 237, 238, 239
		.byte 240, 241, 242, 243, 244, 245, 246, 247
		.byte 248, 249, 250, 251, 252, 253, 254, 255

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

crc8Table:
		.byte $00, $5e, $bc, $e2, $61, $3f, $dd, $83
		.byte $c2, $9c, $7e, $20, $a3, $fd, $1f, $41
		.byte $9d, $c3, $21, $7f, $fc, $a2, $40, $1e
		.byte $5f, $01, $e3, $bd, $3e, $60, $82, $dc
		.byte $23, $7d, $9f, $c1, $42, $1c, $fe, $a0
		.byte $e1, $bf, $5d, $03, $80, $de, $3c, $62
		.byte $be, $e0, $02, $5c, $df, $81, $63, $3d
		.byte $7c, $22, $c0, $9e, $1d, $43, $a1, $ff
		.byte $46, $18, $fa, $a4, $27, $79, $9b, $c5
		.byte $84, $da, $38, $66, $e5, $bb, $59, $07
		.byte $db, $85, $67, $39, $ba, $e4, $06, $58
		.byte $19, $47, $a5, $fb, $78, $26, $c4, $9a
		.byte $65, $3b, $d9, $87, $04, $5a, $b8, $e6
		.byte $a7, $f9, $1b, $45, $c6, $98, $7a, $24
		.byte $f8, $a6, $44, $1a, $99, $c7, $25, $7b
		.byte $3a, $64, $86, $d8, $5b, $05, $e7, $b9
		.byte $8c, $d2, $30, $6e, $ed, $b3, $51, $0f
		.byte $4e, $10, $f2, $ac, $2f, $71, $93, $cd
		.byte $11, $4f, $ad, $f3, $70, $2e, $cc, $92
		.byte $d3, $8d, $6f, $31, $b2, $ec, $0e, $50
		.byte $af, $f1, $13, $4d, $ce, $90, $72, $2c
		.byte $6d, $33, $d1, $8f, $0c, $52, $b0, $ee
		.byte $32, $6c, $8e, $d0, $53, $0d, $ef, $b1
		.byte $f0, $ae, $4c, $12, $91, $cf, $2d, $73
		.byte $ca, $94, $76, $28, $ab, $f5, $17, $49
		.byte $08, $56, $b4, $ea, $69, $37, $d5, $8b
		.byte $57, $09, $eb, $b5, $36, $68, $8a, $d4
		.byte $95, $cb, $29, $77, $f4, $aa, $48, $16
		.byte $e9, $b7, $55, $0b, $88, $d6, $34, $6a
		.byte $2b, $75, $97, $c9, $4a, $14, $f6, $a8
		.byte $74, $2a, $c8, $96, $15, $4b, $a9, $f7
		.byte $b6, $e8, $0a, $54, $d7, $89, $6b, $35


.segment "CODE"


; =============================================================================
;
; compare 256 bytes in BLOCK_BUFFER to flash for the specified address
;
; uint8_t __fastcall__ fastCompare256(uint8_t* address);
;
; parameters:
;       memory address
;
; return:
;       0, if no differences
;
; =============================================================================
.export _fastCompare256
_fastCompare256:
		sta cmpDest
		stx cmpDest+1
		ldx #0
		ldy #0
fastCmp:	lda __BLOCK_BUFFER_START__,y
cmpDest = * + 1
		cmp $8000,y
		bne fastCmpErr
		dey
		bne fastCmp
		lda #0
		rts

fastCmpErr:	lda #0
		rts

; =============================================================================
;
; Test if we are running on a C128 in C64 mode
;
; uint8_t __fastcall__ isC128(void);
;
; parameters:
;       -
;
; return:
;       1 in A, if it is running on a C128, 0 on a C64
;
; =============================================================================
.export _isC128
_isC128:
	inc $d02f
	lda $d02f
	dec $d02f
	eor $d02f
	beq isC64
	lda #1
isC64:	ldx #0
	rts


; =============================================================================
;
; Converts ASCII to PETSCII
;
; uint8_t __fastcall__ ascii2petscii(uint8_t ascii);
;
; parameters:
;       ASCII code
;
; return:
;       PETSCII code
;
; =============================================================================
.export _ascii2petscii
_ascii2petscii:
		tax
		lda ascii2petsciiTable,x
		ldx #0
		rts

; =============================================================================
;
; Disable interrupts (not as inline assembler to avoid optimizer reorder problems).
;
; void __fastcall__ disableInterrupts(void);
;
; parameters:
;       -
;
; return:
;       -
;
; =============================================================================
.export _disableInterrupts
_disableInterrupts:
		sei
		rts

        
; =============================================================================
;
; Enable interrupts (not as inline assembler to avoid optimizer reorder problems).
;
; void __fastcall__ enableInterrupts(void);
;
; parameters:
;       -
;
; return:
;       -
;
; =============================================================================
.export _enableInterrupts
_enableInterrupts:
		cli
		rts
        
; =============================================================================
;
; Fill 256 bytes in BLOCK_BUFFER with random numbers.
;
; void __fastcall__ rand256Block(void);
;
; parameters:
;       -
;
; return:
;       -
;
; =============================================================================
.export _rand256Block
_rand256Block:
		ldy #0
fill:		jsr _rand
		sta __BLOCK_BUFFER_START__,y
		iny
		bne fill
		rts

      
; =============================================================================
;
; Reads a command from MIDI and returns if the checksum was valid.
;
; uint8_t __fastcall__ midiReadCommand(uint8_t tag, uint8_t length);
;
; parameters:
;       tag (on cc65-stack): tag ID. If bit 7 is set, then there is no data and the second byte is an optional data byte.
;	length (in A): size-1 (0 means 1 data byte ... 0xff means 0x100 data bytes)
;
; return:
;       0, if checksum is ok
;
; =============================================================================
dataCount = tmp1
midiMessage = tmp2
data0 = tmp3
data1 = tmp4
ramIndex = ptr1
cmdLength = ptr1+1
cmdTag = ptr2
crc = ptr2+1

.export _midiReadCommand
_midiReadCommand:
		; save parameters
		sta cmdLength
		jsr popa
		sta cmdTag
		
		; init transfer variables
		lda #0
		sta dataCount
		
		; init CRC
		lda #$ff
		sta crc
		lda cmdTag
		jsr updateCrc
		lda cmdLength
		jsr updateCrc
		
		; check if there is data
		lda cmdTag
		and #$80
		beq midiLoadData
		lda cmdLength
		sta __BLOCK_BUFFER_START__
		
		; get checksum and return 0, if checksum is ok
midiTestCrc:	jsr readByte
		eor crc
		ldx #0
		rts
		
		; load data
midiLoadData:	lda #0
		sta ramIndex
		inc cmdLength
midiNextByte:	jsr readByte
		pha
		jsr updateCrc
		pla
		ldx ramIndex
		sta __BLOCK_BUFFER_START__,x
		inc ramIndex
		lda ramIndex
		cmp cmdLength
		bne midiNextByte
		beq midiTestCrc
		
		; read MIDI message, decode bytes and return next byte
readByte:	lda dataCount
		bne nextByte
		jsr _midiWaitAndReadByte
		sta midiMessage
		jsr _midiWaitAndReadByte
		sta data1
		jsr _midiWaitAndReadByte
		sta data0
		lda midiMessage
		and #2
		beq readByte2
		lda data1
		ora #$80
		sta data1
readByte2:	lda midiMessage
		and #1
		beq readByte3
		lda data0
		ora #$80
		sta data0
readByte3:	lda #2
		sta dataCount
nextByte:	dec dataCount
		ldx dataCount
		lda data0,x
		rts

updateCrc:	eor crc
		tax
		lda crc8Table,x
		sta crc
		rts


; =============================================================================
;
; Read a program from RAM and start it. Size and start address in first RAM bank.
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

		; standard mode
		lda #0
		sta CART_CONFIG

		; copy RAM loader to datasette buffer
		ldx #0
copy2:		lda __LOADER_LOAD__,x
		sta loaderStart,x
		inx
		cpx #loaderEnd-loaderStart
		bne copy2
		
		; load program from RAM and start it
		jmp loadRamPrg		

flashBank:
		.res 1

.segment "LOADER"

prgCounter = $5e
bank = $60
prgSize = $df00
prgStart = $df02

loaderStart:

startProgram:
		lda #0
		sta RAM_ADDRESS_EXTENSION
		
		lda prgStart
		beq testHigh
		cmp #$01
		bne startAsm
testHigh:	lda prgStart+1
		cmp #$08
		bne startAsm
		
		; if it starts at $0801 or $0800, then start as BASIC program
		jsr $a663		; CLR
		cli
		jmp $a7ae		; jump to basic RUN command
		
		; start as assembler program
startAsm:	jmp (prgStart)


		; copy program from RAM and start it
loadRamPrg:	sei
		lda #0
		sta RAM_ADDRESS_EXTENSION
		lda prgCounter
		pha
		lda prgCounter+1
		pha
		lda bank
		pha
		lda prgSize
		sta prgCounter
		lda prgSize+1
		sta prgCounter+1
		lda prgStart
		sta prg
		lda prgStart+1
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
		lda prgCounter + 1
		cmp #$ff
		beq copyRomEnd
copyRom2:	iny
		bne copyRom1
		inc prg+1
		inc bank
		lda bank
		sta RAM_ADDRESS_EXTENSION
		bne copyRom1
copyRomEnd:	pla
		sta bank
		pla
		sta prgCounter+1
		pla
		sta prgCounter
		jmp startProgram
		
loaderEnd:


.segment "CART128"
.export _cart128Start
.export _cart128End
_cart128Start:

		; recommended format from "C128 Programmers Reference", page 409
		sei
		jmp startup
		nop
		nop
		.byte 1  ; ID 1 for autostart cartridge
		.byte $43, $42, $4d  ; "cbm"

startup:	sei

		inc $d020
		jmp startup

_cart128End:

