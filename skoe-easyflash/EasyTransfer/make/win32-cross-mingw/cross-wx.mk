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

cross          := $(host)
wx-version     := wxMSW-2.8.12
wx-build-dir   := $(outbase)/wx-build
wx-prefix      := $(outbase)/$(cross)-$(wx-version)
sudo           := 

# after adding some paths to this it will be used as PATH
path           := $(PATH)

# to be used in top-level Makefile
cxxflags       += $(shell $(wx-prefix)/bin/wx-config --static=yes --cxxflags)
cxxlibs        += $(shell $(wx-prefix)/bin/wx-config --libs)

.PHONY: install-wxwidgets
install-wxwidgets: $(wx-build-dir)/$(wx-version)/3-installed

$(wx-build-dir)/$(wx-version)/0-depacked: $(archive_dir)/$(wx-version).tar.bz2
	mkdir -p $(wx-build-dir)
	tar xjf $(archive_dir)/$(wx-version).tar.bz2 -C $(wx-build-dir)
	patch -i $(archive_dir)/filefn.wx2.8.12.diff $(wx-build-dir)/$(wx-version)/include/wx/filefn.h
	touch $@

$(wx-build-dir)/$(wx-version)/1-configured: $(wx-build-dir)/$(wx-version)/0-depacked
	cd $(wx-build-dir)/$(wx-version) && \
		PATH=$(path) ./configure --prefix=$(wx-prefix) --disable-shared --host=$(cross) --build=`uname -m`-linux
	touch $@

$(wx-build-dir)/$(wx-version)/2-compiled: $(wx-build-dir)/$(wx-version)/1-configured
	PATH=$(path) make -C $(wx-build-dir)/$(wx-version)
	touch $@

$(wx-build-dir)/$(wx-version)/3-installed: $(wx-build-dir)/$(wx-version)/2-compiled
	PATH=$(path) $(sudo) make -C $(wx-build-dir)/$(wx-version) install
	touch $@

# download wxwidgets
$(archive_dir)/$(wx-version).tar.bz2:
	mkdir -p $(archive_dir)
	cd $(archive_dir) && wget "http://downloads.sourceforge.net/wxwindows/$(wx-version).tar.bz2"
