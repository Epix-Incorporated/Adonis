-- Run with `lune run Tests/AdminCommandRegistry.spec.luau` from the repository root.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("MainModule/Server/Core/Admin.luau")

local function methodDefinition(methodName)
	local start = assert(source:find(`\t\t{methodName} = function`, 1, true), `Missing Admin.{methodName}`)
	local finish = source:find("\n\t\t[%a_][%w_]* = function", start) or #source + 1
	return source:sub(start, finish - 1)
end

local commands = {
	Moderate = {Prefix = ":", Commands = {"ban", "block"}, AdminLevel = 100},
	Inspect = {Prefix = {"!", "?"}, Commands = {"profile", "who"}, AdminLevel = 0},
	Legacy = {Prefix = "", Commands = {"status"}, AdminLevel = 0},
	NotACommand = "ignored",
}
local admin = {BlankPrefix = false}
local settings = {SplitKey = " ", ChatCommands = false}
local variables = {ChatCreateRobloxCommands = false}
local environment = setmetatable({
	Admin = admin,
	Commands = commands,
	Settings = settings,
	Variables = variables,
}, {__index = getfenv()})
local definitions = table.concat({
	methodDefinition("CacheCommands"),
	methodDefinition("GetCommand"),
	methodDefinition("FindCommands"),
	methodDefinition("SetPermission"),
}, "\n")
local methods = luau.load("return {\n" .. definitions .. "\n}", {environment = environment})()
for name, method in methods do
	admin[name] = method
end

admin.CacheCommands()
assert(admin.PrefixCache[":"] and admin.PrefixCache["!"] and admin.PrefixCache["?"] and admin.PrefixCache[""], "Command prefixes were not cached")
assert(admin.CommandCache[":ban"] == "Moderate" and admin.CommandCache[":block"] == "Moderate", "Command aliases were not cached")
assert(admin.CommandCache["!profile"] == "Inspect" and admin.CommandCache["?who"] == "Inspect", "Multiple command prefixes were not cached")
assert(admin.BlankPrefix, "Blank-prefix command was not recorded")

local commandName, command, matched = admin.GetCommand(":BAN Target reason")
assert(commandName == "Moderate" and command == commands.Moderate and matched == ":BAN", `Command lookup mismatch: {tostring(commandName)} / {tostring(matched)}`)
commandName, command = admin.GetCommand("?WHO Target")
assert(commandName == "Inspect" and command == commands.Inspect, "Command lookup failed for an alternate prefix")
commandName, command = admin.GetCommand("status extra")
assert(commandName == "Legacy" and command == commands.Legacy, "Blank-prefix command lookup failed")
assert(admin.GetCommand(":missing") == nil, "Unknown command resolved")

local matches = admin.FindCommands(":BLOCK Target")
assert(matches.Moderate == commands.Moderate and matches.Inspect == nil, "Prefixed command search returned the wrong definition")
matches = admin.FindCommands("profile")
assert(matches.Inspect == commands.Inspect and matches.Moderate == nil, "Unprefixed command search did not find the alias")

admin.SetPermission(":block", 250)
assert(commands.Moderate.AdminLevel == 250 and commands.Inspect.AdminLevel == 0, "SetPermission changed the wrong command")
admin.SetPermission("profile", 75)
assert(commands.Inspect.AdminLevel == 75, "SetPermission did not update an unprefixed matching command")
admin.SetPermission(":unknown", 900)
assert(commands.Moderate.AdminLevel == 250 and commands.Inspect.AdminLevel == 75, "Unknown permission target changed command permissions")

print("Admin command registry contracts passed")
