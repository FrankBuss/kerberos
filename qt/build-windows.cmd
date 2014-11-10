pushd %CD%
call "C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\qtenv2.bat"
popd

del makefile
del makefile.*
qmake.exe kerberos.pro -r -spec win32-g++ "CONFIG+=release"
mingw32-make clean
mingw32-make

rmdir /s /q kerberos
mkdir kerberos
mkdir kerberos\imageformats
mkdir kerberos\platforms
copy release\kerberos.exe kerberos
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\Qt5Core.dll kerberos
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\Qt5Gui.dll kerberos
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\Qt5Widgets.dll kerberos
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\libgcc_s_dw2-1.dll kerberos
copy "C:\Qt\Qt5.3.2\Tools\mingw482_32\bin\libstdc++-6.dll" kerberos
copy C:\Qt\Qt5.3.2\Tools\mingw482_32\bin\libwinpthread-1.dll kerberos
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\icu*.dll kerberos
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\plugins\imageformats\qico.dll kerberos\imageformats
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\plugins\imageformats\qjpeg.dll kerberos\imageformats
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\plugins\imageformats\qmng.dll kerberos\imageformats
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\plugins\platforms\qwindows.dll kerberos\platforms
