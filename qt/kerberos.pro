QT += core gui widgets
QMAKE_CXXFLAGS += -std=c++11

TARGET = kerberos
TEMPLATE = app


SOURCES += main.cpp\
        mainwindow.cpp\
        disktoolswindow.cpp\
    RtMidi.cpp

HEADERS  += mainwindow.h\
	disktoolswindow.h\
    RtMidi.h \
    RtError.h

FORMS    += mainwindowform.ui
FORMS    += disktoolswindowform.ui

win32:DEFINES += __WINDOWS_MM__
win32:LIBS += -lwinmm
win32:LIBS += -lws2_32
