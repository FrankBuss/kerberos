
.export __STARTUP__ : absolute = 1      ; Mark as startup
.import __RAM_START__, __RAM_SIZE__     ; Linker generated

.import _usbrx

.include "zeropage.inc"
.include "c64.inc"

EASYFLASH_BANK    = $DE00
EASYFLASH_CONTROL = $DE02
EASYFLASH_LED     = $80
EASYFLASH_16K     = $07
EASYFLASH_KILL    = $04

ZPSPACE           = 26

; =============================================================================
; JMP table
; =============================================================================
.segment "JMP_CODE"
        jmp check_usb_input

; =============================================================================
; =============================================================================
.code


; =============================================================================
check_usb_input:
        jsr c_entry
        jsr _usbrx
        jmp c_exit

; =============================================================================
; prepare everything needed to enter C code
; =============================================================================
c_entry:
        ; Set argument stack ptr
        lda #<(__RAM_START__ + __RAM_SIZE__)
        sta sp
        lda #>(__RAM_START__ + __RAM_SIZE__)
        sta sp + 1

        ldx #zpspace - 1
@L1:
        lda sp, x
        sta zpsave, x    ; Save the zero page locations we need
        dex
        bpl @L1
        rts

c_exit:
        ldx #zpspace - 1
@L1:
        lda zpsave, x    ; Restore the zero page locations we need
        sta sp, x
        dex
        bpl @L1
        rts

.segment "ZPSAVE"

zpsave:
        .res ZPSPACE

.code

; =============================================================================
;
; =============================================================================
irq_ret:
        rti

; =============================================================================
; Common code on all KERNAL banks
; =============================================================================
.segment "KERNAL_COMMON"
.include "kernal_common.s"

; these vectors are not used usually as this is the KERNAL bank 1
.segment "VECTORS"
.word   irq_ret
.word   irq_ret ; <= arrrgh!
.word   irq_ret
