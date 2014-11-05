#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <windows.h>
#include <QThread>
#include <QMutex>
#include <QMainWindow>
#include <vector>
#include <stdint.h>
#include "diskdata.h"
#include "d64.h"
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
    void enableMidiTransferButtons(bool enable);

protected:
    void customEvent(QEvent* event);
    void timerEvent(QTimerEvent *event);

private slots:
    void onSelectFile();
    void onNoteOn();
    void onNoteOff();
    void onStartTestSequence();
    void onStopTestSequence();
    void onSelectMidiOutInterfaceName(QString name);
    void onSelectMidiInInterfaceName(QString name);
    void onClear();
    void onFlashPrg();
    void onStartPrgFromSlot();
    void onFlashEasyFlashCrt();
    void onFlashBasicBin();
    void onFlashKernalBin();
    void onFlashMenuBin();
    void onUploadAndRunPrg();
    void onListSlots();
    void onUploadBasicToRam();
    void onUploadKernalToRam();
    void onBackToBasic();

    void onOpenD64File();
    void onReadDirectory();
    void onDownloadD64();
    void onUploadD64();

    void onSaveSettings();

    void onReadFlashBlock();

private:
    void calculateDriveAndType(int& drive, int& type);
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

    void openD64File(QString filename);

    bool m_testSequenceRunning;
    QString m_d64Filename;

    FileDiskData m_fileDiskData;
    D64Disk m_localD64Disk;

    RemoteDiskData m_remoteDiskData;
    D64Disk m_remoteD64Disk;
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
