
# do not remove intermediate targets
.SECONDARY:

name := efmenu

version := none

ld65_version := $(shell [ `ld65 -V 2>&1 | sed -e 's/\(ld65 V\)\([0-9\.]*\)\( .*\)/\2/g; q'` \< "2.13.9" ] && echo old)

ifeq "$(ld65_version)" "old"
        ld_config := src/ld.cfg
else
        ld_config := src/ld2.cfg
endif

obj :=
obj += obj/crt0.o
obj += obj/efmenu.o
obj += obj/efmenu_asm.o
obj += obj/gfx.o
obj += obj/charset.o
obj += obj/text_plot.o
obj += obj/text_plot_asm.o
obj += obj/sound.o
obj += obj/joy.o

inc      := src
inc      += ../../libs/libef3usb/src

INCLUDE  := $(addprefix -I,$(inc))

DEFINE   := -DEFVERSION=\"${version}\"

libef3usb := ../../libs/libef3usb/libef3usb.lib

.PHONY: all
all: $(name).crt

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
# therefore we need a dependency here
#
obj/%.o: src/%.s $(bin_acme) | obj
	ca65 -t c64 -I src -o $@ $<

###############################################################################
# prepare the charset
#
obj/charset.s: src/charset.sed | obj
	sed -e "s/\#/1/g; s/\-/0/g; s/^[01][01]/.byte %&/" \
		$< > $@

###############################################################################
# create a crt image from a binary image
#
%.crt: %.bin
	../../EasySDK/tools/bin2efcrt $< $@

###############################################################################
#
$(libef3usb): force
	$(MAKE) -C $(dir $@)

.PHONY: force
force:

###############################################################################
obj:
	mkdir -p $@

$(name).bin: $(obj) $(ld_config) $(libef3usb)
	ld65 -o $@ -m $@.map -Ln $@.labels -C $(ld_config) $(obj) \
		--lib $(libef3usb) \
		-L /usr/local/lib/cc65/lib --lib c64.lib
	cat $@.map | grep -e "^Name\|^CODE\|^DATA\|^BSS\|^RODATA\|^LOWCODE"

.PHONY: clean
clean:
	rm -f $(name) $(name).bin $(name).bin.map $(name).bin.labels
	rm -f $(name).crt
	rm -f $(obj)
	rm -rf obj
