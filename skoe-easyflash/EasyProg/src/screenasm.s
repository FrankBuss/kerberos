
.include "c64.inc"

.importzp   tmp1, tmp2, tmp3, ptr1, sp
.import     PLOT, plot, incsp2

IOTMP           = $d7
RPTFLG          = $028a
CHROUT_SCREEN   = $e716


; =============================================================================
.bss

; =============================================================================
.rodata
hexDigits:
        .byte "0123456789ABCDEF"

; =============================================================================
.code

; Write one character to the screen without checking any line wrap etc.
; and increment CURS_X
putchar:
        ora RVS                 ; Set revers bit
        sta IOTMP
        tya
        pha
        ldy CURS_X
        lda IOTMP
        sta (SCREEN_PTR),y      ; Set char
        lda CHARCOLOR
        sta (CRAM_PTR),y        ; Set color
        inc CURS_X
        pla
        tay
        lda IOTMP
        rts

; =============================================================================
; Configure key repeat.
; uint8_t __fastcall__ screenSetKeyRepeat(uint8_t val)
;
; parameters:
;       KEY_REPEAT_* in A (X ignored)
; return:
;       previous setting in AX (A = low, X can be ignored)
;
; =============================================================================
.export _screenSetKeyRepeat
_screenSetKeyRepeat:
        ldx RPTFLG
        sta RPTFLG
        txa
        ldx #0
        rts

; =============================================================================
; Make a small delay proportional to t.
; void __fastcall__ screenDelay(unsigned t)
;
; parameters:
;       t in AX (A = low)
; return:
;       -
;
; =============================================================================
.export _screenDelay
_screenDelay:
        tay
@wait:
        dey
        bne @wait
        dex
        bne @wait
        rts

; =============================================================================
; void __fastcall__ screenPrintHex2(uint8_t n)
;
; parameters:
;       n in A
; return:
;       -
;
; =============================================================================
.export _screenPrintHex2
_screenPrintHex2:
        pha
        lsr a
        lsr a
        lsr a
        lsr a
        tax
        lda hexDigits, x
        jsr CHROUT_SCREEN
        pla
        and #$0f
        tax
        lda hexDigits, x
        jmp CHROUT_SCREEN

; =============================================================================
; void __fastcall__ screenPrintHex4(uint16_t n)
;
; parameters:
;       n in AX
; return:
;       -
;
; =============================================================================
.export _screenPrintHex4
_screenPrintHex4:
        pha
        txa
        jsr _screenPrintHex2
        pla
        jmp _screenPrintHex2

; =============================================================================
; void __fastcall__ screenPrintTopLine(uint8_t xStart, uint8_t xEnd, uint8_t y);
; void __fastcall__ screenPrintSepLine(uint8_t xStart, uint8_t xEnd, uint8_t y);
; void __fastcall__ screenPrintBottomLine(uint8_t xStart, uint8_t xEnd, uint8_t y);
;
; Print the Top/Separator/Bottom line of a frame at y between xStart and xEnd
; (incl).
;
; ++++++++ <=
; +      +
; ++++++++ <=
; +      +
; ++++++++ <=
;
; parameters:
;       y in A
;       xEnd on Stack
;       xStart on Stack
; return:
;       -
;
; =============================================================================
.export _screenPrintSepLine
_screenPrintSepLine:
        ldy #$6b        ; screen code for |-
        sty tmp1
        ldy #$40        ; screen code for ---
        sty tmp2
        ldy #$73        ; screen code for -|
        ; fall through
printLine:
        sty tmp3
        ; gotoxy(xStart, y);
        tax             ; line for PLOT
        ldy #0
        lda (sp),y
        sta ptr1        ; xEnd (ptr1 used for single byte)
        iny
        lda (sp),y      ; xStart
        tay             ; column for PLOT, used below too
        clc
        jsr PLOT

        ; cputc(0xab);
        lda tmp1
        jsr putchar

        ; chline(xEnd - xStart - 1);
        lda tmp2
@next:
        iny             ; current column
        cpy ptr1
        beq @end
        jsr putchar; CHROUT_SCREEN
        jmp @next
@end:

        ; cputc(0xb3);
        lda tmp3
        jsr putchar
        jmp incsp2

.export _screenPrintTopLine
_screenPrintTopLine:
        ldy #$70
        sty tmp1
        ldy #$40
        sty tmp2
        ldy #$6e
        bne printLine

.export _screenPrintBottomLine
_screenPrintBottomLine:
        ldy #$6d
        sty tmp1
        ldy #$40
        sty tmp2
        ldy #$7d
        bne printLine
