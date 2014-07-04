
serport         = $1800

retries         = 2             ; number of retries when reading a sector

prev_file_track = $7e
prev_file_sect  = $026f

job_code        = $04
job_track       = $0e
job_sector      = $0f

speed_zone      = $06
status          = $08           ; two bytes for status return
zpptr           = $10           ; two bytes used as pointer

stack           = $8b

iddrv0          = $12           ; disk drive id
header_id       = $16           ; disk id
header_track    = $18
header_sector   = $19
header_parity   = $1a

current_track   = $22

gcr_tmp         = $24

buff_ptr        = $30

sect_per_trk    = $43
head_step_ctr   = $4a

zptmp               = $c1
job_code_backup     = $c2
job_track_backup    = $c3
job_sector_backup   = $c4
retry_sec_cnt       = $c5       ; retry counter for searching sectors
retry_udi_cnt       = $c6       ; retry counter for update_disk_info
retry_sh_cnt        = $c7       ; retry counter for search_header

eor_correction      = $103      ; not on zeropage (need abs addressing)

gcr_overflow_size = 69
gcr_overflow_buff = $01bb

buffer              = $0700
