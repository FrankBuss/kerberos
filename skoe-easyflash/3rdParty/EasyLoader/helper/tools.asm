.print ">tools.asm"

F_BINBCD_8BIT: {
                sed             // Switch to decimal mode
                lda #0          // Ensure the result is clear
                sta P_BINBCD_OUT+0
                sta P_BINBCD_OUT+1
                ldy #8          // The number of source bits
                
        CNVBIT: asl P_BINBCD_IN         // Shift out one bit
                lda P_BINBCD_OUT+0      // And add into result
                adc P_BINBCD_OUT+0
                sta P_BINBCD_OUT+0
                lda P_BINBCD_OUT+1      // propagating any carry
                adc P_BINBCD_OUT+1
                sta P_BINBCD_OUT+1
                dey             // And repeat for next bit
                bne CNVBIT
                cld             // Back to binary
                
                rts             // All Done.
}

F_BINBCD_10BIT: {
                sed             // Switch to decimal mode
                lda #0          // Ensure the result is clear
                sta P_BINBCD_OUT+0
                sta P_BINBCD_OUT+1
                ldy #10         // The number of source bits
                
                // drop 6 bits
                :asl16 P_BINBCD_IN
                :asl16 P_BINBCD_IN
                :asl16 P_BINBCD_IN
                :asl16 P_BINBCD_IN
                :asl16 P_BINBCD_IN
                :asl16 P_BINBCD_IN
                
        CNVBIT: :asl16 P_BINBCD_IN      // Shift out one bit
                lda P_BINBCD_OUT+0      // And add into result
                adc P_BINBCD_OUT+0
                sta P_BINBCD_OUT+0
                lda P_BINBCD_OUT+1      // propagating any carry
                adc P_BINBCD_OUT+1
                sta P_BINBCD_OUT+1
                dey             // And repeat for next bit
                bne CNVBIT
                cld             // Back to binary
                
                rts             // All Done.
}

F_BINBCD_16BIT: {
                sed             // Switch to decimal mode
                lda #0          // Ensure the result is clear
                sta P_BINBCD_OUT+0
                sta P_BINBCD_OUT+1
                sta P_BINBCD_OUT+2
                ldy #16         // The number of source bits
                
        CNVBIT: :asl16 P_BINBCD_IN      // Shift out one bit
                lda P_BINBCD_OUT+0      // And add into result
                adc P_BINBCD_OUT+0
                sta P_BINBCD_OUT+0
                lda P_BINBCD_OUT+1      // propagating any carry
                adc P_BINBCD_OUT+1
                sta P_BINBCD_OUT+1
                lda P_BINBCD_OUT+2      // propagating any carry
                adc P_BINBCD_OUT+2
                sta P_BINBCD_OUT+2
                dey             // And repeat for next bit
                bne CNVBIT
                cld             // Back to binary
                
                rts             // All Done.
}

F_BCDIFY_LOWER_BUF:{
                and #$0f         //; convert lower nybble
                jsr hexc
        output: sta P_DIR_BUFFER,x    //; output a byte using a zp-ptr and Y-index
                inx             //; increment the output address
                rts
        hexc: cmp #$a           //; subroutine converts 0-F to a character
                bcs hexa
                clc             //; digit 0-9
                adc #$30
                bne hexb        //; unconditional jump coz Z=FALSE always
        hexa: lda #$20 // " "
        hexb: rts
}

F_BCDIFY_BUF:{
                tay
                lsr
                lsr
                lsr
                lsr
                jsr hexc        //; convert upper nybble
                jsr output
                tya
                and #$f         //; convert lower nybble
                jsr hexc
        output: sta P_DIR_BUFFER,x    //; output a byte using a zp-ptr and Y-index
                inx             //; increment the output address
                rts
        hexc: cmp #$a           //; subroutine converts 0-F to a character
                bcs hexa
                clc             //; digit 0-9
                adc #$30
                bne hexb        //; unconditional jump coz Z=FALSE always
        hexa: lda #$20 // " "
        hexb: rts
}

.if(false){
F_HEXIFY_BUF:{
                tay
                lsr
                lsr
                lsr
                lsr
                jsr hexc        //; convert upper nybble
                jsr output
                tya
                and #$f         //; convert lower nybble
                jsr hexc
        output: sta P_DIR_BUFFER,x    //; output a byte using a zp-ptr and Y-index
                inx             //; increment the output address
                rts
        hexc: cmp #$a           //; subroutine converts 0-F to a character
                bcs hexa
                clc             //; digit 0-9
                adc #$30
                bne hexb        //; unconditional jump coz Z=FALSE always
        hexa: clc
        		adc #$41-10
        hexb: rts
}
}

F_COPY_TO_DF00:{
	.var PTR = P_BINBCD_IN
	sta PTR+0
	stx PTR+1
!loop:
	lda (PTR), y
	sta $deff, y
	dey
	bne !loop-
	rts
}

.pseudocommand copy_to_df00 start ; len {
	.assert "copy_to_df00: len too big", len.getValue() <= 251, true
	.var PTR = P_BINBCD_IN
	lda #[start.getValue()-1] & $ff
	ldx #[start.getValue()-1] >> 8
	ldy #len.getValue()
	jsr F_COPY_TO_DF00
}

