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


.include "kernal.s"

.import eload_dev

.bss
dos_command:
        .res 1

.code

; =============================================================================
;
; Set SA to 15 (command channel) and call eload_dos_open.
;
; =============================================================================

.export eload_dos_open_listen_cmd
eload_dos_open_listen_cmd:
        lda #15
        sta SA
        ; fall through

; =============================================================================
;
; Send LISTEN to a drive and open the secondary address in SA.
; The caller can use CIOUT or eload_dos_send_data and finally jsr UNLSN and
; eload_dos_cmd_close. Note that for SA 15 no close is needed.
;
; parameters:
;       eload_dev   device number (FA)
;       SA          secondary address $00..$0f
;
; return:
;       C       flag set when an error occured
;
; changes:
;       A, X, Y
;
; =============================================================================
.export eload_dos_open_listen
eload_dos_open_listen:
        lda #0
        sta ST              ; reset error status
        lda #$60            ; open
        sta dos_command
send_listen_sa:
        lda eload_dev
        jsr LISTEN
        jsr check_err
        bcs ret_err
        lda SA
        ora dos_command
        jsr SECOND
        ; jmp check_err -- fall through


; =============================================================================
;
; Check ST for an error. If an error has occured, return with C set.
; Overwise with C clear.
;
; parameters:
;       -
;
; return:
;       C flag set when an error occured
;
; changes:
;       A
;
; =============================================================================
        ; note: fall through from eload_dos_open_listen
check_err:
        sec
        lda ST
        bmi ret_err
        clc
ret_err:
        rts


; =============================================================================
;
; Send data bytes using CIOUT. This can be a file name or a DOS command.
; eload_dos_cmd_open must have been called before.
;
; parameters:
;       A       number of bytes
;       XY      address of bytes (X = low)
;
; return:
;       C       flag set when an error occured
;
; changes:
;       A, Y, FNADR, FNLEN
;
; =============================================================================
.export eload_dos_send_data
eload_dos_send_data:
        jsr SETNAM
        ldy #0
@next:
        lda (FNADR), y
        jsr CIOUT
        jsr check_err
        bcs ret
        iny
        cpy FNLEN
        bne @next
        clc
ret:
        rts

; =============================================================================
;
; Send TALK to a drive and the secondary address SA.
; The caller must jsr UNTALK after he has read enough data.
;
; parameters:
;       eload_dev   device number (FA)
;       SA      secondary address $00..$0f
;
; return:
;       C       flag set when an error occured
;
; changes:
;       A, X, Y (probably)
;
; =============================================================================
.export eload_dos_send_talk
eload_dos_send_talk:
        lda eload_dev
        jsr TALK
        jsr check_err
        bcs ret
        lda SA
        ora #$60
        jmp TKSA


; =============================================================================
;
; Call UNLSN and eload_dos_close
;
; =============================================================================
.export eload_dos_unlisten_close
eload_dos_unlisten_close:
        jsr UNLSN
        ; fall through

; =============================================================================
;
; Close the secondary address in SA on a drive.
;
; parameters:
;       eload_dev   device number (FA)
;       SA      secondary address $00..$0f
;
; return:
;       C       flag set when an error occured
;
; changes:
;       A, X, Y
;
; =============================================================================
.export eload_dos_close
eload_dos_close:
        lda #$e0                ; close
        sta dos_command
        bne send_listen_sa      ; branch always
