# Copyright 2015-2018 Mitchell mitchell.att.foicica.com. See LICENSE.

# Run test suite.

.PHONY: tests
tests:
	cd tests && lua suite.lua

# Documentation.

doc: manual luadoc
manual: *.md | doc/bombay
	$| -d doc -t doc --title Lupa $^
luadoc: lupa.lua
	luadoc -d doc -t doc --doclet doc/markdowndoc $^
cleandoc: ; rm -rf doc/README.html doc/api.html

# Release.

basedir = lupa_$(shell grep '^\#\#' CHANGELOG.md | head -1 | cut -d ' ' -f 2)

$(basedir): ; hg archive $@ -X ".hg*"
release: $(basedir)
	make doc
	cp -r doc $<
	zip -r /tmp/$<.zip $< && rm -r $<

# External dependencies.

bombay_zip = bombay.zip

$(bombay_zip):
	wget "http://foicica.com/hg/bombay/archive/tip.zip" && mv tip.zip $@
doc/bombay: | $(bombay_zip)
	mkdir $(notdir $@) && unzip -d $(notdir $@) $| && \
		mv $(notdir $@)/*/* $(dir $@)
