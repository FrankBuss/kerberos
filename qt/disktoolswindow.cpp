#include <stdint.h>
#include <QTimer>
#include <QVBoxLayout>
#include <QTextStream>
#include <QFile>
#include <QSettings>
#include <QFileDialog>
#include <QMessageBox>
#include <vector>
#include <map>
#include <initializer_list>
#include "disktoolswindow.h"
#include "../c64/src/midi_commands.h"

#define NEWLINE "\x0d\x0a"

using namespace std;

DiskToolsWindow::DiskToolsWindow(QWidget *parent) :
    QDialog(parent)
{
    setupUi(this);
    
    //QObject::connect(midiOutInterfacesComboBox, SIGNAL(activated(QString)), this, SLOT(onSelectMidiOutInterfaceName(QString)));

}

DiskToolsWindow::~DiskToolsWindow() {
}

