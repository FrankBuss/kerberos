
.include "eload_macros.s"

.importzp       sp, sreg, regsave
.importzp       ptr1, ptr2, ptr3, ptr4
.importzp       tmp1, tmp2, tmp3, tmp4

.import         popa

.import eload_send_job
.import eload_upload_drive_overlay


; =============================================================================
;
; void __fastcall__ eload_checksum(uint8_t n_track);
;
; This function saves the IRQ flag, uses SEI, and restores the IRQ flag.
;
; =============================================================================
.export _eload_checksum
_eload_checksum:
        sta n_track

        php                     ; to backup the interrupt flag
        sei

        lda #ELOAD_OVERLAY_WRITE
        jsr eload_upload_drive_overlay

        lda #<job
        ldx #>job
        jsr eload_send_job

        plp                     ; to restore the interrupt flag
        rts

.data

job:
        .byte 2                 ; command: checksum
n_track:
        .byte 1                 ; track
n_sector:
        .byte 0                 ; sector, always 0
flags:
        .byte 0
