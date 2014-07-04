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

.import drv_main
.import drive_code_common_len

.export drive_code_1541
drive_code_1541  = *

; =============================================================================
;
; Drive code assembled to fixed address $0300 follows
;
; =============================================================================
.org $0300

serport         = $1800

retries         = 5             ; number of retries when reading a sector

prev_file_track = $7e
prev_file_sect  = $026f

job3            = $03
trk3            = $0c
sct3            = $0d
zptmp           = $1b
stack           = $8b

iddrv0          = $12           ; disk drive id
id              = $16           ; disk id

drivebuffer     = $0600

.export drv_start
.export drv_send
.export drv_recv
.export drv_readsector
.export drv_exit
.export drv_get_start_ts

; jmp table must be same for other drives
drv_start:
        tsx
        stx stack
        jsr load_common_code
        jmp drv_main
drv_send:
        jmp send
drv_recv:
        jmp recv
drv_readsector:
        jmp readsector
drv_exit:
        jmp exit
drv_get_start_ts:
        ldx prev_file_track
        lda prev_file_sect
        rts

.include "xfer_drive_1mhz.s"

; sector read subroutine. Returns clc if successful, sec if error
; X/A = T/S
readsector:
        ldy #$80                ; read sector job code
        sty zptmp
        stx trk3
        sta sct3

        ldy #retries            ; retry counter
@retry:
        lda zptmp
        sta job3

        cli
@wait:
        lda job3
        bmi @wait

        sei

        cmp #2                  ; check status
        bcc @success

        lda id                  ; check for disk ID change
        sta iddrv0
        lda id + 1
        sta iddrv0 + 1

        dey                    ; decrease retry counter
        bne @retry
@failure:
        ;sec
        rts
@success:
        clc
        rts

; =============================================================================
;
; Release the IEC bus, restore SP and leave the loader code.
;
; =============================================================================
exit:
        lda #0                        ; release IEC bus
        sta serport
        ldx stack
        txs
        cli
        rts

.reloc

.export drive_code_size_1541
drive_code_size_1541  = * - drive_code_1541

.assert drive_code_size_1541 < 256, error, "drive_code_size_1541"
