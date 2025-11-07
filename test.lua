#!/usr/bin/env luajit

assert(
	not core,
	"You are running this the wrong way, i mean, who am i to tell you what you can do with your computer, go ahead, remove this assert"
)

core = {}
function core.get_modpath(modname)
	return "."
end

-- Load slua
dofile(core.get_modpath "slua" .. "/init.lua")

--- REINVENTING THE WHEEL
--- The testing "framework"
--- BTW, code coverage stat is worse than useless here probably
---
---
--- The principle:
---		error() - test fail
---		anything else - test good

local function can(x, f)
	assert(f, "No test function?")
	f()
	print("  --> " .. x .. " OK")
end

function category(name, f)
	print("TESTING " .. name)
	f(can) -- i don't get why they call it it()
end

-- Okay, now load the tests
for _, test in ipairs {
	"./tests/banned_identifiers.lua",
	"./tests/concat_function_name.lua",
	"./tests/before_loop_end.lua",
} do
	dofile(test)
end

-- vim: filetype=lua
