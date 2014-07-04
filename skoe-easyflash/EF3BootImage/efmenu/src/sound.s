;
; EasyFlash - text_plot_asm.s - Text Plotter
;
; (c) 2011 Thomas 'skoe' Giesel
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

; bit 0 = -66 dB
; bit 1 =

.include "c64.inc"

.import __FASTCODE_START__, __FASTCODE_SIZE__

.export _initNMI
_initNMI:
        ; copy code
        ldx #soundNMIEnd - soundNMIStart
@copyCode:
        lda soundNMIStart, x
        sta soundNMI, x
        dex
        bpl @copyCode

        lda #<soundNMI
        sta $fffa
        lda #>soundNMI
        sta $fffb

        lda #$1f
        sta SID_Amp

        lda #$0f
        sta SID_FltCtl

        lda #128
        sta SID_FltHi

        lda #$f0
        sta SID_SUR3

        lda #$7D        ; NMI every ... cycles
        sta $dd04
        lda #0
        sta $dd05

        lda #%10000001  ; enable timer A NMI
        sta $dd0d
        lda $dd0d

        sei

        lda #$01

stable_raster:
        ldx #248
@wait:
        cpx $d012
        bne @wait       ; +3..+9
        ; this loop has 63 or
@improve:
        ldy #8          ; 2
@delay:
        dey
        bpl @delay      ; 8 * 5 + 2 = 42

        inx             ; 2
        beq @synched    ; 2
        cpx $d012       ; 4
        bne @cycleplus  ; 2..3
@cycleplus:
        nop             ; 2
        nop             ; 2
        jmp @improve    ; 3

@synched:
end_stable_raster:

        sta $dd0e       ; start timer A
        cli

        ; KERNAL is in RAM already
        lda #$35
        sta $01

        rts

soundNMIStart:
.org $1d
;__FASTCODE_START__
soundNMI:
        pha
        lda $dd04
        lsr
        bcs :+          ; 2 vs. 3, dt = 1
:
        lsr
        bcc :+          ; 3 vs. 5, dt = 2
        bit $00
:
        lsr
        bcc :+          ; 3 vs. 7; dt = 4
        bit $00
        nop
:

        ;inc $d020

        lda #$11        ; Triangle + Gate
        sta SID_Ctl3
        lda #$09        ; Test + Gate
        sta SID_Ctl3

@addr = * + 1
        lda $8000
        sta SID_S3Hi

        lda #$01        ; No waveform + Gate
        sta SID_Ctl3

        inc @addr
        bne @nohi
        inc @addr + 1
        lda @addr + 1
        cmp #$a0
        bne @nohi
        lda #$80
        sta @addr + 1
@nohi:
        pla
        ;dec $d020
        bit $dd0d
        rti
.reloc
soundNMIEnd:
