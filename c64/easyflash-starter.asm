// C64 color test program
// compile command line: java -jar "C:\Program Files (x86)\kickassembler\KickAss.jar" easyflash-starter.asm
// Kick Assembler: http://www.theweb.dk/KickAssembler/Main.php

.pc = $900

start:
		// disable normal IRQ
		sei
		
		// start EasyFlash in Ultimax mode
		lda #0
		sta $de3f
		lda #$66
		sta $de3e
		jmp ($fffc)
