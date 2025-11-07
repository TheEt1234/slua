category("Codegen option - concat_function_name", function(can)
	can("concat_function_name option", function()
		local code = "x = x .. x" -- the infamous, amongst the niche set of people who care about luacontrollers, who have interest in the mesecons issue tracker, and who discovered that specific issue

		local ast, errs = slua.tl_api.parse(code, "<input>.lua")

		local generated_code = slua.tl_api.generate(ast, "5.1", {
			preserve_ident = true,
			preserve_newlines = true,
			preserve_hashbang = false,
			sandbox_options = {
				concat_function_name = "c",
				banned_identifiers = {},
				before_loop_end = "",
			},
		})
		assert(generated_code == "x = c(x, x)")
	end)
end)
