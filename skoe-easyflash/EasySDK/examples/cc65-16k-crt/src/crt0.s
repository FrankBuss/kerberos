;
; Startup code for cc65 (C64 16k CRT)
; No IRQ support at the moment
;

        .export         _exit
        .export         __STARTUP__ : absolute = 1      ; Mark as startup

        .import _main

        .import initlib, donelib, copydata
        .import zerobss
        .import BSOUT
        .import __RAM_START__, __RAM_SIZE__     ; Linker generated

        .include "zeropage.inc"
        .include "c64.inc"

; ------------------------------------------------------------------------
; Place the startup code in a special segment.

.segment           "STARTUP"

; cold start vector
        .word cold_start

; warm start vector
        .word cold_start

; magic string
        .byte $c3, $c2, $cd, $38, $30

; ------------------------------------------------------------------------
; Actual code

.code

cold_start:
reset:
        ; same init stuff the kernel calls after reset
        ldx #0
        stx $d016
        jsr $ff84   ; Initialise I/O

        ; These may not be needed - depending on what you'll do
        jsr $ff87   ; Initialise System Constants
        jsr $ff8a   ; Restore Kernal Vectors
        jsr $ff81   ; Initialize screen editor

        ; Switch to second charset
        lda #14
        jsr BSOUT

        jsr zerobss
        jsr copydata

        ; and here
        ; Set argument stack ptr
        lda #<(__RAM_START__ + __RAM_SIZE__)
        sta sp
        lda #>(__RAM_START__ + __RAM_SIZE__)
        sta sp + 1

        jsr initlib
        jsr _main

_exit:
        jsr donelib
exit:
        jmp ($fffc) ; reset, mhhh
