/*
 * TabSpecial.h
 *
 *  Created on: 13.02.2012
 *      Author: skoe
 */

#ifndef TABSPECIAL_H_
#define TABSPECIAL_H_

#include <wx/panel.h>


class wxFilePickerCtrl;


class TabUSBTest: public wxPanel
{
public:
    TabUSBTest(wxWindow* parent);

protected:
    void OnButton(wxCommandEvent& event);
};

#endif /* TABSPECIAL_H_ */
