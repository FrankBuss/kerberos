
; EasyFlashSDK sample code
; see README for a description details

* = $0000

EASYFLASH_BANK    = $DE00
EASYFLASH_CONTROL = $DE02
EASYFLASH_LED     = $80
EASYFLASH_16K     = $07
EASYFLASH_KILL    = $04

; =============================================================================
; 00:0:0000 (LOROM, bank 0)
bankStart_00_0:
    ; This code resides on LOROM, it becomes visible at $8000
    !pseudopc $8000 {

        ; === the main application entry point ===
        ; copy the main code to $C000 (or whereever) - we don't run it here
        ; since the banking would make it invisible
        ; it may be a good idea to let exomizer do this in real life
        ldx #0
lp1:
        lda main,x
        sta $c000,x
        dex
        bne lp1
        jmp $c000

main:
        !pseudopc $C000 {
            ; Switch to bank 1, get a byte from LOROM and HIROM
            lda #1
            sta EASYFLASH_BANK
            lda $8000
            ldx $a000
            ; and put them to the screen, we should see "A" and "B" there
            sta $0400
            stx $0401

            ; Switch to bank 2, get a byte from LOROM and HIROM
            lda #2
            sta EASYFLASH_BANK
            lda $8000
            ldx $a000
            ; and put them to the screen, we should see "C" and "D" there
            sta $0400 + 40
            stx $0401 + 40

            ; effect!
lp2:
            dec $d020
            jmp lp2
        }

        ; fill the whole bank with value $ff
        !align $ffff, $a000, $ff
    }

; =============================================================================
; 00:1:0000 (HIROM, bank 0)
bankStart_00_1:
    ; This code runs in Ultimax mode after reset, so this memory becomes
    ; visible at $E000..$FFFF first and must contain a reset vector
    !pseudopc $e000 {
coldStart:
        ; === the reset vector points here ===
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

        ; copy the final start-up code to RAM (bottom of CPU stack)
        ldx #(startUpEnd - startUpCode)
l1:
        lda startUpCode, x
        sta $0100, x
        dex
        bpl l1
        jmp $0100

startUpCode:
        !pseudopc $0100 {
            ; === this code is copied to the stack area, does some inits ===
            ; === scans the keyboard and kills the cartridge or          ===
            ; === starts the main application                            ===
            lda #EASYFLASH_16K + EASYFLASH_LED
            sta EASYFLASH_CONTROL

            ; Check if one of the magic kill keys is pressed
            ; This should be done in the same way on any EasyFlash cartridge!

            ; Prepare the CIA to scan the keyboard
            lda #$7f
            sta $dc00   ; pull down row 7 (DPA)

            ldx #$ff
            stx $dc02   ; DDRA $ff = output (X is still $ff from copy loop)
            inx
            stx $dc03   ; DDRB $00 = input

            ; Read the keys pressed on this row
            lda $dc01   ; read coloumns (DPB)

            ; Restore CIA registers to the state after (hard) reset
            stx $dc02   ; DDRA input again
            stx $dc00   ; Now row pulled down

            ; Check if one of the magic kill keys was pressed
            and #$e0    ; only leave "Run/Stop", "Q" and "C="
            cmp #$e0
            bne kill    ; branch if one of these keys is pressed

            ; same init stuff the kernel calls after reset
            ldx #0
            stx $d016
            jsr $ff84   ; Initialise I/O

            ; These may not be needed - depending on what you'll do
            jsr $ff87   ; Initialise System Constants
            jsr $ff8a   ; Restore Kernal Vectors
            jsr $ff81   ; Initialize screen editor

            ; start the application code
            jmp $8000

kill:
            lda #EASYFLASH_KILL
            sta EASYFLASH_CONTROL
            jmp ($fffc) ; reset
        }
startUpEnd:

        ; fill it up to $FFFA to put the vectors there
        !align $ffff, $fffa, $ff

        !word reti        ; NMI
        !word coldStart   ; RESET

        ; we don't need the IRQ vector and can put RTI here to save space :)
reti:
        rti
        !byte 0xff
    }

; =============================================================================
; 01:0:0000 (LOROM, bank 1)
bankStart_01_0:
        ; fill the whole bank with value 1 = 'A'
        !fill $2000, 1

; =============================================================================
; 01:1:0000 (HIROM, bank 1)
bankStart_01_1:
        ; fill the whole bank with value 2 = 'B'
        !fill $2000, 2

; =============================================================================
; 02:0:0000 (LOROM, bank 2)
bankStart_02_0:
        ; fill the whole bank with value 3 = 'C'
        !fill $2000, 3

; =============================================================================
; 02:1:0000 (HIROM, bank 2)
bankStart_02_1:
        ; fill the whole bank with value 4 = 'D'
        !fill $2000, 4
