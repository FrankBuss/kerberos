;
; EasyFlash - spritesasm.s - Sprites
;
; (c) 2011 Thomas 'skoe' Giesel
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

.import         incsp2
.importzp       sp, tmp1, ptr1, ptr2, ptr3, ptr4

PROGRESS_SCREEN_ADDR    = $0400 + 17 * 40 + 6
PROGRESS_COLOR_ADDR     = $d800 + 17 * 40 + 6
PROGRESS_BANKS_PER_LINE = 32
FLASH_NUM_BANKS         = 64
FLASH_NUM_CHIPS         = 2

.import _m_aBlockStates
.import _g_nSelectedSlot

.code

; =============================================================================
;
; Set ptr2 to screen address of progress map and
;     ptr3 to color address.
;
; Changes: A
;
; =============================================================================
progressSetScreenPointers:
        lda #<PROGRESS_SCREEN_ADDR
        sta ptr2
        sta ptr3
        lda #>PROGRESS_SCREEN_ADDR
        sta ptr2 + 1

        lda #>PROGRESS_COLOR_ADDR
        sta ptr3 + 1
        rts

; =============================================================================
;
; Input:   A = number to add, e.g. 40 for one line
; Changes: A
;
; =============================================================================
progressScreenPointersInc:
        clc
        adc ptr2
        sta ptr2
        sta ptr3
        bcc :+
        inc ptr2 + 1
        inc ptr3 + 1
:
        rts

; =============================================================================
;
; Update the progress display area, values only.
;
; void progressUpdateDisplay(void);
;
;
; parameters:
;       -
;
; return:
;       -
;
; =============================================================================
.export _progressUpdateDisplay
_progressUpdateDisplay:
        lda #<_m_aBlockStates
        sta ptr1
        ldy #>_m_aBlockStates

        ldx _g_nSelectedSlot
@mul:
        dex
        bmi @mulEnd
        lda ptr1
        clc
        adc #(FLASH_NUM_CHIPS * FLASH_NUM_BANKS)
        sta ptr1
        bcc @mul
        iny
        bne @mul    ; always
@mulEnd:
        sty ptr1 + 1

        jsr progressSetScreenPointers
        ldx #3
line_loop:
        ldy #PROGRESS_BANKS_PER_LINE - 1
bank_loop:
        lda (ptr1), y
        sta (ptr2), y
        lda $0286       ; foreground color
        sta (ptr3), y
        dey
        bpl bank_loop

        clc
        lda ptr1
        adc #PROGRESS_BANKS_PER_LINE
        sta ptr1
        bcc :+
        inc ptr1 + 1
:
        lda #40
        jsr progressScreenPointersInc

        dex
        bpl line_loop
        rts

; =============================================================================
;
; Update the progress display area, one bank only.
;
; void __fastcall__ progressSetBankState(uint8_t nBank, uint8_t nChip,
;                                        uint8_t state);
;
; parameters:
;       nBank (on stack)    must be in range 0..63
;
; return:
;       -
;
; =============================================================================
.export _progressDisplayBank
_progressDisplayBank:
        sta tmp1        ; State

        jsr progressSetScreenPointers

        ldy #0
        lda (sp),y      ; Chip => A
        beq @noIncBank
        lda #80
        jsr progressScreenPointersInc
@noIncBank:
        iny             ; Y = 1
        lda (sp),y      ; Bank => A

        cmp #PROGRESS_BANKS_PER_LINE
        bcc @noWrap
        clc
        adc #(40 - PROGRESS_BANKS_PER_LINE)
@noWrap:
        tay             ; Offset to current bank start on screen => Y
        lda tmp1        ; State
        sta (ptr2), y
        lda $0286       ; Foreground color
        sta (ptr3), y

        jmp incsp2
