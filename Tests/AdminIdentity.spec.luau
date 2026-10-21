-- Run with `lune run Tests/AdminIdentity.spec.luau` from the repository root.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("MainModule/Server/Core/Admin.luau")

local function methodDefinition(methodName)
	local start = assert(source:find(`\t\t{methodName} = function`, 1, true), `Missing Admin.{methodName}`)
	local finish = source:find("\n\t\t[%a_][%w_]* = function", start) or #source + 1
	return source:sub(start, finish - 1)
end

local player = {
	Name = "ExampleUser",
	UserId = 456,
	IsA = function(_, className) return className == "Player" end,
}
local ownershipCalls = {}
local service = {
	UnWrap = function(value) return value end,
	Players = {
		GetPlayerByUserId = function(_, userId) return userId == player.UserId and player end,
		FindFirstChild = function(_, name) return string.lower(name) == string.lower(player.Name) and player end,
	},
	CheckAssetOwnership = function(target, assetId)
		table.insert(ownershipCalls, {Kind = "Asset", Player = target, Id = assetId})
		return assetId == 123
	end,
	CheckPassOwnership = function(target, passId)
		table.insert(ownershipCalls, {Kind = "Pass", Player = target, Id = passId})
		return passId == 234
	end,
	CheckSubscriptionStatus = function(target, subscriptionId)
		table.insert(ownershipCalls, {Kind = "Subscription", Player = target, Id = subscriptionId})
		return subscriptionId == "EXP-345"
	end,
}
local functions = {GetUserIdFromNameAsync = function(name)
	return if name == player.Name then player.UserId else nil
end}
local groups = {[100] = 50}
local admin = {
	GetGroupLevel = function(userId, groupId)
		assert(userId == player.UserId, "Group lookup used the wrong user ID")
		return groups[groupId] or 0
	end,
	GetPlayerGroup = function(target, groupId)
		assert(target == player, "Group membership lookup used the wrong player")
		local rank = groups[groupId]
		return rank and {Rank = rank}
	end,
}
local environment = setmetatable({
	Admin = admin,
	Functions = functions,
	service = service,
	typeof = function(value) return if value == player then "userdata" else typeof(value) end,
}, {__index = getfenv()})
local methods = luau.load("return {\n" .. methodDefinition("DoCheck") .. "\n}", {environment = environment})()
admin.DoCheck = methods.DoCheck

assert(admin.DoCheck(player, player.UserId), "Identity check failed for a Player instance and user ID")
assert(admin.DoCheck(player, "ExampleUser"), "Identity check failed for an exact username")
assert(admin.DoCheck(player, "exampleuser:456"), "Identity check failed for a case-insensitive name/user-ID pair")
assert(not admin.DoCheck(player, "UnknownUser"), "Identity check matched an unresolved username")
assert(admin.DoCheck(player.UserId, player), "Identity check did not resolve a player from user ID")
assert(admin.DoCheck("ExampleUser", player.UserId), "Identity check did not resolve a player by name")
assert(not admin.DoCheck(player, "SomeoneElse:789"), "Identity check matched a different name and user ID")
assert(not admin.DoCheck(999, "UnknownUser"), "Identity check accepted an unresolved user")

assert(admin.DoCheck(player, "Group:101") == false, "Group membership check accepted a non-member")
assert(admin.DoCheck(player, "Group:100:50"), `Exact group-rank requirement failed: {tostring(admin.GetGroupLevel(player.UserId, 100))}`)
assert(admin.DoCheck(player, "Group:100:-40"), "Minimum group-rank requirement failed")
assert(admin.DoCheck(player, {Group = 100, Rank = 50}), "Table-form group-rank requirement failed")
assert(not admin.DoCheck(player, {Group = 100, Rank = 60}), "Table-form group-rank accepted an incorrect rank")

assert(admin.DoCheck(player, "Item:123") and not admin.DoCheck(player, "Item:124"), "Asset ownership check returned the wrong result")
assert(admin.DoCheck(player, "Gamepass:234") and not admin.DoCheck(player, "Gamepass:235"), "Gamepass ownership check returned the wrong result")
assert(admin.DoCheck(player, "Subscription:EXP-345") and not admin.DoCheck(player, "Subscription:EXP-999"), "Subscription check returned the wrong result")
assert(#ownershipCalls == 6, "Ownership checks did not reach their service substitutes")

print("Admin identity contracts passed")
