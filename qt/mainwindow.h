#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <windows.h>
#include <QThread>
#include <QMutex>
#include <QMainWindow>
#include <vector>
#include <stdint.h>
#include "ui_mainwindowform.h"

using namespace std;

typedef vector<uint8_t> ByteArray;

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
    void onNoteOn();
    void onNoteOff();
    void onDiskTools();
    void onStartTestSequence();
    void onStopTestSequence();
    void onSelectMidiOutInterfaceName(QString name);
    void onSelectMidiInInterfaceName(QString name);
    void onClear();
    void onFlashPrg();
    void onFlashAndRunPrg();
    void onFlashEasyFlashCrt();
    void onFlashBasicBin();
    void onFlashKernalBin();
    void onFlashMenuBin();
    void onUploadAndRunPrg();
    void onUploadBasicToRam();
    void onUploadKernalToRam();
    void onBackToBasic();

private:
    QString getFilename();
    void setFilename(QString filename);
    QString getMidiOutInterfaceName();
    QString getMidiInInterfaceName();
    void setMidiOutInterfaceName(QString name);
    void setMidiInInterfaceName(QString name);

    QByteArray createHeader(QString name, bool ramOperation, int length);
    void flashBasicKernal(QString name, int address);
    void uploadBasicKernal(QString flashName, int address);
    QByteArray readFile(QString& name);
    bool flashPrg();

    bool m_testSequenceRunning;
};

extern QEvent::Type g_midiMessageEventType;

class MidiMessageEvent : public QEvent
{
public:
    MidiMessageEvent(ByteArray message) : QEvent(g_midiMessageEventType), m_message(message) {}
    ByteArray getMessage() { return m_message; }

private:
    ByteArray m_message;
};


#endif
