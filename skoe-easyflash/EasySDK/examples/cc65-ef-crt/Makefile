
# do not remove intermediate targets
.SECONDARY:

name := hello-ef

ifneq "$(release)" "yes"
	version := $(shell date +%y%m%d-%H%M)
else
	version := 1.0.0
endif

ld_config := src/c64-ef-crt.cfg

obj :=
obj += obj/crt0.o
obj += obj/hello.o

INCLUDE  := include

DEFINE   := -DEFVERSION=\"${version}\"

.PHONY: all
all: $(name).crt

###############################################################################
# Poor men's dependencies: Let all files depend from all header files
#
headers := $(wildcard $(INCLUDE)/*.h)

obj/%.s: src/%.c obj $(headers)
	cc65 -t c64 -T -O --static-locals -I $(INCLUDE) $(DEFINE) -o $@ $<

###############################################################################
obj/%.o: obj/%.s obj
	ca65 -t c64 -o $@ $<

###############################################################################
# the binaries created with acme are included in ca65 source code
# therefore we need a dependency here
#
obj/%.o: src/%.s obj $(bin_acme)
	ca65 -t c64 -o $@ $<


###############################################################################
# create a crt image from a binary image
#
%.crt: %.bin
	../../tools/bin2efcrt $< $@

###############################################################################
obj:
	mkdir -p $@

$(name).bin: $(obj) $(ld_config)
	ld65 -o $@ -m $@.map -C $(ld_config) $(obj) \
		-L /usr/local/lib/cc65/lib --lib c64.lib
ifeq "$(release)" "yes"
	cp $@ $@-$(version).prg
endif

.PHONY: clean
clean:
	rm -f $(name) $(name).map $(name).prg
	rm -rf obj
