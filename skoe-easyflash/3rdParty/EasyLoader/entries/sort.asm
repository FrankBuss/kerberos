.print ">sort.asm"

F_SORT:{
	
	.var ZP_RETRY = P_BINBCD_OUT+0
	.var ZP_TODO = P_BINBCD_OUT+1
	.var ZP_COUNT = P_BINBCD_OUT+2
	.var ZP_NEXT_ENTRY = P_BINBCD_IN
	
	// init
	lda P_NUM_DIR_ENTRIES
	beq return // no files!
	sta ZP_COUNT

big_loop:
	// blink led
	lda P_LED_STATE
	eor #$80
	sta P_LED_STATE
	sta $de02
	
	// do not sort again
	:mov #1 ; ZP_RETRY
	
	:mov ZP_COUNT ; ZP_TODO
	
	:mov16 #P_DIR ; ZP_NEXT_ENTRY
loop_entry:
	dec ZP_TODO
	beq again

	:mov16 ZP_NEXT_ENTRY ; ZP_ENTRY
	:add16_8 ZP_NEXT_ENTRY ; #V_DIR_SIZE
	
	ldy #O_DIR_UNAME-1
loop_char:
	iny
	cpy #V_DIR_SIZE
	beq loop_entry // "cur" == "cur+1" => next line
	lda (ZP_NEXT_ENTRY), y
	cmp (ZP_ENTRY), y
	bcc swap_entries // "cur" > "cur+1" => swap them
	beq loop_char // "cur" == "cur+1" => next char
	bne loop_entry // "cur" < "cur+1" => next line

swap_entries:
	ldy #V_DIR_SIZE-1
!loop:
	lda (ZP_ENTRY),y
	pha
	lda (ZP_NEXT_ENTRY),y
	sta (ZP_ENTRY),y
	pla
	sta (ZP_NEXT_ENTRY),y
	dey
	bpl !loop-
	
	:mov #0 ; ZP_RETRY
	jmp loop_entry

again:
	lda ZP_RETRY
	beq big_loop

return:

	// turn led off
	lda P_LED_STATE
	and #$7f
	sta P_LED_STATE
	sta $de02

	rts
}