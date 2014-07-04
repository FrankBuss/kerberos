		// public MIDI interface routines:
		// midiInit
		// midiRead
		// midiWrite

		// interface type for midiInit:
		// 0: no MIDI interface was detected
		// 1: Sequential Circuits Inc.
		// 2: Passport & Syntech
		// 3: DATEL/Siel/JMS
		// 4: Namesoft

.var PRA  =  $dc00            // CIA#1 (Port Register A)
.var DDRA =  $dc02            // CIA#1 (Data Direction Register A)

.var PRB  =  $dc01            // CIA#1 (Port Register B)
.var DDRB =  $dc03            // CIA#1 (Data Direction Register B)
		
		// init MIDI interface, type in accu from midiDetect
midiInit:	sei

		sta midiInterfaceType
		tax
		dex

		lda #$ff  // CIA#1 port A = outputs 
		sta DDRA             

		lda #0  // CIA#1 port B = inputs
		sta DDRB             
		
		lda #$ff
		sta keyPressed
		sta keyPressedIntern
		lda #0
		sta keyTestIndex

		// init addresses
		lda midiControlOfs,x
		sta midiControl
		lda midiStatusOfs,x
		sta midiStatus
		lda midiTxOfs,x
		sta midiTx
		lda midiRxOfs,x
		sta midiRx
		lda #$de
		sta midiControl+1
		sta midiStatus+1
		sta midiTx+1
		sta midiRx+1
		
		jsr midiReset
		
		// clear ringbuffer
		lda #0
		sta midiRingbufferReadIndex
		sta midiRingbufferWriteIndex
		
		lda midiIrqType,x
		bne midiSetIrq
		
		// set NMI routine
		lda #<midiNmi
		sta $0318
		lda #>midiNmi
		sta $0319
		
		// set IRQ routine
midiSetIrq:	lda #<midiIrq
		sta $0314
		lda #>midiIrq
		sta $0315
		
		// enable IRQ/NMI
		lda #$94
		ora midiCr0Cr1,x
		sta (midiControl),y
		
		cli
		rts

midiRelease:	sei
		jsr midiReset
		lda #$31
		sta $0314
		lda #$ea
		sta $0315
		lda #$47
		sta $0318
		lda #$fe
		sta $0319
		cli
		rts
		
		// MC68B50 master reset and IRQ off
midiReset:
		ldy #0
		lda #3
		sta (midiControl),y
		rts

midiCanRead:	ldx midiRingbufferReadIndex
		cpx midiRingbufferWriteIndex
		rts

		// wait for MIDI byte and read it from ringbuffer
midiRead:	ldx midiRingbufferReadIndex
		cpx midiRingbufferWriteIndex
		beq midiRead
		
		// read next character from ringbuffer
		lda midiRingbuffer,x
		tay
		inx
		txa
		and #31
		sta midiRingbufferReadIndex
		tya
		rts
		
		// write MIDI byte and wait for write complete
midiWrite:	rts  // TODO		

		// NMI handler
midiNmi:	pha
		txa
		pha
		tya
		pha
		
		// test if it was a NMI from the MIDI interface
		ldy #0
		lda (midiStatus),y
		and #1
		beq midiNmiEnd
		jsr midiStore
midiNmiEnd:	pla
		tay
		pla
		tax
		pla
		rti

		// IRQ handler
midiIrq:	ldx midiInterfaceType
		dex
		lda midiIrqType,x
		beq midiIrqKey

		// test if it was an IRQ from the MIDI interface
		ldy #0
		lda (midiStatus),y
		and #1
		beq midiIrqKey
		jsr midiStore
		jmp midiNmiEnd

		// keyboard test
midiIrqKey:	jsr keyboardTest
		lda $dc0d
		jmp midiNmiEnd

		// get MIDI byte and store in ringbuffer
midiStore:	lda (midiRx),y
		ldx midiRingbufferWriteIndex
		sta midiRingbuffer,x
		inx
		txa
		and #31
		sta midiRingbufferWriteIndex
		rts

		// MC68B50 control register (relative to $de00)
midiControlOfs:	.byte 0, 8, 4, 0

		// MC68B50 status register
midiStatusOfs:	.byte 2, 8, 6, 2

		// MC68B50 TX register
midiTxOfs:	.byte 1, 9, 5, 1

		// MC68B50 RX register offset
midiRxOfs:	.byte 3, 9, 7, 3

		// counter divide bits CR0 and CR1 for the MC68B50
midiCr0Cr1:	.byte 1, 1, 2, 1

		// 1=IRQ, 0=NMI
midiIrqType:	.byte 1, 1, 1, 0


		// keyboard test
keyboardTest:	ldx keyTestIndex
		lda keys,x  // load colum
		sta PRA
		inx
		lda PRB
		and keys,x  // mask row
		cmp #0
		bne !+
		txa
		lsr
		sta keyPressedIntern
!:		inx
		cpx #16
		bne !+
		lda keyPressedIntern
		sta keyPressed
		lda #$ff
		sta keyPressedIntern
		ldx #0
!:		stx keyTestIndex
		rts

keys:		.byte %11101111, %00001000  // 0
		.byte %01111111, %00000001  // 1
		.byte %01111111, %00001000  // 2
		.byte %11111101, %00000001  // 3
		.byte %11111101, %00001000  // 4
		.byte %11111011, %00000001  // 5
		.byte %11111011, %00001000  // 6
		.byte %11110111, %00000001  // 7
