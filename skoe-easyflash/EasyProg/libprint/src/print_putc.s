
.include "c64.inc"

.code

; =============================================================================
;
; Send a character to the printer.
; void __fastcall__ print_putc(uint8_t c)
;
; parameters:
;       character in A (X ignored)
; return:
;       -
;
; =============================================================================
.export _print_putc
_print_putc:
        sta CIA2_PRB
        lda CIA2_PRA
        and #255 - 4
        sta CIA2_PRA
        ora #4
        sta CIA2_PRA
        rts

