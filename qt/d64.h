#ifndef D64_H
#define D64_H

#include <vector>
#include <QString>

using namespace std;

#include "diskimage.h"

class D64DirectoryEntry {
public:
    QString type;
    int closed;
    int locked;
    int size;
    QString name;
};

typedef vector<D64DirectoryEntry> D64DirectoryEntryList;

class D64Disk {
public:
    D64Disk();
    ~D64Disk();
    bool open(DiskData* diskData);
    void close();
    bool readDirectory();
    D64DirectoryEntryList getDirectoryEntries() { return m_directoryEntries; }
    QString getDirectoryTitle() { return m_directoryTitle; }
    int getDirectoryFreeBlocks() { return m_directoryFreeBlocks; }

private:
    DiskImage* m_di;
    QString m_directoryTitle;
    D64DirectoryEntryList m_directoryEntries;
    int m_directoryFreeBlocks;
};

#endif
