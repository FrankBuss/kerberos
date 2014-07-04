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

.import eload_dos_open_listen_cmd
.import eload_dos_send_data
.import eload_dos_send_talk
.import eload_dos_close

.include "kernal.s"
.include "drivetype.s"


; =============================================================================
.rodata

; This table is used to detect the type of a disk drive.
; The first entry which matches is used. Table must be smaller than 256 bytes!
;
; It has following format for each entry:
; - 4 bytes     Substring to be found, may end with '*'s as wildcard
; - 1 byte      Drive type ID (refer to drive_type.s)
drive_id_tab:
        .byte "sd2i", drivetype_sd2iec
        .byte "uiec", drivetype_sd2iec
        .byte "1541", drivetype_1541
        .byte "1570", drivetype_1570
        .byte "1571", drivetype_1571
        .byte "1581", drivetype_1581
        ;.byte "fd**", drivetype_fd
        ;.byte "hd**", drivetype_hd
        .byte "vice", drivetype_vice
        .byte "para", drivetype_1541 ; groepaz has a speeddos clone called parados
        .byte 0 ; end marker

str_ui:
        .byte "ui"
str_ui_len = * - str_ui

.bss

drive_id_str_size = 32
drive_id_str:
        .res drive_id_str_size

.code
; =============================================================================

; =============================================================================
;
; =============================================================================
.export drive_detect
drive_detect:
        ; clear id string
        lda #0
        ldy #drive_id_str_size - 1
@clear:
        sta drive_id_str, y
        dey
        bpl @clear

        ; ask the drive to send its ID
        jsr eload_dos_open_listen_cmd
        bcs @not_present
        lda #str_ui_len
        ldx #<str_ui
        ldy #>str_ui
        jsr eload_dos_send_data
        bcs @not_present
        jsr UNLSN
        jsr eload_dos_send_talk
        bcs @not_present
        ldy #0
@next_byte:
        lda ST
        bne @end_of_id
        jsr ACPTR
        sta drive_id_str, y
        iny
        cpy #drive_id_str_size
        bne @next_byte
@end_of_id:
        jsr eload_dos_close

        ; search for the substrings in this string
        ldx #0              ; points into drive_id_tab
@check_next_entry:
        ldy #0              ; points into drive_id_str
@check_next_pos:
        lda drive_id_str, y
        cmp drive_id_tab, x
        bne @mismatch
        lda drive_id_str + 1, y
        cmp drive_id_tab + 1, x
        bne @mismatch
        lda drive_id_str + 2, y
        cmp drive_id_tab + 2, x
        bne @mismatch
        lda drive_id_str + 3, y
        cmp drive_id_tab + 3, x
        beq @match
@mismatch:
        iny
        cpy #drive_id_str_size - 4
        bne @check_next_pos
        inx
        inx
        inx
        inx
        inx
        lda drive_id_tab, x
        bne @check_next_entry
        ; no match
        lda #drivetype_unknown
        rts
@not_present:
        lda #drivetype_not_present
        rts
@match:
        lda drive_id_tab + 4, x
        rts

