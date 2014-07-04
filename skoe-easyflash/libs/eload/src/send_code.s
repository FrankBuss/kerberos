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
.include "drivetype.s"
.include "eload_macros.s"

.importzp       ptr1, ptr2, ptr3, ptr4
.importzp       tmp1, tmp2, tmp3, tmp4

.import eload_dos_open_listen_cmd
.import eload_dos_send_data
.import eload_dos_unlisten_close


.export _eload_prepare_drive

.import drive_detect
.import eload_send
.import eload_send_job

.import drv_start

.import drive_code_1541
;.import drive_code_1571
;.import drive_code_1581
.import drive_code_sd2iec

.import drive_code_init_size_1541
.import drive_code_init_size_sd2iec

.import drive_code_1541_write

.import drive_code_1541_format


code_ptr        = ptr1
code_len        = ptr2
table_ptr       = ptr3

cmdbytes        = 32   ; number of bytes in one M-W command


.bss

.export eload_dev
eload_dev:
        .res 1

drivetype:
        .res 1
cmd_addr:
        .res 2
cmd_len:
        .res 1

current_drv_overlay:
        .res 1

.rodata

str_mw:
        .byte "m-w"
str_mw_len = * - str_mw

str_me:
        .byte "m-e"
        .word $0300
str_me_len = * - str_me

drive_codes:
        .addr 0
        .addr 0
        .addr drive_code_1541
        .addr drive_code_1541           ; 1570
        .addr drive_code_1541           ; for now
        .addr 0; drive_code_1581
        .addr 0
        .addr 0
        .addr drive_code_sd2iec         ; sd2iec
        .addr 0

drive_code_init_sizes:
        .byte 0
        .byte 0
        .byte <drive_code_init_size_1541
        .byte <drive_code_init_size_1541     ; 1570
        .byte <drive_code_init_size_1541     ; for now
        .byte 0 ;<drive_code_size_1581
        .byte 0
        .byte 0
        .byte <drive_code_init_size_sd2iec   ; sd2iec
        .byte 0

overlay_code_to_tab:
        .addr 0 ; read
        .addr drive_codes_write
        .addr drive_codes_format

drive_codes_write:
        .addr 0
        .addr 0
        .addr drive_code_1541_write
        .addr drive_code_1541_write     ; 1570
        .addr drive_code_1541_write     ; for now
        .addr 0; drive_code_1581
        .addr 0
        .addr 0
        .addr 0
        .addr 0

drive_codes_format:
        .addr 0
        .addr 0
        .addr drive_code_1541_format
        .addr drive_code_1541_format    ; 1570
        .addr drive_code_1541_format    ; for now
        .addr 0; drive_code_1581
        .addr 0
        .addr 0
        .addr 0
        .addr 0

.code

; =============================================================================
;
; Refer to eload.h for documentation.
;
; int __fastcall__ eload_set_drive_check_fastload(uint8_t dev);
;
; parameters:
;       drive number in A (X is ignored)
;
; return:
;       drive type in AX (A = low)
;
; =============================================================================
.export _eload_set_drive_check_fastload
_eload_set_drive_check_fastload:
        sta eload_dev
        jsr drive_detect
        sta drivetype
        ldx #0
        rts

.if 0
; =============================================================================
;
; Refer to eload.h for documentation.
;
; void __fastcall__ eload_set_drive_disable_fastload(uint8_t dev);
;
; parameters:
;       drive number in A (X is ignored)
;
; return:
;       -
;
; =============================================================================
.export _eload_set_drive_disable_fastload
_eload_set_drive_disable_fastload:
        sta eload_dev
        lda #drivetype_unknown
        sta drivetype
        rts
.endif

; =============================================================================
;
; Refer to eload.h for documentation.
;
; int eload_drive_is_fast(void);
;
; Return:
;       Result in AX.
;       0       Drive not accelerated (eload uses Kernal calls)
;       >0      Drive has a fast loader
;       Zero flag is set according to the result.
;
; Changes:
;       A, X, flags
;
; =============================================================================
.export _eload_drive_is_fast
_eload_drive_is_fast:
        ldx drivetype
        lda drive_codes + 1,x
        tax
        rts

; =============================================================================
;
; Upload the drive code if this drive is supported.
;
; This function uses KERNAL code, it calls SEI/CLI as usual.
;
; Return:
;       C clear if the drive code has been uploaded
;       C set if the drive is not supported (i.e. must use Kernal)
;
; =============================================================================
.export _eload_prepare_drive
_eload_prepare_drive:
        lda #ELOAD_OVERLAY_NONE
        sta current_drv_overlay
        lda #<drive_codes
        ldx #>drive_codes
        jsr set_code_ptr
        lda #<$0300                     ; where to upload the code to
        sta cmd_addr
        lda #>$0300
        sta cmd_addr + 1

        jsr send_code_slow              ; send initial drive code with KERNAL

        ; Send M-E $0300
        jsr eload_dos_open_listen_cmd
        ; bcs error -- error handling?
        lda #str_me_len
        ldx #<str_me
        ldy #>str_me
        jsr eload_dos_send_data
        jsr UNLSN

        ldy #10                 ; delay
:       dex
        bne :-
        dey
        bne :-
        ; End Send M-E $0300

        ; no final drive code needed for sd2iec
        lda drivetype
        cmp #drivetype_sd2iec
        beq @no_drive_code

        ; upload 2 blocks of drive code using the fast protocol
        lda #<drive_codes
        ldx #>drive_codes
        sei
        jsr set_ptr_and_upload
        cli

@no_drive_code:
        clc
        rts

; =============================================================================
;
; Set code_ptr according to the current drive type to the start address
; of the drive code. Additionally code_init_size is written to code_len,
; which may not by needed by all callers, but who cares...
;
; Parameters:
;       AX      points to the drive code table to be used
;
; =============================================================================
set_code_ptr:
        sta table_ptr
        stx table_ptr + 1
        lda drivetype
        asl
        tay
        lda drive_code_init_sizes, y
        sta code_len
        lda (table_ptr), y          ; ptr to send_code for detected drive
        sta code_ptr
        iny
        lda (table_ptr), y
        sta code_ptr + 1
        rts

; =============================================================================
;
; Upload a new drive code overlay if a different one or none is running.
; If one is running already, exit it first by sending job $00.
; The caller must disable IRQs.
;
; Parameters:
;       A       one of ELOAD_OVERLAY_*
;
; =============================================================================
.export eload_upload_drive_overlay
eload_upload_drive_overlay:
        cmp current_drv_overlay         ; this overlay is running already?
        beq no_upload
        ldx current_drv_overlay         ; no overlay code running?
        beq @noexit
        pha
        jsr eload_exit_drive_overlay
        pla
@noexit:
        sta current_drv_overlay
        asl
        tay
        lda overlay_code_to_tab - 1, y  ; high, index 0 unused
        tax
        lda overlay_code_to_tab - 2, y  ; low
set_ptr_and_upload:
        jsr set_code_ptr
        lda #2                          ; number of blocks to transfer
        sta tmp1
:
        lda code_ptr
        ldx code_ptr + 1
        ldy #0
        jsr eload_send
        inc code_ptr + 1
        dec tmp1
        bne :-
no_upload:
		rts

; =============================================================================
;
; Exit drive overlay code by sending job $00.
; The caller must disable IRQs.
;
; =============================================================================
.export eload_exit_drive_overlay
eload_exit_drive_overlay:
eload_zero_job = * + 1              ; three remaining bytes don't matter
        lda #0
        sta current_drv_overlay
		lda #<eload_zero_job
        ldx #>eload_zero_job
        jmp eload_send_job

; =============================================================================
;
; Send code, 32 bytes at a time.
; This function uses KERNAL code, it calls SEI/CLI as usual.
;
; =============================================================================
send_code_slow:
@next:
        lda #cmdbytes       ; at least 32 bytes left?
        sta cmd_len
        lda code_len
        cmp #cmdbytes
        bcs @send
        beq @done
        sta cmd_len         ; no, just send the rest
@send:
        jsr eload_dos_open_listen_cmd
        bcs @done

        lda #str_mw_len
        ldx #<str_mw
        ldy #>str_mw
        jsr eload_dos_send_data

        lda #3
        ldx #<cmd_addr
        ldy #>cmd_addr
        jsr eload_dos_send_data

        lda cmd_len
        ldx code_ptr
        ldy code_ptr + 1
        jsr eload_dos_send_data
        jsr UNLSN

        lda cmd_addr
        ldx cmd_addr + 1
        jsr addlen
        sta cmd_addr
        stx cmd_addr + 1

        lda code_ptr
        ldx code_ptr + 1
        jsr addlen
        sta code_ptr
        stx code_ptr + 1

        lda code_len
        sec
        sbc cmd_len
        sta code_len
        bne @next
@done:
        rts


addlen:
        clc
        adc #cmdbytes
        bcc :+
        inx
:
        rts
