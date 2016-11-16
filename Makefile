.PHONY: all clean burn libs dirs
.DELETE_ON_ERROR:

latexmk := latexmk
Rscript := Rscript
sqlite  := sqlite3
SHELL := /bin/bash
version = $(shell git describe --tags --abbrev=0)
files = $(filter-out .gitignore TODO.md, \
  $(addprefix texextra/, \
    $(shell cd texextra && git ls-tree --full-tree -r --name-only HEAD)) \
  $(shell git ls-tree --full-tree -r --name-only HEAD))

all: oosbootstrap.pdf

empirics/excessreturns.tex: empirics/excessreturns.R \
  empirics/yearlyData2009.csv empirics/config
montecarlo/west_iv.pdf: montecarlo/west_iv_graph.R montecarlo/west_iv.csv
montecarlo/west_iv.tex: montecarlo/west_iv_table.R montecarlo/west_iv.csv
montecarlo/west_iv.pdf montecarlo/west_iv.tex empirics/excessreturns.tex:
	$(Rscript) $(RSCRIPTFLAGS) $< $@ $(filter-out $<,$^)

montecarlo/west_iv.csv: montecarlo/west_iv.jl \
  montecarlo/west_iv_functions.jl montecarlo/config
	julia $< $@ $(notdir $(filter-out $<,$^))

oosbootstrap.pdf: oosbootstrap.tex empirics/excessreturns.tex \
  montecarlo/west_iv.pdf montecarlo/west_iv.tex
	texi2dvi -p -b -c $<

clean: 
	$(latexmk) -c oosbootstrap.tex
	rm -f *~ slides/*~ data/*~

burn: clean
	$(latexmk) -C oosbootstrap.tex
	rm -rf R auto lib montecarlo.out empirics.out

ROPTS = --byte-compile
libs: 
	mkdir -p lib/oosanalysis.Rcheck lib/dbframe.Rcheck
	R CMD check -o lib/oosanalysis.Rcheck oosanalysis-R-library-0.4.0
	R CMD INSTALL $(ROPTS) --library=lib oosanalysis-R-library-0.4.0
	R CMD check -o lib/dbframe.Rcheck dbframe-R-library-0.4.0
	R CMD INSTALL $(ROPTS) --library=lib dbframe-R-library-0.4.0
