QT += core gui widgets
QMAKE_CXXFLAGS += -std=c++11

TARGET = midi
TEMPLATE = app


SOURCES += main.cpp\
        mainwindow.cpp\
    RtMidi.cpp

HEADERS  += mainwindow.h\
    RtMidi.h \
    RtError.h

FORMS    += mainwindowform.ui

win32:DEFINES += __WINDOWS_MM__
win32:LIBS += -lwinmm
win32:LIBS += -lws2_32
