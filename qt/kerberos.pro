QT += core gui widgets
QMAKE_CXXFLAGS += -std=c++11

TARGET = kerberos
TEMPLATE = app


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

RESOURCES = application.qrc
RC_ICONS = kerberos.ico
