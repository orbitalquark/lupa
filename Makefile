# Copyright 2015-2020 Mitchell mitchell.att.foicica.com. See LICENSE.

# Run test suite.

.PHONY: tests
tests: ; cd tests && lua5.1 suite.lua

# Documentation.

docs: docs/index.md docs/api.md $(wildcard docs/*.md) | \
      docs/_layouts/default.html
	for file in $(basename $^); do \
		cat $| | docs/fill_layout.lua $$file.md > $$file.html; \
	done
docs/index.md: README.md
	sed 's/^\# [[:alpha:]]\+/## Introduction/;' $< > $@
	sed -i 's|https://[[:alpha:]]\+\.github\.io/[[:alpha:]]\+/||;' $@
	sed -i '1 i {% raw %}' $@ && echo "{% endraw %}" >> $@
docs/api.md: lupa.lua
	luadoc --doclet docs/markdowndoc $^ > $@
	sed -i '1 i {% raw %}' $@ && echo "{% endraw %}" >> $@
cleandocs: ; rm -f docs/*.html docs/index.md docs/api.html
