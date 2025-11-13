# Slua guide

Any code you sandbox through slua needs to go through:
- lexing, parsing (handled by `tl`)
- code generation (handled by `tl`, this part was modified in slua)
- loadstring
- setfenv (you have to be extra careful on what you put into the environment)
- string metatable sandboxing when running

Most of that is handled with `slua.create_sandbox` with very few lines of code that glues those parts.  
The only things you need to worry about are limits and the environment.

## How to make an environment
```lua
local env = {}
local env_config = {
    max_string_len = 64000, -- Should be good enough (mesecons has this set as the limit for string.rep)

    -- 8 miliseconds, you can do more, you can do less
    -- It will also send the message "timeout", you can change that as well to anything
    --
    -- you can also make your own limiting function if you wanted to
    -- This function will get executed at the end of loops, or at the start/end of functions, example:
    -- while true do <whatever was in the loop> your_limiting_function() end, you can do whatever you want in there
    --
    -- note: This function won't be called a single time if the code looks something like "f(); f(); f(); f(); f(); f(); f(); f(); f(); f()", if `f` doesn't call the limiting function (this will be relevant, not here though)
    limit_function = slua.get_default_limit_function(8, "timeout"),

    -- The maximum length of code that you can put into `loadstring()`, 8k should be good enough, you don't want it to feel limiting if you are aiming for players to make something extremely unnesecarily complex (say in a computers mod)
    max_loadstring_code_length = 8000,
}

slua.env.init_environment(env, env_config) -- Adds the immutable __slua table

slua.env.basic_env(env, env_config) -- If you want the bare minimum
slua.env.add_luanti_utils(env, env_config) -- If you want luanti exclusive stuff like string.split/string.trim/vector library/etc.
```

## How to add a custom function to the environment
```lua
--- NOTE: When i am referring to "spamming" a function, i mean doing something like
--- f(); f(); f(); f(); f()..., without a loop
--- If `f` doesn't call the limiting function, this can be a problem


--- EXAMPLE 1: core.set_node

--- Assumbtions:
---     - we know very little about core.set_node
---     - we are too lazy to look it up in builtin
---     - we intuitively know it can't take a significant amount of time
---     - we know it doesn't take functions as an argument
---
--- What we don't know:
---     - If this function will take a lot of time when spammed
---     - If it uses ("string"):whatever() syntax
--- 
--- What we can do 
---    - call the limiting function at the end, so that if it is spammed, it will call the limiting function properly (and also call it at the start because why not)
---    - Escape the string sandbox, so that functions that use ("string"):whatever() syntax won't be messed up
--- 
--- Turns out, slua.make_safer does both of those things (and also check the length of all string arguments), so we can use that

env.core.set_node = slua.make_safer(core.set_node, env_config)





--- EXAMPLE 2: table.foreach

--- What we know:
---     - This function takes another function as an argument, and calls it
---     - It doesn't use ("string"):whatever() syntax
---     - It's deprecated and deeply unperformant in luaJIT... of course we know that xD

--- What we don't know 
---    - How much time this function could take
---
--- What we can assume:
---    - If a function provided to table.foreach doesn't call the limit_function, it won't take much time
---
---  So.. we can't use slua.make_safer in this case, because it escapes the string sandbox
---      - Escaping the string sandbox would mean, that the sandbox would have access to unsafe functions through (""):whatever syntax
--- 
--- We can just call the limit_function before and after the table.foreach call

env.table.foreach = function(...)
    env_config.limit_function()
    table.foreach(...)
    env_config.limit_function()
end
```

## Sandboxing
```lua
--- Create
local co, syntax_errors = slua.create_sandbox({
    env = env,
    code = code, -- Any user-submitted code, you should check for its length
})

if syntax_errors then
    -- You handle them somehow, they can be both a string or a table which can make things tricky
end

--- Run
local ok, results = slua.run_sandbox(co, env)

```
