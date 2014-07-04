
* = $8000
crtStart:

!convtab scr

ram_code_start = $0800

; =============================================================================
; header

; cold start vector => our program
!word coldStart

; warm start => $febc => exit interrupt
; fixme: something wrong with this, it crashes on <Restore>
!word $febc

; magic string
!byte $c3, $c2, $cd, $38, $30

; =============================================================================
; program

coldStart:
        sei
        ldx #$ff
        txs
        cld

        ; enable VIC (e.g. RAM refresh)
        lda #8
        sta $d016

        ; write to RAM to make sure it starts up correctly (=> RAM datasheets)
startWait:
        sta $0100, x
        dex
        bne startWait

        ; same init stuff the kernel calls after reset
        ldx #0
        stx $d016
        jsr $ff84   ; Initialise I/O
        jsr $ff87   ; Initialise System Constants
        jsr $ff8a   ; Restore Kernal Vectors
        jsr $ff81   ; Initialize screen editor

        ; copy the final start-up code to RAM (bottom of CPU stack)
        ldx #0
l1:
        lda start_up_code, x
        sta ram_code_start, x
        lda start_up_code + $100, x
        sta ram_code_start + $100, x
        dex
        bne l1
        jmp ram_code_start

start_up_code:
        !pseudopc ram_code_start {
            ; Init C64 RAM
            lda #$30
            sta $01
            lda #'8'
            ldx #$80
            jsr fill8k

            lda #'a'
            ldx #$a0
            jsr fill8k

            lda #'d'
            ldx #$d0
            jsr fill8k

            lda #'e'
            ldx #$e0
            jsr fill8k
            lda #$37
            sta $01

            ; 1. line - state after reset
            lda #<($0400)
            ldx #>($0400)
            jsr print_line

            ; fill RAM (if there is RAM) with 'p'/'q'
            lda #'p'
            ldx #$80
            jsr fill8k
            lda #'q'
            ldx #$a0
            jsr fill8k

            ; 2. line
            lda #<($0400 + 40)
            ldx #>($0400 + 40)
            jsr print_line

            ; 3. line - $de00 = #$22
            lda #$22
            sta $de00
            lda #<($0400 + 2 * 40)
            ldx #>($0400 + 2 * 40)
            jsr print_line

            ; fill RAM (if there is RAM) with 'r'/'s'
            lda #'r'
            ldx #$80
            jsr fill8k
            lda #'s'
            ldx #$a0
            jsr fill8k

            ; 4. line
            lda #<($0400 + 3 * 40)
            ldx #>($0400 + 3 * 40)
            jsr print_line

            ; 5. line - $de00 = #$00
            lda #$00
            sta $de00
            lda #<($0400 + 4 * 40)
            ldx #>($0400 + 4 * 40)
            jsr print_line

            ; fill RAM (if there is RAM) with 't'/'u'
            lda #'t'
            ldx #$80
            jsr fill8k
            lda #'u'
            ldx #$a0
            jsr fill8k

            ; 6. line
            lda #<($0400 + 5 * 40)
            ldx #>($0400 + 5 * 40)
            jsr print_line

            ; 7. line - $de00 = #$20
            lda #$20
            sta $de00
            lda #<($0400 + 6 * 40)
            ldx #>($0400 + 6 * 40)
            jsr print_line

            ; 8. line - $de00 = #$28 (bank 1)
            lda #$28
            sta $de00
            lda #<($0400 + 7 * 40)
            ldx #>($0400 + 7 * 40)
            jsr print_line

            ; 9. line - $de00 = #$08 (bank 1)
            lda #$08
            sta $de00
            lda #<($0400 + 8 * 40)
            ldx #>($0400 + 8 * 40)
            jsr print_line

            ; 10. line - $de00 = #$2a (bank 1)
            lda #$2a
            sta $de00
            lda #<($0400 + 8 * 40)
            ldx #>($0400 + 8 * 40)
            jsr print_line

here:
            dec $d020
            jmp here

fill8k:
            stx fill8k_hi
            ldx #0
            ldy #32
fill8k_loop:
fill8k_hi = * + 2
            sta $8000, x
            dex
            bne fill8k_loop
            inc fill8k_hi
            dey
            bne fill8k_loop
            rts

print_line:
            sta $02
            stx $03

            ; IO2
            ldy #0
            lda $df00
            sta ($02), y
            lda $dfff
            iny
            sta ($02), y

            ; ROML
            ldy #4
            lda $8400
            sta ($02), y
            lda $9c00
            iny
            sta ($02), y

            ; ROMH
            ldy #8
            lda $a400
            sta ($02), y
            lda $bc00
            iny
            sta ($02), y
            rts
        }
start_up_end:

; =============================================================================
; fill it up to 8k (Bank 0)
!fill ($2000 - (* - crtStart)), 'a'

; =============================================================================
; 8k Bank 1
!fill $2000, 'b'

; =============================================================================
; 8k Bank 2
!fill $2000, 'c'

; =============================================================================
; 8k Bank 3
!fill $2000, 'd'
