.segment "MUSIC"
		.incbin "Vomitoxin.sid", $7e
		
.segment "GRAPHICS"
leftBlack:
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte $1c, $f0, $00
	        .byte $35, $9f, $ff
	        .byte $27, $1b, $18
	        .byte $26, $31, $6b
	        .byte $20, $67, $6b
	        .byte $20, $63, $18
	        .byte $20, $f7, $1b
	        .byte $30, $d1, $4b
	        .byte $10, $7f, $6b
	        .byte $10, $19, $f8
	        .byte $10, $0c, $0f
	        .byte $13, $84, $00
	        .byte $12, $cc, $00
	        .byte $12, $78, $00
	        .byte $1e, $00, $00
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte 0

rightBlack:
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte $81, $c0, $00
	        .byte $fd, $60, $f8
	        .byte $47, $31, $8c
	        .byte $5e, $d1, $06
	        .byte $c6, $d1, $22
	        .byte $5c, $3f, $3e
	        .byte $45, $73, $0c
	        .byte $7d, $6d, $86
	        .byte $cb, $6d, $e2
	        .byte $8f, $b2, $32
	        .byte $00, $fe, $12
	        .byte $00, $13, $12
	        .byte $00, $11, $f2
	        .byte $00, $10, $06
	        .byte $00, $18, $04
	        .byte $00, $0e, $1c
	        .byte $00, $03, $f0
	        .byte $00, $00, $00
	        .byte 0

leftOrange:
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte $08, $60, $00
	        .byte $18, $e4, $e7
	        .byte $19, $ce, $94
	        .byte $1f, $98, $94
	        .byte $1f, $9c, $e7
	        .byte $1f, $08, $e4
	        .byte $0f, $0e, $b4
	        .byte $0f, $80, $94
	        .byte $0f, $e0, $07
	        .byte $0f, $f0, $00
	        .byte $0c, $78, $00
	        .byte $0c, $30, $00
	        .byte $0c, $00, $00
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte 0

rightOrange:
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte $00, $80, $00
	        .byte $b8, $c0, $70
	        .byte $a1, $20, $f8
	        .byte $39, $20, $dc
	        .byte $a3, $c0, $c0
	        .byte $ba, $8c, $f0
	        .byte $82, $92, $78
	        .byte $04, $92, $1c
	        .byte $00, $4c, $0c
	        .byte $00, $00, $0c
	        .byte $00, $0c, $0c
	        .byte $00, $0e, $0c
	        .byte $00, $0f, $f8
	        .byte $00, $07, $f8
	        .byte $00, $01, $e0
	        .byte $00, $00, $00
	        .byte $00, $00, $00
	        .byte 0
		

.segment "LOWCODE"

; =============================================================================
;
; About music player init
;
; void __fastcall__ aboutInit(void);
;
; parameters:
;       -
;
; return:
;       -
;
; =============================================================================
.export _musicInit
_musicInit:
		lda #0
		jmp $1000


; =============================================================================
;
; About music player and wait for VSync
;
; void __fastcall__ aboutPlay(void);
;
; parameters:
;       -
;
; return:
;       -
;
; =============================================================================
.export _musicPlay
_musicPlay:
		jmp $1003

; =============================================================================
;
; About music player and wait for VSync
;
; void __fastcall__ aboutPlay(void);
;
; parameters:
;       -
;
; return:
;       -
;
; =============================================================================
.export _waitVsync
_waitVsync:
		lda #250
waitVsync2:	cmp $d012
		beq waitVsync2
waitVsync3:	cmp $d012
		bne waitVsync3
		rts
