project webpage: https://frank-buss.de/kerberos/

# New Kerberos 2 design

See the kicad directory for the current schematic and board. [Here](kicad/kerberos2.pdf) is a PDF export of the current schematic.


# planned new features

- Mirror MIDI-in to thru and out

- USB MIDI device implementation

- USB host implementation for connecting USB keyboards, if possible

- SD-card for storing more programs and data


# Kerberos 2 parts

FPGA with 8 MB integrated RAM:
https://eu.mouser.com/ProductDetail/GOWIN-Semiconductor/GW1NR-LV4QN88C6-I5?qs=wnTfsH77Xs4Nd00MqWDpJw%3D%3D

16 MB flash:
https://lcsc.com/product-detail/NOR-FLASH_Winbond-Elec-W25Q128JVSIQ_C113767.html

Microcontroller for FPGA powerup sequencing, updating the flash, and booting the FPGA:
RP2040

USB-C connector:
https://lcsc.com/product-detail/USB-Connectors_XUNPU-TYPEC-304J-BCP16_C2835315.html

12 MHz oscillator:
https://lcsc.com/product-detail/Oscillators_Shenzhen-SCTF-Elec-SX3M12-000M20F30TNN_C2901561.html

Schottky Diode:
https://lcsc.com/product-detail/span-style-background-color-ff0-Schottky-span-Barrier-Diodes-SBD_MDD-Microdiode-Electronics-SS34_C8678.html

16 Bit Level Shifter:
https://lcsc.com/product-detail/Translators-Level-Shifters_Nexperia-74ALVC164245DGG-11_C5531.html

8 x 33 ohm resistor network:
https://lcsc.com/product-detail/Resistor-Networks-Arrays_UNI-ROYAL-Uniroyal-Elec-16P8WGF330JT4E_C422182.html

SD-card:
https://lcsc.com/product-detail/span-style-background-color-ff0-SD-span-span-style-background-color-ff0-Card-span-Connectors_MOLEX-5033981892_C428492.html

internal reset button:
https://lcsc.com/product-detail/Tactile-Switches_ALPSALPINE-SKRPADE010_C127488.html

optoisolator:
https://www.digikey.com/en/products/detail/liteon/6N138S/1969181?s=N4IgTCBcDaIIwDYAMBaOB2AnOlA5AIiALoC%2BQA


# credits
Gowin Kicad library:
https://github.com/devbisme/KiCad-Schematic-Symbol-Libraries

USB-C connector: EasyEDA library for this product:
https://lcsc.com/product-detail/USB-Connectors_XUNPU-TYPEC-304J-BCP16_C2835315.html
Converted to KiCad with this tool:
https://github.com/RigoLigoRLC/LC2KiCad
