-- Run with `lune run Tests/AdminFormatting.spec.luau` from the repository root.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local adminSource = fs.readFile("MainModule/Server/Core/Admin.luau")
local functionsSource = fs.readFile("MainModule/Server/Core/Functions.luau")

local function methodDefinition(source, methodName)
	local start = assert(source:find(`\t\t{methodName} = function`, 1, true), `Missing {methodName}`)
	local finish = source:find("\n\t\t[%a_][%w_]* = function", start) or #source + 1
	return source:sub(start, finish - 1)
end

local environment = setmetatable({
	Settings = {SplitKey = " "},
	Functions = {},
	Admin = {},
}, {__index = getfenv()})
local splitDefinition = methodDefinition(functionsSource, "Split")
environment.Functions.Split = luau.load("return {\n" .. splitDefinition .. "\n}", {environment = environment})().Split
local adminDefinitions = table.concat({
	methodDefinition(adminSource, "GetArgs"),
	methodDefinition(adminSource, "FormatCommandArguments"),
	methodDefinition(adminSource, "FormatCommand"),
}, "\n")
local methods = luau.load("return {\n" .. adminDefinitions .. "\n}", {environment = environment})()
for name, method in methods do environment.Admin[name] = method end

local args = environment.Admin.GetArgs(":command first remaining values", 2)
assert(#args == 2 and args[1] == "first" and args[2] == "remaining values", "Argument parser did not preserve the final remainder")
args = environment.Admin.GetArgs(':command "two words" last', math.huge)
assert(#args == 2 and args[1] == "two words" and args[2] == "last", `Quoted arguments mismatch: {#args} / {tostring(args[1])} / {tostring(args[2])}`)
args = environment.Admin.GetArgs(":command one", 3, "injected")
assert(args[1] == "one" and args[2] == "injected", "Explicit arguments were not appended to parsed arguments")
assert(#environment.Admin.GetArgs(":command", 2) == 0, "Argument parser fabricated missing arguments")

local command = {Prefix = {":", ";"}, Commands = {"teleport", "tp"}, Args = {"player", "destination"}}
assert(environment.Admin.FormatCommandArguments(command) == "<player> <destination>", "Command argument placeholders were not formatted")
assert(environment.Admin.FormatCommand(command) == ":teleport <player> <destination>", "Default command formatting was incorrect")
assert(environment.Admin.FormatCommand(command, 2) == ":tp <player> <destination>", "Alternate command alias formatting was incorrect")
local noArgs = {Prefix = "!", Commands = {"help"}, Args = {}}
assert(environment.Admin.FormatCommand(noArgs) == "!help", "No-argument command formatting added a separator")

print("Admin argument and formatting contracts passed")
