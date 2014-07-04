
; This code does some basic system initializations and starts a cartridge
; from bank BOOT_FROM_BANK

* = $ff00

EASYFLASH_BANK    = $DE00
EASYFLASH_CONTROL = $DE02
EASYFLASH_LED     = $80
EASYFLASH_16K     = $07
EASYFLASH_KILL    = $04

BOOT_FROM_BANK    = $08

start:
        ; === the reset vector points to here ===
        sei
        ldx #$ff
        txs
        cld

        lda #$37
        sta $01
        lda #$2f
        sta $00

        ; enable VIC (e.g. RAM refresh)
        lda #8
        sta $d016

        ; write to RAM to make sure it starts up correctly (=> RAM datasheets)
wait:
        sta $0100, x
        dex
        bne wait

        ; x is 0 now
copy:
        lda ramcode, x
        sta $0400, x
        inx
        bne copy
        jmp $0400

ramcode:
!pseudopc 0x0400 {
        lda #BOOT_FROM_BANK
        sta EASYFLASH_BANK
        jmp ($fffc)
}

!fill $0100 - (* - start) - 4, $ff
!word   start
!word   0xffff
