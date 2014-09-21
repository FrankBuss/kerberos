pushd %CD%
call "C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\qtenv2.bat"
popd

del makefile
del makefile.*
qmake.exe midi.pro -r -spec win32-g++ "CONFIG+=release"
mingw32-make clean
mingw32-make

rmdir /s /q windows-export
mkdir windows-export
copy release\midi.exe windows-export
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\Qt5Core.dll windows-export
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\Qt5Gui.dll windows-export
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\Qt5Widgets.dll windows-export
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\libgcc_s_dw2-1.dll windows-export
copy "C:\Qt\Qt5.3.2\Tools\mingw482_32\bin\libstdc++-6.dll" windows-export
copy C:\Qt\Qt5.3.2\Tools\mingw482_32\bin\libwinpthread-1.dll windows-export
copy C:\Qt\Qt5.3.2\5.3\mingw482_32\bin\icu*.dll windows-export
