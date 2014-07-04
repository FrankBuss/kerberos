;
; EasyFlash - spritesasm.s - Sprites
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

    .importzp       ptr1, ptr2, ptr3, ptr4


NUM_LOGO_SPRITES = 5

; temporary storage
zp_tmp   = ptr1

.code

; =============================================================================
;
; Show the sprites in the upper right corner.
; void spritesShow(void);
;
; Turn on/off the sprites, return old state.
; uint8_t spritesOn(uint8_t on);
;
; parameters:
;       -
;
; return:
;       -
;
; =============================================================================
.export _spritesShow
.export _spritesOn
_spritesShow:
        ; positions
        ldx #2 * NUM_LOGO_SPRITES - 1
sh1:
        lda spritePos, x
        sta $d000, x            ; sprite coords
        dex
        bpl sh1

        ldx #NUM_LOGO_SPRITES - 1
sh2:
        lda spriteCol, x
        sta $d027, x            ; sprite colors
        dex
        bpl sh2

        ; sprite pointers are calc'd at runtime, because of the linker...
        ; we need spriteBitmapsStart / 64
        lda _pSprites
        sta zp_tmp
        lda _pSprites + 1
        sta zp_tmp + 1
        ; shift right 6 times
        ldx #6
sh3:
        lsr zp_tmp + 1
        ror zp_tmp
        dex
        bne sh3

        lda zp_tmp
        clc
        ; sprite pointers, must be in sync with sprite order in sprites.s
        sta $07f8       ; "EA"
        adc #1
        sta $07f9       ; "SY"
        adc #3
        sta $07fc       ; (flash symbol)
        adc #3
        sta $07fa       ; "PR"
        adc #1
        sta $07fb       ; "OG"

        ldy #0
        sty $d010               ; sprite X MSB off
        sty $d017               ; sprite expand Y off
        sty $d01d               ; sprite expand X off
        sty $d01c               ; sprite MCM off

        ; A != 0
_spritesOn:
        cmp #0
        beq spSet               ; off?
        lda #%00011111          ; on
spSet:
        tay
        lda $d015               ; return old state
        sty $d015               ; sprite display enable
        ldx #0
        rts

spritePos:
    .byte 145 + 0 * 24, 102
    .byte 145 + 1 * 24, 102
    .byte 145 + 2 * 24, 102
    .byte 145 + 3 * 24, 102
    .byte 145 +     36, 102

spriteCol:
    .byte 0, 0, 0, 0, 8


; =============================================================================
; =============================================================================
.data
.export _pSprites
_pSprites:
    .word spriteBitmapsStart


; =============================================================================
; Put the sprites into their own segment, this is in a quite low memory
; area so it's in the VIC bank. And it's aligned.
; =============================================================================
.segment "SPRITES"
spriteBitmapsStart:
.incbin "obj/sprites.bin"

