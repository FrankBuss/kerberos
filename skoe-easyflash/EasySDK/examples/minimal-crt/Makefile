
minimal.crt: minimal.s
	acme -o minimal.bin minimal.s
	cartconv -t normal -i minimal.bin -o minimal.crt

.PHONY: clean
clean:
	rm -f minimal.bin minimal.crt
