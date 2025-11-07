local forbidden_identifier = "poo" -- bad word!! clearly must not be allowed in any lua code

category("Codegen option - banned_identifiers", function(can)
	local function make_test(code, debug)
		return function()
			code = code:format(forbidden_identifier)
			local ast, errs = slua.tl_api.parse(code, "<input>.lua")
			if #errs ~= 0 then
				error("BROKEN TEST: HAS SYNTAX ERRORS: " .. errs[1].msg)
			end
			local generated_code = slua.tl_api.generate(ast, "5.1", {
				preserve_ident = true,
				preserve_newlines = true,
				preserve_hashbang = false,
				sandbox_options = {
					concat_function_name = "c",
					banned_identifiers = { [forbidden_identifier] = true },
					before_loop_end = "",
				},
			})
			assert(
				not generated_code:find(forbidden_identifier),
				"Whoops test failed, generated code: " .. generated_code
			)
			assert(generated_code:find "_not_allowed", "Whoops test failed, generated code: " .. generated_code)
			if debug then
				error(tostring(generated_code))
			end
		end
	end
	can("local <bad>", (make_test "local %s"))
	can("local function <bad>", (make_test "local function %s() return end"))
	can("local function x(<bad>)", (make_test "local function x(%s) return end"))
	can("local type <bad>", (make_test "local type %s = string"))
end)
