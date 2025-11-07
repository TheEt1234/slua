--- Makes a function safer to use in an slua environment by calling the limit function and checking the size of string arguments.
---@param f function
---@param config slua.env_config
---@return function
function slua.make_safer(f, config)
	return function(...)
		local args = { ... }
		local len = 0
		for _, arg in pairs(args) do
			if type(arg) == "string" then
				len = len + #arg
			end
		end

		if len > config.max_string_len then
			error(
				string.format(
					"The result of this function will violate the string limit. (The limit is %s characters)",
					config.max_string_len
				)
			)
		end

		config.limit_function()
		local ret = { f(...) }
		config.limit_function()
		return unpack(ret)
	end
end

---@return number miliseconds
local get_time = function()
	return core.get_us_time() / 1000
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
