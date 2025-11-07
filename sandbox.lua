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

	local f, err = loadstring(generated_code, options.chunkname)

	if not f then
		return nil, "Possible tl compiler bug: " .. err
	end

	f = setfenv(f, options.env)

	local co = coroutine.create(f)
	return co
end
