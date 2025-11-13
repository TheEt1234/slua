# Environment documentation
This is *not* the documentation for creating your own environment, see guide.md for that.

This is a documentation for the functions in the default environments (so when you do `slua.env.basic_env` and `slua.env.add_luanti_utils`).

This documentation is marked under [CC0](https://creativecommons.org/publicdomain/zero/1.0). You should copy paste parts of it to make ***in-game documentation*** for your own mods!

# Every slua environment
- `__slua = {}` 
    - An immutable table, cannot be changed
    - **Any identifier (so variable name) with the name __slua will be *silently replaced* with _not_allowed**
    - You can get it with `_G["__slua"]` if you really want it, assuming the environment has `_G`
    - contains `__slua.concat` and `__slua.limit_function`

# Basic slua environment (from `slua.env.basic_env`)

### base
- [`assert`](https://www.lua.org/manual/5.1/manual.html#pdf-assert)
- [`error`](https://www.lua.org/manual/5.1/manual.html#pdf-error)
- `_G` - points to the sandboxed environment, for example: `_G.assert` will equal to `assert`
- [`ipairs`](https://www.lua.org/manual/5.1/manual.html#pdf-ipairs)
- [`pairs`](https://www.lua.org/manual/5.1/manual.html#pdf-pairs)
- [`next`](https://www.lua.org/manual/5.1/manual.html#pdf-next)
- [`pcall`](https://www.lua.org/manual/5.1/manual.html#pdf-pcall)
- [`xpcall`](https://www.lua.org/manual/5.1/manual.html#pdf-xpcall)
- `f, syntax_errors = loadstring(code, chukname)` - Turns string `code` into a function
    - `code` - length may be limited
    - `chukname` - limited to 500 characters
    - `f` is nil if there are `syntax_errors`
    - `syntax_errors` - is a table, but rarely can be a string too (useless detail: it depends if the syntax error is coming from `tl` or not)
        - When a table, it is in the format of
        ```lua
            syntax_error = {
                filename = "something.lua",
                msg = "syntax error", -- tl can often give you some of these really generic syntax errors
                x = 1,
                y = 1, -- On the flip side, you get the exact position of where it happened
            }

            syntax_errors = {syntax_error, syntax_error, ...}
        ```
- [`select`](https://www.lua.org/manual/5.1/manual.html#pdf-select)
- [`tonumber`](https://www.lua.org/manual/5.1/manual.html#pdf-tonumber)
- [`tostring`](https://www.lua.org/manual/5.1/manual.html#pdf-tostring)
- [`type`](https://www.lua.org/manual/5.1/manual.html#pdf-type)
- [`unpack`](https://www.lua.org/manual/5.1/manual.html#pdf-unpack)

### `string`
- [`string.byte`](https://www.lua.org/manual/5.1/manual.html#pdf-string.byte)
- [`string.char`](https://www.lua.org/manual/5.1/manual.html#pdf-string.char)
- [`string.find`](https://www.lua.org/manual/5.1/manual.html#pdf-string.find) - **without patterns**
- [`string.format`](https://www.lua.org/manual/5.1/manual.html#pdf-string.format) - limited string length
- [`string.len`](https://www.lua.org/manual/5.1/manual.html#pdf-string.len)
- [`string.lower`](https://www.lua.org/manual/5.1/manual.html#pdf-string.lower)
- [`string.rep`](https://www.lua.org/manual/5.1/manual.html#pdf-string.rep) - limited string length
- [`string.reverse`](https://www.lua.org/manual/5.1/manual.html#pdf-string.reverse)
- [`string.sub`](https://www.lua.org/manual/5.1/manual.html#pdf-string.sub)
- [`string.upper`](https://www.lua.org/manual/5.1/manual.html#pdf-string.upper)

### `table`
- [`table.concat`](https://www.lua.org/manual/5.1/manual.html#pdf-table.concat)
- [`table.insert`](https://www.lua.org/manual/5.1/manual.html#pdf-table.insert)
- [`table.maxn`](https://www.lua.org/manual/5.1/manual.html#pdf-table.maxn)
- [`table.remove`](https://www.lua.org/manual/5.1/manual.html#pdf-table.remove)
- [`table.sort`](https://www.lua.org/manual/5.1/manual.html#pdf-table.sort)

### [`math`](https://www.lua.org/manual/5.1/manual.html#5.6)
- Except `math.randomseed`

### `os`
- [`os.clock`](https://www.lua.org/manual/5.1/manual.html#pdf-os.clock)
- [`os.difftime`](https://www.lua.org/manual/5.1/manual.html#pdf-os.difftime)
- [`os.time`](https://www.lua.org/manual/5.1/manual.html#pdf-os.time)

### `debug`
- [`debug.getinfo`](https://www.lua.org/manual/5.1/manual.html#pdf-debug.getinfo) - can't output functions
- [`debug.traceback`](https://www.lua.org/manual/5.1/manual.html#pdf-debug.traceback)

### [`bit`](https://bitop.luajit.org/api.html)
