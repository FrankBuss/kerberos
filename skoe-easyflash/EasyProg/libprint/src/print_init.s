
.include "c64.inc"

.import _print_putc

.code

; =============================================================================
;
; Init printer library.
; void print_init(void)
;
; parameters:
;       -
; return:
;       -
;
; =============================================================================
.export _print_init
_print_init:
        lda #$ff
        sta CIA2_DDRB
        lda CIA2_PRA
        ora #4
        sta CIA2_PRA
        lda CIA2_DDRA
        ora #4
        sta CIA2_DDRA
        ; switch to business mode (refer to MPS-801 printer manual)
        lda #17
        jmp _print_putc

