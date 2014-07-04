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

.import eload_ctr
.import eload_recv

.bss

; points to the function to read bytes
eload_read_byte_fn:
        .res 2

; the first byte of a file is read upon open already, it is buffered here
.export eload_buffered_byte
eload_buffered_byte:
        .res 1

.code

; =============================================================================
;
; Read a byte from the file.
; int eload_read_byte(void);
;
; parameters:
;       -
;
; return:
;       result in AX (A = low), 0 = okay, -1 = error
;
; changes:
;       flags
;
; =============================================================================
.export _eload_read_byte
.align 4
_eload_read_byte:
        jmp (eload_read_byte_fn)

; =============================================================================
;
; Set eload_read_byte_fn. Used internally only.
;
; parameters:
;       pointer to function in AX (A = low)
;
; return:
;       -
; =============================================================================
.export eload_set_read_byte_fn
eload_set_read_byte_fn:
        sta eload_read_byte_fn
        stx eload_read_byte_fn + 1
        rts

; =============================================================================
;
; Implementation for eload_read_byte. Used internally only.
; This version returns the buffered byte and redirects further calls to
; read_byte_kernal.
;
; =============================================================================
.export eload_read_byte_from_buffer
eload_read_byte_from_buffer:
        lda #<eload_read_byte_kernal
        ldx #>eload_read_byte_kernal
        jsr eload_set_read_byte_fn

        lda eload_buffered_byte
        ldx #0
        rts

; =============================================================================
;
; Implementation for eload_read_byte. Used internally only.
; This version reads the byte from the serial bus using ACPTR.
; TALK must have been sent already.
;
; =============================================================================
.export eload_read_byte_kernal
eload_read_byte_kernal:
        ldx ST
        bne ret_err
        jmp ACPTR


; =============================================================================
;
; Implementation for eload_read_byte. Used internally only.
; Use the fast protocol to read a byte from the bus.
;
; =============================================================================
.export eload_read_byte_fast
eload_read_byte_fast:
        ldx ST          ; x = 0 will be used as high byte below
        bne ret_err
        lda eload_ctr
        beq @nextblock
@return:
        dec eload_ctr
        ; return value x = 0 from ST above
        sei
        jsr eload_recv
        cli
        rts
@nextblock:
        sei
        jsr eload_recv
        cli
        beq set_eof
        sta eload_ctr
        cmp #$ff        ; error flag
        bne @return

set_error:
        lda ST
        ora #$02        ; Read error
        sta ST
        bne ret_err     ; branch always
set_eof:
        lda ST
        ora #$40        ; EOF flag
        sta ST
ret_err:
        lda #$ff
        tax
        rts
