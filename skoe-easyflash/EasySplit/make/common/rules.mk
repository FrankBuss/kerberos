#
# rules.mk - various Makefile rules (version 1)
#
# (c) 2003-2010 Thomas Giesel
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

# variables used here must be set in the including Makefile
INCLUDE   += -I$(objdir)

cflags    += -DVERSION=\"$(version)\"
cxxflags  += -DVERSION=\"$(version)\"

# don't delete intermediate files
.SECONDARY:

###############################################################################
# Main targets
#
.PHONY: all
all: $(outbase)/$(app_name)$(version_suffix).tar.bz2

$(outbase)/$(app_name)$(version_suffix).tar.bz2: \
		$(outdir)/$(app_name) $(outres) $(outdoc)
	rm -f $@
	cd $(dir $@) && tar cjf $(notdir $@) $(app_name)

###############################################################################
# Link the app
# 
$(outdir)/$(app_name): $(obj) | $(outdir) check-environment
	$(cxx) $(ldflags) $(obj) -o $@ \
		`wx-config --libs`

###############################################################################
# This rule can create the directories we need
#
$(outdir) $(objdir):
	mkdir -p $@

###############################################################################
# This rule can compile <base>/src/*.cpp to <here>/out/obj/*.o
#
$(objdir)/%.o: $(srcdir)/%.cpp $(headers) | $(objdir) check-environment
	$(cxx) -c $(cxxflags) $(INCLUDE) -o $@ $<

###############################################################################
# This rule can compile <base>/src/*.c to <here>/out/obj/*.o
#
$(objdir)/%.o: $(srcdir)/%.c $(headers) | $(objdir) check-environment
	$(cc) -c $(ccflags) $(INCLUDE) -o $@ $<

###############################################################################
# This rule can compile <base>/res/*.png to <here>/out/obj/*.xpm
#
$(objdir)/%.xpm: $(srcdir)/../res/%.png | $(objdir) check-environment
	convert $< $@.tmp.xpm
	cat $@.tmp.xpm | sed "\
			s/static char/static const char/;\
			s/[\._]tmp//;\
			s/\.xpm/_xpm/" > $@

###############################################################################
# This rule can copy * to $(outdir)/*
# 
$(outdir)/%: $(srcdir)/../%
	mkdir -p $(dir $@)
	cp $< $@

###############################################################################
# This rule can convert * to $(outdir)/*.txt using unix2dos
# 
$(outdir)/%.txt: $(srcdir)/../%
	cat $< | unix2dos > $@

###############################################################################
# make clean the simple way
#
.PHONY: clean
clean:
	rm -rf $(outbase)
