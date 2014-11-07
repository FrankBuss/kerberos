#ifndef TESTS_H
#define TESTS_H

#include <stdint.h>

// test all 128 kB of the RAM, return 1 if ok
uint8_t testRam();

// delete and test the 2 MB flash, return 1 if ok
uint8_t testFlash();

// test the special KERNAL hack etc. functions, return 1 if ok
uint8_t testRamAsRom();

#endif
