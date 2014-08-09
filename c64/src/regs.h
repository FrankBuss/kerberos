// address offset for MIDI read/write access from $de00.
#define MIDI_ADDRESS *((uint8_t*) 0xde39)

// MIDI configuration for MC68B50 and routing.
#define MIDI_CONFIG *((uint8_t*) 0xde3a)
#define MIDI_CONFIG_IRQ_OFF 0x00
#define MIDI_CONFIG_IRQ_ON 0x01
#define MIDI_CONFIG_NMI_OFF 0x00
#define MIDI_CONFIG_NMI_ON 0x02
#define MIDI_CONFIG_CLOCK_500_KHZ 0x00
#define MIDI_CONFIG_CLOCK_2_MHZ 0x04
#define MIDI_CONFIG_THRU_IN_OFF 0x00
#define MIDI_CONFIG_THRU_IN_ON 0x08
#define MIDI_CONFIG_THRU_OUT_OFF 0x00
#define MIDI_CONFIG_THRU_OUT_ON 0x10
#define MIDI_CONFIG_ENABLE_OFF 0x00
#define MIDI_CONFIG_ENABLE_ON 0x20

// Controls the GAME/EXROM levels, LEDs and software reset.
#define CART_CONTROL *((uint8_t*) 0xde3b)
#define CART_CONTROL_GAME_LOW 0x00
#define CART_CONTROL_GAME_HIGH 0x01
#define CART_CONTROL_EXROM_LOW 0x00
#define CART_CONTROL_EXROM_HIGH 0x02
#define CART_CONTROL_LED1_RX 0x00
#define CART_CONTROL_LED1_ON 0x04
#define CART_CONTROL_LED2_TX 0x00
#define CART_CONTROL_LED2_ON 0x08
#define CART_CONTROL_RESET_GENERATE 0x10

// RAM and mode configurations.
#define CART_CONFIG *((uint8_t*) 0xde3c)
#define CART_CONFIG_EASYFLASH_OFF 0x00
#define CART_CONFIG_EASYFLASH_ON 0x01
#define CART_CONFIG_RAM_AS_ROM_OFF 0x00
#define CART_CONFIG_RAM_AS_ROM_ON 0x02
#define CART_CONFIG_KERNAL_HACK_OFF 0x00
#define CART_CONFIG_KERNAL_HACK_ON 0x04
#define CART_CONFIG_BASIC_HACK_OFF 0x00
#define CART_CONFIG_BASIC_HACK_ON 0x08
#define CART_CONFIG_HIRAM_HACK_OFF 0x00
#define CART_CONFIG_HIRAM_HACK_ON 0x10

// Address bits 20..13 for flash.
#define FLASH_ADDRESS_EXTENSION *((uint8_t*) 0xde3d)

// Address bits 15..8 for RAM.
#define RAM_ADDRESS_EXTENSION *((uint8_t*) 0xde3e)

// More address bits.
#define ADDRESS_EXTENSION2 *((uint8_t*) 0xde3f)
#define ADDRESS_EXTENSION2_RAM_A16 0x01
#define ADDRESS_EXTENSION2_FLASH_A20 0x02
