-- Run with `lune run Tests/AdminCooldownUpdates.spec.luau` from the repository root.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("MainModule/Server/Core/Admin.luau")
local start = assert(source:find("\t\tUpdateCooldown = function", 1, true), "Missing Admin.UpdateCooldown")
local finish = source:find("\n\t\t[%a_][%w_]* = function", start) or #source + 1
local definition = source:sub(start, finish - 1)

local now = 123.5
local player = {UserId = 555}
local playerData = {_crossCooldownCache = {}}
local getPlayerCalls = 0
local environment = setmetatable({
	Core = {GetPlayer = function(target)
		assert(target == player, "Cooldown update requested another player's data")
		getPlayerCalls += 1
		return playerData
	end},
	service = {HttpService = {GenerateGUID = function() return "generated" end}},
	os = {clock = function() return now end},
}, {__index = getfenv()})
local updateCooldown = luau.load("return {\n" .. definition .. "\n}", {environment = environment})().UpdateCooldown

local command = {
	Prefix = ":",
	Commands = {"test", "t"},
	PlayerCooldown = 10,
	ServerCooldown = 20,
	CrossCooldown = 30,
}
updateCooldown({Player = player}, command)
assert(command._fullName == ":test", "Cooldown key did not use the canonical command name")
assert(command._playerCooldownCache["555"] == now, "Player cooldown timestamp was not recorded by user ID")
assert(command._serverCooldownCache["555"] == now, "Server cooldown timestamp was not recorded by user ID")
assert(playerData._crossCooldownCache[":test"] == now, "Cross-server cooldown timestamp was not recorded in player data")
assert(getPlayerCalls == 1, "Player data was not fetched exactly once for cross-server cooldown")

now = 130
updateCooldown({Player = player}, command)
assert(command._playerCooldownCache["555"] == now and command._serverCooldownCache["555"] == now, "Cooldown timestamps were not refreshed")
assert(playerData._crossCooldownCache[":test"] == now, "Cross-server cooldown timestamp was not refreshed")

local previousPlayer, previousServer, previousCross = command._playerCooldownCache["555"], command._serverCooldownCache["555"], playerData._crossCooldownCache[":test"]
updateCooldown({Player = "SYSTEM"}, command)
assert(command._playerCooldownCache["555"] == previousPlayer and command._serverCooldownCache["555"] == previousServer, "SYSTEM execution changed player cooldowns")
assert(playerData._crossCooldownCache[":test"] == previousCross and getPlayerCalls == 2, "SYSTEM execution changed or fetched player cooldown state")

local noCooldown = {Prefix = ":", Commands = {"plain"}}
updateCooldown({Player = player}, noCooldown)
assert(noCooldown._playerCooldownCache["555"] == nil and noCooldown._serverCooldownCache["555"] == nil, "Command without cooldown settings wrote local cooldowns")
assert(playerData._crossCooldownCache[":plain"] == nil, "Command without cross cooldown created a cross-server timestamp")

print("Admin cooldown update contracts passed")
