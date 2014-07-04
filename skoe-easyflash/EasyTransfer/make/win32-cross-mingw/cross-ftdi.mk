#
# This software is provided 'as-is', without any express or implied
# warranty.  In no event will the authors be held liable for any damages
# arising from the use of this software.
#
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
#
# 1. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software
#    in a product, an acknowledgment in the product documentation would be
#    appreciated but is not required.
# 2. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
# 3. This notice may not be removed or altered from any source distribution.
#
# Thomas Giesel skoe@directbox.com
#

here := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
cross_ftdi_dir := $(here)

libusb_dir    := $(archive_dir)/libusb-1.0.9
libftdi_dir   := $(archive_dir)/libftdi-HEAD-a67c3be

# to be used in top-level Makefile
cxxflags      += -I $(tmp_install)/include/libusb-1.0
cxxflags      += -I $(tmp_install)/include/libftdi1
cflags        += -I $(tmp_install)/include/libusb-1.0
cflags        += -I $(tmp_install)/include/libftdi1
cxxlibs       += -L $(tmp_install)/lib -L $(tmp_install)/bin 
cxxlibs       += -l ftdi1 -lusb-1.0.dll
clibs         += -L $(tmp_install)/lib -L $(tmp_install)/bin 
clibs         += -l ftdi1 -lusb-1.0.dll

ftdiopt := -DDOCUMENTATION=OFF -DEXAMPLES=OFF -DFTDIPP=OFF -DFTDI_EEPROM=OFF
ftdiopt += -DPYTHON_BINDINGS=OFF

cmakeopt := -DCMAKE_TOOLCHAIN_FILE=$(cross_ftdi_dir)/Toolchain-$(host).cmake
cmakeopt += -DCMAKE_INSTALL_PREFIX=$(tmp_install)
cmakeopt += -DCMAKE_BUILD_TYPE=Release
cmakeopt += $(ftdiopt)
cmakeopt += -DLIBUSB_INCLUDE_DIR=$(tmp_install)/include/libusb-1.0
cmakeopt += -DLIBUSB_LIBRARIES=$(tmp_install)/lib/libusb-1.0.dll.a


###############################################################################
#
$(libusb_dir)/configure:
	cd $(archive_dir) && tar xjf $(libusb_dir).tar.bz2


###############################################################################
#
$(outbase)/libusb/Makefile: $(libusb_dir)/configure
	mkdir -p $(outbase)/libusb
	-make -C $(libusb_dir) distclean # wtf?
	cd $(outbase)/libusb && $(libusb_dir)/configure \
		--disable-static --enable-shared \
		--prefix=$(tmp_install) --host=$(host)
	

###############################################################################
#
.PHONY: libusb
libusb: $(outbase)/libusb.done

$(outbase)/libusb.done: $(outbase)/libusb/Makefile
	$(MAKE) -C $(outbase)/libusb install
	touch $@

###############################################################################
#
$(libftdi_dir)/CMakeLists.txt: libusb
	cd $(archive_dir) && tar xzf $(libftdi_dir).tar.gz


###############################################################################
#
.PHONY: libftdi
libftdi: $(outbase)/libftdi.done

$(outbase)/libftdi.done: $(libftdi_dir)/CMakeLists.txt
	mkdir -p $(outbase)/libftdi
	cd $(outbase)/libftdi && cmake $(cmakeopt) $(libftdi_dir)
	make -C $(outbase)/libftdi install
	touch $@
