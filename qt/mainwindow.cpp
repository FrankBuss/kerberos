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
#include <initializer_list>
#include "mainwindow.h"
#include "RtMidi.h"
#include "../c64/src/midi_commands.h"

#define NEWLINE "\x0d\x0a"

using namespace std;

const char* g_filename = "filename";
const char* g_midiInInterfaceName = "midiInInterfaceName";
const char* g_midiOutInterfaceName = "midiOutInterfaceName";

RtMidiOutWinMM g_midiOut;
RtMidiInWinMM g_midiIn;
int g_lastByte;

QEvent::Type g_midiMessageEventType = (QEvent::Type) QEvent::registerEventType();

static uint8_t g_crc;

void crc8Init()
{
    g_crc = 0xff;
}

uint8_t crc8Update(uint8_t data)
{
    static const uint8_t crcTable[256] = {
        0x00, 0x5e, 0xbc, 0xe2, 0x61, 0x3f, 0xdd, 0x83,
        0xc2, 0x9c, 0x7e, 0x20, 0xa3, 0xfd, 0x1f, 0x41,
        0x9d, 0xc3, 0x21, 0x7f, 0xfc, 0xa2, 0x40, 0x1e,
        0x5f, 0x01, 0xe3, 0xbd, 0x3e, 0x60, 0x82, 0xdc,
        0x23, 0x7d, 0x9f, 0xc1, 0x42, 0x1c, 0xfe, 0xa0,
        0xe1, 0xbf, 0x5d, 0x03, 0x80, 0xde, 0x3c, 0x62,
        0xbe, 0xe0, 0x02, 0x5c, 0xdf, 0x81, 0x63, 0x3d,
        0x7c, 0x22, 0xc0, 0x9e, 0x1d, 0x43, 0xa1, 0xff,
        0x46, 0x18, 0xfa, 0xa4, 0x27, 0x79, 0x9b, 0xc5,
        0x84, 0xda, 0x38, 0x66, 0xe5, 0xbb, 0x59, 0x07,
        0xdb, 0x85, 0x67, 0x39, 0xba, 0xe4, 0x06, 0x58,
        0x19, 0x47, 0xa5, 0xfb, 0x78, 0x26, 0xc4, 0x9a,
        0x65, 0x3b, 0xd9, 0x87, 0x04, 0x5a, 0xb8, 0xe6,
        0xa7, 0xf9, 0x1b, 0x45, 0xc6, 0x98, 0x7a, 0x24,
        0xf8, 0xa6, 0x44, 0x1a, 0x99, 0xc7, 0x25, 0x7b,
        0x3a, 0x64, 0x86, 0xd8, 0x5b, 0x05, 0xe7, 0xb9,
        0x8c, 0xd2, 0x30, 0x6e, 0xed, 0xb3, 0x51, 0x0f,
        0x4e, 0x10, 0xf2, 0xac, 0x2f, 0x71, 0x93, 0xcd,
        0x11, 0x4f, 0xad, 0xf3, 0x70, 0x2e, 0xcc, 0x92,
        0xd3, 0x8d, 0x6f, 0x31, 0xb2, 0xec, 0x0e, 0x50,
        0xaf, 0xf1, 0x13, 0x4d, 0xce, 0x90, 0x72, 0x2c,
        0x6d, 0x33, 0xd1, 0x8f, 0x0c, 0x52, 0xb0, 0xee,
        0x32, 0x6c, 0x8e, 0xd0, 0x53, 0x0d, 0xef, 0xb1,
        0xf0, 0xae, 0x4c, 0x12, 0x91, 0xcf, 0x2d, 0x73,
        0xca, 0x94, 0x76, 0x28, 0xab, 0xf5, 0x17, 0x49,
        0x08, 0x56, 0xb4, 0xea, 0x69, 0x37, 0xd5, 0x8b,
        0x57, 0x09, 0xeb, 0xb5, 0x36, 0x68, 0x8a, 0xd4,
        0x95, 0xcb, 0x29, 0x77, 0xf4, 0xaa, 0x48, 0x16,
        0xe9, 0xb7, 0x55, 0x0b, 0x88, 0xd6, 0x34, 0x6a,
        0x2b, 0x75, 0x97, 0xc9, 0x4a, 0x14, 0xf6, 0xa8,
        0x74, 0x2a, 0xc8, 0x96, 0x15, 0x4b, 0xa9, 0xf7,
        0xb6, 0xe8, 0x0a, 0x54, 0xd7, 0x89, 0x6b, 0x35,
    };
    g_crc = crcTable[data ^ g_crc];
    return g_crc;
}

uint8_t ascii2petscii(uint8_t ascii)
{
    static const uint8_t table[256] = {
        0, 1, 2, 3, 4, 5, 6, 7,
        8, 9, 10, 11, 12, 13, 14, 15,
        16, 17, 18, 19, 20, 21, 22, 23,
        24, 25, 26, 27, 28, 29, 30, 31,
        32, 33, 34, 35, 36, 37, 38, 39,
        40, 41, 42, 43, 44, 45, 46, 47,
        48, 49, 50, 51, 52, 53, 54, 55,
        56, 57, 58, 59, 60, 61, 62, 63,
        64, 97, 98, 99, 100, 101, 102, 103,
        104, 105, 106, 107, 108, 109, 110, 111,
        112, 113, 114, 115, 116, 117, 118, 119,
        120, 121, 122, 91, 92, 93, 94, 95,
        96, 65, 66, 67, 68, 69, 70, 71,
        72, 73, 74, 75, 76, 77, 78, 79,
        80, 81, 82, 83, 84, 85, 86, 87,
        88, 89, 90, 123, 124, 125, 126, 127,
        128, 129, 130, 131, 132, 133, 134, 135,
        136, 137, 138, 139, 140, 141, 142, 143,
        144, 145, 146, 147, 148, 149, 150, 151,
        152, 153, 154, 155, 156, 157, 158, 159,
        160, 161, 162, 163, 164, 165, 166, 167,
        168, 169, 170, 171, 172, 173, 174, 175,
        176, 177, 178, 179, 180, 181, 182, 183,
        184, 185, 186, 187, 188, 189, 190, 191,
        192, 193, 194, 195, 196, 197, 198, 199,
        200, 201, 202, 203, 204, 205, 206, 207,
        208, 209, 210, 211, 212, 213, 214, 215,
        216, 217, 218, 219, 220, 221, 222, 223,
        224, 225, 226, 227, 228, 229, 230, 231,
        232, 233, 234, 235, 236, 237, 238, 239,
        240, 241, 242, 243, 244, 245, 246, 247,
        248, 249, 250, 251, 252, 253, 254, 255
    };
    return table[ascii];
}

// data transfers encoded in note-off messages:
// 0x8n, n:
// bit 3: 1=start of data transfer, 0=data bytes
// bit 2: 1=two data bytes, 0=one data byte (second data byte of the note-off message is ignored)
// bit 1: bit 7 of first data byte
// bit 0: bit 7 of second data byte (if sent)
//
// start of data transfer, with two data bytes (0x8c)
// first byte: tag ID
// second byte: length
// last byte in the next data messages: CRC8 checksum

static void sendNoteOff(uint8_t channelBits, uint8_t note, uint8_t velocity)
{
    try {
        ByteArray message;
        message.push_back(0x80 | channelBits);
        message.push_back(note);
        message.push_back(velocity);
        g_midiOut.sendMessage(&message);
    } catch (RtError& err) {
        //qWarning() << QString::fromStdString(err.getMessage());
    }
}

static void midiSendBytesWithFlags(int b1, int b2, int flags)
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
    sendNoteOff(channel | flags, b1, b2);
}

static void midiStartTransfer(uint8_t tag, uint8_t length)
{
    g_lastByte = -1;
    midiSendBytesWithFlags(tag, length, 1 << 3);
}

static void midiSendBytes(int b1, int b2)
{
    midiSendBytesWithFlags(b1, b2, 0);
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

static void midiSendCommand(uint8_t tag, ByteArray data)
{
    // start file transfer
    size_t length = data.size();
    if (length <= 1) {
        tag |= 0x80;
        if (length == 1) {
            length = data[0];
            data.clear();
        }
    } else {
        length--;
    }
    midiStartTransfer(tag, length);

    // init checksum
    crc8Init();
    crc8Update(tag);
    crc8Update(length);

    // send data
    for (size_t i = 0; i < data.size(); i++) {
        midiSendByte(data[i]);
        crc8Update(data[i]);
    }

    // send checksum
    midiSendByte(g_crc);

    // end file transfer
    midiEndTransfer();
}

template <class T>
static void midiSendCommand(uint8_t tag, initializer_list<T> list)
{
    ByteArray array;
    for (auto elem : list) {
        array.push_back(elem);
    }
    midiSendCommand(tag, array);
}

static void midiSendWordCommand(uint8_t tag, uint16_t word)
{
    midiSendCommand(tag, { word & 0xff, word >> 8 });
}

static void midiSendCommand(uint8_t tag)
{
    midiSendCommand(tag, { 0 });
}

void midiCallback( double /*deltatime*/,
                   ByteArray* message,
                   void* userData )
{
    MainWindow* instance = static_cast<MainWindow*>(userData);
    QApplication::postEvent(instance, new MidiMessageEvent(*message));
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

void addString(ByteArray& data, QString string)
{
    for (int i = 0; i < string.size(); i++) {
        data.push_back(ascii2petscii(string[i].toLatin1()));
    }
    data.push_back(0);
}

static void midiSendPrintCommand(QString string)
{
    ByteArray data;
    addString(data, string);
    midiSendCommand(MIDI_COMMAND_PRINT, data);
}

static void midiSendNopCommand()
{
    ByteArray data;
    for (int j = 0; j < 256; j++) data.push_back(0);
    midiSendCommand(MIDI_COMMAND_NOP, data);
}

void MainWindow::onNoteOn()
{
    midiSendCommand(MIDI_COMMAND_START_SLOT_PROGRAM, { 2 });
    return;

    {
        int i = 0;
        while (1) {
    ByteArray data;
    addString(data, QString("").sprintf("Hello World! %i", i));
    midiSendCommand(MIDI_COMMAND_PRINT, data);
    ByteArray data2;
    data2.push_back(15);
    midiSendCommand(MIDI_COMMAND_GOTOX, data2);
    i++;
    ByteArray data3;
    for (int j = 0; j < 256; j++) data3.push_back(0);
    midiSendCommand(MIDI_COMMAND_NOP, data3);
    }
    }
#if 0
    {
    ByteArray data;
    addString(data, "Hello! World!\r\n");
    midiSendCommand(MIDI_COMMAND_PRINT, data);
    }

    {
    ByteArray data;
    addString(data, "Hello! World!\r\n");
    midiSendCommand(MIDI_COMMAND_PRINT, data);
    }

    {
    ByteArray data;
    addString(data, "Hello! World!\r\n");
    midiSendCommand(MIDI_COMMAND_PRINT, data);
    }

    {
    ByteArray data;
    addString(data, "Hello! World!\r\n");
    midiSendCommand(MIDI_COMMAND_PRINT, data);
    }

    {
    ByteArray data;
    addString(data, "Hello! World!\r\n");
    midiSendCommand(MIDI_COMMAND_PRINT, data);
    }

    {
    ByteArray data;
    addString(data, "Hello! World!\r\n");
    midiSendCommand(MIDI_COMMAND_PRINT, data);
    }

    {
    ByteArray data;
    addString(data, "Hello! World!\r\n");
    midiSendCommand(MIDI_COMMAND_PRINT, data);
    }

    {
    ByteArray data;
    addString(data, "Hello! World!\r\n");
    midiSendCommand(MIDI_COMMAND_PRINT, data);
    }

    {
    ByteArray data;
    addString(data, "Hello! World!\r\n");
    midiSendCommand(MIDI_COMMAND_PRINT, data);
    }
#endif

#if 0
    {
    ByteArray data;
    addString(data, "12");
    midiSendCommand(MIDI_COMMAND_PRINT, data);
    }

    {
    ByteArray data;
    addString(data, "1");
    midiSendCommand(MIDI_COMMAND_PRINT, data);
    }
#endif

    return;

    try {
        ByteArray message;
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
        ByteArray message;
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
    if (data.size() < 3) {
        QMessageBox::warning(NULL, tr("Filetransfer"), tr("file size too small, min 3 bytes"));
    }
    if (data.size() > 63486) {
        QMessageBox::warning(NULL, tr("Filetransfer"), tr("file size too big, max 63486 bytes"));
        return;
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
            int nameSize = name.size();
            if (nameSize > 30) nameSize = 30;
            for (int i = 0; i < name.size(); i++) {
                header.append(name[i].toLatin1());
            }

            // fill filename with zeros
            while (header.length() < 250) {
                header.append(char(0));
            }

            // CRC16 checksum
            uint16_t crc = 0;
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
        } else {
            if (!filename.toLower().endsWith(".bin")) {
                QMessageBox::warning(NULL, tr("Filetransfer"), tr(".bin-file required for menu update"));
                return;
            }

            // menu update
            startAddress = 0;
        }

        // flash
        midiSendPrintCommand("flashing " + name.left(20) + "..." + NEWLINE);
        midiSendNopCommand();
        int full = data.size();
        int transferred = 0;
        int oldPercent = -1;
        while (data.size() > 0) {
            int c64Address = (startAddress & 0x1fff) | 0x8000;
            midiSendWordCommand(MIDI_COMMAND_SET_ADDRESS, c64Address);
            midiSendCommand(MIDI_COMMAND_SET_FLASH_BANK, { startAddress >> 13 });
            if ((c64Address & 0x0fff) == 0) {
                midiSendNopCommand();
                midiSendCommand(MIDI_COMMAND_ERASE_FLASH_SECTOR);
                midiSendNopCommand();
            }
            int size = data.size();
            if (size > 256) size = 256;
            ByteArray block;
            for (int j = 0; j < size; j++) block.push_back(data[j]);
            while (block.size() < 256) block.push_back(0xff);
            midiSendCommand(MIDI_COMMAND_WRITE_FLASH, block);
            data.remove(0, size);
            startAddress += 0x100;
            transferred += size;
            int percent = transferred * 100 / full;
            if (percent > 100) percent = 100;
            if (percent != oldPercent) {
                midiSendNopCommand();
                midiSendCommand(MIDI_COMMAND_GOTOX, { 0 });
                midiSendPrintCommand(QString("").sprintf("%i%%", percent));
                oldPercent = percent;
                midiSendNopCommand();
            }
        }

        midiSendNopCommand();
        midiSendPrintCommand(NEWLINE);
        midiSendPrintCommand(QString("flash done") + NEWLINE);
        midiSendCommand(MIDI_COMMAND_EXIT);
    } else {

        // save size and address in first SRAM bank
        midiSendWordCommand(MIDI_COMMAND_SET_ADDRESS, 0xdf00);
        midiSendWordCommand(MIDI_COMMAND_SET_RAM_BANK, 0);
        int size = data.size() - 2;
        midiSendCommand(MIDI_COMMAND_WRITE_RAM, { uint8_t(size & 0xff), uint8_t(size >> 8), data[0], data[1] });

        // transfer program to SRAM, starting at second bank
        midiSendNopCommand();
        midiSendPrintCommand("receiving " + name.left(20) + "..." + NEWLINE);
        midiSendNopCommand();
        midiSendWordCommand(MIDI_COMMAND_SET_ADDRESS, 0xdf00);
        data.remove(0, 2);
        int bank = 1;
        int full = data.size();
        int transferred = 0;
        int oldPercent = -1;
        while (data.size() > 0) {
            midiSendWordCommand(MIDI_COMMAND_SET_RAM_BANK, bank);
            int size = data.size();
            if (size > 256) size = 256;
            ByteArray block;
            for (int j = 0; j < size; j++) block.push_back(data[j]);
            midiSendCommand(MIDI_COMMAND_WRITE_RAM, block);
            data.remove(0, size);
            bank++;
            transferred += size;
            int percent = transferred * 100 / full;
            if (percent != oldPercent) {
                midiSendCommand(MIDI_COMMAND_GOTOX, { 0 });
                midiSendPrintCommand(QString("").sprintf("%i%%", percent));
                oldPercent = percent;
            }
        }

        // start program
        midiSendPrintCommand(NEWLINE);
        midiSendCommand(MIDI_COMMAND_START_SRAM_PROGRAM);
    }
    return;


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
                header.append(name[i].toLatin1());
            }

            // fill filename with zeros
            while (header.length() < 250) {
                header.append(char(0));
            }

            // CRC16 checksum
            uint16_t crc = 0;
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
//        uploadFile(name, 2, startAddress, data);
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
//        uploadFile(name, 1, startAddress, data);
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

void MainWindow::timerEvent(QTimerEvent*)
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
