

inc :=
inc += src/drivetype.s
inc += src/kernal.s
inc += src/xfer_drive_1mhz.s
inc += src/xfer_drive_2mhz.s

obj := 
obj += obj/drive_1541.o
#obj += obj/drive_1571.o
obj += obj/drive_1581.o
obj += obj/drive_sd2iec.o
obj += obj/drive_common.o
obj += obj/send_code.o
obj += obj/drive_detect.o
obj += obj/eload.o
obj += obj/eload_read.o
obj += obj/eload_read_byte.o
obj += obj/eload_close.o
obj += obj/eload_dos.o

.PHONY: all
all: eload.lib

.PHONY: test
test: eload_test.prg

obj/%.o: src/%.s $(inc) | obj
	ca65 -I src -t c64 -o $@ $<

obj:
	mkdir -p obj

eload.lib: $(obj)
	rm -f $@
	ar65 a $@ $(obj)

eload_test.prg: src/eload_test.c eload.lib
	cl65 -g -O -I src -m $@.map -o $@ $^

.PHONY: clean
clean:
	rm -f $(obj)
	rm -rf obj
	rm -f eload.lib
	rm -f eload_test.prg
	rm -f eload_test.prg.map

.PHONY: distclean
distclean: clean
	rm -f *~

