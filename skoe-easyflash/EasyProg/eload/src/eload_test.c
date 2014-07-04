/*
 * ELoad
 *
 * (c) 2011 Thomas Giesel
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 *
 * Thomas Giesel skoe@directbox.com
 */


#include <string.h>
#include <unistd.h>
#include <cbm.h>
#include <conio.h>

#include "eload.h"

#define TEST_DATA_SIZE       8192
#define ELOAD_TEST_FILE_NAME "eload-test-file"

static uint8_t test_data[TEST_DATA_SIZE];
static uint8_t read_data[TEST_DATA_SIZE];


static void create_test_data(void)
{
    unsigned i;
    for (i = 0; i < TEST_DATA_SIZE; ++i)
    {
        test_data[i] = i;
    }
}


static uint8_t get_drive_number(void)
{
    int drv;

    cputs("Enter drive number: ");
    cursor(1);
    cscanf("%d", &drv);
    cursor(0);
    cputs("\r\n");

    return drv;
}


static void test_write(void)
{
    uint8_t drv;

    cputs("Write test data\r\n");
    drv = get_drive_number();
    cputs("writing... ");

    if ((cbm_open(1, drv, 1, ELOAD_TEST_FILE_NAME ",p,w") == 0) &&
        (cbm_write(1, test_data, TEST_DATA_SIZE) == TEST_DATA_SIZE))
    {
        cbm_close(1);
        cputs("ok");
    }
    else
        cputs("error");

    while (kbhit())
        cgetc();
    cputs("\r\n\r\npress a key");
    cgetc();
}


static void test_read(void)
{
    unsigned loop, type, errors;
    uint8_t drv, bad;

    drv = get_drive_number();

    loop   = 0;
    errors = 0;
    while (!kbhit() || cgetc() != CH_STOP)
    {
        clrscr();
        cputs("\r\nRead test data\r\n");
        cputs("\r\npass:      $");
        cputhex16(loop);
        cputs("\r\nerrors:    $");
        cputhex16(errors);
        cputs("\r\n\nreference: $");
        cputhex16((unsigned)test_data);
        cputs("\r\nread to:   $");
        cputhex16((unsigned)read_data);
        cputs("\r\nsize:      $");
        cputhex16(TEST_DATA_SIZE);

        bad = 0;

        type = eload_set_drive_check_fastload(drv);
        cputs("\r\n\nDrive type found: 0x");
        cputhex8(type);
        cputs("\r\n");
        if (type == 0)
        {
            cputs("\r\nDevice not present");
            bad = 1;
        }
        else
        {
            memset(read_data, 0, TEST_DATA_SIZE);

            if (eload_open_read(ELOAD_TEST_FILE_NAME) != 0)
            {
                cputs("Failed to open test file\r\n");
                bad = 1;
            }
            else if (eload_read(read_data, TEST_DATA_SIZE) != TEST_DATA_SIZE)
            {
                cputs("Read error\r\n");
                bad = 1;
            }
            else if (memcmp(test_data, read_data, TEST_DATA_SIZE) != 0)
            {
                cputs("Verify error\r\n");
                bad = 1;
            }
            eload_close();
        }

        if (bad)
        {
            ++errors;
            sleep(1);
        }

        ++loop;
    }
}


int main(void)
{
    uint8_t key;

    create_test_data();

    do
    {
        clrscr();
        cputs("\r\nELoad Test Program\r\n\n");
        cputs(" W : Write test file to disk\r\n");
        cputs(" R : Read and verify test file\r\n");

        key = cgetc();
        if (key == 'w')
            test_write();
        else if (key == 'r')
            test_read();
    } while (key != CH_STOP);

    return 0;
}
