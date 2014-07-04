
; Initialize TOD Clock by correctly determining the actual frequency
; by which the TOD is clocked.
; Supports PAL/NTSC with 50/60Hz TOD-Clock in ANY combination.
; based on code by Devia/Ancients 2009-02-13
; modifications by skoe 2010-01-24:
; - NMI initialisation removed
; - Use AND and ORA for control registers
; - Screen can (and must now) remain active
; - Restore IRQ flag on exit
; - Simplified code
; - Doesn't hang on systems which are DC powered

.include "c64.inc"

.importzp tmp1, tmp2, tmp3



; =============================================================================
.bss
currTime:
        .res 4
pauseTime:
        .res 4
timerRunning:
        .res 1

; =============================================================================
.code

; =============================================================================
;
; =============================================================================
.align 16
.export _timerInitTOD
_timerInitTOD:
        php
        sei

        lda $dc0e               ; Set TOD Clock Frequency to 60Hz
        and #$7f
        sta $dc0e
        lda $dc0f               ; Enable Set-TOD-Clock
        and #$7f
        sta $dc0f

        jsr _timerStart
        ldx #0
        stx timerRunning

        lda CIA1_TOD10
@sync:
        cmp CIA1_TOD10          ; Sync raster to TOD Clock Frequency
        beq @sync

        ;ldx #0                  ; Prep X and Y for 16 bit
        ldy #0                  ; counter operation
        lda CIA1_TOD10          ; Read deciseconds
@loop:
        dex                     ; 2
        bne @loop               ; 3/2 (5 * 256 + 13 = 1293)
@end_loop:
        .assert >(@end_loop) = >@loop, error, "loop mustn't cross page boundary"
        iny                     ; 2
        beq @keep60             ; 2 overrun: No TOD clock, e.g. DC power
        cmp CIA1_TOD10          ; 4 - Did 1 decisecond pass?
        beq @loop               ; 3 - If not, loop-di-doop
                                ; roughly 95000 cycles (depends from PAL/NTSC)
                                ; mean AC frequency is actually 60 Hz
                                ; roughly 115000 cycles mean it's 50 Hz
                                ; We use a threshold at 81 * 1293 = 104733
        sty $07f0
        cpy #81                 ; Did 104490 cycles or less go by?
        bcc @keep60             ; - Keep correct 60Hz $dc0e value
        lda $dc0e
        ora #$80                ; Otherwise, we need to set it to 50Hz
        sta $dc0e
@keep60:
        plp
        rts

; =============================================================================
;
; =============================================================================
.export _timerStart
_timerStart:
        lda #0
        ldx #3
        stx timerRunning
        ; must set all values from hours to ds to unfreeze the counters
@next:
        sta CIA1_TOD10, x
        dex
        bpl @next
        rts

; =============================================================================
;
; =============================================================================
.export _timerStop
_timerStop:
        lda #0
        sta timerRunning
timerCopyToCurr:
        lda #0
        ldx #3
        ; must read all values from hours to ds to unfreeze the counters
@next:
        lda CIA1_TOD10, x
        sta currTime, x
        dex
        bpl @next
        rts

; =============================================================================
;
; =============================================================================
.export _timerCont
_timerCont:
        ldx #3
        stx timerRunning
        ; must set all values from hours to ds to unfreeze the counters
@next:
        lda currTime, x
        sta CIA1_TOD10, x
        dex
        bpl @next
        rts

; =============================================================================
;
; Return the Minutes and Seconds elapsed so far.
;
; uint16_t timerGet(void);
;
; Return:
;       Result in AX (A = low = seconds, X = high = minutes)
;
; Changes:
;       A, X, flags
;
; =============================================================================
.export _timerGet
_timerGet:
        lda timerRunning
        beq @stopped
        jsr timerCopyToCurr
@stopped:
        lda currTime + 1        ; seconds
        jsr BCD2dec
        pha
        lda currTime + 2        ; minutes
        jsr BCD2dec
        tax
        pla
        rts

        ; dec = (((BCD>>4)*10) + (BCD&0xf))
BCD2dec:
        tax
        and     #%00001111
        sta     tmp1
        txa
        and     #%11110000      ; *16
        lsr                     ; *8
        sta     tmp2
        lsr
        lsr                     ; *2
        adc     tmp2            ; = *10
        adc     tmp1
        rts
