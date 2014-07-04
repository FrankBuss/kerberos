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

.include "kernal.s"

.importzp       sp, sreg, regsave
.importzp       tmp1, tmp2, tmp3
.importzp       ptr1

.import eload_dos_close
.import eload_set_read_byte_fn
.import eload_read_byte_from_buffer
.import eload_read_byte_kernal
.import eload_read_byte_fast
.import eload_buffered_byte



.import loader_upload_code


; loader_send and eload_recv are for communicating with the drive
.export loader_send

.rodata

        .align 16
sendtab:
        .byte $00, $80, $20, $a0
        .byte $40, $c0, $60, $e0
        .byte $10, $90, $30, $b0
        .byte $50, $d0, $70, $f0
sendtab_end:
        .assert >(sendtab_end - 1) = >sendtab, error, "sendtab mustn't cross page boundary"
        ; If you get this error, you linker config may need something like this:
        ; RODATA:   load = RAM, type = ro, align = $10;

.bss

; remaining number of bytes in this sector
.export eload_ctr
eload_ctr:
        .res 1

.code

; =============================================================================
;
; Open the file for read access.
;
; int __fastcall__ eload_open_read(const char* name);
;
; parameters:
;       pointer to name in AX (A = low)
;
; return:
;       result in AX (A = low), 0 = okay, -1 = error
;
; =============================================================================
        .export _eload_open_read
_eload_open_read:
        sta ptr1
        stx ptr1 + 1
        lda #0
        sta ST                  ; set status to OK
        lda $ba                 ; set drive to listen
        jsr LISTEN
        lda #$f0                ; open + secondary addr 0
        jsr SECOND

        ldy #0
@send_name:
        lda (ptr1),y            ; send file name
        beq @end_name           ; 0-termination
        jsr CIOUT
        iny
        bne @send_name          ; branch always (usually)
@end_name:
        jsr UNLSN

        ; give up if we couldn't even send the file name
        lda ST
        bne @fail

        ; Check if the file is readable
        lda $ba
        jsr TALK
        lda #$60                ; talk + secondary addr 0
        jsr TKSA
        jsr ACPTR               ; read a byte
        sta eload_buffered_byte       ; keep it for later
        jsr UNTLK

        lda ST
        bne @close_and_fail

        jsr loader_upload_code
        bcs @use_kernal

        lda #<eload_read_byte_fast
        ldx #>eload_read_byte_fast
        jsr eload_set_read_byte_fn

        ldx #0
@delay:
        dex
        bne @delay

        lda #1                  ; command: load
        jsr loader_send
        jsr eload_recv         ; status / number of bytes

        sta eload_ctr
        cmp #$ff
        beq @close_and_fail
        bne @ok

@use_kernal:
        ; no suitable speeder found, use Kernal
        lda #<eload_read_byte_from_buffer
        ldx #>eload_read_byte_from_buffer
        jsr eload_set_read_byte_fn

        ; send TALK so we can read the bytes afterwards
        lda $ba
        jsr TALK
        lda #$60
        jsr TKSA
@ok:
        lda #0
        tax
        rts

@close_and_fail:
        lda #0                  ; channel 0
        sta SA
        jsr eload_dos_close
@fail:
        lda #$ff
        tax
        rts


; send a byte to the drive
loader_send:
        sta tmp1
loader_send_do:
        sty tmp2

        pha
        lsr
        lsr
        lsr
        lsr
        tay

        lda $dd00
        and #7
        sta $dd00
        sta tmp3
        eor #$07
        ora #$38
        sta $dd02

@waitdrv:
        bit $dd00           ; wait for drive to signal ready to receive
        bvs @waitdrv        ; with CLK low

        lda $dd00       ; pull DATA low to acknowledge
        ora #$20
        sta $dd00

@wait2:
        bit $dd00       ; wait for drive to release CLK
        bvc @wait2

        sei

loader_send_waitbadline:
        lda $d011       ; wait until a badline won't screw up
        clc             ; the timing
        sbc $d012
        and #7
        beq loader_send_waitbadline
loader_send_nobadline:

        lda $dd00       ; release DATA to signal that data is coming
        ;ora #$20
        and #$df
        sta $dd00

        lda sendtab,y   ; 4
        sta $dd00       ; 8     send bits 7 and 5

        lsr             ; 10
        lsr             ; 12
        and #%00110000  ; 14
        sta $dd00       ; 18    send bits 6 and 4

        pla             ; 22    get the next nibble
        and #$0f        ; 24
        tay             ; 26
        lda sendtab,y   ; 30
        sta $dd00       ; 34    send bits 3 and 1

        lsr             ; 36
        lsr             ; 38
        and #%00110000  ; 40
        sta $dd00       ; 44    send bits 2 and 0

        nop             ; 46
        nop             ; 48
        lda tmp3        ; 51
        ldy #$3f        ; 53
        sta $dd00       ; 57    restore $dd00 and $dd02
        sty $dd02

        ldy tmp2
        lda tmp1

        cli
        rts


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
.export eload_recv
eload_recv:
        ; $dd00: | D_in | C_in | D_out | C_out || A_out | RS232 | VIC | VIC |
        ; Note about the timing: After 50 cycles a PAL C64 is about 1 cycle
        ; slower than the drive, an NTSC C64 is about 1 cycle faster. As we
        ; have a safety gap of about 2 us, this doesn't matter.

        ; Handshake Step 1: Drive signals byte ready with DATA low
@wait1:
        lda $dd00
        bmi @wait1

        sei

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
        sta @eor+1              ; 4

        nop
        nop
        nop
        nop
        nop                     ; 14

        ; receive bits
        lda $dd00               ; 18 - b0 b1
        lsr
        lsr
        eor $dd00               ; 26 - b2 b3
        lsr
        lsr
        eor $dd00               ; 34 - b4 b5
        lsr
        lsr
@eor:
        eor #$00
        eor $dd00               ; 44 - b6 b7
        cli
        rts

