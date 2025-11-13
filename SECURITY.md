# Reporting vurnabilities

- If it's a sandbox escape, try privately disclosing that somehow
    - I don't expect this bug to happen
- If it can crash/freeze a server, make a github issue
    - Unless luanti has gotten to the point where people will abuse these issues



# How severe can lua sandboxing bugs get?

## Usually not that severe, making a server completely unusable at most
- https://github.com/minetest-mods/mesecons/issues/711 
- https://github.com/minetest-mods/mesecons/issues/516
- https://github.com/minetest-mods/mesecons/issues/415
- https://github.com/loosewheel/lwcomputers (As cool as this mod is, it is beyond saving and should not be anywhere near multiplayer)
    - fun excercise: try to find a bug that will let you freeze a server in that project

(Yes, all of those are different links)

These issues would be really bad, but luckily are really obscure... is it bad that i am bringing attention to them? i hope not.

All lua sandboxing solutions suffer from at least one of those issues. (Except libox if you use it correctly, and if you do, the experience for the user(user=human whose code is being sandboxed) would be miserable. That is the reason i am making this project.)

## In rare cases: sandbox escape
- https://github.com/loosewheel/lwcomputers/blame/7c1d49b0551873a0e9f5bccd3b3c83bd86514837/computer_env.lua#L27 - For example this allows a trivial sandbox escape
    - I am cherry-picking an extremely old commit, this has luckily been fixed
- this type of bug is rare, you allow the user to mess function environments or somehow completely miss `setfenv` to cause it
- but also extremely destructive, in multiplayer, assume that if this bug is present, any player can permanently destroy your world, and access everything in that world (and all unencrypted data)

# What can cause bugs/vurnabilities
- (assume not) hardware: cpu vurnabilities? (could they even be abused there?)
- (assume not) lua5.1/luajit: There could be a flaw in those interpreters that would make sandboxing even more painful (like `setfenv` not actually working)
- tl: There could be a bug that could hang the tl compiler during parsing/code generation, this would be painful
- slua/slua's changes to tl: This is probably the most likely one

