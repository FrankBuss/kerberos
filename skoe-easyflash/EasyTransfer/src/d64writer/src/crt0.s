;
; Startup code for cc65 (C64 version)
; modified
;
; This must be the *first* file on the linker command line
;

    .import        initlib, donelib, callirq
    .import        zerobss
    .import        callmain
    .import        RESTOR, BSOUT, CLRCH
    .import        __INTERRUPTOR_COUNT__
    .import        __RAM_START__, __RAM_SIZE__    ; Linker generated

    .importzp       sp, sreg, regsave
    .importzp       ptr1, ptr2, ptr3, ptr4
    .importzp       tmp1, tmp2, tmp3, tmp4
    .importzp       regbank

    zpspace = 26

IRQVec              := $0314

; ------------------------------------------------------------------------
; Place the startup code in a special segment.

.segment           "STARTUP"

; BASIC header with a SYS call

        .word   Head            ; Load address
Head:   .word   @Next
        .word   .version        ; Line number
        .byte   $9E,"2061"      ; SYS 2061
        .byte   $00             ; End of BASIC line
@Next:  .word   0               ; BASIC end marker

; ------------------------------------------------------------------------
; Actual code

        ldx #zpspace-1
L1:     lda sp,x
        sta zpsave,x    ; Save the zero page locations we need
        dex
        bpl L1

        lda #$36        ; Hide BASIC/CART
        sta $01

        ; Close open files
        jsr CLRCH

        ; Switch to second charset
        lda #14
        jsr BSOUT

        ; Clear the BSS data
        jsr zerobss

        tsx
        stx spsave      ; Save the system stack ptr

        ; Set argument stack ptr
        lda #<(__RAM_START__ + __RAM_SIZE__)
        sta sp
        lda #>(__RAM_START__ + __RAM_SIZE__)
        sta sp+1

        ; Call module constructors
        jsr initlib

        ; Call main - will never return
        jmp callmain

; ------------------------------------------------------------------------
; The IRQ vector jumps here, if condes routines are defined with type 2.

IRQStub:
        cld             ; Just to be sure
        jsr callirq     ; Call the functions
        jmp IRQInd      ; Jump to the saved IRQ vector

; ------------------------------------------------------------------------
.data

IRQInd:
        jmp $0000


; ------------------------------------------------------------------------
.segment "ZPSAVE"

zpsave:
        .res zpspace

; ------------------------------------------------------------------------
.bss

spsave:
        .res 1
