/*
 * TabSpecial.cpp
 *
 *  Created on: 13.02.2012
 *      Author: skoe
 */

#include <wx/wx.h>
#include <wx/utils.h>

#include "EasyTransferMainFrame.h"
#include "WorkerThread.h"
#include "TabUSBTest.h"

TabUSBTest::TabUSBTest(wxWindow* parent) :
    wxPanel(parent)
{
    wxBoxSizer*         pMainSizer;
    wxStaticText*       pText;
    const wxChar* texts[] =
    {
        _("First start EasyProg \"Expert => USB Test\"."),
        _("Then run this test with the button below."),
        NULL
    };

    pMainSizer = new wxBoxSizer(wxVERTICAL);

    for (int i = 0; texts[i] != NULL; ++i)
    {
        pText = new wxStaticText(this, wxID_ANY, texts[i], wxDefaultPosition, wxDefaultSize, wxALIGN_CENTRE);
        pMainSizer->Add(pText, 1, wxEXPAND | wxLEFT | wxTOP, 24);
    }
    pMainSizer->AddSpacer(24);

    SetSizer(pMainSizer);
    pMainSizer->SetSizeHints(this);

    Connect(wxEVT_COMMAND_BUTTON_CLICKED, wxCommandEventHandler(TabUSBTest::OnButton));
}


/*****************************************************************************/
void TabUSBTest::OnButton(wxCommandEvent& event)
{
    EasyTransferMainFrame* pMainFrame;
    WorkerThread* pWorkerThread;

    pMainFrame = (EasyTransferMainFrame*) wxTheApp->GetTopWindow();
    pWorkerThread = pMainFrame->GetWorkerThread();

    pWorkerThread->SetTransferType(_("USBTEST"));
    pMainFrame->DoIt();
}
