.PHONY: all clean burn libs dirs
all: oosbootstrap.pdf

.DELETE_ON_ERROR:

latexmk := latexmk
Rscript := Rscript
sqlite  := sqlite3
LATEXMKFLAGS := -pdf -silent
SHELL := /bin/bash

dirs: tex db
tex db:
	mkdir -p $@

tex/ap.tex: R/ap.R | tex
	$(Rscript) $(RSCRIPTFLAGS) $< &> $<out

montecarlo.out/west_iv.csv: montecarlo.src/west_iv.jl | montecarlo.out
	julia $< $@
montecarlo.out/west_iv.tex: montecarlo.out/west_iv.csv | montecarlo.out
	touch $@
montecarlo.out:
	mkdir -p $@

oosbootstrap.pdf: oosbootstrap.tex tex/ap.tex montecarlo.out/west_iv.tex
	$(latexmk) $(LATEXMKFLAGS) $<

clean: 
	$(latexmk) -c oosbootstrap.tex
	rm -f *~ slides/*~ data/*~
burn: clean
	$(latexmk) -C oosbootstrap.tex
	rm -rf R auto floats tex slides/*.tex lib 

ROPTS = --byte-compile
libs: 
	mkdir -p lib/oosanalysis.Rcheck lib/dbframe.Rcheck
	R CMD check -o lib/oosanalysis.Rcheck oosanalysis-R-library-0.4.0
	R CMD INSTALL $(ROPTS) --library=lib oosanalysis-R-library-0.4.0
	R CMD check -o lib/dbframe.Rcheck dbframe-R-library-0.4.0
	R CMD INSTALL $(ROPTS) --library=lib dbframe-R-library-0.4.0
