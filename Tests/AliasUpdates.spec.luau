-- Run with `lune run Tests/AliasUpdates.spec.luau`; exercises actual alias save and UI callbacks.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local now, refreshes, failRefresh, pendingRefresh = 0, 0, false, false
local stored = {Aliases = {[":old"] = ":pm 2 old"}}
local actor = {}
local admin = {CheckAliasBlacklist = function() return false end}
local env = setmetatable({
	Admin = admin, Settings = {Prefix = {":", ";"}, PlayerPrefix = "!"},
	Core = {GetPlayer = function() return stored end},
	os = {clock = function() return now end},
	stripArgPlaceholders = function(alias) return alias:gsub("<%S+>", ""):match("^%s*(.-)%s*$") end,
}, {__index = getfenv()})
local adminSource = fs.readFile("MainModule/Server/Core/Admin.luau")
local first = assert(adminSource:find("\t\tGetNativeAliasToken = function", 1, true))
local finish = assert(adminSource:find("\t\tCacheNativeChatCommands = function", first, true))
admin.GetNativeAliasToken = luau.load("return {" .. adminSource:sub(first, finish - 1) .. "}", {environment = env})().GetNativeAliasToken
admin.CacheNativeChatCommands = function(immediate, onlyPending)
	assert(immediate == true, "Accepted updates must complete server registration before replying")
	if onlyPending and not pendingRefresh then return end
	pendingRefresh = false
	refreshes += 1
	if failRefresh then error("fixture unavailable") end
end
local source = fs.readFile("MainModule/Server/Core/Remote.luau")
first = assert(source:find("\t\t\tUpdateAliases = function", 1, true))
finish = assert(source:find("\t\t\tPlayerData = function", first, true))
local update = luau.load("local aliasUpdateTimes = setmetatable({}, {__mode = 'k'})\nreturn {" .. source:sub(first, finish - 1) .. "}", {environment = env})().UpdateAliases

-- Advances the per-player edit window without hiding immediate-repeat failures.
local function save(aliases)
	now += 1
	return update(actor, {aliases})
end

local response = save({[":new <text>"] = ":pm 2 <text>"})
assert(response.Success and refreshes == 1 and stored.Aliases[":new <text>"], "An accepted map must be installed synchronously")
local admitted = stored.Aliases
assert(not update(actor, {{[":flood"] = ":pm 2 text"}}).Success and stored.Aliases == admitted and refreshes == 1, "Repeated writes must be throttled without mutation")
assert(save(table.clone(admitted)).Success and refreshes == 1, "Identical maps must not rebuild native commands")
pendingRefresh = true
assert(save(table.clone(admitted)).Success and not pendingRefresh and refreshes == 2, "Identical saves must finish a queued native refresh before returning")
refreshes = 1
local oversized = {}
for index = 1, 65 do oversized[":a" .. index] = ":pm 2 text" end
for _, invalid in {oversized, {[string.rep("a", 129)] = "command"}, {[":x"] = string.rep("x", 4097)}, {[3] = "command"}, {[":x"] = {}}, {[""] = "command"}} do
	assert(not save(invalid).Success and stored.Aliases == admitted and refreshes == 1, "Invalid maps must be rejected atomically")
end
response = save({["hello <text>"] = ":pm 2 <text>", [":bad! <text>"] = ":pm 2 <text>"})
assert(response.Success and response.CommandBarOnly, "Unsupported native aliases need an explicit command-bar-only result")
admitted = stored.Aliases
failRefresh = true
assert(not save({[":replacement"] = ":pm 2 text"}).Success and stored.Aliases == admitted, "Failed installation must restore the previous map")
failRefresh = false

local variables, requests, notices = {Aliases = {[":old"] = ":pm 2 old"}}, {}, {}
local functions = {}
local nextResponse = {Success = false, Message = "Wait one second between alias changes."}
local clientEnv = setmetatable({
	Functions = functions, Variables = variables,
	Remote = {Get = function(name, aliases)
		assert(name == "UpdateAliases", "Alias helpers must use the bounded alias-update endpoint")
		table.insert(requests, table.clone(aliases))
		return nextResponse
	end},
	client = {MatIcons = {}}, UI = {MakeGui = function(_, data) table.insert(notices, data) end},
	task = {defer = function(callback, ...) callback(...) end},
}, {__index = getfenv()})
source = fs.readFile("MainModule/Client/Core/Functions.luau")
first = assert(source:find("\t\tSaveAliases = function", 1, true))
finish = assert(source:find("\t\tPlaylist = function", first, true))
local implementation = luau.load("return {" .. source:sub(first, finish - 1) .. "}", {environment = clientEnv})()
for name, method in implementation do functions[name] = method end
local initial = variables.Aliases
assert(not functions.AddAlias(":new", ":pm 2 new", ":old") and variables.Aliases == initial, "Rejected renames must retain the original client map")
assert(#requests == 1 and not requests[1][":old"] and requests[1][":new"], "A rename must use one atomic request")
assert(not functions.RemoveAlias(":old") and variables.Aliases == initial, "Rejected removal must retain local aliases")
nextResponse = {Success = true, CommandBarOnly = true}
assert(functions.AddAlias("hello", ":pm 2 text", ":old") and not variables.Aliases[":old"] and variables.Aliases.hello, "Accepted edits must update the local map")
assert(notices[#notices - 1].Message:find("only in the command bar", 1, true), "Unsupported native aliases need a user-facing warning")
assert(functions.RemoveAlias("hello") and not next(variables.Aliases), "Accepted removal must update the local map")

-- Executes the real alias-editor click callback with the real staged-save helper.
source = fs.readFile("MainModule/Client/UI/Default/UserPanel.luau")
local binder = assert(source:find("local binderBox; binderBox = aliasTab", 1, true))
first = assert(source:find("OnClicked = function()", binder, true))
finish = assert(source:find("\n\t\t\t\t\t};", first, true))
local redraws = 0
local uiEnv = setmetatable({
	Functions = functions, aliasBox = {Text = ":renamed"}, commandBox = {Text = ":pm 2 new"},
	editOldAlias = ":old", currentAlias = ":old", binderBox = {Visible = true}, inputBlock = false,
	getAliases = function() redraws += 1 end,
}, {__index = getfenv()})
local click = luau.load("return {" .. source:sub(first, finish - 1) .. "}", {environment = uiEnv})().OnClicked
local uiState = getfenv(click)
variables.Aliases = {[":old"] = ":pm 2 old"}
local beforeRequests = #requests
nextResponse = {Success = false, Message = "Wait one second between alias changes."}
click()
assert(#requests == beforeRequests + 1 and variables.Aliases[":old"] and not variables.Aliases[":renamed"], "UI rename rejection must not remove the original alias")
assert(uiState.binderBox.Visible and uiState.aliasBox.Text == ":renamed" and uiState.editOldAlias == ":old" and not uiState.inputBlock and redraws == 0, "Rejected edits must stay open with retry state intact")
nextResponse = {Success = true}
click()
assert(#requests == beforeRequests + 2 and not variables.Aliases[":old"] and variables.Aliases[":renamed"], "Accepted UI rename must use exactly one replacement request")
assert(not uiState.binderBox.Visible and not uiState.editOldAlias and not uiState.currentAlias and redraws == 1, "Accepted UI edits must close and refresh the list")

-- Exercises incremental legacy cleanup through the real client helper and server endpoint.
stored.Aliases = {}
for index = 1, 66 do stored.Aliases[`:legacy{index}`] = ":help" end
variables.Aliases = table.clone(stored.Aliases)
local legacy = stored.Aliases
assert(not save(table.clone(legacy)).Success and stored.Aliases == legacy, "Oversized unchanged maps must still be rejected")
local changedLegacy = table.clone(legacy)
changedLegacy[":legacy1"] = nil
changedLegacy[":legacy2"] = ":pm 2 changed"
assert(not save(changedLegacy).Success and stored.Aliases == legacy, "Oversized cleanup must not alter retained aliases")
changedLegacy = table.clone(legacy)
changedLegacy[":new"] = ":help"
assert(not save(changedLegacy).Success and stored.Aliases == legacy, "Oversized cleanup must not add aliases")

clientEnv.Remote.Get = function(name, aliases)
	assert(name == "UpdateAliases", "Alias cleanup must use the bounded update endpoint")
	nextResponse = save(aliases)
	return nextResponse
end
assert(functions.RemoveAlias(":legacy1") and not stored.Aliases[":legacy1"] and not variables.Aliases[":legacy1"], "The editor must be able to reduce a 66-entry legacy map to 65")
assert(nextResponse.CommandBarOnly, "An oversized reduced map must remain command-bar-only")
local serverBefore, clientBefore = stored.Aliases, variables.Aliases
failRefresh = true
assert(not functions.RemoveAlias(":legacy2") and stored.Aliases == serverBefore and variables.Aliases == clientBefore, "Failed cleanup registration must roll back both maps")
failRefresh = false
assert(functions.RemoveAlias(":legacy2") and not nextResponse.CommandBarOnly, "Reducing to 64 eligible aliases must restore native eligibility")

-- Removing another entry may retain an unchanged legacy value beyond today's length limit.
stored.Aliases = {[":long"] = string.rep("x", 4097), [":delete"] = ":help"}
assert(save({[":long"] = stored.Aliases[":long"]}).Success, "Legacy length limits must not trap deletion-only cleanup")
assert(not save({[":long"] = string.rep("y", 4097)}).Success, "Cleanup must not permit new oversized expansions")
print("Alias update contracts passed: bounded atomic saves, legacy deletion-only cleanup, throttling, synchronous registration, rollback, client acceptance and atomic UI rename")
