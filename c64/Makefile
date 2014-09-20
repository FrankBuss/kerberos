menu_obj :=
menu_obj += obj/util.o
menu_obj += obj/util_asm.o
menu_obj += obj/midi.o
menu_obj += obj/flash.o
menu_obj += obj/main_menu.o
menu_obj += obj/test_menu.o

synthesizer_obj :=
synthesizer_obj += obj/util.o
synthesizer_obj += obj/util_asm.o
synthesizer_obj += obj/midi.o
synthesizer_obj += obj/synthesizer.o

obj := menu_obj synthesizer_obj

ld_config := src/ld.cfg

inc      := src

INCLUDE  := $(addprefix -I,$(inc))

###############################################################################
#
.PHONY: all
all: menu.bin synthesizer.prg

###############################################################################
# Poor men's dependencies: Let all files depend from all header files
#
headers := $(foreach dir, $(inc), $(wildcard $(dir)/*.h))

obj/%.s: src/%.c $(headers) | obj
	cc65 -t c64 -T -O $(INCLUDE) $(DEFINE) -o $@ $<

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

synthesizer: $(synthesizer_obj) $(ld_config)
	ld65 -o $@ -m $@.map -C $(ld_config) $(synthesizer_obj) --lib c64.lib
	cat $@.map | grep -e "^Name\|^CODE\|^DATA\|^BSS\|^RODATA\|^LOWCODE"

synthesizer.prg: synthesizer
	cp -f synthesizer synthesizer.prg

.PHONY: clean
clean:
	rm -f menu menu.map menu.prg menu.bin synthesizer synthesizer.prg
	rm -rf obj
