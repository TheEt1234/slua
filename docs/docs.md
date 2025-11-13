# Slua
- `slua = {}`

# Environment
**Unlike other sandboxes, in slua, you have to make sure any function you add to the environment can't cause an infinite loop.**

### Philosophy
An slua sandbox may also unintentionally be a learning tool for someone, keep that in mind when you are designing the environment for your own sandbox.  
It may be worth to provide a more basic environment so that a player has an opportunity to learn how to re-create some functions, or maybe you want to encourage creativity by giving them a lot of functions, your choice.  
Just don't include something like `core.is_nan`, because that would be extremely trivial for a player to write, and the knowledge from doing it without using that function would be more a lot valuable than knowing about `core.is_nan` because the `x ~= x` check applies to all programming languages, not just luaJIT running inside luanti.

I personally learned lua with mesecons luacontrollers in multiplayer, that then got me to luanti, and that's why i am here. So you should think about people learning in a lua sandbox too. There isn't a wrong way to design an environment, just please don't include functions like `core.is_nan`.

Also keep in mind that lua is *really* bad with strings (luanti mod security forces it this way, we don't have access to string buffers or ffi character arrays), so don't try to force players to use/communicate with them for "realism", it will end badly.


# TL-related
- `slua.tl` - All teal compiler modules
    - Think of `module = slua.tl[module_name]` as `module = require(module_name)`
    - Not interesting for sandboxing, if you want, you can see for yourself with `dump(slua.tl)`
    - Side note: `tl` is the name for the teal compiler, i don't know why they picked that name
- `slua.tl_api` - is `slua.tl["teal.api.v2"]`
    - Again, not all that relevant, but it is the most relevant tl module
    - From `v2.tl`:
    ```tl
       check_file: function(filename: string, env?: Env, fd?: FILE): (Result, string)
       check: function(Node, ? string, ? CheckOptions, ? Env): Result, string
       check_string: function(teal_code: string, env?: Env, filename?: string, parse_lang?: ParseLang): Result
       generate: function(ast: Node, gen_target: GenTarget, opts?: GenerateOptions): string, string
       gen: function(string, ? Env, ? GenerateOptions): string, Result
       get_token_at: function(tks: {Token}, y: integer, x: integer): string
       lex: function(teal_code: string, filename: string): {Token}, {Error}
       loader: function()
       load: function(string, ? string, ? LoadMode, ...: {any:any}): LoadFunction, string
       new_env: function(? EnvOptions): Env, string
       parse: function(teal_code: string, filename: string, parse_lang?: ParseLang): Node, {Error}, {string}
       parse_program: function(tokens: {Token}, errs: {Error}, filename?: string, parse_lang?: ParseLang): Node, {string}
       process: function(filename: string, env?: Env, fd?: FILE): (Result, string)
       search_module: function(module_name: string, search_all: boolean): string, FILE, {string}
       symbols_in_scope: function(tr: TypeReport, y: integer, x: integer, filename: string): {string:integer}
       target_from_lua_version: function(str: string): GenTarget
       version: function(): string
    ```
    - The only thing relevant here is `gen`, you can use `check_string` if you want type checking but that is a very strange use
- `ast, errors, required_modules = slua.tl_api.parse(code, "<input>.lua")`
    - Gets you the AST
    - The second argument is the file name, it should end with `.lua` or tl will assume it's teal code (*Even if it will always parse it like it is teal code, it doesn't matter that much, **all code you are sandboxing with slua is technically teal code***)
        - So yes, that also means this project should be maybe called `steal` for "sandboxed teal", but that's not a good name
        - ... even if i borrowed that entire compiler xD
- `the_code = slua.tl_api.generate(ast, "5.1", options)`
    - not to be confused with `slua.tl_api.gen` - that can work too but it is a *lot* more bloated and will make a lot more more information you usually don't want (because it also performs type checking)
    - you get the ast from `slua.tl_api.parse`
    - The second argument of this function is not all that relevant, i have no idea what it does
    - `options` - okay the exciting stuff
        - `options.preserve_indent` - ehh... set it to `true`
        - `options.preserve_newlines` - if you don't set this one to `true`, people will hate you, and this is literally *the entire reason i picked teal*
        - `options.preserve_hashbang` - preserve a syntax error? you want this to be `false`
        - `options.sandbox_options` - Okay, the fun stuff, the things i actually added to tl (optional table, dont use if you just want to use teal compiler for teal stuff (why))
            - `options.sandbox_options.banned_identifiers` - a table of `{[any_string]=true}`, it won't actually disallow those locals but replace them with `_not_allowed`, use for things that you don't want to be changed, and make the variable name obscure (like `__internal`)
                - This does not work for globals
                - It's a bit of a hack to make the bottom 2 options work, yes, but there just needs to be some way to have something you just cannot change in the environment for all of slua to work
            - `options.sandbox_options.concat_function_name` - Replaces concatination (`x .. y`) with a custom function
                - example: `options.sandbox_options.concat_function_name = "__internal.c"`, that will replace `x..y` with `__internal.c(x, y)`
            - `options.sandbox_options.before_loop_end` - Adds the code in that option before everything that can loop
                - example: `options.sandbox_options.before_loop_end = "__internal.check_time_limit()`, would replace `while true do end` with `while true __internal.check_time_limit() end`
                - this works on functions too, basically anything that can loop

