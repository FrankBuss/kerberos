#ifndef CONFIG_H
#define CONFIG_H

#include <stdint.h>


// config keys

// 1, if MIDI in is mirrored to MIDI thru
#define KERBEROS_CONFIG_MIDI_IN_THRU 1

// 1, if MIDI out is mirrored to MIDI thru
#define KERBEROS_CONFIG_MIDI_OUT_THRU 2

// autostart slot, 0 if no autostart
#define KERBEROS_CONFIG_AUTOSTART_SLOT 3

// drive number for internal disk drive 1
#define KERBEROS_CONFIG_DRIVE_1 4

// drive number for internal disk drive 2
#define KERBEROS_CONFIG_DRIVE_2 5

// end marker
#define KERBEROS_CONFIG_END 0xff


// functions

// load configs from flash to RAM
void loadConfigs(void);

// save configs from RAM to flash. Returns 1, if flash write was successful.
uint8_t saveConfigs(void);

// get a config value from RAM, or default, if not loaded
uint8_t getConfigValue(uint8_t key);

// set a config value in RAM
void setConfigValue(uint8_t key, uint8_t value);


#endif
