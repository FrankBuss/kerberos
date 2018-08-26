rem
rem this script mus be started from a "Qt 5.8 for Desktop (MinGW 5.3.0 32 bit)" shell
rem

rem clean
rem
rmdir /q /s debug
rmdir /q /s release
del /q *.bak
del /q Makefile
del /q Makefile.*
del /q *.pdb
del /q ui_*.*

rem
rem compile application
rem
qmake.exe kerberos.pro
mingw32-make clean
mingw32-make

rem
rem copy all files to the export directory
rem
rmdir /s /q kerberos
mkdir kerberos
xcopy /y release\kerberos.exe kerberos
xcopy /y flux-cuda.dll kerberos
xcopy /y default.ini kerberos
windeployqt -printsupport kerberos\kerberos.exe
xcopy /y mingw32_dll\libquadmath-0.dll kerberos
xcopy /y mingw32_dll\libgcc_s_sjlj-1.dll kerberos
xcopy /y mingw32_dll\libgfortran-3.dll kerberos
xcopy /y %QWT_ROOT%\lib\qwt.dll kerberos
