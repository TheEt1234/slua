---@class slua.sandbox_options
---@field env table
---@field code string
---@field chunkname string?

---@param options slua.sandbox_options
---@return thread?, (slua.syntax_error[]|string)?
function slua.create_sandbox(options)
	local generated_code, syntax_errors = slua.default_compile(options.code)
	if not generated_code then
		return nil, syntax_errors
	end

	local f, err = loadstring(generated_code, options.chunkname or "=(load)")

	if not f then
		return nil, "Possible tl compiler bug: " .. err
	end

	f = setfenv(f, options.env)

	local co = coroutine.create(f)
	return co
end

--- begins string metatable sandboxing and just does coroutine.resume(co)
---@param co thread
---@param env table
---@return boolean ok, ...
function slua.run_sandbox(co, env)
	local string_mt = getmetatable "string"

	string_mt.__index = (env.string or {})
	local results = { coroutine.resume(co) }
	string_mt.__index = string

	return unpack(results)
end
