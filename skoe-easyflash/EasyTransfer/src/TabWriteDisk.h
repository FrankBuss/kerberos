/*
 * TabWriteDisk.h
 *
 *  Created on: 13.02.2012
 *      Author: skoe
 */

#ifndef TABWRITEDISK_H_
#define TABWRITEDISK_H_

#include <wx/wx.h>


class wxFilePickerCtrl;


class TabWriteDisk: public wxPanel
{
public:
    TabWriteDisk(wxWindow* parent);

protected:
    void OnButton(wxCommandEvent& event);

    wxFilePickerCtrl*   m_pInputFilePicker;
    wxChoice*           m_pDriveNumberChoice;

};

#endif /* TABWRITEDISK_H_ */
