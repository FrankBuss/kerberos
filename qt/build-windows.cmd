pushd %CD%
call "C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\qtenv2.bat"
popd

del makefile
del makefile.*
qmake.exe kerberos.pro -r -spec win32-g++ "CONFIG+=release"
mingw32-make clean
mingw32-make

rmdir /s /q windows-export
mkdir windows-export
mkdir windows-export\imageformats
mkdir windows-export\platforms
copy release\kerberos.exe windows-export
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\Qt5Core.dll windows-export
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\Qt5Gui.dll windows-export
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\Qt5Widgets.dll windows-export
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\libgcc_s_dw2-1.dll windows-export
copy "C:\Qt\Qt5.3.2\Tools\mingw482_32\bin\libstdc++-6.dll" windows-export
copy C:\Qt\Qt5.3.2\Tools\mingw482_32\bin\libwinpthread-1.dll windows-export
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\icu*.dll windows-export
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\plugins\imageformats\qico.dll windows-export\imageformats
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\plugins\imageformats\qjpeg.dll windows-export\imageformats
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\plugins\imageformats\qmng.dll windows-export\imageformats
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\plugins\platforms\qwindows.dll windows-export\platforms
