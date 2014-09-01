#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <windows.h>
#include <QThread>
#include <QMutex>
#include <QMainWindow>
#include <vector>
#include "ui_mainwindowform.h"

using namespace std;

// Main Window
class MainWindow : public QMainWindow, Ui_MainWindowForm
{
	Q_OBJECT

public:
	explicit MainWindow(QWidget *parent = 0);
	~MainWindow();

protected:
    void customEvent(QEvent* event);
    void timerEvent(QTimerEvent *event);

private slots:
    void onSelectFile();
    void onUploadFile();
    void onNoteOn();
    void onNoteOff();
    void onStartTestSequence();
    void onStopTestSequence();
    void onSelectMidiOutInterfaceName(QString name);
    void onSelectMidiInInterfaceName(QString name);

private:
    QString getFilename();
    void setFilename(QString filename);
    QString getMidiOutInterfaceName();
    QString getMidiInInterfaceName();
    void setMidiOutInterfaceName(QString name);
    void setMidiInInterfaceName(QString name);
    bool m_testSequenceRunning;
};

extern QEvent::Type g_midiMessageEventType;

class MidiMessageEvent : public QEvent
{
public:
    MidiMessageEvent(vector< unsigned char > message) : QEvent(g_midiMessageEventType), m_message(message) {}
    vector< unsigned char > getMessage() { return m_message; }

private:
    vector< unsigned char > m_message;
};


#endif
