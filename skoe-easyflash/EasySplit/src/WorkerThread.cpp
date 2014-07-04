/*
 *
 * (c) 2003-2009 Thomas Giesel
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

#include <wx/wx.h>
#include <wx/file.h>
#include <wx/thread.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdint.h>

extern "C"
{
#   include "exo_helper.h"
#   include "membuf.h"
#   include "membuf_io.h"
#   include "crc16.h"
}

#include "WorkerThread.h"
#include "EasySplitMainFrame.h"
#include "EasySplitApp.h"

/*****************************************************************************/

WorkerThread* WorkerThread::m_pTheWorkerThread;

/*****************************************************************************/
WorkerThread::WorkerThread(wxEvtHandler* pEventHandler,
        const wxString& stringInputFileName,
        const wxString& stringOutputFileName, unsigned nSize1, unsigned nSizeN) :
    wxThread(wxTHREAD_JOINABLE), m_pEventHandler(pEventHandler),
            m_stringInputFileName(stringInputFileName), m_stringOutputFileName(
                    stringOutputFileName), m_nSize1(nSize1), m_nSizeN(nSizeN)
{
    m_pTheWorkerThread = this;
}

/*****************************************************************************/
WorkerThread::~WorkerThread()
{
    m_pTheWorkerThread = NULL;
}

/*****************************************************************************/
void WorkerThread::LogText(const wxString& str)
{
    wxCommandEvent event(wxEVT_EASY_SPLIT_LOG);
    event.SetString(str);
    event.SetInt(0);
    m_pEventHandler->AddPendingEvent(event);
}


/*****************************************************************************/
/*
 * Tell the main thread that we're done.
 */
void WorkerThread::LogComplete(void)
{
    wxCommandEvent event(wxEVT_EASY_SPLIT_LOG);

    event.SetInt(1); // done!

    m_pEventHandler->AddPendingEvent(event);
}


/*****************************************************************************/
void* WorkerThread::Entry()
{
    struct crunch_options options =
    { NULL, 65535, EASY_SPLIT_MAX_EXO_OFFSET, 0 };
    struct crunch_info info;
    struct membuf inbuf;
    struct membuf outbuf;
    uint16_t      crc;
    size_t        i, size;
    uint8_t*      p;

    WorkerThread_Log("Input:  %s\n",
            (const char*) m_stringInputFileName.mb_str());
    WorkerThread_Log("Output: %s.xx\n",
            (const char*) m_stringOutputFileName.mb_str());

    membuf_init(&inbuf);
    membuf_init(&outbuf);
    if (read_file(m_stringInputFileName.mb_str(), &inbuf))
    {
        LogComplete();
        return NULL;
    }


    crc  = 0xffff;   // start value
    p    = (uint8_t*) membuf_get(&inbuf);
    size = membuf_memlen(&inbuf);
    for (i = 0; i < size; ++i)
        crc = crc16_update(crc, p[i]);

    crunch(&inbuf, &outbuf, &options, &info);
    WorkerThread_Log("\n");

    if (SaveFiles((uint8_t*) membuf_get(&outbuf), membuf_memlen(&outbuf),
            size, crc))
    {
        WorkerThread_Log("\n\\o/\nREADY.\n\n");
    }

    membuf_free(&outbuf);
    membuf_free(&inbuf);

    LogComplete();

    return NULL;
}

/*****************************************************************************/
/**
 *
 */
bool WorkerThread::SaveFiles(uint8_t* pData, size_t len, size_t nOrigLen,
        uint16_t crc)
{
    wxFile *pFile;
    wxString str;
    int nRemaining; /* remaining bytes w/o header */
    int nSize; /* current file size w/o header */

    EasySplitHeader header =
    {
        { 0x65, 0x61, 0x73, 0x79, 0x73, 0x70, 0x6c, 0x74 } /* EASYSPLT */
    };

    nRemaining = len;

    header.len[0] = nOrigLen % 0x100;
    header.len[1] = nOrigLen / 0x100;
    header.len[2] = nOrigLen / 0x10000;
    header.len[3] = nOrigLen / 0x1000000;
    header.crc16[0] = crc & 0xff;
    header.crc16[1] = crc >> 8;

    /* find out how many files we're going to write */
    if (len <= m_nSize1 - sizeof(header))
        header.total = 1;
    else
        header.total =
                (len - (m_nSize1 - sizeof(header)) + (m_nSizeN - sizeof(header) - 1)) /
                        (m_nSizeN - sizeof(header)) +
                        1;

    for (header.part = 0; header.part < header.total; ++header.part)
    {
        if (header.part == 0)
            nSize = m_nSize1 - sizeof(header);
        else
            nSize = m_nSizeN - sizeof(header);

        if (nSize > nRemaining)
            nSize = nRemaining;

        str = m_stringOutputFileName;
        str.Append(wxString::Format(_(".%02x"), header.part + 1));
        WorkerThread_Log("Writing %u of %u bytes to %s...\n",
                nSize + sizeof(header), len + header.part * sizeof(header),
                (const char*) str.mb_str());

        pFile = new wxFile(str, wxFile::write);
        if (!pFile->IsOpened())
        {
            WorkerThread_Log("Error: Cannot open %s for writing\n",
                    (const char*) str.mb_str());
            delete pFile;
            return false;
        }

        if (pFile->Write((void*) &header, sizeof(header)) != sizeof(header)
                || pFile->Write((void*) pData, nSize) != nSize)
        {
            WorkerThread_Log("Error: Write to %s failed\n",
                    (const char*) str.mb_str());
            pFile->Close();
            delete pFile;
            return false;
        }

        pFile->Close();
        delete pFile;

        pData += nSize;

        nRemaining -= nSize;
    }
    return true;
}

/*****************************************************************************/
/**
 *
 */
void WorkerThread::Log(const char* pStrFormat, va_list args)
{
    char str[200];
    vsnprintf(str, sizeof(str) - 1, pStrFormat, args);
    str[sizeof(str) - 1] = '\0';

    LogText(wxString(str, wxConvUTF8));
}

/*****************************************************************************/
/**
 *
 */
extern "C" void WorkerThread_Log(const char* pStrFormat, ...)
{
    va_list args;

    if (WorkerThread::m_pTheWorkerThread)
    {
        va_start(args, pStrFormat);
        WorkerThread::m_pTheWorkerThread->Log(pStrFormat, args);
        va_end(args);
    }
}

