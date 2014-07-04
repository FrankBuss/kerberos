
ifeq "$(release)" "yes"
	version := 1.1.1
else
	version := $(shell date +%y%m%d-%H%M)
endif

here 		:= $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
synth_dir 	:= $(here)/synth
src_dir		:= $(here)/src
vhdlprj		:= ef3

# this file list is for dependencies only, keep in sync with $(vhdlprj).prj
src 		:= $(src_dir)/ef3.vhdl
src 		+= $(src_dir)/exp_bus_ctrl.vhdl
src 		+= $(src_dir)/reset_generator.vhdl
src 		+= $(src_dir)/freezer.vhdl
src 		+= $(src_dir)/cart_easyflash.vhdl
src 		+= $(src_dir)/cart_io2ram.vhdl
src 		+= $(src_dir)/cart_kernal.vhdl
src 		+= $(src_dir)/cart_ar.vhdl
src 		+= $(src_dir)/cart_ss5.vhdl
src 		+= $(src_dir)/cart_usb.vhdl

uc  := $(src_dir)/$(vhdlprj).ucf

xst_cfg    := $(here)/$(vhdlprj).xst
project    := $(here)/$(vhdlprj).prj

#netlist    := $(addprefix $(synth_dir)/, $(notdir $(src:.vhdl=.ngc)))
netlist		:= $(synth_dir)/$(vhdlprj).ngc

gen_db     := $(synth_dir)/$(vhdlprj).ngd
fit        := $(synth_dir)/$(vhdlprj).vm6
jedec      := $(here)/$(vhdlprj).jed
svf       := $(here)/$(vhdlprj).svf

dev_type   := xc95144xl
dev_pkg    := tq100
dev_speed  := 10
device     := $(dev_type)-$(dev_pkg)-$(dev_speed)
device_fit := $(dev_type)-$(dev_speed)-$(dev_pkg)

fit_flags  := -p $(device_fit) -ofmt abel -log fitter.log -optimize density
fit_flags  += -power low -slew slow 
#fit_flags  += -exhaust
fit_flags  += -inputs 54 -pterms 25 
fit_filter_output := "^CS: block property:\|^$$"

# directories to be created
dirs       := $(synth_dir) $(here)/log

.PHONY: all
ifeq "$(release)" "yes"
all: ef3-cpld-$(version).zip
else
all: $(svf)
endif

################################################################################
ef3-cpld-$(version).zip: $(svf) README.txt
	rm -rf ef3-cpld-$(version)
	rm -f $@
	mkdir ef3-cpld-$(version)
	cp $(svf) ef3-cpld-$(version)/ef3-cpld-$(version).svf
	cp README.txt ef3-cpld-$(version)
	zip -v -r $@ ef3-cpld-$(version)

################################################################################
.PHONY: netlist
netlist: $(netlist)
$(netlist): $(xst_cfg) $(src) $(project) | $(dirs)
	mkdir -p $(synth_dir)/xst/tmp/
	xst -intstyle silent -ifn $<
	mv $(vhdlprj).srp log/netlist.$(vhdlprj).srp

################################################################################
.PHONY: gen_db
gen_db: $(gen_db)
$(gen_db): $(netlist) $(uc) | $(dirs)
	mkdir -p synth/ngdbuild/tmp/
	cd $(synth_dir) && ngdbuild -p $(device) -uc $(uc) -quiet \
		-intstyle silent -dd $(synth_dir)/ngdbuild/tmp/ $<
	mv $(synth_dir)/$(vhdlprj).bld log/ngd.$(vhdlprj).bld

################################################################################
.PHONY: fit
fit: $(fit)
$(fit): $(gen_db) | $(dirs)
	cd $(synth_dir) && cpldfit $(fit_flags) $< | grep -v $(fit_filter_output)
	mv $(synth_dir)/$(vhdlprj).rpt log/fitter.$(vhdlprj).rpt

################################################################################
.PHONY: jedec
jedec: $(jedec)
$(jedec): $(fit)
	hprep6 -i $<

################################################################################
.PHONY: svf
svf: $(svf)
$(svf): $(jedec)
	cat impact.batch | impact -batch

################################################################################
.PHONY: usbprog
usbprog: $(svf)
	svfplayer $<

################################################################################
.PHONY: prog
prog: $(svf)
	easp -p 0x8738 $<

################################################################################
$(dirs):
	mkdir -p $@

################################################################################
.PHONY: clean
clean:
	rm -rf synth
	rm -rf log
	rm -f $(vhdlprj).jed
	rm -f tmperr.err
