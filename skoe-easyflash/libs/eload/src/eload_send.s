
.importzp   tmp3, ptr3
.import     sendtab
.import     sendtab75, sendtab64, sendtab31, sendtab20


.include "config.s"

; =============================================================================
;
; Like eload_send, but always 4 bytes.
;
; Used internally only.
;
; =============================================================================
.export  eload_send_job
eload_send_job:
        ldy #4
        ; fall through

; =============================================================================
;
; Send up to 256 bytes to the drive over the fast protocol. The last byte is
; sent first.
;
; This function does not use SEI/CLI, the caller must care for it.
;
; Used internally only.
;
; parameters:
;       AX  pointer to data
;       Y   number of bytes (1 for 256=0)
;
; return:
;       Y   #$ff
;
; changes:
;   A, X, Y
;
; =============================================================================
        ; fall through from eload_send_job
.export  eload_send
eload_send:
        sta ptr3
        stx ptr3 + 1

        lda $dd00
        sta tmp3
        and #7
        sta $dd00
        eor #$07
        ora #$38
        sta $dd02
; =============================================================================
.if eload_use_fast_tx = 0

        dey
@next_byte:
        lda (ptr3), y

@waitdrv:
        bit $dd00       ; wait for drive to signal ready to receive
        bvs @waitdrv    ; with CLK low

        ldx #$20        ; pull DATA low to acknowledge
        stx $dd00

        pha
        lsr
        lsr
        lsr
        lsr
        tax

@wait2:
        bit $dd00       ; wait for drive to release CLK
        bvc @wait2

@waitbadline:
        lda $d011       ; wait until a badline won't screw up
        clc             ; the timing
        sbc $d012
        and #7
        beq @waitbadline
@nobadline:
        nop             ; <= NOP makes sure the code below is after the bad line

        lda #$00        ; release DATA to signal that data is coming
        sta $dd00

        lda sendtab,x   ; 4
        sta $dd00       ; 8     send bits 7 and 5

        lsr             ; 10
        lsr             ; 12
        and #%00110000  ; 14
        sta $dd00       ; 18    send bits 6 and 4

        pla             ; 22    get the next nibble
        and #$0f        ; 24
        tax             ; 26
        lda sendtab,x   ; 30
        sta $dd00       ; 34    send bits 3 and 1

        lsr             ; 36
        lsr             ; 38
        and #%00110000  ; 40
        sta $dd00       ; 44    send bits 2 and 0

        dey             ; 46
        ldx #$3f        ; 48
        lda tmp3        ; 51
        cpy #$ff        ; 53
        sta $dd00       ; 57    restore $dd00 and $dd02

        bne @next_byte  ;       Z from cpy

        stx $dd02
        rts
; =============================================================================
.else ; eload_use_fast_tx

@waitdrv:
        bit $dd00       ; wait for drive to signal ready to receive
        bvs @waitdrv    ; with CLK low

        ldx #$20        ; pull DATA low
        stx $dd00
@wait2:
        bit $dd00       ; wait for drive to release CLK
        bvc @wait2

        dey
@next_byte:
        lda (ptr3), y   ; 58..59
        tax             ; 60..61

@waitbadline:
        lda $d011       ; wait until a badline won't screw up
        clc             ; the timing
        sbc $d012
        and #7
        beq @waitbadline
@nobadline:
        nop             ; <= NOP makes sure the code below is after the bad line

        lda #$00        ;
        sta $dd00       ; 0     release DATA to signal that data is coming

        lda sendtab75,x ; 4
        sta $dd00       ; 8     send bits 7 and 5

        nop             ; 10
        lda sendtab64,x ; 14
        sta $dd00       ; 18    send bits 6 and 4

        nop             ; 20
        lda sendtab31,x ; 24
        sta $dd00       ; 28    send bits 3 and 1

        nop             ; 30
        lda sendtab20,x ; 34
        sta $dd00       ; 38    send bits 2 and 0

        dey             ; 40
        ldx #$3f        ; 42    (for $dd02 below)
        lda #$20        ; 44
        cpy #$ff        ; 46
        sta $dd00       ; 50    pull DATA low

        bne @next_byte  ; 53*   from cpy

        lda tmp3
        sta $dd00       ;       restore $dd00, $dd02
        stx $dd02
        rts
.endif
