.print ">last_config.asm"

.const P_LAST_CONFIG_ADDRESS = $dffc

F_LAST_CONFIG_READ:{

	// scan stack-area for $00 or $ff -> less than 5 others do a fresh_start
	ldx #$00
	ldy #-5
!loop:
	lda $100, x
	beq !skip+
	cmp #$ff
	beq !skip+
	iny
	beq next_step
!skip:
	inx
	bne !loop-
	beq fresh_start

next_step:
	:mov P_LAST_CONFIG_ADDRESS+0 ; P_DRAW_START
	:mov P_LAST_CONFIG_ADDRESS+1 ; P_DRAW_OFFSET

	lda P_DRAW_START
	clc
	adc P_DRAW_OFFSET
	clc
	adc P_LAST_CONFIG_ADDRESS+2
	cmp #$65
	bne fresh_start

	// just belive we're right
	rts

fresh_start:
	lda #0
	sta P_DRAW_START // show first line
	sta P_DRAW_OFFSET // first line is active
	
	jsr F_LAST_CONFIG_WRITE
	
	:copy_to_df00 copy_scan_boot_start ; [copy_scan_boot_end - copy_scan_boot_start]
	jmp scan_boot // does a rts it not found

copy_scan_boot_start:
	.pseudopc $df00 {
		.const TEMP = $02
		end_scan:
			:mov #EASYLOADER_BANK ; $de00
	rts	
		scan_boot:
			:mov #EASYFILESYSTEM_BANK ; $de00
			:mov16 #$a000-V_EFS_SIZE ; TEMP
		big_loop:
			:add16_8 TEMP ; #V_EFS_SIZE
		
			ldy #O_EFS_TYPE
			lda (TEMP), y
			and #O_EFST_MASK
			cmp #O_EFST_END
			beq end_scan // type = end of fs
			and #$10
			beq big_loop // not of type crt
		
			ldy #$00
		!loop:
			// check a char
			lda (TEMP), y
			cmp boot_once, y
			bne big_loop
			
			iny
			cpy #[boot_once_end - boot_once]
			bne !loop-			
	
		found_boot:
			ldy #O_EFS_TYPE
			lda (TEMP), y
			and #$03
			tax
			lda type2mode_table, x
			tax
			iny
			lda (TEMP), y
			sta $de00
			sta $df00
			lda #$00
			sta $df01
			stx $de02
			jmp ($fffc)
			
		type2mode_table:
			.byte MODE_8k
			.byte MODE_16k
			.byte MODE_ULT
			.byte MODE_ULT
		
		boot_once: // "!el_boot-once"
			.byte $21, $45, $4c, $5f, $42, $4f, $4f, $54, $2d, $4f, $4e, $43, $45, $00
		boot_once_end:

	}
copy_scan_boot_end:
	
}

F_LAST_CONFIG_WRITE:{

	lda #$65
	sec
	sbc P_DRAW_START
	sec
	sbc P_DRAW_OFFSET
	sta P_LAST_CONFIG_ADDRESS+2

	:mov P_DRAW_START ; P_LAST_CONFIG_ADDRESS+0
	:mov P_DRAW_OFFSET ; P_LAST_CONFIG_ADDRESS+1

	rts
}