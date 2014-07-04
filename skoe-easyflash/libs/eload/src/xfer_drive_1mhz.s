 ;
 ; ELoad
 ;
 ; (c) 2011 Thomas Giesel
 ; transfer code based on work by Per Olofsson
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
 ;
 ; Thomas Giesel skoe@directbox.com
 ;

; =============================================================================
;
; Signal with CLK low that we are ready and wait until the C64 signals that it
; wants to send data. Return after SEI.
;
; Exit the drive code on ATN.
;
; changes:
;       A
;
; =============================================================================
drv_wait_rx:
        lda #$08                ; CLK low to signal that we're receiving
        sta serport

        lda #$01
:
        bit serport             ; wait for DATA low
        bmi @exit               ; exit if ATN goes low
        beq :-
        sei
        rts
@exit:
        jmp drv_exit

; =============================================================================
;
; Send a byte to the host.
;
; parameters:
;       Byte in A
;
; return:
;       -
;
; changes:
;       A, Y, zptmp
;
; =============================================================================
        ; serport: | A_in | DEV | DEV | ACK_out || C_out | C_in | D_out | D_in |
drv_send:
        bit serport             ; check for ATN
        bmi exit_1              ; leave the drive code if it is active

        sta zptmp
        lsr
        lsr
        lsr
        lsr
        tay                     ; get high nibble into Y

        ; Handshake Step 1: Drive signals byte ready with DATA low
        lda #$02
        sta serport

        ; I moved this after Step 1 because the C64
        ; makes SEI and the badline test now
        lda drv_sendtbl,y       ; get the CLK, DATA pairs for high nibble
        pha
        lda zptmp
        and #$0f                ; get low nibble into Y
        tay

        ; Handshake Step 2: Host sets CLK low to acknowledge
        lda #$04
@wait2:
        bit serport             ; wait for CLK low (that's 1!)
        beq @wait2
        ; between the last cycle of these two "bit serport" are 6..12 cycles

        ; Handshake Step 3: Host releases CLK - Timing base
        ; if CLK is high (that's 0!) already, skip 3 cycles
        bit serport
        beq @reduce_jitter
        nop                     ; 6 cycles vs. 3 cycles
        nop
@reduce_jitter:                 ; t = 4..7 (only 3 us jitter)

        ; 1 MHz code
        ; get CLK, DATA pairs for low nibble
        lda drv_sendtbl,y       ;  8..
        sta serport             ; 12..15 - b0 b1 (CLK DATA)

        asl                     ; 14..
        and #$0f                ; 16..
        sta serport             ; 20..23 - b2 b3

        pla                     ; 24
        sta serport             ; 28..31 - b4 b5

        asl                     ; 30..
        and #$0f                ; 32..
        sta serport             ; 36..39 - b6 b7

        nop                     ; 38..
        nop                     ; 40..
        lda #$00                ; 42..
        sta serport             ; 48..51  set CLK and DATA high

        rts

exit_1:
        jmp drv_exit

drv_sendtbl:
        ; 0 0 0 0 b0 b2 b1 b3
        .byte $0f, $07, $0d, $05
        .byte $0b, $03, $09, $01
        .byte $0e, $06, $0c, $04
        .byte $0a, $02, $08, $00

; =============================================================================
;
; Receive 2 * 256 bytes of drive code to $0300
;
; =============================================================================
drv_load_code:
        ldx #>$0300
        bne drv_load_code_common ; always

; =============================================================================
;
; Receive 2 * 256 bytes of overlay code to $0500
;
; =============================================================================
drv_load_overlay:
        ldx #>$0500
drv_load_code_common:
        ldy #0
        tya
        jsr recv                ; 1st block
        inc buff_ptr + 1
        jsr recv_to_ptr         ; 2nd block
        rts

; =============================================================================
;
; Load Y bytes to AX. The first byte will be stored to the highest
; address.
;
; parameters:
;       Y           number of bytes (1 to 256=0)
;
; return:
;       buff_ptr    set to AX
;       A           last byte transfered
;       Y           0
;
; changes:
;       A, X, Y
;
; Returns with I-flag set (SEI).
;
; =============================================================================
recv_to_buffer:
        lda #<buffer
        ldx #>buffer
recv:
        sta buff_ptr
        stx buff_ptr + 1
recv_to_ptr:
        jsr drv_wait_rx         ; does SEI

        ; initialize recv code
        lda serport
        and #$60                ; <= needed?
        asl
        eor serport
        and #$e0
        sta eor_correction

        lda #0                  ; release CLK
        sta serport

; =============================================================================
.if eload_use_fast_tx = 0

@next_byte:
        lda #$08                ; CLK low to signal that we're receiving
        sta serport

        lda #$01
:
        bit serport             ; wait for DATA low
        bmi exit_1
        beq :-

        sei

        lda #0                  ; release CLK
        sta serport

        lda #$01
:
        bit serport             ; wait for DATA high
        bne :-                  ; t = 3..9

        nop
        nop                     ;  7..
        lda serport             ; 11..17    get bits 7 and 5

        asl
        nop
        nop                     ; 17..
        eor serport             ; 21..27    get bits 6 and 4

        asl
        asl
        asl                     ; 27..
        nop
        nop
        nop                     ; 33..
        eor serport             ; 37..43    get bits 3 and 1

        asl
        eor eor_correction      ; 43..      not on zeropage (abs addressing)
        eor serport             ; 47..53    get bits 2 and 0

        dey
        sta (buff_ptr), y
        bne @next_byte

        rts
; =============================================================================
.else ; eload_use_fast_tx
;                                                    .
; bit pair timing           11111111112222222222333333333344444444445555555555
; (us)            012345678901234567890123456789012345678901234567890123456789
; PAL write       S       7         6         3          2           X
;                         5         4         1          0
; NTSC write      S       7         6         3        2           X
;                         5         4         1        0

; drive read       ssssss    777777    666666    333333    222222

@next_byte:
        lda #$01                ; 54..
:
        bit serport             ;           wait for DATA high
        bne :-                  ; t = 3..9

        nop
        nop                     ;  7..
        lda serport             ; 11..17    get bits 7 and 5

        asl
        nop
        nop                     ; 17..
        eor serport             ; 21..27    get bits 6 and 4

        asl
        asl
        asl                     ; 27..
        eor serport             ; 31..37    get bits 3 and 1

        asl
        eor eor_correction      ; 37..      not on zeropage (abs addressing)
        eor serport             ; 41..47    get bits 2 and 0

        dey                     ; 43..
        sta (buff_ptr), y       ; 49..

        bne @next_byte          ; 52*..
        rts
.endif
