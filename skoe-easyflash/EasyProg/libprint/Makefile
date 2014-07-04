

dep :=
dep += src/print.h

obj := 
obj += obj/print_crlf.o
obj += obj/print_hex_digit.o
obj += obj/print_hex_padded.o
obj += obj/print_init.o
obj += obj/print_putc.o
obj += obj/print_puts.o

.PHONY: all
all: libprint.lib

obj/%.o: src/%.s $(dep) | obj
	ca65 -I src -t c64 -o $@ $<

obj/%.o: obj/%.s $(dep) | obj
	ca65 -I src -t c64 -o $@ $<

obj/%.s: src/%.c $(dep) | obj
	cc65 -I src -t c64 -O -o $@ $<

obj:
	mkdir -p obj

libprint.lib: $(obj)
	rm -f $@
	ar65 a $@ $(obj)

.PHONY: clean
clean:
	rm -f $(obj)
	rm -rf obj
	rm -f libprint.lib

.PHONY: distclean
distclean: clean
	rm -f *~

