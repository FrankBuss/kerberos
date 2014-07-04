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

#ifndef EASYTRANSFERMAINFRAME_H
#define EASYTRANSFERMAINFRAME_H

#include <wx/frame.h>

class wxSlider;
class wxButton;
class wxTextCtrl;
class wxGauge;
class wxNotebook;

class WorkerThread;

class TabStartPRG;
class TabWriteCRT;
class TabWriteDisk;
class TabUSBTest;

BEGIN_DECLARE_EVENT_TYPES()
    DECLARE_EVENT_TYPE(wxEVT_EASY_TRANSFER_LOG,      -1)
    DECLARE_EVENT_TYPE(wxEVT_EASY_TRANSFER_PROGRESS, -1)
    DECLARE_EVENT_TYPE(wxEVT_EASY_TRANSFER_COMPLETE, -1)
END_DECLARE_EVENT_TYPES()

class EasyTransferMainFrame: public wxFrame
{
public:
    EasyTransferMainFrame(wxFrame* parent,
            const wxString& title);

    void LoadDoc(const wxString& name);
    WorkerThread* GetWorkerThread();
    void DoIt();

protected:
    void EnableMyControls(bool bEnable);
    void OnButton(wxCommandEvent& event);
    void OnLog(wxCommandEvent& event);
    void OnProgress(wxCommandEvent& event);
    void OnComplete(wxCommandEvent& event);

    wxNotebook*         m_pNotebook;

    TabStartPRG*        m_pTabStartPRG;
    TabWriteCRT*        m_pTabWriteCRT;
    TabWriteDisk*       m_pTabWriteDisk;
    TabUSBTest*         m_pTabSpecial;

    wxButton*           m_pButtonStart;
    wxButton*           m_pButtonQuit;
    wxTextCtrl*         m_pTextCtrlLog;
    wxGauge*            m_pProgress;

    WorkerThread*       m_pWorkerThread;
};


#endif // EASYTRANSFERMAINFRAME_H
