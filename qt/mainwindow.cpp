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
#include <QStandardItemModel>
#include "mainwindow.h"
#include "RtMidi.h"
#include "d64.h"
#include "../c64/src/midi_commands.h"
#include "../c64/src/kerberos.h"
#include "../c64/src/regs.h"
#include "../c64/src/config.h"

#define NEWLINE QString("\x0d\x0a")

using namespace std;

const char* g_filename = "filename";
const char* g_midiInInterfaceName = "midiInInterfaceName";
const char* g_midiOutInterfaceName = "midiOutInterfaceName";

const char g_kerberosPrgSlotId[16] = KERBEROS_PRG_SLOT_ID;
const char g_kerberosMenuId[16] = { 75, 69, 82, 66, 69, 82, 79, 83, 32, 77, 69, 78, 85, 32, 73, 68 };


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
    startTimer(100);

    connect(selectFileButton, SIGNAL(clicked()), this, SLOT(onSelectFile()));
    connect(noteOnButton, SIGNAL(clicked()), this, SLOT(onNoteOn()));
    connect(noteOffButton, SIGNAL(clicked()), this, SLOT(onNoteOff()));
    connect(startTestSequenceButton, SIGNAL(clicked()), this, SLOT(onStartTestSequence()));
    connect(stopTestSequenceButton, SIGNAL(clicked()), this, SLOT(onStopTestSequence()));
    connect(midiInInterfacesComboBox, SIGNAL(activated(QString)), this, SLOT(onSelectMidiInInterfaceName(QString)));
    connect(midiOutInterfacesComboBox, SIGNAL(activated(QString)), this, SLOT(onSelectMidiOutInterfaceName(QString)));
    connect(clearButton, SIGNAL(clicked()), this, SLOT(onClear()));
    connect(flashPrgButton, SIGNAL(clicked()), this, SLOT(onFlashPrg()));
    connect(startPrgFromSlotButton, SIGNAL(clicked()), this, SLOT(onStartPrgFromSlot()));
    connect(flashEasyFlashCrtButton, SIGNAL(clicked()), this, SLOT(onFlashEasyFlashCrt()));
    connect(flashBasicBinButton, SIGNAL(clicked()), this, SLOT(onFlashBasicBin()));
    connect(flashKernalBinButton, SIGNAL(clicked()), this, SLOT(onFlashKernalBin()));
    connect(flashMenuBinButton, SIGNAL(clicked()), this, SLOT(onFlashMenuBin()));
    connect(uploadAndRunPrgButton, SIGNAL(clicked()), this, SLOT(onUploadAndRunPrg()));
    connect(uploadBasicToRamButton, SIGNAL(clicked()), this, SLOT(onUploadBasicToRam()));
    connect(uploadKernalToRamButton, SIGNAL(clicked()), this, SLOT(onUploadKernalToRam()));
    connect(backToBasicButton, SIGNAL(clicked()), this, SLOT(onBackToBasic()));

    connect(openD64FileButton, SIGNAL(clicked()), this, SLOT(onOpenD64File()));

    connect(saveSettingsButton, SIGNAL(clicked()), this, SLOT(onSaveSettings()));

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

static QString hexNumber4(int number)
{
    QString result = QString::number(number, 16);
    while (result.size() < 4) result = "0" + result;
    return result;
}

void MainWindow::onSelectFile()
{
    QString filename = QFileDialog::getOpenFileName(this, tr("Open PRG"), getFilename(), tr("C64 files (*.prg *.bin *.crt)"));
    if (filename.size() > 0) {
        fileEdit->setText(filename);
        setFilename(filename);

        if (filename.toLower().endsWith(".prg")) {
            QString name;
            QByteArray data = readFile(name);
            if (data.size() > 2) {
                int loadAddress = data[0] | data[1] << 8;
                if (loadAddress == 0x4001) {
                    if (QMessageBox::question(this, QCoreApplication::applicationName(), tr("Load address $4001, probably wrong C128 load address\nDo you want to change it to $1c01?"),
                                              QMessageBox::Yes | QMessageBox::No, QMessageBox::Yes) == QMessageBox::Yes)
                    {
                        loadAddress = 0x1c01;
                    }
                }

                // use start address 0 for BASIC programs
                int startAddress = 0;
                if (loadAddress != 0x0801 && loadAddress != 0x0800 && loadAddress != 0x1c01) {
                    startAddress = loadAddress;
                }
                loadAddressEdit->setText(hexNumber4(loadAddress));
                startAddressEdit->setText(hexNumber4(startAddress));

                // test if C64 or C128 program
                if (loadAddress == 0x1c01) {
                    resetModeC64RadioButton->setChecked(false);
                    resetModeC128RadioButton->setChecked(true);
                } else {
                    resetModeC64RadioButton->setChecked(true);
                    resetModeC128RadioButton->setChecked(false);
                }
            }
        }
    }
}

static bool isBlock255(ByteArray block)
{
    for (size_t i = 0; i < block.size(); i++) if (block[i] != 0xff) return false;
    return true;
}

static void flashFile(QString name, QByteArray data, int startAddress)
{
    midiSendCommand(MIDI_COMMAND_REDRAW_SCREEN);

    midiSendNopCommand();
    midiSendPrintCommand("erasing..." + NEWLINE);
    midiSendNopCommand();

    // first erase all sectors
    int full = data.size();
    int transferred = 0;
    int oldPercent = -1;
    int address = startAddress;
    while (transferred < data.size()) {
        int c64Address = (address & 0x1fff) | 0x8000;
        if ((c64Address & 0x0fff) == 0) {
            midiSendWordCommand(MIDI_COMMAND_SET_ADDRESS, c64Address);
            midiSendCommand(MIDI_COMMAND_SET_FLASH_BANK, { address >> 13 });
            midiSendCommand(MIDI_COMMAND_ERASE_FLASH_SECTOR);
            midiSendNopCommand();
        }
        int size = data.size();
        if (size > 256) size = 256;
        address += 0x100;
        transferred += size;
        int percent = transferred * 100 / full;
        if (percent > 100) percent = 100;
        if (percent != oldPercent && ((c64Address & 0x0fff) == 0)) {
            midiSendCommand(MIDI_COMMAND_GOTOX, { 0 });
            midiSendPrintCommand(QString("").sprintf("%i%%", percent));
            oldPercent = percent;
            midiSendNopCommand();
        }
    }
    midiSendCommand(MIDI_COMMAND_GOTOX, { 0 });
    midiSendPrintCommand("100%");

    // then flash all blocks, which are not erased (all 0xff)
    midiSendNopCommand();
    midiSendPrintCommand(NEWLINE + NEWLINE + "flashing " + name.left(20) + "..." + NEWLINE);
    midiSendNopCommand();

    full = data.size();
    transferred = 0;
    oldPercent = -1;
    address = startAddress;
    while (data.size() > 0) {
        int c64Address = (address & 0x1fff) | 0x8000;
        int size = data.size();
        if (size > 256) size = 256;
        ByteArray block;
        for (int j = 0; j < size; j++) block.push_back(data[j]);
        while (block.size() < 256) block.push_back(0xff);
        if (!isBlock255(block)) {
            midiSendWordCommand(MIDI_COMMAND_SET_ADDRESS, c64Address);
            midiSendCommand(MIDI_COMMAND_SET_FLASH_BANK, { address >> 13 });
            midiSendCommand(MIDI_COMMAND_WRITE_FLASH, block);
            midiSendNopCommand();
            int percent = transferred * 100 / full;
            if (percent > 100) percent = 100;
            if (percent != oldPercent) {
                midiSendCommand(MIDI_COMMAND_GOTOX, { 0 });
                midiSendPrintCommand(QString("").sprintf("%i%%", percent));
                oldPercent = percent;
                midiSendNopCommand();
            }
        }
        data.remove(0, size);
        address += 0x100;
        transferred += size;
    }
    midiSendCommand(MIDI_COMMAND_GOTOX, { 0 });
    midiSendPrintCommand("100%");

    midiSendNopCommand();
    midiSendPrintCommand(NEWLINE);
    midiSendPrintCommand("flash done" + NEWLINE);
}

/*
static void flashCompare(QString name, QByteArray data, int startAddress)
{
    midiSendCommand(MIDI_COMMAND_REDRAW_SCREEN);
    midiSendNopCommand();
    midiSendPrintCommand("flash cmp " + name.left(20) + "..." + NEWLINE);
    midiSendNopCommand();
    int full = data.size();
    int transferred = 0;
    int oldPercent = -1;
    while (data.size() > 0) {
        int c64Address = (startAddress & 0x1fff) | 0x8000;
        midiSendWordCommand(MIDI_COMMAND_SET_ADDRESS, c64Address);
        midiSendCommand(MIDI_COMMAND_SET_FLASH_BANK, { startAddress >> 13 });
        int size = data.size();
        if (size > 256) size = 256;
        ByteArray block;
        for (int j = 0; j < size; j++) block.push_back(data[j]);
        while (block.size() < 256) block.push_back(0xff);
        midiSendCommand(MIDI_COMMAND_COMPARE_FLASH, block);
        data.remove(0, size);
        startAddress += 0x100;
        transferred += size;
        int percent = transferred * 100 / full;
        if (percent > 100) percent = 100;
        if (percent != oldPercent) {
            midiSendCommand(MIDI_COMMAND_GOTOX, { 0 });
            midiSendPrintCommand(QString("").sprintf("%i%%", percent));
            oldPercent = percent;
            midiSendNopCommand();
        }
    }

    midiSendNopCommand();
    midiSendPrintCommand(NEWLINE);
    midiSendPrintCommand("flash done" + NEWLINE);
}
*/

static void sramUpload(QString name, QByteArray data, int startBank)
{
    midiSendCommand(MIDI_COMMAND_REDRAW_SCREEN);
    midiSendNopCommand();
    midiSendPrintCommand("receiving " + name.left(20) + "..." + NEWLINE);
    midiSendNopCommand();
    midiSendWordCommand(MIDI_COMMAND_SET_ADDRESS, 0xdf00);
    int bank = startBank;
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
    midiSendPrintCommand(NEWLINE);
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
    g_midiOut.openPort(midiOutInterfacesComboBox->currentIndex());
}

void MainWindow::onSelectMidiInInterfaceName(QString name)
{
    setMidiInInterfaceName(name);
    g_midiIn.closePort();
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

void MainWindow::onClear()
{
    midiInDataTextEdit->clear();
}

QByteArray MainWindow::readFile(QString& name)
{
    // read file
    QString filename = fileEdit->text();
    QFile file(filename);
    name = QFileInfo(file).fileName();
    if (!file.open(QIODevice::ReadOnly)) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr("file open error"));
        return QByteArray();
    }
    QByteArray data = file.readAll();
    file.close();
    if (data.size() < 3) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr("file size too small, min 3 bytes"));
    }
    return data;
}

bool MainWindow::flashPrg()
{
    QString name;
    QByteArray data = readFile(name);
    if (data.size() == 0) return false;
    if (data.size() > 63486) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr("file size too big, max 63486 bytes"));
        return false;
    }
    if (!name.toLower().endsWith(".prg")) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr(".prg-file required for slot save"));
        return false;
    }

    // remove load address
    data.remove(0, 2);

    // calculate flash start address
    int slot = prgSlotSpinBox->value();
    int startAddress = slot * 0x10000 + 0x60000;

    // prepend header
    QByteArray header = createHeader(name, false, data.length());
    data.prepend(header);

    // flash data
    flashFile(name, data, startAddress);
    return true;
}

void MainWindow::onFlashPrg()
{
    flashPrg();
}

void MainWindow::onStartPrgFromSlot()
{
    QByteArray header = createHeader("", true, 0);
    ByteArray data;
    data.push_back(prgSlotSpinBox->value());
    for (int i = 0; i < 16; i++) {
        data.push_back(header[0x30 + i]);
    }
    midiSendCommand(MIDI_COMMAND_START_SLOT_PROGRAM, data);
}


// Reference: http://ist.uwaterloo.ca/~schepers/formats/CRT.TXT
typedef struct CartHeader_s
{
    // Cartridge signature "C64 CARTRIDGE" (padded with space chars)
    char signature[16];

    // File header length  ($00000040,  high/low)
    uint8_t headerLen[4];

    // Cartridge version (high/low, presently 01.00)
    uint8_t version[2];

    // Cartridge hardware type ($0000, high/low)
    uint8_t type[2];

    // Cartridge port EXROM line status (1 = active)
    uint8_t exromLine;

    // Cartridge port GAME line status (1 = active)
    uint8_t gameLine;

    // Reserved for future use (6 bytes)
    uint8_t reserved[6];

    // 32-byte cartridge name (uppercase,  padded with 0)
    char name[32];
}
CartHeader;


typedef struct BankHeader_s
{
    // Contained ROM signature "CHIP"
    char signature[4];

    // Total packet length, ROM image size + header (high/low format)
    uint8_t packetLen[4];

    // Chip type: 0 - ROM, 1 - RAM, no ROM data, 2 - Flash ROM
    uint8_t chipType[2];

    // Bank number ($0000 - normal cartridge) (?)
    uint8_t bank[2];

    // Starting load address (high/low format) (?)
    uint8_t loadAddr[2];

    // ROM image size (high/low format, typically $2000 or $4000)
    uint8_t romLen[2];
}
BankHeader;


typedef struct CartChip_s
{
    BankHeader header;

    // For a linked list of several chips
    struct CartChip_s* pNext;

    // Points to the chip data, size is contained in header
    uint8_t* pData;
}
CartChip;

/// This structure contains an EasyFlash address 00:0:0000
typedef struct EasyFlashAddr_s
{
    uint8_t     nSlot;
    uint8_t     nBank;
    uint8_t     nChip;
    uint16_t    nOffset;
}
EasyFlashAddr;

// "C64 CARTRIDGE   "
#define CART_SIGNATURE { 0x43, 0x36, 0x34, 0x20, 0x43, 0x41, 0x52, 0x54, 0x52, 0x49, 0x44, 0x47, 0x45, 0x20, 0x20, 0x20 }
#define CHIP_SIGNATURE { 0x43, 0x48, 0x49, 0x50 }
const char strCartSignature[16] = CART_SIGNATURE;
const char strChipSignature[4] = CHIP_SIGNATURE;

// These are the cartridge types from the file header
#define CART_TYPE_EASYFLASH       32

// Number of banks when using 2 * 512 kByte
#define FLASH_NUM_BANKS     64

// Mask to isolate the plain bank number
#define FLASH_BANK_MASK     (FLASH_NUM_BANKS - 1)

// Address of Low ROM Chip
#define ROM0_BASE           0x8000

// Address of High ROM Chip
#define ROM1_BASE           0xA000

// Address of High ROM when being in Ultimax mode
#define ROM1_BASE_ULTIMAX   0xE000

static QByteArray loadEapi()
{
    // load EAPI resource
    QFile file(":/eapi-sst39vf1681");
    QString name = QFileInfo(file).fileName();
    if (!file.open(QIODevice::ReadOnly)) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), "file open error");
        return QByteArray();
    }
    QByteArray data = file.readAll();
    file.close();

    // remove start address
    data.remove(0, 2);

    return data;
}

#define FLASH_WRITE_SIZE 256

// EAPI signature
static const unsigned char aEAPISignature[] =
{
    0x65, 0x61, 0x70, 0x69 /* "EAPI" */
};

// EAPI signature
static const unsigned char aEFNameSignature[] =
{
    0x65, 0x66, 0x2d, 0x6e, 0x41, 0x4d, 0x45, 0x3a /* "EF-Name:" */
};

#define EF_CART_NAME_LEN 16

static QString flashWriteBankFromFile(QByteArray& flash, uint8_t* data, uint8_t nBank, uint8_t nChip, uint16_t nSize)
{
    QString name = "";
    EasyFlashAddr addr;
    uint8_t  bReplaceEAPI;
    uint16_t nOffset;
    uint16_t nBytes;

    nOffset      = 0;
    bReplaceEAPI = 0;
    while (nSize) {
        nBytes = (nSize > FLASH_WRITE_SIZE) ? FLASH_WRITE_SIZE : nSize;

        addr.nSlot = 0;
        addr.nBank = nBank;
        addr.nChip = nChip;
        addr.nOffset = nOffset;

        // Check if EAPI has to be replaced
        if (nBank == 0 && nChip == 1) {
            if (nOffset == 0x1800 &&
                    memcmp(data, aEAPISignature, sizeof(aEAPISignature)) == 0)
                bReplaceEAPI = 1;
            if (nOffset == 0x1b00 &&
                    memcmp(data, aEFNameSignature, sizeof(aEFNameSignature)) == 0)
            {
                for (int i = 0; i < EF_CART_NAME_LEN; i++) {
                    char c = data[i];
                    if (c == 0) break;
                    name += c;
                }
            }
        }

        if (bReplaceEAPI) {
            QByteArray eapi = loadEapi();
            if (nOffset == 0x1800)
                memcpy(data, eapi.data(), 0x100);
            else if (nOffset == 0x1900)
                memcpy(data, eapi.data() + 0x100, 0x100);
            else if (nOffset == 0x1a00)
            {
                memcpy(data, eapi.data() + 0x200, 0x100);
                bReplaceEAPI = 0;
            }
        }

        // write to flash memory
        // bits 18-13
        int physicalAddress = addr.nBank << 13;
        // bits 12-0
        physicalAddress |= addr.nOffset & 0x1fff;
        // bit 19
        if (addr.nChip) physicalAddress |= 1 << 19;
        for (int i = 0; i < 256; i++) flash[physicalAddress + i] = data[i];
        data += nBytes;

        nSize -= nBytes;
        nOffset += nBytes;
    }

    return name;
}

void MainWindow::onFlashEasyFlashCrt()
{
    QString name;
    QByteArray data = readFile(name);
    if (!name.toLower().endsWith(".crt")) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr(".crt-file required for EasyFlash"));
        return;
    }
    if (data.size() == 0) return;
    if (data.size() < 0x50) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr("file size too small"));
        return;
    }

    // extract cart header
    CartHeader cartHeader;
    memcpy(&cartHeader, data.data(), sizeof(CartHeader));
    if (cartHeader.type[0] != 0 || cartHeader.type[1] != CART_TYPE_EASYFLASH || memcmp(cartHeader.signature, strCartSignature, sizeof(strCartSignature))) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr("unsupported CRT file format"));
        return;
    }

    // 1 MB flash memory
    QByteArray flash;
    flash.reserve(1024*1024);
    for (int i = 0; i < 1024*1024; i++) flash.append(char(0xff));

    // extract all bank blocks
    size_t pos = sizeof(CartHeader);
    while (pos < size_t(data.size())) {
        // copy and test bank header
        BankHeader bankHeader;
        if (pos + sizeof(BankHeader) > size_t(data.size())) {
            QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr("unsupported CRT file format"));
            return;
        }
        memcpy(&bankHeader, data.data() + pos, sizeof(BankHeader));
        pos += sizeof(BankHeader);
        if (memcmp(bankHeader.signature, strChipSignature, sizeof(strChipSignature)) != 0) {
            QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr("unsupported CRT file format"));
            return;
        }
        int m_nBank = bankHeader.bank[1] & FLASH_BANK_MASK;
        int m_nAddress = 256 * bankHeader.loadAddr[0] + bankHeader.loadAddr[1];
        int m_nSize = 256 * bankHeader.romLen[0] + bankHeader.romLen[1];

        // copy data
        if (pos + m_nSize > size_t(data.size())) {
            QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr("unsupported CRT file format"));
            return;
        }
        uint8_t* bankData = (uint8_t*) (data.data() + pos);
        if ((m_nAddress == ROM0_BASE) && (m_nSize <= 0x4000)) {
            if (m_nSize > 0x2000) {
                flashWriteBankFromFile(flash, bankData, m_nBank, 0, 0x2000);
                flashWriteBankFromFile(flash, bankData, m_nBank, 1, m_nSize - 0x2000);
            } else {
                flashWriteBankFromFile(flash, bankData, m_nBank, 0, m_nSize);
            }
        }
        else if (((m_nAddress == ROM1_BASE) ||
                  (m_nAddress == ROM1_BASE_ULTIMAX)) &&
                 (m_nSize <= 0x2000))
        {
            flashWriteBankFromFile(flash, bankData, m_nBank, 1, m_nSize);
        } else {
            QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr("unsupported CRT file format"));
            return;
        }
        pos += m_nSize;
    }

    // flash
    //flashCompare(name, flash, 1024*1024);
    flashFile(name, flash, 1024*1024);
}

void MainWindow::flashBasicKernal(QString flashName, int address)
{
    QString name;
    QByteArray data = readFile(name);
    if (!name.toLower().endsWith(".bin")) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), ".bin-file required for " + flashName + " flash");
        return;
    }
    if (data.size() == 0) return;
    if (data.size() > 8192) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr("wrong file size"));
        return;
    }
    flashFile(flashName, data, address);
}

void MainWindow::onFlashBasicBin()
{
    flashBasicKernal("BASIC", 0xc000);
}

void MainWindow::onFlashKernalBin()
{
    flashBasicKernal("KERNAL", 0xe000);
}

void MainWindow::onFlashMenuBin()
{
    QString name;
    QByteArray data = readFile(name);
    if (!name.toLower().endsWith(".bin")) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr(".bin-file required for menu update"));
        return;
    }
    if (data.size() == 0) return;
    if (data.size() < 256) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr("wrong file size"));
        return;
    }
    for (int i = 0; i < 16; i++) {
        if (g_kerberosMenuId[i] != data[0xf0 + i]) {
            QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr("invalid Kerberos menu file"));
            return;
        }
    }
    if (QMessageBox::question(this, QCoreApplication::applicationName(), tr("Are you sure to update the menu system?"),
                              QMessageBox::Yes | QMessageBox::No, QMessageBox::Yes) == QMessageBox::Yes)
    {
        flashFile(name, data, 0);
    }
}

QByteArray MainWindow::createHeader(QString name, bool ramOperation, int length)
{
    QByteArray header;

    // add ID
    for (int i = 0; i < 16; i++) header.append(char(g_kerberosPrgSlotId[i]));

    // add filename
    for (int i = 0; i < 32; i++) {
        if (name.size() > i && i < 32) {
            header.append(char(name[i].toLatin1()));
        } else {
            header.append(char(0));
        }
    }

    // add control byte
    uint8_t controlByte = 0;
    if (resetModeC128RadioButton->isChecked()) controlByte |= 1;
    if (customBasicCheckBox->isChecked()) {
        if (!ramOperation || (ramOperation && !customBasicFromRamCheckbox->isChecked())) {
            controlByte |= 1 << 1;
        }
    }
    if (customKernalCheckBox->isChecked()) {
        if (!ramOperation || (ramOperation && !customKernalFromRamCheckbox->isChecked())) {
            controlByte |= 1 << 2;
        }
    }
    controlByte |= 1 << 3;  // use global MIDI thru settings
    header.append(controlByte);

    // unused and init registers with 0
    for (int i = 0; i < 15; i++) header.append(char(0));

    // MIDI config
    uint8_t midiAddress = 0;
    uint8_t midiConfig = 0;
    switch (midiEmulationComboBox->currentIndex()) {

    // Sequential Circuits Inc.
    case 1:
        midiAddress = 0x02;
        midiConfig = MIDI_CONFIG_IRQ_ON | MIDI_CONFIG_NMI_OFF | MIDI_CONFIG_CLOCK_500_KHZ | MIDI_CONFIG_ENABLE_ON;
        break;

        // Passport & Syntech
    case 2:
        midiAddress = 0x88;
        midiConfig = MIDI_CONFIG_IRQ_ON | MIDI_CONFIG_NMI_OFF | MIDI_CONFIG_CLOCK_500_KHZ | MIDI_CONFIG_ENABLE_ON;
        break;

        // DATEL/Siel/JMS
    case 3:
        midiAddress = 0x46;
        midiConfig = MIDI_CONFIG_IRQ_ON | MIDI_CONFIG_NMI_OFF | MIDI_CONFIG_CLOCK_2_MHZ | MIDI_CONFIG_ENABLE_ON;
        break;

        // Namesoft
    case 4:
        midiAddress = 0x02;
        midiConfig = MIDI_CONFIG_IRQ_OFF | MIDI_CONFIG_NMI_ON | MIDI_CONFIG_CLOCK_500_KHZ | MIDI_CONFIG_ENABLE_ON;
        break;

    default:
        break;
    }
    if (midiThruInCheckBox->isChecked()) midiConfig |= MIDI_CONFIG_THRU_IN_ON;
    if (midiThruOutCheckBox->isChecked()) midiConfig |= MIDI_CONFIG_THRU_OUT_ON;
    header[int(&MIDI_ADDRESS) - 0xde00] = midiAddress;
    header[int(&MIDI_CONFIG) - 0xde00] = midiConfig;

    // cart control
    header[int(&CART_CONTROL) - 0xde00] = CART_CONTROL_GAME_HIGH | CART_CONTROL_EXROM_HIGH;

    // cart config
    int cartConfig = 0;
    if (customBasicCheckBox->isChecked() || customKernalCheckBox->isChecked()) {
        cartConfig |= CART_CONFIG_RAM_AS_ROM_ON;
    }
    if (customBasicCheckBox->isChecked()) {
        cartConfig |= CART_CONFIG_BASIC_HACK_ON;
    }
    if (customKernalCheckBox->isChecked()) {
        cartConfig |= CART_CONFIG_KERNAL_HACK_ON;
        if (kernalHiramHackCheckBox->isChecked()) {
            cartConfig |= CART_CONFIG_HIRAM_HACK_ON;
        }
    }
    header[int(&CART_CONFIG) - 0xde00] = cartConfig;

    // load address, start address and length
    uint16_t loadAddress = loadAddressEdit->text().toInt(NULL, 16);
    uint16_t startAddress = startAddressEdit->text().toInt(NULL, 16);
    header.append(uint8_t(loadAddress & 0xff));
    header.append(uint8_t(loadAddress >> 8));
    header.append(uint8_t(startAddress & 0xff));
    header.append(uint8_t(startAddress >> 8));
    header.append(uint8_t(length & 0xff));
    header.append(uint8_t(length >> 8));

    // fill and return header
    while (header.size() < 0x100) header.append(char(0));
    return header;
}

void MainWindow::onUploadAndRunPrg()
{
    QString name;
    QByteArray data = readFile(name);
    if (!name.toLower().endsWith(".prg")) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr(".prg-file required for PRG run"));
        return;
    }
    if (data.size() == 0) return;
    if (data.size() > 63486) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr("file size too big, max 63486 bytes"));
        return;
    }

    // remove load address
    data.remove(0, 2);

    // save size and address in first SRAM bank (at 0x10000)
    QByteArray header = createHeader(name, true, data.length());

    // program starts at second bank in SRAM (at 0x10100)
    data.prepend(header);

    // transfer data
    sramUpload(name, data, 256);

    // start program
    midiSendCommand(MIDI_COMMAND_START_SRAM_PROGRAM);
}

void MainWindow::uploadBasicKernal(QString flashName, int address)
{
    QString name;
    QByteArray data = readFile(name);
    if (!name.toLower().endsWith(".bin")) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), ".bin-file required for " + flashName + " flash");
        return;
    }
    if (data.size() == 0) return;
    if (data.size() > 8192) {
        QMessageBox::warning(NULL, QCoreApplication::applicationName(), tr("wrong file size"));
        return;
    }
    sramUpload(flashName, data, address >> 8);
}

void MainWindow::onUploadBasicToRam()
{
    uploadBasicKernal("BASIC", 0xa000);
}

void MainWindow::onUploadKernalToRam()
{
    uploadBasicKernal("KERNAL", 0xe000);
}

void MainWindow::onBackToBasic()
{
    // save size and address in first SRAM bank (at 0x10000)
    QString name = "BASIC";
    QByteArray header = createHeader(name, true, 0);

    // set load address 0 for special BASIC boot
    header[0x40] = 0;
    header[0x41] = 0;

    // transfer data
    sramUpload(name, header, 256);

    // start program
    midiSendCommand(MIDI_COMMAND_START_SRAM_PROGRAM);
}

void MainWindow::onOpenD64File()
{
    QString filename = QFileDialog::getOpenFileName(this, tr("Open D64"), getFilename(), tr("D64 file (*.d64)"));
    if (filename.size() > 0) {
        d64FileEdit->setText(filename);
        m_d64Filename = filename;

        // read directory
        D64Disk d64;
        d64.open(filename);
        d64.readDirectory();

        // show files in table
        int entriesCount = d64.getDirectoryEntries().size();
        QStandardItemModel* model = new QStandardItemModel(entriesCount, 3);
        for (int row = 0; row < entriesCount; ++row) {
            D64DirectoryEntry entry = d64.getDirectoryEntries()[row];
            QStandardItem* size = new QStandardItem(QString::number(entry.size));
            model->setItem(row, 0, size);
            QStandardItem* name = new QStandardItem(entry.name);
            model->setItem(row, 1, name);
            QStandardItem* type = new QStandardItem(entry.type);
            model->setItem(row, 2, type);
        }
        QStringList header;
        header.append("Blocks");
        header.append("Name");
        header.append("Type");
        model->setHorizontalHeaderLabels(header);
        d64DirectoryListingTableView->setModel(model);
        d64DirectoryListingTableView->verticalHeader()->hide();
        d64DirectoryListingTableView->resizeColumnsToContents();
        d64DirectoryListingTableView->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);
        d64DirectoryListingTableView->setSelectionBehavior(QAbstractItemView::SelectRows);
        d64DirectoryListingTableView->horizontalHeader()->setSectionResizeMode(0, QHeaderView::ResizeToContents);
        d64DirectoryListingTableView->horizontalHeader()->setSectionResizeMode(1, QHeaderView::Stretch);
        d64DirectoryListingTableView->horizontalHeader()->setSectionResizeMode(2, QHeaderView::ResizeToContents);

        // show title and free blocks
        d64DirectoryListingTitle->setText(d64.getDirectoryTitle());
        d64DirectoryListingFreeBlocks->setText(QString::number(d64.getDirectoryFreeBlocks()));
    }
}

void MainWindow::onSaveSettings()
{
    ByteArray configs;

    configs.push_back(KERBEROS_CONFIG_MIDI_IN_THRU);
    configs.push_back(midiThruInCheckBox->isChecked());

    configs.push_back(KERBEROS_CONFIG_MIDI_OUT_THRU);
    configs.push_back(midiThruOutCheckBox->isChecked());

    configs.push_back(KERBEROS_CONFIG_AUTOSTART_SLOT);
    configs.push_back(autostartSlotSpinBox->value());

    configs.push_back(KERBEROS_CONFIG_DRIVE_1);
    configs.push_back(disk1SpinBox->value());

    configs.push_back(KERBEROS_CONFIG_DRIVE_2);
    configs.push_back(disk2SpinBox->value());

    midiSendCommand(MIDI_COMMAND_CHANGE_CONFIG, configs);
}
