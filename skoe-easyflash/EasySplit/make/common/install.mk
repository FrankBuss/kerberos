#
# rules.mk - Makefile rules for install/uninstall (version 1)
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
#
# File to be checked for uninstall
#
check_uninstall :=

# old installation names/paths
check_uninstall += /usr/local/share/applications/$(app_name).desktop
check_uninstall += /usr/local/share/$(app_name)
check_uninstall += /usr/local/bin/$(app_name)
check_uninstall += /usr/share/applications/$(app_name).desktop
check_uninstall += /usr/share/$(app_name)
check_uninstall += /usr/bin/$(app_name)

# current installation names/paths
check_uninstall += $(desktop_inst_dir)/$(app_name).desktop
check_uninstall += $(res_inst_dir)/$(app_name)
check_uninstall += $(doc_inst_dir)/$(app_name)
check_uninstall += $(bin_inst_dir)/$(app_name)

uninstall_entries := $(sort $(foreach x,$(check_uninstall),$(wildcard $(x))))

###############################################################################
#
# Uninstall the application
#
.PHONY: uninstall
uninstall:
ifeq "$(strip $(uninstall_entries))" ""
	@echo
	@echo '### No installed files found. ###'
	@echo
	@echo 'If you think this is wrong, use the right prefix:'
	@echo '    make prefix=<prefix> clean'
	@echo
else
	@echo ''
	@echo 'Following files and directories will be deleted:'
	@echo $(uninstall_entries)
ifneq "$(shell id -u)" "0"
	@echo 'If it fails you may want to try again as root'
endif
	@echo
	@echo '### Are you sure that you want to delete them? (y|n)'
	@read ans && test "$${ans}" = "y" || kill 0
	rm -rf $(uninstall_entries)
	@echo Done.
endif

###############################################################################
#
# Install the application
#
.PHONY: install
install: all
ifneq "$(strip $(uninstall_entries))" ""
	@echo
	@echo '### Old installation found. ###'
	@echo
	@echo 'It is recommended to interrupt now and "make uninstall" first.'
	@echo 'Continue nevertheless? (y|n)'
	@read ans && test "$${ans}" = "y" || kill 0
	@echo
endif
ifneq "$(shell id -u)" "0"
	@echo 'If it fails you may want to try again as root'
	@echo
endif
	mkdir -p $(bin_inst_dir)
	cp $(outdir)/$(app_name) $(bin_inst_dir)
	mkdir -p $(res_inst_dir)/$(app_name)
	cp -r  $(outdir)/res $(res_inst_dir)/$(app_name)
	mkdir -p $(doc_inst_dir)/$(app_name)
	cp $(outdoc) $(doc_inst_dir)/$(app_name)
	mkdir -p $(desktop_inst_dir)
	cp $(srcdir)/../res/$(app_name).desktop $(desktop_inst_dir)
	@echo Done.
