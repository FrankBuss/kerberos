
.importzp       sp, sreg, regsave
.importzp       ptr1, ptr2, ptr3, ptr4
.importzp       tmp1, tmp2, tmp3, tmp4

.import         popax
.import         memcpy_getparams

.import         _g_nSelectedSlot
.import         __BLOCK_BUFFER_START__


; Entry points for EasyFlash driver (EAPI)
EAPIBase            = $c000         ; <= Use any address here
EAPIInit            = EAPIBase + 20
EAPIWriteFlash      = $df80 +  0
EAPIEraseSector     = $df80 +  3
EAPISetBank         = $df80 +  6
EAPIGetBank         = $df80 +  9
EAPISetPtr          = $df80 + 12
EAPISetLen          = $df80 + 15
EAPIReadFlashInc    = $df80 + 18
EAPIWriteFlashInc   = $df80 + 21
EAPISetSlot         = $df80 + 24
EAPIGetSlot         = $df80 + 27

;EASYFLASH_SLOT    = $de01

EASYFLASH_CONTROL = $de02
EASYFLASH_KILL    = $04
EASYFLASH_16K     = $07

.segment "LOWCODE"

; =============================================================================
;
; Hide BASIC/Cartridge ROM and CLI.
;
; changes: -
;
; =============================================================================
.export _efHideROM
_efHideROM:
        pha
        lda #$36
        sta $01
        lda #EASYFLASH_KILL
        sta EASYFLASH_CONTROL ; avoid the evil mode with cart ROM at $a000
        cli
        pla
        rts


; =============================================================================
;
; Show BASIC/Cartridge ROM.
;
; changes: -
;
; =============================================================================
.export _efShowROM
_efShowROM:
        sei
        pha
        lda #$37
        sta $01
        lda #EASYFLASH_16K
        sta EASYFLASH_CONTROL
        pla
        rts


; =============================================================================
;
; Map cartridge ROM, read a byte from cartridge ROM, hide ROM again.
;
; parameters:
;       pointer in AX
; return:
;       value in A
;
; =============================================================================
.export _efPeekCartROM
_efPeekCartROM:
        sta ptr1
        stx ptr1 + 1
        lda _g_nSelectedSlot
        jsr EAPISetSlot
        jsr _efShowROM
        ldy #0
        lda (ptr1), y
        jsr _efHideROM
        ldx #0
        rts


; =============================================================================
;
; Copy data from cartridge ROM to RAM. The RAM may be under the ROM.
;
; parameters:
;       like memcpy
; return:
;       like memcpy
;
; =============================================================================
.export _efCopyCartROM
_efCopyCartROM:
        ; Get the parameters from stack as follows:
        ;       size            --> ptr3
        ;       src             --> ptr1
        ;       dest            --> ptr2
        ;   First argument (dest) will remain on stack and is returned in a/x!
        jsr memcpy_getparams

        lda _g_nSelectedSlot
        jsr EAPISetSlot

        ; assert Y = 0
        ; copy n * 256 bytes
        ldx ptr3 + 1
        beq @less256
@copy256:
        jsr _efShowROM
        lda (ptr1),y
        jsr _efHideROM
        sta (ptr2),y

        iny
        bne @copy256
        inc ptr1 + 1
        inc ptr2 + 1
        dex
        bne @copy256

@less256:
        ldx ptr3        ; Get the low byte of n
        beq @done       ; something to copy
@copyRest:
        ; assert Y = 0
        jsr _efShowROM
        lda (ptr1),y
        jsr _efHideROM
        sta (ptr2),y
        iny
        dex
        bne @copyRest
@done:
        jmp popax       ; Pop ptr and return as result

; =============================================================================
;
; Compare 256 bytes of flash contents with the content of BLOCK_BUFFER.
; The bank must be set up already. The whole block must be located in one bank
; and in one flash chip.
;
; Return 0x100 for success, the offset (0..255) for error
; uint16_t __fastcall__ efVerifyFlash(uint8_t* pFlash);
;
; Do not call this from Ultimax mode, use normal addresses (8000/a000)
;
; parameters:
;       flash address in AX (A = low)
;
; return:
;       result in AX (A = low), 0x100 = okay, offset = error
;
; =============================================================================
.export _efVerifyFlash
.proc   _efVerifyFlash
_efVerifyFlash:
        sta cmpaddr
        stx cmpaddr + 1

        sei
        lda _g_nSelectedSlot
        jsr EAPISetSlot
        ldy #EASYFLASH_16K
        sty EASYFLASH_CONTROL

        jsr _efShowROM
        ldy #0
l1:
        lda __BLOCK_BUFFER_START__, y
cmpaddr = * + 1
        cmp $8000, y
        bne bad
        iny
        bne l1

        ; okay, return 0x100
        tya
        lda #1
        jmp ret4
bad:
        ; return bad offset
        tya
        ldx #0
ret4:
        jsr _efHideROM
        ldy #EASYFLASH_KILL
        sty EASYFLASH_CONTROL
        cli

        rts

.endproc


; =============================================================================
;
; (refer to EasyAPI documentation)
; In case of an error, the error code is returned in *pDeviceId.
;
; uint8_t __fastcall__ eapiInit(uint8_t* pManufacturerId, uint8_t* pDeviceId)
; uint8_t eapiReInit(void);
;
; parameters:
;       pDeviceId in AX
;       pManufacturerId on cc65-stack
; return:
;       number of banks in AX (A = low),
;                       0 = error, chipset not found or not supported
;
; =============================================================================
.export _eapiInit
_eapiInit:
        sta ptr2
        stx ptr2 + 1    ; pDeviceId
        jsr popax
        sta ptr1
        stx ptr1 + 1    ; pManufacturerId

        jsr _efShowROM
        jsr EAPIInit
        sty tmp1
        jsr _efHideROM

        ldy #0
        sta (ptr2),y    ; Device ID
        txa
        sta (ptr1),y    ; Manufacturer ID
eapiInitRet:
        bcc eiOK
        lda #0
        tax
        rts
eiOK:
        lda tmp1
        ldx #0
        rts

.export _eapiReInit
_eapiReInit:
        jsr _efShowROM
        jsr EAPIInit
        sty tmp1
        jsr _efHideROM
        jmp eapiInitRet

; =============================================================================
;
; Get the selected bank.
;
; uint8_t __fastcall__ eapiGetBank(void);
;
; parameters:
;       -
;
; return:
;       bank in AX (A = low)
;
; =============================================================================
.export _eapiGetBank
_eapiGetBank:
        jsr EAPIGetBank
        ldx #0
        rts

; =============================================================================
;
; Set the bank. This will take effect immediately for read access and will be
; used for the next write and erase commands.
;
; void __fastcall__ eapiSetBank(uint8_t nBank);
;
; parameters:
;       bank in A
;
; return:
;       -
;
; =============================================================================
.export _eapiSetBank
_eapiSetBank:
        jmp EAPISetBank

; =============================================================================
;
; Get the selected slot.
;
; uint8_t __fastcall__ eapiGetSlot(void);
;
; parameters:
;       -
;
; return:
;       slot in AX (A = low)
;
; =============================================================================
.export _eapiGetSlot
_eapiGetSlot:
        jsr EAPIGetSlot
        ldx #0
        rts

; =============================================================================
;
; Set the slot. This will take effect immediately for read access and will be
; used for the next write and erase commands.
;
; void __fastcall__ eapiSetSlot(uint8_t nSlot);
;
; parameters:
;       slot in A
;
; return:
;       -
;
; =============================================================================
.export _eapiSetSlot
_eapiSetSlot:
        jmp EAPISetSlot

; =============================================================================
;
; Erase the sector at the given address.
;
; uint8_t __fastcall__ eapiSectorErase(uint8_t* pBase);
;
; parameters:
;       base in AX (A = low), $8000 or $E000
;
; return:
;       result in AX (A = low), 1 = okay, 0 = error
;
; =============================================================================
.export _eapiSectorErase
_eapiSectorErase:
        lda _g_nSelectedSlot
        jsr EAPISetSlot

        ; x to y (high byte of address)
        txa
        tay

        jsr _efShowROM
        jsr EAPIGetBank
        jsr EAPIEraseSector
        jsr _efHideROM

        lda #0
        tax
        bcs eseError
        lda #1
eseError:
        rts

.if 0 ; unused
; =============================================================================
;
; Write a byte to the given address.
;
; uint8_t __fastcall__ eapiWriteFlash(uint8_t* pAddr, uint8_t nVal);
;
; parameters:
;       value in A
;       address on cc65-stack $8xxx/$9xxx or $Exxx/$Fxxx
;
; return:
;       result in AX (A = low), 1 = okay, 0 = error
;
; =============================================================================
.export _eapiWriteFlash
_eapiWriteFlash:
        ; remember value
        pha

        lda _g_nSelectedSlot
        jsr EAPISetSlot

        ; get address
        jsr popax
        ; ax to xy
        pha
        txa
        tay
        pla
        tax

        pla

        jsr _efShowROM
        jsr EAPIWriteFlash
        jsr _efHideROM
        lda #0
        tax
        bcs ewfError
        lda #1
ewfError:
        rts
.endif ; not used

; =============================================================================
;
; Write 256 bytes from BLOCK_BUFFER to the given address. The destination
; address must be aligned to 256 bytes.
;
; uint8_t __fastcall__ eapiGlueWriteBlock(uint8_t* pDst);
;
; parameters:
;       destination address in AX $8xxx/$9xxx or $Exxx/$Fxxx
;
; return:
;       result in AX (A = low), 0x100 = okay, offset with error otherwise
;
; =============================================================================
.export _eapiGlueWriteBlock
_eapiGlueWriteBlock:
        ; ax to xy
        pha
        txa
        tay
        pla
        tax

        lda _g_nSelectedSlot
        jsr EAPISetSlot

        jsr _efShowROM
wbNext:
        lda __BLOCK_BUFFER_START__, x
        ; parameters for EAPIWriteFlash
        ;       A   value
        ;       XY  address (X = low), $8xxx/$9xxx or $Exxx/$Fxxx
        jsr EAPIWriteFlash
        bcs wbError
        inx
        bne wbNext

        ; return 0x100 => okay
        jsr _efHideROM
        lda #0
        ldx #$01
        rts

wbError:
        ; return bad offset in AX
        jsr _efHideROM
        txa
        ldx #0
        rts

; =============================================================================
;
; Include EAPI drivers
;
; =============================================================================
.segment    "RODATA"

.export _aEAPIDrivers
_aEAPIDrivers:

EAPICode1:
@CodeStart:
.incbin "obj/eapi-am29f040-14", 2
.res $0300 - (* - @CodeStart), $ff

EAPICode2:
@CodeStart:
.incbin "obj/eapi-m29w160t-03", 2
.res $0300 - (* - @CodeStart), $ff

EAPICode3:
@CodeStart:
.incbin "obj/eapi-mx29640b-12", 2
.res $0300 - (* - @CodeStart), $ff

EAPICodeEnd:
.byte 0
