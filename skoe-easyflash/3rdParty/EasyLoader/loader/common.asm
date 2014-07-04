.print ">common.asm"

F_LAUNCH:
{

	.var ZP_LINE = P_BUFFER

	:mov P_DRAW_OFFSET ; ZP_LINE
	:add ZP_LINE ; P_DRAW_START

	:mul8_16 ZP_LINE ; #V_DIR_SIZE ; ZP_ENTRY ; X
	:add16 ZP_ENTRY ; #P_DIR

	:lday( ZP_ENTRY , O_DIR_TYPE )
	beq return // 0 => not loadable
	// if it's a file:
	:if A ; EQ ; #O_EFST_FILE ; JMP ; F_LAUNCH_FILE
	// otherwise it must be a crt, because others are not supported
	jmp F_LAUNCH_CRT

return:
	rts
}

F_RESET_GRAPHICS:{
	// make screen black
	lda #$00
	ldx #$00
!loop:
	sta $d800, x
	sta $d900, x
	sta $da00, x
	sta $db00, x
	dex
	bne !loop-
	
	// reset graphics
	:mov #$00 ; $d011
	:mov #$c0 ; $d016
	:mov #$01 ; $d018
	:mov #$ff ; $dd00
	
	rts
}
