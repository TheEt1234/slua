# Comparing slua to other projects

### slua
- Was made because libox's execution time limiting was either flawed (by instructions) or very unstable (by time), and this is what i saw as the perfect solution
- Changes inputted source code to be easier to sandbox by transpiling it with a modified version of `tl` compiler
    - So this means regular lexing, parsing, code generating is being done
    - The code generating part has been modified
- Default environment includes many functions
- I hope it will geniuenly be the perfect solution

### libox
- Was partially made because i was frustrated at mesecons luacontroller's limitations
- This was me trying to extend what was possible with mesecons luacontrollers, and me discovering that you can use coroutines to do sandboxing, and putting all that into a convenient library
- I also encouraged limiting the sandbox based on time, not instructions
    - I would later learn that this was a terrible idea, as it would make limiting extremely inconsistent
- Default environment includes many functions
- Corpserot also added autohook to it (Making coroutine sandboxes automatically yield when they run too long, instead of removing them)
    - This was achieved through the Lua C api, *with some overly complex build scripts*, so it isn't really practical

### mesecons luacontrollers
- I love them, they are what got me into luanti modding
    - Their purpose to me was to allow me to be a lot more creative in a multiplayer server, and show off the cool things i made
    - And they also allowed me to learn a lot, i didn't want to *intentionally* learn, but i did
        - Luacontrollers are amazing as a learning tool, even if people may not talk about it that way
- They are limited by instructions (very flawed!)
- The environment lacks in some useful functions, namely `pcall`, `xpcall` (there is a PR for these) and `loadstring`
- They aren't ran in a coroutine, which makes some things very annoying
    - Suppose you want to do something computationally complex, like generate a detailed mandelbrot set
        - You would have to awkwardly break up the for loop (you need to iterate over each pixel), nobody wants to do that
    - Or if you want to get information from a digilines device and act on it
        ```lua
            -- with coroutines this could be something like:
            info = coroutine.yield({type = "digiline_send", channel = "info", message = "GET"})
            -- then you could act on it 


            ------------------------------------------------

            -- Without coroutines it would be like
            if "whatever that caused you to need the info" then
                digiline_send("info", "GET")
            end

            if event.type == "digiline" and event.channel == "info" then
                info = event.msg
                -- AFTER THAT you can act on it, kind of inconvenient isn't it?
                -- and this could get VERY messy if you have multiple places that can send the info request to do different things with it, you have to track so much... horrible!
            end
        ```
- Not perfect at what they do, but not bad either

### saferlua (not to be confused with slua)
- A strange sandboxing library present within the techage modpack
- In techage, i recommend:
    - i don't think you should interact techage luacontrollers
    - Instead use mods that depend on https://github.com/joe7575/vm16 - a mod adding virtual machines to luanti by the same author, it is really cool.
        - Example: use [beduino](https://github.com/joe7575/beduino) instead of techage luacontrollers, you get to experience actual low level coding... instead of wishing you had while loops
    - Or maybe use signs bot (by the same author), those are really cool
- [I don't think you should use this library for anything, this code can tell you why](https://github.com/joe7575/techage_modpack/blob/master/safer_lua/scanner.lua#L88)
- It bans while loops, `x:y()` syntax, tables, table indexing with brackets, `_G` (strangely)
    - The only way to make loops, to my knowledge, is with functions (or `goto`, that might be a bug... whoops :P)
    - When you have to resort to banning while loops and tables, i think you are doing something wrong
    - Alternative interpretation is that: It offers an esoteric experience that is optimal for learning functional programing and recursion... yes
- It has custom datastructures instead of tables, i think they are extremely inferiour to tables and have little reason to exist
- Uses coroutines for sandboxing
- Uses debug hooks for time limiting, has a time limit that gets executed every function call
- [Has a very basic environment (notably missing a lot of math functions)](https://github.com/joe7575/techage_modpack/blob/master/safer_lua/environ.lua#L58)
