.print ">const.asm"

/*
	scan.asm
*/

.const O_DIR_NAME = 0
// !! TYPE, BANK, OFFSET, SIZE must be in same order as in EFS
.const O_DIR_TYPE = 24
// !! BANK, OFFSET, SIZE, LOADADDR, UNAME must be togehter (in any order)
.const O_DIR_BANK = 25
.const O_DIR_PAD = 26
.const O_DIR_OFFSET = 27
.const O_DIR_SIZE = 29
// !! TYPE, BANK, OFFSET, SIZE must be in same order as in EFS
.const O_DIR_LOADADDR = 32
.const O_DIR_UNAME = 34
// !! BANK, OFFSET, SIZE, LOADADDR, UNAME must be togehter (in any order)
.const V_DIR_SIZE = 50

.const O_DIR_MODULE_MODE = O_DIR_OFFSET // OFFET will be reused

.const O_EFS_NAME = 0
.const O_EFS_TYPE = 16
.const O_EFS_BANK = 17
.const O_EFS_PAD = 18
.const O_EFS_OFFSET = 19
.const O_EFS_SIZE = 21
.const V_EFS_SIZE = 24

.const O_EFST_MASK = $1f
.const O_EFST_FILE = $01
.const O_EFST_SUB = $02
.const O_EFST_8KCRT = $10
.const O_EFST_16KCRT = $11
.const O_EFST_16KULTCRT = $12
.const O_EFST_8KULTCRT = $13
.const O_EFST_END = $1f

.enum {
	V_KEY_NO = 0,
	V_KEY_DEL = 1,
	V_KEY_INS = 2,
	V_KEY_RETURN = 3,
	V_KEY_CLEFT = 4,
	V_KEY_CRIGHT = 5,
	// regular f-keys
//	V_KEY_F1 = 6,
	V_KEY_F2 = 7,
	V_KEY_F3 = 8,
	V_KEY_F4 = 9,
//	V_KEY_F5 = 10,
//	V_KEY_F6 = 11,
//	V_KEY_F7 = 12,
//	V_KEY_F8 = 13,
	V_KEY_CUP = 14,
	V_KEY_CDOWN = 15,
//	V_KEY_HOME = 16,
	V_KEY_CLR = 17,
	V_KEY_CTRL = 18,
	V_KEY_SCTRL = 19,
	V_KEY_COMD = 20,
	V_KEY_SCOMD = 21,
//	V_KEY_RUN = 22,
//	V_KEY_STOP = 23,

	V_JOYPRESS_FIRE_UP = $01,
	V_JOYPRESS_FIRE_DOWN = $02,
	V_JOYPRESS_FIRE_LEFT = $03,
	V_JOYPRESS_FIRE_RIGHT = $04
}

	// f-keys for movement
.const V_KEY_F1 = V_KEY_RETURN
.const V_KEY_F5 = V_KEY_CUP
.const V_KEY_F6 = V_KEY_CLEFT
.const V_KEY_F7 = V_KEY_CDOWN
.const V_KEY_F8 = V_KEY_CRIGHT
.const V_KEY_HOME = V_KEY_CLR
.const V_KEY_RUN = V_KEY_CLR
.const V_KEY_STOP = V_KEY_CLR
