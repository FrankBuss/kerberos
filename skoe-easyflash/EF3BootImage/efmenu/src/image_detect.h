/*
 * image_detect.h
 *
 *  Created on: 17.07.2011
 *      Author: skoe
 */

#ifndef IMAGE_DETECT_H_
#define IMAGE_DETECT_H_

#include <stdint.h>
#include "efmenu.h"

#define IMAGE_SIGNATURE_LEN 8

typedef struct image_fingerprint_s
{
    uint16_t        offset;
    uint8_t         signature[IMAGE_SIGNATURE_LEN];
    const char*     name;
} image_fingerprint_t;


void detect_images(efmenu_entry_t* kernal_menu);

#endif /* IMAGE_DETECT_H_ */
