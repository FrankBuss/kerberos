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

#ifndef WORKERTHREAD_H_
#define WORKERTHREAD_H_

#include <wx/wx.h>
#include <wx/thread.h>
#include <stdarg.h>
#include <stdint.h>

class WorkerThread : public wxThread
{
public:
    WorkerThread(wxEvtHandler* pEventHandler);
    virtual ~WorkerThread();

    void SetFileName(const wxString& str);
    void SetTransferType(const wxString& str);
    void SetDriveNumber(int nDriveNumber);

    static WorkerThread* m_pTheWorkerThread;
protected:
    virtual void* Entry();

    static void LogComplete(void);
    static void LogText(const char* pStr);
    static void LogProgress(int percent, int b_gui_only);

    wxEvtHandler* m_pEventHandler;
    wxString m_stringInputFileName;
    wxString m_stringTransferType;
    int      m_nDriveNumber;
};

/*****************************************************************************/
inline void WorkerThread::SetFileName(const wxString& str)
{
    m_stringInputFileName = str;
}

/*****************************************************************************/
inline void WorkerThread::SetTransferType(const wxString& str)
{
    m_stringTransferType = str;
}

/*****************************************************************************/
inline void WorkerThread::SetDriveNumber(int nDriveNumber)
{
    m_nDriveNumber = nDriveNumber;
}

#endif /* WORKERTHREAD_H_ */
