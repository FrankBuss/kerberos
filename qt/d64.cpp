#include "d64.h"

D64Disk::D64Disk()
{
    m_di = NULL;
    m_directoryFreeBlocks = 0;
}

D64Disk::~D64Disk()
{
    close();
}

bool D64Disk::open(DiskData* diskData)
{
    if (m_di) close();
    if ((m_di = di_load_image(diskData)) == NULL) {
        return false;
    }
    return true;
}

void D64Disk::close()
{
    if (m_di) {
        di_free_image(m_di);
        m_di = NULL;
    }
}

void ptoa(unsigned char *s) {
    unsigned char c;

    while ((c = *s)) {
        c &= 0x7f;
        if (c >= 'A' && c <= 'Z') {
            c += 32;
        } else if (c >= 'a' && c <= 'z') {
            c -= 32;
        } else if (c == 0x7f) {
            c = 0x3f;
        }
        *s++ = c;
    }
}

bool D64Disk::readDirectory()
{
    static const char *ftype[] = {
        "del",
        "seq",
        "prg",
        "usr",
        "rel",
        "cbm",
        "dir",
        "???"
    };
    unsigned char buffer[254];
    ImageFile *dh;
    int offset;
    char name[17];
    char id[6];

    m_directoryEntries.clear();

    /* Open directory for reading */
    if ((dh = di_open(m_di, (const unsigned char*) "$", T_PRG, "rb")) == NULL) {
        // Couldn't open directory
        return false;
    }

    /* Convert title to ascii */
    di_name_from_rawname(name, di_title(m_di));
    ptoa((unsigned char*) name);

    /* Convert ID to ascii */
    memcpy(id, di_title(m_di) + 18, 5);
    id[5] = 0;
    ptoa((unsigned char*) id);

    /* Print title and disk ID */
    m_directoryTitle = name;

    /* Read first block into buffer */
    if (di_read(dh, buffer, 254) != 254) {
        // BAM read failed
        di_close(dh);
        return false;
    }

    /* Read directory blocks */
    while (di_read(dh, buffer, 254) == 254) {
        for (offset = -2; offset < 254; offset += 32) {

            /* If file type != 0 */
            if (buffer[offset+2]) {
                D64DirectoryEntry entry;
                di_name_from_rawname(name, buffer + offset + 5);
                entry.type = ftype[buffer[offset + 2] & 7];
                entry.closed = buffer[offset + 2] & 0x80;
                entry.locked = buffer[offset + 2] & 0x40;
                entry.size = buffer[offset + 31]<<8 | buffer[offset + 30];

                /* Convert to ascii */
                ptoa((unsigned char*) name);
                entry.name = name;

                m_directoryEntries.push_back(entry);
            }
        }
    }

    /* Print number of blocks free */
    m_directoryFreeBlocks = m_di->blocksfree;
    di_close(dh);

    return true;
}
