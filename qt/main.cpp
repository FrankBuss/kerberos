#include <QThread>
#include <QApplication>
#include <stdio.h>
#include <cmath>
#include <time.h>
#include "mainwindow.h"
#include "QDebug"

bool g_debugging = false;

int main(int argc, char** argv)
{
    QCoreApplication::setOrganizationName("Frank Buss");
    QCoreApplication::setOrganizationDomain("frank-buss.de");
    QCoreApplication::setApplicationName("Kerberos App");

    QApplication a(argc, argv);
    if (argc == 2) {
        if (strcmp(argv[1], "debugging") == 0) g_debugging = true;
    }
    MainWindow w;
	w.show();

	return a.exec();
}
