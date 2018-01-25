-- Copyright 2015-2018 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Contributions from Ana Balan.
-- Contains Lupa's copy of Jinja2's test suite.
-- Any descrepancies are noted and/or described.
-- Note: Lupa's range(n) behaves differently than Jinja2's in that it produces
-- sequences from 1 to n. All tests that utilize range() reflect this.
-- Also, Lua tables are 1-indexed, not 0-indexed, so the tests reflect that.

local lupa = dofile('../lupa.lua')
local expand, expand_file = lupa.expand, lupa.expand_file

-- Asserts that value *value* is equal to value *expected*.
-- @param value Resultant value.
-- @param expected Expected value.
local function assert_equal(value, expected)
  assert(expected ~= nil, 'expected argument not given to assert_equal')
  assert(value == expected,
         'assertion failed! "'..expected..'" expected, got "'..value..'"')
end

-- Asserts that function *f* raises an error that contains string or pattern
-- *message*.
-- @param message String or pattern that matches the error raised by *f*.
-- @param f The function to call.
-- @param ... Any arguments to *f*.
local function assert_raises(message, f, ...)
  local ok, errmsg = pcall(f, ...)
  assert(not ok, 'no error raised')
  assert(errmsg:find(message),
         'raised error was "'..errmsg..'" and did not contain "'..message..'"')
end

-- Returns string *s* with any leading or trailing whitespace removed.
-- @param s The string to trim.
function string.trim(s) return s:gsub('^%s*(.-)%s*$', '%1') end

local test_suite = {
  api = {
    -- Note: Nearly all Jinja2 API tests are not applicable since Lupa's API is
    -- completely different.
    api_tests = {
      test_cycler = function()
        local c = cycler(1, 2, 3)
        for _, item in ipairs{1, 2, 3, 1, 2, 3} do
          assert_equal(c.current, item)
          assert_equal(c:next(), item)
        end
        c:next()
        assert_equal(c.current, 2)
        c:reset()
        assert_equal(c.current, 1)
      end,
    }
  },
  core_tags = {
    for_tests = {
      test_simple = function()
        local tmpl = '{% for item in seq %}{{ item }}{% endfor %}'
        local env = {seq = range(10)}
        assert_equal(expand(tmpl, env), '12345678910')
      end,
      test_else = function()
        local tmpl = '{% for item in seq %}XXX{% else %}...{% endfor %}'
        assert_equal(expand(tmpl), '...')
      end,
      test_empty_blocks = function()
        local tmpl = '<{% for item in seq %}{% else %}{% endfor %}>'
        assert_equal(expand(tmpl), '<>')
      end,
      test_context_vars = function()
        local tmpl = [[{% for item in seq -%}
        {{ loop.index }}|{{ loop.index0 }}|{{ loop.revindex }}|{{
            loop.revindex0}}|{{ loop.first }}||{{ loop.last }}|{{
           loop.length}}###{% endfor %}]]
        local env = {seq = {0, 1}}
        local one, two = expand(tmpl, env):match('^(.+)###(.+)###$')
        local one_values, two_values = {}, {}
        for v in one:gmatch('[^|]+') do one_values[#one_values + 1] = v end
        for v in two:gmatch('[^|]+') do two_values[#two_values + 1] = v end
        assert_equal(tonumber(one_values[1]), 1)
        assert_equal(tonumber(two_values[1]), 2)
        assert_equal(tonumber(one_values[2]), 0)
        assert_equal(tonumber(two_values[2]), 1)
        assert_equal(tonumber(one_values[3]), 2)
        assert_equal(tonumber(two_values[3]), 1)
        assert_equal(tonumber(one_values[4]), 1)
        assert_equal(tonumber(two_values[4]), 0)
        assert_equal(one_values[5], 'true')
        assert_equal(two_values[5], 'false')
        assert_equal(one_values[6], 'false')
        assert_equal(two_values[6], 'true')
        assert_equal(one_values[7], '2')
        assert_equal(two_values[7], '2')
      end,
      test_cycling = function()
        local tmpl = [[{% for item in seq %}{{
            loop.cycle('<1>', '<2>') }}{% endfor %}{%
            for item in seq %}{{ loop.cycle(table.unpack(through)) }}{% endfor %}]]
        local env = {seq = range(4), through = {'<1>', '<2>'}}
        assert_equal(expand(tmpl, env), string.rep('<1><2>', 4))
      end,
      test_scope = function()
        local tmpl = '{% for item in seq %}{% endfor %}{{ item }}'
        local env = {seq = range(10)}
        assert_equal(expand(tmpl, env), '')
      end,
      test_varlen = function()
        local t = range(5)
        local function iter()
          return function(_, i)
            if i > #t then return nil end
            return i + 1, t[i]
          end, t, 1
        end
        local tmpl = '{% for item in iter() %}{{ item }}{% endfor %}'
        local env = {iter = iter}
        assert_equal(expand(tmpl, env), '12345')
        tmpl = '{% for item in iter %}{{ item }}{% endfor %}'
        assert_raises('invalid generator', expand, tmpl, env)
      end,
      test_noniter = function()
        local tmpl = '{% for item in seq() %}...{% endfor %}'
        assert_raises('attempt to call.+nil value', expand, tmpl)
      end,
      test_recursive = function()
        -- Note: no need for 'recursive' keyword, unlike Jinja2.
        local tmpl = [[{% for item in seq -%}
            [{{ item.a }}{% if item.b %}<{{ loop(item.b) }}>{% endif %}]
        {%- endfor %}]]
        local env = {seq = {{a = 1, b = {{a = 1}, {a = 2}}},
                            {a = 2, b = {{a = 1}, {a = 2}}},
                            {a = 3, b = {{a = 'a'}}}}}
        assert_equal(expand(tmpl, env), '[1<[1][2]>][2<[1][2]>][3<[a]>]')
      end,
      test_recursive_depth0 = function()
        local tmpl = [[{% for item in seq -%}
            [{{ loop.depth0 }}:{{ item.a }}{% if item.b %}<{{ loop(item.b) }}>{% endif %}]
        {%- endfor %}]]
        local env = {seq = {{a = 1, b = {{a = 1}, {a = 2}}},
                            {a = 2, b = {{a = 1}, {a = 2}}},
                            {a = 3, b = {{a = 'a'}}}}}
        assert_equal(expand(tmpl, env), '[0:1<[1:1][1:2]>][0:2<[1:1][1:2]>][0:3<[1:a]>]')
      end,
      test_recursive_depth = function()
        local tmpl = [[{% for item in seq -%}
            [{{ loop.depth }}:{{ item.a }}{% if item.b %}<{{ loop(item.b) }}>{% endif %}]
        {%- endfor %}]]
        local env = {seq = {{a = 1, b = {{a = 1}, {a = 2}}},
                            {a = 2, b = {{a = 1}, {a = 2}}},
                            {a = 3, b = {{a = 'a'}}}}}
        assert_equal(expand(tmpl, env), '[1:1<[2:1][2:2]>][1:2<[2:1][2:2]>][1:3<[2:a]>]')
      end,
      test_looploop = function()
        local tmpl = [[{% for row in table %}
            {%- set rowloop = loop -%}
            {% for cell in row:gmatch('.') -%}
                [{{ rowloop.index }}|{{ loop.index }}]
            {%- endfor %}
        {%- endfor %}]]
        local env = {table = {'ab', 'cd'}}
        assert_equal(expand(tmpl, env), '[1|1][1|2][2|1][2|2]')
      end,
      test_loop_last = function()
        local tmpl = '{% for i in items %}{{ i }}'..
                     '{% if not loop.last %}'..
                     ',{% endif %}{% endfor %}'
        local env = {items={1, 2, 3}}
        assert_equal(expand(tmpl, env), '1,2,3')
      end,
      test_loop_errors = function()
        local tmpl = [[{% for item in {1} if loop.index
                           == 0 %}...{% endfor %}]]
        assert_raises('attempt to index.+nil value', expand, tmpl)
        tmpl = [[{% for item in {} %}...{% else
            %}{{ loop }}{% endfor %}]]
        assert_equal(expand(tmpl), '')
      end,
      test_loop_filter = function()
        local tmpl = '{% for item in range(10) if '..
                     'is_even(item) %}[{{ item }}]{% endfor %}'
        assert_equal(expand(tmpl), '[2][4][6][8][10]')
        tmpl = [[
            {%- for item in range(10) if is_even(item) %}[{{
                loop.index }}:{{ item }}]{% endfor %}]]
        assert_equal(expand(tmpl), '[1:2][2:4][3:6][4:8][5:10]')
      end,
      test_loop_unassignable = function()
        local tmpl = '{% for loop in seq %}...{% endfor %}'
        local env = {0}
        assert_raises('invalid variable name', expand, tmpl, env)
      end,
      test_scoped_special_var = function()
        local tmpl = '{% for s in seq %}[{{ loop.first }}{% for c in s:gmatch(".") %}'..
                     '|{{ loop.first }}{% endfor %}]{% endfor %}'
        local env = {seq = {'ab', 'cd'}}
        assert_equal(expand(tmpl, env), '[true|true|false][false|true|false]')
      end,
      test_scoped_loop_var = function()
        local tmpl = '{% for x in seq %}{{ loop.first }}'..
                     '{% for y in seq %}{% endfor %}{% endfor %}'
        local env = {seq = {'a', 'b'}}
        assert_equal(expand(tmpl, env), 'truefalse')
        tmpl = '{% for x in seq %}{% for y in seq %}'..
               '{{ loop.first }}{% endfor %}{% endfor %}'
        assert_equal(expand(tmpl, env), 'truefalsetruefalse')
      end,
      test_recursive_empty_loop_iter = function()
        local tmpl = [[
        {%- for item in foo -%}{%- endfor -%}
        ]]
        local env = {foo = {}}
        assert_equal(expand(tmpl, env), '')
      end,
      test_call_in_loop = function()
        local tmpl = [[
        {%- macro do_something() -%}
          [{{ caller() }}]
        {%- endmacro %}

        {%- for i in {1,2,3} %}
          {%- call do_something() -%}
            {{ i }}
          {%- endcall %}
        {%- endfor -%}
        ]]
        assert_equal(expand(tmpl), '[1][2][3]')
      end,
      test_scoping = function()
        local tmpl = [[
        {%- for item in foo %}...{{ item }}...{% endfor %}
        {%- macro item(a) %}...{{ a }}...{% endmacro %}
        {{- item(2) -}}
        ]]
        local env = {foo = {1}}
        assert_equal(expand(tmpl, env), '...1......2...')
      end,
      test_unpacking = function()
        local tmpl = '{% for a, b, c in {{1, 2, 3}} %}'..
                      '{{ a }}|{{ b }}|{{ c }}{% endfor %}'
        assert_equal(expand(tmpl), '1|2|3')
      end
    },
    if_tests = {
      test_simple = function()
        local tmpl = '{% if true %}...{% endif %}'
        assert_equal(expand(tmpl), '...')
      end,
      test_elif = function()
        local tmpl = '{% if false %}XXX{% elseif true'..
                     '%}...{% else %}XXX{% endif %}'
        assert_equal(expand(tmpl), '...')
      end,
      test_else = function()
        local tmpl = '{% if false %}XXX{% else %}...{% endif %}'
        assert_equal(expand(tmpl), '...')
      end,
      test_empty = function()
        local tmpl = '[{% if true %}{% else %}{% endif %}]'
        assert_equal(expand(tmpl), '[]')
      end,
      test_complete = function()
        local tmpl = '{% if a %}A{% elseif b %}B{% elseif c == d %}'..
                     'C{% else %}D{% endif %}'
        local env = {a = false, b = false, c = 42, d = 42.0}
        assert_equal(expand(tmpl, env), 'C')
      end,
      test_no_scope = function()
        local tmpl = '{% if a %}{% set foo = 1 %}{% endif %}{{ foo }}'
        local env = {a = true}
        assert_equal(expand(tmpl, env), '1')
        tmpl = '{% if true %}{% set foo = 1 %}{% endif %}{{ foo }}'
        assert_equal(expand(tmpl), '1')
      end
    },
    macro_tests = {
      setup = function() lupa.configure{trim_blocks = true} end,
      teardown = lupa.reset,
      test_simple = function()
        local tmpl = [[
{%macro say_hello(name) %}Hello {{ name }}!{% endmacro %}
{{ say_hello('Peter') }}]]
        assert_equal(expand(tmpl), 'Hello Peter!')
      end,
      test_scoping = function()
        local tmpl = [[
{% macro level1(data1) %}
{% macro level2(data2) %}{{ data1 }}|{{ data2 }}{% endmacro %}
{{ level2('bar') }}{% endmacro %}
{{ level1('foo') }}]]
        assert_equal(expand(tmpl), 'foo|bar')
      end,
      test_arguments = function()
        local tmpl = [[
{% macro m(a, b, c='c', d='d') %}{{ a }}|{{ b }}|{{ c }}|{{ d }}{% endmacro %}
{{ m() }}|{{ m('a') }}|{{ m('a', 'b') }}|{{ m(1, 2, 3) }}]]
        assert_equal(expand(tmpl), '||c|d|a||c|d|a|b|c|d|1|2|3|d')
      end,
      test_varargs = function()
        local tmpl = [[
{% macro test() %}{{ varargs|join('|') }}{% endmacro %}
{{ test(1, 2, 3) }}]]
        assert_equal(expand(tmpl), '1|2|3')
      end,
      test_simple_call = function()
        local tmpl = [=[
{% macro test() %}[[{{ caller() }}{% endmacro %}
{% call test() %}data{% endcall %}]]]=]
        assert_equal(expand(tmpl), '[[data]]')
      end,
      test_complex_call = function()
        local tmpl = [=[
{% macro test() %}[[{{ caller('data') }}]]{% endmacro %}
{% call(data) test() %}{{ data }}{% endcall %}]=]
        assert_equal(expand(tmpl), '[[data]]')
      end,
      test_caller_undefined = function()
        local tmpl = [[
{% set caller = 42 %}
{% macro test() %}{{ not caller }}{% endmacro %}
{{ test() }}]]
        assert_equal(expand(tmpl), 'true')
      end,
      test_include = function()
        local tmpl = '{% include "data/test_macro" %}{{ test("foo") }}'
        assert_equal(expand(tmpl), '[foo]')
      end,
      -- Note: test_macro_api is not applicable since this implementation stores
      -- macros as Lua functions with no metadata.
      test_callself = function()
        local tmpl = '{% macro foo(x) %}{{ x }}{% if x > 1 %}|'..
                     '{{ foo(x - 1) }}{% endif %}{% endmacro %}'..
                     '{{ foo(5) }}'
        assert_equal(expand(tmpl), '5|4|3|2|1')
      end
    }
  },
  debug = {
    debug_tests = {
      test_runtime_error = function()
        local tmpl = 'data/debug/broken.html'
        local env = {fail = function() next() end}
        assert_raises('^Runtime Error.+broken%.html.+'..
                      'on line %d, column %d: bad argument', expand_file, tmpl,
                      env)
      end,
      test_syntax_error = function()
        local tmpl = 'data/debug/syntaxerror.html'
        assert_raises('^Parse Error.+syntaxerror%.html.+'..
                      'on line %d, column %d:.+endfor.+expected', expand_file,
                      tmpl)
      end,
      test_regular_error = function()
        local tmpl = '{{ test() }}'
        local env = {test = function() error('wtf') end}
        assert_raises('^Runtime Error.+<string>.+wtf', expand, tmpl, env)
      end,
    }
  },
  filters = {
    filter_tests = {
      test_filter_calling = function()
        local result = lupa.filters.sum{1, 2, 3}
        assert_equal(result, 6)
      end,
      test_capitalize = function()
        local tmpl = '{{ "foo bar"|capitalize }}'
        assert_equal(expand(tmpl), 'Foo bar')
      end,
      test_center = function()
        local tmpl = '{{ "foo"|center(9) }}'
        assert_equal(expand(tmpl), '   foo   ')
      end,
      test_default = function()
        local tmpl = '{{ missing|default("no") }}|{{ false|default("no") }}|'..
                     '{{ false|default("no", true) }}|{{ given|default("no") }}'
        local env = {given = 'yes'}
        assert_equal(expand(tmpl, env), 'no|false|no|yes')
      end,
      test_dictsort = function()
        local tmpl = '{{ foo|dictsort|string }}|'..
                     '{{ foo|dictsort(true)|string }}|'..
                     '{{ foo|dictsort(false, "value")|string }}'
        local env = {foo={aa = 0, b = 1, c = 2, AB = 3}}
        assert_equal(expand(tmpl, env),
                     '{{"aa", 0}, {"AB", 3}, {"b", 1}, {"c", 2}}|'..
                     '{{"AB", 3}, {"aa", 0}, {"b", 1}, {"c", 2}}|'..
                     '{{"aa", 0}, {"b", 1}, {"c", 2}, {"AB", 3}}')
      end,
      test_batch = function()
        local tmpl = '{{ foo|batch(3)|list|string }}|'..
                     '{{ foo|batch(3, "X")|list|string }}'
        local env = {foo = range(10)}
        assert_equal(expand(tmpl, env),
                     '{{1, 2, 3}, {4, 5, 6}, {7, 8, 9}, {10}}|'..
                     '{{1, 2, 3}, {4, 5, 6}, {7, 8, 9}, {10, "X", "X"}}')
      end,
      test_slice = function()
        local tmpl = '{{ foo|slice(3)|list|string }}|'..
                     '{{ foo|slice(3, "X")|list|string }}'
        local env = {foo = range(10)}
        assert_equal(expand(tmpl, env),
                     '{{1, 2, 3, 4}, {5, 6, 7}, {8, 9, 10}}|'..
                     '{{1, 2, 3, 4}, {5, 6, 7, "X"}, {8, 9, 10, "X"}}')
      end,
      test_escape = function()
        local tmpl = [[{{ '<">&'|escape}}]]
        assert_equal(expand(tmpl), '&lt;&#34;&gt;&amp;')
      end,
      test_striptags = function()
        local tmpl = '{{ foo|striptags }}'
        local env = {foo = '  <p>just a small   \n <a href="#">'..
                           'example</a> link</p>\n<p>to a webpage</p> '..
                           '<!-- <p>and some commented stuff</p> -->'}
        assert_equal(expand(tmpl, env), 'just a small example link to a webpage')
      end,
      test_filesizeformat = function()
        local tmpl = '{{ 100|filesizeformat }}|'..
                     '{{ 1000|filesizeformat }}|'..
                     '{{ 1000000|filesizeformat }}|'..
                     '{{ 1000000000|filesizeformat }}|'..
                     '{{ 1000000000000|filesizeformat }}|'..
                     '{{ 100|filesizeformat(true) }}|'..
                     '{{ 1000|filesizeformat(true) }}|'..
                     '{{ 1000000|filesizeformat(true) }}|'..
                     '{{ 1000000000|filesizeformat(true) }}|'..
                     '{{ 1000000000000|filesizeformat(true) }}'
        assert_equal(expand(tmpl),
                     '100 Bytes|1.0 kB|1.0 MB|1.0 GB|1.0 TB|100 Bytes|'..
                     '1000 Bytes|976.6 KiB|953.7 MiB|931.3 GiB')
        tmpl = '{{ 300|filesizeformat }}|'..
               '{{ 3000|filesizeformat }}|'..
               '{{ 3000000|filesizeformat }}|'..
               '{{ 3000000000|filesizeformat }}|'..
               '{{ 3000000000000|filesizeformat }}|'..
               '{{ 300|filesizeformat(true) }}|'..
               '{{ 3000|filesizeformat(true) }}|'..
               '{{ 3000000|filesizeformat(true) }}'
        assert_equal(expand(tmpl),
                     '300 Bytes|3.0 kB|3.0 MB|3.0 GB|3.0 TB|300 Bytes|'..
                     '2.9 KiB|2.9 MiB')
      end,
      test_first = function()
        local tmpl = '{{ foo|first }}'
        local env = {foo = range(10)}
        assert_equal(expand(tmpl, env), '1')
      end,
      test_float = function()
        local tmpl = '{{ "42"|float }}|'..
                     '{{ "ajsghasjgd"|float }}|'..
                     '{{ "32.32"|float }}'
        if _VERSION >= 'Lua 5.3' then
          assert_equal(expand(tmpl), '42.0|0.0|32.32')
        end
      end,
      test_format = function()
        local tmpl = '{{ "%s,%s"|format("a", "b") }}'
        assert_equal(expand(tmpl), 'a,b')
      end,
      test_indent = function()
        local tmpl = '{{ foo|indent(2) }}|{{ foo|indent(2, true) }}'
        local env = {foo = 'foo bar foo bar\nfoo bar foo bar'}
        assert_equal(expand(tmpl, env),
                     'foo bar foo bar\n  foo bar foo bar|  '..
                     'foo bar foo bar\n  foo bar foo bar')
      end,
      test_int = function()
        local tmpl = '{{ "42"|int }}|{{ "ajsghasjgd"|int }}|{{ "32.32"|int }}'
        assert_equal(expand(tmpl), '42|0|32')
      end,
      test_join = function()
        local tmpl = '{{ {1, 2, 3}|join("|") }}'
        assert_equal(expand(tmpl), '1|2|3')
        -- Note: '|' cannot occur within an expression, only at the end, so this
        -- test input is slightly different.
        lupa.configure{autoescape = true}
        tmpl = '{{ {"<foo>", "<span>foo</span>"}|join }}'
        assert_equal(expand(tmpl), '&lt;foo&gt;&lt;span&gt;foo&lt;/span&gt;')
        lupa.reset()
      end,
      test_join_attribute = function()
        local tmpl = '{{ users|join(", ", "username") }}'
        local env = {users = {{username = 'foo'}, {username = 'bar'}}}
        assert_equal(expand(tmpl, env), 'foo, bar')
      end,
      test_last = function()
        local tmpl = '{{ foo|last }}'
        local env = {foo = range(10)}
        assert_equal(expand(tmpl, env), '10')
      end,
      test_length = function()
        local tmpl = '{{ "hello world"|length }}'
        assert_equal(expand(tmpl), '11')
      end,
      test_lower = function()
        local tmpl = '{{ "FOO"|lower }}'
        assert_equal(expand(tmpl), 'foo')
      end,
      -- Note: pprint filter is not applicable since Lua does not have a data
      -- pretty-printer.
      test_random = function()
        local tmpl = '{{ seq|random }}'
        local env = {seq = range(100)}
        for i = 1, 10 do
          local j = tonumber(expand(tmpl, env))
          assert(j >= 1 and j <= 100)
        end
      end,
      test_reverse = function()
        local tmpl = '{{ "foobar"|reverse }}|'..
                     '{{ {1, 2, 3}|reverse|string }}'
        assert_equal(expand(tmpl), 'raboof|{3, 2, 1}')
      end,
      test_string = function()
        local tmpl = '{{ obj|string }}'
        local env = {obj = {1, 2, 3, 4, 5}}
        assert_equal(expand(tmpl, env), '{1, 2, 3, 4, 5}')
      end,
      test_title = function()
        local tmpl = '{{ "foo bar"|title }}'
        assert_equal(expand(tmpl), 'Foo Bar')
        tmpl = [[{{ "foo\'s bar"|title }}]]
        assert_equal(expand(tmpl), "Foo's Bar")
        tmpl = '{{ "foo   bar"|title }}'
        assert_equal(expand(tmpl), 'Foo   Bar')
        tmpl = '{{ "f bar f"|title }}'
        assert_equal(expand(tmpl), 'F Bar F')
        tmpl = '{{ "foo-bar"|title }}'
        assert_equal(expand(tmpl), 'Foo-Bar')
        tmpl = '{{ "foo\tbar"|title }}'
        assert_equal(expand(tmpl), 'Foo\tBar')
        tmpl = '{{ "FOO\tBAR"|title }}'
        assert_equal(expand(tmpl), 'Foo\tBar')
      end,
      test_truncate = function()
        local tmpl = '{{ data|truncate(15, true, ">>>") }}|'..
                     '{{ data|truncate(15, false, ">>>") }}|'..
                     '{{ smalldata|truncate(15) }}'
        local env = {
          data = string.rep('foobar baz bar', 1000),
          smalldata = 'foobar baz bar'
        }
        assert_equal(expand(tmpl, env), 'foobar baz barf>>>|foobar baz >>>|foobar baz bar')
      end,
      test_upper = function()
        local tmpl = '{{ "foo"|upper }}'
        assert_equal(expand(tmpl), 'FOO')
      end,
      test_urlize = function()
        local tmpl = '{{ "foo http://www.example.com/ bar"|urlize }}'
        assert_equal(expand(tmpl),
                     'foo <a href="http://www.example.com/">'..
                     'http://www.example.com/</a> bar')
      end,
      test_wordcount = function()
        local tmpl = '{{ "foo bar baz"|wordcount }}'
        assert_equal(expand(tmpl), '3')
      end,
      test_block = function()
        local tmpl = '{% filter lower|escape %}<HEHE>{% endfilter %}'
        assert_equal(expand(tmpl), '&lt;hehe&gt;')
      end,
      test_chaining = function()
        local tmpl = '{{ {"<foo>", "<bar>"}|first|upper|escape}}'
        assert_equal(expand(tmpl), '&lt;FOO&gt;')
      end,
      test_sum = function()
        local tmpl = '{{ {1, 2, 3, 4, 5, 6}|sum }}'
        assert_equal(expand(tmpl), '21')
      end,
      test_sum_attributes = function()
        local tmpl = '{{ values|sum("value") }}'
        local env = {values = {{value = 23}, {value = 1}, {value = 18}}}
        assert_equal(expand(tmpl, env), '42')
      end,
      test_sum_attributes_nested = function()
        local tmpl = '{{ values|sum("real.value") }}'
        local env = {values = {{real = {value = 23}},
                               {real = {value = 1}},
                               {real = {value = 18}}}}
        assert_equal(expand(tmpl, env), '42')
      end,
      test_sum_attributes = function()
        local tmpl = [[{{ values|sum('2') }}]]
        local env = {values = {{'foo', 23}, {'bar', 1}, {'baz', 18}}}
        assert_equal(expand(tmpl, env), '42')
        tmpl = [[{{ values|sum(2) }}]]
        assert_equal(expand(tmpl, env), '42')
      end,
      test_abs = function()
        local tmpl = '{{ -1|abs }}|{{ 1|abs }}'
        assert_equal(expand(tmpl), '1|1')
      end,
      test_round_positive = function()
        local tmpl = '{{ 2.7|round }}|{{ 2.1|round }}|'..
                     '{{ 2.1234|round(3, "floor") }}|'..
                     '{{ 2.1|round(0, "ceil") }}'
        -- Note: Lua's results drop the fractional part if it is 0.
        assert_equal(expand(tmpl), '3|2|2.123|3')
      end,
      test_round_negative = function()
        local tmpl = '{{ 21.3|round(-1)}}|'..
                     '{{ 21.3|round(-1, "ceil")}}|'..
                     '{{ 21.3|round(-1, "floor")}}'
        assert_equal(expand(tmpl), '20|30|20')
      end,
      test_xmlattr = function()
        local tmpl = '{{ {foo = 42, bar = 23, ["blub:blub"] = "<?>"}|xmlattr }}'
        local s = expand(tmpl)
        assert(select(2, s:gsub(' ', '')) == 2)
        assert(s:find('foo="42"'))
        assert(s:find('bar="23"'))
        assert(s:find('blub:blub="&lt;?&gt;"', 1, true))
      end,
      test_sort = function()
        local tmpl = '{{ {2, 3, 1}|sort|string }}|{{ {2, 3, 1}|sort(true)|string }}'
        assert_equal(expand(tmpl), '{1, 2, 3}|{3, 2, 1}')
        tmpl = '{{ {"c", "A", "b", "D"}|sort|join }}'
        assert_equal(expand(tmpl), 'AbcD')
        tmpl = '{{ {"foo", "Bar", "blah"}|sort|string }}'
        assert_equal(expand(tmpl), '{"Bar", "blah", "foo"}')
        tmpl = '{{ items|sort(nil, nil, "value")|join("", "value") }}'
        local env = {
          items = {{value = 3}, {value = 2}, {value = 4}, {value = 1}}
        }
        assert_equal(expand(tmpl, env), '1234')
      end,
      test_groupby = function()
        local tmpl = [[
        {%- for grouper, list in {{foo = 1, bar = 2},
                                  {foo = 2, bar = 3},
                                  {foo = 1, bar = 1},
                                  {foo = 3, bar = 4}}|groupby("foo") -%}
            {{ grouper }}{% for x in list %}: {{ x.foo }}, {{ x.bar }}{% endfor %}|
        {%- endfor %}]]
        assert_equal(expand(tmpl), '1: 1, 2: 1, 1|2: 2, 3|3: 3, 4|')
      end,
      test_grouby_index = function()
        local tmpl = [[
        {%- for grouper, list in {{"a", 1},
                                  {"a", 2},
                                  {"b", 1}}|groupby(1) -%}
            {{ grouper }}{% for x in list %}:{{ x[2] }}{% endfor %}|
        {%- endfor %}]]
        assert_equal(expand(tmpl), 'a:1:2|b:1|')
      end,
      test_groupby_multidot = function()
        local tmpl = [[
        {%- for year, list in articles|groupby("date.year") -%}
            {{ year }}{% for x in list %}[{{ x.title }}]{% endfor %}|
        {%- endfor %}]]
        local env = {
          articles = {
            {title = 'aha', date = {day = 1, month = 1, year = 1970}},
            {title = 'interesting', date = {day = 2, month = 1, year = 1970}},
            {title = 'really?', date = {day = 3, month = 1, year = 1970}},
            {title = 'totally not', date = {day = 1, month = 1, year = 1971}},
          }
        }
        assert_equal(expand(tmpl, env), '1970[aha][interesting][really?]|1971[totally not]|')
      end,
      test_filtertag = function()
        local tmpl = '{% filter upper|replace("FOO", "foo") %}'..
                     'foobar{% endfilter %}'
        assert_equal(expand(tmpl), 'fooBAR')
      end,
      test_replace = function()
        local tmpl = '{{ string|replace("o", 42) }}'
        local env = {string = '<foo>'}
        assert_equal(expand(tmpl, env), '<f4242>')
        lupa.configure{autoescape = true}
        tmpl = '{{ string|replace("o", 42) }}'
        env = {string = '<foo>'}
        assert_equal(expand(tmpl, env), '&lt;f4242&gt;')
        tmpl = '{{ string|replace("<", 42) }}'
        env = {string = '<foo>'}
        assert_equal(expand(tmpl, env), '42foo&gt;')
        tmpl = '{{ string|replace("o", ">x<") }}'
        env = {string = 'foo'}
        assert_equal(expand(tmpl, env), 'f&gt;x&lt;&gt;x&lt;')
        lupa.reset()
      end,
      test_forceescape = function()
        -- Note: This implementation does not support markup, so this test input
        -- is slightly different.
        local tmpl = '{% set x = "<div />"|safe %}{{ x|forceescape }}'
        assert_equal(expand(tmpl), '&lt;div /&gt;')
      end,
      test_safe = function()
        lupa.configure{autoescape = true}
        local tmpl = '{{ "<div>foo</div>"|safe }}'
        assert_equal(expand(tmpl), '<div>foo</div>')
        tmpl = '{{ "<div>foo</div>" }}'
        assert_equal(expand(tmpl), '&lt;div&gt;foo&lt;/div&gt;')
        lupa.reset()
      end,
      test_urlencode = function()
        lupa.configure{autoescape = true}
        local tmpl = '{{ "Hello, world!"|urlencode }}'
        assert_equal(expand(tmpl), 'Hello%2C%20world%21')
        -- Note: Lua does not support unicode escape sequences in strings so
        -- some unicode tests are left out.
        tmpl = '{{ o|urlencode }}'
        local env = {o = {{'f', 1}}}
        assert_equal(expand(tmpl, env), 'f=1')
        env = {o = {{'f', 1}, {'z', 2}}}
        assert_equal(expand(tmpl, env), 'f=1&amp;z=2')
        env = {o = {[0] = 1}}
        assert_equal(expand(tmpl, env), '0=1')
        lupa.reset()
      end,
      test_simple_map = function()
        local tmpl = '{{ {"1", "2", "3"}|map("int")|sum }}'
        assert_equal(expand(tmpl), '6')
      end,
      test_attribute_map = function()
        local tmpl = '{{ users|mapattr("name")|join("|") }}'
        local env = {
          users = {{name = 'john'}, {name = 'jane'}, {name = 'mike'}}
        }
        assert_equal(expand(tmpl, env), 'john|jane|mike')
      end,
      test_empty_map = function()
        local tmpl = '{{ {}|map("upper")|string }}'
        assert_equal(expand(tmpl), '{}')
      end,
      test_simple_select = function()
        local tmpl = '{{ {1, 2, 3, 4, 5}|select(is_odd)|join("|") }}'
        assert_equal(expand(tmpl), '1|3|5')
      end,
      test_bool_select = function()
        local tmpl = '{{ {false, 0, 1, 2, 3, 4, 5}|select|join("|") }}'
        assert_equal(expand(tmpl), '0|1|2|3|4|5')
      end,
      test_simple_reject = function()
        local tmpl = '{{ {1, 2, 3, 4, 5}|reject(is_odd)|join("|") }}'
        assert_equal(expand(tmpl), '2|4')
      end,
      test_bool_reject = function()
        local tmpl = '{{ {false, 0, 1, 2, 3, 4, 5}|reject|join("|") }}'
        assert_equal(expand(tmpl), 'false')
      end,
      test_simple_select_attr = function()
        local tmpl = '{{ users|selectattr("is_active")|'..
                     'mapattr("name")|join("|") }}'
        local env = {users = {{name = 'john', is_active = true},
                              {name = 'jane', is_active = true},
                              {name = 'mike', is_active = false}}}
        assert_equal(expand(tmpl, env), 'john|jane')
      end,
      test_simple_reject_attr = function()
        local tmpl = '{{ users|rejectattr("is_active")|'..
                     'mapattr("name")|join(",") }}'
        local env = {users = {{name = 'john', is_active = true},
                              {name = 'jane', is_active = true},
                              {name = 'mike', is_active = false}}}
        assert_equal(expand(tmpl, env), 'mike')
      end,
      test_func_select_attr = function()
        local tmpl = '{{ users|selectattr("id", is_odd)|'..
                     'mapattr("name")|join("|") }}'
        local env = {users = {{id = 1, name = 'john'},
                              {id = 2, name = 'jane'},
                              {id = 3, name = 'mike'}}}
        assert_equal(expand(tmpl, env), 'john|mike')
      end,
      test_func_reject_attr = function()
        local tmpl = '{{ users|rejectattr("id", is_odd)|'..
                     'mapattr("name")|join(",") }}'
        local env = {users = {{id = 1, name = 'john'},
                              {id = 2, name = 'jane'},
                              {id = 3, name = 'mike'}}}
        assert_equal(expand(tmpl, env), 'jane')
      end,
    }
  },
  imports = {
    import_tests = {
      setup = function()
        lupa.configure{loader = lupa.loaders.filesystem('data/imports')}
      end,
      teardown = lupa.reset,
      test_context_imports = function()
        lupa.env.bar = 23
        local tmpl = '{% import "module" as m %}{{ m.test() }}'
        local env = {foo = 42}
        assert_equal(expand(tmpl, env), '[|23]')
        tmpl = '{% import "module" as m without context %}{{ m.test() }}'
        assert_equal(expand(tmpl, env), '[|23]')
        tmpl = '{% import "module" as m with context %}{{ m.test() }}'
        assert_equal(expand(tmpl, env), '[42|23]')
        -- Note: "from x import y" is not supported by this implementation.
        lupa.env.bar = nil
      end,
      -- Note: test_trailing_comma is not applicable since this implementation
      -- does not support "from x import y".
      test_exports = function()
        local tmpl = '{% import "exports" %}'
        local env = {}
        expand(tmpl, env)
        assert_equal(env.toplevel(), '...')
        assert(not env.__missing)
        assert_equal(env.variable, 42)
        assert(not env.nothere)
      end,
    },
    include_tests = {
      setup = function()
        lupa.configure{loader = lupa.loaders.filesystem('data/imports')}
      end,
      teardown = lupa.reset,
      test_context_include = function()
        local tmpl = '{% include "header" %}'
        local env = {foo = 42}
        assert_equal(expand(tmpl, env), '[42|23]')
        tmpl = '{% include "header" with context %}'
        assert_equal(expand(tmpl, env), '[42|23]')
        tmpl = '{% include "header" without context %}'
        assert_equal(expand(tmpl, env), '[|23]')
      end,
      test_choice_includes = function()
        local tmpl = '{% include {"missing", "header"} %}'
        local env = {foo = 42}
        assert_equal(expand(tmpl, env), '[42|23]')
        tmpl = '{% include {"missing", "missing2"} ignore missing %}'
        assert_equal(expand(tmpl, env), '')
        tmpl = '{% include {"missing", "missing2"} %}'
        assert_raises('no file.-found', expand, tmpl, env)
        tmpl = '{% include x %}'
        env.x = {'missing', 'header'}
        assert_equal(expand(tmpl, env), '[42|23]')
        env.x = 'header'
        assert_equal(expand(tmpl, env), '[42|23]')
        tmpl = '{% include {x} %}'
        assert_equal(expand(tmpl, env), '[42|23]')
      end,
      test_include_ignoring_missing = function()
        local tmpl = '{% include "missing" %}'
        assert_raises('no file.-found', expand, tmpl)
        tmpl = '{% include "missing" ignore missing %}'
        assert_equal(expand(tmpl), '')
        tmpl = '{% include "missing" ignore missing with context %}'
        assert_equal(expand(tmpl), '')
        tmpl = '{% include "missing" ignore missing without context %}'
        assert_equal(expand(tmpl), '')
      end,
      test_context_include_with_override = function()
        local tmpl = 'main'
        assert_equal(expand_file(tmpl), '123')
      end,
      test_unoptimized_scopes = function()
        local tmpl = [[
            {% macro outer(o) %}
            {% macro inner() %}
            {% include "o_printer" %}
            {% endmacro %}
            {{ inner() }}
            {% endmacro %}
            {{ outer("FOO") }}
        ]]
        assert_equal(expand(tmpl):trim(), '(FOO)')
      end,
    }
  },
  inheritence = {
    inheritence_tests = {
      setup = function()
        lupa.configure{
          trim_blocks = true,
          loader = lupa.loaders.filesystem('data/inheritence')
        }
      end,
      teardown = lupa.reset,
      test_layout = function()
        local tmpl = 'layout'
        assert_equal(expand_file(tmpl),
                     '|block 1 from layout|block 2 from '..
                     'layout|nested block 4 from layout|')
      end,
      test_level1 = function()
        local tmpl = 'level1'
        assert_equal(expand_file(tmpl),
                     '|block 1 from level1|block 2 from '..
                     'layout|nested block 4 from layout|')
      end,
      test_level2 = function()
        local tmpl = 'level2'
        assert_equal(expand_file(tmpl),
                     '|block 1 from level1|nested block 5 from '..
                     'level2|nested block 4 from layout|')
      end,
      test_level3 = function()
        local tmpl = 'level3'
        assert_equal(expand_file(tmpl),
                     '|block 1 from level1|block 5 from level3|'..
                     'block 4 from level3|')
      end,
      test_level4 = function()
        local tmpl = 'level4'
        assert_equal(expand_file(tmpl),
                     '|block 1 from level1|block 5 from '..
                     'level3|block 3 from level4|')
      end,
      test_super = function()
        local tmpl = 'super/c'
        assert_equal(expand_file(tmpl), '--INTRO--|BEFORE|[(INNER)]|AFTER')
      end,
      -- Note: test_working is not applicable since it is incomplete.
      test_reuse_blocks = function()
        local tmpl = '{% block foo %}42{% endblock %}|'..
                     '{{ self.foo() }}|{{ self.foo() }}'
        assert_equal(expand(tmpl), '42|42|42')
      end,
      -- Note: test_preserve_blocks is not applicable since false blocks are
      -- never loaded.
      test_dynamic_inheritence = function()
        for i = 1, 2 do
          local tmpl = 'dynamic/child'
          local env = {master = 'master'..i}
          assert_equal(expand_file(tmpl, env), 'MASTER'..i..'CHILD')
        end
      end,
      test_multi_inheritence = function()
        -- Note: cannot have
        --   {% if master %}{% extends master %}{% else %}
        --   {% extends 'master1' %}{% endif %}{% block x %}CHILD{% endblock %}
        -- since the extends within 'if' is local to that block.
        -- Must use {% extends master or 'master1' %} instead.
        local tmpl = 'multi/child'
        local env = {master = 'master2'}
        assert_equal(expand_file(tmpl, env), 'MASTER2CHILD')
        local env = {master = 'master1'}
        assert_equal(expand_file(tmpl, env), 'MASTER1CHILD')
        assert_equal(expand_file(tmpl), 'MASTER1CHILD')
      end,
      test_scoped_block = function()
        local tmpl = '{% extends "scoped/master.html" %}{% block item %}'..
                     '{{ item }}{% endblock %}'
        local env = {seq = range(5)}
        assert_equal(expand(tmpl, env), '[1][2][3][4][5]')
      end,
      test_super_in_scoped_block = function()
        local tmpl = '{% extends "super_scoped/master.html" %}{% block item %}'..
                     '{{ super() }}|{{ item * 2 }}{% endblock %}'
        local env = {seq = range(5)}
        assert_equal(expand(tmpl, env), '[1|2][2|4][3|6][4|8][5|10]')
      end,
      test_scoped_block_after_inheritence = function()
        local tmpl = 'scoped/index.html'
        local env = {the_foo = 42}
        assert_equal(expand_file(tmpl, env):trim():gsub('%s+', '|'), '43|44|45')
      end,
      test_fixed_macro_scoping = function()
        local tmpl = 'macro_scoping/test.html'
        assert_equal(expand_file(tmpl, env):trim():gsub('%s+', '|'),
                     'outer_box|my_macro')
      end,
      test_double_extends = function()
        local tmpl = 'doublee'
        assert_raises('multiple.+extends', expand_file, tmpl)
      end,
    }
  },
  lexer = {
    -- Note: token_stream_tests are not applicable since this implementation
    -- does not have a similar tokenizer.
    lexer_tests = {
      test_raw1 = function()
        local tmpl = '{% raw %}foo{% endraw %}|'..
                     '{%raw%}{{ bar }}|{% baz %}{%       endraw    %}'
        assert_equal(expand(tmpl), 'foo|{{ bar }}|{% baz %}')
      end,
      test_raw2 = function()
        local tmpl = '1  {%- raw -%}   2   {%- endraw -%}   3'
        assert_equal(expand(tmpl), '123')
      end,
      test_raw3 = function()
        local tmpl = '{% raw %}{{ FOO }} and {% BAR %}{% endraw %}'
        assert_equal(expand(tmpl), '{{ FOO }} and {% BAR %}')
      end,
      test_balancing = function()
        lupa.configure('{%', '%}', '${', '}')
        local tmpl = [[{% for item in seq
            %}${{item..' foo'}|string|upper}{% endfor %}]]
        local env = {seq = range(3)}
        assert_equal(expand(tmpl, env), '{"1 FOO"}{"2 FOO"}{"3 FOO"}')
        lupa.reset()
      end,
      test_comments = function()
        lupa.configure('<!--', '-->', '{', '}')
        local tmpl = [[
<ul>
<!--- for item in seq -->
  <li>{item}</li>
<!--- endfor -->
</ul>]]
        local env = {seq = range(3)}
        assert_equal(expand(tmpl, env), '<ul>\n  <li>1</li>\n  '..
                                        '<li>2</li>\n  <li>3</li>\n</ul>')
        lupa.reset()
      end,
      -- Note: test_string_escapes is not applicable since Lua does not handle
      -- unicode well enough (even with Lua 5.3).
      -- Note: test_bytefallback is not applicable since Lua does not have a
      -- data pretty-printer.
      -- Note: test_operators is not applicable since this implementation
      -- does not have a similar tokenizer.
      test_normalizing = function()
        local tmpl = '1\n2\r\n3\n4\n'
        for _, seq in ipairs{'\r\n', '\n'} do
          lupa.configure{newline_sequence = seq}
          assert_equal(expand(tmpl):gsub(seq, 'X'), '1X2X3X4')
        end
        lupa.reset()
      end,
      test_trailing_newline = function()
        for _, keep in ipairs{true, false} do
          lupa.configure{keep_trailing_newline = keep}
          local tmpl = ''
          assert_equal(expand(tmpl), '')
          tmpl = 'no\nnewline'
          assert_equal(expand(tmpl), tmpl)
          tmpl = 'with\nnewline\n'
          assert_equal(expand(tmpl), keep and tmpl or 'with\nnewline')
          tmpl = 'with\nseveral\n\n\n'
          assert_equal(expand(tmpl), keep and tmpl or 'with\nseveral\n\n')
        end
        lupa.reset()
      end,
    },
    parser_tests = {
      test_php_syntax = function()
        lupa.configure('<?', '?>', '<?=', '?>', '<!--', '-->')
        local tmpl = [[
<!-- I'm a comment, I'm not interesting -->
<? for item in seq -?>
    <?= item ?>
<?- endfor ?>]]
        local env = {seq = range(5)}
        assert_equal(expand(tmpl, env), '\n12345')
        lupa.reset()
      end,
      test_erb_syntax = function()
        lupa.configure('<%', '%>', '<%=', '%>', '<%#', '%>')
        local tmpl = [[
<%# I'm a comment, I'm not interesting %>
<% for item in seq -%>
    <%= item %>
<%- endfor %>]]
        local env = {seq = range(5)}
        assert_equal(expand(tmpl, env), '\n12345')
        lupa.reset()
      end,
      test_comment_syntax = function()
        lupa.configure('<!--', '-->', '${', '}', '<!--#', '-->')
        local tmpl = [[
<!--# I'm a comment, I'm not interesting -->
<!-- for item in seq --->
    ${item}
<!--- endfor -->]]
        local env = {seq = range(5)}
        assert_equal(expand(tmpl, env), '\n12345')
        lupa.reset()
      end,
      test_balancing = function()
        local tmpl = [[{{{1, 2, 3}|length}}]]
        assert_equal(expand(tmpl), '3')
      end,
      test_start_comment = function()
        local tmpl = [[{# foo comment
        and bar comment #}
        {% macro blub() %}foo{% endmacro %}
        {{ blub() }}]]
        assert_equal(expand(tmpl):trim(), 'foo')
      end,
      -- Note: test_line_syntax is not applicable since line statements are not
      -- supported.
      -- Note: test_line_syntax_priority is not applicable since line statements
      -- are not supported.
      test_error_messages = function()
        local tmpl = '{% for item in seq %}...{% endif %}'
        assert_raises('endfor.+expected', expand, tmpl)
        tmpl = '{% if foo %}{% for item in seq %}...{% endfor %}{% endfor %}'
        assert_raises('endif.+expected', expand, tmpl)
        tmpl = '{% if foo %}'
        assert_raises('endif.+expected', expand, tmpl)
        tmpl = '{% for item in seq %}'
        assert_raises('endfor.+expected', expand, tmpl)
        tmpl = '{% block foo-bar-baz %}{% endblock %}'
        assert_raises('invalid block name', expand, tmpl)
        tmpl = '{% unknown_tag %}'
        assert_raises('unknown or unexpected tag', expand, tmpl)
      end,
    },
    -- Note: syntax_tests are not applicable since this implementation uses
    -- Lua's parser.
    lstrip_blocks_tests = {
      setup = function() lupa.configure{lstrip_blocks = true} end,
      teardown = lupa.reset,
      test_lstrip = function()
        local tmpl = '    {% if true %}\n    {% endif %}'
        assert_equal(expand(tmpl), '\n')
      end,
      test_lstrip_trim = function()
        lupa.configure{lstrip_blocks = true, trim_blocks = true}
        local tmpl = '    {% if true %}\n    {% endif %}'
        assert_equal(expand(tmpl), '')
        lupa.configure{lstrip_blocks = true}
      end,
      test_no_lstrip = function()
        local tmpl = '    {%+ if true %}\n    {%+ endif %}'
        assert_equal(expand(tmpl), '    \n    ')
      end,
      test_lstrip_endline = function()
        local tmpl = '    hello{% if true %}\n    goodbye{% endif %}'
        assert_equal(expand(tmpl), '    hello\n    goodbye')
      end,
      test_lstrip_inline = function()
        local tmpl = '    {% if true %}hello    {% endif %}'
        assert_equal(expand(tmpl), 'hello    ')
      end,
      test_lstrip_nested = function()
        local tmpl = '    {% if true %}a {% if true %}b {% endif %}c {% endif %}'
        assert_equal(expand(tmpl), 'a b c ')
      end,
      test_lstrip_left_chars = function()
        local tmpl = [[    abc {% if true %}
        hello{% endif %}]]
        assert_equal(expand(tmpl), '    abc \n        hello')
      end,
      -- Note: test_lstrip_embedded_strings is not applicable since this
      -- implementation's grammar cannot parse Lua itself in order to handle
      -- embedded tags.
      test_lstrip_preserve_leading_newlines = function()
        local tmpl = '\n\n\n{% set hello = 1 %}'
        assert_equal(expand(tmpl), '\n\n\n')
      end,
      test_lstrip_comment = function()
        local tmpl = [[    {# if true #}
hello
    {#endif#}]]
        assert_equal(expand(tmpl), '\nhello\n')
      end
    },
    lstrip_blocks_angle_bracket_tests = {
      setup = function()
        lupa.configure('<%', '%>', '${', '}', '<%#', '%>',
                       {lstrip_blocks = true, trim_blocks = true})
      end,
      teardown = lupa.reset,
      test_lstrip_angle_bracket_simple = function()
        local tmpl = '    <% if true %>hello    <% endif %>'
        assert_equal(expand(tmpl), 'hello    ')
      end,
      test_lstrip_angle_bracket_comment = function()
        local tmpl = '    <%# if true %>hello    <%# endif %>'
        assert_equal(expand(tmpl), 'hello    ')
      end,
      test_lstrip_angle_bracket = function()
        -- Note: this implementation does not support line statements, so this
        -- test input is slightly different.
        local tmpl = [[
    <%# regular comment %>
    <% for item in seq %>
${item}
   <% endfor %>]]
        local env = {seq = range(5)}
        assert_equal(expand(tmpl, env), '1\n2\n3\n4\n5\n')
      end,
      test_lstrip_angle_bracket_compact = function()
        -- Note: this implementation does not support line statements, so this
        -- test input is slightly different.
        local tmpl = [[
    <%#regular comment%>
    <%for item in seq%>
${item}
   <%endfor%>]]
        local env = {seq = range(5)}
        assert_equal(expand(tmpl, env), '1\n2\n3\n4\n5\n')
      end,
    },
    lstrip_blocks_php_syntax_tests = {
      setup = function()
        lupa.configure('<?', '?>', '<?=', '?>', '<!--', '-->',
                       {lstrip_blocks = true, trim_blocks = true})
      end,
      teardown = lupa.reset,
      test_php_syntax_with_manual = function()
        local tmpl = [[
    <!-- I'm a comment, I'm not interesting -->
    <? for item in seq -?>
        <?= item ?>
    <?- endfor ?>]]
        local env = {seq = range(5)}
        assert_equal(expand(tmpl, env), '12345')
      end,
      test_php_syntax = function()
        local tmpl = [[
    <!-- I'm a comment, I'm not interesting -->
    <? for item in seq ?>
        <?= item ?>
    <? endfor ?>]]
        local env = {seq = range(5)}
        assert_equal(expand(tmpl, env),
                     '        1\n        2\n        3\n        4\n        5\n')
      end,
      test_php_syntax_compact = function()
        local tmpl = [[
    <!-- I'm a comment, I'm not interesting -->
    <?for item in seq?>
        <?=item?>
    <?endfor?>]]
        local env = {seq = range(5)}
        assert_equal(expand(tmpl, env),
                     '        1\n        2\n        3\n        4\n        5\n')
      end,
    },
    lstrip_blocks_erb_syntax_tests = {
      setup = function()
        lupa.configure('<%', '%>', '<%=', '%>', '<%#', '%>',
                       {lstrip_blocks = true, trim_blocks = true})
      end,
      teardown = lupa.reset,
      test_erb_syntax = function()
        local tmpl = [[
<%# I'm a comment, I'm not interesting %>
    <% for item in seq %>
    <%= item %>
    <% endfor %>
]]
        local env = {seq = range(5)}
        assert_equal(expand(tmpl, env), '    1\n    2\n    3\n    4\n    5\n')
      end,
      test_erb_syntax_with_manual = function()
        local tmpl = [[
<%# I'm a comment, I'm not interesting %>
    <% for item in seq -%>
        <%= item %>
    <%- endfor %>]]
        local env = {seq = range(5)}
        assert_equal(expand(tmpl, env), '12345')
      end,
      test_erb_syntax_no_lstrip = function()
        local tmpl = [[
<%# I'm a comment, I'm not interesting %>
    <%+ for item in seq -%>
        <%= item %>
    <%- endfor %>]]
        local env = {seq = range(5)}
        assert_equal(expand(tmpl, env), '    12345')
      end,
    },
    lstrip_blocks_comment_tests = {
      test_comment_syntax = function()
        lupa.configure('<!--', '-->', '${', '}', '<!--#', '-->',
                       {lstrip_blocks = true, trim_blocks = true})
        local tmpl = [[
<!--# I'm a comment, I'm not interesting -->
<!-- for item in seq --->
    ${item}
<!--- endfor -->]]
        local env = {seq = range(5)}
        assert_equal(expand(tmpl, env), '12345')
        lupa.reset()
      end,
    }
  },
  regression = {
    corner_case_tests = {
      test_assigned_scoping = function()
        local tmpl = [[
        {%- for item in {1, 2, 3, 4} -%}
            [{{ item }}]
        {%- endfor %}
        {{- item -}}
        ]]
        local env = {item = 42}
        assert_equal(expand(tmpl, env), '[1][2][3][4]42')
        tmpl = [[
        {%- for item in {1, 2, 3, 4} -%}
            [{{ item }}]
        {%- endfor %}
        {%- set item = 42 %}
        {{- item -}}
        ]]
        assert_equal(expand(tmpl), '[1][2][3][4]42')
        tmpl = [[
        {%- set item = 42 %}
        {%- for item in {1, 2, 3, 4} -%}
            [{{ item }}]
        {%- endfor %}
        {{- item -}}
        ]]
        assert_equal(expand(tmpl), '[1][2][3][4]42')
      end,
      test_closure_scoping = function()
        local tmpl = [[
        {%- set wrapper = "<FOO>" %}
        {%- for item in {1, 2, 3, 4} %}
            {%- macro wrapper() %}[{{ item }}]{% endmacro %}
            {{- wrapper() }}
        {%- endfor %}
        {{- wrapper -}}
        ]]
        assert_equal(expand(tmpl), '[1][2][3][4]<FOO>')
      end,
    },
    other_tests = {
      test_keyword_folding = function()
        lupa.filters.testing = function(v, s) return v..s end
        local tmpl = [[{{ 'test'|testing('stuff') }}]]
        assert_equal(expand(tmpl), 'teststuff')
        lupa.filters.testing = nil
      end,
      test_extends_output = function()
        -- Note: "extends" cannot be within an "if" so use conditional expr.
        local tmpl = '{% extends expr and "data/other/parent.html" %}'..
                     '[[{% block title %}title{% endblock %}]]'..
                     '{% for item in {1, 2, 3} %}({{ item }}){% endfor %}'
        local env = {expr = false}
        assert_equal(expand(tmpl, env):gsub('\n', ''), '[[title]](1)(2)(3)')
        env = {expr = true}
        assert_equal(expand(tmpl, env):gsub('\n', ''), '((title))')
      end,
      test_urlize_filter_escaping = function()
        local tmpl = '{{ "http://www.example.org/<foo"|urlize }}'
        assert_equal(expand(tmpl), '<a href="http://www.example.org/&lt;foo">http://www.example.org/&lt;foo</a>')
      end,
      test_loop_call_loop = function()
        local tmpl = [[

        {% macro test() %}
            {{ caller() }}
        {% endmacro %}

        {% for num1 in range(5) %}
            {% call test() %}
                {% for num2 in range(10) %}
                    {{ loop.index }}
                {% endfor %}
            {% endcall %}
        {% endfor %}

        ]]
        assert_equal(expand(tmpl):trim():gsub('%s+', ''),
                     string.rep('12345678910', 5))
      end,
      test_weird_inline_comment = function()
        local tmpl = '{% for item in seq {# missing #}%}...{% endfor %}'
        assert_raises('%%}.+expected', expand, tmpl)
      end,
      test_old_macro_loop_scoping = function()
        local tmpl = '{% for i in {1, 2} %}{{ i }}{% endfor %}'..
                     '{% macro i() %}3{% endmacro %}{{ i() }}'
        assert_equal(expand(tmpl), '123')
      end,
      test_partial_conditional_assignments = function()
        local tmpl = '{% if b %}{% set a = 42 %}{% endif %}{{ a }}'
        local env = {a = 23}
        assert_equal(expand(tmpl, env), '23')
        env = {b = true}
        assert_equal(expand(tmpl, env), '42')
      end,
      test_stacked_locals_scoping = function()
        -- Note: this implementation does not support line statements, so this
        -- test input is slightly different.
        local tmpl = [[
{% for j in {1, 2}     -%}
{%   set x = 1         -%}
{%   for i in {1, 2}   -%}
{{     x               -}}
{%     if i % 2 == 0   -%}
{%       set x = x + 1 -%}
{%     endif           -%}
{%   endfor            -%}
{% endfor              -%}
{% if a                -%}
{{   'A'               -}}
{% elseif b            -%}
{{   'B'               -}}
{% elseif c == d       -%}
{{   'C'               -}}
{% else                -%}
{{   'D'               -}}
{% endif               -%}
    ]]
        local env = {a = nil, b = false, c = 42, d = 42.0}
        assert_equal(expand(tmpl, env), '1111C')
      end,
      test_stacked_locals_scoping_twoframe = function()
        local tmpl = [[
            {% set x = 1 %}
            {% for item in foo %}
                {% if item == 1 %}
                    {% set x = 2 %}
                {% endif %}
            {% endfor %}
            {{ x }}
        ]]
        local env = {foo = {1}}
        assert_equal(expand(tmpl, env):gsub('%s+', ''), '1')
      end,
      test_call_with_args = function()
        local tmpl = [[{% macro dump_users(users) -%}
        <ul>
          {%- for user in users -%}
            <li><p>{{ user.username|e }}</p>{{ caller(user) }}</li>
          {%- endfor -%}
          </ul>
        {%- endmacro -%}

        {% call(user) dump_users(list_of_user) -%}
          <dl>
            <dl>Realname</dl>
            <dd>{{ user.realname|e }}</dd>
            <dl>Description</dl>
            <dd>{{ user.description }}</dd>
          </dl>
        {% endcall %}]]
        local env = {
          list_of_user = {
            {username = 'apo', realname = 'something else',
             description = 'test'}
          }
        }
        local lines = {}
        for line in expand(tmpl, env):gmatch('[^\n]+') do
          lines[#lines + 1] = line:trim()
        end
        assert_equal(lines[1], '<ul><li><p>apo</p><dl>')
        assert_equal(lines[2], '<dl>Realname</dl>')
        assert_equal(lines[3], '<dd>something else</dd>')
        assert_equal(lines[4], '<dl>Description</dl>')
        assert_equal(lines[5], '<dd>test</dd>')
        assert_equal(lines[6], '</dl>')
        assert_equal(lines[7], '</li></ul>')
      end,
      test_empty_if_condition_fails = function()
        local tmpl = '{% if %}....{% endif %}'
        assert_raises('expression expected', expand, tmpl)
        tmpl = '{% if foo %}...{% elif %}...{% endif %}'
        assert_raises('additional tag or.+endif.+expected', expand, tmpl)
        tmpl = '{% for x in %}..{% endfor %}'
        assert_raises('invalid for expression', expand, tmpl)
      end,
      -- Note: test_recursive_loop is not applicable since it is incomplete.
      test_else_loop = function()
        local tmpl = [[
            {% for x in y %}
                {{ loop.index0 }}
            {% else %}
                {% for i in range(3) %}{{ i }}{% endfor %}
            {% endfor %}
        ]]
        local env = {y = {}}
        assert_equal(expand(tmpl, env):trim(), '123')
      end,
      -- Note: test_correct_prefix_loader is not applicable since this
      -- implementation does not use a prefix loader.
      -- TODO: this isn't exactly practical...
      test_contextfunction_callable_classes = function()
        local tmpl = '{{ callableclass() }}'
        local env = {hello = 'TEST'}
        env.callableclass = setmetatable({env = env}, {__call = function(t)
          return t.env.hello
        end})
        assert_equal(expand(tmpl, env), 'TEST')
      end,
    }
  },
  -- Note: security tests are not applicable since Lua has no security
  -- mechanisms.
  tests = {
    tests_tests = {
      test_defined = function()
        local tmpl = '{{ is_defined(nil) }}|{{ is_defined(true) }}'
        assert_equal(expand(tmpl), 'false|true')
      end,
      test_even = function()
        local tmpl = '{{ is_even(1) }}|{{ is_even(2) }}'
        assert_equal(expand(tmpl), 'false|true')
      end,
      test_odd = function()
        local tmpl = '{{ is_odd(1) }}|{{ is_odd(2) }}'
        assert_equal(expand(tmpl), 'true|false')
      end,
      test_lower = function()
        local tmpl = '{{ is_lower("foo") }}|{{ is_lower("FOO") }}'
        assert_equal(expand(tmpl), 'true|false')
      end,
      test_typechecks = function()
        local tmpl = [[
            {{ is_undefined(42) }}
            {{ is_defined(42) }}
            {{ is_nil(42) }}
            {{ is_nil(nil) }}
            {{ is_number(42) }}
            {{ is_string(42) }}
            {{ is_string("foo") }}
            {{ is_sequence("foo") }}
            {{ is_sequence({1}) }}
            {{ is_callable(range) }}
            {{ is_callable(42) }}
            {{ is_iterable(range(5)) }}
            {{ is_mapping({}) }}
            {{ is_mapping(mydict) }}
            {{ is_mapping("foo") }}
        ]]
        local env = {mydict = {}}
        local results = {}
        for result in expand(tmpl, env):gmatch('%S+') do
          results[#results + 1] = result
        end
        local expected = {
          'false', 'true', 'false', 'true', 'true', 'false',
          'true', 'false', 'true', 'true', 'false', 'true',
          'true', 'true', 'false'
        }
        for i = 1, #results do assert_equal(results[i], expected[i]) end
      end,
      test_sequence = function()
        local tmpl = '{{ is_sequence({1, 2, 3}) }}|'..
                     '{{ is_sequence("foo") }}|'..
                     '{{ is_sequence(42) }}'
        assert_equal(expand(tmpl), 'true|false|false')
      end,
      test_upper = function()
        local tmpl = '{{ is_upper("FOO") }}|{{ is_upper("foo") }}'
        assert_equal(expand(tmpl), 'true|false')
      end,
      test_sameas = function()
        local tmpl = '{{ is_sameas(foo, false) }}|'..
                     '{{ is_sameas(nil, false) }}'
        local env = {foo = false}
        assert_equal(expand(tmpl, env), 'true|false')
      end,
      test_nil_is_nil = function()
        local tmpl = '{{ is_sameas(foo, nil) }}'
        local env = {foo = nil}
        assert_equal(expand(tmpl, env), 'true')
      end,
      test_escaped = function()
        lupa.configure{autoescape = true}
        -- Note: This implementation does not support markup, so this test input
        -- is slightly different.
        local tmpl = '{% set y = "foo"|safe %}{{ is_escaped(x) }}|{{ is_escaped(y) }}'
        local env = {x = 'foo'}
        assert_equal(expand(tmpl, env), 'false|true')
        lupa.reset()
      end,
    }
  }
}

local num_tests, failures = 0, {}
print('Starting test suite.')
for test_group, types in pairs(test_suite) do
  for test_type, tests in pairs(types) do
    print("Running all of "..test_type.."'s tests.")
    if tests.setup then tests.setup() end
    for test_name, test in pairs(tests) do
      if test_name ~= 'setup' and test_name ~= 'teardown' then
        local pass, message = pcall(test)
        if pass then
          io.output():write('.')
        else
          io.output():write('E')
          failures[#failures + 1] = {
            test_type, test_name, message:match('^[^:]*:?%d*:?%s*(.+)$')
          }
        end
        io.output():flush()
        num_tests = num_tests + 1
      end
    end
    if tests.teardown then tests.teardown() end
    print('') -- newline
  end
end
print('\nSummary:')
if #failures == 0 then
  print('All '..num_tests..' tests passed!')
else
  local line = string.rep('-', 72)
  print(#failures..' of '..num_tests..' tests failed!')
  print(line)
  for i = 1, #failures do
    print("Failure in "..failures[i][1].."'s "..failures[i][2]..':')
    print(failures[i][3])
    print(line)
  end
end
