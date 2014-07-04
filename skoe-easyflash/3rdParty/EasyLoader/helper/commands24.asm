
.pseudocommand lsr24 src ; dst {
	.if(_isunset(dst)){
		lsr _24bit_upperArgument(src)
		ror _24bit_middleArgument(src)
		ror _24bit_lowerArgument(src)
	}else{
		lda _24bit_upperArgument(src)
		lsr
		sta _24bit_upperArgument(dst)
		lda _24bit_middleArgument(src)
		lsr
		sta _24bit_middleArgument(dst)
		lda _24bit_lowerArgument(src)
		lsr
		sta _24bit_lowerArgument(dst)
	}
}

.pseudocommand adc24_8 src1 ; src2 ; dst {
	.if(_isunset(dst)){
			lda _24bit_lowerArgument(src1)
			adc src2
			sta _24bit_lowerArgument(src1)
			bcc skip
			inc _24bit_middleArgument(src1)
			bne skip
			inc _24bit_upperArgument(src1)
		skip:
	}else{
			lda _24bit_lowerArgument(src1)
			adc src2
			sta _24bit_lowerArgument(src1)
			lda _24bit_middleArgument(src1)
			adc #0
			sta _24bit_middleArgument(src1)
			lda _24bit_upperArgument(src1)
			adc #0
			sta _24bit_upperArgument(src1)
	}
}

.pseudocommand add24_8 src1 ; src2 ; dst {
	clc
	:adc24_8 src1 ; src2 ; dst
}

