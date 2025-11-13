--- Makes a function safer to use in an slua environment by calling the limit function and checking the size of string arguments.
---
--- It will also escape the string sandbox for that function, *don't use if the function requires another function as input, for safety reasons it will make an error if you try doing that*
---   - You can turn off this behavior by setting the `ignore_functions_in_arguments` to true
---@see slua.escape_string_sandbox
---@param f function
---@param config slua.env_config
---@param ignore_functions_in_arguments boolean? If set to true, won't make an error when any functions are put into the arguments of the resulting function
---@return function
function slua.make_safer(f, config, ignore_functions_in_arguments)
	return function(...)
		local args = { ... }
		local len = 0
		for _, arg in pairs(args) do
			if type(arg) == "string" then
				len = len + #arg
			elseif type(arg) == "function" and not ignore_functions_in_arguments then
				error "Functions cannot be put as arguments to this function."
			end
		end

		if len > config.max_string_len then
			error(
				string.format(
					"The result of this function might violate the string limit, because the string arguments given to it are too long. (The limit is %s characters)",
					config.max_string_len
				)
			)
		end

		local string_mt = getmetatable ""
		local sandboxed_stringlib = string_mt.__index

		config.limit_function()
		string_mt.__index = string

		local ret = { f(...) }

		string_mt.__index = sandboxed_stringlib
		config.limit_function()

		return unpack(ret)
	end
end

--- Not using core.get_us_time, because non-luanti does not have that
---@return number miliseconds
local get_time = function()
	return os.clock() * 1000
end

---@param time number miliseconds
---@param message any The message sent to coroutine.yield
---@return function
function slua.get_default_limit_function(time, message)
	local t0
	return function()
		if not t0 then
			t0 = get_time()
		end

		if get_time() - t0 > time then
			coroutine.yield(message)
			t0 = get_time()
		end
	end
end

--- Makes it so that for function `f`, running `("some string"):some_function()` will make `some_function` point to the one in the global environment, not in the sandboxed environment
--- So that in the sandbox, you can't do `function string.some_function` to potentially, intentionally, create vurnabilities
---
--- Hovewer, it is not worth doing this for every simple function
---@param f function
---@return function
function slua.escape_string_sandbox(f)
	return function(...)
		local string_mt = getmetatable ""
		local sandboxed_stringlib = string_mt.__index
		string_mt.__index = string
		local rets = { f(...) }
		string_mt.__index = sandboxed_stringlib

		return unpack(rets)
	end
end
