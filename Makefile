#######################################################################
# Build maint-guide
# vim: set ts=8:
#######################################################################
### key adjustable parameters
#######################################################################
# base file name excluding file extension
MANUAL	:=	maint-guide
# languages translated with PO files
LANGPO	:=	ca de es fr it ja ru de zh-cn zh-tw
# languages to skip generation of PDF files
NOPDF	:=	zh-cn zh-tw
# languages to build document
LANGALL	=	en $(LANGPO)

ifndef PUBLISHDIR
PUBLISHDIR	:= $(CURDIR)/html
endif

# Change $(DRAFTMODE) from "yes" to "maybe" when this document 
# should go into production mode
#DRAFTMODE      := yes
DRAFTMODE       := maybe
export DRAFTMODE
#######################################################################
### basic constant parameters
#######################################################################
# Directories (no trailing slash)
DXSL	:=	xslt
DBIN	:=	bin
DPO	:=	po
DIMG	:=	/usr/share/xml/docbook/stylesheet/nwalsh/images

# Program name and option
XLINT	:=	xmllint --format
XPNO	:=	xsltproc --novalid --nonet
XPINC	:=	xsltproc --novalid --nonet --xinclude
# The threshold should be 80 if translation is completed.
THRESHOLD:=	0
TRANSLATE:=	po4a-translate  -M utf-8          --format docbook --keep $(THRESHOLD) -v 
GETTEXT	:=	po4a-gettextize -M utf-8 -L utf-8 --format docbook
UPDATEPO:=	msgmerge --update --previous
MSGATTR	:=	msgattrib
MSGCAT	:=	msgcat
DBLATEX	:=	dblatex

# source XML inclusion files (excluding version.ent)
ENT_STAT:=	common.ent $(addsuffix .ent, $(addprefix  $(DPO)/, $(LANGPO)))
ENT_ALL	:=	$(ENT_STAT) version.ent
# source PO files for all languages (build prcess requires these)
SRC_PO	:=	$(addsuffix .po, $(addprefix  $(DPO)/, $(LANGPO)))
# source XML files for all languages (build prcess requires these)
SRC_XML	:=	$(addsuffix .dbk, $(addprefix  $(MANUAL)., $(LANGALL)))

#######################################################################
# Used as $(call check-command, <command>, <package>)
define check-command
set -e; if ! which $(1) >/dev/null; then \
  echo "Missing command: $(1), install package: $(2)"; \
  false; \
fi
endef

#######################################################################
# $ make all       # build all
#######################################################################
.PHONY: all
# set LANGPO to limit language to speed up build
all: css html txt pdf epub 

#######################################################################
# $ make test      # build html for testing (for Translator)
#######################################################################
.PHONY: test
test: html css

#######################################################################
# $ make publish   # build html text from RAWXML/PO for DDP
#######################################################################
.PHONY: package
# $(PUBLISHDIR) is set to be: /org/www.debian.org/www/doc/manuals for master-www
publish:
	-mkdir -p $(PUBLISHDIR)/$(MANUAL)
	$(MAKE) css html txt "PUBLISHDIR=$(PUBLISHDIR)/$(MANUAL)"

#######################################################################
# $ make clean     # clean files ready for tar 
#######################################################################
.PHONY: clean
clean:
	-rm -f *.swp *~ *.tmp
	-rm -f $(DPO)/*~ $(DPO)/*.mo $(DPO)/*.po.*
	-rm -rf $(CURDIR)/html $(CURDIR)/tmp
	-rm -f $(addsuffix .dbk, $(addprefix $(MANUAL)., $(LANGPO)))

#######################################################################
# $ make distclean # clean files to reset RAWXML/ENT/POT
#######################################################################
.PHONY: distclean
distclean: clean
	-rm -f version.ent
	-rm -f $(DPO)/*.pot
	-rm -f fuzzy.log

##############################################################################
# Version file preparations
##############################################################################
# version from debian/changelog
# if for www-master directly building from subversion source 
version.ent: $(MANUAL).en.dbk
	echo "<!ENTITY docisodate \"$(shell LC_ALL=C date -u +'%F %T %Z')\">" > version.ent
	[ -r debian/changelog ] && \
	echo "<!ENTITY docversion \"$(shell LC_ALL=C dpkg-parsechangelog | grep '^Version: ' | sed 's/^Version: *//')-svn\">" >> version.ent ||\
	echo "<!ENTITY docversion \"unknown version\">" >> version.ent

#######################################################################
# $ make po        # update all PO from RAWXML
#######################################################################
.PHONY: po pot
pot: $(DPO)/templates.pot
po: $(SRC_PO)

# Do not record line number to avoid useless diff in po/*.po files: --no-location
# Do not update templates.pot if contents are the same as before; -I '^"POT-Creation-Date:'
$(DPO)/templates.pot: $(MANUAL).en.dbk FORCE
	@$(call check-command, po4a-gettextize, po4a)
	@$(call check-command, msgcat, gettext)
	$(GETTEXT) -m $(MANUAL).en.dbk | $(MSGCAT) --no-location -o $(DPO)/templates.pot.new -
	if diff -I '^"POT-Creation-Date:' -q $(DPO)/templates.pot $(DPO)/templates.pot.new ; then \
	  echo "Don't update templates.pot" ;\
	  touch $(DPO)/templates.pot ;\
	  rm -f $(DPO)/templates.pot.new ;\
	else \
	  echo "Update templates.pot" ;\
	  mv -f $(DPO)/templates.pot.new $(DPO)/templates.pot ;\
	fi
	: > fuzzy.log

# Always update
$(DPO)/%.po: $(DPO)/templates.pot FORCE
	@$(call check-command, msgmerge, gettext)
	$(UPDATEPO) $(DPO)/$*.po $(DPO)/templates.pot
	MESS1="no-obsolete  $*  `$(MSGATTR) --no-obsolete  $(DPO)/$*.po |grep ^msgid |sed 1d|wc -l`";\
	MESS2="untranslated $*  `$(MSGATTR) --untranslated $(DPO)/$*.po |grep ^msgid |sed 1d|wc -l`";\
	MESS3="fuzzy        $*  `$(MSGATTR) --fuzzy        $(DPO)/$*.po |grep ^msgid |sed 1d|wc -l`";\
	echo "$$MESS1" >>fuzzy.log ; \
	echo "$$MESS2" >>fuzzy.log ; \
	echo "$$MESS3" >>fuzzy.log ; \
	echo "" >>fuzzy.log

FORCE:

#######################################################################
# $ make wrap       # wrap all PO
#######################################################################
.PHONY: wrap nowrap wip
wrap:
	@$(call check-command, msgcat, gettext)
	for XX in $(foreach LX, $(LANGPO), $(DPO)/$(LX).po); do \
	$(MSGCAT) -o $$XX $$XX ;\
	done
nowrap:
	@$(call check-command, msgcat, gettext)
	for XX in $(foreach LX, $(LANGPO), $(DPO)/$(LX).po); do \
	$(MSGCAT) -o $$XX --no-wrap $$XX ;\
	done

wip:
	@$(call check-command, msgattrib, gettext)
	for XX in $(foreach LX, $(LANGPO), $(DPO)/$(LX).po); do \
	$(MSGATTR) -o $$XX.fuzz --fuzzy        $$XX ;\
	$(MSGATTR) -o $$XX.untr --untranslated $$XX ;\
	done

#######################################################################
# $ make dbk       # update all *.dbk from EN.DBK/ENT/PO/ADD
#######################################################################
.PHONY: xml
xml: $(SRC_XML)

$(MANUAL).en.dbk:
	: # This should exist in the source.

$(MANUAL).%.dbk: $(DPO)/%.po $(MANUAL).en.dbk
	@$(call check-command, po4a-translate, po4a)
	@$(call check-command, msgcat, gettext)
	if [ -f $(DPO)/$*.add ]; then \
	$(TRANSLATE) -m $(MANUAL).en.dbk -a $(DPO)/$*.add -p $(DPO)/$*.po -l $(MANUAL).$*.dbk ;\
	else \
	$(TRANSLATE) -m $(MANUAL).en.dbk -p $(DPO)/$*.po -l $(MANUAL).$*.dbk ;\
	fi
	sed -i -e 's/$(DPO)\/en\.ent/$(DPO)\/$*.ent/' $@

#######################################################################
# $ make css       # update CSS and DIMG in $(PUBLISHDIR)
#######################################################################
.PHONY: css
css:
	-rm -rf $(PUBLISHDIR)/images
	mkdir -p $(PUBLISHDIR)/images
	cp -f $(DXSL)/$(MANUAL).css $(PUBLISHDIR)/$(MANUAL).css
	echo "AddCharset UTF-8 .txt" > $(PUBLISHDIR)/.htaccess
	cd $(DIMG) ; cp caution.png home.gif important.png next.gif note.png prev.gif tip.png up.gif warning.png $(PUBLISHDIR)/images

#######################################################################
# $ make html      # update all HTML in $(PUBLISHDIR)
#######################################################################
.PHONY: html
html:	$(foreach LX, $(LANGALL), $(PUBLISHDIR)/index.$(LX).html)

$(PUBLISHDIR)/index.%.html: $(MANUAL).%.dbk $(ENT_ALL)
	@$(call check-command, xsltproc, xsltproc)
	-mkdir -p $(PUBLISHDIR)
	$(XPINC)   --stringparam root.filename index \
		--stringparam base.dir $(PUBLISHDIR)/ \
                --stringparam html.ext .$*.html \
                --stringparam html.stylesheet $(MANUAL).css \
                xslt/style-html.xsl $<

#######################################################################
# $ make txt       # update all Plain TEXT in $(PUBLISHDIR)
#######################################################################
.PHONY: txt
txt:	$(foreach LX, $(LANGALL), $(PUBLISHDIR)/$(MANUAL).$(LX).txt)

# txt.xsl provides work around for hidden URL links by appending them explicitly.
$(PUBLISHDIR)/$(MANUAL).%.txt: $(MANUAL).%.dbk $(ENT_ALL)
	@$(call check-command, w3m, w3m)
	@$(call check-command, xsltproc, xsltproc)
	-mkdir -p $(PUBLISHDIR)
	@test -n "`which w3m`"  || { echo "ERROR: w3m not found. Please install the w3m package." ; false ;  }
	$(XPINC) $(DXSL)/txt.xsl $< | LC_ALL=en_US.UTF-8 w3m -o display_charset=UTF-8 -cols 70 -dump -no-graph -T text/html > $@


#######################################################################
# $ make pdf       # update all PDF in $(PUBLISHDIR)
#######################################################################
.PHONY: pdf
pdf:	$(foreach LX, $(LANGALL), $(PUBLISHDIR)/$(MANUAL).$(LX).pdf)

$(foreach LX, $(NOPDF), $(PUBLISHDIR)/$(MANUAL).$(LX).pdf):
	-mkdir -p $(PUBLISHDIR)
	echo "PDF generation skipped." >$@

# dblatex.xsl provide work around for hidden URL links by appending them explicitly.
$(PUBLISHDIR)/$(MANUAL).%.pdf: $(MANUAL).%.dbk $(ENT_ALL)
	@$(call check-command, dblatex, dblatex)
	@$(call check-command, xsltproc, xsltproc)
	-mkdir -p $(PUBLISHDIR)
	-mkdir -p $(CURDIR)/tmp/$*
	@test -n "`which $(DBLATEX)`"  || { echo "ERROR: dblatex not found. Please install the dblatex package." ; false ;  }
	export TEXINPUTS=".:"; \
	export TMPDIR="$(CURDIR)/tmp/$*"; \
	$(XPINC) $(DXSL)/dblatex.xsl $<  | \
	$(DBLATEX) --style=native \
		--debug \
		--backend=xetex \
		--xsl-user=$(DXSL)/user_param.xsl \
		--xsl-user=$(DXSL)/xetex_param.xsl \
		--param=draft.mode=$(DRAFTMODE) \
		--param=lingua=$* \
		--output=$@ - || { echo "OMG!!!!!! XXX_CHECK_XXX ... Do not worry ..."; true ; }

#######################################################################
# $ make tex       # update all TeX source in $(PUBLISHDIR)
#######################################################################
.PHONY: tex
tex:	$(foreach LX, $(LANGALL), $(PUBLISHDIR)/$(MANUAL).$(LX).tex)

# dblatex.xsl provide work around for hidden URL links by appending them explicitly.
$(PUBLISHDIR)/$(MANUAL).%.tex: $(MANUAL).%.dbk $(ENT_ALL)
	-mkdir -p $(PUBLISHDIR)
	-mkdir -p $(CURDIR)/tmp/$*
	@test -n "`which $(DBLATEX)`"  || { echo "ERROR: dblatex not found. Please install the dblatex package." ; false ;  }
	export TEXINPUTS=".:"; \
	export TMPDIR="$(CURDIR)/tmp/$*"; \
	$(XPINC) $(DXSL)/dblatex.xsl $<  | \
	$(DBLATEX) --style=native \
		--debug \
		--type=tex \
		--backend=xetex \
		--xsl-user=$(DXSL)/user_param.xsl \
		--xsl-user=$(DXSL)/xetex_param.xsl \
		--param=draft.mode=$(DRAFTMODE) \
		--param=lingua=$* \
		--output=$@ - || { echo "OMG!!!!!! XXX_CHECK_XXX ... Do not worry ..."; true ; }

#######################################################################
# $ make epub      # update all epub in $(PUBLISHDIR)
#######################################################################
.PHONY: epub
epub:	$(foreach LX, $(LANGALL), $(PUBLISHDIR)/$(MANUAL).$(LX).epub)

$(PUBLISHDIR)/$(MANUAL).%.epub: $(MANUAL).%.dbk $(ENT_ALL)
	@$(call check-command, dbtoepub, dbtoepub)
	-mkdir -p $(PUBLISHDIR)
	#xmlto epub -m $(DXSL)/$(MANUAL).css -o $(PUBLISHDIR) $<
	dbtoepub -o $(PUBLISHDIR)/$(MANUAL).$*.epub -c $(DXSL)/$(MANUAL).css  $<

#######################################################################
### Utility targets
#######################################################################
#######################################################################
# $ make url       # check duplicate URL references
#######################################################################
.PHONY: url
url: $(MANUAL).en.dbk
	@echo "----- Duplicate URL references (start) -----"
	-sed -ne "/^<\!ENTITY/s/<\!ENTITY \([^ ]*\) .*$$/\" \1 \"/p"  < $< | uniq -d | xargs -n 1 grep $< -e  | grep -e "^<\!ENTITY"
	@echo "----- Duplicate URL references (end) -----"

