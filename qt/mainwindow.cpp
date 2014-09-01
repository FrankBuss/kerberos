#include <stdint.h>
#include <QTimer>
#include <QVBoxLayout>
#include <QTextStream>
#include <QFile>
#include <QSettings>
#include <QFileDialog>
#include <QMessageBox>
#include <vector>
#include <map>
#include "mainwindow.h"
#include "RtMidi.h"
using namespace std;

const char* g_filename = "filename";
const char* g_midiInInterfaceName = "midiInInterfaceName";
const char* g_midiOutInterfaceName = "midiOutInterfaceName";

RtMidiOutWinMM g_midiOut;
RtMidiInWinMM g_midiIn;
int g_lastByte;

QEvent::Type g_midiMessageEventType = (QEvent::Type) QEvent::registerEventType();

void midiCallback( double /*deltatime*/,
                   vector< unsigned char > *message,
                   void* userData )
{
    MainWindow* instance = static_cast<MainWindow*>(userData);
    QApplication::postEvent(instance, new MidiMessageEvent(*message));
}

// data transfers encoded in note-off messages:
// 0x8n, n:
// bit 3: 1=start of data transfer, 0=data bytes
// bit 2: 1=two data bytes, 0=one data byte (second data byte of the note-off message is ignored)
// bit 1: bit 7 of first data byte
// bit 0: bit 7 of second data byte (if sent)
//
// start of data transfer, with two data bytes (0x8c)
// first byte: type of transfer:
// 0x01 or 0x02: file transfer from PC to C64: 0x01: start as PRG, 0x02: write to flash
//   filename string in ASCII, zero terminated
//   2 bytes program length (LSB first, without the first two bytes of the PRG for the start address)
//   4 bytes destination address (LSB first, flash addresses start at 0)
//   data
//   2 bytes CRC16 checksum (LSB first)
// second byte: unused

static void sendNoteOff(uint8_t channelBits, uint8_t note, uint8_t velocity)
{
    try {
        vector<unsigned char> message;
        message.push_back(0x80 | channelBits);
        message.push_back(note);
        message.push_back(velocity);
        g_midiOut.sendMessage(&message);
    } catch (RtError& err) {
        //qWarning() << QString::fromStdString(err.getMessage());
    }
}

static void midiStartTransfer(uint8_t type)
{
    g_lastByte = -1;
    sendNoteOff(0xc, type, 0);
}

static void midiSendBytes(int b1, int b2)
{
    int channel = 0;
    if (b1 & 0x80) {
        b1 &= 0x7f;
        channel |= 2;
    }
    if (b2 >= 0) {
        if (b2 & 0x80) {
            b2 &= 0x7f;
            channel |= 1;
        }
        channel |= 1 << 2;
    } else {
        b2 = 0;
    }
    sendNoteOff(channel, b1, b2);
}

static void midiSendByte(uint8_t byte)
{
    if (g_lastByte < 0) {
        g_lastByte = byte;
    } else {
        midiSendBytes(g_lastByte, byte);
        g_lastByte = -1;
    }
}

static void midiEndTransfer()
{
    if (g_lastByte >= 0) {
        midiSendBytes(g_lastByte, -1);
    }
}

static void midiSendWord(uint16_t word)
{
    midiSendByte(word & 0xff);
    midiSendByte((word >> 8) & 0xff);
}

static void midiSendDWord(uint32_t word)
{
    midiSendByte(word & 0xff);
    midiSendByte((word >> 8) & 0xff);
    midiSendByte((word >> 16) & 0xff);
    midiSendByte((word >> 24) & 0xff);
}

// CRC16, Modbus polynomial and initial value
uint16_t crc16(uint8_t* data, int length)
{
    static const uint16_t crcTable[] = {
        0X0000, 0XC0C1, 0XC181, 0X0140, 0XC301, 0X03C0, 0X0280, 0XC241,
        0XC601, 0X06C0, 0X0780, 0XC741, 0X0500, 0XC5C1, 0XC481, 0X0440,
        0XCC01, 0X0CC0, 0X0D80, 0XCD41, 0X0F00, 0XCFC1, 0XCE81, 0X0E40,
        0X0A00, 0XCAC1, 0XCB81, 0X0B40, 0XC901, 0X09C0, 0X0880, 0XC841,
        0XD801, 0X18C0, 0X1980, 0XD941, 0X1B00, 0XDBC1, 0XDA81, 0X1A40,
        0X1E00, 0XDEC1, 0XDF81, 0X1F40, 0XDD01, 0X1DC0, 0X1C80, 0XDC41,
        0X1400, 0XD4C1, 0XD581, 0X1540, 0XD701, 0X17C0, 0X1680, 0XD641,
        0XD201, 0X12C0, 0X1380, 0XD341, 0X1100, 0XD1C1, 0XD081, 0X1040,
        0XF001, 0X30C0, 0X3180, 0XF141, 0X3300, 0XF3C1, 0XF281, 0X3240,
        0X3600, 0XF6C1, 0XF781, 0X3740, 0XF501, 0X35C0, 0X3480, 0XF441,
        0X3C00, 0XFCC1, 0XFD81, 0X3D40, 0XFF01, 0X3FC0, 0X3E80, 0XFE41,
        0XFA01, 0X3AC0, 0X3B80, 0XFB41, 0X3900, 0XF9C1, 0XF881, 0X3840,
        0X2800, 0XE8C1, 0XE981, 0X2940, 0XEB01, 0X2BC0, 0X2A80, 0XEA41,
        0XEE01, 0X2EC0, 0X2F80, 0XEF41, 0X2D00, 0XEDC1, 0XEC81, 0X2C40,
        0XE401, 0X24C0, 0X2580, 0XE541, 0X2700, 0XE7C1, 0XE681, 0X2640,
        0X2200, 0XE2C1, 0XE381, 0X2340, 0XE101, 0X21C0, 0X2080, 0XE041,
        0XA001, 0X60C0, 0X6180, 0XA141, 0X6300, 0XA3C1, 0XA281, 0X6240,
        0X6600, 0XA6C1, 0XA781, 0X6740, 0XA501, 0X65C0, 0X6480, 0XA441,
        0X6C00, 0XACC1, 0XAD81, 0X6D40, 0XAF01, 0X6FC0, 0X6E80, 0XAE41,
        0XAA01, 0X6AC0, 0X6B80, 0XAB41, 0X6900, 0XA9C1, 0XA881, 0X6840,
        0X7800, 0XB8C1, 0XB981, 0X7940, 0XBB01, 0X7BC0, 0X7A80, 0XBA41,
        0XBE01, 0X7EC0, 0X7F80, 0XBF41, 0X7D00, 0XBDC1, 0XBC81, 0X7C40,
        0XB401, 0X74C0, 0X7580, 0XB541, 0X7700, 0XB7C1, 0XB681, 0X7640,
        0X7200, 0XB2C1, 0XB381, 0X7340, 0XB101, 0X71C0, 0X7080, 0XB041,
        0X5000, 0X90C1, 0X9181, 0X5140, 0X9301, 0X53C0, 0X5280, 0X9241,
        0X9601, 0X56C0, 0X5780, 0X9741, 0X5500, 0X95C1, 0X9481, 0X5440,
        0X9C01, 0X5CC0, 0X5D80, 0X9D41, 0X5F00, 0X9FC1, 0X9E81, 0X5E40,
        0X5A00, 0X9AC1, 0X9B81, 0X5B40, 0X9901, 0X59C0, 0X5880, 0X9841,
        0X8801, 0X48C0, 0X4980, 0X8941, 0X4B00, 0X8BC1, 0X8A81, 0X4A40,
        0X4E00, 0X8EC1, 0X8F81, 0X4F40, 0X8D01, 0X4DC0, 0X4C80, 0X8C41,
        0X4400, 0X84C1, 0X8581, 0X4540, 0X8701, 0X47C0, 0X4680, 0X8641,
        0X8201, 0X42C0, 0X4380, 0X8341, 0X4100, 0X81C1, 0X8081, 0X4040 };

    uint8_t temp;
    uint16_t crcWord = 0xFFFF;

    while (length--) {
        temp = *data++ ^ crcWord;
        crcWord >>= 8;
        crcWord ^= crcTable[temp];
    }
    return crcWord;
}

MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent)
{
    m_testSequenceRunning = false;
    setupUi(this);
    statusBar()->setVisible(false);
    startTimer(100);

    QObject::connect(selectFileButton, SIGNAL(clicked()), this, SLOT(onSelectFile()));
    QObject::connect(uploadFileButton, SIGNAL(clicked()), this, SLOT(onUploadFile()));
    QObject::connect(noteOnButton, SIGNAL(clicked()), this, SLOT(onNoteOn()));
    QObject::connect(noteOffButton, SIGNAL(clicked()), this, SLOT(onNoteOff()));
    QObject::connect(startTestSequenceButton, SIGNAL(clicked()), this, SLOT(onStartTestSequence()));
    QObject::connect(stopTestSequenceButton, SIGNAL(clicked()), this, SLOT(onStopTestSequence()));
    QObject::connect(midiInInterfacesComboBox, SIGNAL(activated(QString)), this, SLOT(onSelectMidiInInterfaceName(QString)));
    QObject::connect(midiOutInterfacesComboBox, SIGNAL(activated(QString)), this, SLOT(onSelectMidiOutInterfaceName(QString)));

    fileEdit->setText(getFilename());

    QString selectedName = getMidiInInterfaceName();
    int c = g_midiIn.getPortCount();
    int selectedIndex = -1;
    if (c > 0) {
        for (int i = 0; i < c; i++) {
            QString name = g_midiIn.getPortName(i).c_str();
            midiInInterfacesComboBox->addItem(name);
            if (name == selectedName) selectedIndex = i;
        }
        if (selectedIndex >= 0) {
            midiInInterfacesComboBox->setCurrentIndex(selectedIndex);
            g_midiIn.openPort(selectedIndex);
        } else {
            midiInInterfacesComboBox->setCurrentIndex(0);
            setMidiInInterfaceName(g_midiIn.getPortName(0).c_str());
            g_midiIn.openPort(0);
        }
        g_midiIn.setCallback(&midiCallback, this);
    } else {
        midiInInterfacesComboBox->addItem("No MIDI-in interfaces found!");
    }

    selectedName = getMidiOutInterfaceName();
    c = g_midiOut.getPortCount();
    selectedIndex = -1;
    if (c > 0) {
        for (int i = 0; i < c; i++) {
            QString name = g_midiOut.getPortName(i).c_str();
            midiOutInterfacesComboBox->addItem(name);
            if (name == selectedName) selectedIndex = i;
        }
        if (selectedIndex >= 0) {
            midiOutInterfacesComboBox->setCurrentIndex(selectedIndex);
            g_midiOut.openPort(selectedIndex);
        } else {
            midiOutInterfacesComboBox->setCurrentIndex(0);
            setMidiOutInterfaceName(g_midiOut.getPortName(0).c_str());
            g_midiOut.openPort(0);
        }
    } else {
        midiOutInterfacesComboBox->addItem("No MIDI-out interfaces found!");
    }
}

MainWindow::~MainWindow() {
}

#define STATUS_NOTEOFF    0x80
#define STATUS_NOTEON     0x90

void MainWindow::onNoteOn()
{
    try {
        vector<unsigned char> message;
        unsigned char chan = 0;

        int midiNote = 60;
        int vel = 100;

        // Note On: 0x90 + channel, note, vel
        message.push_back(STATUS_NOTEON | chan);
        message.push_back(midiNote);
        message.push_back(vel);
        g_midiOut.sendMessage(&message);
    } catch (RtError& err) {
        //qWarning() << QString::fromStdString(err.getMessage());
    }
}

void MainWindow::onNoteOff()
{
    try {
        vector<unsigned char> message;
        unsigned char chan = 0;

        int midiNote = 60;
        int vel = 0;

        // Note On: 0x80 + channel, note, vel
        message.push_back(STATUS_NOTEOFF | chan);
        message.push_back(midiNote);
        message.push_back(vel);
        g_midiOut.sendMessage(&message);
    } catch (RtError& err) {
        //qWarning() << QString::fromStdString(err.getMessage());
    }
}

void MainWindow::onStartTestSequence()
{
    m_testSequenceRunning = true;
}

void MainWindow::onStopTestSequence()
{
    m_testSequenceRunning = false;
}

void MainWindow::onSelectFile()
{
    QString filename = QFileDialog::getOpenFileName(this, tr("Open PRG"), getFilename(), tr("C64 PRG files (*.prg)"));
    if (filename.size() > 0) {
        fileEdit->setText(filename);
        setFilename(filename);
    }
}

static void uploadFile(QString filename, uint8_t type, uint32_t startAddress, QByteArray data)
{
    // start file transfer
    midiStartTransfer(type);

    // send name
    for (int i = 0; i < filename.size(); i++) {
        midiSendByte(filename[i].toAscii());
    }
    midiSendByte(0);

    // send size
    midiSendWord(data.size());

    // send start address
    midiSendDWord(startAddress);

    // send bytes
    for (int i = 0; i < data.size(); i++) {
        midiSendByte(data[i]);
    }

    // send checksum
    uint16_t crc = crc16((uint8_t*) data.data(), data.size());
    midiSendWord(crc);

    // end file transfer
    midiEndTransfer();
}

void MainWindow::onUploadFile()
{
    // read file
    uint32_t startAddress = 0;
    QString filename = fileEdit->text();
    QFile file(filename);
    QString name = QFileInfo(file).fileName();
    if (!file.open(QIODevice::ReadOnly)) {
        QMessageBox::warning(NULL, tr("Filetransfer"), tr("file open error"));
        return;
    }
    QByteArray data = file.readAll();
    file.close();
    if (data.size() < 2) {
        QMessageBox::warning(NULL, tr("Filetransfer"), tr("file size too small, min 2 bytes"));
    }

    // if save to flash is checked, then prepend slot data and change address
    if (saveRadioButton->isChecked()) {
        int slot = slotSpinBox->value();

        // create slot header, if slot is not 0 = menu
        if (slot) {
            if (!filename.toLower().endsWith(".prg")) {
                QMessageBox::warning(NULL, tr("Filetransfer"), tr(".prg-file required for slot save"));
                return;
            }

            QByteArray header;

            // magic byte
            header.append(0x42);

            // filename
            for (int i = 0; i < name.size(); i++) {
                header.append(name[i].toAscii());
            }

            // fill filename with zeros
            while (header.length() < 250) {
                header.append(char(0));
            }

            // CRC16 checksum
            uint16_t crc = crc16((uint8_t*) data.data(), data.size());
            header.append(crc & 0xff);
            header.append(crc >> 8);

            // PRG length
            int l = data.length() - 2;
            header.append(l & 0xff);
            header.append((l >> 8) & 0xff);

            // start included in data

            // calculate flash start address
            startAddress = slot * 0x10000;

            // prepend header
            data.prepend(header);

            if (data.size() > 63486) {
                QMessageBox::warning(NULL, tr("Filetransfer"), tr("file size too big, max 63486 bytes"));
                return;
            }

        } else {
            if (!filename.toLower().endsWith(".bin")) {
                QMessageBox::warning(NULL, tr("Filetransfer"), tr(".bin-file required for menu update"));
                return;
            }

            // menu update
            startAddress = 0;
        }
        uploadFile(name, 2, startAddress, data);
    } else {
        if (!filename.toLower().endsWith(".prg")) {
            QMessageBox::warning(NULL, tr("Filetransfer"), tr(".prg-file required for program run"));
            return;
        }

        // get start address
        startAddress = data[0] | (data[1] << 8);

        // remove from program data
        data.remove(0, 2);

        // upload and start
        uploadFile(name, 1, startAddress, data);
    }
}

QString MainWindow::getFilename()
{
    QSettings settings;
    return settings.value(g_filename, "").toString();
}

void MainWindow::setFilename(QString filename)
{
    QSettings settings;
    settings.setValue(g_filename, filename);
}

QString MainWindow::getMidiOutInterfaceName()
{
    QSettings settings;
    return settings.value(g_midiOutInterfaceName, "").toString();
}

QString MainWindow::getMidiInInterfaceName()
{
    QSettings settings;
    return settings.value(g_midiInInterfaceName, "").toString();
}

void MainWindow::setMidiOutInterfaceName(QString name)
{
    QSettings settings;
    settings.setValue(g_midiOutInterfaceName, name);
}

void MainWindow::setMidiInInterfaceName(QString name)
{
    QSettings settings;
    settings.setValue(g_midiInInterfaceName, name);
}

void MainWindow::onSelectMidiOutInterfaceName(QString name)
{
    setMidiOutInterfaceName(name);
    g_midiOut.closePort();
    //qDebug("index: %i", midiInterfacesComboBox->currentIndex());
    g_midiOut.openPort(midiOutInterfacesComboBox->currentIndex());
}

void MainWindow::onSelectMidiInInterfaceName(QString name)
{
    setMidiInInterfaceName(name);
    g_midiIn.closePort();
    //qDebug("index: %i", midiInterfacesComboBox->currentIndex());
    g_midiIn.openPort(midiInInterfacesComboBox->currentIndex());
    g_midiIn.setCallback(&midiCallback, this);
}

void MainWindow::customEvent(QEvent *event)
{
    if (event->type() == g_midiMessageEventType) {
        MidiMessageEvent* midiEvent = static_cast<MidiMessageEvent*>(event);
        vector< unsigned char > msg = midiEvent->getMessage();
        for (size_t i = 0; i < msg.size(); i++) {
            midiInDataTextEdit->append(QString("").sprintf("%02x", msg[i]));
        }
    }
    event->accept();
}

void MainWindow::timerEvent(QTimerEvent *event)
{
    static int state = 0;
    if (m_testSequenceRunning) {
        switch (state) {
            case 0:
                onNoteOn();
                state++;
                break;
            case 1:
                onNoteOff();
                state++;
                break;
            case 2:
                state = 0;
                break;
        }
    }
}
