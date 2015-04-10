.PHONY: all dl test zip clean burn libs dirs
.DELETE_ON_ERROR:

latexmk := latexmk
Rscript := Rscript
sqlite  := sqlite3
LATEXMKFLAGS := -pdf -silent
SHELL := /bin/bash
version := $(shell git describe --tags)

dl all test: oosbootstrap.pdf

# Use different configuration files for `make test` and store the
# results in another directory
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

# For `make dl` we're going to download pre-computed monte carlo and
# empirical results
ifeq ($(MAKECMDGOALS),dl)
oosbootstrap_$(version).zip: %: ~/Desktop/%
	cp $< ./
$(montecarlodir)/west_iv.tex $(empiricsdir)/excessreturns.tex: oosbootstrap_$(version).zip
	unzip -u $< $@
else
oosbootstrap_$(version).zip: oosbootstrap.pdf empirics.full/excessreturns.tex montecarlo.full/west_iv.tex
	zip $@ $^
$(empiricsdir)/excessreturns.tex: empirics.src/excessreturns.R \
  empirics.src/yearlyData2009.csv $(empiricsconfig) | $(empiricsdir)
	$(Rscript) $(RSCRIPTFLAGS) $< $@ $(filter-out $<,$^)
$(montecarlodir)/west_iv.tex: $(montecarlodir)/west_iv.csv | $(montecarlodir)
	touch $@
endif

dirs: tex db
tex db:
	mkdir -p $@

empirics.staged/excessreturns.tex: empirics.staged/%: $(empiricsdir)/% | empirics.staged
	cp $< $@
montecarlo.staged/west_iv.tex: montecarlo.staged/%: $(montecarlodir)/% | montecarlo.staged
	cp $< $@

$(montecarlodir)/west_iv.csv: montecarlo.src/west_iv.jl $(montecarloconfig) | $(montecarlodir)
	julia $< $@ $(notdir $(montecarloconfig))

empirics.staged $(empiricsdir) montecarlo.staged $(montecarlodir):
	mkdir -p $@

oosbootstrap.pdf: oosbootstrap.tex empirics.staged/excessreturns.tex \
  montecarlo.staged/west_iv.tex
	$(latexmk) $(LATEXMKFLAGS) $<

# For `make zip` we're going to make a zipfile with the monte carlo
# and empirical results, then upload it to an accessible location.
zip: oosbootstrap.pdf oosbootstrap_$(version).stamp oosbootstrap_$(version).zip
oosbootstrap_$(version).stamp: %.stamp: %.zip
# This next line needs to be replaced with the real upload commands
	cp $< ~/Desktop/$<
	touch $@

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
