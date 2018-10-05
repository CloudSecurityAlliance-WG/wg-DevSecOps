SRC  := $(wildcard csand-*.adoc)
XML  := $(patsubst %.adoc,%.xml,$(SRC))
HTML := $(patsubst %.adoc,%.html,$(SRC))
DOC  := $(patsubst %.adoc,%.doc,$(SRC))
PDF  := $(patsubst %.adoc,%.doc,$(PDF))

SHELL := /bin/bash

all: $(HTML) $(XML) $(PDF) $(DOC)

clean: clean-doc clean-xml clean-html clean-pdf

clean-doc:
	rm -f $(DOC)

clean-pdf:
	rm -f $(PDF)

clean-xml:
	rm -f $(XML)

clean-html:
	rm -f $(HTML)

bundle:
	bundle

%.xml %.html %.doc %.pdf:	%.adoc | bundle
	bundle exec metanorma -t csand -x doc,pdf,xml,html $^

html: clean-html $(HTML)

open:
	open $(HTML)

.PHONY: bundle all open
