#include "../c64/src/midi_commands.h"
#include "diskdata.h"

extern void midiDriveSaveBlock(int driveType, int driveNumber, int block, QByteArray blockData);

extern QByteArray midiDriveLoadBlock(int driveType, int driveNumber, int block);

FileDiskData::FileDiskData()
{
}

bool FileDiskData::load(QString filename)
{
    m_filename = filename;
    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly)) {
        return false;
    }
    m_data = file.readAll();

    // only standard D64 is supported
    return m_data.size() == 174848;
}

void FileDiskData::save()
{

}

RemoteDiskData::RemoteDiskData()
{
    init();
}

void RemoteDiskData::init()
{
    m_driveType = DRIVE_IEC;
    m_driveNumber = 8;

    m_data.clear();
    m_loadedData.clear();
    m_loadedBlocks.clear();

    m_data.reserve(D64_FILE_SIZE);
    m_loadedData.reserve(D64_FILE_SIZE);
    m_loadedBlocks.reserve(D64_FILE_SIZE / 256);

    for (int i = 0; i < D64_FILE_SIZE; i++) {
        m_data.push_back((char)0);
        m_loadedData.push_back((char)0);
    }
    for (int i = 0; i < D64_FILE_SIZE / 256; i++) {
        m_loadedBlocks.push_back((char)0);
    }
}

void RemoteDiskData::save()
{
    /*
    for (int block = 0; block < D64_FILE_SIZE / 256; block++) {
        if (m_loadedBlocks[block]) {
            bool changed = false;
            int adr = block * 256;
            QByteArray blockData;
            blockData.reserve(256);
            for (int i = 0; i < 256; i++) {
                blockData.push_back((char)m_data[adr]);
                if (m_data[adr] != m_loadedData[adr]) {
                    changed = true;
                }
                adr++;
            }
            if (changed) {
                midiDriveSaveBlock(m_driveType, m_driveNumber, block, blockData);
            }
        }
    }
    */
}

unsigned char* RemoteDiskData::getData(int index)
{
    int block = index / 256;
    int adr = block * 256;
    if (!m_loadedBlocks[block]) {
        QByteArray blockData = midiDriveLoadBlock(m_driveType, m_driveNumber, block);
        for (int i = 0; i < 256; i++) {
            m_data[adr] = blockData[i];
            m_loadedData[adr] = blockData[i];
            adr++;
        }
        m_loadedBlocks[block] = 1;
    }
    return (unsigned char*) &m_data.data()[index];
}
