 ;
 ; ELoad
 ;
 ; (c) 2011 Thomas Giesel
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

.include "eload_macros.s"
.include "config.s"
.include "drive_1541_inc.s"

; =============================================================================
;
; Drive code assembled to fixed address $0600 follows
;
; =============================================================================
.org $0600
.export drive_code_1541_read_start
drive_code_1541_read_start      = *

; sector read subroutine. Returns clc if successful, sec if error
; X/A = T/S
drv_readsector:
        ldy #$80                ; read sector job code
        jsr set_job_ts_backup

        ldy #retries            ; retry counter
@retry:
        jsr restore_orig_job
        jsr exec_current_job
        bcc @ret
        dey                     ; decrease retry counter
        bne @retry
@ret:
        rts                     ; C = error state, A = error code

; =============================================================================
;
; load file
; args: start track, start sector
; returns: $00 for EOF, $ff for error, $01-$fe for each data block
;
; =============================================================================
load:
        ldx prev_file_track
        lda prev_file_sect
loadchain:
@sendsector:
        jsr drv_readsector
        bcc :+
        lda #$ff                ; send read error
        jmp error
:
        ldx #254                ; send 254 bytes (full sector)
        lda buffer              ; last sector?
        bne :+
        ldx buffer + 1          ; send number of bytes in sector (1-254)
        dex
:
        stx @buflen
        txa
        jsr drv_send           ; send byte count

        ldx #0                  ; send data
@send:
        txa
        pha
        lda buffer + 2,x
        jsr drv_send
        pla
        tax
        inx
@buflen = * + 1
        cpx #$ff
        bne @send

        ; load next t/s in chain into x/a or exit loop if EOF
        ldx buffer
        beq @done
        lda buffer + 1
        jmp @sendsector
@done:
        lda #0
        jmp senddone

drive_code_1541_read_size  = * - drive_code_1541_read_start
.assert drive_code_1541_read_size <= 256, error, "drive_code_1541_read_size"
.reloc
