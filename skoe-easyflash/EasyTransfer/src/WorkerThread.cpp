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
#include <stdlib.h>
#include <stdint.h>

#include <ftdi.h>

#include "ef3xfer.h"
#include "WorkerThread.h"
#include "EasyTransferMainFrame.h"
#include "EasyTransferApp.h"

/*****************************************************************************/

WorkerThread* WorkerThread::m_pTheWorkerThread;

/*****************************************************************************/
WorkerThread::WorkerThread(wxEvtHandler* pEventHandler) :
    wxThread(wxTHREAD_JOINABLE), m_pEventHandler(pEventHandler),
            m_stringInputFileName(_T(""))
{
    m_pTheWorkerThread = this;
    ef3xfer_set_callbacks(LogText, LogProgress);
}

/*****************************************************************************/
WorkerThread::~WorkerThread()
{
    m_pTheWorkerThread = NULL;
}


/*****************************************************************************/
void* WorkerThread::Entry()
{
    uint16_t      crc;
    size_t        i, size;
    uint8_t*      p;

    if (m_stringTransferType == _("CRT"))
        ef3xfer_transfer_crt(m_stringInputFileName.mb_str());
    else if (m_stringTransferType == _("PRG"))
        ef3xfer_transfer_prg(m_stringInputFileName.mb_str());
    else if (m_stringTransferType == _("D64"))
        ef3xfer_d64_write(m_stringInputFileName.mb_str(), m_nDriveNumber, 1);
    else if (m_stringTransferType == _("USBTEST"))
        ef3xfer_usb_test();
    LogComplete();

    return NULL;
}


/*****************************************************************************/
void WorkerThread::LogText(const char* pStr)
{
    wxCommandEvent event(wxEVT_EASY_TRANSFER_LOG);
    event.SetString(wxString(pStr, wxConvUTF8));
    m_pTheWorkerThread->m_pEventHandler->AddPendingEvent(event);
}


/*****************************************************************************/
/*
 * Tell the main thread that we're done.
 */
void WorkerThread::LogComplete(void)
{
    wxCommandEvent event(wxEVT_EASY_TRANSFER_COMPLETE);
    m_pTheWorkerThread->m_pEventHandler->AddPendingEvent(event);
}


/*****************************************************************************/
/*
 * Tell the main thread that we're done.
 */
void WorkerThread::LogProgress(int percent, int b_gui_only)
{
    if (percent < 0)
        percent = 0;
    if (percent > 100)
        percent = 100;

    wxCommandEvent event(wxEVT_EASY_TRANSFER_PROGRESS);
    event.SetInt(percent);
    m_pTheWorkerThread->m_pEventHandler->AddPendingEvent(event);
}
