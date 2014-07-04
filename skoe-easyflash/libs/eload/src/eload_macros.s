
.ifndef ELOAD_OK

; These error codes are the same as the ones for 1541 job codes
ELOAD_OK                =  1
ELOAD_HEADER_NOT_FOUND  =  2
ELOAD_ERR_NO_SYNC       =  3
ELOAD_SECTOR_NOT_FOUND  =  4
ELOAD_WRITE_PROTECTED   =  8

ELOAD_UNKNOWN_CMD       =  255

; Used as table indexes, do not change
ELOAD_OVERLAY_NONE    = 0
ELOAD_OVERLAY_READ    = 1
ELOAD_OVERLAY_WRITE   = 2
ELOAD_OVERLAY_FORMAT  = 3


; Byte ready check for drive code
.macro wait_byte_ready
    bvc *
    clv
.endmacro

.endif
