.importzp       sp, sreg, regsave
.importzp       ptr1, ptr2, ptr3, ptr4
.importzp       tmp1, tmp2, tmp3, tmp4

.import         popax
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
; Start program from currently selected ROM slot.
;
; void __fastcall__ startProgramFromRom(void);
;
; parameters:
;       -
;
; return:
;       -
;
; =============================================================================
.export _startProgramFromRom
_startProgramFromRom:
		; copy RAM loader to datasette buffer
		ldx #0
copy:		lda __ROMLOADER_LOAD__,x
		sta romLoaderStart,x
		inx
		cpx #romLoaderEnd-romLoaderStart
		bne copy
		
		; save bank
		lda flashBank
		sta romLoaderFlashBank

		; load program from ROM and start it
		jmp romLoaderStart
		
.segment "ROMLOADER"

romLoaderStart:
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

		; enable cartridge at $8000
		sei
		lda #(CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW)
		sta CART_CONTROL

		; copy program from ROM
		ldx $80fd
		inx
		lda $80fe
		sta copyCrt2+1
		lda $80ff
		sta copyCrt2+2
		lda romLoaderFlashBank
		pha
		ldy #0
copyCrt1:	lda $8100,y
copyCrt2:	sta $0801,y
		iny
		bne copyCrt1
		inc copyCrt2+2
		inc copyCrt1+2
		lda copyCrt1+2
		cmp #$a0
		bne copyCrt3
		lda #$80
		sta copyCrt1+2
		inc romLoaderFlashBank
		lda romLoaderFlashBank
		sta FLASH_ADDRESS_EXTENSION
copyCrt3:	dex
		bne copyCrt1
		
		; adjust prg end
		pla
		sta FLASH_ADDRESS_EXTENSION
		clc
		lda $80fc
		adc $80fe
		sta prg
		lda $80fd
		adc $80ff
		sta prg+1

		; disable cartridge
		lda #(CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH)
		sta CART_CONTROL

		; enable MIDI DATEL
		lda #(MIDI_CONFIG_IRQ_ON | MIDI_CONFIG_CLOCK_2_MHZ | MIDI_CONFIG_ENABLE_ON)
		sta MIDI_CONFIG
		lda #$46
		sta MIDI_ADDRESS

		; start as BASIC program
		jsr $a663		; CLR
		cli
		jmp $a7ae		; jump to basic RUN command
		
romLoaderEnd:

romLoaderFlashBank:
		.res 1

.segment "LOWCODE"

        
; =============================================================================
;
; Receive data from MIDI and save in external cartride RAM.
;
; void __fastcall__ loadProgram(void);
;
; parameters:
;       -
;
; return:
;       -
;
; =============================================================================
dataCount = tmp1
midiMessage = tmp2
data0 = tmp3
data1 = tmp4
ramIndex = ptr1
ramBank = ptr1+1
start = ptr2
end = ptr3

.export _loadProgram
_loadProgram:
		; init transfer variables
		lda #0
		sta dataCount
		
		; read filename
		ldx #0
		stx ramIndex
readFilename:	jsr readByte
		cmp #0
		beq nameEnd
		tax
		lda ascii2Screencode,x
		ldx ramIndex
		sta $0428,x
		lda #1
		sta $d828,x
		inc ramIndex
		bne readFilename
		
		; init RAM write variables
nameEnd:	lda #0
		sta RAM_ADDRESS_EXTENSION
		sta ramBank
		sta ramIndex
		lda #1
		sta $d850

		; read program length
		jsr readByte
		sta prgSize
		jsr readByte
		sta prgSize+1
		
		; read program start
		jsr readByte
		sta prgStart
		sta start
		jsr readByte
		sta prgStart+1
		sta start+1
		jsr readByte
		sta prgStart+2
		jsr readByte
		sta prgStart+3
		
		; calculate program end
		lda start
		clc
		adc prgSize
		sta end
		lda start+1
		adc prgSize+1
		sta end+1
		
;		jsr showTransferStarted

		lda #1
		sta ramBank
		sta RAM_ADDRESS_EXTENSION
		
		; read program
readProgram:	jsr readByte
		ldy ramIndex
		sta $df00,y
		inc ramIndex
		bne readProgram2
		inc ramBank
		lda ramBank
		sta RAM_ADDRESS_EXTENSION
readProgram2:	inc start
		bne readProgram3
		inc start+1
		inc $0450
readProgram3:	lda start+1
		cmp end+1
		bne readProgram
		lda start
		cmp end
		bne readProgram
		
		; read checksum
		jsr readByte
		jsr readByte
		
		rts
		
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


; =============================================================================
;
; Read a program from RAM and start it. Size and start address in first RAM bank.
;
; void __fastcall__ startProgram(void);
;
; parameters:
;       start: destination address where the program starts
;       size: program size
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
copyRom1:	lda $df00,y
		sta (prg),y
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

