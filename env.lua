---@class slua.env
slua.env = {}

---@class slua.env_config
---@field max_string_len integer
---@field limit_function fun():nil
---@field max_loadstring_code_length integer

local function immutable(table)
	return setmetatable({}, {
		__index = table,
		__newindex = function()
			error "This table is read only!"
		end,
		__metatable = false,
	})
end

--- Makes an immutable table
--- Name it in the environment "__slua"
---@param env_config slua.env_config
local function make_slua_table(env_config)
	return immutable {
		-- Don't put any information that may be useful to the user, because "__slua" is a forbidden identifier
		-- the "__slua" name is also standardized, because it doesn't matter what the name is as long as the user can't accidentally stumble onto it
		concat = function(str1, str2)
			assert(
				(#str1 + #str2) <= env_config.max_string_len,

				string.format(
					"Concat operation violates string limit. (The limit is %s characters)",
					env_config.max_string_len
				)
			)
			return str1 .. str2
		end,
		limit_function = env_config.limit_function,
	}
end

---@param env_config slua.env_config
---@param env table?
---@return table
function slua.env.init_environment(env, env_config)
	env = env or {}
	setmetatable(env, {
		__index = {
			__slua = make_slua_table(env_config),
		},
		__newindex = function(t, k, v)
			if k == "__slua" then
				error("Field " .. k .. " is read only!")
			end
			rawset(t, k, v)
		end,
	})

	return env
end

--- describes itself, not done for everything
local function wrap_with_limiting_function(f, limit_f)
	return function(...)
		limit_f()
		local retvals = { f(...) }
		limit_f()
		return unpack(retvals)
	end
end

---- ---- ----

local function safe_find(s, pattern, init, plain)
	if plain == false then
		error "string.find call must be plain due to sandboxing resource restrictions."
	end
	return string.find(s, pattern, init, true)
end

local function string_limit_error(max_len)
	error(
		string.format(
			"The result of this function will violate the string limit. (The limit is %s characters)",
			max_len
		)
	)
end

local function safe_format(max_string_len)
	return function(s, ...)
		local args = { ... }
		local total_size = 0
		for _, arg in ipairs(args) do
			if type(arg) == "string" then
				total_size = total_size + #arg
			end
		end
		if total_size > max_string_len then
			string_limit_error(max_string_len)
		end
		return string.format(s, ...)
	end
end

local function safe_rep(max_string_len)
	return function(s, n)
		local size = #s * n
		if size > max_string_len then
			string_limit_error(max_string_len)
		end
		return string.rep(s, n)
	end
end

local function safe_table_concat(max_string_len)
	return function(t, sep, i, j)
		i = i or 1
		j = j or #t
		if i > j then
			return ""
		end

		local len = 0

		for _, str in ipairs(t) do -- i know i am not being exact but that doesn't really matter that much does it?
			if type(str) == "string" then
				len = len + #str
			end
		end

		if len > max_string_len then
			string_limit_error(max_string_len)
		end
		return table.concat(t, sep, i, j)
	end
end

-- slua.escape_string_sandbox is needed here, because it's calling to `slua.default_compiler`, which is TL code, which is basically a black box, and almost definitely makes calls in the style of ("Myepic%sstring!"):format("Whatever")
local function safe_loadstring(config, env)
	-- slua.make_safer is okay here because it doesn't call any user-provided functions, it just creates the function
	return slua.make_safer(function(code, name)
		assert(type(code) == "string", "Code must be a string")
		if #code > config.max_loadstring_code_length then
			error(string.format("Code is too long, the limit: %s characters", config.max_loadstring_code_length))
		end

		name = name or "(load)"
		name = "=" .. name

		--- This limit is so large as to not put a limit when you are trying to make a filesystem of some kind
		if (#name - 1) > 500 then
			error "Chunkname is too long (What are you even trying to do?)"
		end

		local generated_code, error_messages = slua.default_compile(code)
		if #generated_code > config.max_loadstring_code_length then
			error(string.format("Code is too long, the limit: %s characters", config.max_loadstring_code_length))
		end
		if not generated_code then
			return nil, error_messages
		end

		local f, errmsg = loadstring(generated_code, name)
		if not f then
			return nil, "TL may have generated incorrect code, please report this as a bug to slua: " .. errmsg -- should not ever happen
		end
		f = setfenv(f, env) -- sandbox
		f = wrap_with_limiting_function(f, config.limit_function)

		-- good to go
		return f
	end, config)
end

---@param config slua.env_config
local function safe_getinfo(config)
	return function(f, what)
		-- so umm... obviously: It shouldn't be able to get the function
		-- the rest is fair game
		local info = debug.getinfo(f, what)
		info.func = nil
		return info
	end
end

local function make_math_env()
	return {
		"abs",
		"acos",
		"asin",
		"atan",
		"atan2",
		"ceil",
		"cos",
		"cosh",
		"deg",
		"exp",
		"floor",
		"fmod",
		"frexp",
		"huge",
		"ldexp",
		"log",
		"log10",
		"max",
		"min",
		"modf",
		"pi",
		"pow",
		"rad",
		"random",
		"randomseed",
		"sin",
		"sinh",
		"sqrt",
		"tan",
		"tanh",
	}
end

--- The most basic acceptable environment
--- Without any luanti additions
--- - Base lib
---      - Without things that rely on files, change global state, or output to stdout
---      - Also no coroutines (I WILL DO THEM ONLY if there is demand)
---      - AND without getfenv/setfenv because i am scared of those functions+you don't need them i hope
---      - ... and without metatables (i will do if there is demand)
--- - String library
---		- No pattern matching
--- - Table library
--- - Math library
---		- No functions that change global state (math.randomseed)
---	- OS library
---		- Nothing that can mess with the operating system of course
--- - Small amount of debug
--- - BIT library
---@param env table?
---@param config slua.env_config
---@return table
function slua.env.basic_env(env, config)
	env = env or {}
	for k, v in pairs {
		assert = assert,
		error = error,
		_G = env,
		ipairs = ipairs,
		next = next,
		pairs = pairs,

		loadstring = wrap_with_limiting_function(safe_loadstring(config, env), config.limit_function),
		-- load is useless

		pcall = pcall, -- In a sandbox regulated by errors, this wouldn't be acceptable. But no worries, slua sandboxes are supposed to be in a coroutine, where you can yield to get out of it, so pcall like this is perfectly safe
		xpcall = wrap_with_limiting_function(xpcall),

		-- rawset cannot be included, unless it ignores the __slua table i think?
		-- if there is demand for metatables, they will be introduced

		select = select,
		tonumber = tonumber,
		tostring = tostring,
		type = type,
		unpack = unpack,
		-- _VERSION is useless

		-- WARN: String metatable needs to be sandboxed to this!
		-- WARN: You must do getmetatable("").__index = env.string, then get out of it once you are done
		string = {
			byte = string.byte,
			char = string.char,
			-- dump is not needed
			find = wrap_with_limiting_function(safe_find, config.limit_function),
			format = wrap_with_limiting_function(safe_format(config.max_string_len), config.limit_function),
			-- pattern-matching functions can hang the server, won't be included in the basic env
			len = string.len,
			lower = string.lower,
			rep = wrap_with_limiting_function(safe_rep(config.max_string_len), config.limit_function),
			reverse = string.reverse,
			sub = string.sub,
			upper = string.upper,
		},
		table = {
			concat = wrap_with_limiting_function(safe_table_concat(config.max_string_len), config.limit_function),
			insert = table.insert,
			maxn = table.maxn,
			remove = table.remove,
			sort = wrap_with_limiting_function(table.sort, config.limit_function),
		},
		math = make_math_env(),
		os = {
			clock = os.clock,
			-- apparently os.date can cause a segfault? unless you mitigate it somehow, okay
			difftime = os.difftime,
			time = os.time,
		},
		debug = {
			getinfo = wrap_with_limiting_function(safe_getinfo(config), config.limit_function),
			traceback = wrap_with_limiting_function(debug.traceback, config.limit_function), -- can create lag if the code got itself into a mess, shouldn't be too much lag though
		},
		bit = table.copy(bit),
	} do
		env[k] = v
	end
	return env
end

local function safe_split(str, seperator, include_empty, max_splits, sep_is_pattern)
	if sep_is_pattern == true then
		error "In string.split, the last argument (sep_is_pattern) must be false or nil due to sandboxing resource restrictions."
	end
	return string.split(str, seperator, include_empty, max_splits, false)
end

--- Luanti namespace is in `core = {}`
---
--- Adds
---		- Safe "Helper functions" in lua_api.md
---		- Formspec related functions
---		- Everything from vector lib
---@param env table?
---@param config slua.env_config
---@return table
function slua.env.add_luanti_utils(env, config)
	local wwlf = wrap_with_limiting_function
	local limit_f = config.limit_function

	-- Q:Why slua.make_safer and wwlf are used inconsistently:
	-- A: Because slua.make_safer is slightly slower, so it's used when needed
	-- And also slua.make_safer was made later and i'm too lazy to change it

	env = env or {}
	for k, v in pairs {
		dump = wwlf(dump, limit_f),
		dump2 = wwlf(dump2, limit_f),
		math = {
			hypot = math.hypot,
			sign = math.sign,
			factorial = wwlf(math.factorial, lmit_f),
			round = math.round,
		},

		string = {
			split = wwlf(safe_split, limit_f),
			trim = wwlf(string.trim, limit_f),
		},

		core = {
			wrap_text = slua.make_safer(core.wrap_text, config),
			pos_to_string = wwlf(core.pos_to_string, limit_f),
			string_to_pos = wwlf(core.string_to_pos, limit_f),
			is_yes = core.is_yes,

			-- formspec related, lua sandboxing stuffs may work with formspecs
			formspec_escape = slua.make_safer(core.formspec_escape, config),
			hypertext_escape = slua.make_safer(core.hypertext_escape, config),
			explode_textlist_event = slua.make_safer(core.explode_textlist_event, config),
			explode_table_event = slua.make_safer(core.explode_table_event, config),
			explode_scrollbar_event = slua.make_safer(core.explode_scrollbar_event, config),

			--is_nan = core.is_nan, -- not including this one, reasoning: A programmer should learn how to check if a number is nan without this luanti-specific function
			-- you check it with `x == x` btw, nans have the unique property of `x ~= x` being true too

			get_us_time = core.get_us_time,
		},

		table = {
			copy = wwlf(table.copy, limit_f),
			indexof = wwlf(table.indexof, limit_f),
			insert_all = wwlf(table.insert_all, limit_f),
			key_value_swap = wwlf(table.key_value_swap, limit_f),
		},

		vector = table.copy(vector),
	} do
		if type(env[k]) == "table" and type(v) == "table" then
			for k2, v2 in pairs(v) do
				env[k][k2] = v2
			end
		else
			env[k] = v
		end
	end
	return env
end
