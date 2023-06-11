#!/bin/bash

cargo build --release
objcopy -O ihex target/thumbv6m-none-eabi/release/kerberos2 kerberos2.hex
JLinkExe -device RP2040_M0_0 -if swd -speed 4000 -AutoConnect 1 -CommanderScript flash.txt

