

.PHONY: all
all: out/ef3kernal_b0.bin out/ef3kernal_b1.bin

src := src/ef3kernal.s

inc      := src
inc      += ../../libs/libef3usb/src

INCLUDE  := $(addprefix -I,$(inc))

libef3usb := ../../libs/libef3usb/libef3usb.lib

###############################################################################
# KERNAL bank 0
# We do this with acme since it makes it very easy to overwrite portions of 
# the original KERNAL image
out/ef3kernal_b0.bin: src/ef3kernal.s src/kernal.bin out
	acme -l $@.labels -o $@ src/ef3kernal.s

###############################################################################
# KERNAL bank 1

obj_b1 := obj/kernal_b1.o
obj_b1 += obj/usbrx.o
obj_b1 += obj/usbrx_asm.o

out/ef3kernal_b1.bin: $(obj_b1) $(libef3usb) src/ld.kernal.cfg
	ld65 -o $@ -m $@.map -C src/ld.kernal.cfg $(obj_b1) \
		--lib $(libef3usb) \
		-L /usr/local/lib/cc65/lib  --lib c64.lib
	cat $@.map | grep -e "^Name\|^CODE\|^DATA\|^BSS\|^RODATA"

###############################################################################
#
$(libef3usb): force
	$(MAKE) -C $(dir $@)

.PHONY: force
force:

###############################################################################
# Poor men's dependencies: Let all files depend from all header files
headers := $(foreach dir, $(inc), $(wildcard $(dir)/*.h))

###############################################################################
obj/%.o: obj/%.s obj
	ca65 -t c64 -o $@ $<

###############################################################################
obj/%.s: src/%.c obj $(headers)
	cc65 -t c64 -T -O --static-locals -I $(INCLUDE) $(DEFINE) -o $@ $<

###############################################################################
obj/%.o: src/%.s obj
	ca65 -t c64 $(INCLUDE) -o $@ $<

obj:
	mkdir -p $@

out:
	mkdir -p $@


.PHONY: clean
clean:
	rm -rf obj
	rm -rf out

