.print ">input.asm"

F_GETIN:{
	jsr get_shift
	beq is_shift

	// no shift
	:mov16 #tab1 ; ZP_INPUT_KEYTABLE
	bne !skip+
	// whith shift
is_shift:
	:mov16 #tab2 ; ZP_INPUT_KEYTABLE
!skip:

	// go trough rows
	ldy #63 // char in table
	lda #$7f
row_loop:
	sta ZP_INPUT_MATRIX
	sta $dc00
// row-loop
!loop:
	lda $dc01
	cmp $dc01
	bne !loop-
	ldx #7
// col-loop
col_loop:
	asl
	bcc a_char
doch_nicht_a_char:
	dey
	bmi no_char
	dex
	bpl col_loop

// row-loop
	lda ZP_INPUT_MATRIX
	sec
	ror
	bne row_loop // branches always

no_char:
	lda #$00
	rts

.var ZP_BUFFER = P_BUFFER

a_char:
	sta ZP_BUFFER
		// check weather shift is still the same
		jsr get_shift
		beq !skip1+
		lda #<tab1 // no shift
		bne !skip2+
	!skip1:
		lda #<tab2 // shift
	!skip2:
		cmp ZP_INPUT_KEYTABLE
		bne F_GETIN // if shift state is different: just restart
	
	lda (ZP_INPUT_KEYTABLE), y
	beq doch_nicht_a_char_l
	rts

doch_nicht_a_char_l:
	lda ZP_BUFFER
	bne doch_nicht_a_char

get_shift:
	:mov #$bf ; $dc00
!loop:
	lda $dc01
	cmp $dc01
	bne !loop-
	and #$10
	beq !is_shift+
	:mov #$fd ; $dc00
!loop:
	lda $dc01
	cmp $dc01
	bne !loop-
	and #$80
!is_shift:
	rts
}

/*
                               Port B - $DC01
              +-----+-----+-----+-----+-----+-----+-----+-----+
              |Bit 7|Bit 6|Bit 5|Bit 4|Bit 3|Bit 2|Bit 1|Bit 0|
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
        |Bit 7| R/S |  Q  |  C= |SPACE|  2  | CTRL|A_LFT|  1  |
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
        |Bit 6|  /  | A_UP|  =  | S_R | HOME|  ;  |  *  |POUND|
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
        |Bit 5|  ,  |  @  |  :  |  .  |  -  |  L  |  P  |  +  |
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
        |Bit 4|  N  |  O  |  K  |  M  |  0  |  J  |  I  |  9  |
 Port A +-----+-----+-----+-----+-----+-----+-----+-----+-----+
 $DC00  |Bit 3|  V  |  U  |  H  |  B  |  8  |  G  |  Y  |  7  |
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
        |Bit 2|  X  |  T  |  F  |  C  |  6  |  D  |  R  |  5  |
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
        |Bit 1| S_L |  E  |  S  |  Z  |  4  |  A  |  W  |  3  |
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
        |Bit 0|C_U/D|  F5 |  F3 |  F1 |  F7 |C_L/R|  CR | DEL |
        +-----+-----+-----+-----+-----+-----+-----+-----+-----+
*/

tab1:
	.byte V_KEY_DEL, V_KEY_RETURN, V_KEY_CRIGHT, V_KEY_F7, V_KEY_F1, V_KEY_F3, V_KEY_F5, V_KEY_CDOWN
	.byte $33, $57, $41, $34, $5a, $53, $45, 0   // no SHIFT
	.byte $35, $52, $44, $36, $43, $46, $54, $58
	.byte $37, $59, $47, $38, $42, $48, $55, $56
	.byte $39, $49, $4a, $30, $4d, $4b, $4f, $4e
	.byte $2b, $50, $4c, $2d, $2e, $3a, $40, $2c
	.byte $5c, $2a, $3b, V_KEY_HOME, 0, $3d, $5e, $2f // no SHIFT
	.byte $31, $5f, V_KEY_CTRL,  $32, $20, V_KEY_COMD,  $51, V_KEY_STOP

tab2:
	.byte V_KEY_INS, V_KEY_RETURN, V_KEY_CLEFT, V_KEY_F8, V_KEY_F2, V_KEY_F4, V_KEY_F6, V_KEY_CUP
		// shifted RETURN = RETURN
	.byte $23, $77, $61, $24, $7a, $73, $65, 0   // no shifted SHIFT
	.byte $25, $72, $64, $26, $63, $66, $74, $78
	.byte $27, $79, $67, $28, $62, $68, $75, $76
	.byte $29, $69, $6a, $30, $6d, $6b, $6f, $6e
	.byte 0,   $70, $6c, 0,   $3e, $5b, 0,   $3c // no shifted +,-,@
	.byte 0,   0,   $5d, V_KEY_CLR,  0, 0,   0,   $3f // no shifted POUND,*,SHIFT,=,A_UP
	.byte $21, 0,   V_KEY_SCTRL, $22, $20, V_KEY_SCOMD, $71, V_KEY_RUN
		// no shifted A_LEFT

F_INPUT_INIT:{
		// init
		:mov #0 ; ZP_INPUT_LAST_CHAR

		// init CIA1-data direction
		ldx #$ff
		stx $dc02
		inx
		stx $dc03
		
		// alles in CIA2
		// timer A stoppen
		lda #%11000000
		sta $dd0e
		// timer B stoppen
		lda #%01000000
		sta $dd0f
		// latch (zeit eines durchgangs) fuer timer A setzen
		lda #$08 // 0808 -> 2056 cycles -> ~0.002 sec / ~2/1000 sec
		sta $dd05
		sta $dd04
		// upper latch fuer timer B auf 0 setzen
		lda #$00
		sta $dd07
		// timer A starten
		lda #%11000001
		sta $dd0e

		
		rts
}

F_INPUT_GETJOY:{
		lda #$7f
		sta $dc00
!loop:
		lda $dc00
		cmp $dc00
		bne !loop-
		lsr
		bcc up
		lsr
		bcc down
		lsr
		bcc left
		lsr
		bcc right
		lsr
		bcc fire
		lda #$00
		rts

	up:
		lda #V_KEY_CUP // crsr up
		rts

	down:
		lda #V_KEY_CDOWN // crsr down
		rts

	left:
		lda #V_KEY_CLEFT // crsr left
		rts

	right:
		lda #V_KEY_CRIGHT // crsr right
		rts

	fire:
		lda #V_KEY_RETURN // crsr right
		rts
}

F_INPUT_GETKEY:{

	// get from joystick
	jsr F_INPUT_GETJOY
	bne !skip+
	// if no joystick: get from keyboard
	jsr F_GETIN
!skip:

	// process the key
	beq no_char
	
	// a key is pressed
	cmp ZP_INPUT_LAST_CHAR
	bne use_key // key is different to the last, get it
	
	lda $dd0f
	and #$01
	bne show_no_char // time is not yet done -> no key

	// rep-loop is done -> emit a key and use another rep.time
	lda #48
	jsr set_timer
	jmp return_char
	
use_key:
	sta ZP_INPUT_LAST_CHAR
	lda #200
	jsr set_timer
return_char:
	lda ZP_INPUT_LAST_CHAR
	rts

no_char:
	sta ZP_INPUT_LAST_CHAR
	rts

set_timer:
	sta $dd06
	lda #%01011001
	sta $dd0f
	rts

show_no_char:
	lda #$00
return:
	rts

}
