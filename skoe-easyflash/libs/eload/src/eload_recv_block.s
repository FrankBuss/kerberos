
.importzp       ptr1
.import         popax

.import         eload_recv
.export         _eload_recv_block
.export         _eload_recv_status

.include "config.s"

; =============================================================================
;
; Receive a byte from the drive over the fast protocol. Used internally only.
; void __fastcall__ eload_recv_block(uint8_t* addr, uint8_t size);
;
; parameters:
;       addr        Destination address
;       size        Number of bytes, 0..255, 0 means 256
;
; return:
;       -
;
; changes:
;       A, X, Y
;
; =============================================================================
_eload_recv_block:
        php                 ; to backup the interrupt flag
        sei

        pha                 ; size

        jsr popax
        sta ptr1
        stx ptr1 + 1

        pla
        tax                 ; size in x
recv_loop:
        ldy #0              ; offset in y
:
        jsr eload_recv
        sta (ptr1), y
        iny
        dex
        bne :-

        plp                 ; to restore the interrupt flag
        rts

; =============================================================================
;
; Receive 4 bytes from the drive over the fast protocol.
; void __fastcall__ eload_recv_status(uint8_t* addr);
;
; parameters:
;       addr        Destination address
;
; return:
;       -
;
; changes:
;       A, X, Y
;
; =============================================================================
_eload_recv_status:
        php                 ; to backup the interrupt flag
        sei

        sta ptr1
        stx ptr1 + 1
        ldx #3
        jmp recv_loop

