 ;
 ; ELoad
 ;
 ; (c) 2011 Thomas Giesel
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
 ; Thomas Giesel skoe@directbox.com
 ;

    .importzp       sp, sreg, regsave
    .importzp       ptr1, ptr2, ptr3, ptr4
    .importzp       tmp1, tmp2, tmp3, tmp4

    .import         popax

    .import         _eload_read_byte

; =============================================================================
;
; unsigned int __fastcall__ eload_read(void* buffer, unsigned int size);
;
; Reads up to "size" bytes from a file to "buffer".
; Returns the number of bytes actually read, 0 if there are no bytes left
; (EOF).
;
; =============================================================================
.export _eload_read
_eload_read:
        eor #$ff
        sta ptr1
        txa
        eor #$ff
        sta ptr1 + 1            ; Save -size-1

        jsr popax
        sta ptr2
        stx ptr2 + 1            ; Save buffer

        lda #$00                ; bytesread = 0
        sta ptr3
        sta ptr3 + 1
        beq @Read3              ; Branch always

@Loop:
        jsr _eload_read_byte
        cpx #0
        bne @End                ; EOF
        sta (ptr2, x)           ; Save read byte

        inc ptr2
        bne @Read2
        inc ptr2 + 1            ; ++buffer;
@Read2:
        inc ptr3
        bne @Read3
        inc ptr3 + 1            ; ++bytesread;
@Read3:
        inc ptr1
        bne @Loop
        inc ptr1 + 1
        bne @Loop
@End:
        lda ptr3
        ldx ptr3 + 1            ; return bytesread;

        rts
