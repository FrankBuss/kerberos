#ifndef LOG_H
#define LOG_H

#include <stdio.h>
#include <stdarg.h>

#include "WorkerThread.h"

enum log_level {
    LOG_MIN = -99,
    LOG_FATAL = -40,
    LOG_ERROR = -30,
    LOG_WARNING = -20,
    LOG_BRIEF = -10,
    LOG_NORMAL = 0,
    LOG_VERBOSE = 10,
    LOG_TRACE = 20,
    LOG_DEBUG = 30,
    LOG_DUMP = 40,
    LOG_MAX = 99
};

#define LOG(L,ARGS)         do { if (L <= LOG_NORMAL) WorkerThread_Log ARGS; } while(0)
#define IS_LOGGABLE(L)      0
#define LOG_SET_LEVEL(L)    do {} while(0)

#endif /* LOG_H */
