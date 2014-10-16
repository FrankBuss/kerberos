#ifndef DISKDATA_H
#define DISKDATA_H

#include <stdint.h>
#include <QByteArray>
#include <QFile>

#define D64_FILE_SIZE 174848

class DiskData
{
public:
    virtual int getSize() = 0;
    virtual void save() = 0;
    virtual unsigned char* getData(int index) = 0;
};

class FileDiskData : public DiskData
{
public:
    FileDiskData();
    int getSize() { return m_data.size(); }
    bool load(QString filename);
    void save();
    virtual unsigned char* getData(int index) {
        return (unsigned char*) &m_data.data()[index];
    }

private:
    QByteArray m_data;
    QString m_filename;
};

class RemoteDiskData : public DiskData
{
public:
    RemoteDiskData();
    int getSize() { return D64_FILE_SIZE; }
    void save();
    virtual unsigned char* getData(int index);
    void setDriveType(int driveType) { m_driveType = driveType; }
    void setDriveNumber(int driveNumber) { m_driveNumber = driveNumber; }
    void init();

private:
    int m_driveType;
    int m_driveNumber;
    QByteArray m_data;
    QByteArray m_loadedData;
    QByteArray m_loadedBlocks;
};

#endif
