##############################################################################
# Makefile for the Debian New Maintainers' Guide
##############################################################################

# Note: This Makefile should work perfectly without the debian/ directory.

# Required packages for building documentation source
# basic:		xsltproc, docbook-xsl (These are dependency of dblatex)
# i18n:			po4a
# plain text conv.:	w3m
# pdf via pdflatex:	dblatex, ghostscript, lmodern, texlive-lang-*
# pdf via xelatex:	texlive-xelatex, (ttf-font-packages)

##############################################################################
# Package specific customization
##############################################################################
# package name
MANUAL		:= maint-guide
# common inclusion entity files (excluding version)
COMMON_ENT	:= common.ent
# format to be built
FORMATS		:= html txt pdf
##############################################################################
# PDF build tool customization for each lunguage
##############################################################################
# languages supported by direct DocBook files (always: en)
LANGS_EN	:= en
# languages supported by translation PO files
LANGS_PO	:= ca de es fr it ja ru de zh-cn zh-tw
# ca: 99%
# de: 24%
# es: 97%
# fr: 100%
# it: 100%
# ja: 100%
# ru: 100%
# zh-cn: 33%
# zh-tw:28%
# 
# dblatex is used as the default PDF build tool
# No PDF build for these lunguages (in case of error, use this as work around)
LANGS_NOPDF		:= zh-cn zh-tw 
# all languages to build
LANGS		:= $(LANGS_EN) $(LANGS_PO)
# local script file directory
SCRIPT		:= script
# translation contents directory such as PO file
PO4A		:= po4a
# The translation threshold percent should be 80, if translation is completed.
THRESHOLD	:= 0
# XSLT (Extensible Stylesheet Language Transformations) file directory
XSLT		:= xslt
# manual publish directory
ifeq ($(PUBLISHDIR),)
# local test build
MANUALDIR	:= $(CURDIR)/html
else
# www-master.debian.org build script.
MANUALDIR       := $(abspath $(PUBLISHDIR)/$(MANUAL))
endif
XTMPDIR	:= $(CURDIR)/tmp
# CSS (Cascading Style Sheets) file
CSS		:= $(MANUAL).css
# Image files
IMAGES		:= caution.png home.gif important.png next.gif note.png prev.gif tip.png up.gif warning.png draft.png
IMAGESSRC	:= /usr/share/xml/docbook/stylesheet/nwalsh/images
IMAGESDIR	:= $(MANUALDIR)/images

# install
install_file	:= install -p -m 664
install_dir	:= install -d -m 2775

# Change $(DRAFTMODE) from "yes" to "maybe" when this $(MANUAL) should go into
# production mode
#DRAFTMODE      := yes
DRAFTMODE       := maybe
export DRAFTMODE
##############################################################################
# PO update
##############################################################################
# Usually, POMODE =  update|static
POMODE	:= static

##############################################################################
# build tool customization for debug etc.
##############################################################################
XP		:= xsltproc --nonet --novalid --xinclude
XL		:= xmllint --nonet --noout --postvalid --xinclude
# Set $(DEBUG) to activate debug mode
ifeq ($(DEBUG),)
DBLATEX		:= dblatex
else
DBLATEX		:= dblatex --verbose --dump --debug
endif
##############################################################################
# Basic phony targets
##############################################################################
.PHONY: all build build-indep
all: build

build: build-indep

build-indep:	$(foreach lng,$(LANGS), $(foreach fmt, $(filter-out html, $(FORMATS)), $(MANUAL).$(lng).$(fmt))) \
		$(foreach lng,$(LANGS), $(foreach fmt, $(filter     html, $(FORMATS)),     index.$(lng).html))

##############################################################################
# Utility phony targets
##############################################################################
.PHONY: dbk dbk-orig txt html pdf po pot
txt:	$(foreach lng,$(LANGS), $(MANUAL).$(lng).txt)
html:	$(foreach lng,$(LANGS), index.$(lng).html)
pdf:	$(foreach lng,$(LANGS), $(MANUAL).$(lng).pdf)
po:
	touch $(MANUAL).en.dbk
	$(MAKE) $(foreach lng, $(LANGS_PO), $(PO4A)/$(MANUAL).$(lng).po) POMODE=update
pot:	$(PO4A)/$(MANUAL).pot
dbk:	$(foreach lng,$(LANGS_PO), $(MANUAL).$(lng).dbk)

##############################################################################
# Conditional branching variable
##############################################################################
# Conditional branching of build process is implimented by recursively calling
# this Makefile.  The first level executon of this Makefile calls $(MAKE) with
# the controlling variable $(LINGUA).  The second level executon of this
# Makefile uses $(LINGUA) as conditional branching.  Initial value of $(LINGUA)
# is "".
LINGUA		:=

##############################################################################
# Version file preparations
##############################################################################
# version from debian/changelog
ifeq ($(PUBLISHDIR),)
# if not for www-master (e.g., package building)
version.ent:
	echo "<!ENTITY docisodate \"$(shell LC_ALL=C date -u +'%F %T %Z')\">" > version.ent
	[ -r debian/changelog ] && \
	echo "<!ENTITY docversion \"$(shell LC_ALL=C dpkg-parsechangelog | grep '^Version: ' | sed 's/^Version: *//')\">" >> version.ent ||\
	echo "<!ENTITY docversion \"unknown version\">" >> version.ent
else
# if for www-master directly building from subversion source 
version.ent:
	echo "<!ENTITY docisodate \"$(shell LC_ALL=C date -u +'%F %T %Z')\">" > version.ent
	[ -r debian/changelog ] && \
	echo "<!ENTITY docversion \"$(shell LC_ALL=C dpkg-parsechangelog | grep '^Version: ' | sed 's/^Version: *//')-svn\">" >> version.ent ||\
	echo "<!ENTITY docversion \"unknown version\">" >> version.ent
endif
##############################################################################
# DocBook XML source file preparations
##############################################################################
$(MANUAL).en.dbk:
	# This is source
	@true

# Generate base localized DocBook XML files for all non-"en"
# This does not depend on $(PO4A)/$(MANUAL).%.po intentionally 
# to aviod automatic update of $(PO4A)/$(MANUAL).%.po.
$(MANUAL).%.dbk: $(MANUAL).en.dbk $(PO4A)/$(MANUAL).%.ent $(PO4A)/$(MANUAL).%.po
	po4a-translate --format docbook --keep $(THRESHOLD) --master-charset UTF-8 \
		--master $< --po $(PO4A)/$(MANUAL).$*.po --localized $@ ;\
	sed -i -e 's/$(PO4A)\/$(MANUAL)\.en\.ent/$(PO4A)\/$(MANUAL).$*.ent/' $@ ;\

##############################################################################
# DocBook PO source file preparations
##############################################################################
ifeq ($(POMODE),update)
# Always update localized PO files while making PO template(pot) as needed
# .PHONY as follows does not work nicely with %, thus FORCE is used here.
#.PHONY: $(foreach lng, $(LANGS_PO), $(PO4A)/$(MANUAL).$(lng).po)
$(PO4A)/$(MANUAL).%.po: FORCE
	$(MAKE) $(PO4A)/$(MANUAL).pot
	msgmerge --update --previous $@ $(PO4A)/$(MANUAL).pot
else

$(PO4A)/$(MANUAL).%.po: FORCE
	: # do nothing
endif

# Generate PO template(pot) file from English DocBook XML file
# make sure no location line for easier merge.
$(PO4A)/$(MANUAL).pot: $(MANUAL).en.dbk
	po4a-gettextize --format docbook --master-charset UTF-8 --master $< |\
	msgcat --no-location - > $@

##############################################################################
# Plain text building
##############################################################################
# Generate formatted output in single page plain text
# txt.xsl provide work around for hidden URL links by appending them explicitly.
$(MANUAL).%.txt: $(MANUAL).%.dbk $(COMMON_ENT)
	[ -e version.ent ] || $(MAKE) version.ent
	@test -n "`which w3m`"  || { echo "E: w3m not found. Please install the w3m package." ; false ;  }
	$(XP) $(XSLT)/txt.xsl $< |\
		LC_ALL=C.UTF-8 w3m -o display_charset=UTF-8 -cols 70 -dump -no-graph -T text/html > $@

##############################################################################
# HTML text building
##############################################################################
# Generate formatted output in multi-page html text
index.%.html: $(MANUAL).%.dbk $(COMMON_ENT)
	[ -e version.ent ] || $(MAKE) version.ent
	$(XP) --stringparam draft.mode $(DRAFTMODE) \
		--stringparam root.filename index \
                --stringparam html.ext .$*.html \
                --stringparam html.stylesheet $(MANUAL).css \
		$(XSLT)/html.xsl $<

##############################################################################
# PDF building (conditional)
##############################################################################

ifeq ($(LINGUA),)
# if $(LINGUA) is "" (unset == inital call)

$(MANUAL).%.pdf: $(MANUAL).%.dbk $(COMMON_ENT)
	[ -e version.ent ] || $(MAKE) version.ent
	# This calls itself while setting LINGUA (conditional trick) for $@
	make "LINGUA=$*" $@

$(MANUAL).%.tex: $(MANUAL).%.dbk $(COMMON_ENT)
	[ -e version.ent ] || $(MAKE) version.ent
	# This calls itself while setting LINGUA (conditional trick) for $@
	make "LINGUA=$*" $@

else ifeq ($(filter-out $(LANGS_NOPDF),$(LINGUA)),)
# if $(LINGUA) belongs to $(LANGS_NOPDF)

$(MANUAL).$(LINGUA).pdf: $(MANUAL).$(LINGUA).dbk $(COMMON_ENT)
	echo "PDF building for $(LINGUA) currently disabled." > $@

else
# build with xelatex backend

$(MANUAL).$(LINGUA).pdf: $(MANUAL).$(LINGUA).dbk $(COMMON_ENT)
	@test -n "`which $(DBLATEX)`"  || { echo "E: dblatex not found. Please install the dblatex package." ; false ;  }
	@mkdir -p $(XTMPDIR)
	export TMPDIR=$(XTMPDIR) ; \
	export TEXINPUTS=".:" ; \
	$(XP) $(XSLT)/dblatex.xsl $<  | \
	$(DBLATEX) --style=db2latex \
		--backend=xetex \
		--xsl-user=$(XSLT)/user_param.xsl \
		--xsl-user=$(XSLT)/xetex_param.xsl \
		--param=draft.mode=$(DRAFTMODE) \
		--param=lingua=$(LINGUA) \
		--output=$@ -

$(MANUAL).$(LINGUA).tex: $(MANUAL).$(LINGUA).dbk $(COMMON_ENT)
	@test -n "`which $(DBLATEX)`"  || { echo "E: dblatex not found. Please install the dblatex package." ; false ;  }
	@mkdir -p $(XTMPDIR)
	export TMPDIR=$(XTMPDIR) ; \
	export TEXINPUTS=".:"; \
	$(XP) $(XSLT)/dblatex.xsl $<  | \
	$(DBLATEX) --style=db2latex \
		--type=tex \
		--backend=xetex \
		--xsl-user=$(XSLT)/user_param.xsl \
		--xsl-user=$(XSLT)/xetex_param.xsl \
		--param=draft.mode=$(DRAFTMODE) \
		--param=lingua=$(LINGUA) \
		--output=$@ -

endif

##############################################################################
# This rule controls the build and installation on the website
# Logs are here: http://www-master.debian.org/build-logs/ddp/
# For web page building (publish)
# this can and will be overriden by a higher level makefile
##############################################################################
.PHONY: publish
publish:
	# next lines are for transition
	-$(MAKE) clean
	# real publish target
	-rm -f version.ent
	$(MAKE) version.ent
	$(MAKE) html txt pdf
	[ -d $(IMAGESDIR) ] || $(install_dir) $(IMAGESDIR)
	$(install_file) *.html		$(MANUALDIR)
	$(install_file) $(MANUAL).*.txt $(MANUALDIR)
	$(install_file) $(MANUAL).*.pdf $(MANUALDIR)
	$(install_file) $(CSS) 		$(MANUALDIR)
	echo "AddCharset UTF-8 .txt" > $(MANUALDIR)/.htaccess
	$(install_file) $(addprefix $(IMAGESSRC)/, $(IMAGES)) $(IMAGESDIR)

##############################################################################
# Special utility targets used only by the maintainer
##############################################################################
.PHONY:	tw
# Translate from zh-cn to zh-tw (semi-automatic)
tw:
	msgcat --no-wrap $(PO4A)/$(MANUAL).zh-cn.po | opencc | sed -f $(BIN)/cn2tw.sed | msgcat - > $(PO4A)/$(MANUAL).zh-tw.po

# phony targets for PO maintainances
.PHONY:  tidypo
tidypo:
	for f in $(LANGS_PO); do msgcat --no-location $(PO4A)/$(MANUAL).$$f.po | sponge $(PO4A)/$(MANUAL).$$f.po ; done
	msgcat --no-location $(PO4A)/$(MANUAL).pot | sponge $(PO4A)/$(MANUAL).pot

##############################################################################
# Special utility targets used by the maintainer and translators
##############################################################################
.PHONY:  checkpo
checkpo:
	for f in $(LANGS_PO); do msgfmt --check --verbose $(PO4A)/$(MANUAL).$$f.po | sponge $(PO4A)/$(MANUAL).$$f.po; done
	msgfmt --check --verbose $(PO4A)/$(MANUAL).pot | sponge $(PO4A)/$(MANUAL).pot

.PHONY:  validate
validate: $(foreach lng,$(LANGS_PO),$(MANUAL).$(lng).dbk) $(COMMON_ENT)
	for f in $(LANGS_PO); do $(XL) $(MANUAL).$$f.dbk; done

##############################################################################
# Basic utility targets for clean
##############################################################################
.PHONY: clean distclean prep
clean:
	rm -f version.ent
	rm -rf $(MANUALDIR)
	rm -rf $(XTMPDIR)
	rm -f $(foreach lng, $(LANGS_PO), $(MANUAL).$(lng).dbk)
	-rm -rf *.fo *.pdf *.txt *.html *.rej
	rm -f *~ *.bak .#*
	rm -f $(PO4A)/*.mo $(PO4A)/*~ $(PO4A)/*.bak
	rm -f *.cb *.cb2 *.glo *.idx *.log *.out *.tex *.toc *.aux

distclean: clean

prep:
	debian/rules prep

# if rule bomb out, delete the target
#.DELETE_ON_ERROR:

FORCE:

