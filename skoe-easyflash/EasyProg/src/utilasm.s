;
; EasyFlash - util.s - Some utility functions
;
; (c) 2009 Thomas 'skoe' Giesel
;
; This software is provided 'as-is', without any express or implied
; warranty.  In no event will the authors be held liable for any damages
; arising from the use of this software.
;
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
;
; 1. The origin of this software must not be misrepresented; you must not
;    claim that you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation would be
;    appreciated but is not required.
; 2. Altered source versions must be plainly marked as such, and must not be
;    misrepresented as being the original software.
; 3. This notice may not be removed or altered from any source distribution.
;

.import         BASIN
.importzp       ptr1, ptr2, ptr3, tmp1, tmp2
.import         popax, popa

.import         init_decruncher
.import         get_decrunched_byte
.import         _eload_read_byte
.import         _utilStr
.import         _utilAskForNextFile
.import         _getCrunchedByte
.import         __EXOBUFFER_START__
.import         __EXOBUFFER_SIZE__

.export buffer_start_hi: absolute
.export buffer_len_hi: absolute
buffer_start_hi   = >__EXOBUFFER_START__
buffer_len_hi     = >__EXOBUFFER_SIZE__  ; see EASY_SPLIT_MAX_EXO_OFFSET

; Kernal I/O Status Word ST
ST                = $90

EASYFLASH_BANK    = $DE00
EASYFLASH_CONTROL = $DE02
EASYFLASH_LED     = $80
EASYFLASH_KILL    = $04
EASYFLASH_ULTIMAX = $05
EASYFLASH_8K      = $06
EASYFLASH_16K     = $07

.segment "LOWCODE"


; =============================================================================
; hex digits
; =============================================================================
.rodata
hexDigits:
        .byte "0123456789ABCDEF"

; =============================================================================
; Two's complement of uncompressed bytes remaining - 1 to be read from exomizer
; =============================================================================
.data
.export _nUtilExoBytesRemaining
_nUtilExoBytesRemaining:
        .res 4

.code



; =============================================================================
;
; The decruncher jsr:s to the get_crunched_byte address when it wants to
; read a crunched byte. This subroutine has to preserve x and y register
; and must not modify the state of the carry flag.
;
; =============================================================================
        .export get_crunched_byte
get_crunched_byte:
        php
        stx tmp1
ugcbCont:
        jsr _eload_read_byte
        cpx #0
        bne @EOF

        ldx tmp1
        plp
        rts

@EOF:
        sty tmp2        ; save Y

        jsr utilAskForNextCrunchedFile
        ldy tmp2        ; restore Y
        bcs @cancel
        bcc ugcbCont
@cancel:
        ; skip the whole call chain and return from _utilReadEasySplitFile
        ldx utilReadEasySplitFileEntrySP
        txs

        lda #0          ; return 0
        tax
        rts

; =============================================================================
;
; See exomizer documentation
;
; void utilInitDecruncher(void);
;
; =============================================================================

.export _utilInitDecruncher
_utilInitDecruncher:
        jmp init_decruncher


; =============================================================================
;
; Backup the zero page (because we use cc65 tmp* and ptr*) for our storage),
; ask for the next split file and restore the zero page.
;
; Return C = 1 if the user cancelled.
;
; =============================================================================
utilAskForNextCrunchedFile:
        ; backup cc65 ZP area
        ldx #$1a        ; see ld.cfg
uafE1:
        lda $02, x      ; see ld.cfg
        sta $c400, x
        dex
        bpl uafE1

        jsr _utilAskForNextFile

        cmp #0
        beq uafCancel

        ; restore cc65 ZP area
        ldx #$1a        ; see ld.cfg
uafE2:
        lda $c400, x
        sta $02, x      ; see ld.cfg
        dex
        bpl uafE2
        clc
        rts

        ; todo: xxx mit Stack-Rollback implementieren
uafCancel:
        sec
        rts

; =============================================================================
;
; unsigned int __fastcall__ utilReadEasySplitFile(void* buffer,
;                                                 unsigned int size);
;
; Reads up to "size" bytes from a file to "buffer".
; Returns the number of actually read bytes, 0 if there are no bytes left
; (EOF).
;
; =============================================================================
.data
utilReadEasySplitFileEntrySP:
        .res 1

.code
.export _utilReadEasySplitFile
_utilReadEasySplitFile:
        eor     #$FF
        sta     ptr1
        txa
        eor     #$FF
        sta     ptr1 + 1        ; Save -size-1

        jsr     popax
        sta     ptr2
        stx     ptr2 + 1        ; Save buffer

        ; remember the stack pointer at this point
        ; so we are able to cancel the whole call chain later
        tsx
        stx utilReadEasySplitFileEntrySP

; bytesread = 0;

        lda #$00
        sta ptr3
        sta ptr3 + 1
        beq urs3                ; Branch always

; Loop

urs1:
        ; increment
        inc _nUtilExoBytesRemaining
        bne ursNoEOF
        inc _nUtilExoBytesRemaining + 1
        bne ursNoEOF
        inc _nUtilExoBytesRemaining + 2
        bne ursNoEOF
        inc _nUtilExoBytesRemaining + 3
        beq ursEnd

ursNoEOF:
        ; don't forget: this may call the disk change dialog
        ; so before calling utilAskNextFile we must save the ptr1..ptr3
        jsr get_decrunched_byte
        sta     (ptr2),y        ; Save read byte

        inc     ptr2
        bne     urs2
        inc     ptr2 + 1        ; ++buffer;
urs2:
        inc     ptr3
        bne     urs3
        inc     ptr3 + 1        ; ++bytesread;

urs3:
        ; increment bytes to read (negative), end if 0 is reached
        inc     ptr1
        bne     urs1
        inc     ptr1 + 1
        bne     urs1

ursEnd:
        lda     ptr3
        ldx     ptr3 + 1        ; return bytesread;

        rts

; =============================================================================
;
; Append a single digit hex number to the string utilStr.
;
; void __fastcall__ utilAppendHex1(uint8_t n);
;
; parameters:
;       value n in A
;       address on cc65-stack
;
; return:
;       -
;
; =============================================================================
.export _utilAppendHex1
_utilAppendHex1:
        pha             ; remember n

        ; get string end
        jsr _utilGetStringEnd
        sta ptr1
        stx ptr1 + 1
        pla
        pha

        ldy #0
utilAppendHex1_:
        ; get low nibble
        pla
        and #$0f
        tax
        lda hexDigits, x
        sta (ptr1), y

        ; 0-termination
        lda #0
        iny
        sta (ptr1), y

        rts


; =============================================================================
;
; Append a two digit hex number to the string utilStr.
;
; void __fastcall__ utilAppendHex2(uint8_t n);
;
; parameters:
;       value n in A
;
; return:
;       -
;
; =============================================================================
.export _utilAppendHex2
_utilAppendHex2:
        pha             ; remember n

        ; get string end
        jsr _utilGetStringEnd
        sta ptr1
        stx ptr1 + 1
        pla

        ; get high nibble
        pha
        lsr
        lsr
        lsr
        lsr
        tax
        lda hexDigits, x
        ldy #0
        sta (ptr1), y

        iny
        bne utilAppendHex1_ ; always

; =============================================================================
;
; Append a character to the string utilStr.
;
; void __fastcall__ utilAppendChar(char c);
;
; parameters:
;       character c in A
;
; return:
;       -
;
; =============================================================================
.export _utilAppendChar
_utilAppendChar:
        pha             ; remember c

        ; get string end
        jsr _utilGetStringEnd
        sta ptr1
        stx ptr1 + 1

        ldy #0
        pla
        sta (ptr1), y

        ; 0-termination
        tya
        iny
        sta (ptr1), y

        rts

; =============================================================================
;
; Return the address of end of utilStr.
;
; parameters:
;       -
;
; return:
;       address of 0-termination of string in AX
;
; changes:
;       Y, C
;
; =============================================================================
;.export _utilGetStringEnd
_utilGetStringEnd:
        lda #<_utilStr
        ldx #>_utilStr
        sta ptr1
        stx ptr1 + 1

        ldy #0
@next:
        lda (ptr1), y
        beq @end

        iny
        bne @noHi
        inc ptr1 + 1
        inx
@noHi:
        bne @next       ; always (as long as the string doesn't wrap to ZP)

@end:
        clc
        tya             ; update low-byte
        adc ptr1
        bcc @endNoHi
        inx
@endNoHi:
        rts
