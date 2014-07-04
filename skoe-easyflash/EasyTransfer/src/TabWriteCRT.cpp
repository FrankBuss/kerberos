/*
 * TabWriteCRT.cpp
 *
 *  Created on: 13.02.2012
 *      Author: skoe
 */

#include <wx/wx.h>
#include <wx/filepicker.h>
#include <wx/utils.h>

#include "EasyTransferMainFrame.h"
#include "WorkerThread.h"
#include "TabWriteCRT.h"


TabWriteCRT::TabWriteCRT(wxWindow* parent) :
    wxPanel(parent)
{
    wxFlexGridSizer*    pMainSizer;
    wxStaticText*       pText;

    pMainSizer = new wxFlexGridSizer(5, 2, 8, 8);
    pMainSizer->AddGrowableCol(1);

    // Input file
    pText = new wxStaticText(this, wxID_ANY, _("Cartridge Image"));
    pMainSizer->Add(pText, 0,
                    wxALIGN_CENTER_VERTICAL | wxALIGN_RIGHT | wxALL, 10);

    m_pInputFilePicker = new wxFilePickerCtrl(this, wxID_ANY, wxEmptyString,
            _("Select a cartridge image"), _("*"), wxDefaultPosition, wxDefaultSize,
            wxFLP_USE_TEXTCTRL | wxFLP_OPEN | wxFLP_FILE_MUST_EXIST);
    m_pInputFilePicker->SetMinSize(wxSize(300, m_pInputFilePicker->GetMinSize().GetHeight()));
    pMainSizer->Add(m_pInputFilePicker, 1, wxEXPAND | wxALL, 10);

    SetSizer(pMainSizer);
    pMainSizer->SetSizeHints(this);

    Connect(wxEVT_COMMAND_BUTTON_CLICKED, wxCommandEventHandler(TabWriteCRT::OnButton));
}

/*****************************************************************************/
void TabWriteCRT::OnButton(wxCommandEvent& event)
{
    EasyTransferMainFrame* pMainFrame;
    WorkerThread* pWorkerThread;

    pMainFrame = (EasyTransferMainFrame*) wxTheApp->GetTopWindow();
    pWorkerThread = pMainFrame->GetWorkerThread();

    pWorkerThread->SetFileName(m_pInputFilePicker->GetPath());
    pWorkerThread->SetTransferType(_("CRT"));
    pMainFrame->DoIt();
}
