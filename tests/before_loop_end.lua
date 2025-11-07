category("Codegen option - before_loop_end", function(can)
	local function make_test(code, match_code, debug)
		return function()
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
					banned_identifiers = {},
					before_loop_end = "before_loop_end()",
				},
			})
			assert(not debug, tostring(generated_code))

			if match_code then
				assert(generated_code == match_code, "Whoops test failed, generated code: " .. generated_code)
			else
				assert(
					generated_code:find "before_loop_end", -- not perfect, but ehh whatever
					"Whoops test failed, generated code: " .. generated_code
				)
			end
		end
	end

	-- i will go the order that is in teal/gen/lua_generator.tl
	-- all of these will be infinite loops, using before_loop_end option should allow you to add a function that can break you out of those

	can("while", make_test "while true do end -- classic")
	can("repeat", make_test "repeat until false")
	can("forin", make_test "for k,v in pairs(x) do end")
	can("fornum", make_test "for i=1,math.huge do end")
	can("goto", make_test "::x:: goto x")
	can("function", make_test "function x() x() end")
end)
