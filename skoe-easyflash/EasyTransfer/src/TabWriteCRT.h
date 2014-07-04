/*
 * TabWriteCRT.h
 *
 *  Created on: 13.02.2012
 *      Author: skoe
 */

#ifndef TABWRITECRT_H_
#define TABWRITECRT_H_

#include <wx/wx.h>


class wxFilePickerCtrl;


class TabWriteCRT: public wxPanel
{
public:
    TabWriteCRT(wxWindow* parent);

protected:
    void OnButton(wxCommandEvent& event);

    wxFilePickerCtrl*   m_pInputFilePicker;

};

#endif /* TABWRITECRT_H_ */
