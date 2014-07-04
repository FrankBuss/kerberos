
EAPI := out/eapi-am29f040-14 out/eapi-m29w160t-03 out/eapi-mx29640b-12

.PHONY: all
all: $(EAPI)

###############################################################################
out/eapi-am29f040-14: eapi-am29f040.s | out
	acme -l $@.labels -o $@ $<

out/eapi-m29w160t-03: eapi-m29w160t.s | out
	acme -l $@.labels -o $@ $<

out/eapi-mx29640b-12: eapi-mx29640b.s | out
	acme -l $@.labels -o $@ $<

###############################################################################
out:
	mkdir -p $@


.PHONY: clean
clean:
	rm -f $(EAPI)
	rm -rf out
