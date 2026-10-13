-- Run with `lune run Tests/CommandErrors.spec.luau`; executes policy projection and actual exception sinks.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local secret = "UNVERIFIABLE_COMMAND_EXCEPTION"
local server = {}
local env = setmetatable({server = server}, {__index = getfenv()})
luau.load(fs.readFile("MainModule/Server/Core/TextPolicy.luau"), {environment = env})()({Server = server, Service = {}})
local project = server.TextPolicy.ProjectCommandError
local generic = "Command failed; details are unavailable."
for _, value in {secret, {Message = secret}, 123, true, "Source:4: " .. secret, "Wait 61 seconds before editing shared text again", "Wait -1 seconds before editing shared text again", "Wait 20 seconds before editing shared text again\n" .. secret} do
	assert(project(value) == generic, "An arbitrary exception escaped the error allowlist")
end
for _, value in {"Text could not be filtered. Please try again later.", "Enter chat text yourself; generated commands cannot send messages.", "Wait 0 seconds before editing shared text again", "Wait 60 seconds before editing shared text again"} do
	assert(project(value) == value and project("Source:12: " .. value) == value, "Approved fixed policy feedback was discarded")
end
assert(project(nil) == generic, "A nil exception lacked a safe fallback")

local outputs, audits = {}, {}
local actor = {UserId = 17, Name = "Actor"}
env.opts, env.isSystem, env.p, env.index = {}, false, actor, "TestCommand"
env.auditActor, env.command = actor, {}
env.Logs = {AddAudit = function(category, event, player, metadata) table.insert(audits, {Category = category, Event = event, Actor = player.UserId, Metadata = metadata}) end}
env.Remote = {MakeGui = function(_, _, data) table.insert(outputs, data) end}
env.Core = {DebugMode = true}
env.warn = function(message) table.insert(outputs, {Console = message}) end
local process = fs.readFile("MainModule/Server/Core/Process.luau")
local first = assert(process:find("TrackTask(taskName, executeCommand, function(cmdError)", 1, true))
local start = assert(process:find("function(cmdError)", first, true))
local finish = assert(process:find("\n\t\t\t\tend, p, args,", start, true))
local processError = luau.load("return " .. process:sub(start, finish - 1) .. "\nend", {environment = env})()
processError(secret)
processError({Message = secret})
processError("Source:12: Wait 59 seconds before editing shared text again")
assert(outputs[1].Message == generic and outputs[3].Message == generic and outputs[5].Message == "Wait 59 seconds before editing shared text again", "Process bypassed approved error projection")
assert(#audits == 3 and audits[1].Actor == actor.UserId and audits[1].Metadata.CommandKey == "TestCommand" and audits[1].Metadata.Outcome == "Failed", "Process error audit lost safe actor, command or outcome metadata")

local injected
env.Settings = {}
env.Color3 = {new = function() return "red" end}
env.Admin = {
	GetCommand = function() return "TestCommand", {Args = {}, AdminLevel = 0, Function = function() end} end,
	GetLevel = function() return 900 end,
	GetArgs = function() return {} end,
}
env.TrackTask = function(_, _, onError) onError(injected); return false, injected end
local admin = fs.readFile("MainModule/Server/Core/Admin.luau")
start = assert(admin:find("\t\tRunCommandAsPlayer = function", 1, true))
finish = assert(admin:find("\t\tCacheCommands = function", start, true))
local methods = luau.load("return {" .. admin:sub(start, finish - 1) .. "}", {environment = env})()
for _, method in {methods.RunCommandAsPlayer, methods.RunCommandAsNonAdmin} do
	injected = secret
	method(":test", actor)
	assert(outputs[#outputs - 1].Message == generic, "An Admin helper emitted an unknown exception or global error function")
	injected = "Text could not be filtered. Please try again later."
	method(":test", actor)
	assert(outputs[#outputs - 1].Message == injected, "An Admin helper discarded fixed filter feedback")
end
local mode = "syntax"
local taskNames = {}
env.Commands = {ScriptEditor = {AdminLevel = 900}}
env.Variables = {ScriptEditor = {[tostring(actor.UserId)] = {example = {Script = secret}}}}
env.Admin.CheckComLevel = function() return true end
env.GetEnv = function(_, overrides) return overrides end
env.Core.Loadstring = function(_, scriptEnv)
	if mode == "syntax" then return nil, secret end
	return function()
		if mode == "explicit" then scriptEnv.error(secret) else error(secret, 0) end
	end
end
env.service = {TrackTask = function(name, callback) table.insert(taskNames, name); callback() end}
local remote = fs.readFile("MainModule/Server/Core/Remote.luau")
start = assert(remote:find("\t\t\tRunScript = function", 1, true))
finish = assert(remote:find("\t\t\tPromptBulkPurchase = function", start, true))
local runScript = luau.load("return {" .. remote:sub(start, finish - 1) .. "}", {environment = env})().RunScript
for _, errorMode in {"syntax", "runtime", "explicit"} do
	mode = errorMode
	runScript(actor, {{"example"}})
	assert(outputs[#outputs].Message == (if mode == "syntax" then "Script syntax is invalid; details are unavailable." else "Script failed; details are unavailable."), "ScriptEditor exposed compilation or runtime error text")
end
assert(#taskNames == 3 and not serde.encode("json", taskNames):find(secret, 1, true), "ScriptEditor task metadata retained raw source text")
assert(not serde.encode("json", outputs):find(secret, 1, true), "Outbound error payload retained raw exception details")
assert(not serde.encode("json", audits):find(secret, 1, true), "Error audit retained raw exception details")
print("Command error contracts passed: fixed allowlist, bounded cooldown, Process/Admin/ScriptEditor sinks and audit metadata")
