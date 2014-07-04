
pdfs := ../EasyFlash-ProgRef.pdf
pdfs += ../EasyFlash-AppSupport.pdf

.PHONY: all
all: $(pdfs)


../%.pdf: %.pdf
	cp $^ $@

%.pdf: src/%.tex
	pdflatex $^
	pdflatex $^

.PHONY: clean
clean:
	rm -f *.toc
	rm -f *.dvi
	rm -f *.aux
	rm -f *.log
	rm -f *.out

