.include "regs.inc"

.segment "CARTRIDGE_DISK"
.export         D_CHROUT
D_CHROUT:	inc $d020
		jmp $F1CA
;		rts
