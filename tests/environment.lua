local env_config = {
	max_string_len = 64000, -- 64k, the default mesecons string limit
	max_loadstring_code_length = 8 * 1000,
}

local function pretty_print_syntax_errors(syntax_errs)
	for k, v in pairs(syntax_errs) do
		for k2, v2 in pairs(v) do
			print(k2, v2)
		end
	end
end

--- bit of a hack
local last_env

local function make_sandbox_with_basic_env(code)
	local env = {}
	last_env = env

	env_config.limit_function = slua.get_default_limit_function(8, "timeout") -- generate this each time for each sandbox

	slua.env.init_environment(env, env_config)
	slua.env.basic_env(env, env_config)
	--slua.env.add_luanti_utils(env, env_config) -- Tests are not ran in luanti

	local co, syntax_errs = slua.create_sandbox {
		env = env,
		code = code,
	}

	if not co then
		error("Broken test, syntax error: " .. syntax_errs)
	end
	return co
	-- yes that's it
end

local function string_length_error(max_len)
	return ("The result of this function will violate the string limit. (The limit is %s characters)"):format(max_len)
end

-- scuffed
-- removes line number and filename, useful for getting consistent error messages
local remove_details_from_errmsg = function(errmsg)
	if type(errmsg) ~= "string" then
		return errmsg
	end
	if string.find(errmsg, ":") then
		errmsg = errmsg:sub(string.find(errmsg, ":") + 1, -1)
		errmsg = errmsg:sub(string.find(errmsg, ":") + 2, -1)
		return errmsg
	else
		return errmsg
	end
end

local function run_and_expect(co, expected_ok, expected_errmsg)
	local ok, errmsg = slua.run_sandbox(co, last_env)

	if ok ~= expected_ok or remove_details_from_errmsg(errmsg) ~= expected_errmsg then
		error("Test failed, coroutine result: " .. tostring(ok) .. ", " .. tostring(remove_details_from_errmsg(errmsg)))
	end
end

category("Environment and Sandboxing", function(it)
	it("Sandbox can't override __slua table", function()
		run_and_expect(
			make_sandbox_with_basic_env [[
			_G["__sl".."ua"] = {}
		]],
			false,
			"Field __slua is read only!"
		)
	end)

	it("Sandbox execution time is limited", function()
		run_and_expect(
			make_sandbox_with_basic_env [[
			while true do end
		]],
			true,
			"timeout"
		)
	end)

	it("Sandbox concatination is limited", function()
		run_and_expect(
			make_sandbox_with_basic_env [[
			x = string.rep("a", 64000)
			while true do
				x = x .. x
			end
		]],
			false,
			("Concat operation violates string limit. (The limit is %s characters)"):format(env_config.max_string_len)
		)
	end)

	-- do not take this advice if you are making a mesecons-luacontroller-like sandbox, see existing PRs for a safe pcall in mesecons luacontrollers, and to minetest-mods team: please merge the best one
	it("pcall is fine", function()
		run_and_expect(
			make_sandbox_with_basic_env [[
			pcall(function()
				while true do

				end
			end)

			while true do end
		]],
			true,
			"timeout"
		)
	end)

	it("loadstring is fine: Is time limited", function()
		run_and_expect(
			make_sandbox_with_basic_env [[
			assert(loadstring("while true do end"))()
		]],
			true,
			"timeout"
		)
	end)

	it("loadstring is fine: Environment is limited", function()
		run_and_expect(
			make_sandbox_with_basic_env [[
			assert(loadstring('os.execute("echo hello :3")'))()
		]],
			false,
			"attempt to call field 'execute' (a nil value)"
		)
	end)

	it("loadstring is fine: Chunkname is limited", function()
		run_and_expect(
			make_sandbox_with_basic_env [[
			assert(loadstring('while true do end', string.rep('a',5000)))()
		]],
			false,
			"Chunkname is too long (What are you even trying to do?)"
		)
	end)

	it("string metatable is sandboxed", function()
		run_and_expect(make_sandbox_with_basic_env "local a = ''; assert(not a.match)", true)
	end)

	it(
		"string.find won't pattern match, and no pattern matching functions are avaliable in the basic environment",
		function()
			run_and_expect(
				make_sandbox_with_basic_env "string.find('a', 'b', 1, false)",
				false,
				"string.find call must be plain due to sandboxing resource restrictions."
			)
			run_and_expect(
				make_sandbox_with_basic_env "assert(not (string.match or string.gsub or string.gfind))",
				true
			)
		end
	)

	it("string.format is limited", function()
		run_and_expect(
			make_sandbox_with_basic_env [[
			for s in string.format, "%q", "" do end -- Copyright: ONLY for this single one line of code in this specific file: unknown (scary) (i stole it) (legal trouble awaiting) (in actuality probably fine as i doubt that single line is copyrightable)
		]],
			false,
			string_length_error(env_config.max_string_len)
		)
	end)

	it("string.rep is limited", function()
		run_and_expect(
			make_sandbox_with_basic_env [[
			string.rep("a", 690000000)
		]],
			false,
			string_length_error(env_config.max_string_len)
		)
	end)

	it("table.concat is limited", function()
		run_and_expect(
			make_sandbox_with_basic_env [[
			x = "."
			while true do
				x = table.concat{x, x}
			end
		]],
			false,
			string_length_error(env_config.max_string_len)
		)
	end)

	it("debug.getinfo can't return functions", function()
		run_and_expect(
			make_sandbox_with_basic_env [[
				assert(not debug.getinfo(1).func)
			]],
			true
		)
	end)
end)
