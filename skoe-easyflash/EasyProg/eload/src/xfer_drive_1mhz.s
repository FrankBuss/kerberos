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

.import drv_sendtbl
.import drive_common_start
.import drive_code_common_len

; =============================================================================
;
; =============================================================================
load_common_code:
        ldx #<drive_code_common_len
@next_byte:
        jsr recv
        sta drive_common_start - 1, x
        dex
        bne @next_byte
        rts


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
send:
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
        jmp exit

; =============================================================================
;
; =============================================================================
recv:
        lda #$08                ; CLK low to signal that we're receiving
        sta serport

        lda serport             ; get EOR mask for data
        asl
        eor serport
        and #$e0
        sta @eor

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
        cmp ($00,x)             ; 33..
        eor serport             ; 37..43    get bits 3 and 1

        asl
@eor = * + 1
        eor #$5e
        nop                     ; 43..
        eor serport             ; 47..53    get bits 2 and 0

        rts
