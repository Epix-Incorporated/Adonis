-- Run with `lune run Tests/AdminAliases.spec.luau` from the repository root.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("MainModule/Server/Core/Admin.luau")

local function methodDefinition(methodName)
	local start = assert(source:find(`\t\t{methodName} = function`, 1, true), `Missing Admin.{methodName}`)
	local finish = source:find("\n\t\t[%a_][%w_]* = function", start) or #source + 1
	return source:sub(start, finish - 1)
end

local helpersStart = assert(source:find("local function stripArgPlaceholders", 1, true), "Missing alias helpers")
local helpersFinish = assert(source:find("\n\tserver.Admin = {", helpersStart, true), "Missing Admin table boundary")
local helperSource = source:sub(helpersStart, helpersFinish - 1)

local function split(text, separator, limit)
	local result, cursor = {}, 1
	while #result < (limit or math.huge) do
		local start, finish = text:find(separator, cursor, true)
		if not start then
			break
		end
		table.insert(result, text:sub(cursor, start - 1))
		cursor = finish + 1
	end
	table.insert(result, text:sub(cursor))
	return result
end

local function sanitizePattern(text)
	return (text:gsub("([%^$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

local player = {
	Name = "Fixture",
	UserId = 77,
	IsA = function(_, className) return className == "Player" end,
}
local aliases = {
	["!greet"] = ":message <name>",
	["!loop"] = "!loop",
	["!cycle-a"] = "!cycle-b",
	["!cycle-b"] = "!cycle-a",
}
local admin = {}
local settings = {SplitKey = "|", BatchKey = ";", PlayerPrefix = "!", Prefix = {":", ";"}}
local variables = {Aliases = {["!global <name>"] = ":say <name>"}}
local environment = setmetatable({
	Admin = admin,
	Settings = settings,
	Variables = variables,
	Core = {GetPlayer = function(target)
		assert(target == player, "Alias lookup requested data for a different player")
		return {Aliases = aliases}
	end},
	Functions = {
		Split = split,
		Trim = function(text) return text:match("^%s*(.-)%s*$") end,
	},
	service = {
		SanitizePattern = sanitizePattern,
		Trim = function(text) return text:match("^%s*(.-)%s*$") end,
	},
	type = function(value) return if value == player then "userdata" else type(value) end,
}, {__index = getfenv()})

local definitions = table.concat({
	methodDefinition("GetArgs"),
	methodDefinition("CheckAliasBlacklist"),
	methodDefinition("IsAlias"),
	methodDefinition("IsRecursiveAlias"),
	methodDefinition("AliasFormat"),
}, "\n")
local methods = luau.load(helperSource .. "\nreturn {\n" .. definitions .. "\n}", {environment = environment})()
for name, method in methods do
	admin[name] = method
end

local alias, execution = admin.IsAlias(player, "!GREET Alice Smith")
assert(alias == "!greet" and execution == ":message <name>", `Player alias lookup mismatch: {tostring(alias)} / {tostring(execution)}`)
assert(admin.IsAlias(player, "!greetings Alice") == false, "Player alias lookup matched a partial alias")
assert(admin.IsAlias({}, "!greet Alice") == false, "Alias lookup accepted a non-player")

assert(admin.AliasFormat({["!greet <name>"] = ":message <name>"}, "!greet|Alice Smith") == ":message Alice Smith", "Player alias formatting lost its argument")
assert(admin.AliasFormat(nil, "!global|Bob Jones") == ":say Bob Jones", "Global alias formatting lost its argument")
assert(admin.CheckAliasBlacklist("!alias") and admin.CheckAliasBlacklist(":adonissettings"), "Protected aliases were not blacklisted")
assert(not admin.CheckAliasBlacklist("!greet"), "A normal alias was blacklisted")

assert(admin.IsRecursiveAlias(player, "!loop", "!loop") == true, "Direct recursive alias was not detected")
assert(admin.IsRecursiveAlias(player, "!cycle-a", "!cycle-b") == true, "Indirect recursive alias was not detected")
assert(admin.IsRecursiveAlias(player, "!greet", ":message <name>") == false, "Non-recursive alias was rejected")

print("Admin alias contracts passed")
