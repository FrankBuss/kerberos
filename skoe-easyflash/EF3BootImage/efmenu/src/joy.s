

DEBOUNCE_DELAY  =   3
REPEAT_DELAY    =  25
REPEAT_TIME     =   8

CH_CURS_UP      = 145
CH_CURS_DOWN    =  17
CH_CURS_LEFT    = 157
CH_CURS_RIGHT   =  29
CH_ENTER        =  13

.code

;--------------
.export _joy_init_irq
_joy_init_irq:
    sei
    lda $0314
    sta orig_irq
    lda $0315
    sta orig_irq + 1

    lda #<irq
    sta $0314
    lda #>irq
    sta $0315
    cli
    rts

;----------------
irq:
    lda #$7f
    sta $dc00
    lda $dc00
    and #$1f
    cmp #$1f
    beq @nothing_pressed

    tay
    ldx #4
@next_dir:
    tya
    lsr
    tay
    bcs @not_this_dir

    dec repeat_counter
    bne @not_this_dir

    lda next_repeat_time
    sta repeat_counter
    lda #REPEAT_TIME
    sta next_repeat_time

    lda key_list, x
    bne @push_key

@not_this_dir:
    dex
    bpl @next_dir
    jmp (orig_irq)

@push_key:
    ldx $c6
    cpx $0289       ; Maximum number of Bytes in Keyboard Buffer
    bcs @q_full
    sta $0277,x     ; Keyboard Buffer Queue (FIFO)
    inc $c6
@q_full:
    jmp (orig_irq)

@nothing_pressed:
    lda #DEBOUNCE_DELAY
    sta repeat_counter
    lda #REPEAT_DELAY
    sta next_repeat_time
    jmp (orig_irq)

;----------------
.rodata
key_list:
    .byte CH_ENTER, CH_CURS_RIGHT, CH_CURS_LEFT, CH_CURS_DOWN, CH_CURS_UP

;----------------
.bss
orig_irq:
    .res 2

;----------------
.data

repeat_counter:
    .byte DEBOUNCE_DELAY
next_repeat_time:
    .byte REPEAT_DELAY
