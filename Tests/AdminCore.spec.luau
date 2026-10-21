-- Run with `lune run Tests/AdminCore.spec.luau` from the repository root.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("MainModule/Server/Core/Admin.luau")

-- Loads selected actual Admin method definitions without initializing Roblox services.
local function loadMethods(methodNames, environment)
	local definitions = {}
	for _, methodName in methodNames do
		local marker = `\t\t{methodName} = function`
		local start = assert(source:find(marker, 1, true), `Missing Admin.{methodName}`)
		local nextStart = source:find("\n\t\t[%a_][%w_]* = function", start)
			or #source + 1
		table.insert(definitions, source:sub(start, nextStart - 1))
	end
	local chunk = "return {\n" .. table.concat(definitions, "\n") .. "\n}"
	return luau.load(chunk, {environment = environment})()
end

local function makePermissionFixture()
	local player = {UserId = 10}
	local now = 100
	local crossCooldownCache = {}
	local playerDataCache = {_crossCooldownCache = crossCooldownCache}
	local settings = {
		CrossServerCommands = true,
		DonorCommands = false,
		FunCommands = true,
		PlayerCommands = true,
		Ranks = {Creators = {Level = 900}},
	}
	local variables = {IsStudio = false}
	local core = {
		DebugMode = false,
		GetPlayer = function(target)
			assert(target == player, "Cross-server cooldown requested data for a different player")
			return playerDataCache
		end,
	}
	local admin = {
		IsPlaceOwner = function() return false end,
		IsBlacklisted = function() return false end,
		CheckComLevel = function(adminLevel, commandLevel)
			return type(commandLevel) == "number" and adminLevel >= commandLevel
		end,
	}
	local environment = setmetatable({
		Settings = settings,
		Variables = variables,
		Core = core,
		Admin = admin,
		HTTP = {Trello = {CheckAgent = function() return false end}},
		service = {HttpService = {GenerateGUID = function() return "fixture" end}},
		os = {clock = function() return now end},
		type = function(value)
			return if value == player then "userdata" else type(value)
		end,
	}, {__index = getfenv()})
	admin.CheckPermission = loadMethods({"CheckPermission"}, environment).CheckPermission
	return admin.CheckPermission, settings, variables, core, admin, player, function(value) now = value end, crossCooldownCache
end

local checkPermission, settings, variables, core, admin, player, setPermissionTime, crossCooldownCache = makePermissionFixture()
local playerData = {Player = player, Level = 0, isDonor = false}

local allowed, reason = checkPermission(playerData, {AdminLevel = 0, Disabled = true}, true)
assert(not allowed and reason == "This command has been disabled.", "Disabled command was permitted")

allowed, reason = checkPermission(playerData, {AdminLevel = 0}, true)
assert(allowed and reason == nil, "An enabled player command should be permitted")

settings.PlayerCommands = false
allowed, reason = checkPermission(playerData, {AdminLevel = 0}, true)
assert(not allowed and reason == "Player commands are disabled in this game.", "Disabled player commands were not denied")
settings.PlayerCommands = true

allowed, reason = checkPermission(playerData, {AdminLevel = 50}, true)
assert(not allowed and reason == nil, "An under-ranked player received an elevated command")
playerData.Level = 50
allowed = checkPermission(playerData, {AdminLevel = 50}, true)
assert(allowed, "A player at the required rank was denied")
playerData.Level = 0

variables.IsStudio = true
allowed, reason = checkPermission(playerData, {AdminLevel = 0, NoStudio = true}, true)
assert(not allowed and reason == "This command cannot be used in Roblox Studio.", "Studio-restricted command was permitted")
variables.IsStudio = false

allowed, reason = checkPermission(playerData, {AdminLevel = 0, CrossServerDenied = true}, true, {CrossServer = true})
assert(not allowed and reason == "This command may not be run across servers (cross-server-blacklisted).", "Cross-server denied command was permitted")
allowed, reason = checkPermission(playerData, {AdminLevel = 0, CrossServer = true}, true)
assert(allowed, "Enabled cross-server command was denied")
settings.CrossServerCommands = false
allowed, reason = checkPermission(playerData, {AdminLevel = 0, CrossServer = true}, true)
assert(not allowed and reason == "This command has been disabled due to CrossServerCommands being disabled", "Disabled cross-server commands were permitted")
settings.CrossServerCommands = true

allowed, reason = checkPermission(playerData, {AdminLevel = 0, Fun = true}, true)
assert(allowed, "Fun commands should be permitted while enabled")
settings.FunCommands = false
allowed, reason = checkPermission(playerData, {AdminLevel = 0, Fun = true}, true)
assert(not allowed and reason == "Fun commands are disabled in this game.", "Fun commands were permitted while disabled")
settings.FunCommands = true

allowed, reason = checkPermission(playerData, {AdminLevel = 0, NonChattable = true}, true, {Chat = true})
assert(not allowed and reason == "This command is not permitted as chat message (non-chattable command).", "Non-chattable command was allowed from chat")
allowed = checkPermission(playerData, {AdminLevel = 0, NonChattable = true}, true)
assert(allowed, "Non-chattable command was denied outside chat")

allowed = checkPermission(playerData, {AdminLevel = 100, Donors = true}, true)
assert(not allowed, "Non-donors were allowed to use a donor command")
playerData.isDonor = true
settings.DonorCommands = true
allowed = checkPermission(playerData, {AdminLevel = 100, Donors = true}, true)
assert(allowed, "Eligible donor was denied a donor command")
settings.DonorCommands = false
allowed = checkPermission(playerData, {AdminLevel = 100, Donors = true, AllowDonors = true}, true)
assert(allowed, "Command-level donor opt-in was ignored")
playerData.isDonor = false

admin.IsBlacklisted = function() return true end
allowed, reason = checkPermission(playerData, {AdminLevel = 0}, true)
assert(not allowed and reason == "You are blacklisted from running commands.", "Blacklisted user was allowed")
playerData.Level = settings.Ranks.Creators.Level
allowed = checkPermission(playerData, {AdminLevel = 900, Fun = true, NonChattable = true}, true, {Chat = true})
assert(allowed, "Creator-level permission bypass did not work")
admin.IsBlacklisted = function() return false end
playerData.Level = 0

local cooldownCommand = {
	AdminLevel = 0,
	Commands = {"cooldown"},
	Prefix = ":",
}
local function expectCooldownBlocked(expected, label)
	local hasPermission, cooldownMessage = checkPermission(playerData, cooldownCommand, false)
	assert(not hasPermission and cooldownMessage and cooldownMessage:find(expected, 1, true), `{label} cooldown was not enforced`)
end

cooldownCommand.PlayerCooldown = 10
cooldownCommand._playerCooldownCache = {["10"] = 95}
expectCooldownBlocked("[PlayerCooldown]", "Player")
cooldownCommand._playerCooldownCache["10"] = 90
allowed = checkPermission(playerData, cooldownCommand, false)
assert(allowed, "Expired player cooldown continued to block the command")
cooldownCommand._playerCooldownCache = nil
allowed = checkPermission(playerData, cooldownCommand, false)
assert(allowed, "An absent player cooldown blocked the command")

cooldownCommand.PlayerCooldown = nil
cooldownCommand.ServerCooldown = 10
cooldownCommand._serverCooldownCache = {["10"] = 95}
expectCooldownBlocked("[ServerCooldown]", "Server")
cooldownCommand._serverCooldownCache["10"] = 90
allowed = checkPermission(playerData, cooldownCommand, false)
assert(allowed, "Expired server cooldown continued to block the command")
cooldownCommand._serverCooldownCache = nil
allowed = checkPermission(playerData, cooldownCommand, false)
assert(allowed, "An absent server cooldown blocked the command")

cooldownCommand.ServerCooldown = nil
cooldownCommand.CrossCooldown = 10
crossCooldownCache[":cooldown"] = 95
expectCooldownBlocked("[CrossServerCooldown]", "Cross-server")
crossCooldownCache[":cooldown"] = 90
allowed = checkPermission(playerData, cooldownCommand, false)
assert(allowed, "Expired cross-server cooldown continued to block the command")
crossCooldownCache[":cooldown"] = nil
allowed = checkPermission(playerData, cooldownCommand, false)
assert(allowed, "An absent cross-server cooldown blocked the command")
setPermissionTime(101)

local function makeRankFixture()
	local now = 100
	local data = {AdminLevel = 0, AdminRank = nil, LastLevelUpdate = now}
	local player = {UserId = 7, Name = "Member"}
	local updateCount = 0
	local admin = {
		SpecialLevels = {},
		AdminLevelCacheTimeout = 30,
		DoCheck = function(_, check)
			if type(check) == "number" then
				return check == player.UserId
			elseif type(check) == "string" then
				return check == player.Name
			end
			return false
		end,
		IsPlaceOwner = function() return false end,
		UpdateCachedLevel = function(target, cachedData)
			assert(target == player and cachedData == data, "Cached level refresh received the wrong player data")
			updateCount += 1
			data.AdminLevel, data.AdminRank, data.LastLevelUpdate = 40, "Refreshed", now
			return data.AdminLevel, data.AdminRank
		end,
	}
	local settings = {
		Ranks = {
			Low = {Level = 10, Users = {"Member"}},
			High = {Level = 50, Users = {7}},
			Highest = {Level = 90, Users = {"Other"}},
		},
	}
	local core = {GetPlayer = function(target)
		assert(target == player, "Rank lookup requested data for a different player")
		return data
	end}
	local environment = setmetatable({
		Admin = admin,
		Settings = settings,
		Core = core,
		Remote = {Clients = {}},
		Functions = {},
		os = {time = function() return now end},
	}, {__index = getfenv()})
	local methods = loadMethods({"GetUpdatedLevel", "GetLevel"}, environment)
	admin.GetUpdatedLevel = methods.GetUpdatedLevel
	admin.GetLevel = methods.GetLevel
	return admin, player, data, settings, function(value) now = value end, function() return updateCount end
end

local rankAdmin, rankPlayer, rankData, rankSettings, setNow, getUpdateCount = makeRankFixture()
local level, rank = rankAdmin.GetUpdatedLevel(rankPlayer, rankData)
assert(level == 50 and rank == "High", "Rank lookup did not choose the highest matching rank")
rankAdmin.SpecialLevels["7"] = {Player = 7, Level = 70, Rank = "Temporary"}
level, rank = rankAdmin.GetUpdatedLevel(rankPlayer, rankData)
assert(level == 70 and rank == "Temporary", "Special level did not override configured ranks")
rankAdmin.SpecialLevels["7"] = nil
rankAdmin.IsPlaceOwner = function() return true end
level, rank = rankAdmin.GetUpdatedLevel(rankPlayer, rankData)
assert(level == 1000 and rank == "Place Owner", "Place owner did not receive the owner level")
rankAdmin.IsPlaceOwner = function() return false end

level, rank = rankAdmin.GetLevel(rankPlayer)
assert(level == 0 and rank == nil and getUpdateCount() == 0, "Fresh rank cache was unnecessarily recalculated")
setNow(131)
level, rank = rankAdmin.GetLevel(rankPlayer)
assert(level == 40 and rank == "Refreshed" and getUpdateCount() == 1, "Expired rank cache was not refreshed")
rankData.LastLevelUpdate = 200
setNow(150)
rankAdmin.GetLevel(rankPlayer)
assert(getUpdateCount() == 2, "Future-dated rank cache was not refreshed")

print("Admin permission and rank contracts passed")
