-- Run with `lune run Tests/AdminBans.spec.luau` from the repository root.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("MainModule/Server/Core/Admin.luau")

-- Loads selected actual Admin method definitions without initializing Roblox services.
local function loadMethods(methodNames, environment)
	local definitions = {}
	for _, methodName in methodNames do
		local marker = `\t\t{methodName} = function`
		local start = assert(source:find(marker, 1, true), `Missing Admin.{methodName}`)
		local nextStart = source:find("\n\t\t[%a_][%w_]* = function", start) or #source + 1
		table.insert(definitions, source:sub(start, nextStart - 1))
	end
	local chunk = "return {\n" .. table.concat(definitions, "\n") .. "\n}"
	return luau.load(chunk, {environment = environment})()
end

local now = 2000
local saves, crossServerCalls, banEvents = {}, {}, {}
local settings = {Banned = {}}
local core = {
	Variables = {TimeBans = {}},
	DoSave = function(data) table.insert(saves, data) end,
	CrossServer = function(...) table.insert(crossServerCalls, table.pack(...)) end,
}
local variables = {BanMessage = "Banned"}
local service = {
	FormatPlayer = function(player) return player.Name end,
	FormatTime = function(timestamp)
		return `time-{timestamp}`
	end,
	Players = {FindFirstChild = function() return nil end},
	Events = {
		PlayerBanned = {
			Fire = function(_, ...)
				table.insert(banEvents, table.pack(...))
			end,
		},
	},
}
local admin = {
	DoCheck = function(player, check)
		return check == player.UserId or (type(check) == "string" and string.lower(check) == string.lower(player.Name))
	end,
}
local environment = setmetatable({
	Admin = admin,
	Settings = settings,
	Core = core,
	Variables = variables,
	HTTP = {Trello = {Bans = {}, Mutes = {}}, WebPanel = {Bans = {}}},
	Remote = {},
	service = service,
	os = {time = function() return now end},
}, {__index = getfenv()})
local methods = loadMethods({
	"CheckBan",
	"AddBan",
	"AddTimeBan",
	"DoBanCheck",
	"RemoveBan",
	"RemoveTimeBan",
}, environment)
for name, method in methods do
	admin[name] = method
end

local target = {Name = "Target", UserId = 17}
table.insert(settings.Banned, {Name = "Target", UserId = 17, Reason = "Permanent reason"})
local banned, reason = admin.CheckBan(target)
assert(banned and reason == "Permanent reason", "Permanent ban lookup lost the matching reason")
assert(admin.DoBanCheck(17, settings.Banned[1]), "Ban matching by user ID failed")
assert(admin.DoBanCheck("target", settings.Banned[1]), "Ban matching by case-insensitive name failed")

settings.Banned = {}
table.insert(core.Variables.TimeBans, {Name = "Target", UserId = 17, EndTime = now + 60, Reason = "Temporary reason"})
banned, reason = admin.CheckBan(target)
assert(banned and reason:find("Temporary reason", 1, true) and reason:find("time-2060", 1, true), "Active time ban did not return its reason and expiry")

core.Variables.TimeBans = {{Name = "Target", UserId = 17, EndTime = now, Reason = "Expired"}}
banned = admin.CheckBan(target)
assert(not banned and #core.Variables.TimeBans == 0, "Expired time ban was not removed")

local moderator = {Name = "Moderator", UserId = 23}
admin.AddBan(target, "Recorded reason", true, moderator, "Server")
local permanent = settings.Banned[1]
assert(permanent.Name == target.Name and permanent.UserId == target.UserId, "Permanent ban did not retain the resolved target")
assert(permanent.Reason == "Recorded reason" and permanent.Moderator == moderator.Name and permanent.BanType == "Server", "Permanent ban metadata was not retained")
assert(saves[1].Type == "TableAdd" and saves[1].Table == "Banned" and saves[1].Value == permanent, "Permanent ban was not persisted")
assert(crossServerCalls[1][1] == "RemovePlayer" and crossServerCalls[1][2] == target.UserId, "Permanent ban did not notify other servers")
assert(banEvents[1][1] == target and banEvents[1][2] == "Recorded reason", "Permanent ban event had incorrect arguments")

admin.AddTimeBan(target, 120, "Time-ban reason", moderator)
local timed = core.Variables.TimeBans[1]
assert(timed.UserId == target.UserId and timed.EndTime == now + 120, "Time ban did not store the expected expiration")
assert(timed.Reason == "Time-ban reason" and timed.Moderator == moderator.Name, "Time-ban metadata was not retained")
assert(saves[2].Type == "TableAdd" and saves[2].Table[3] == "TimeBans" and saves[2].Value == timed, "Time ban was not persisted")
assert(crossServerCalls[2][2] == target.UserId and banEvents[2][3] == true, "Time ban side effects were not issued")

assert(admin.RemoveBan(target.UserId, true) == permanent and #settings.Banned == 0, "Permanent ban removal did not find the target")
assert(saves[3].Type == "TableRemove" and saves[3].Value == permanent, "Permanent ban removal was not persisted")
assert(admin.RemoveTimeBan("target") == timed and #core.Variables.TimeBans == 0, "Time ban removal did not find the target")
assert(saves[4].Type == "TableRemove" and saves[4].Value == timed, "Time ban removal was not persisted")

print("Admin ban lifecycle contracts passed")
