
.include "config.s"


.rodata

; =============================================================================
;.if eload_use_fast_tx = 0

.align 16

.export sendtab
sendtab:
    .byte $00, $80, $20, $a0
    .byte $40, $c0, $60, $e0
    .byte $10, $90, $30, $b0
    .byte $50, $d0, $70, $f0
sendtab_end:
    .assert >(sendtab_end - 1) = >sendtab, error, "sendtab mustn't cross page boundary"
    ; If you get this error, you linker config may need something like this:
    ; RODATA:   load = RAM, type = ro, align = $10;

; =============================================================================
;.else ; eload_use_fast_tx

    .align 256

.export sendtab75, sendtab64, sendtab31, sendtab20
sendtab75:
    ; bit 7 and bit 5 of the index at bit 4 (clock) and bit 5 (data)
    .repeat 256, n
        .byte ((n & $80) >> 3) | (n & $20)
    .endrep

sendtab64:
    ; bit 6 and bit 4 of the index at bit 4 (clock) and bit 5 (data)
    .repeat 256, n
        .byte ((n & $40) >> 2) | ((n & $10) << 1)
    .endrep

sendtab31:
    ; bit 3 and bit 1 of the index at bit 4 (clock) and bit 5 (data)
    .repeat 256, n
        .byte ((n & $08) << 1) | ((n & $02) << 4)
    .endrep

sendtab20:
    ; bit 2 and bit 0 of the index at bit 4 (clock) and bit 5 (data)
    .repeat 256, n
        .byte ((n & $04) << 2) | ((n & $01) << 5)
    .endrep
sendtab75_end:
    .assert >(sendtab75_end - 1) = (>sendtab75) + 3, error, "sendtab mustn't cross page boundary"
    ; If you get this error, you linker config may need something like this:
    ; RODATA:   load = RAM, type = ro, align = $100;

;.endif
