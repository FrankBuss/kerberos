

.importzp   tmp1

.export     eload_recv

.include "config.s"

; =============================================================================
;
; Receive a byte from the drive over the fast protocol. Used internally only.
;
; parameters:
;       -
;
; return:
;       Byte in A, Z-flag according to A
;
; changes:
;       flags
;
; =============================================================================
.align 32
eload_recv:
        ; $dd00: | D_in | C_in | D_out | C_out || A_out | RS232 | VIC | VIC |
        ; Note about the timing: After 50 cycles a PAL C64 is about 1 cycle
        ; slower than the drive, an NTSC C64 is about 1 cycle faster. As we
        ; have a safety gap of about 2 us, this doesn't matter.

        ; Handshake Step 1: Drive signals byte ready with DATA low
@wait1:
        lda $dd00
        bmi @wait1

@eload_recv_waitbadline:
        lda $d011               ; wait until a badline won't screw up
        clc                     ; the timing
        sbc $d012
        and #7
        beq @eload_recv_waitbadline

        ; Handshake Step 2: Host sets CLK low to acknowledge
        lda $dd00
        ora #$10
        sta $dd00               ; [1]

        ; Handshake Step 3: Host releases CLK - Time base
        bit $ff                 ; waste 3 cycles
        and #$03
        ; an 1 MHz drive sees this 6..12 us after [1], so we have dt = 9
        sta $dd00               ; t = 0
        sta tmp1                ; 3

        nop
        nop
        nop
        nop
        nop                     ; 13

        ; receive bits
        lda $dd00               ; 17 - b0 b1
        lsr
        lsr
        eor $dd00               ; 25 - b2 b3
        lsr
        lsr
        eor $dd00               ; 33 - b4 b5
        lsr
        lsr
@eor:
        eor tmp1
        eor $dd00               ; 44 - b6 b7
        rts

