
* = $8000
crtStart:

; =============================================================================
; header

; cold start vector => our program
!word coldStart

; warm start => $febc => exit interrupt
; fixme: something wrong with this, it crashes on <Restore>
!word $febc

; magic string
!byte $c3, $c2, $cd, $38, $30

; =============================================================================
; program

coldStart:
    dec $d020
    jmp coldStart

; =============================================================================
; fill it up to 8k
!fill $2000 - (* - crtStart), $ff
