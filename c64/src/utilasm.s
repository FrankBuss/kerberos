
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


.export _test5
_test5:
		sei
		; enable Ultimax mode
		lda #(CART_CONTROL_GAME_LOW | CART_CONTROL_EXROM_HIGH)
		sta CART_CONTROL
test5_loop:	lda $f000
		jmp test5_loop

.export _test6
_test6:
		sei
		; enable Ultimax mode
		lda #(CART_CONTROL_GAME_LOW | CART_CONTROL_EXROM_HIGH)
		sta CART_CONTROL
		lda #$42
test6_loop:	sta $f000
		jmp test6_loop

.export _test7
_test7:
		sei
		lda #(CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH)
		sta CART_CONTROL
		; enable kernal hack and hiram hack
		lda #(CART_CONFIG_RAM_AS_ROM_ON | CART_CONFIG_KERNAL_HACK_ON | CART_CONFIG_HIRAM_HACK_ON)
		sta CART_CONFIG
		lda 1
		ldx #$35
		ldy #$37
test7_loop:	stx 1
		lda $f000
		sty 1
		lda $f000
		jmp test7_loop


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
; Set flash bank for flashWriteByte and flashEraseSector
;
; void __fastcall__ flashSetBank(uint8_t bank);
;
; parameters:
;       bank
;
; return:
;       -
;
; =============================================================================
.export _flashSetBank
_flashSetBank:
		sta flashBank
		rts

; =============================================================================
;
; Erase 4 k sector at the specified address in flash (starting at $8000, set bank before)
;
; void __fastcall__ flashEraseSector(uint8_t* address);
;
; parameters:
;       memory address ($8000 or $9000)
;
; return:
;       -
;
; =============================================================================
.export _flashEraseSector
_flashEraseSector:
		sta tmp1
		stx tmp2
		
		jsr prepareWrite
		
		; cycle 3: write $80 to $AAA
		ldx #<$8aaa
		ldy #>$8aaa
		lda #$80
		jsr ultimaxWrite
		
		; cycle 4: write $AA to $AAA
		ldx #<$8aaa
		ldy #>$8aaa
		lda #$aa
		jsr ultimaxWrite
		
		; cycle 5: write $55 to $555
		ldx #<$8555
		ldy #>$8555
		lda #$55
		jsr ultimaxWrite
		
		; activate the right bank
		lda flashBank
		sta FLASH_ADDRESS_EXTENSION
		
		; cycle 6: write $50 to base + SA
		ldx tmp1
		ldy tmp2
		lda #$50
		jsr ultimaxWrite
		
		; wait min. 25 ms
		ldy #20
sewait2:
		ldx #0
sewait:
		dex
		bne sewait
		dey
		bne sewait2
		
		rts

; =============================================================================
;
; Write 256 bytes in BLOCK_BUFFER to flash to the specified address (starting at $8000, set bank before)
;
; void __fastcall__ flashWrite256Block(uint8_t* address);
;
; parameters:
;       memory address
;
; return:
;       -
;
; =============================================================================
.export _flashWrite256Block
_flashWrite256Block:
		sei
		sta blwDest
		stx blwDest+1
		ldy #0
block2:		lda __BLOCK_BUFFER_START__,y
		cmp #$ff
		; nothing to be done if $ff
		beq blockEnd

		; Ultimax mode
		ldx #(CART_CONTROL_GAME_LOW | CART_CONTROL_EXROM_HIGH)
		stx CART_CONTROL

		; select bank 0
		ldx #0
		stx FLASH_ADDRESS_EXTENSION
		
		; cycle 1: write $AA to $AAA
		ldx #$aa
		stx $8aaa
		
		; cycle 2: write $55 to $555
		ldx #$55
		stx $8555

		; cycle 3: write $A0 to $AAA
		ldx #$a0
		stx $8aaa

		; now we have to activate the right bank
		ldx flashBank
		stx FLASH_ADDRESS_EXTENSION
		
		; cycle 4: write data
blwDest = * + 1
		sta $ffff           ; will be modified
		; wait max 10 us for byte programming; next commands are longer, so no more delay needed
		
		; normal cartridge mode
		ldx #(CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW)
		stx CART_CONTROL
		
blockEnd:	inc blwDest
		bne block3
		inc blwDest+1
block3:		iny
		bne block2
		cli
		rts


; =============================================================================
;
; compare 256 bytes in BLOCK_BUFFER to flash for the specified address (starting at $8000, set bank before)
;
; uint8_t __fastcall__ flashCompare256Block(uint8_t* address);
;
; parameters:
;       memory address
;
; return:
;       0, if no differences
;
; =============================================================================
.export _flashCompare256Block
_flashCompare256Block:
		sta tmp1
		stx tmp2
		lda #0
		sta tmp3
		
		; activate bank
		lda flashBank
		sta FLASH_ADDRESS_EXTENSION

		; read byte
cmp1:		ldx tmp1
		ldy tmp2
		jsr ultimaxRead
		
		; compare
		ldy tmp3
		cmp __BLOCK_BUFFER_START__,y
		bne cmpErr
		
		; next byte
		inc tmp1
		bne cmp2
		inc tmp2
cmp2:		inc tmp3
		bne cmp1
		
		; compare ok, return 0
		ldx #0
		txa
		rts

		; compare error
cmpErr: 	lda #1
		ldx #0
		rts

; =============================================================================
;
; Write byte to flash (address starts at $8000, set bank before)
;
; void __fastcall__ flashWriteByte(uint8_t* address, uint8_t data);
;
; parameters:
;       value in A
;       address on cc65-stack $8xxx/$9xxx
;
; return:
;       -
;
; =============================================================================
.export _flashWriteByte
_flashWriteByte:
		pha
		jsr popax
		sta bwDest
		stx bwDest+1
		
		; nothing to be done if $ff
		pla
		cmp #$ff
		beq writeEnd
		pha
		
		sei

		; Ultimax mode
		ldx #(CART_CONTROL_GAME_LOW | CART_CONTROL_EXROM_HIGH)
		stx CART_CONTROL

		; select bank 0
		lda #0
		sta FLASH_ADDRESS_EXTENSION
		
		; cycle 1: write $AA to $AAA
		lda #$aa
		sta $8aaa
		
		; cycle 2: write $55 to $555
		lda #$55
		sta $8555

		; cycle 3: write $A0 to $AAA
		lda #$a0
		sta $8aaa

		; now we have to activate the right bank
		lda flashBank
		sta FLASH_ADDRESS_EXTENSION
		
		; cycle 4: write data
		pla
bwDest = * + 1
		sta $ffff           ; will be modified
		; wait max 10 us for byte programming; next commands are longer, so no more delay needed
		
writeEnd:	
		; normal cartridge mode
		ldx #(CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW)
		stx CART_CONTROL
		cli
		rts


; =============================================================================
;
; Write byte to flash (address starts at $8000, set bank before)
;
; void __fastcall__ flashWriteByte(uint8_t* address, uint8_t data);
;
; parameters:
;       value in A
;       address on cc65-stack $8xxx/$9xxx
;
; return:
;       -
;
; =============================================================================
.export _flashWriteByte2
_flashWriteByte2:
		pha
		jsr popax
		sta tmp1
		stx tmp2
		
		; nothing to be done if $ff
		pla
		cmp #$ff
		beq writeEnd
		pha
		
		jsr prepareWrite
		
		; cycle 3: write $A0 to $AAA
		ldx #<$8aaa
		ldy #>$8aaa
		lda #$a0
		jsr ultimaxWrite
		
		; now we have to activate the right bank
		lda flashBank
		sta FLASH_ADDRESS_EXTENSION
		
		; cycle 4: write data
		ldx tmp1
		ldy tmp2
		pla
		jsr ultimaxWrite
		
		; max 10 us for byte programming, wait a bit longer
		ldy #15
writeWaitx:	dey
		bne writeWaitx

writeEndx:	rts


; =============================================================================
;
; Read flash ID
;
; uint16_t __fastcall__ flashReadId();
;
; parameters:
;       -
;
; return:
;       id in AX (A = low)
;
; =============================================================================
.export _flashReadId
_flashReadId:
		; check for flash
		jsr prepareWrite
		
		; cycle 3: write $90 to $AAA
		ldx #<$8AAA
		ldy #>$8AAA
		lda #$90
		jsr ultimaxWrite
		
		; offset 0: Manufacturer ID
		ldx #<$8000
		ldy #>$8000
		jsr ultimaxRead
		sta tmp1
		
		; offset 1: Device ID
		ldx #<$8001
		ldy #>$8001
		jsr ultimaxRead
		pha
		
		; ID Exit: write 0xf0 to any address
		ldy #>$8000
		lda #$f0
		jsr ultimaxWrite
		
		pla
		ldx tmp1
		rts

; =============================================================================
;
; Read byte from flash (address starts at $8000, set bank before)
;
; uint8_t __fastcall__ flashReadByte(uint8_t* address);
;
; parameters:
;       address
;
; return:
;       data in AX (A = low)
;
; =============================================================================
.export _flashReadByte
_flashReadByte:
		sta tmp1
		stx tmp2
		
		; activate bank
		lda flashBank
		sta FLASH_ADDRESS_EXTENSION
		
		; read byte
		ldx tmp1
		ldy tmp2
		jsr ultimaxRead
		
		; data in A
		ldx #0
		rts


; =============================================================================
;
; Internal function
;
; Set bank 0, send command cycles 1 and 2.
;
; =============================================================================
prepareWrite:
		; select bank 0
		lda #0
		sta FLASH_ADDRESS_EXTENSION
		
		; cycle 1: write $AA to $AAA
		ldx #<$8aaa
		ldy #>$8aaa
		lda #$aa
		jsr ultimaxWrite
		
		; cycle 2: write $55 to $555
		ldx #<$8555
		ldy #>$8555
		lda #$55
		jmp ultimaxWrite


; =============================================================================
;
; Internal function
;
; Write byte to address
;
;
; Parameters:
;           A   Value
;           XY  Address (X = low)
; Changes:
;           X
;
; =============================================================================
ultimaxWrite:
		sei
		stx uwDest
		sty uwDest + 1
		
		; /GAME low, /EXROM high
		ldx #(CART_CONTROL_GAME_LOW | CART_CONTROL_EXROM_HIGH)
		stx CART_CONTROL
uwDest = * + 1
		sta $ffff           ; will be modified
		
		; /GAME high, /EXROM low
		ldx #(CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW)
		stx CART_CONTROL
		cli
		rts

ultimaxRead:
		sei
		stx urDest
		sty urDest + 1
		
		; /GAME low, /EXROM high
		ldx #(CART_CONTROL_GAME_LOW | CART_CONTROL_EXROM_HIGH)
		stx CART_CONTROL
urDest = * + 1
		lda $ffff           ; will be modified
		
		; /GAME high, /EXROM low
		ldx #(CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW)
		stx CART_CONTROL
		cli
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


.segment "TEST"

.org $7000
.export _test1
_test1:
		sei
		lda #1
test1_loop:	sta $0400
		jmp test1_loop
.align 256

.export _test2
_test2:
		sei
test2_loop:	lda $0400
		jmp test2_loop
.align 256

.export _test3
_test3:
		sei
		lda #$42
test3_loop:	lda $df00
		jmp test3_loop
.align 256

.export _test4
_test4:
		sei
		lda #$42
test4_loop:	sta $df00
		jmp test4_loop
.align 256
