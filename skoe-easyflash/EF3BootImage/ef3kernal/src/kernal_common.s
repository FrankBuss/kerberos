
; =============================================================================
; Common code on all KERNAL banks
;
; This code goes to $fec2 and is used on Bank 0 (acme) and all other banks
; (ca65). That's why the syntax has to use the common subset of both
; assemblers.
;
; =============================================================================

; I/O address to set the KERNAL bank
EASYFLASH3_IO_KERNAL_BANK   = $de0e

RAM_JSR_OP  = $dff0
RAM_JSR_LO  = $dff1
RAM_JSR_HI  = $dff2


; =============================================================================
; JSR to a subroutine on bank 0 and return to bank 1. The address to be JSRed
; to is at ram_jsr_lo/ram_jsr_hi. All registers are forwarded transparently.
; =============================================================================
bank1_jsr_to_bank0:
        pha
        lda #$4c                ; opcode of JMP
        sta RAM_JSR_OP
        lda #0
        sta EASYFLASH3_IO_KERNAL_BANK
        pla
        jsr $dff0
        pha
        lda #1
        sta EASYFLASH3_IO_KERNAL_BANK
        pla
        rts

; =============================================================================
; Same as bank1_jsr_to_bank0, but different banks
; =============================================================================
bank0_jsr_to_bank1_ax:
        sta RAM_JSR_LO
        stx RAM_JSR_HI
bank0_jsr_to_bank1:
        pha
        lda #$4c                ; opcode of JMP
        sta RAM_JSR_OP
        lda #1
        sta EASYFLASH3_IO_KERNAL_BANK
        pla
        jsr $dff0
        pha
        lda #0
        sta EASYFLASH3_IO_KERNAL_BANK
        pla
        rts
