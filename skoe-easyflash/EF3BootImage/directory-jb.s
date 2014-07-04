
* = $0000

; 16 bytes signature
!pet "EF-Directory V1:"

; 16 EasyFlash slots
!pet "System Area"      ; slot 0
!align 15, 0, 0
!pet "Slot 1"           ; slot 1
!align 15, 0, 0
!pet "Slot 2"           ; slot 2
!align 15, 0, 0
!pet "Slot 3"           ; slot 3
!align 15, 0, 0
!pet "Slot 4"           ; slot 4
!align 15, 0, 0
!pet "Slot 5"           ; slot 5
!align 15, 0, 0
!pet "Slot 6"           ; slot 6
!align 15, 0, 0
!pet "Slot 7"           ; slot 7
!align 15, 0, 0
!pet "Slot 8"           ; slot 8
!align 15, 0, 0
!pet "Slot 9"           ; slot 9
!align 15, 0, 0
!pet "Slot 10"          ; slot 10
!align 15, 0, 0
!pet "Slot 11"          ; slot 11
!align 15, 0, 0
!pet "Slot 12"          ; slot 12
!align 15, 0, 0
!pet "Slot 13"          ; slot 13
!align 15, 0, 0
!pet "Slot 14"          ; slot 14
!align 15, 0, 0
!pet "Slot 15"          ; slot 15
!align 15, 0, 0

; 8 KERNAL slots
!pet "C64 KERNAL V1"    ; KERNAL 1
!align 15, 0, 0
!pet "C64 KERNAL V2"    ; KERNAL 2
!align 15, 0, 0
!pet "C64 KERNAL V3"    ; KERNAL 3
!align 15, 0, 0
!pet "SX64 KERNAL"      ; KERNAL 4
!align 15, 0, 0
!pet "KERNAL 5"         ; KERNAL 5
!align 15, 0, 0
!pet "KERNAL 6"         ; KERNAL 6
!align 15, 0, 0
!pet "KERNAL 7"         ; KERNAL 7
!align 15, 0, 0
!pet "KERNAL 8"         ; KERNAL 8
!align 15, 0, 0

; $4711 = no checksum
!word $4711
