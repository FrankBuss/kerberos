.include "regs.inc"

MIDI_6850_CONTROL = $de00
MIDI_6850_STATUS  = $de02
MIDI_6850_TX      = $de01
MIDI_6850_RX      = $de03


.segment "LOWCODE"

; =============================================================================
;
; Test IRQ and NMI for the MIDI interface
;
; uint8_t __fastcall__ midiIrqNmiTest(void);
;
; parameters:
;       -
;
; return:
;       1, if NMI and IRQ is working
;
; =============================================================================
.export _midiIrqNmiTest
_midiIrqNmiTest:
		sei
		
		; disable MIDI NMI interrupts
		lda #0
		sta MIDI_CONFIG
		
		; set NMI routine
		lda #<midiNmiTest
		sta $0318
		lda #>midiNmiTest
		sta $0319
		
		; enable MIDI
		lda #MIDI_CONFIG_ENABLE_ON
		sta MIDI_CONFIG
		
		; Namesoft registers
		lda #$02
		sta MIDI_ADDRESS
		
		; reset 68B50
		lda #3
		sta MIDI_6850_CONTROL
		
		; init 68B50 with transmit interrupt enabled
		lda #$35
		sta MIDI_6850_CONTROL
		
		; reset flag
		lda #0
		sta midiIrqFlag
		
		; enable MIDI NMI interrupts
		lda #(MIDI_CONFIG_ENABLE_ON | MIDI_CONFIG_NMI_ON)
		sta MIDI_CONFIG
		nop
		
		; test if NMI interrupt was called
		lda midiIrqFlag
		beq testEnd
		
		; disable IRQs
		lda #MIDI_CONFIG_ENABLE_ON
		sta MIDI_CONFIG

		; test IRQ
		lda #<midiIrqTest
		sta $0314
		lda #>midiIrqTest
		sta $0315
		
		; switch off CIA1 IRQs
		lda #127
		sta $dc0d
		
		; clear pending CIA1 IRQs
		lda $dc0d
		
		; reset 68B50
		lda #3
		sta MIDI_6850_CONTROL
		
		; init 68B50 with transmit interrupt enabled
		lda #$35
		sta MIDI_6850_CONTROL
		
		; reset flag
		lda #0
		sta midiIrqFlag

		; enable MIDI IRQ interrupts
		lda #(MIDI_CONFIG_ENABLE_ON | MIDI_CONFIG_IRQ_ON)
		sta MIDI_CONFIG
		nop
		
		; test, if NMI was not called
		lda midiIrqFlag
		eor #1
		beq testEnd
		cli
		nop
		
		; test if IRQ interrupt was called
		lda midiIrqFlag
		sei
		
testEnd:	ldx #0
		stx MIDI_CONFIG
		ldx #3
		stx MIDI_6850_CONTROL
		ldx #$31
		stx $0314
		ldx #$ea
		stx $0315
		ldx #$47
		stx $0318
		ldx #$fe
		stx $0319
		ldx #$81
		stx $dc0d
		ldx #0
		cli
		rts

		; NMI test handler
midiNmiTest:	pha
		txa
		pha
		tya
		pha
		; set flag
		lda #1
		sta midiIrqFlag
		; disable interrupt
		lda #3
		sta MIDI_6850_CONTROL
		jmp midiNmiEnd
	
		; NMI test handler
midiIrqTest:	; set flag
		lda #1
		sta midiIrqFlag
		; disable interrupt
		lda #3
		sta MIDI_6850_CONTROL
		jmp midiNmiEnd
	
; =============================================================================
;
; Init MIDI interface for Namesoft emulation with NMI
;
; void __fastcall__ midiInit(void);
;
; parameters:
;       -
;
; return:
;       -
;
; =============================================================================
.export _midiInit
_midiInit:	sei
		
		; disable MIDI NMI interrupts
		lda #0
		sta MIDI_CONFIG
		
		; clear ringbuffer
		lda #0
		sta midiReadIndex
		sta midiWriteIndex
		sta midiFifoMax
		
		; set NMI routine
		lda #<midiNmi
		sta $0318
		lda #>midiNmi
		sta $0319
		
		; enable MIDI NMI interrupts and set Namesoft configuration
		lda #(MIDI_CONFIG_NMI_ON | MIDI_CONFIG_CLOCK_500_KHZ | MIDI_CONFIG_ENABLE_ON)
		sta MIDI_CONFIG
		lda #$02
		sta MIDI_ADDRESS
		
		; reset 68B50
		lda #3
		sta MIDI_6850_CONTROL
		
		; init 68B50
		lda #$95
		sta MIDI_6850_CONTROL
		lda MIDI_6850_STATUS
		lda MIDI_6850_RX
		
		cli
		
		rts
	
        
; =============================================================================
;
; Test for MIDI byte received.
;
; uint8_t __fastcall__ midiByteReceived(void);
;
; parameters:
;       -
;
; return:
;       1, if at least one MIDI byte is in the receive buffer
;
; =============================================================================
.export _midiByteReceived
_midiByteReceived:
		ldx #0
		lda #0
		ldy midiReadIndex
		cpy midiWriteIndex
		beq noByte
		lda #1
noByte:		rts

; =============================================================================
;
; Read next byte from ringbuffer.
;
; uint8_t __fastcall__ midiReadByte(void);
;
; parameters:
;       -
;
; return:
;       next byte in ringbuffer, if available, or 0 if ringbuffer is empty
;
; =============================================================================
.export _midiReadByte
_midiReadByte:	ldx #0
		lda #0
		ldy midiReadIndex
		cpy midiWriteIndex
		beq skip
		lda midiRingbuffer,y
		inc midiReadIndex
skip:		rts

; =============================================================================
;
; Wait until next byte, then read it from ringbuffer.
;
; uint8_t __fastcall__ midiWaitAndReadByte(void);
;
; parameters:
;       -
;
; return:
;       next byte in ringbuffer, if available, or 0 if ringbuffer is empty
;
; =============================================================================
.export _midiWaitAndReadByte
_midiWaitAndReadByte:
		ldx #0
		lda #0
		ldy midiReadIndex
wait:		cpy midiWriteIndex
		beq wait
		lda midiRingbuffer,y
		inc midiReadIndex
		rts

; =============================================================================
;
; Send next byte to MIDI and wait until it was sent.
;
; void __fastcall__ midiSendByte(uint8_t);
;
; parameters:
;       byte to send
;
; return:
;       -
;
; =============================================================================
.export _midiSendByte
_midiSendByte:
send_byte:	sta MIDI_6850_TX
send2:		lda MIDI_6850_STATUS
		and #2
		beq send2
		rts


.segment "LOWCODE"

		; NMI handler
midiNmi:	pha
		txa
		pha
		tya
		pha
		
		; test if it was a NMI from the MIDI interface
		lda MIDI_6850_STATUS
		and #1
		beq midiNmiEnd

		; get MIDI byte and store in ringbuffer
midiStore:	lda MIDI_6850_RX
		ldx midiWriteIndex
		sta midiRingbuffer,x
		inc midiWriteIndex

midiNmiEnd:	pla
		tay
		pla
		tax
		pla
		rti

midiRingbuffer: .res 256
midiWriteIndex:	.res 1
midiReadIndex:	.res 1
midiIrqFlag:	.res 1
midiFifoMax:	.res 1
