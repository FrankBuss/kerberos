

inc :=
inc += src/drivetype.s
inc += src/kernal.s
inc += src/xfer_drive_1mhz.s
inc += src/xfer_drive_2mhz.s

obj := 
obj += obj/drive_1541.o
obj += obj/drive_1541_write.o
obj += obj/drive_1541_format.o
#obj += obj/drive_1571.o
#obj += obj/drive_1581.o
obj += obj/drive_sd2iec.o
obj += obj/send_code.o
obj += obj/drive_detect.o
#obj += obj/eload.o

obj += obj/eload_send.o
obj += obj/eload_send_nodma.o
obj += obj/eload_sendtab.o
obj += obj/eload_recv.o
obj += obj/eload_format.o
obj += obj/eload_checksum.o

obj += obj/eload_read_byte.o
obj += obj/eload_close.o
obj += obj/eload_dos.o

obj += obj/eload_read.o
obj += obj/eload_write_sector.o
obj += obj/eload_write_sector_nodma.o
obj += obj/eload_recv_block.o

test_obj :=
test_obj += obj/crt0.o
test_obj += obj/eload_test.o
test_obj += obj/gcr.o

disk_type := g64

.PHONY: all
all: eload.lib 

.PHONY: test
test: test.$(disk_type)

obj/%.o: src/%.s obj $(inc)
	ca65 -I src -t c64 -o $@ $<

obj/%.o: obj/%.s obj $(inc)
	ca65 -I src -t c64 -o $@ $<

obj/%.s: test/%.c obj $(inc)
	cc65 -I src -O -t c64 -o $@ $<

obj/%.o: test/%.s obj $(inc)
	ca65 -I src -t c64 -o $@ $<

obj:
	mkdir -p obj

eload.lib: $(obj)
	rm -f $@
	ar65 a $@ $(obj)

test.$(disk_type): eload_test.prg
	c1541 -format test,td $(disk_type) $@ 8 \
		-write eload_test.prg etest

eload_test.prg: $(test_obj) eload.lib
	ld65 -o $@ -m $@.map -C test/ld.cfg -L /usr/local/lib/cc65/lib \
		$(test_obj) --lib eload.lib --lib c64.lib

clean:
	rm -rf obj
	rm -f eload.lib
	rm -f eload_test.prg
	rm -f eload_test.prg.map

distclean: clean
	rm -f *~
