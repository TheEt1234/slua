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

# Basic slua environment (`slua.env.basic_env`)
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

