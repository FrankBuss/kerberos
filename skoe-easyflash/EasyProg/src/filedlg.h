
#ifndef FILEDLG_H
#define FILEDLG_H

#include <stdint.h>
#include <stdio.h>

// Current drive
extern uint8_t g_nDrive;

// File name of current file
extern char g_strFileName[FILENAME_MAX];

uint8_t __fastcall__ fileDlg(const char* pStrType);

#endif // FILEDLG_H
