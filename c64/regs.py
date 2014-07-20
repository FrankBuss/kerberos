#!/bin/python3

import xml.etree.ElementTree as ET

regs = ET.parse('regs.xml')
root = regs.getroot()

print("text description")
print("==============================")
for reg in root:
	if reg.tag == 'reg':
		regName = reg.get('name')
		regAddress = int(reg.get('address'), 0)
		regDescription = reg.find('description').text
		print('%s (0x%04x, %i):' % (regName, regAddress, regAddress))
		print('')
		for child in reg:
			if child.tag == 'bits':
				bitsStart = int(child.get('start'), 0)
				bitsEnd = int(child.get('end'), 0)
				bitsName = regName + "_" + child.get('name')
				bitsDescription = child.find('description').text
				print('  bits %i..%i, %s: %s' % (bitsEnd, bitsStart, bitsName, bitsDescription))
				for case in child:
					if case.tag == 'case':
						caseValue = int(case.get('value'), 0)
						caseName = bitsName + "_" + case.get('name')
						caseDescription = case.find('description').text
						print('  %i, %s: %s' % (caseValue, caseName, caseDescription))
				print('')
			if child.tag == 'bit':
				bitPosition = int(child.get('position'), 0)
				bitName = regName + "_" + child.get('name')
				bitDescription = child.find('description').text
				print('  bit %i, %s: %s' % (bitPosition, bitName, bitDescription))
				for case in child:
					if case.tag == 'case':
						caseValue = int(case.get('value'), 0)
						caseName = bitName  + "_" + case.get('name')
						caseDescription = case.find('description').text
						print('  %i, %s: %s' % (caseValue, caseName, caseDescription))
				print('')
		print(regDescription)
		print('')
		print('')

print("VHDL bit constants")
print("==============================")
for reg in root:
	if reg.tag == 'reg':
		regName = reg.get('name')
		for child in reg:
			if child.tag == 'bit':
				bitPosition = int(child.get('position'), 0)
				bitName = regName + "_" + child.get('name')
				print('constant %s : integer := %i;' % (bitName, bitPosition))
print('')
print('')

print("VHDL registers")
print("==============================")
for reg in root:
	if reg.tag == 'reg':
		regName = reg.get('name')
		print('signal %s: std_logic_vector(7 downto 0);' % (regName.lower()))
print('')
print('')

print("C defines")
print("==============================")
for reg in root:
	if reg.tag == 'reg':
		regName = reg.get('name')
		regAddress = int(reg.get('address'), 0)
		regDescription = reg.find('description').text
		print('// %s' % (regDescription))
		print('#define %s *((uint8_t*) 0x%04x)' % (regName, regAddress))
		for child in reg:
			if child.tag == 'bit':
				bitPosition = int(child.get('position'), 0)
				bitName = regName + "_" + child.get('name')
				for case in child:
					if case.tag == 'case':
						caseValue = int(case.get('value'), 0)
						caseName = bitName  + "_" + case.get('name')
						caseDescription = case.find('description').text
						print('#define %s 0x%02x' % (caseName, caseValue << bitPosition))
		print('')
print('')
print('')

print("assembler defines")
print("==============================")
for reg in root:
	if reg.tag == 'reg':
		regName = reg.get('name')
		regAddress = int(reg.get('address'), 0)
		regDescription = reg.find('description').text
		print('; %s' % (regDescription))
		print('%s = $%04x' % (regName, regAddress))
		for child in reg:
			if child.tag == 'bit':
				bitPosition = int(child.get('position'), 0)
				bitName = regName + "_" + child.get('name')
				for case in child:
					if case.tag == 'case':
						caseValue = int(case.get('value'), 0)
						caseName = bitName  + "_" + case.get('name')
						caseDescription = case.find('description').text
						print('%s = $%02x' % (caseName, caseValue << bitPosition))
		print('')
