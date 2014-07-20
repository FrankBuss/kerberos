obj :=
obj += obj/crt0.o
obj += obj/utilasm.o
obj += obj/midiasm.o
obj += obj/menu.o

ld_config := src/ld.cfg

inc      := src

INCLUDE  := $(addprefix -I,$(inc))

###############################################################################
#
.PHONY: all
all: menu.bin

###############################################################################
# Poor men's dependencies: Let all files depend from all header files
#
headers := $(foreach dir, $(inc), $(wildcard $(dir)/*.h))

obj/%.s: src/%.c $(headers) | obj
	cc65 -t c64 -T -O --static-locals $(INCLUDE) $(DEFINE) -o $@ $<

###############################################################################
obj/%.o: obj/%.s | obj
	ca65 -t c64 $(INCLUDE) -o $@ $<

obj/%.o: src/%.s | obj
	ca65 -t c64 $(INCLUDE) -o $@ $<

###############################################################################
obj:
	mkdir -p $@

menu: $(obj) $(ld_config)
	ld65 -o $@ -Ln vice.label -m $@.map -C $(ld_config) $(obj) --lib c64.lib
	cat $@.map | grep -e "^Name\|^CODE\|^DATA\|^BSS\|^RODATA\|^LOWCODE"
	cp -f obj/menu.s menu.s

menu.prg: menu
	cp -f menu menu.prg

menu.bin: menu.prg
	ca65 -t none -Isrc -o obj/cart-loader.o src/cart-loader.s
	ld65 -o menu.bin -C src/ld-cart.cfg obj/cart-loader.o

#cartconv -t md -i menu.bin -o menu.crt

.PHONY: clean
clean:
	rm -f menu menu.map menu.prg menu.bin
	rm -rf obj

