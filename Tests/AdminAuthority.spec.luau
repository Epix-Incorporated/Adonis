-- Run with `lune run Tests/AdminAuthority.spec.luau` from the repository root.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("MainModule/Server/Core/Admin.luau")
local start = assert(source:find("\t\tCheckAuthority = function", 1, true), "Missing Admin.CheckAuthority")
local finish = source:find("\n\t\t[%a_][%w_]* = function", start) or #source + 1
local implementation = source:sub(start, finish - 1)

local actor = {Name = "Actor"}
local target = {Name = "Target"}
local levels = {[actor] = 50, [target] = 20}
local hints, prompts = {}, {}
local promptAnswer
local admin = {GetLevel = function(player) return levels[player] end}
local remote = {
	GetGui = function(player, gui, data)
		table.insert(prompts, {Player = player, Gui = gui, Data = data})
		return promptAnswer
	end,
}
local functions = {
	Hint = function(message, recipients)
		table.insert(hints, {Message = message, Recipients = recipients})
	end,
}
local service = {FormatPlayer = function(player) return player.Name end}
local environment = setmetatable({
	Admin = admin,
	Remote = remote,
	Functions = functions,
	service = service,
}, {__index = getfenv()})
local checkAuthority = luau.load("return {" .. implementation .. "}", {environment = environment})().CheckAuthority

assert(checkAuthority(actor, target, "moderate", false), "Higher-level actor was denied authority over a lower-level target")
levels[target] = levels[actor]
assert(not checkAuthority(actor, target, "moderate", false), "Equal-level actor was allowed to act on a target")
assert(hints[#hints].Message == "You don't have permission to moderate Target" and hints[#hints].Recipients[1] == actor, "Denied authority did not notify the actor")

levels[target] = levels[actor] + 1
assert(not checkAuthority(actor, target, "moderate", false), "Lower-level actor was allowed to act on a higher-level target")

local hintCount = #hints
assert(not checkAuthority(actor, actor, "remove", false), "Explicitly forbidden self-target action was allowed")
assert(#hints == hintCount + 1 and hints[#hints].Message == "You cannot remove yourself", "Forbidden self-target action gave the wrong hint")

assert(checkAuthority(actor, actor, "change", true), "Explicitly allowed self-target action was denied")
assert(not checkAuthority(actor, actor, "remove", nil), "Unconfirmed self-target action was allowed")
assert(prompts[#prompts].Data.Question == "Are you sure you want to remove yourself?", "Self-target confirmation asked the wrong question")
promptAnswer = "Yes"
assert(checkAuthority(actor, actor, "remove", nil), "Confirmed self-target action was denied")
promptAnswer = "No"
assert(not checkAuthority(actor, actor, "remove", nil), "Declined self-target confirmation was allowed")

print("Admin authority contracts passed")
