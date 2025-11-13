This is not a guide, and it is not an explanation of how slua works, this is API documentation.  
Slua has a common pattern of having `one_high_level_function`, that is made up of multiple lower level functions that you can use to recreate that `one_high_level_function`, and it may not be needed to learn about those lower level functions. I wish this pattern was seen more in luanti.  
This API documentation may send you to other functions to avoid repeating itself, please be prepared to use `Ctrl+F` if in a web browser (vscode counts as a web browser)

# slua
- `slua = {}` - all functions will be located in this table

# Env
- One of the more interesting parts of slua (in a bad way, you have to be really careful with this, more careful than in other methods of sandboxing)
- `slua.env = {}`
- This docs will often reference "env configuration", it is a table like
    ```lua
    env_config = {
        max_string_len = 64000,
        limit_function = slua.get_default_limit_function(8, "timeout"),
        max_loadstring_code_length = 10000, -- 10000 characters should be enough hopefully
    }
- `env = slua.env.init_environment(env, env_config)` - Adds the immutable `__slua` table to that environment
    - `env` - Can be a table or nil, gets changed
- `env = slua.env.basic_env(env, env_config)` - Adds basic functions to the environment, **without any luanti functions**
    - `env` - Can be a table or nil, gets changed
- `env = slua.env.add_luanti_utils(env, env_config)` - Adds luanti functions to the environment, including things like `string.split` and `string.trim`, but also things like `core.get_us_time` and the vector library
    - `env` - Can be a table or nil, gets changed


# Sandbox
- `thread, syntax_errors = slua.create_sandbox(sandbox_options)`
    - `sandbox_options` a table like:
        ```lua
            {
                env = {}, -- An environment, must have __slua table defined
                code = "", -- The input code, may be anything, do not pass a result from `slua.default_compile to this`, as this function will do that already
                chunkname = "hello", -- Can be nil, probably should be nil unless you want it, really doesn't really matter
            }
        ```
    - `thread` - coroutine, may be nil if there are `syntax_errors`
        - Do not directly run this with `coroutine.resume`, because then the sandbox can access unsafe string functions through `(""):whatever()` syntax
        - Instead, run it with `slua.run_sandbox`
    - `syntax_errors` - May be a string (a syntax error coming from `loadstring`, or may be an array of teal syntax errors), or may be nil if there aren't any syntax errors
        ```lua
            syntax_error = {
                filename = "something.lua",
                msg = "syntax error", -- tl can often give you some of these really generic syntax errors
                x = 1,
                y = 1, -- On the flip side, you get the exact position of where it happened
            }

            syntax_errors = {syntax_error, syntax_error, ...}
        ```
- `ok, ... = slua.run_sandbox(co, env)`
    - `co` - the coroutine you got from `slua.create_sandbox`
    - `env` - `env.string` gets used for string metatable sandboxing
    - Returns the same things as `coroutine.resume`


# Misc
- `returned_f = slua.make_safer(f, config, ignore_functions_in_arguments)`
    - Makes `returned_f` safer to put in a sandbox by:
        - Checking the length of all the string arguments, and making sure their combined length is less than `config.max_string_len`
        - Escapes string metatable sandboxing exclusively for `returned_f` (see the implications of that in `slua.escape_string_sandbox`
        - `returned_f` calls `config.limit_function()` before and after `f` executes
    - `config` - Meant to be the environment configuration
    - `ignore_functions_in_arguments` - if set to nil/false, `returned_f` will throw an error when it has a function in one of its arguments
        - See `slua.escape_string_sandbox` as to why this is a thing
- `f = slua.get_default_limit_function(time, message)`
    - Returns a function that will call `coroutine.yield(message)` after `time` has passed since the first call of it
    - time is in miliseconds
- `f = slua.escape_string_sandbox(f)`
    - returned function will escape any string metatable sandboxing that has been thrown at it
    - **`f` must not call any sandbox-provided functions, unless it re-instates that string metatable sandboxing**
    - Okay but what does that actually mean??:
        - Strings by default have a metatable, whose `__index` field points to `_G.string` (where `_G` is an unsandboxed environment)
            - This is used when you do `("%something"):format("s")` - equivalent to `getmetatable("").__index.format("%something", "s")`
        - This is problematic, as some functions in that aren't safe to put in a sandbox
        - So the string metatable sandbox's `__index` field gets changed to `sandboxed_env.string` instead
        - Problem now is, that your code now can't use those unsafe functions, and sandboxed code can modify them
        - To evade that problem, this function creates a new function that temporarily sets the string metatable's `__index` to the regular `string` table for itself, then sets it back to the sandboxed `string` table

# tl
- `output_code, syntax_errors = slua.default_compile(code)` - `slua.compile` but with default options
    - **This is the only tl-related function you need to know about, all of the 16 000+ lines in the tl compiler were added just for this**
    - `code` - tl code (any valid lua code should be valid tl code)
    - `output_code` - lua code, may be nil if there are syntax errors
        - *Does not have to be syntactically valid, you should check if `loadstring()` complains*
    - `syntax_errors` is an array of
        ```lua
            syntax_error = {
                filename = "something.lua",
                msg = "syntax error", -- tl can often give you some of these really generic "syntax errors", but the location helps
                x = 1,
                y = 1, -- On the flip side, you get the exact position of where it happened
            }

            syntax_errors = {xsyntax_error, syntax_error, ...}
        ```
    - Default generate options are:
        ```lua
        -- You can read up what these do in documentation for `slua.tl_api.generate`
        {
            preserve_ident = true,
            preserve_newlines = true,
            preserve_hashbang = false,
            sandbox_options = {
                banned_identifiers = { ["__slua"] = true },
                concat_function_name = "__slua.concat",
                before_loop_end = "__slua.limit_function()",
            }
        }
        ```
- `output_code, syntax_errors = slua.compile(code, options)` - A higher level function, abstracting the mess below
    - `code` -  tl code (any valid lua code should be valid tl code)
    - `options` - See documentation for `slua.tl_api.generate`
    - `output_code` - lua code, may be nil if there are syntax errors
        - *Does not have to be syntactically valid, you should check if `loadstring()` complains*
    - `syntax_errors` - See documentation for `slua.tl_api.parse`
- `slua.tl_api` - the `teal.api.v2` module, the only one that is important, not all functions are documented here
- `ast, syntax_errors = slua.tl_api.parse(code, name)` - Parses `code` and gives you the `ast`, or `syntax_errors` if the code has them.
    - `code` - tl code (any valid lua code should be valid tl code)
    - `name` - If you want to parse lua code, the name is supposed to end with `.lua`, but this does not matter that much
    - `ast` - may be nil if there are syntax errors
    - `syntax_errors` is an array of
        ```lua
            syntax_error = {
                filename = "something.lua",
                msg = "syntax error", -- tl can often give you some of these really generic syntax errors
                x = 1,
                y = 1, -- On the flip side, you get the exact position of where it happened
            }

            syntax_errors = {syntax_error, syntax_error, ...}
        ```
- `code = slua.tl_api.generate(ast, "5.1", options)` - Generates code from the AST you got from `slua.tl_api.parse`
    - `options` is a table like
    ```lua
    {
        preserve_ident = true,
        preserve_newlines = true,
        preserve_hashbang = false, -- For those that don't know, this is a thing at the top of the file that tells linux how to run your script, see https://en.wikipedia.org/wiki/Shebang_%28Unix%29 but the TL;DR is that you should set this to false
        sandbox_options = { -- This is something that was added by slua, *it can be nil*
            -- For tables that you don't want the user to be able to shadow (like if you don't want `local __my_internal_table` to be a thing
            -- This will replace that identifier with `_not_allowed`
            -- The standard for an internal table in slua-type sandboxes is `__slua`
            banned_identifiers = { ["__slua"] = true },

            -- This option will replace concatination (so like `x .. y`, but can be VASTLY more complicated)
            -- with your own function, so that for example `x .. y` may become `__slua.concat(x, y)`
            concat_function_name = "__slua.concat",

            --[[
            An **expression** to put at "loop points", not a function
            Loop points are really anywhere, where something can loop infinitely, like while loops

            == EXAMPLE:==
            while true do
            end
            == Turns into:==
            while true do
            __slua.limit_function() end

            ==With the __slua.limit_function() actually just being this before_loop_end expression==

            == There is one case where it isn't before loop end though: FUNCTIONS ==
            function x()
                if y then
                    x()
                elseif z then
                    return false
                end
            end
            ==Turns into==
            function x()
                __slua.limit_function() if y then
                    x()
                elseif z then
                    return false
                end
            end
            --]]
            before_loop_end = "__slua.limit_function()",

        }
    }
    ```
- `slua.tl = { [module_name] = module }` - all modules of tl are in this table, you can use it like `lua_generator = slua.tl["teal.gen.lua_generator"]`, these modules are not documented.
    - A module of interest may be `teal.gen.lua_compat`, if someone ports the functionality of this to slua's higher level functions (so stuff like `x // y` for integer division wouldn't syntax error) it would be welcome

