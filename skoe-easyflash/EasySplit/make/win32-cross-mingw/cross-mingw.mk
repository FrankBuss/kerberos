#
# MultiColor - An image manipulation tool for Commodore 8-bit computers'
#              graphic formats
#
# (c) 2003-2009 Thomas Giesel
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

# information taken from:
# http://ubuntuforums.org/showthread.php?t=998561&page=2

mingw-build-dir := $(here)/mingw-build
archive-dir     := $(here)/archive

binutils  := binutils-2.20
gcc       := gcc-4.3.4
mingwrt   := mingwrt-3.16-mingw32
w32api    := w32api-3.13-mingw32

cross     := i686-pc-mingw32
gccprefix := /opt/cross/$(cross)-$(gcc)

mingwdll  := $(gccprefix)/$(cross)/bin/mingwm10.dll

sudo      := sudo

path      := $(gccprefix)/bin:$(path)

.PHONY: install-mingw
install-mingw: $(mingw-build-dir)/7-gcc-full.done $(mingw-build-dir)/8-directx.done

###############################################################################
# Rules to check the cross compiling environment
#
.PHONY: check-mingw
check-mingw:
	$(gccprefix)/bin/$(cross)-c++ --version > /dev/null || $(MAKE) no-mingw

.PHONY: no-mingw
no-mingw:
	$(warning ========================================================================)
	$(warning No $(cross) toolchain found.)
	$(warning )
	$(warning This could mean that it is not installed or not at the place we look at:)
	$(warning /opt/cross/$(cross)-$(gcc))
	$(warning )
	$(warning If you have a suitable toolchain installed, you may want to adapt)
	$(warning the path in this makefile.)
	$(warning )
	$(warning However, it's recommended to build it with this makefile, it uses a path)
	$(warning which is unlikely to collide with other versions. Otherwise it may)
	$(warning become a pain in the ass to get the config running.)
	$(warning )
	$(warning You can install it using this makefile by invoking:)
	$(warning make install-mingw)
	$(warning This needs you to be a sudoer, because some commands use sudo)
	$(warning ========================================================================)
	$(error stop.)

###############################################################################
# Binutils

# build binutils
$(mingw-build-dir)/1-binutils.done: $(mingw-build-dir)/$(binutils)
	mkdir -p $(mingw-build-dir)/obj-$(binutils)
	cd $(mingw-build-dir)/obj-$(binutils) && $(mingw-build-dir)/$(binutils)/configure \
		--target=$(cross) --prefix=$(gccprefix)
	make -C $(mingw-build-dir)/obj-$(binutils)
	$(sudo) make -C $(mingw-build-dir)/obj-$(binutils) install
	touch $@

# unpack binutils
$(mingw-build-dir)/$(binutils): $(archive-dir)/$(binutils).tar.bz2
	mkdir -p $(mingw-build-dir)
	tar xjf $(archive-dir)/$(binutils).tar.bz2 -C $(mingw-build-dir)

# download binutils
$(archive-dir)/$(binutils).tar.bz2:
	mkdir -p $(archive-dir)
	cd $(archive-dir) && wget ftp://ftp.fu-berlin.de/unix/gnu/binutils/$(binutils).tar.bz2
	touch $@

###############################################################################
# GCC Step 1

# build gcc - C only
$(mingw-build-dir)/2-gcc-c.done: $(mingw-build-dir)/$(gcc) \
		$(mingw-build-dir)/1-binutils.done \
		$(mingw-build-dir)/3-w32api-headers.done \
		$(mingw-build-dir)/4-mingwrt-headers.done
	mkdir -p $(mingw-build-dir)/obj-$(gcc)
	cd $(mingw-build-dir)/obj-$(gcc) && $(mingw-build-dir)/$(gcc)/configure \
		--target=$(cross) --prefix=$(gccprefix) \
		--with-headers=$(gccprefix)/$(cross)/include \
		--enable-languages=c
	PATH=$(path) make -C $(mingw-build-dir)/obj-$(gcc)
	sudo bash -c "PATH=$(path) make -C $(mingw-build-dir)/obj-$(gcc) install"
	touch $@

# unpack gcc
$(mingw-build-dir)/$(gcc): $(archive-dir)/$(gcc).tar.bz2
	mkdir -p $(mingw-build-dir)
	tar xjf $(archive-dir)/$(gcc).tar.bz2 -C $(mingw-build-dir)
	touch $@

# download gcc
$(archive-dir)/$(gcc).tar.bz2:
	mkdir -p $(archive-dir)
	cd $(archive-dir) && wget ftp://ftp.fu-berlin.de/unix/languages/gcc/releases/$(gcc)/$(gcc).tar.bz2

###############################################################################
# Win32 API

# resolve cicular build dependency
$(mingw-build-dir)/3-w32api-headers.done: $(mingw-build-dir)/$(w32api)
	sudo mkdir -p $(gccprefix)/$(cross)
	sudo cp -rf $(mingw-build-dir)/$(w32api)/include $(gccprefix)/$(cross)
	touch $@

# build win32 api
$(mingw-build-dir)/5-w32api.done: $(mingw-build-dir)/$(w32api) | $(mingw-build-dir)/2-gcc-c.done
	mkdir -p $(mingw-build-dir)/obj-$(w32api)
	cd $(mingw-build-dir)/obj-$(w32api) && PATH=$(path) $(mingw-build-dir)/$(w32api)/configure \
		--host=$(cross) --prefix=$(gccprefix)/$(cross)
	PATH=$(path) make -C $(mingw-build-dir)/obj-$(w32api)
	$(sudo) bash -c "PATH=$(path) make -C $(mingw-build-dir)/obj-$(w32api) install"
	touch $@

# unpack win32 api
$(mingw-build-dir)/$(w32api): $(archive-dir)/$(w32api)-src.tar.gz
	mkdir -p $(mingw-build-dir)
	tar xzf $(archive-dir)/$(w32api)-src.tar.gz -C $(mingw-build-dir)
	ln -sf $(w32api) $(mingw-build-dir)/w32api
	touch $@

# download win32 api
$(archive-dir)/$(w32api)-src.tar.gz:
	mkdir -p $(archive-dir)
	#cd $(archive-dir) && wget http://www.mirrorservice.org/sites/download.sourceforge.net/pub/sourceforge/m/mi/mingw/$(w32api)-src.tar.gz
	cd $(archive-dir) && wget http://www.mirrorservice.org/sites/download.sourceforge.net/pub/sourceforge/m/project/mi/mingw/MinGW%20API%20for%20MS-Windows/Current%20Release_%20w32api-3.13/$(w32api)-src.tar.gz

###############################################################################
# MinGW runtime

# resolve cicular build dependency
$(mingw-build-dir)/4-mingwrt-headers.done: $(mingw-build-dir)/$(mingwrt)
	sudo mkdir -p $(gccprefix)/$(cross)
	sudo cp -rf $(mingw-build-dir)/$(mingwrt)/include $(gccprefix)/$(cross)
	touch $@

# build mingw runtime
$(mingw-build-dir)/6-mingwrt.done: $(mingw-build-dir)/$(mingwrt) $(mingw-build-dir)/2-gcc-c.done $(mingw-build-dir)/5-w32api.done
	mkdir -p $(mingw-build-dir)/obj-$(mingwrt)
	cd $(mingw-build-dir)/obj-$(mingwrt) && PATH=$(path) $(mingw-build-dir)/$(mingwrt)/configure \
		--host=$(cross) --prefix=$(gccprefix)/$(cross)
	PATH=$(path) make -C $(mingw-build-dir)/obj-$(mingwrt)
	$(sudo) bash -c "PATH=$(path) make -C $(mingw-build-dir)/obj-$(mingwrt) install"
	touch $@

# unpack mingw runtime
$(mingw-build-dir)/$(mingwrt): $(archive-dir)/$(mingwrt)-src.tar.gz
	mkdir -p $(mingw-build-dir)
	tar xzf $(archive-dir)/$(mingwrt)-src.tar.gz -C $(mingw-build-dir)
	touch $@

# download mingw runtime
$(archive-dir)/$(mingwrt)-src.tar.gz:
	mkdir -p $(archive-dir)
	#cd $(archive-dir) && wget http://www.mirrorservice.org/sites/download.sourceforge.net/pub/sourceforge/m/mi/mingw/$(mingwrt)-src.tar.gz
	cd $(archive-dir) && wget http://www.mirrorservice.org/sites/download.sourceforge.net/pub/sourceforge/m/project/mi/mingw/MinGW%20Runtime/mingwrt-3.16/$(mingwrt)-src.tar.gz

###############################################################################
# Final GCC C and C++ compilers

# build final c and c++ compiler
$(mingw-build-dir)/7-gcc-full.done: $(mingw-build-dir)/$(gcc) \
	$(mingw-build-dir)/5-w32api.done $(mingw-build-dir)/6-mingwrt.done
	mkdir -p $(mingw-build-dir)/obj-full-$(gcc)
	cd $(mingw-build-dir)/obj-full-$(gcc) && $(mingw-build-dir)/$(gcc)/configure \
		--target=$(cross) --prefix=$(gccprefix) \
		--with-headers=$(gccprefix)/$(cross)/include \
		--enable-languages=c,c++
	PATH=$(path) make -C $(mingw-build-dir)/obj-full-$(gcc)
	$(sudo) bash -c "PATH=$(path) make -C $(mingw-build-dir)/obj-full-$(gcc) install"
	touch $@

###############################################################################
# DirectX headers/libs

# build mingw runtime
$(mingw-build-dir)/8-directx.done: $(mingw-build-dir)/5-w32api.done $(archive-dir)/directx-devel.tar.gz
	$(sudo) bash -c "cd $(gccprefix)/$(cross) && tar xzf $(archive-dir)/directx-devel.tar.gz"
	touch $@

# download directx headers/libs
$(archive-dir)/directx-devel.tar.gz:
	mkdir -p $(archive-dir)
	cd $(archive-dir) && wget http://www.libsdl.org/extras/win32/common/directx-devel.tar.gz
