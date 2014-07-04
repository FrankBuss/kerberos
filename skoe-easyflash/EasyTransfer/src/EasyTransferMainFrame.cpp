/*
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

#include <wx/wx.h>
#include <wx/button.h>
#include <wx/slider.h>
#include <wx/filepicker.h>
#include <wx/notebook.h>
#include <wx/gauge.h>

#include "EasyTransferApp.h"
#include "EasyTransferMainFrame.h"
#include "WorkerThread.h"

#include "TabStartPRG.h"
#include "TabWriteCRT.h"
#include "TabWriteDisk.h"
#include "TabUSBTest.h"


DEFINE_EVENT_TYPE(wxEVT_EASY_TRANSFER_LOG)
DEFINE_EVENT_TYPE(wxEVT_EASY_TRANSFER_PROGRESS)
DEFINE_EVENT_TYPE(wxEVT_EASY_TRANSFER_COMPLETE)

/*****************************************************************************/
/*
 * -pOuterSizer---------------------------------------------------
 * |                                                             |
 * | -pMainSizer------------------------------------------------ |
 * | |                            |                            | |
 * | --------------------------------------------------------- | |
 * | |                            |                            | |
 * | ----------------------------------------------------------- |
 * |                                                             |
 * | -pButtonSizer---------------------------------------------- |
 * | | m_pButtonQuit              | m_pButtonStart             | |
 * | ----------------------------------------------------------- |
 * |                                                             |
 * |                        m_pTextCtrlLog                       |
 * ---------------------------------------------------------------
 */
EasyTransferMainFrame::EasyTransferMainFrame(wxFrame* parent, const wxString& title) :
    wxFrame(parent, wxID_ANY, title, wxDefaultPosition, wxSize(800, 700),
            wxDEFAULT_FRAME_STYLE),
    m_pWorkerThread(NULL)
{
    wxStaticText*       pText;
    wxBoxSizer*         pOuterSizer;
    wxFlexGridSizer*    pMainSizer;
    wxBoxSizer*         pButtonSizer;

    wxPanel *pPanel = new wxPanel(this, wxID_ANY, wxDefaultPosition,
            wxDefaultSize, wxTAB_TRAVERSAL);

    pOuterSizer = new wxBoxSizer(wxVERTICAL);

    m_pNotebook = new wxNotebook(pPanel, wxID_ANY);
    pOuterSizer->Add(m_pNotebook, 0, wxEXPAND | wxALL, 20);

    m_pTabStartPRG = new TabStartPRG(m_pNotebook);
    m_pNotebook->AddPage(m_pTabStartPRG, wxT("Start PRG"));

    m_pTabWriteCRT = new TabWriteCRT(m_pNotebook);
    m_pNotebook->AddPage(m_pTabWriteCRT, wxT("Write CRT"));

    m_pTabWriteDisk = new TabWriteDisk(m_pNotebook);
    m_pNotebook->AddPage(m_pTabWriteDisk, wxT("Write Disk"));

    m_pTabSpecial = new TabUSBTest(m_pNotebook);
    m_pNotebook->AddPage(m_pTabSpecial, wxT("USB Test"));

    pMainSizer = new wxFlexGridSizer(5, 2, 8, 8);
    pMainSizer->AddGrowableCol(1);
    pOuterSizer->Add(pMainSizer, 0, wxEXPAND | wxALL, 20);

    // Progress
    pText = new wxStaticText(pPanel, wxID_ANY, _("Progress"));
    pMainSizer->Add(pText, 0, wxALIGN_CENTER_VERTICAL | wxALIGN_RIGHT);
    m_pProgress = new wxGauge(pPanel, wxID_ANY, 100);
    pMainSizer->Add(m_pProgress, 1, wxEXPAND);

    pMainSizer->AddSpacer(10);

    // Start Button etc.
    pButtonSizer = new wxBoxSizer(wxHORIZONTAL);
    pOuterSizer->Add(pButtonSizer, 0, wxALIGN_CENTER_HORIZONTAL);
    m_pButtonQuit = new wxButton(pPanel, wxID_ANY, _("Quit"));
    pButtonSizer->Add(m_pButtonQuit, 0, wxALIGN_CENTER_HORIZONTAL);
    pButtonSizer->AddSpacer(20);
    m_pButtonStart = new wxButton(pPanel, wxID_ANY, _("Go!"));
    pButtonSizer->Add(m_pButtonStart, 0, wxALIGN_CENTER_HORIZONTAL);

    // Text Control for Log
    pOuterSizer->AddSpacer(10);
    m_pTextCtrlLog = new wxTextCtrl(pPanel, wxID_ANY, _(""), wxDefaultPosition, wxDefaultSize, wxTE_MULTILINE | wxTE_READONLY);
    m_pTextCtrlLog->SetMinSize(wxSize(500, 200));
    //m_pTextCtrlLog->
    pOuterSizer->Add(m_pTextCtrlLog, 1, wxEXPAND | wxALL);

    pPanel->SetSizer(pOuterSizer);
    pOuterSizer->SetSizeHints(this);

    Connect(wxEVT_COMMAND_BUTTON_CLICKED, wxCommandEventHandler(EasyTransferMainFrame::OnButton));

    Connect(wxEVT_EASY_TRANSFER_LOG,      wxCommandEventHandler(EasyTransferMainFrame::OnLog));
    Connect(wxEVT_EASY_TRANSFER_PROGRESS, wxCommandEventHandler(EasyTransferMainFrame::OnProgress));
    Connect(wxEVT_EASY_TRANSFER_COMPLETE, wxCommandEventHandler(EasyTransferMainFrame::OnComplete));
}


/*****************************************************************************/
void EasyTransferMainFrame::OnButton(wxCommandEvent& event)
{
    wxWindow* pWindow;

    if (event.GetEventObject() == m_pButtonStart)
    {
        /*if (m_pInputFilePicker->GetPath().size())
            DoIt();*/
        pWindow = m_pNotebook->GetCurrentPage();
        if (pWindow)
        {
            pWindow->AddPendingEvent(event);
        }
    }
    else if (event.GetEventObject() == m_pButtonQuit)
    {
        /*if (m_pWorkerThread)
        {
            m_pWorkerThread->Kill();
            delete m_pWorkerThread;
            m_pWorkerThread = NULL;
        }*/
        Close();
    }
}


/*****************************************************************************/
void EasyTransferMainFrame::OnLog(wxCommandEvent& event)
{
    m_pTextCtrlLog->AppendText(event.GetString());
}


/*****************************************************************************/
void EasyTransferMainFrame::OnProgress(wxCommandEvent& event)
{
    int i = event.GetInt();

    if (i >= 0 && i <= 100)
    {
        m_pProgress->SetValue(i);
    }
}


/*****************************************************************************/
void EasyTransferMainFrame::OnComplete(wxCommandEvent& event)
{
    EnableMyControls(true);
    if (m_pWorkerThread)
    {
        m_pWorkerThread->Wait();
        delete m_pWorkerThread;
        m_pWorkerThread = NULL;
    }
}


/*****************************************************************************/
void EasyTransferMainFrame::EnableMyControls(bool bEnable)
{
    m_pNotebook->Enable(bEnable);
    m_pButtonStart->Enable(bEnable);
}


/*****************************************************************************/
WorkerThread* EasyTransferMainFrame::GetWorkerThread()
{
    if (!m_pWorkerThread)
    {
        m_pWorkerThread = new WorkerThread(this);
    }

    return m_pWorkerThread;
}


/*****************************************************************************/
void EasyTransferMainFrame::DoIt()
{
    if (m_pWorkerThread && m_pWorkerThread->IsRunning())
    {
        return;
    }
    else
    {
        EnableMyControls(false);

        m_pTextCtrlLog->SetValue(_(""));
        m_pWorkerThread->Create();
        m_pWorkerThread->Run();
    }
}

