java -jar "C:\Program Files (x86)\kickassembler\KickAss.jar" -binfile menu.asm
rem del menu.crt
rem python create-flash.py
rem "C:\Program Files\WinVICE-2.4-x64\cartconv" -t md -i flash.bin -o menu.crt
rem "C:\data\projects\vice-2.4\src\cartconv" -t md -i flash.bin -o menu.crt
java -jar "C:\Program Files (x86)\kickassembler\KickAss.jar" flash-program.asm
rem copy /y /b flash-test.prg + menu.bin flash-test2.prg
rem copy /y /b flash-test2.prg flash-test.prg
copy /y /b flash-program.prg ..\qt\flash-program.prg
copy /y /b flash-program.prg ..\qt\windows-export\flash-program.prg
