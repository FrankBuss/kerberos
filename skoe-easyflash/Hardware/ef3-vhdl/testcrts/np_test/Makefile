
np_test.crt: np_test.s
	acme -o np_test.bin np_test.s
	cartconv -t ap -i np_test.bin -o np_test.crt

.PHONY: clean
clean:
	rm -f np_test.bin np_test.crt
