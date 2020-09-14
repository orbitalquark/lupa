{% raw %}
## Lupa API Documentation

<a id="lupa"></a>
## The `lupa` Module
---

Lupa is a Jinja2 template engine implementation written in Lua and supports
Lua syntax within tags and variables.

### Functions defined by `lupa`

<a id="_G.cycler"></a>
#### `_G.cycler`(*...*)

Returns an object that cycles through the given values by calls to its
`next()` function.
A `current` field contains the cycler's current value and a `reset()`
function resets the cycler to its beginning.

Parameters:

* *`...`*: Values to cycle through.

Usage:

* `c = cycler(1, 2, 3)`
* `c:next(), c:next() --> 1, 2`
* `c:reset() --> c.current == 1`

<a id="_G.range"></a>
#### `_G.range`(*start, stop, step*)

Returns a sequence of integers from *start* to *stop*, inclusive, in
increments of *step*.
The complete sequence is generated at once -- no generator is returned.

Parameters:

* *`start`*: Optional number to start at. The default value is `1`.
* *`stop`*: Number to stop at.
* *`step`*: Optional increment between sequence elements. The default value
  is `1`.

<a id="lupa.configure"></a>
#### `lupa.configure`(*ts, te, vs, ve, cs, ce, options*)

Configures the basic delimiters and options for templates.
This function then regenerates the grammar for parsing templates.
Note: this function cannot be used iteratively to configure Lupa options.
Any options not provided are reset to their default values.

Parameters:

* *`ts`*: The tag start delimiter. The default value is '{%'.
* *`te`*: The tag end delimiter. The default value is '%}'.
* *`vs`*: The variable start delimiter. The default value is '{{'.
* *`ve`*: The variable end delimiter. The default value is '}}'.
* *`cs`*: The comment start delimiter. The default value is '{#'.
* *`ce`*: The comment end delimiter. The default value is '#}'.
* *`options`*: Optional set of options for templates:

  * `trim_blocks`: Trim the first newline after blocks.
  * `lstrip_blocks`: Strip line-leading whitespace in front of tags.
  * `newline_sequence`: The end-of-line character to use.
  * `keep_trailing_newline`: Whether or not to keep a newline at the end of
    a template.
  * `autoescape`: Whether or not to autoescape HTML entities. May be a
    function that accepts the template's filename as an argument and returns
    a boolean.
  * `loader`: Function that receives a template name to load and returns the
    path to that template.

<a id="lupa.expand"></a>
#### `lupa.expand`(*template, env*)

Expands the string template *template*, subject to template environment
*env*, and returns the result.

Parameters:

* *`template`*: String template to expand.
* *`env`*: Optional environment for the given template.

<a id="lupa.expand_file"></a>
#### `lupa.expand_file`(*filename, env*)

Expands the template within file *filename*, subject to template environment
*env*, and returns the result.

Parameters:

* *`filename`*: Filename containing the template to expand.
* *`env`*: Optional environment for the template to expand.

<a id="filters.batch"></a>
#### `filters.batch`(*t, size, fill*)

Returns a generator that produces all of the items in table *t* in batches
of size *size*, filling any empty spaces with value *fill*.
Combine this with the "list" filter to produce a list.

Parameters:

* *`t`*: The table to split into batches.
* *`size`*: The batch size.
* *`fill`*: The value to use when filling in any empty space in the last
  batch.

Usage:

* `expand('{% for i in {1, 2, 3}|batch(2, 0) %}{{ i|string }}
  {% endfor %}') --> {1, 2} {3, 0}`

See also:

* [`filters.list`](#filters.list)

<a id="filters.capitalize"></a>
#### `filters.capitalize`(*s*)

Capitalizes string *s*.
The first character will be uppercased, the others lowercased.

Parameters:

* *`s`*: The string to capitalize.

Usage:

* `expand('{{ "foo bar"|capitalize }}') --> Foo bar`

<a id="filters.center"></a>
#### `filters.center`(*s, width*)

Centers string *s* within a string of length *width*.

Parameters:

* *`s`*: The string to center.
* *`width`*: The length of the centered string.

Usage:

* `expand('{{ "foo"|center(9) }}') --> "   foo   "`

<a id="filters.default"></a>
#### `filters.default`(*value, default, false\_defaults*)

Returns value *value* or value *default*, depending on whether or not *value*
is "true" and whether or not boolean *false_defaults* is `true`.

Parameters:

* *`value`*: The value return if "true" or if `false` and *false_defaults*
  is `true`.
* *`default`*: The value to return if *value* is `nil` or `false` (the latter
  applies only if *false_defaults* is `true`).
* *`false_defaults`*: Optional flag indicating whether or not to return
  *default* if *value* is `false`. The default value is `false`.

Usage:

* `expand('{{ false|default("no") }}') --> false`
* `expand('{{ false|default("no", true) }') --> no`

<a id="filters.dictsort"></a>
#### `filters.dictsort`(*t, case\_sensitive, by, value*)

Returns a table constructed from table *t* such that each element is a list
that contains a single key-value pair and all elements are sorted according
to string *by* (which is either "key" or "value") and boolean
*case_sensitive*.

Parameters:

* *`t`*: 
* *`case_sensitive`*: Optional flag indicating whether or not to consider
  case when sorting string values. The default value is `false`.
* *`by`*: Optional string that specifies which of the key-value to sort by,
  either "key" or "value". The default value is `"key"`.
* *`value`*: The table to sort.

Usage:

* `expand('{{ {b = 1, a = 2}|dictsort|string }}') --> {{"a", 2},
  {"b", 1}}`

<a id="filters.e"></a>
#### `filters.e`(*s*)

Returns an HTML-safe copy of string *s*.

Parameters:

* *`s`*: String to ensure is HTML-safe.

Usage:

* `expand([[{{ '<">&'|escape}}]]) --> &lt;&#34;&gt;&amp;`

<a id="filters.escape"></a>
#### `filters.escape`(*s*)

Returns an HTML-safe copy of string *s*.

Parameters:

* *`s`*: String to ensure is HTML-safe.

Usage:

* `expand([[{{ '<">&'|e}}]]) --> &lt;&#34;&gt;&amp;`

<a id="filters.filesizeformat"></a>
#### `filters.filesizeformat`(*bytes, binary*)

Returns a human-readable, decimal (or binary, depending on boolean *binary*)
file size for *bytes* number of bytes.

Parameters:

* *`bytes`*: The number of bytes to return the size for.
* *`binary`*: Flag indicating whether or not to report binary file size
   as opposed to decimal file size. The default value is `false`.

Usage:

* `expand('{{ 1000|filesizeformat }}') --> 1.0 kB`

<a id="filters.first"></a>
#### `filters.first`(*t*)

Returns the first element in table *t*.

Parameters:

* *`t`*: The table to get the first element of.

Usage:

* `expand('{{ range(10)|first }}') --> 1`

<a id="filters.float"></a>
#### `filters.float`(*value*)

Returns value *value* as a float.
This filter only works in Lua 5.3, which has a distinction between floats and
integers.

Parameters:

* *`value`*: The value to interpret as a float.

Usage:

* `expand('{{ 42|float }}') --> 42.0`

<a id="filters.forceescape"></a>
#### `filters.forceescape`(*value*)

Returns an HTML-safe copy of value *value*, even if *value* was returned by
the "safe" filter.

Parameters:

* *`value`*: Value to ensure is HTML-safe.

Usage:

* `expand('{% set x = "<div />"|safe %}{{ x|forceescape }}') -->
  &lt;div /&gt;`

<a id="filters.format"></a>
#### `filters.format`(*s, ...*)

Returns the given arguments formatted according to string *s*.
See Lua's `string.format()` for more information.

Parameters:

* *`s`*: The string to format subsequent arguments according to.
* *`...`*: Arguments to format.

Usage:

* `expand('{{ "%s,%s"|format("a", "b") }}') --> a,b`

<a id="filters.groupby"></a>
#### `filters.groupby`(*t, attribute*)

Returns a generator that produces lists of items in table *t* grouped by
string attribute *attribute*.

Parameters:

* *`t`*: The table to group items from.
* *`attribute`*: The attribute of items in the table to group by. This may
  be nested (e.g. "foo.bar" groups by t[i].foo.bar for all i).

Usage:

* `expand('{% for age, group in people|groupby("age") %}...{% endfor %}')`

<a id="filters.indent"></a>
#### `filters.indent`(*s, width, first\_line*)

Returns a copy of string *s* with all lines after the first indented by
*width* number of spaces.
If boolean *first_line* is `true`, indents the first line as well.

Parameters:

* *`s`*: The string to indent lines of.
* *`width`*: The number of spaces to indent lines with.
* *`first_line`*: Optional flag indicating whether or not to indent the
  first line of text. The default value is `false`.

Usage:

* `expand('{{ "foo\nbar"|indent(2) }}') --> "foo\n  bar"`

<a id="filters.int"></a>
#### `filters.int`(*value*)

Returns value *value* as an integer.

Parameters:

* *`value`*: The value to interpret as an integer.

Usage:

* `expand('{{ 32.32|int }}') --> 32`

<a id="filters.join"></a>
#### `filters.join`(*t, sep, attribute*)

Returns a string that contains all the elements in table *t* (or all the
attributes named *attribute* in *t*) separated by string *sep*.

Parameters:

* *`t`*: The table to join.
* *`sep`*: The string to separate table elements with.
* *`attribute`*: Optional attribute of elements to use for joining instead
  of the elements themselves. This may be nested (e.g. "foo.bar" joins
  `t[i].foo.bar` for all i).

Usage:

* `expand('{{ {1, 2, 3}|join("|") }}') --> 1|2|3`

<a id="filters.last"></a>
#### `filters.last`(*t*)

Returns the last element in table *t*.

Parameters:

* *`t`*: The table to get the last element of.

Usage:

* `expand('{{ range(10)|last }}') --> 10`

<a id="filters.length"></a>
#### `filters.length`(*value*)

Returns the length of string or table *value*.

Parameters:

* *`value`*: The value to get the length of.

Usage:

* `expand('{{ "hello world"|length }}') --> 11`

<a id="filters.list"></a>
#### `filters.list`(*generator, s, i*)

Returns the list of items produced by generator *generator*, subject to
initial state *s* and initial iterator variable *i*.
This filter should only be used after a filter that returns a generator.

Parameters:

* *`generator`*: Generator function that produces an item.
* *`s`*: Initial state for the generator.
* *`i`*: Initial iterator variable for the generator.

Usage:

* `expand('{{ range(4)|batch(2)|list|string }}') --> {{1, 2}, {3, 4}}`

See also:

* [`filters.batch`](#filters.batch)
* [`filters.groupby`](#filters.groupby)
* [`filters.slice`](#filters.slice)

<a id="filters.lower"></a>
#### `filters.lower`(*s*)

Returns a copy of string *s* with all lowercase characters.

Parameters:

* *`s`*: The string to lowercase.

Usage:

* `expand('{{ "FOO"|lower }}') --> foo`

<a id="filters.map"></a>
#### `filters.map`(*t, filter, ...*)

Maps each element of table *t* to a value produced by filter name *filter*
and returns the resultant table.

Parameters:

* *`t`*: The table of elements to map.
* *`filter`*: The name of the filter to pass table elements through.
* *`...`*: Any arguments for the filter.

Usage:

* `expand('{{ {"1", "2", "3"}|map("int")|sum }}') --> 6`

<a id="filters.mapattr"></a>
#### `filters.mapattr`(*t, attribute, filter, ...*)

Maps the value of each element's string *attribute* in table *t* to the
value produced by filter name *filter* and returns the resultant table.

Parameters:

* *`t`*: The table of elements with attributes to map.
* *`attribute`*: The attribute of elements in the table to filter. This may
  be nested (e.g. "foo.bar" maps t[i].foo.bar for all i).
* *`filter`*: The name of the filter to pass table elements through.
* *`...`*: Any arguments for the filter.

Usage:

* `expand('{{ users|mapattr("name")|join("|") }}')`

<a id="filters.random"></a>
#### `filters.random`(*t*)

Returns a random element from table *t*.

Parameters:

* *`t`*: The table to get a random element from.

Usage:

* `expand('{{ range(100)|random }}')`

<a id="filters.reject"></a>
#### `filters.reject`(*t, test, ...*)

Returns a list of elements in table *t* that fail test name *test*.

Parameters:

* *`t`*: The table of elements to reject from.
* *`test`*: The name of the test to use on table elements.
* *`...`*: Any arguments for the test.

Usage:

* `expand('{{ range(5)|reject(is_odd)|join("|") }}') --> 2|4`

<a id="filters.rejectattr"></a>
#### `filters.rejectattr`(*t, attribute, test, ...*)

Returns a list of elements in table *t* whose string attribute *attribute*
fails test name *test*.

Parameters:

* *`t`*: The table of elements to reject from.
* *`attribute`*: The attribute of items in the table to reject from. This
  may be nested (e.g. "foo.bar" tests t[i].foo.bar for all i).
* *`test`*: The name of the test to use on table elements.
* *`...`*: Any arguments for the test.

Usage:

* `expand('{{ users|rejectattr("offline")|mapattr("name")|join(",") }}')`

<a id="filters.replace"></a>
#### `filters.replace`(*s, pattern, repl, n*)

Returns a copy of string *s* with all (or up to *n*) occurrences of string
*old* replaced by string *new*.
Identical to Lua's `string.gsub()` and handles Lua patterns.

Parameters:

* *`s`*: The subject string.
* *`pattern`*: The string or Lua pattern to replace.
* *`repl`*: The replacement text (may contain Lua captures).
* *`n`*: Optional number indicating the maximum number of replacements to
  make. The default value is `nil`, which is unlimited.

Usage:

* `expand('{% filter upper|replace("FOO", "foo") %}foobar
  {% endfilter %}') --> fooBAR`

<a id="filters.reverse"></a>
#### `filters.reverse`(*value*)

Returns a copy of the given string or table *value* in reverse order.

Parameters:

* *`value`*: The value to reverse.

Usage:

* `expand('{{ {1, 2, 3}|reverse|string }}') --> {3, 2, 1}`

<a id="filters.round"></a>
#### `filters.round`(*value, precision, method*)

Returns number *value* rounded to *precision* decimal places based on string
*method* (if given).

Parameters:

* *`value`*: The number to round.
* *`precision`*: Optional precision to round the number to. The default
  value is `0`.
* *`method`*: Optional string rounding method, either `"ceil"` or
  `"floor"`. The default value is `nil`, which uses the common rounding
  method (if a number's fractional part is 0.5 or greater, rounds up;
  otherwise rounds down).

Usage:

* `expand('{{ 2.1236|round(3, "floor") }}') --> 2.123`

<a id="filters.safe"></a>
#### `filters.safe`(*s*)

Marks string *s* as HTML-safe, preventing Lupa from modifying it when
configured to autoescape HTML entities.
This filter must be used at the end of a filter chain unless it is
immediately proceeded by the "forceescape" filter.

Parameters:

* *`s`*: The string to mark as HTML-safe.

Usage:

* `lupa.configure{autoescape = true}`
* `expand('{{ "<div>foo</div>"|safe }}') --> <div>foo</div>`

<a id="filters.select"></a>
#### `filters.select`(*t, test, ...*)

Returns a list of the elements in table *t* that pass test name *test*.

Parameters:

* *`t`*: The table of elements to select from.
* *`test`*: The name of the test to use on table elements.
* *`...`*: Any arguments for the test.

Usage:

* `expand('{{ range(5)|select(is_odd)|join("|") }}') --> 1|3|5`

<a id="filters.selectattr"></a>
#### `filters.selectattr`(*t, attribute, test, ...*)

Returns a list of elements in table *t* whose string attribute *attribute*
passes test name *test*.

Parameters:

* *`t`*: The table of elements to select from.
* *`attribute`*: The attribute of items in the table to select from. This
  may be nested (e.g. "foo.bar" tests t[i].foo.bar for all i).
* *`test`*: The name of the test to use on table elements.
* *`...`*: Any arguments for the test.

Usage:

* `expand('{{ users|selectattr("online")|mapattr("name")|join("|") }}')`

<a id="filters.slice"></a>
#### `filters.slice`(*t, slices, fill*)

Returns a generator that produces all of the items in table *t* in *slices*
number of iterations, filling any empty spaces with value *fill*.
Combine this with the "list" filter to produce a list.

Parameters:

* *`t`*: The table to slice.
* *`slices`*: The number of slices to produce.
* *`fill`*: The value to use when filling in any empty space in the last
  slice.

Usage:

* `expand('{% for i in {1, 2, 3}|slice(2, 0) %}{{ i|string }}
  {% endfor %}') --> {1, 2} {3, 0}`

See also:

* [`filters.list`](#filters.list)

<a id="filters.sort"></a>
#### `filters.sort`(*value, reverse, case\_sensitive, attribute*)

Returns a copy of table or string *value* in sorted order by value (or by
an attribute named *attribute*), depending on booleans *reverse* and
*case_sensitive*.

Parameters:

* *`value`*: The table or string to sort.
* *`reverse`*: Optional flag indicating whether or not to sort in reverse
  (descending) order. The default value is `false`, which sorts in ascending
  order.
* *`case_sensitive`*: Optional flag indicating whether or not to consider
  case when sorting string values. The default value is `false`.
* *`attribute`*: Optional attribute of elements to sort by instead of the
  elements themselves.

Usage:

* `expand('{{ {2, 3, 1}|sort|string }}') --> {1, 2, 3}`

<a id="filters.string"></a>
#### `filters.string`(*value*)

Returns the string representation of value *value*, handling lists properly.

Parameters:

* *`value`*: Value to return the string representation of.

Usage:

* `expand('{{ {1 * 1, 2 * 2, 3 * 3}|string }}') --> {1, 4, 9}`

<a id="filters.striptags"></a>
#### `filters.striptags`(*s*)

Returns a copy of string *s* with any HTML tags stripped.
Also cleans up whitespace.

Parameters:

* *`s`*: String to strip HTML tags from.

Usage:

* `expand('{{ "<div>foo</div>"|striptags }}') --> foo`

<a id="filters.sum"></a>
#### `filters.sum`(*t, attribute*)

Returns the numeric sum of the elements in table *t* or the sum of all
attributes named *attribute* in *t*.

Parameters:

* *`t`*: The table to calculate the sum of.
* *`attribute`*: Optional attribute of elements to use for summing instead
  of the elements themselves. This may be nested (e.g. "foo.bar" sums
  `t[i].foo.bar` for all i).

Usage:

* `expand('{{ range(6)|sum }}') --> 21`

<a id="filters.title"></a>
#### `filters.title`(*s*)

Returns a copy of all words in string *s* in titlecase.

Parameters:

* *`s`*: The string to titlecase.

Usage:

* `expand('{{ "foo bar"|title }}') --> Foo Bar`

<a id="filters.truncate"></a>
#### `filters.truncate`(*s, length, partial\_words, delimiter*)

Returns a copy of string *s* truncated to *length* number of characters.
Truncated strings end with '...' or string *delimiter*. If boolean
*partial_words* is `false`, truncation will only happen at word boundaries.

Parameters:

* *`s`*: The string to truncate.
* *`length`*: The length to truncate the string to.
* *`partial_words`*: Optional flag indicating whether or not to allow
  truncation within word boundaries. The default value is `false`.
* *`delimiter`*: Optional delimiter text. The default value is '...'.

Usage:

* `expand('{{ "foo bar"|truncate(4) }}') --> "foo ..."`

<a id="filters.upper"></a>
#### `filters.upper`(*s*)

Returns a copy of string *s* with all uppercase characters.

Parameters:

* *`s`*: The string to uppercase.

Usage:

* `expand('{{ "foo"|upper }}') --> FOO`

<a id="filters.urlencode"></a>
#### `filters.urlencode`(*value*)

Returns a string suitably encoded to be used in a URL from value *value*.
*value* may be a string, table of key-value query parameters, or table of
lists of key-value query parameters (for order).

Parameters:

* *`value`*: Value to URL-encode.

Usage:

* `expand('{{ {{'f', 1}, {'z', 2}}|urlencode }}') --> f=1&z=2`

<a id="filters.urlize"></a>
#### `filters.urlize`(*s, length, nofollow*)

Replaces any URLs in string *s* with HTML links, limiting link text to
*length* characters.

Parameters:

* *`s`*: The string to replace URLs with HTML links in.
* *`length`*: Optional maximum number of characters to include in link text.
  The default value is `nil`, which imposes no limit.
* *`nofollow`*: Optional flag indicating whether or not HTML links will get a
  "nofollow" attribute.

Usage:

* `expand('{{ "example.com"|urlize }}') -->
  <a href="http://example.com">example.com</a>`

<a id="filters.wordcount"></a>
#### `filters.wordcount`(*s*)

Returns the number of words in string *s*.
A word is a sequence of non-space characters.

Parameters:

* *`s`*: The string to count words in.

Usage:

* `expand('{{ "foo bar baz"|wordcount }}') --> 3`

<a id="filters.xmlattr"></a>
#### `filters.xmlattr`(*t*)

Interprets table *t* as a list of XML attribute-value pairs, returning them
as a properly formatted, space-separated string.

Parameters:

* *`t`*: The table of XML attribute-value pairs.

Usage:

* `expand('<data {{ {foo = 42, bar = 23}|xmlattr }} />')`

<a id="loaders.filesystem"></a>
#### `loaders.filesystem`(*directory*)

Returns a loader for templates that uses the filesystem starting at directory
*directory*.
When looking up the template for a given filename, the loader considers the
following: if no template is being expanded, the loader assumes the given
filename is relative to *directory* and returns the full path; otherwise the
loader assumes the given filename is relative to the current template's
directory and returns the full path.
The returned path may be passed to `io.open()`.

Parameters:

* *`directory`*: Optional the template root directory. The default value is
  ".", which is the current working directory.

See also:

* [`lupa.configure`](#lupa.configure)

<a id="lupa.reset"></a>
#### `lupa.reset`()

Resets Lupa's default delimiters, options, and environments to their
original default values.

<a id="tests.is_callable"></a>
#### `tests.is_callable`(*value*)

Returns whether or not value *value* is a function.

Parameters:

* *`value`*: The value to test.

Usage:

* `expand('{% if is_callable(x) %}...{% endif %}')`

<a id="tests.is_defined"></a>
#### `tests.is_defined`(*value*)

Returns whether or not value *value* is non-nil, and thus defined.

Parameters:

* *`value`*: The value to test.

Usage:

* `expand('{% if is_defined(x) %}...{% endif %}')`

<a id="tests.is_divisibleby"></a>
#### `tests.is_divisibleby`(*n, num*)

Returns whether or not number *n* is evenly divisible by number *num*.

Parameters:

* *`n`*: The dividend to test.
* *`num`*: The divisor to use.

Usage:

* `expand('{% if is_divisibleby(x, y) %}...{% endif %}')`

<a id="tests.is_escaped"></a>
#### `tests.is_escaped`(*value*)

Returns whether or not value *value* is HTML-safe.

Parameters:

* *`value`*: The value to test.

Usage:

* `expand('{% if is_escaped(x) %}...{% endif %}')`

<a id="tests.is_even"></a>
#### `tests.is_even`(*n*)

Returns whether or not number *n* is even.

Parameters:

* *`n`*: The number to test.

Usage:

* `expand('{% for x in range(10) if is_even(x) %}...{% endif %}')`

<a id="tests.is_iterable"></a>
#### `tests.is_iterable`(*value*)

Returns whether or not value *value* is a sequence (a table with non-zero
length) or a generator.
At the moment, all functions are considered generators.

Parameters:

* *`value`*: The value to test.

Usage:

* `expand('{% if is_iterable(x) %}...{% endif %}')`

<a id="tests.is_lower"></a>
#### `tests.is_lower`(*s*)

Returns whether or not string *s* is in all lower-case characters.

Parameters:

* *`s`*: The string to test.

Usage:

* `expand('{% if is_lower(s) %}...{% endif %}')`

<a id="tests.is_mapping"></a>
#### `tests.is_mapping`(*value*)

Returns whether or not value *value* is a table.

Parameters:

* *`value`*: The value to test.

Usage:

* `expand('{% if is_mapping(x) %}...{% endif %}')`

<a id="tests.is_nil"></a>
#### `tests.is_nil`(*value*)

Returns whether or not value *value* is nil.

Parameters:

* *`value`*: The value to test.

Usage:

* `expand('{% if is_nil(x) %}...{% endif %}')`

<a id="tests.is_none"></a>
#### `tests.is_none`(*value*)

Returns whether or not value *value* is nil.

Parameters:

* *`value`*: The value to test.

Usage:

* `expand('{% if is_none(x) %}...{% endif %}')`

<a id="tests.is_number"></a>
#### `tests.is_number`(*value*)

Returns whether or not value *value* is a number.

Parameters:

* *`value`*: The value to test.

Usage:

* `expand('{% if is_number(x) %}...{% endif %}')`

<a id="tests.is_odd"></a>
#### `tests.is_odd`(*n*)

Returns whether or not number *n* is odd.

Parameters:

* *`n`*: The number to test.

Usage:

* `expand('{% for x in range(10) if is_odd(x) %}...{% endif %}')`

<a id="tests.is_sameas"></a>
#### `tests.is_sameas`(*value, other*)

Returns whether or not value *value* is the same as value *other*.

Parameters:

* *`value`*: The value to test.
* *`other`*: The value to compare with.

Usage:

* `expand('{% if is_sameas(x, y) %}...{% endif %}')`

<a id="tests.is_sequence"></a>
#### `tests.is_sequence`(*value*)

Returns whether or not value *value* is a sequence, namely a table with
non-zero length.

Parameters:

* *`value`*: The value to test.

Usage:

* `expand('{% if is_sequence(x) %}...{% endif %}')`

<a id="tests.is_string"></a>
#### `tests.is_string`(*value*)

Returns whether or not value *value* is a string.

Parameters:

* *`value`*: The value to test.

Usage:

* `expand('{% if is_string(x) %}...{% endif %}')`

<a id="tests.is_table"></a>
#### `tests.is_table`(*value*)

Returns whether or not value *value* is a table.

Parameters:

* *`value`*: The value to test.

Usage:

* `expand('{% if is_table(x) %}...{% endif %}')`

<a id="tests.is_undefined"></a>
#### `tests.is_undefined`(*value*)

Returns whether or not value *value* is nil, and thus effectively undefined.

Parameters:

* *`value`*: The value to test.

Usage:

* `expand('{% if is_undefined(x) %}...{% endif %}')`

<a id="tests.is_upper"></a>
#### `tests.is_upper`(*s*)

Returns whether or not string *s* is in all upper-case characters.

Parameters:

* *`s`*: The string to test.

Usage:

* `expand('{% if is_upper(s) %}...{% endif %}')`


### Tables defined by `lupa`

<a id="lupa.env"></a>
#### `lupa.env`

The default template environment.

<a id="lupa.filters"></a>
#### `lupa.filters`

Lupa's expression filters.

<a id="lupa.loaders"></a>
#### `lupa.loaders`

Lupa's template loaders.

<a id="lupa.tests"></a>
#### `lupa.tests`

Lupa's value tests.

---

{% endraw %}
