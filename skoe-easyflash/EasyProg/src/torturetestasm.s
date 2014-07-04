;
; EasyFlash
;
; (c) 2009 Thomas 'skoe' Giesel
;
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
;
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
;
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.

.importzp       sp, sreg, regsave
.importzp       ptr1, ptr2, ptr3, ptr4
.importzp       tmp1, tmp2, tmp3, tmp4
.importzp       regbank

.import         popax

.import         _efShowROM
.import         _efHideROM
.import         __BLOCK_BUFFER_START__

; address of EasyFlash address
zpaddr   = ptr2

; address of EasyFlash offset
zpoffs   = ptr3

; I/O address used to select bank and slot
EASYFLASH_IO_BANK    = $de00
EASYFLASH_IO_SLOT    = $de01

; =============================================================================
;
; Fill the given buffer (256 bytes) with the test pattern for the flash address
; pointed to. Refer to the comment in tortureTest.c.
;
; void __fastcall__ tortureTestFillBuffer(const uint8_t* pBuffer,
;                                         const EasyFlashAddr* pAddr);
;
; parameters:
;       pAddr in AX
;       address pBuffer on cc65-stack
;
; return:
;       -
;
; =============================================================================
.export _tortureTestFillBuffer
.proc   _tortureTestFillBuffer
_tortureTestFillBuffer:
        ; remember address of EasyFlash address
        sta zpaddr
        stx zpaddr + 1

        ; get high-byte of offset
        ldy #4
        lda (zpaddr), y

        cmp #4
        bcs notLT1k

        ; byte 0..1k-1 => bank number + chip number
        ; load bank number
        ldy #1
        lda (zpaddr), y
        dey
fillWithBank:
        sta __BLOCK_BUFFER_START__, y
        iny
        iny
        bne fillWithBank
		; load chip number
		ldy #2
        lda (zpaddr), y
        ldy #0
fillWithChip:
        iny
        sta __BLOCK_BUFFER_START__, y
        iny
        bne fillWithChip
        rts

notLT1k:
        cmp #8
        bcs notLT2k

        ; byte 1k..2k-1 => slot number
        ldy #0
        lda (zpaddr), y
        bcc fillConst

notLT2k:
        cmp #16
        bcs notLT4k

        ; byte 2k..4k-1 => 0xaa
        lda #$aa
        bcc fillConst

notLT4k:
        ; byte 4k..6k-1 => 0x55
        cmp #24
        bcs notLT6k

        lda #$55

fillConst:
        ; fill the buffer with the value in A
        ldy #0
fillConst1:
        sta __BLOCK_BUFFER_START__, y
        iny
        bne fillConst1
        rts

notLT6k:
        ; byte 6k..7k-1 => 0..255
        cmp #28
        bcs notLT7k

        ldy #0
fillInc:
        tya
        sta __BLOCK_BUFFER_START__, y
        iny
        bne fillInc
        rts

notLT7k:
        ; byte 7k..8k-1 => 0..255
        ldy #0
        ldx #255
fillDec:
        txa
        sta __BLOCK_BUFFER_START__, y
        dex
        iny
        bne fillDec
        rts
.endproc

; =============================================================================
;
; Test the banking register: First 0..63 then 63..0
;
; uint16_t __fastcall__ tortureTestBanking(void);

; Note: This function and all data must not be below ROM!
;       Therefore LOWCODE must be for code and HIRAM or BLOCK_BUFFER for data.
;
; parameters: Refer to the comment in tortureTest.c.
;
; return:
;       AX  0 for no error, otherwise
;           high byte (X) bank which didn't work, low byte (A) actual bank set
;
; =============================================================================
.segment "LOWCODE"
.export _tortureTestBanking
.proc   _tortureTestBanking
_tortureTestBanking:
        jmp _efShowROM
        ldx #0
tb:
        stx EASYFLASH_IO_BANK
        cpx $8000
        bne bankError
        inx
        cpx #64
        bne tb

        dex     ; 63
tb2:
        stx EASYFLASH_IO_BANK
        cpx $8000
        bne bankError
        dex
        bpl tb2

        lda #0
        tax
        jmp _efHideROM

bankError:
        lda $8000
        jmp _efHideROM

.endproc
.code


; =============================================================================
;
; Check if the 256 bytes of RAM at $DF00 are okay.
;
; Return 1 for success, 0 for error
; uint8_t __fastcall__ tortureTestCheckRAM(void);
;
; parameters:
;       -
;
; return:
;       result in AX (A = low), 1 = okay, 0 = error
;
; =============================================================================
.export _tortureTestCheckRAM
.proc   _tortureTestCheckRAM
_flashCodeCheckRAM:
        ; write 0..255
        ldx #0
l1:
        txa
        sta $df00, x
        dex
        bne l1
        ; check 0..255
l2:
        txa
        cmp $df00, x
        bne ret_err
        dex
        bne l2

        ; write $55
        lda #$55
l3:
        sta $df00, x
        dex
        bne l3
        ; check $55
l4:
        cmp $df00, x
        bne ret_err
        dex
        bne l4

        ; write $AA
        lda #$AA
l5:
        sta $df00, x
        dex
        bne l5
        ; check $AA
l6:
        cmp $df00, x
        bne ret_err
        dex
        bne l6  ; x = 0
        lda #1
        rts
ret_err:
        lda #0
        tax
        rts
.endproc


