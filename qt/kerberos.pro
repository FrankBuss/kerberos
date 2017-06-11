QT += core gui widgets

TARGET = kerberos
TEMPLATE = app

macx: DEFINES += __MACOSX_CORE__
macx: LIBS += -framework CoreAudio -framework CoreMIDI -framework CoreFoundation
ICON = kerberos.icns

SOURCES += main.cpp\
        mainwindow.cpp\
    RtMidi.cpp \
    diskimage.cpp \
    diskdata.cpp \
    d64.cpp

HEADERS  += mainwindow.h\
    RtMidi.h \
    RtError.h \
    diskimage.h \
    diskdata.h \
    d64.h

FORMS    += mainwindowform.ui

win32:DEFINES += __WINDOWS_MM__
win32:LIBS += -lwinmm
win32:LIBS += -lws2_32

unix:DEFINES += __LINUX_ALSASEQ__
unix:LIBS += -lasound 
unix:TARGET = kerberos.bin

# unix:DEFINES += __LINUX_JACK__
# unix:LIBS += -ljack

RESOURCES = application.qrc
RC_ICONS = kerberos.ico
