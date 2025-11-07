# slua - Sandboxed Lua

A library to transpile lua code        into lua code (that it doesn't need debug hooks for sandboxing and runs `coroutine.yield` every `x` !TODO!WHAT WILL IT BE BASED ON?).

## The problems with lua sandboxing
- concatination can be a pain, as you can concatinate extremely large strings without any sandbox being able to fully stop you, except super unreliable ones (meaning the same program can execute with the exact same inputs twice, but one can time out and one doesn't have to) which use time instead of the amount of instructions
- i want to automatically pause it when it reaches like 100 instructions, not `error` it out of existence
- debug hooks are kinda awkward

# The solution
- Transpile lua code into perfectly safe lua code of course

## Why this
- fun
- it solves a super niche problem
- sandboxed code that can be JITed

# Problems
- `coroutine.yield` is a stich (I dunno what that means but i think that means generated code filled with `coroutine.yield` won't be ***BLAZINGLY FAST*** but okay-ish, and the luaJIT wiki for some reason is archived in this random place) - https://github.com/tarantool/tarantool/wiki/LuaJIT-Not-Yet-Implemented#coroutine-library
- this is a project where i (frog) learned about parsing, so it's going to be a slight mess
- it was made with LuaJIT in mind, the tokenizer is ***literally 10 times slower*** when ran on lua5.1

# Ok, what issues can it solve and how

- concatination being laggy with gigantic strings
    - replacing `x .. y` with `c(x,y)`, where `c` will concatinate `x` and `y` but with a character limit
- debug hooks being kinda awkward (most lua sandboxes erase the hook that was set before, meaning things like finding out lua code coverage will work weirdly)
    - Debug hooks that execute every `some_amount` of instructions require jit compilation to be disabled, causing the code to be slower
    - instead of debug hooks, i can just make the generated code call `coroutine.yield`

