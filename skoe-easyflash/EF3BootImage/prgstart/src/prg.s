
.importzp   ptr1, ptr2, ptr3, ptr4
.importzp   tmp1, tmp2, tmp3, tmp4
.import     popa, popax

.import _ef3usb_fload
.import _ef3usb_fclose

.include "ef3usb_macros.s"


EASYFLASH_CONTROL = $de02
EASYFLASH_KILL    = $04
EASYFLASH_16K     = $07

trampoline = $0100

start_addr = $fb

.code

.if 1=0
hex:
        .byte $30, $31, $32, $33, $34, $35, $36, $37, $38, $39
        .byte 1, 2, 3, 4, 5, 6

dump_mem:
        ldx #0
@next:
        lda $0020,x
        lsr
        lsr
        lsr
        lsr
        tay
        lda hex,y
        sta $0400,x
        lda $0020,x
        and #$0f
        tay
        lda hex,y
        sta $0400+40,x
        inx
        cpx #32
        bne @next
        jmp *
.endif

; ------------------------------------------------------------------------
; faster replacement for $ff87
init_system_constants_light:
        ; from KERNAL @ FD50:
        lda #$00
        tay
:
        sta $0002,y
        sta $0200,y
        sta $0300,y
        iny
        bne :-
        ldx #$3c
        ldy #$03
        stx $b2
        sty $b3
        tay

        ; result from loop KERNAL @ FD6C:
        lda #$00
        sta $c1
        sta $0283
        lda #$a0
        sta $c2
        sta $0284

        ; from KERNAL @ FD90:
        lda #$08
        sta $0282       ; pointer: bottom of memory for operating system
        lda #$04
        sta $0288       ; high byte of screen memory address
        rts

; =============================================================================
;
; void usbtool_prg_load_and_run(void);
;
; =============================================================================
.proc   _usbtool_prg_load_and_run
.export _usbtool_prg_load_and_run
_usbtool_prg_load_and_run:
        sei
        jsr init_system_constants_light
        jsr $ff8a   ; Restore Kernal Vectors

        ldx #$19    ; ZP size - 1 from linker config
@backup_zp:
        lda $02, x
        sta $df00, x
        dex
        bpl @backup_zp

        jsr _ef3usb_fload

        sta start_addr
        stx start_addr + 1

		; set end addr + 1 to $2d and $ae
        clc
        adc ptr1
        sta $2d
        sta $ae
        txa
        adc ptr1 + 1
        sta $2e
        sta $af

        jsr _ef3usb_fclose

        ldx #$19    ; ZP size - 1 from linker config
@restore_zp:
        lda $df00, x
        sta $02, x
        dex
        bpl @restore_zp

        ; start the program
        ; looks like BASIC?
        lda start_addr
        ldx start_addr + 1
        cmp #<$0801
        bne @no_basic
        cpx #>$0801
        bne @no_basic

        ; === start basic ===
        ldx #basic_starter_end - basic_starter
:
        lda basic_starter, x
        sta trampoline, x
        dex
        bpl :-
        bmi @run_it

        ; === start machine code ===
@no_basic:
        ldx #asm_starter_end - asm_starter
:
        lda asm_starter, x
        sta trampoline, x
        dex
        bpl :-

        lda start_addr
        sta trampoline_jmp_addr + 1
        lda start_addr + 1
        sta trampoline_jmp_addr + 2
@run_it:
        lda #EASYFLASH_KILL
        jmp trampoline
.endproc

; =============================================================================
basic_starter:
.org trampoline
        sta EASYFLASH_CONTROL
        jsr $ff81   ; Initialize screen editor

        ; for BASIC programs
        jsr $e453     ; Initialize Vectors
        jsr $e3bf     ; Initialize BASIC RAM

        jsr $a659        ; Basic-Zeiger setzen und CLR
        jmp $a7ae        ; Interpreterschleife (RUN)
.reloc
basic_starter_end:

; =============================================================================
asm_starter:
.org trampoline
        sta EASYFLASH_CONTROL

        jsr $ff81   ; Initialize screen editor

        ; for BASIC programs (here too?)
        jsr $E453     ; Initialize Vectors
        jsr $E3BF     ; Initialize BASIC RAM

trampoline_jmp_addr:
        jmp $beef
.reloc
asm_starter_end:

