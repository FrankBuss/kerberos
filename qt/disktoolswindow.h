#ifndef DISKTOOLSWINDOW_H
#define DISKTOOLSWINDOW_H

#include <windows.h>
#include <QThread>
#include <QMutex>
#include <QMainWindow>
#include <vector>
#include <stdint.h>
#include "ui_disktoolswindowform.h"

using namespace std;

// DiskTools Window
class DiskToolsWindow : public QDialog, Ui_DiskToolsWindowForm
{
	Q_OBJECT

public:
	explicit DiskToolsWindow(QWidget *parent = 0);
	~DiskToolsWindow();

private slots:

private:
};

#endif
