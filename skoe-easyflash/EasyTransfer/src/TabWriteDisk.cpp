/*
 * TabWriteDisk.cpp
 *
 *  Created on: 13.02.2012
 *      Author: skoe
 */

#include <wx/wx.h>
#include <wx/filepicker.h>
#include <wx/utils.h>

#include "EasyTransferMainFrame.h"
#include "WorkerThread.h"
#include "TabWriteDisk.h"


TabWriteDisk::TabWriteDisk(wxWindow* parent) :
    wxPanel(parent)
{
    wxFlexGridSizer*    pMainSizer;
    wxStaticText*       pText;
    wxString            str;
    wxArrayString       choices;
    int                 i;

    pMainSizer = new wxFlexGridSizer(5, 2, 8, 8);
    pMainSizer->AddGrowableCol(1);

    // Input file
    pText = new wxStaticText(this, wxID_ANY, _("Disk Image"));
    pMainSizer->Add(pText, 0,
                    wxALIGN_CENTER_VERTICAL | wxALIGN_RIGHT | wxALL, 10);

    m_pInputFilePicker = new wxFilePickerCtrl(this, wxID_ANY, wxEmptyString,
            _("Select a disk image"), _("*"), wxDefaultPosition, wxDefaultSize,
            wxFLP_USE_TEXTCTRL | wxFLP_OPEN | wxFLP_FILE_MUST_EXIST);
    m_pInputFilePicker->SetMinSize(wxSize(300, m_pInputFilePicker->GetMinSize().GetHeight()));
    pMainSizer->Add(m_pInputFilePicker, 1, wxEXPAND | wxALL, 10);

    // Drive number
    pText = new wxStaticText(this, wxID_ANY, _("Drive Number"));
    pMainSizer->Add(pText, 0,
                    wxALIGN_CENTER_VERTICAL | wxALIGN_RIGHT | wxALL, 10);
    for (i = 8; i < 16; ++i)
    {
        str = wxString::Format(_("Drive %d"), i);
        choices.Add(str);
    }
    m_pDriveNumberChoice = new wxChoice(this, wxID_ANY,
            wxDefaultPosition, wxDefaultSize, choices);
    m_pDriveNumberChoice->Select(0);
    pMainSizer->Add(m_pDriveNumberChoice, 1, wxALIGN_CENTER, 10);

    SetSizer(pMainSizer);
    pMainSizer->SetSizeHints(this);

    Connect(wxEVT_COMMAND_BUTTON_CLICKED, wxCommandEventHandler(TabWriteDisk::OnButton));
}

/*****************************************************************************/
void TabWriteDisk::OnButton(wxCommandEvent& event)
{
    EasyTransferMainFrame* pMainFrame;
    WorkerThread* pWorkerThread;

    pMainFrame = (EasyTransferMainFrame*) wxTheApp->GetTopWindow();
    pWorkerThread = pMainFrame->GetWorkerThread();

    pWorkerThread->SetFileName(m_pInputFilePicker->GetPath());
    pWorkerThread->SetTransferType(_("D64"));
    pWorkerThread->SetDriveNumber(m_pDriveNumberChoice->GetSelection() + 8);
    pMainFrame->DoIt();
}
