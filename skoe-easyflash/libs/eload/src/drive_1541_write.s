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

.import drv_1541_prepare_read
.import drv_1541_restore_orig_job
.import drv_1541_recv_to_buffer
.import drv_1541_recv
.import drv_1541_send
.import drv_1541_search_header
.import drv_1541_wait_sync
.import drv_1541_move_head

.export drive_code_1541_write
drive_code_1541_write  = *

; =============================================================================
;
; Drive code assembled to fixed address $0500 follows
;
; =============================================================================
.org $0500
.export drive_code_1541_write_start
drive_code_1541_write_start      = *

loop:
        cli                     ; allow IRQs when waiting
        ldy #4                  ; receive job to buffer (does SEI when rx)
        jsr drv_1541_recv_to_buffer

        lda buffer + 1
        sta job_track_backup
        lda buffer + 2
        sta job_sector_backup

        ldx buffer              ; job
        dex
        beq write_sector
        dex
        bne :+
        jmp track_checksum
:
ret:
        rts                     ; leave overlay code

; =============================================================================
;
; Write a GCR sector to disk.
;
; =============================================================================
write_sector:
        ; receive 69 + 256 bytes of GCR encoded track
        ldy #gcr_overflow_size
        lda #<gcr_overflow_buff
        ldx #>gcr_overflow_buff
        jsr drv_1541_recv           ; 69 bytes
        jsr drv_1541_recv_to_buffer ; 256 bytes (Y = 0 from prev call)

        ; write
        jsr drv_1541_restore_orig_job

        lda $1c00                   ; read port B
        and #$10                    ; isolate bit for 'write protect'
        bne @wprot_ok
        lda #ELOAD_WRITE_PROTECTED
        sec
        bcs status_motor_off_ret
@wprot_ok:
        jsr drv_1541_prepare_read
        jsr drv_1541_search_header
        bcs status_motor_off_ret ; error: code in A already

        ldx #8                  ; skip last byte of header + 8 bytes gap
@skip9:
        wait_byte_ready
        dex
        bpl @skip9
                                ; the 9th byte gap is being read
                                ; while we change to write mode
        stx $1c03               ; data port output
        stx $1c01               ; write $ff = sync
        lda #$ce
        sta $1c0c               ; write mode

        ldy #5                  ; write 5 bytes sync
@wrsync:
        wait_byte_ready
        dey
        bne @wrsync

        ldy #$bb
@write_data_1:
        lda $0100, y
        sta $1c01               ; write data byte
        wait_byte_ready
        iny
        bne @write_data_1

@write_data_2:
        lda buffer, y
        sta $1c01               ; write data byte
        wait_byte_ready
        iny
        bne @write_data_2

        bvc *                   ; wait last byte ready
        lda #$ee                ; read mode
        sta $1c0c
        sty $1c03               ; port A (read/write head) to input

        clc                     ; mark for success
status_motor_off_ret:
        bcs :+                  ; C set == error
        lda #ELOAD_OK
:
        jsr send_status
motor_off_and_ret:
        jsr $f98f               ; prepare motor off (doesn't change C)
        lda $1c00
        and #$f7                ; LED off
        sta $1c00
        jmp loop

send_status:
        ; send the return value from A and two bytes of status
        jsr drv_1541_send
        lda job_track
        jsr drv_1541_send
        lda job_sector + 1
        jmp drv_1541_send

; =============================================================================
;
;
; =============================================================================
track_checksum:
        jsr drv_1541_restore_orig_job
        jsr drv_1541_prepare_read
        lda job_track
        cmp #1
        bne @move_head_only     ; for all tracks except #1
        jsr drv_1541_search_header
@move_head_only:
        jsr drv_1541_move_head
        lda $43                 ; sectors per track
        sta job_sector          ; counter

        ldy #0
        sty buff_ptr            ; used as index to buffer $0700
@next_sector:
        ldx #2                  ; retry counter, may find a data block first
@retry_header:
        jsr drv_1541_wait_sync
        bcs error
@check_header:
        wait_byte_ready
        lda $1c01               ; read data from head
        cmp #$52                ; Is it a header?
        beq @header_found
        dex
        bne @retry_header
        beq @no_header
@header_found:
        ldy buff_ptr
        sta buffer, y
        iny
        ldx #9                  ; 9 GCR bytes left
@copy_header:
        wait_byte_ready
        lda $1c01               ; read data from head
        sta buffer, y
        iny
        dex
        bne @copy_header
        sty buff_ptr

        ; === Wait for data block and calculate its checksum ===
        jsr checksum16

        dec job_sector
        bne @next_sector

        ; fertig!
        ; send status
        lda #ELOAD_OK
        jsr send_status
        ; send data block, always 256 bytes
        ldx #0
@send_buffer:
        lda buffer, x
        jsr drv_1541_send
        inx
        bne @send_buffer

        jmp motor_off_and_ret

@no_header:
        lda #ELOAD_HEADER_NOT_FOUND
        sec
error:
        jmp status_motor_off_ret

; Depending from the bit rate we have 26 to 32 cycles per byte,
; so our loop must take less then 26 cycles.
checksum16:
        ldx #65         ; 325 / 5 = 65 => speed code
        lda #0
        sta zptmp       ; high byte = 0

        jsr drv_1541_wait_sync
        bcs error

        ; y is 0 after drv_1541_wait_sync => init high byte
        ; c is clear on success, addition prepared

        tya             ; low byte = 0
@check:
        bvc @check
@read:
.repeat 5
        eor $1c01       ;   4    4      low ^= data
        clv             ;   2    6
        inc zptmp       ;   5   11      high++
        rol zptmp       ;   5   16      carry << high << carry
        rol             ;   2   18      carry << low << carry
:
        bvs :+          ;   3   21
        bvs :+
        bvs :+
        bvs :+
        jmp :-
:
.endrepeat

        dex
        bne @read

.assert >checksum16 = >*, error, "page boundary crossed"
        ldx buff_ptr
        sta buffer, x
        inx
        lda zptmp       ; high
        sta buffer, x
        inx
        stx buff_ptr
        rts



drive_code_1541_write_size  = * - drive_code_1541_write_start
.assert drive_code_1541_write_size <= 512, error, "drive_code_1541_write_size"
.reloc
