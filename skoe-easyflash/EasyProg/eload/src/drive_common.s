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

.import drv_get_start_ts
.import drv_readsector
.import drv_send
.import drv_recv

drivebuffer     = $0600


.export drive_code_common_start
drive_code_common_start:

; =============================================================================
;
; Drive code assembled to fixed address $0400 follows
;
; =============================================================================
.org $0400

.export drive_common_start
drive_common_start:

; =============================================================================
;
; load file
; args: start track, start sector
; returns: $00 for EOF, $ff for error, $01-$fe for each data block
;
; =============================================================================
load:
        jsr drv_get_start_ts
loadchain:
@sendsector:
        jsr drv_readsector
        bcc :+
        lda #$ff                ; send read error
        jmp error
:
        ldx #254                ; send 254 bytes (full sector)
        lda drivebuffer         ; last sector?
        bne :+
        ldx drivebuffer + 1     ; send number of bytes in sector (1-254)
        dex
:
        stx @buflen
        txa
        jsr drv_send           ; send byte count

        ldx #0                  ; send data
@send:
        txa
        pha
        lda drivebuffer + 2,x
        jsr drv_send
        pla
        tax
        inx
@buflen = * + 1
        cpx #$ff
        bne @send

        ; load next t/s in chain into x/a or exit loop if EOF
        ldx drivebuffer
        beq @done
        lda drivebuffer + 1
        jmp @sendsector
@done:
        lda #0
        jmp senddone

; =============================================================================
;
; =============================================================================
.export drv_main
drv_main:
        cli                     ; allow IRQs when waiting
        jsr drv_recv            ; get command byte, exit if ATN goes low

        cmp #1                  ; load a file
        beq load

        lda #$ff                ; unknown command
senddone:
error:
        jsr drv_send
        jmp drv_main

; =============================================================================
;
; Used in all versions of the send function
;
; =============================================================================
.export drv_sendtbl
drv_sendtbl:
        ; 0 0 0 0 b0 b2 b1 b3
        .byte $0f, $07, $0d, $05
        .byte $0b, $03, $09, $01
        .byte $0e, $06, $0c, $04
        .byte $0a, $02, $08, $00

.reloc

.export drive_code_common_end
drive_code_common_end:

.export drive_code_common_len
drive_code_common_len = drive_code_common_end - drive_code_common_start

.assert drive_code_common_len < 256, error, "drive_code_common too long"

