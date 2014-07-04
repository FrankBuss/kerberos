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


.include "kernal.s"

.import eload_dos_close
.import _eload_drive_is_fast


; =============================================================================
;
; void eload_close(void);
;
; Close the current file and cancel the drive code, if any.
;
; =============================================================================
.export _eload_close
_eload_close:
        jsr _eload_drive_is_fast
        beq @close_kernal

        ; First cancel the drive code
        lda $dd00
        ora #$08                ; ATN low
        sta $dd00
        ldx #10
:
        dex
        bne :-
        and #$07
        sta $dd00               ; ATN high

@close_kernal:
        ; Close file
        jsr UNTLK
        lda #0                  ; channel 0
        sta SA
        jmp eload_dos_close
