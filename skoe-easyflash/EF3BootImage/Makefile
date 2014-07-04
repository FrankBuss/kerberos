# BANK ROML             |  ROMH
# ==========================================
# 00   KERNAL0          |  Trampoline
# 01   KERNAL1          |
# 02   KERNAL2          |
# 03   KERNAL3          |
# 04   KERNAL4          |
# 05   KERNAL5          |
# 06   KERNAL6          |
# 07   KERNAL7          |
# ==========================================
# 08   <----------- Boot menu ------------->
# 09 \ <----------- EasyProg
# 0a /                       -------------->
# 0b   <----------- USB tool -------------->
# .                     .
# 0f <--------------- Sound --------------->
# ==========================================
# 10                    |   Action Replay
# .     Directory       |      Slot 0
# .     (64k reserved)  |      (64 k)
# 17                    |
# ==========================================
# 18    EF3 KERNAL      |   Action Replay
# .                     |      Slot 1
# .     Reserved        |      (64 k)
# 1f                    |
# ==========================================
# 20
# .              Super Snapsot
# .             (128 k reserved)
# 27
# ==========================================
# 28
# .            Final Cartridge III
# .                    (?)
# 2f
# ==========================================


# uncompressed version of EasyProg
easyprog    := ../EasyProg/easyprog

ifneq "$(release)" "yes"
	version := $(shell date +%y%m%d-%H%M)
else
	version := 1.2.0
endif

ifeq "$(variant)" "jb"
    prj := ef3-jb
else
    prj := ef3
endif

dirname := $(prj)-menu-init-$(version)

###############################################################################
#
.PHONY: all
ifeq "$(release)" "yes"
all: $(prj)-menu-init-$(version).zip
else
all: $(prj)-init.crt $(prj)-menu.crt
endif

$(dirname).zip: $(prj)-init.crt $(prj)-menu.crt CHANGES.txt README.txt
	rm -rf $(dirname)
	rm -f $@
	mkdir $(dirname)
	cp $(prj)-init.crt $(dirname)/$(prj)-init-$(version).crt
	cp $(prj)-menu.crt $(dirname)/$(prj)-menu-$(version).crt
	cp CHANGES.txt $(dirname)
	cp README.txt $(dirname)
	zip -v -r $@ $(dirname)

###############################################################################
# These files are in "menu" image and "initial" image

menu_image  := trampoline.bin                           0x00 0x1F00 H
menu_image  += efmenu/efmenu.bin                        0x08 0x0000 LH
menu_image  += $(easyprog)                              0x09 0x0000 LH
menu_image  += prgstart/prgstart.bin                    0x0b 0x0000 LH
#menu_image  += ef3kernal/out/ef3kernal_b0.bin           0x18 0x0000 L
#menu_image  += ef3kernal/out/ef3kernal_b1.bin           0x19 0x0000 L

#menu_image += waterdrop.raw        0x0f 0x0000
#menu_image += bing.raw        0x0f 0x0000


menu_deps   := trampoline.bin
menu_deps   += efmenu/efmenu.bin
menu_deps   += $(easyprog)
menu_deps   += prgstart/prgstart.bin
#menu_deps   += ef3kernal_phony

###############################################################################
# These files are in and "initial" image only

init_image :=

ifeq "$(variant)" "jb"
    init_image  += directory-jb.bin                     0x10 0x0000 L

    init_image  += images/kernal.901227-01.bin          0x00 0x0000 L
    init_image  += images/kernal.901227-02.bin          0x01 0x0000 L
    init_image  += images/kernal.901227-03.bin          0x02 0x0000 L
    init_image  += images/kernal.sx.251104-04.bin       0x03 0x0000 L

    init_image  += images/empty.bin                     0x10 0x0000 H
    init_image  += images/empty.bin                     0x18 0x0000 L
    init_image  += images/empty.bin                     0x18 0x0000 H
    init_image  += images/empty.bin                     0x20 0x0000 L
    init_image  += images/empty.bin                     0x20 0x0000 H
    init_image  += images/empty.bin                     0x30 0x0000 L
    init_image  += images/empty.bin                     0x30 0x0000 H
    init_image  += images/empty.bin                     0x38 0x0000 L
    init_image  += images/empty.bin                     0x38 0x0000 H
else
    init_image  += directory.bin                        0x10 0x0000 L

    init_image  += images/exos.bin                      0x00 0x0000 L
    init_image  += images/beast.bin                     0x01 0x0000 L
    init_image  += images/ttn2crom.bin                  0x02 0x0000 L

    init_image  += images/rr38ppal.bin                  0x10 0x0000 H
    #init_image += images/apower.bin                    0x18 0x0000 H
    init_image  += images/ar.bin                        0x18 0x0000 H

    init_image  += images/empty.bin                     0x18 0x0000 L
    #init_image += images/ss522-2-pal.bin               0x20 0x0000 LH
    init_image  += images/empty.bin                     0x20 0x0000 L
    init_image  += images/empty.bin                     0x20 0x0000 H
endif

init_image      += images/empty.bin                     0x28 0x0000 L
init_image      += images/empty.bin                     0x28 0x0000 H
init_image      += images/empty.bin                     0x30 0x0000 L
init_image      += images/empty.bin                     0x30 0x0000 H
init_image      += images/empty.bin                     0x38 0x0000 L
init_image      += images/empty.bin                     0x38 0x0000 H

###############################################################################
# The menu image: Contains menu and tools
#
$(prj)-menu.bin: $(menu_deps) mkimages | images/empty.bin
	./mkimages \
		$(menu_image) \
		$(prj)-menu.bin

###############################################################################
# The initial image: Contains menu, tools, some KERNALS and a directory
#
$(prj)-init.bin: $(menu_deps) mkimages \
              directory.bin directory-jb.bin | images/empty.bin
	./mkimages \
		$(menu_image) \
		$(init_image) \
		$(prj)-init.bin


###############################################################################
#
mkimages: mkimages.c
	$(CC) -o $@ $<

###############################################################################
#
images/empty.bin:
	rm -f $@
	touch $@

###############################################################################
#
efmenu/efmenu.bin: always
	$(MAKE) -C efmenu version=$(version)

.PHONY: always
always:

###############################################################################
#
#.PHONY: ef3kernal_phony
#ef3kernal_phony:
#	$(MAKE) -C ef3kernal release=$(release)

###############################################################################
#
prgstart/prgstart.bin: always
	$(MAKE) -C prgstart version=$(version)

###############################################################################
#
$(easyprog): always
	$(MAKE) -C $(dir $@) release=$(release)

###############################################################################
#
.PHONY: clean
clean:
	-rm -f mkimages
	-rm -f *-init.crt
	-rm -f *-init.bin
	-rm -f *-menu.crt
	-rm -f *-menu.bin
	-rm -f directory*.bin
	-rm -f trampoline.bin
	-rm -f images/empty.bin
	#-$(MAKE) -C ef3kernal clean
	-$(MAKE) -C efmenu clean
	-$(MAKE) -C prgstart clean
	-$(MAKE) -C $(dir $(easyprog)) clean

###############################################################################
# create a .crt image from a .bin image
#
%.crt: %.bin
	cartconv -t easy -i $< -o $@

###############################################################################
# create a plain .bin image from a .s file
#
%.bin: %.s
	acme -f plain -o $@ $<
