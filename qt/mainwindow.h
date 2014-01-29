#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <windows.h>
#include <QThread>
#include <QMutex>
#include <QMainWindow>
#include "ui_mainwindowform.h"

// Main Window
class MainWindow : public QMainWindow, Ui_MainWindowForm
{
	Q_OBJECT

public:
	explicit MainWindow(QWidget *parent = 0);
	~MainWindow();

private slots:
    void onSelectFile();
    void onUploadFile();
    void onNoteOn();
    void onNoteOff();
    void onSelectMidiInterfaceName(QString name);

private:
    QString getFilename();
    void setFilename(QString filename);
    QString getMidiInterfaceName();
    void setMidiInterfaceName(QString name);
};

#endif
