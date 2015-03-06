.PHONY: all clean burn dirs
all: oosbootstrap.pdf

.DELETE_ON_ERROR:

latexmk := latexmk
Rscript := Rscript
sqlite  := sqlite3
LATEXMKFLAGS := -pdf -silent
SHELL := /bin/bash

dirs: tex
tex:
	mkdir -p $@

oosbootstrap.pdf: oosbootstrap.tex
	$(latexmk) $(LATEXMKFLAGS) $<

clean: 
	$(latexmk) -c oosbootstrap.tex
	rm -f *~ slides/*~ data/*~
burn: clean
	$(latexmk) -C oosbootstrap.tex
	rm -rf R auto tex slides/*.tex

ROPTS = --byte-compile
