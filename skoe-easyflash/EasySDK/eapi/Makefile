
EAPI := out/eapi-sst39vf1681

.PHONY: all
all: $(EAPI)

###############################################################################
out/eapi-sst39vf1681: eapi-sst39vf1681.s | out
	acme -l $@.labels -o $@ $<

###############################################################################
out:
	mkdir -p $@


.PHONY: clean
clean:
	rm -f $(EAPI)
	rm -rf out
