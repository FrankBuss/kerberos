#!/usr/bin/env python3

import serial
import time
import sys

# Open the serial port
ser = serial.Serial('/dev/ttyACM0')

# Clear the serial port in case there's anything pending
ser.flushInput()
ser.flushOutput()

b = 0
last = 0
bytes_to_write = []


def set_jtagsel(state):
    global b
    if state:
        b |= 1
    else:
        b &= ~1
    bytes_to_write.append(b)


def set_tck(state):
    global b
    if state:
        b |= 2
    else:
        b &= ~2
    bytes_to_write.append(b)


def set_tms(state):
    global b
    if state:
        b |= 4
    else:
        b &= ~4
    bytes_to_write.append(b)


def set_tdi(state):
    global b
    if state:
        b |= 0x10
    else:
        b &= ~0x10
    bytes_to_write.append(b)


def set_reconfig(state):
    global b
    if state:
        b |= 0x40
    else:
        b &= ~0x40
    bytes_to_write.append(b)


def transmit():
    # write output in chunks of 64 bytes
    global b, last, bytes_to_write
    b ^= 8
    bytes_to_write.append(b)
    while len(bytes_to_write) > 0:
        to_write = bytes_to_write[:64]
        ser.write(bytes(to_write))
        bytes_to_write = bytes_to_write[64:]
        bytes_from_serial = ser.read(len(to_write))
        last = bytes_from_serial[-1]


def read_tdo():
    global last
    transmit()
    return 1 if (last & 8) > 0 else 0

# https://vlsitutorialscom.files.wordpress.com/2020/01/jtag-operation-example.png


def strobe(tms_value):
    set_tms(tms_value)
    set_tck(1)
    set_tck(0)


set_jtagsel(0)


def jtag_reset():
    # Send a JTAG TAP reset
    for i in range(5):
        strobe(1)

    # Enter the Idle state
    strobe(0)


def jtag_send_instruction(instruction):
    # Send 8 bit instruction
    # From idle, we want to go to the Shift-IR state
    # The sequence is: Select-DR-Scan -> Select-IR-Scan -> Capture-IR -> Shift-IR
    strobe(1)
    strobe(1)
    strobe(0)
    strobe(0)

    # Now we can shift in the instruction (with TMS=0)
    # last bit with TMS=1 to move to Exit1-IR
    instruction = 0x11
    for i in range(8):
        set_tdi((instruction >> i) & 1)
        strobe(0 if i < 7 else 1)

    # Update-IR and then go back to idle
    strobe(1)
    strobe(0)


def jtag_send_msb_array(bytes):
    # Send byte array in MSB format
    # From idle, we want to go to the Shift-DR state
    # The sequence is: Select-DR-Scan -> Capture-DR
    strobe(1)
    strobe(0)

    # Now we can shift in the data (with TMS=0), first step transitions to Shift-DR state
    # Last bit with TMS=1 to move to Exit1-DR
    for i in range(len(bytes)):
        for j in range(8):
            set_tdi((bytes[i] >> (7 - i)) & 1)
            strobe(1 if j == 7 and i == len(bytes) - 1 else 0)

    # Update-DR and then go back to idle
    strobe(1)
    strobe(0)


def jtag_read_id():
    # Run 3 cycles in idle
    strobe(0)
    strobe(0)
    strobe(0)

    # Read 32 bit data
    # From idle, we want to go to the Shift-DR state
    # The sequence is: Select-DR-Scan -> Capture-DR
    strobe(1)
    strobe(0)

    # Now we can shift in the data (with TMS=0), first step transitions to Shift-DR state
    data = 0
    for i in range(31):
        strobe(0)
        data |= (read_tdo() << i)

    # Last bit with TMS=1 to move to Exit1-DR
    strobe(1)
    data |= (read_tdo() << 31)

    # Update-DR and then go back to idle
    strobe(1)
    strobe(0)
    return data


def erase_sram():
    jtag_reset()

    # ConfigEnable
    jtag_send_instruction(0x15)

    # SRAM Erase
    jtag_send_instruction(0x05)

    # Noop
    jtag_send_instruction(0x02)

    # delay 2 ms
    time.sleep(0.002)

    # SRAM Erase Done
    jtag_send_instruction(0x09)

    # Config Disable
    jtag_send_instruction(0x3a)

    # Noop
    jtag_send_instruction(0x02)

    # wait a second (not needed?)
    time.sleep(1)


def program_sram(bytes):
    # ConfigEnable
    jtag_send_instruction(0x15)

    # Address Initialize
    jtag_send_instruction(0x12)

    # Transfer Configuration Data
    jtag_send_instruction(0x17)

    # transfer data
    jtag_send_msb_array(bytes)

    # Config Disable
    jtag_send_instruction(0x3a)

    # Noop
    jtag_send_instruction(0x02)


def read_sram(address_size, address_count):
    byte = bytearray(address_size * address_count)


# verify ID
jtag_reset()
jtag_send_instruction(0x11)
id = jtag_read_id()
print("Gowin FPGA ID: 0x%08x" % id)
if id != 0x1100381b:
    print("wrong ID")
    sys.exit()

sys.exit()

# load program
with open('program.bin', 'rb') as f:
    program = bytearray(f.read())

# program SRAM
erase_sram()
program_sram(program)

# verify
address_size = 2296 / 8
address_count = 494

ser.close()
