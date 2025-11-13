# slua - short for "Sandboxed Lua"

A library to transpile input lua code into trivially sandboxable lua code, that doesn't need debug hooks for time limiting and replaces `x .. y` with `some_func(x, y)`

## The problems with usual lua sandboxing
- String concatination **cannot be reliably limited**
    - **This leads to bugs that can freeze a server**
    - or it being limited with unreliable methods
- In coroutine sandboxes, sometimes i want to automatically yield instead of throwing an error
    - Only lua C api can do this, not ideal in luanti
- debug hooks are kinda awkward
    - Your code now becomes incompatible with tools like luacov
    - You have to disable JIT to use the most useful type of debug hook for sandboxing

# What slua does to solve all of those

It modifies the inputted lua code. I don't think there is a better solution to this problem than doing that.

Slua will:
- Replace concat expressions like `x..y` with `__slua.concat(x, y)`
- Add a function before loop points
    ```lua
    while true do
        
    end
    ```
    Would turn into
    ```lua
    while true do

    __slua.limiting_function() end
    ```
- Not allow you to declare certain locals
    ```lua
        local __slua = {} -- This table is also immutable when made as a global, so _G["__slu".."a"] = {} would throw an error at runtime
        local function f(__slua) end
    ```
    Would turn into
    ```lua
        local _not_allowed = {} -- It cannot make a syntax error in the code generation stage, so it just does this instead
        local function f(_not_allowed) end
    ```

Slua achieves this by using and modifying the `tl` (compiler for the `teal` language). When you are writing code to be sandboxed to slua, you are technically writing [teal code](https://teal-language.org), but all valid lua code is also valid teal code, so you don't have to concern yourself with this.

~~Slua could've been called `Steal` but that is a worse name~~
