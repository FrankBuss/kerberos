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

wx-version     := wxMSW-2.8.9
wx-archive-dir := $(here)/archive
wx-build-dir  := wx-build
wx-prefix      := /opt/cross/$(cross)-$(wx-version)

###############################################################################
# Rules to check the cross compiling environment
#
.PHONY: check-environment
check-environment: out/check-environment.ok

out/check-environment.ok:
	$(MAKE) check-mingw
	$(MAKE) check-wx
	mkdir -p out
	touch $@

.PHONY: check-wx
check-wx:
	$(wx-prefix)/bin/wx-config --version > /dev/null || $(MAKE) no-wx

.PHONY: no-wx
no-wx:
	$(warning ========================================================================)
	$(warning No cross-wxWidgets found.)
	$(warning )
	$(warning This could mean that it is not installed or not at the place we look at:)
	$(warning $(wx-prefix)/bin/wx-config)
	$(warning )
	$(warning If you have a suitable i586-wxWidgets installed, you may want to adapt)
	$(warning the path in this makefile.)
	$(warning )
	$(warning However, it's recommended to build it with this makefile, it uses a path)
	$(warning which is unlikely to collide with other versions. Otherwise it may)
	$(warning become a pain in the ass to get the config running.)
	$(warning )
	$(warning You can install it using this makefile by invoking:)
	$(warning make install-wxwidgets)
	$(warning This needs you to be a sudoer, because some commands use sudo)
	$(warning ========================================================================)
	$(error stop.)

###############################################################################
# Rules for installing cross-wxWidgets
#
.PHONY: install-wxwidgets
install-wxwidgets: $(wx-build-dir)/$(wx-version)/3-installed

$(wx-build-dir)/$(wx-version)/1-configured: $(wx-build-dir)/$(wx-version)
	cd $(wx-build-dir)/$(wx-version) && \
		PATH=$(path) ./configure --prefix=$(wx-prefix) --disable-shared --host=$(cross) --build=`uname -m`-linux
	touch $@

$(wx-build-dir)/$(wx-version)/2-compiled: $(wx-build-dir)/$(wx-version)/1-configured
	PATH=$(path) make -C $(wx-build-dir)/$(wx-version)
	touch $@

$(wx-build-dir)/$(wx-version)/3-installed: $(wx-build-dir)/$(wx-version)/2-compiled
	PATH=$(path) sudo make -C $(wx-build-dir)/$(wx-version) install
	touch $@

# unpack wxwidgets
$(wx-build-dir)/$(wx-version): $(wx-archive-dir)/$(wx-version).tar.bz2
	mkdir -p $(wx-build-dir)
	tar xjf $(wx-archive-dir)/$(wx-version).tar.bz2 -C $(wx-build-dir)

# download wxwidgets
$(wx-archive-dir)/$(wx-version).tar.bz2:
	mkdir -p $(wx-archive-dir)
	cd $(wx-archive-dir) && wget "http://downloads.sourceforge.net/wxwindows/$(wx-version).tar.bz2"
