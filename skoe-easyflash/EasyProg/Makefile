
ifeq "$(release)" "yes"
	version := 1.7.1
else
	version := $(shell date +%y%m%d-%H%M)
endif

# do not remove intermediate targets
.SECONDARY:

obj :=
obj += obj/crt0.o
obj += obj/autoinit.o
obj += obj/eapiglueasm.o
obj += obj/texts.o
obj += obj/torturetestasm.o
obj += obj/startupbin.o
obj += obj/spritesasm.o
obj += obj/exostreamdecr1.o
obj += obj/utilasm.o
obj += obj/easyprog.o
obj += obj/flash.o
obj += obj/cart.o
obj += obj/screen.o
obj += obj/screenasm.o
obj += obj/progress.o
obj += obj/progressasm.o
obj += obj/timerasm.o
obj += obj/dir.o
obj += obj/filedlg.o
obj += obj/selectbox.o
obj += obj/slots.o
obj += obj/hex.o
obj += obj/torturetest.o
obj += obj/write.o
obj += obj/usbtest.o
obj += obj/util.o

ld65_version := $(shell [ `ld65 -V 2>&1 | sed -e 's/\(ld65 V\)\([0-9\.]*\)\( .*\)/\2/g; q'` \< "2.13.9" ] && echo old)

ifeq "$(ld65_version)" "old"
        ld_config := src/ld.cfg
else
        ld_config := src/ld2.cfg
endif

bin_acme :=
bin_acme += obj/startup.bin
bin_acme += obj/sprites.bin

eapi += eapi-sst39vf1681

eapi_dir := ../EasySDK/eapi
eapi_src := $(addprefix $(eapi_dir)/out/,$(eapi))
eapi_obj := $(addprefix obj/,$(eapi))

inc      := src
inc      += eload/src
inc      += libprint/src
inc      += ../libs/libef3usb/src

eload     := eload/eload.lib
libprint  := libprint/libprint.lib
libef3usb := ../libs/libef3usb/libef3usb.lib

INCLUDE  := $(addprefix -I,$(inc))

DEFINE   := -DEFVERSION=\"${version}\"

ifeq "$(debug)" "yes"
DEFINE   += -DEFDEBUG
endif

###############################################################################
#
.PHONY: all
ifeq "$(release)" "yes"
all: easyprog-$(version).zip
else
all: easyprog.prg
endif

###############################################################################
# Poor men's dependencies: Let all files depend from all header files
#
headers := $(foreach dir, $(inc), $(wildcard $(dir)/*.h))

obj/%.s: src/%.c $(headers) | obj
	cc65 -t c64 -T -O --static-locals $(INCLUDE) $(DEFINE) -o $@ $<

###############################################################################
obj/%.o: obj/%.s | obj
	ca65 -t c64 -o $@ $<

###############################################################################
# the binaries created with acme are included in ca65 source code
# therefore we need a dependency here, and we need the built-in eapi
#
obj/%.o: src/%.s $(bin_acme) $(eapi_obj) | obj
	ca65 -t c64 -o $@ $<

###############################################################################
# Always build eapi and copy it here
#
.PHONY: always
always:

$(eapi_obj): always | obj
	$(MAKE) -C $(eapi_dir)
	cp $(eapi_src) obj

###############################################################################
obj/%.bin: src/%.s | obj
	acme -o $@ $<

###############################################################################
obj:
	mkdir -p $@

easyprog: $(obj) $(ld_config) $(eload) $(libprint) $(libef3usb)
	ld65 -o $@ -m $@.map -C $(ld_config) $(obj) -L /usr/local/lib/cc65/lib \
		--lib $(eload) --lib $(libprint) --lib $(libef3usb) --lib c64.lib
	cat $@.map | grep -e "^Name\|^CODE\|^DATA\|^BSS\|^RODATA\|^LOWCODE"

easyprog.prg: easyprog
	exomizer sfx 0x080d -o $@ -q $^

easyprog-$(version).zip: easyprog.prg CHANGES
	rm -rf easyprog-$(version)
	rm -f $@
	mkdir easyprog-$(version)
	cp easyprog.prg easyprog-$(version)/easyprog-$(version).prg
	cp CHANGES easyprog-$(version)
	cp IMPORTANT.txt easyprog-$(version)
	zip -v -r $@ easyprog-$(version)

$(eload): force
	$(MAKE) -C $(dir $@)

$(libprint): force
	$(MAKE) -C $(dir $@)

$(libef3usb): force
	$(MAKE) -C $(dir $@)

.PHONY: force
force:

.PHONY: clean
clean:
	rm -f easyprog easyprog.map easyprog.prg
	rm -rf obj
	$(MAKE) -C $(dir $(eload)) clean
	$(MAKE) -C $(dir $(libprint)) clean

