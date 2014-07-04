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

#ifdef __cplusplus
#include <wx/wx.h>
#include <wx/thread.h>
#include <stdarg.h>
#include <stdint.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif
void WorkerThread_Log(const char* pStrFormat, ...);
#ifdef __cplusplus
}
#endif

#ifdef __cplusplus

class WorkerThread : public wxThread
{
public:
    WorkerThread(wxEvtHandler* pEventHandler, const wxString& stringInputFileName,
            const wxString& stringOutputFileName, unsigned nSize1, unsigned nSizeN);
    virtual ~WorkerThread();

    void Log(const char* pStrFormat, va_list args);
    void LogComplete(void);

    static WorkerThread* m_pTheWorkerThread;
protected:
    virtual void* Entry();
    void LogText(const wxString& str);
    bool SaveFiles(uint8_t* pData, size_t len, size_t nOrigLen, uint16_t crc);

    wxEvtHandler* m_pEventHandler;
    wxString m_stringInputFileName;
    wxString m_stringOutputFileName;
    unsigned m_nSize1;
    unsigned m_nSizeN;
};

#endif /* __cplusplus */

#endif /* WORKERTHREAD_H_ */
