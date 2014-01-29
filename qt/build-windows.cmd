rmdir /s /q .build
call "c:\QtSDK\Desktop\Qt\4.7.4\mingw\bin\qtenv2.bat"

del makefile
del makefile.*
qmake.exe midi.pro -r -spec win32-g++ "CONFIG+=release"
mingw32-make clean
mingw32-make

del /s /q windows-export\*.*
mkdir windows-export
copy release\midi.exe windows-export
copy ..\c64\flash-program.prg windows-export
copy C:\QtSDK\Desktop\Qt\4.7.4\mingw\bin\mingwm10.dll windows-export
copy C:\QtSDK\Desktop\Qt\4.7.4\mingw\bin\QtCore4.dll windows-export
copy C:\QtSDK\Desktop\Qt\4.7.4\mingw\bin\QtGui4.dll windows-export
copy C:\QtSDK\Desktop\Qt\4.7.4\mingw\bin\libgcc_s_dw2-1.dll windows-export
