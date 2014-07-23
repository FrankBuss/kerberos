menu_obj :=
menu_obj += obj/crt0.o
menu_obj += obj/utilasm.o
menu_obj += obj/midiasm.o
menu_obj += obj/menu.o

test_obj :=
test_obj += obj/crt0.o
test_obj += obj/utilasm.o
test_obj += obj/midiasm.o
test_obj += obj/test.o

synthesizer_obj :=
synthesizer_obj += obj/crt0.o
synthesizer_obj += obj/utilasm.o
synthesizer_obj += obj/midiasm.o
synthesizer_obj += obj/synthesizer.o

obj := menu_obj test_obj

ld_config := src/ld.cfg

inc      := src

INCLUDE  := $(addprefix -I,$(inc))

###############################################################################
#
.PHONY: all
all: menu.bin test.prg synthesizer.prg

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

menu: $(menu_obj) $(ld_config)
	ld65 -o $@ -Ln vice.label -m $@.map -C $(ld_config) $(menu_obj) --lib c64.lib
	cat $@.map | grep -e "^Name\|^CODE\|^DATA\|^BSS\|^RODATA\|^LOWCODE"

menu.prg: menu
	cp -f menu menu.prg

menu.bin: menu.prg
	ca65 -t none -Isrc -o obj/cart-loader.o src/cart-loader.s
	ld65 -o menu.bin -C src/ld-cart.cfg obj/cart-loader.o


cart128.bin: src/cart128.s
	ca65 -t none -Isrc -o obj/cart128.o src/cart128.s
	ld65 -o cart128.bin -C src/ld-cart.cfg obj/cart128.o
	cartconv -t md -i cart128.bin -o cart128.crt

test: $(test_obj) $(ld_config)
	ld65 -o $@ -m $@.map -C $(ld_config) $(test_obj) --lib c64.lib
	cat $@.map | grep -e "^Name\|^CODE\|^DATA\|^BSS\|^RODATA\|^LOWCODE"

test.prg: test
	cp -f test test.prg

synthesizer: $(synthesizer_obj) $(ld_config)
	ld65 -o $@ -m $@.map -C $(ld_config) $(synthesizer_obj) --lib c64.lib
	cat $@.map | grep -e "^Name\|^CODE\|^DATA\|^BSS\|^RODATA\|^LOWCODE"

synthesizer.prg: synthesizer
	cp -f synthesizer synthesizer.prg


#cartconv -t md -i menu.bin -o menu.crt

.PHONY: clean
clean:
	rm -f menu menu.map menu.prg menu.bin
	rm -rf obj

