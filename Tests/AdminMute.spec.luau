-- Run with `lune run Tests/AdminMute.spec.luau` from the repository root.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("MainModule/Server/Core/Admin.luau")

local function methodDefinition(methodName)
	local start = assert(source:find(`\t\t{methodName} = function`, 1, true), `Missing Admin.{methodName}`)
	local finish = source:find("\n\t\t[%a_][%w_]* = function", start) or #source + 1
	return source:sub(start, finish - 1)
end

local player = {
	Name = "MutedUser",
	UserId = 456,
	IsA = function(_, className) return className == "Player" end,
}
local service = {
	UnWrap = function(value) return value end,
	Players = {
		GetPlayerByUserId = function(_, userId) return userId == player.UserId and player end,
		FindFirstChild = function(_, name) return string.lower(name) == string.lower(player.Name) and player end,
	},
}
local functions = {
	GetUserIdFromNameAsync = function(name)
		return if string.lower(name) == string.lower(player.Name) then player.UserId else nil
	end,
}
local settings = {Muted = {}}
local http = {Trello = {Mutes = {}}, WebPanel = {Mutes = {}}}
local admin = {
	GetGroupLevel = function() return 0 end,
	GetPlayerGroup = function() return nil end,
}
local environment = setmetatable({
	Admin = admin,
	Settings = settings,
	HTTP = http,
	Functions = functions,
	service = service,
	typeof = function(value) return if value == player then "userdata" else typeof(value) end,
}, {__index = getfenv()})
local methods = luau.load("return {\n"
	.. methodDefinition("IsMuted") .. "\n"
	.. methodDefinition("DoCheck") .. "\n}", {environment = environment})()
admin.IsMuted, admin.DoCheck = methods.IsMuted, methods.DoCheck

assert(admin.DoCheck(player, 456), "Direct user-ID check failed")
assert(admin.DoCheck(player, "MutedUser"), "Direct name check failed")
assert(admin.DoCheck(player, "muteduser:456"), "Name and user-ID check failed")
assert(not admin.DoCheck(player, "OtherUser"), "Identity check accepted a name that did not resolve to this player")
assert(not admin.DoCheck(player, "OtherUser:999"), "Identity check matched another user")
assert(not admin.DoCheck(999, "Unresolvable"), "Unresolvable identity unexpectedly matched")

assert(not admin.IsMuted(player), "Player without a mute entry was marked muted")
table.insert(settings.Muted, 456)
assert(admin.IsMuted(player), "Configured mute was not recognized")
settings.Muted = {}
table.insert(http.Trello.Mutes, "MutedUser")
assert(admin.IsMuted(player), "Trello mute was not recognized")
http.Trello.Mutes = {}
table.insert(http.WebPanel.Mutes, {Group = 10, Rank = 3})
admin.GetPlayerGroup = function(target, groupId)
	assert(target == player and groupId == 10, "Web-panel group mute checked the wrong group")
	return {Rank = 3}
end
assert(admin.IsMuted(player), "Web-panel group mute was not recognized")
http.WebPanel.Mutes = nil
assert(not admin.IsMuted(player), "Missing web-panel mute list caused a false mute")

print("Admin mute and identity contracts passed")
