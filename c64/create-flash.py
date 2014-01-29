# creates the file flash.bin from menu and some PRGs

import binascii
import array
import struct

# output data array
outData = []

# add menu
menuFile = open('menu.bin', 'rb')
menuData = menuFile.read()
outData += menuData
menuFile.close()

# fill to 32768 bytes
while len(outData) < 32768:
	outData += [0]

# add PRGs
prgs = [ 
	"synthesizer-test.prg",
        "midi-out-test.prg",
	"basic-test.prg",
	"color-test.prg",
]
for prg in prgs:
	# magic byte
	data = [0x42]
	
	# filename
	for c in prg:
		data += [ord(c)]
	
	# fill filename with zeros
	while len(data) < 250:
		data += [0]

	# TODO: CRC16 checksum
	data += [0]
	data += [0]

	# load PRG file
	prgFile = open(prg, 'rb')
	prgData = prgFile.read()
	
	# length
	l = len(prgData) - 2
	data += [l & 0xff, (l >> 8) & 0xff]

	# PRG start and PRG data
	data += prgData
	
	# fill to 32768 bytes
	while len(data) < 32768:
		data += [0]

	# add to output
	outData += data
	
	prgFile.close()
	
# save flash
flash = open('flash.bin', 'wb')
flash.write(bytearray(outData))
flash.close()
