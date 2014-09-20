.importzp       tmp1, tmp2

.import         __BLOCK_BUFFER_START__

.include "regs.inc"

.segment "LOWCODE"

        
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
; Note: uses Ultimax mode, so disable interrupts before calling this function
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
; Note: uses Ultimax mode, so disable interrupts before calling this function
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
		sta blwDest
		stx blwDest+1
		ldy #0
block2:		lda __BLOCK_BUFFER_START__,y
		cmp #$ff
		; nothing to be done if $ff
		beq blockEnd

		; Ultimax mode
		ldx #(MIDI_CONFIG_NMI_OFF | MIDI_CONFIG_CLOCK_500_KHZ | MIDI_CONFIG_ENABLE_ON)
		stx MIDI_CONFIG
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
		sta $ffff,y         ; will be modified
		; wait max 10 us for byte programming; next commands are longer, so no more delay needed
		
		; normal cartridge mode
		ldx #(CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW)
		stx CART_CONTROL
		ldx #(MIDI_CONFIG_NMI_ON | MIDI_CONFIG_CLOCK_500_KHZ | MIDI_CONFIG_ENABLE_ON)
		stx MIDI_CONFIG
		
blockEnd:	iny
		bne block2
		rts


; =============================================================================
;
; Read flash ID
; Note: uses Ultimax mode, so disable interrupts before calling this function
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
		lda $8000
		sta tmp1
		
		; offset 1: Device ID
		lda $8001
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
		stx uwDest
		sty uwDest + 1
		
		; /GAME low, /EXROM high
		ldx #(MIDI_CONFIG_NMI_OFF | MIDI_CONFIG_CLOCK_500_KHZ | MIDI_CONFIG_ENABLE_ON)
		stx MIDI_CONFIG
		ldx #(CART_CONTROL_GAME_LOW | CART_CONTROL_EXROM_HIGH)
		stx CART_CONTROL
uwDest = * + 1
		sta $ffff           ; will be modified
		
		; /GAME high, /EXROM low
		ldx #(CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_LOW)
		stx CART_CONTROL
		ldx #(MIDI_CONFIG_NMI_ON | MIDI_CONFIG_CLOCK_500_KHZ | MIDI_CONFIG_ENABLE_ON)
		stx MIDI_CONFIG
		rts

flashBank:
		.res 1
