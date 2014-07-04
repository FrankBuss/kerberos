/*
 * EasySplit
 *
 * (c) 2003-2008 Thomas Giesel
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 *
 * Thomas Giesel skoe@directbox.com
 */

#ifndef MCAPP_H
#define MCAPP_H

#include <stdint.h>
#include <wx/app.h>
#include <list>

#include "EasySplitMainFrame.h"

/* This must fit to the buffer size of the decruncher in EasyProg */
#define EASY_SPLIT_MAX_EXO_OFFSET (16 * 256)

class PalettePanel;
class MCChildFrame;

class EasySplitApp : public wxApp
{
public:
    EasySplitApp();
    virtual ~EasySplitApp();
    virtual bool OnInit();

protected:
    EasySplitMainFrame*    m_pMainFrame;
};

DECLARE_APP(EasySplitApp)


/*****************************************************************************/
/*
 * An EasySplit file contains data which is compressed in the same way as
 * "exoraw -m 4096 -c" does it (exomizer 2 beta), i.e. max offset is 4k,
 * no literal sequences are used. The compressed data is split into several
 * files. Each of them has its own header.
 *
 * When the original file has a CBM-like start address, this is contained in
 * the encrypted data transparently.
 *
 * This is the header for an EasySplit file.
 */
typedef struct EasySplitHeader_s
{
    /* PETSCII EASYSPLT (hex 65 61 73 79 73 70 6c 74) */
    char    magic[8];

    /* uncompressed file size (little endian) */
    uint8_t len[4];

    /*
     * CRC-CCITT (start value 0xFFFF) of original file, little endian.
     * When unpacking, you should at least check if all parts contain the
     * same value to make sure not to mix parts of different files.
     */
    uint8_t crc16[2];

    /* Number of this part (0 = "*.01", 1 = "*.02"...) */
    uint8_t part;

    /* Total number of parts */
    uint8_t total;
}
EasySplitHeader;

#endif // MCAPP_H
