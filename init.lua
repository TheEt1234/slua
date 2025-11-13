---@class slua.sandbox_options : { banned_identifiers: table<string, boolean>, concat_function_name: string, before_loop_end: string }

--- must match `record Options` in tl/teal/gen/lua_generator.tl
---@class slua.compile_options
---@field preserve_indent boolean
---@field preserve_newlines boolean
---@field preserve_hasbang boolean
---@field sandbox_options? slua.sandbox_options

--- must match `record Error` in tl/teal/errors.tl
---@class slua.syntax_error
---@field x integer
---@field y integer
---@field msg string
---@field tag? "unknown"| "unused"| "redeclaration"| "branch"| "hint"| "debug"| "unread" the type's name internally is "WarningKind"

---@diagnostic disable-next-line: lowercase-global
---@class slua
slua = {}

local mp = core.get_modpath "slua"

dofile(mp .. "/import_tl.lua")
dofile(mp .. "/misc.lua")
dofile(mp .. "/sandbox.lua")
dofile(mp .. "/env.lua")
