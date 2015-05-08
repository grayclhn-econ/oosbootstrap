.PHONY: all dl full test zip clean burn libs dirs source
.DELETE_ON_ERROR:

latexmk := latexmk
Rscript := Rscript
sqlite  := sqlite3
SHELL := /bin/bash
version = $(shell git describe --tags --abbrev=0)
zipfile = calhoun_oosbootstrap_$(version).zip
pdffile = calhoun_oosbootstrap_$(version).pdf
files = $(filter-out .gitignore TODO.md, \
  $(addprefix texextra/, \
    $(shell cd texextra && git ls-tree --full-tree -r --name-only HEAD)) \
  $(shell git ls-tree --full-tree -r --name-only HEAD))

dl all full test: oosbootstrap.pdf $(zipfile)

source: $(zipfile)
$(zipfile): $(files)
	zip $@ $(files)


# Use different configuration files for `make test` and store the
# results in another directory
ifeq ($(MAKECMDGOALS),test)
  empiricsconfig = empirics.src/config.test
  empiricsdir = empirics.test
  montecarloconfig = montecarlo.src/config.test
  montecarlodir = montecarlo.test
else ifeq '$(MAKECMDGOALS)' ''
  empiricsconfig = empirics.src/config.default
  empiricsdir = empirics.default
  montecarloconfig = montecarlo.src/config.default
  montecarlodir = montecarlo.default
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
$(montecarlodir)/west_iv.pdf $(empiricsdir)/excessreturns.tex: oosbootstrap_$(version).zip
	unzip -u $< $@
else
oosbootstrap_$(version).zip: oosbootstrap.pdf empirics.full/excessreturns.tex montecarlo.full/west_iv.pdf
	zip $@ $^
$(empiricsdir)/excessreturns.tex: empirics.src/excessreturns.R \
  empirics.src/yearlyData2009.csv $(empiricsconfig) | $(empiricsdir)
$(montecarlodir)/west_iv.pdf: montecarlo.src/west_iv_graph.R \
  $(montecarlodir)/west_iv.csv | $(montecarlodir)
$(montecarlodir)/west_iv.tex: montecarlo.src/west_iv_table.R \
  $(montecarlodir)/west_iv.csv | $(montecarlodir)

$(montecarlodir)/west_iv.pdf $(montecarlodir)/west_iv.tex $(empiricsdir)/excessreturns.tex:
	$(Rscript) $(RSCRIPTFLAGS) $< $@ $(filter-out $<,$^)
endif

empirics/excessreturns.tex: empirics/%: $(empiricsdir)/% | empirics
	cp $< $@
montecarlo/west_iv.pdf montecarlo/west_iv.tex: montecarlo/%: \
  $(montecarlodir)/% | montecarlo
	cp $< $@

$(montecarlodir)/west_iv.csv: montecarlo.src/west_iv.jl \
  montecarlo.src/west_iv_functions.jl $(montecarloconfig) | $(montecarlodir)
	julia $< $@ $(notdir $(filter-out $<,$^))

empirics $(empiricsdir) montecarlo $(montecarlodir):
	mkdir -p $@

oosbootstrap.pdf: oosbootstrap.tex empirics/excessreturns.tex \
  montecarlo/west_iv.pdf montecarlo/west_iv.tex
	texi2dvi -p -b -c $<

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
