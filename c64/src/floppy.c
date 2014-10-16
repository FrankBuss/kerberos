/*
 
1541 block read/write test.
 
compile command line (with CC65, see http://www.cc65.org )

cl65 -O -t c64 floppy.c -o floppy.prg
 
*/

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>
#include <ctype.h>
#include <cbm.h>
#include <errno.h>

char* blockPointer0 = "b-p: 5 0";
char buf[16];

uint8_t readBlock(uint8_t device, uint8_t track, uint8_t sector, uint8_t* data)
{
	uint8_t err;
	
	// open command and data files
	err = cbm_open(2, device, 15, "");
	if (err) goto end;
	err = cbm_open(5, device, 5, "#");
	if (err) goto end;
	
	// load data from disk to floppy RAM
	sprintf(buf, "u1: 5 0 %i %i", track, sector);
	if (cbm_write(2, buf, strlen(buf)) < 0) {
		err = _oserror;
		goto end;
	}
		
	// set block pointer to 0
	if (cbm_write(2, blockPointer0, strlen(blockPointer0)) < 0) err = _oserror;

	// read floppy RAM
	if (cbm_read(5, data, 256) < 0) err = _oserror;
		
	// close files and return error status
end:	cbm_close(5);
	cbm_close(2);
	return err;
}

uint8_t writeBlock(uint8_t device, uint8_t track, uint8_t sector, uint8_t* data)
{
	uint8_t err;
	
	// open command and data files
	err = cbm_open(2, device, 15, "");
	if (err) goto end;
	err = cbm_open(5, device, 5, "#");
	if (err) goto end;
		
	// set block pointer to 0
	if (cbm_write(2, blockPointer0, strlen(blockPointer0)) < 0) err = _oserror;

	// write data to floppy RAM
	if (cbm_write(5, data, 256) < 0) {
		err = _oserror;
		goto end;
	}
	
	// write data in floppy RAM to disk
	sprintf(buf, "u2: 5 0 %i %i", track, sector);
	if (cbm_write(2, buf, strlen(buf)) < 0) err = _oserror;
		
	// close files and return error status
end:	cbm_close(5);
	cbm_close(2);
	return err;
}
