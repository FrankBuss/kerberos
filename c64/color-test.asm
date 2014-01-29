// C64 color test program
// compile command line: java -jar "C:\Program Files (x86)\kickassembler\KickAss.jar" color-test.asm
// Kick Assembler: http://www.theweb.dk/KickAssembler/Main.php

.pc = $1000

start:
		// disable normal IRQ
		sei
		
		// color test
!:		
		inc $d020
		jmp !-
