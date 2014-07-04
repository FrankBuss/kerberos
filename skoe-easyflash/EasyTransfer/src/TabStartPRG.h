/*
 * TabStartPRG.h
 *
 *  Created on: 13.02.2012
 *      Author: skoe
 */

#ifndef TABSTARTPRG_H_
#define TABSTARTPRG_H_

#include <wx/panel.h>


class wxFilePickerCtrl;


class TabStartPRG: public wxPanel
{
public:
    TabStartPRG(wxWindow* parent);

protected:
    void OnButton(wxCommandEvent& event);

    wxFilePickerCtrl*   m_pInputFilePicker;

};

#endif /* TABSTARTPRG_H_ */
