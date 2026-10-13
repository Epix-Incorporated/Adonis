-- Run with `lune run Tests/Logging.spec.luau`; this exercises audit boundaries with isolated services.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local secret = "UNFILTERED_TEST_SECRET"
local checks = 0

-- Ensures both visible fields and otherwise hidden payload fields obey the redaction contract.
local function containsNoSecret(value)
	checks += 1
	assert(not serde.encode("json", value):find(secret, 1, true), "Unverified text escaped in an audit payload")
end

local persisted = {{Time = 1, Text = secret, Desc = secret, Player = {UserId = 17, Name = secret}}}
local server = {
	Settings = {UseLinkedListsInLogs = false, MaxLogs = 3, SaveCommandLogs = true, DataStoreEnabled = true},
	Data = {SilentStartup = true}, Commands = {Kick = {}}, Remote = {Commands = {ProcessCommand = true}, Returnables = {}},
	Core = {PlayerData = {}, UpdateData = function(key, callback)
		assert(key == "OldCommandLogs", "History moved to an unexpected datastore key")
		persisted = serde.decode("json", callback(persisted))
	end},
	TextPolicy = {GetRecordText = function(record)
		return if record.Trusted then "FILTERED_DETAIL" else nil
	end},
}
local warningType = {Name = "MessageWarning"}
local service = {
	Events = {LogAdded = {Fire = function() end}},
	RunService = {IsStudio = function() return false end, IsRunMode = function() return false end},
	HttpService = {JSONEncode = function(_, value) return serde.encode("json", value) end, JSONDecode = function(_, value) return serde.decode("json", value) end},
}
local env = setmetatable({script = {}, Enum = {MessageType = {GetEnumItems = function() return {warningType} end}}}, {__index = getfenv()})
local loader = luau.load(fs.readFile("MainModule/Server/Core/Logs.luau"), {environment = env})()
loader({Server = server, Service = service}, function() return env end)
server.Logs.Init()
local logs = server.Logs

logs.AddLog("Commands", {Text = secret, Desc = secret, Filter = secret, Extra = {secret}, Player = {UserId = 17, Name = secret}})
containsNoSecret(logs.Commands)
containsNoSecret(logs.Project(logs.Commands, "Commands"))
containsNoSecret(logs.Project(persisted, "Commands"))
assert(logs.Project(persisted, "Commands")[1].Player.UserId == 17, "Legacy numeric identity was lost")

logs.AddAudit("Commands", "Command", {UserId = 17}, {CommandKey = "Kick", TargetUserIds = {5, secret}, Outcome = "Completed", Raw = secret})
local projected = logs.Project(logs.Commands, "Commands")
assert(projected[1].Text:find("Kick", 1, true) and projected[1].Text:find("5", 1, true), "Safe operational details were lost")
containsNoSecret(projected)

logs.AddAudit("RemoteFires", "Remote", {UserId = 17}, {RemoteName = secret, Count = 3, Outcome = secret})
containsNoSecret(logs.RemoteFires)
logs.AddAudit("Script", "System", nil, {DetailRecord = {Kind = "Chat", Text = secret, Trusted = true}})
containsNoSecret(logs.Script)
logs.AddAudit("Script", "System", nil, {DetailRecord = {Kind = "Moderation", Version = 1, AuthorUserId = 17, Text = secret}})
containsNoSecret(logs.Script)
logs.AddAudit("Script", "System", nil, {DetailRecord = {Kind = "Moderation", Version = 1, AuthorUserId = 17, Text = secret, Hidden = secret, Trusted = true}})
containsNoSecret(logs.Script)
containsNoSecret(logs.ProjectConsole({{message = secret, messageType = warningType, timestamp = 12}}))
containsNoSecret(logs.ProjectTasks({{Name = secret, Function = secret, Status = secret, Created = 12}}))
assert(logs.ProjectConsole({{message = secret, messageType = warningType, timestamp = 12}})[1].Desc == "MessageWarning", "Console severity was discarded")

logs.SaveCommandLogs()
assert(#persisted == 3, "Array-backed logs must be saved as individual records alongside existing history")
assert(persisted[#persisted].Text == secret, "Existing datastore history must not be destructively rewritten")
containsNoSecret(logs.Project(persisted, "Commands"))
print(`Logging contracts passed: {checks}`)
