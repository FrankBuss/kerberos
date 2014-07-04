/*
 * str_to_key.h
 *
 *  Created on: 18.04.2012
 *      Author: skoe
 */

#ifndef STR_TO_KEY_H_
#define STR_TO_KEY_H_


/* Translate string constants to key buffer bytes */
typedef struct str_to_key_s
{
    const char*   str;
    unsigned char key;
} str_to_key_t;

extern const str_to_key_t str_to_key[];

#endif /* STR_TO_KEY_H_ */
