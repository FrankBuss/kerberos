
How to update the EasyFlash3 menu
=================================

This chapter describes how to update the EasyFlash3 software. The EasyFlash3
software consists of the EF3 menu and built it EasyProg. It is saved in EF3
cartridge's System Area (EasyFlash Slot 0). The software can be updated
without erasing any existing EasyFlash, KERNAL or freezer cartridge slots.

There are two images you can use to update the menu:

ef3-menu.crt
============

This image contains:

- The menu
- EasyProg

This is the file you should use to update an existing cartridge which has
already software on it.

ef3-init.crt
============

This image contains:

- The menu
- EasyProg
- Example KERNALs
- A directory which contains the KERNALs but is empty otherwise

This is the file you should use to initialize a new EasyFlash 3. If your
System Area got erased or overwritten, you can use this image to repair it.

How to write a Menu Image to Flash
==================================

Use EasyProg to write ef3-menu.crt or ef3-init.crt. Select Slot 0, confirm the
warning message and select the file. See Write a CRT to EF/EF3 with EasyProg.

In case the EF3 menu is not accessible (e.g. the System Area has been erased),
EasyProg can be loaded from a disk drive.
