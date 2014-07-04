
.importzp   tmp2 ; $ 3 6
.importzp   ptr1 ; $ 3 0
.importzp   ptr2 ; $ 3 e

.import     popax

.bss
gcr_bin:
        .res 4 ; $ 5 2
gcr_tmp:
        .res 5
parity:
        .res 1


.rodata

gcr_tab:
.byte $0a, $0b, $12, $13, $0e, $0f, $16, $17
.byte $09, $19, $1a, $1b, $0d, $1d, $1e, $15

.code

; =============================================================================
;
; void __fastcall__ convert_block_to_gcr(uint8_t* p_dst, uint8_t* p_src);
;
; =============================================================================
.export _convert_block_to_gcr
_convert_block_to_gcr:
        sta ptr2
        stx ptr2 + 1
        jsr popax
        sta ptr1
        stx ptr1 + 1

; Convert 260 bytes to 325 bytes group code
; (ptr2) => (ptr1)
convert_block_to_gcr:
        lda #0
        tay
:
        eor (ptr2),y        ; calc parity
        iny
        bne :-
        sta parity
        tya                 ; 0
        sta tmp2            ; start at offset 0

        lda #$07            ; data block id
        sta gcr_bin
        ldy tmp2
        lda (ptr2),y
        sta gcr_bin + 1
        iny
        lda (ptr2),y
        sta gcr_bin + 2
        iny
        lda (ptr2),y
        sta gcr_bin + 3     ; and 3 bytes of data
        iny
@next:
        sty tmp2
        jsr convert_4_to_gcr
        ldy tmp2
        lda (ptr2),y
        sta gcr_bin
        iny
        beq @last
        lda (ptr2),y        ; data from block
        sta gcr_bin + 1
        iny
        lda (ptr2),y
        sta gcr_bin + 2
        iny
        lda (ptr2),y
        sta gcr_bin + 3
        iny
        bne @next
@last:
        lda parity
        sta gcr_bin + 1
        lda #0              ; parity and 0 0
        sta gcr_bin + 2
        sta gcr_bin + 3
        jmp convert_4_to_gcr



; Convert 4 binary bytes to 5 GCR bytes
; Input is read from gcr_bin
; Output is written to (ptr1), ptr1 is updated
convert_4_to_gcr:
        lda #$00
        sta gcr_tmp + 1
        sta gcr_tmp + 4
        tay
        lda gcr_bin
        pha
        and #$f0            ; isolate hi-nibble
        lsr
        lsr                 ; and rotate to lower nibble
        lsr
        lsr
        tax                 ; as index in table
        lda gcr_tab, x
        asl
        asl                 ; times 8
        asl
        sta gcr_tmp
        pla
        and #$0f            ; isolate lower nibble
        tax                 ; as index in table
        lda gcr_tab, x
        ror
        ror gcr_tmp + 1
        ror
        ror gcr_tmp + 1
        and #$07
        ora gcr_tmp
        sta (ptr1), y       ; in buffer
        iny                 ; increment buffer
        lda gcr_bin + 1
        pha
        and #$f0            ; isolate upper nibble
        lsr
        lsr
        lsr                 ; shift to upper nibble
        lsr
        tax                 ; as index in table
        lda gcr_tab, x
        asl
        ora gcr_tmp + 1
        sta gcr_tmp + 1
        pla
        and #$0f            ; lower nibble
        tax                 ; as index
        lda gcr_tab, x
        rol
        rol
        rol
        rol
        sta gcr_tmp + 2
        rol
        and #$01
        ora gcr_tmp + 1
        sta (ptr1), y       ; in buffer
        iny                 ; increment buffer
        lda gcr_bin + 2
        pha
        and #$f0            ; isolate hi-nibble
        lsr
        lsr
        lsr
        lsr
        tax
        lda gcr_tab, x
        clc
        ror
        ora gcr_tmp + 2
        sta (ptr1), y       ; in buffer
        iny                 ; increment buffer pointer
        ror
        and #$80
        sta gcr_tmp + 3
        pla
        and #$0f            ; lower nibble
        tax                 ; as index
        lda gcr_tab, x
        asl
        asl
        and #$7c
        ora gcr_tmp + 3
        sta gcr_tmp + 3
        lda gcr_bin + 3
        pha
        and #$f0            ; isolate hi-nibble
        lsr
        lsr                 ; shift to lower nibble
        lsr
        lsr
        tax                 ; as index in table
        lda gcr_tab, x
        ror
        ror gcr_tmp + 4
        ror
        ror gcr_tmp + 4
        ror
        ror gcr_tmp + 4
        and #$03
        ora gcr_tmp + 3
        sta (ptr1), y       ; in buffer
        iny                 ; increment buffer pointer
        pla
        and #$0f            ; lower nibble
        tax                 ; as index
        lda gcr_tab, x
        ora gcr_tmp + 4
        sta (ptr1), y       ; in buffer

        clc
        lda ptr1
        adc #5              ; advance ptr1
        sta ptr1
        bcc @ret
        inc ptr1 + 1
@ret:
        rts



