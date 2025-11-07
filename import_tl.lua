-- Import the teal compiler

-- The teal compiler is found in a single, gigantic tl.lua file, in the format of
-- package.preload[%q] = function(...) %s end
--
-- The code will also contain `require` functions which is annoying

local tl = {}
local ran_modules = {} ---@type { [string]: boolean }

local function get_or_load_module(modname)
	if ran_modules[modname] then
		return tl[modname]
	else
		ran_modules[modname] = true
		tl[modname] = tl[modname]()
		return tl[modname]
	end
end

local old_package, old_require = package, require

package = {}
package.preload = tl

function require(modname)
	return get_or_load_module(modname)
end

slua.tl_api = loadfile(core.get_modpath "slua" .. "/tl/tl.lua")()

package = old_package
require = old_require

slua.tl = tl

--- NOW: Some useful functions, basically we imported all of tl just to get this

--- As much of tl needs to be turned off as possible
--- So that:
---  1) We don't get bombarded with useless type information making it hard to debug
---  2) It's faster that way
--- So that is why i am not using tl.gen(), and instead tl.parse() with tl.generate(), because tl.gen uses the type checker(i think) to get the ast
---@param code string Any untrusted code, is teal code
---@param opts slua.compile_options
---@return string? generated_code, slua.syntax_error[]? errs
slua.compile = function(code, opts)
	local ast, errs = slua.tl_api.parse(code, "<input>.lua")
	if #errs > 0 then
		return nil, errs
	end
	return slua.tl_api.generate(ast, "5.1", opts)
end

---@see slua.compile
--- Similar to slua.compile but with default options instead
---@param code string
---@return string? generated_code, slua.syntax_error[]? errs
slua.default_compile = function(code)
	local ast, errs = slua.tl_api.parse(code, "<input>.lua")
	if #errs > 0 then
		return nil, errs
	end
	return slua.tl_api.generate(ast, "5.1", {
		preserve_ident = true,
		preserve_newlines = true,
		preserve_hashbang = false,
		sandbox_options = {
			banned_identifiers = { ["__slua"] = true },
			concat_function_name = "__slua.concat",
			before_loop_end = "__slua.limit_function",
		},
	})
end
