#!/bin/sh

export PATH=$PATH:/Users/gartenzwerg/Qt5.3.2/5.3/clang_64/bin/
rm -rf kerberos.app
rm -rf kerberos.dmg
qmake
make
macdeployqt kerberos.app -dmg
