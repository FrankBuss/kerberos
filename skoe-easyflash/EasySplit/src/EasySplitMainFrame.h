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

#ifndef MCMAINFRAME_H
#define MCMAINFRAME_H

#include <wx/frame.h>

class wxSlider;
class wxFilePickerCtrl;
class wxFileDirPickerEvent;
class wxButton;
class wxTextCtrl;

class WorkerThread;

BEGIN_DECLARE_EVENT_TYPES()
    DECLARE_EVENT_TYPE(wxEVT_EASY_SPLIT_LOG, -1)
END_DECLARE_EVENT_TYPES()

class EasySplitMainFrame: public wxFrame
{
public:
    EasySplitMainFrame(wxFrame* parent,
            const wxString& title);

    void LoadDoc(const wxString& name);
    void FixFocus();

protected:
    void EnableMyControls(bool bEnable);
    void DoIt();
    void OnButton(wxCommandEvent& event);
    void OnLog(wxCommandEvent& event);
    void OnFilePickerChanged(wxFileDirPickerEvent& event);

    wxFilePickerCtrl*   m_pInputFilePicker;
    wxFilePickerCtrl*   m_pOutputFilePicker;
    wxSlider*           m_pSliderSize1;
    wxSlider*           m_pSliderSizeN;
    wxButton*           m_pButtonSize170k;
    wxButton*           m_pButtonSize800k;
    wxButton*           m_pButtonStart;
    wxButton*           m_pButtonQuit;
    wxTextCtrl*         m_pTextCtrlLog;

    WorkerThread*       m_pWorkerThread;
};


#endif // EasySplitMainFrame_H
