/*
	to compile use KickAssembler 3.6+
	
	set the use (normal or ocean) first
	
	example:
		java -jar /path/to/KickAss.jar -binfile -showmem easyloader_launcher.asm -o easyloader_launcher_nrm.bin
		java -jar /path/to/KickAss.jar -binfile -showmem easyloader_launcher.asm -o easyloader_launcher_ocm.bin

*/

.const is_ocean_module = false

.if(is_ocean_module){
	// dont load the bank, its X. if bank 1 then with INX before
	.pc = $ffde+0 "jumper"
}else{
	// regular mode
	.pc = $ffde+1 "jumper"
}

	jump_start:
		// store bank
		stx $de00
		lda #$07 // 16k-mode
		sta $de02
.if(is_ocean_module){
		jmp ($a000) // jump into the cartridge
}else{
		jmp ($8000) // jump into the cartridge
}

	.pc = * "copy it"

	start:
		sei
		// since no calculations are made and the stack is not used we do'nt initialize them
		ldx #$de
		stx $d016 // enable vic (bit 5 ($20) is clear)
	// first, initialize ram
	// second, copy a few bytes to $02+
	loop:
		lda jump_start-1, x
		sta $02-1, x
		dex
		bne loop

		// X is now zero
.if(is_ocean_module){
		inx
		bne $10002
}else{
		beq $10002
}

	.pc = $fffa "vectors"
		.word do_rti
		.word start // @fffc -> address of reset routine
	do_rti:
		rti
		.byte $78
