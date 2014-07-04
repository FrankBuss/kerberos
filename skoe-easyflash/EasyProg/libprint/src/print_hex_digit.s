
.include "c64.inc"

.import _print_putc

.code

; =============================================================================
;
; Print a hexadecimal digit.
; void __fastcall__ print_hex_digit(uint8_t val)
;
; parameters:
;       value in A (X ignored)
; return:
;       -
;
; =============================================================================
.export _print_hex_digit
_print_hex_digit:
        and #$0f
        cmp #10
        bcs ge10
        adc #$30            ; PETSCII '0'
        jmp _print_putc
ge10:
        adc #$41 - 10 - 1   ; PETSCII 'a', - 1 because C is set
        jmp _print_putc
