
* = $e000

USB_ID     = $de08
USB_STATUS = $de09
USB_DATA   = $de0a

bank1_check_usb_input   = $e000

; include original KERNAL image
!bin "src/kernal.bin"

; =============================================================================
; Overrite startup message
; =============================================================================
;* = $e47e
;        !text "EASYFLASH 3 "

; =============================================================================
; No memory test on startup
; =============================================================================
* = $fd50
        ; $fd50 Init Memory Subst by tlr
        ; (to avoid the slow memory test, and avoid trashing one byte at $a000)
;        lda #0
;        tay
;-
;        sta !$0002, y
;        sta $0200, y
;        sta $0300, y
;        iny
;        bne -

;        ldx #$03
;        lda #$3c
;        sta $b2
;        stx $b3

;        ldx #$00
;        ldy #$a0
;        jmp $fd8c       ; Set MemBounds, original code
        ; end $fd50 subst

        ; note: between here and $fd8c is free space

;        !if * > $fd8c {
;            !serious "Code too large"
;        }

; =============================================================================
; Patch for USB scan in keyboard scan
; =============================================================================
* = $ea87 ; keyboard scan

        ; EA87: A9 00     LDA #$00
        ; EA89: 8D 8D 02  STA $028D     ; Flag: Shift Keys
        jmp ef3_usb_scan
        nop
        nop
keyboard_scan_cont:

        !if * > $ea8c {
            !serious "Code too large"
        }

; =============================================================================
; USB scan
; =============================================================================
* = $e4b7   ;   Unused Bytes For Future Patches

ef3_usb_scan:
        bit USB_STATUS
        bpl no_usb

        lda #<bank1_check_usb_input
        ldx #>bank1_check_usb_input
        jsr bank0_jsr_to_bank1_ax       ; test KERNAL banking
no_usb:
        lda #$00
        sta $028d                       ; from original keyboard scan code
        jmp keyboard_scan_cont

        !if * > $e4d0 {
            !serious "Code too large"
        }

; =============================================================================
; Common code on all KERNAL banks
; =============================================================================
* = $fec2
        !src "src/kernal_common.s"
        !if * > $ff43 {
            !serious "Code too large"
        }

; $e430 3
; $e44f 2
; $e460 80
; $e491 2
; $e4b7 27
; $eebb 489
; $f409 24
; $f422 23
; $f43a 61
; $fec2 109
; $ff30 15
