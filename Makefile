.PHONY: all test clean burn libs dirs
all test: oosbootstrap.pdf
.DELETE_ON_ERROR:

latexmk := latexmk
Rscript := Rscript
sqlite  := sqlite3
LATEXMKFLAGS := -pdf -silent
SHELL := /bin/bash

ifeq ($(MAKECMDGOALS),test)
  empiricsconfig = empirics.src/config.test
  empiricsdir = empirics.test
  montecarloconfig = montecarlo.src/config.test
  montecarlodir = montecarlo.test
else
  empiricsconfig = empirics.src/config.full
  empiricsdir = empirics.full
  montecarloconfig = montecarlo.src/config.full
  montecarlodir = montecarlo.full
endif

dirs: tex db
tex db:
	mkdir -p $@

$(empiricsdir)/excessreturns.tex: empirics.src/excessreturns.R \
  empirics.src/yearlyData2009.csv $(empiricsconfig) | $(empiricsdir)
	$(Rscript) $(RSCRIPTFLAGS) $< $@ $(filter-out $<,$^)
empirics.staged/excessreturns.tex: empirics.staged/%: $(empiricsdir)/% | empirics.staged
	cp $< $@

$(montecarlodir)/west_iv.csv: montecarlo.src/west_iv.jl $(montecarloconfig) | $(montecarlodir)
	julia $< $@ $(notdir $(montecarloconfig))
$(montecarlodir)/west_iv.tex: $(montecarlodir)/west_iv.csv | $(montecarlodir)
	touch $@
montecarlo.staged/west_iv.tex: montecarlo.staged/%: $(montecarlodir)/% | montecarlo.staged
	cp $< $@

empirics.staged $(empiricsdir) montecarlo.staged $(montecarlodir):
	mkdir -p $@

oosbootstrap.pdf: oosbootstrap.tex empirics.staged/excessreturns.tex \
  montecarlo.staged/west_iv.tex
	$(latexmk) $(LATEXMKFLAGS) $<

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
