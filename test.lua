#!/usr/bin/env luajit

-- SETUP
assert(
	not core,
	"You are running this the wrong way, i mean, who am i to tell you what you can do with your computer, go ahead, remove this assert"
)

core = {}
function core.get_modpath(modname)
	return "."
end

bit = require "bit"

--- From builtin, modified
function table.copy(value)
	local seen = {}
	local function copy(t)
		if type(t) ~= "table" then
			return t
		end
		if seen[t] then
			return seen[t]
		end
		local res = {}
		seen[t] = res
		for k, v in pairs(t) do
			res[copy(k)] = copy(v)
		end
		return res
	end
	return copy(value)
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

local function it(x, f)
	assert(f, "No test function?")
	f()
	print("  --> " .. x .. " OK")
end

-- I am obfuscating the "_G" here so that lua_ls won't think category is a global function
_G["_" .. "G"].category = function(name, f)
	print("TESTING " .. name)
	f(it) -- i don't get why they call it it()
end

-- Okay, now load the tests
for _, test in ipairs {
	"./tests/banned_identifiers.lua",
	"./tests/concat_function_name.lua",
	"./tests/before_loop_end.lua",
	"./tests/environment.lua",
} do
	dofile(test)
end

-- vim: filetype=lua
