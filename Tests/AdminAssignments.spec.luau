-- Run with `lune run Tests/AdminAssignments.spec.luau` from the repository root.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("MainModule/Server/Core/Admin.luau")

local function methodDefinition(methodName)
	local start = assert(source:find(`\t\t{methodName} = function`, 1, true), `Missing Admin.{methodName}`)
	local finish = source:find("\n\t\t[%a_][%w_]* = function", start) or #source + 1
	return source:sub(start, finish - 1)
end

local player = {Name = "AssignedUser", UserId = 123}
local ranks = {
	Moderator = {Level = 100, Users = {"AssignedUser:123"}},
	Administrator = {Level = 200, Users = {}},
}
local settings = {Ranks = ranks, SaveAdmins = true}
local admin = {SpecialLevels = {}, TempAdmins = {}}
local saves, cacheUpdates = {}, 0
local function isPlayer(value)
	return value == player and "userdata" or type(value)
end
local environment = setmetatable({
	Admin = admin,
	Settings = settings,
	Core = {DoSave = function(data) table.insert(saves, data) end},
	TrackTask = function(name, callback, ...)
		table.insert(saves, {Task = name, Callback = callback, Arguments = table.pack(...)})
	end,
	type = isPlayer,
}, {__index = getfenv()})

admin.GetLevel = function(target)
	assert(target == player, "Assignment looked up another player's level")
	local special = admin.SpecialLevels[tostring(player.UserId)]
	if special then return special.Level, special.Rank end
	for rankName, rankData in ranks do
		for _, entry in rankData.Users do
			if entry == `{player.Name}:{player.UserId}` or entry == player.Name or entry == player.UserId then
				return rankData.Level, rankName
			end
		end
	end
	return 0, nil
end
admin.DoCheck = function(target, check)
	return target == player and (
		check == player.UserId
		or check == player.Name
		or check == `{player.Name}:{player.UserId}`
		or check == player
	)
end
admin.IsTempAdmin = function(target)
	for index, tempPlayer in admin.TempAdmins do
		if admin.DoCheck(target, tempPlayer.UserId) then return true, index end
	end
	return false
end
admin.UpdateCachedLevel = function(target)
	assert(target == player, "Assignment updated another player's cached level")
	cacheUpdates += 1
end
admin.LevelToList = function(level)
	for rankName, rankData in ranks do
		if rankData.Level == level then return rankData.Users, rankName end
	end
	return nil
end
admin.StringToComLevel = function(rankName)
	return ranks[rankName] and ranks[rankName].Level
end

local methods = luau.load("return {\n"
	.. methodDefinition("SetLevel") .. "\n"
	.. methodDefinition("IsTempAdmin") .. "\n"
	.. methodDefinition("RemoveAdmin") .. "\n"
	.. methodDefinition("AddAdmin") .. "\n}", {environment = environment})()
for name, method in methods do admin[name] = method end

admin.AddAdmin(player, "Administrator")
assert(admin.GetLevel(player) == 200, "Rank assignment did not set the requested level")
assert(#ranks.Moderator.Users == 0 and #ranks.Administrator.Users == 1, "Rank reassignment did not move the player between rank lists")
assert(ranks.Administrator.Users[1] == "AssignedUser:123", "Persistent rank entry did not use canonical name and ID")
assert(
	#saves == 2
		and saves[1].Task == "Thread: RemoveAdmin"
		and saves[1].Arguments[2].Type == "TableRemove"
		and saves[2].Task == "Thread: SaveAdmin"
		and saves[2].Arguments[2].Type == "TableAdd",
	"Persistent rank reassignment did not queue the removal and addition"
)

local savedCount = #saves
admin.AddAdmin(player, "Moderator", true)
assert(admin.GetLevel(player) == 100 and #admin.TempAdmins == 1, "Temporary rank assignment did not update the player")
assert(#ranks.Administrator.Users == 0 and #ranks.Moderator.Users == 1, "Temporary reassignment did not remove the previous persistent rank")
assert(#saves == savedCount, "Temporary rank assignment persisted a settings change")
assert(admin.IsTempAdmin(player), "Temporary admin status was not detected")

admin.RemoveAdmin(player)
assert(admin.GetLevel(player) == 0 and #admin.TempAdmins == 0, "Removing a temporary admin did not clear the assignment")
assert(#ranks.Moderator.Users == 0, "Removing a temporary admin left a rank-list entry")
assert(#saves == savedCount, "Removing a temporary admin unexpectedly persisted a change")

admin.AddAdmin(player, "Administrator")
local savedBeforeRemoval = #saves
admin.RemoveAdmin(player, nil, true)
assert(admin.GetLevel(player) == 0 and #ranks.Administrator.Users == 0, "Permanent admin removal did not clear the rank")
assert(#saves == savedBeforeRemoval + 1 and saves[#saves].Task == "Thread: RemoveAdmin", "Permanent admin removal was not queued for saving")

admin.SpecialLevels[tostring(player.UserId)] = {Player = player.UserId, Level = 1000, Rank = "Place Owner"}
assert(admin.SetLevel(player, 500) == false, "SetLevel allowed changing an existing level 1000 account")
assert(admin.SpecialLevels[tostring(player.UserId)].Level == 1000, "Rejected level change modified the protected level")

print("Admin assignment contracts passed")
