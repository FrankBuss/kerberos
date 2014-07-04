
.include "eload_macros.s"

.importzp       sp, sreg, regsave
.importzp       ptr1, ptr2, ptr3, ptr4
.importzp       tmp1, tmp2, tmp3, tmp4

.import         popax

.import eload_send_nodma
.import eload_send_job_nodma
.import eload_upload_drive_overlay

gcr_overflow_size = 69


; =============================================================================
;
; void __fastcall__ eload_write_sector(unsigned ts, uint8_t* block);
;
; This function saves the IRQ flag, uses SEI, and restores the IRQ flag.
;
; =============================================================================
.export _eload_write_sector_nodma
_eload_write_sector_nodma:
        sta block_tmp
        stx block_tmp + 1       ; Save buffer

        jsr popax
        stx n_track
        sta n_sector

        php                     ; to backup the interrupt flag
        sei

        lda #ELOAD_OVERLAY_WRITE
        jsr eload_upload_drive_overlay

        lda #1                  ; command: write sector
        sta job
        lda #<job
        ldx #>job
        jsr eload_send_job_nodma

        ; this will go to the GCR overflow buffer $1bb
        lda block_tmp
        ldx block_tmp + 1
        ldy #gcr_overflow_size
        jsr eload_send_nodma

        ; this will go to the main buffer
        ldx block_tmp + 1
        clc
        lda block_tmp
        adc #gcr_overflow_size
        bcc :+
        inx
:
        iny                     ; Y = 0xff => 0 = 256 bytes
        jsr eload_send_nodma

        plp                     ; to restore the interrupt flag
        rts

.data
; keep the order of these bytes
job:
        .byte 2                 ; command: write sector
n_track:
        .byte 1                 ; track
n_sector:
        .byte 0                 ; sector

.bss
block_tmp:
        .res 2
