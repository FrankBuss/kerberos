#
# rules.mk - various Makefile string transformations (version 1)
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

###############################################################################
# Various derived variables
#
bin_inst_dir  := $(inst_prefix)/bin
res_inst_dir  := $(inst_prefix)/share
doc_inst_dir  := $(inst_prefix)/share/doc
desktop_inst_dir := $(inst_prefix)/share/applications

outdir        := $(outbase)/$(app_name)
objdir        := $(outbase)/obj
srcdir        := src

###############################################################################
# Transform all names from $(src)/*.cpp|c|png to out/obj/foo.o or
# out/obj/foo.xpm
#
src_cpp := $(filter %.cpp,$(src))
obj     := $(addprefix $(objdir)/, $(src_cpp:.cpp=.o))
src_c   := $(filter %.c,$(src))
obj     += $(addprefix $(objdir)/, $(src_c:.c=.o))
src_png := $(filter %.png,$(src))
xpm     := $(addprefix $(objdir)/, $(src_png:.png=.xpm))

###############################################################################
# Transform all names in $res to $(outdir)/res/*
#
outres := $(addprefix $(outdir)/res/, $(res))

###############################################################################
# Transform all names in $doc to $(outdir)/* or $(outdir)/*.txt
#
ifeq "$(win32)" "yes"
outdoc := $(addsuffix .txt, $(addprefix $(outdir)/, $(doc)))
else
outdoc := $(addprefix $(outdir)/, $(doc))
endif

###############################################################################
# Poor men's dependencies: Let all files depend from all header files
#
headers := $(wildcard $(srcdir)/*.h) $(xpm)
