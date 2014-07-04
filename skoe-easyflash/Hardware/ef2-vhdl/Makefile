
here 		:= $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
synth_dir 	:= $(here)/synth
src_dir		:= $(here)/src

# this file list is for dependencies only, keep in sync with ef2.prj
src 		:= $(src_dir)/ef2.vhdl
src 		+= $(src_dir)/exp_bus_ctrl.vhdl
src 		+= $(src_dir)/reset_generator.vhdl
src 		+= $(src_dir)/freezer.vhdl

uc  := $(src_dir)/ef2.ucf

xst_cfg    := $(here)/ef2.xst
project    := $(here)/ef2.prj

#netlist    := $(addprefix $(synth_dir)/, $(notdir $(src:.vhdl=.ngc)))
netlist		:= $(synth_dir)/ef2.ngc

gen_db     := $(synth_dir)/ef2.ngd
fit        := $(synth_dir)/ef2.vm6
jedec      := $(here)/ef2.jed
xsvf       := $(here)/ef2.xsvf

dev_type   := xc95144xl
dev_pkg    := tq100
dev_speed  := 10
device     := $(dev_type)-$(dev_pkg)-$(dev_speed)
device_fit := $(dev_type)-$(dev_speed)-$(dev_pkg)

fit_flags  := -p $(device_fit) -ofmt abel -log fitter.log -optimize density
fit_flags  += -power low -slew slow
fit_filter_output := "^CS: block property:\|^$$"

# directories to be created
dirs       := $(synth_dir) $(here)/log

all: xsvf

################################################################################

.PHONY: netlist
netlist: $(netlist)
$(netlist): $(xst_cfg) $(src) $(project) $(dirs)
	mkdir -p $(synth_dir)/xst/tmp/
	xst -intstyle silent -ifn $<
	mv ef2.srp log/netlist.ef2.srp

################################################################################
.PHONY: gen_db
gen_db: $(gen_db)
$(gen_db): $(netlist) $(uc) $(dirs)
	mkdir -p synth/ngdbuild/tmp/
	cd $(synth_dir) && ngdbuild -p $(device) -uc $(uc) -quiet \
		-intstyle silent -dd $(synth_dir)/ngdbuild/tmp/ $<
	mv $(synth_dir)/ef2.bld log/ngd.ef2.bld

################################################################################
.PHONY: fit
fit: $(fit)
$(fit): $(gen_db) $(dirs)
	cd $(synth_dir) && cpldfit $(fit_flags) $< | grep -v $(fit_filter_output)
	mv $(synth_dir)/ef2.rpt log/fitter.ef2.rpt

################################################################################
.PHONY: jedec
jedec: $(jedec)
$(jedec): $(fit)
	hprep6 -i $<

################################################################################
.PHONY: xsvf
xsvf: $(xsvf)
$(xsvf): $(jedec)
	cat impact.batch | impact -batch

################################################################################
.PHONY: usbprog
usbprog: $(xsvf)
	xsvfplayer $<

################################################################################
.PHONY: sim
sim:
	fuse -mt off -v -incremental -prj ef2_isim.prj -o ef2_isim work.ef2_tb
	./ef2_isim -gui -wdb ef2_isim.wdb -view ef2.wcfg

################################################################################
$(dirs):
	mkdir -p $@

################################################################################
.PHONY: clean
clean:
	rm -rf synth
	rm -rf log
	rm -rf isim
	rm -f ef2.jed
	rm -f ef2_isim
	rm -f tmperr.err
