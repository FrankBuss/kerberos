/*
 *
 * (c) 2011 Thomas Giesel
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

#ifdef __WXMAC__
#include <ApplicationServices/ApplicationServices.h>
#endif // __WXMAC__

#include <wx/wx.h>
#include <wx/icon.h>
#include <wx/stdpaths.h>
#include <wx/filename.h>
#include <wx/msgdlg.h>
#include <wx/cmdline.h>

#include "easytransfer.xpm"
#include "EasyTransferApp.h"

IMPLEMENT_APP(EasyTransferApp);

static const wxCmdLineEntryDesc aCmdLineDesc[] =
{
#if 0
     {
             wxCMD_LINE_SWITCH, wxT("h"), wxT("help"),
             wxT("display help on the command line parameters"),
             wxCMD_LINE_VAL_NONE, wxCMD_LINE_OPTION_HELP
     },
     {
             wxCMD_LINE_PARAM, NULL, NULL,
             wxT("filename"),
             wxCMD_LINE_VAL_STRING, wxCMD_LINE_OPTION_MANDATORY
     },
     {
             wxCMD_LINE_SWITCH, wxT("s"), wxT("silent"),
             wxT("disables the GUI")
     },
#endif
     { wxCMD_LINE_NONE }
};

/*****************************************************************************/
EasyTransferApp::EasyTransferApp()
{
#ifdef __WXMAC__
    ProcessSerialNumber psn;
    GetCurrentProcess(&psn);
    TransformProcessType(&psn, kProcessTransformToForegroundApplication);
#endif // __WXMAC__
}

/*****************************************************************************/
EasyTransferApp::~EasyTransferApp()
{
}

/*****************************************************************************/
bool EasyTransferApp::OnInit()
{
    size_t i;
    wxIcon icon(easytransfer_xpm);

    // call default behaviour (mandatory)
    if (!wxApp::OnInit())
        return false;

    m_pMainFrame = new EasyTransferMainFrame(NULL, _T("EasyTransfer " VERSION));
    m_pMainFrame->SetIcon(icon);
    m_pMainFrame->Show();
    SetTopWindow(m_pMainFrame);

    return true;
}


/*****************************************************************************/
void EasyTransferApp::OnInitCmdLine(wxCmdLineParser& parser)
{
    parser.SetDesc(aCmdLineDesc);
    // must refuse '/' as parameter starter or cannot use "/path" style paths
    parser.SetSwitchChars (wxT("-"));
}


/*****************************************************************************/
bool EasyTransferApp::OnCmdLineParsed(wxCmdLineParser& parser)
{
    //silent_mode = parser.Found(wxT("s"));

    // to get at your unnamed parameters use
    wxArrayString files;
    for (int i = 0; i < parser.GetParamCount(); i++)
    {
            files.Add(parser.GetParam(i));
    }

    // and other command line parameters

    // then do what you need with them.

    return wxApp::OnCmdLineParsed(parser);
    //return true; ??
}
