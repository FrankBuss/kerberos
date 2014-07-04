// flash library for accessing the SST39SF040
// needs to be executed from RAM because of self modifying code, and below $1000, because of ultimax mode
//
// public functions:
//   flashReadId
//   flashConvertAdr
//   flashProgramByte
//   flashReadByte
//   flashErase
//   flashSectorErase
//
// required zeropage variables:
//   program_dst, +1, +2
//   tmp1, tmp2, tmp3
//   flashBank/flashHigh/flashLow

		// read flash ID in X/Y
		// expected result for SST39SF040: X=$bf, Y=$b7
flashReadId:
		// first send reset, then flash ID entry command
		jsr flash_id_exit
		jsr flash_id_entry
		
		// read ID
		lda $8000
		pha
		lda $8001
		pha

		// ID exit command
		jsr flash_id_exit

		// return ID
		pla
		tay
		pla
		tax
		rts

		// flash id exit and reset
flash_id_exit:	lda #$f0
		jmp flash_cmd

		// flash id entry
flash_id_entry:	lda #$90
		jmp flash_cmd

		// write accu to flash address in X/Y (high/low), a17-a20 = 0
flash_write:	pha
		sty sta_addr+1
		txa
		lsr
		lsr
		lsr
		lsr
		lsr
		sta $de3f
		txa
		and #$1f
		clc
		adc #$80
		sta sta_addr+2
		lda #2
		sta $de3e
		pla
sta_addr:	sta $8000  // dummy address, self modifying code
		lda #1
		sta $de3e
		rts

		// convert address in program_dst+2/+1/+0 to flashBank/flashHigh/flashLow
		// e.g. address $0000 = $8000, $2000 = $8000 + bank=$01
flashConvertAdr:
		// calculate bank (one bank size: 8kb)
		lda program_dst
		sta tmp1
		lda program_dst+1
		sta tmp2
		lda program_dst+2
		sta tmp3
		ldx #13
!:		lsr tmp3
		ror tmp2
		ror tmp1
		dex
		bne !-
		lda tmp1
		sta flashBank
		
		// calculate absolute address of bank
		ldx #13
!:		asl tmp1
		rol tmp2
		rol tmp3
		dex
		bne !-
		
		// program_dst - absolute address = rest
		lda program_dst
		sec
		sbc tmp1
		sta tmp1
		lda program_dst+1
		sbc tmp2
		sta tmp2
		lda program_dst+2
		sbc tmp3
		sta tmp3
		
		// add $8000 offset for physical address
		clc
		lda tmp2
		adc #$80
		sta tmp2
		
		// return result
		lda tmp2
		sta flashHigh
		lda tmp1
		sta flashLow
		rts

		// program accu to flash, address has to be in flashBank/flashHigh/flashLow in converted format
		// returns the number of write errors in x. if x=$ff then programming was unsuccesful.
flashProgramByte:
		sta tmp1
		lda flashBank
		sta $de3f
		lda flashHigh
		sta staLoc+2
		sta ldaLoc+2
		lda flashLow
		sta staLoc+1
		sta ldaLoc+1
		ldx #0
programStart:	lda #2
		sta $de3e
		lda #$aa
		sta $8aaa
		lda #$55
		sta $8555
		lda #$a0
		sta $8aaa
		lda tmp1
staLoc:		sta $8000  // dummy address, self modifying code
		lda #1
		sta $de3e
		// max 10 us for byte programming, wait a bit longer
		ldy #15
!:		dey
		bne !-
		// check if written
ldaLoc:		lda $8000  // dummy address, self modifying code
		cmp tmp1
		beq !+
		inx
		cpx #$ff
		bne programStart
!:		rts

		// reads a byte from flash, the address has to be in flashBank/flashHigh/flashLow in converted format
		// and returns in in accu
flashReadByte:
		lda flashBank
		sta $de3f
		lda #1
		sta $de3e
		lda flashHigh
		sta ldaLoc2+2
		lda flashLow
		sta ldaLoc2+1
ldaLoc2:	lda $8000  // dummy address, self modifying code
		rts

		// erase flash
flashErase:	lda #$80
		jsr flash_cmd

		// $aaa = $aa
		lda #$aa
		ldx #$0a
		ldy #$aa
		jsr flash_write

		// $555 = $55
		lda #$55
		ldx #$05
		ldy #$55
		jsr flash_write

		// $aaa = $10
		lda #$10
		ldx #$0a
		ldy #$aa
		jsr flash_write

		jmp wait_300_ms

		// erase flash sector (4k, sector start address in flashBank/flashHigh/flashLow)
flashSectorErase:
		lda flashHigh
		sta staLoc2+2
		lda flashLow
		sta staLoc2+1

		lda #$80
		jsr flash_cmd

		// $aaa = $aa
		lda #$aa
		ldx #$0a
		ldy #$aa
		jsr flash_write

		// $555 = $55
		lda #$55
		ldx #$05
		ldy #$55
		jsr flash_write
		
		lda flashBank
		sta $de3f
		lda #2
		sta $de3e
		lda #$50
staLoc2:	sta $8000
		lda #1
		sta $de3e
		jmp wait_300_ms

		// write flash command in accu
flash_cmd:	// $aaa = $aa
		pha
		lda #$aa
		ldx #$0a
		ldy #$aa
		jsr flash_write

		// $555 = $55
		lda #$55
		ldx #$05
		ldy #$55
		jsr flash_write
		
		// $aaa = accu
		pla
		ldx #$0a
		ldy #$aa
		jmp flash_write

wait_300_ms:	ldy #0
delay:		ldx #0
!:		dex
		bne !-
		dey
		bne delay
		rts
