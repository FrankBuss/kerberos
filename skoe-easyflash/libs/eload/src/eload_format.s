
.include "eload_macros.s"

.importzp       sp, sreg, regsave
.importzp       ptr1, ptr2, ptr3, ptr4
.importzp       tmp1, tmp2, tmp3, tmp4

.import         popa

.import eload_send_job
.import eload_upload_drive_overlay

gcr_overflow_size = 69


; =============================================================================
;
; void __fastcall__ eload_format(uint8_t n_tracks, uint16_t id);
;
; This function saves the IRQ flag, uses SEI, and restores the IRQ flag.
;
; =============================================================================
.export _eload_format
_eload_format:
        sta id1
        stx id2

        jsr popa
        sta n_tracks

        php                     ; to backup the interrupt flag
        sei

        lda #ELOAD_OVERLAY_FORMAT
        jsr eload_upload_drive_overlay

        lda #<job
        ldx #>job
        jsr eload_send_job

        plp                     ; to restore the interrupt flag
        rts

.data
; keep the order of these bytes
job:
        .byte 1                 ; command: format
n_tracks:
        .byte 1                 ; track
id1:
        .byte 0
id2:
        .byte 0
