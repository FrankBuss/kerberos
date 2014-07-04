

.import _print_putc

.code

; =============================================================================
;
; Print CR/LF.
; void print_crlf(void)
;
; parameters:
;       -
; return:
;       -
;
; =============================================================================
.export _print_crlf
_print_crlf:
        lda #10
        jsr _print_putc
        lda #13
        jmp _print_putc

