-- Run with `lune run Tests/CommandProvenance.spec.luau`; executes the checkout's parser functions.
-- Permission and engine services are isolated mocks; parser and provenance code are loaded verbatim.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local adminSource = fs.readFile("MainModule/Server/Core/Admin.luau")
local processSource = fs.readFile("MainModule/Server/Core/Process.luau")
local functionsSource = fs.readFile("MainModule/Server/Core/Functions.luau")
local aliases, observed, audits = {}, {}, {}
local commandLevel, commandNoLog, failCommand, pauseCommand
local now = 0
local settings = {SplitKey = " ", BatchKey = "|"}
local admin, process, functions = {}, {MsgStringLimit = 500}, {}
local players = {}
local actor = {Name = "Author", UserId = 1, Parent = players, IsA = function(_, name) return name == "Player" end}
local other = {Name = "Other", UserId = 2, Parent = players, IsA = actor.IsA}
local service = {
	UnWrap = function(value) return value end,
	Players = players,
	HttpService = {GenerateGUID = function() return "invocation" end},
	Events = {CommandRan = {Fire = function() end}},
	Trim = function(text) return text:match("^%s*(.-)%s*$") end,
	SanitizePattern = function(text) return text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") end,
}
local server = {Settings = settings}
local env = setmetatable({
	script = {}, server = server, service = service, Settings = settings,
	Admin = admin, Process = process, Functions = functions, Variables = {Aliases = {}},
	Core = {}, Logs = {AddAudit = function(category, event, auditActor, metadata)
		table.insert(audits, {Category = category, Event = event, Actor = auditActor, Metadata = metadata})
	end}, Remote = {MakeGui = function() end},
	AddLog = function() end,
	TrackTask = function(_, callback, onError, ...)
		local result = table.pack(pcall(callback, ...))
		if not result[1] then onError(result[2]) end
		return table.unpack(result, 1, result.n)
	end,
	typeof = function(value) return if value == actor or value == other then "Instance" else typeof(value) end,
	os = {clock = function() return now end},
}, {__index = getfenv()})

-- Selects exact source sections by stable surrounding declarations, avoiding copied implementations.
local function between(source, first, following)
	local start = assert(source:find(first, 1, true), `Missing declaration: {first}`)
	local finish = assert(source:find(following, start + #first, true), `Missing boundary: {following}`)
	return source:sub(start, finish - 1)
end

functions.Split = luau.load("return {" .. between(functionsSource, "\t\tSplit = function", "\t\tIsValidTexture = function") .. "}", {environment = env})().Split
functions.Trim = service.Trim
admin.GetArgs = luau.load("return {" .. between(adminSource, "\t\tGetArgs = function", "\t\tAliasFormat = function") .. "}", {environment = env})().GetArgs
local aliasHelpers = between(adminSource, "\tlocal function stripArgPlaceholders", "\tserver.Admin = {")
admin.AliasFormat = luau.load(aliasHelpers .. "\nreturn {" .. between(adminSource, "\t\tAliasFormat = function", "\t\tStringToComLevel = function") .. "}", {environment = env})().AliasFormat
admin.CheckAliasBlacklist = function() return false end
admin.GetAliases = function() return aliases end
admin.GetLevel = function() return 900 end
admin.CheckPermission = function() return true end
admin.CheckAdmin = function() return true end
admin.CheckDonor = function() return false end
admin.UpdateCooldown = function() end
admin.GetCommand = function(text)
	if text:match("^(%S+)") ~= ":pm" then return nil end
	return "PrivateMessage", {
		Args = {"player", "message"}, UserText = {Kind = "Chat", Args = {2}},
		AdminLevel = commandLevel, NoLog = commandNoLog,
		Function = function(_, args, data)
			if pauseCommand then coroutine.yield("pending command") end
			if failCommand then error("Unverified command failure", 0) end
			table.insert(observed, {Body = args[2], Allowed = data.ChatInput ~= nil})
		end,
	}, ":pm"
end
local transportLoader = luau.load(fs.readFile("MainModule/Server/Core/ChatTransport.luau"), {environment = env})()
transportLoader({Server = server, Service = service}, function() return env end)
process.GetOverrideMap = luau.load("return {" .. between(processSource, "\t\tGetOverrideMap = function", "\t\tCommand = function") .. "}", {environment = env})().GetOverrideMap
process.Command = luau.load("return {" .. between(processSource, "\t\tCommand = function", "\t\tCrossServerChat = function") .. "}", {environment = env})().Command

-- Runs an explicit or generated submission through the real command and alias parser.
local function submit(text, configuredAliases, options, executingPlayer)
	aliases, observed, audits = configuredAliases or {}, {}, {}
	options = options or {UserCommandOrigin = server.ChatTransport.NewOrigin(actor, text)}
	process.Command(executingPlayer or actor, text, options)
	return observed
end

assert(submit(":pm 2 hello world")[1].Allowed, "Literal command text was rejected")
assert(submit("!say 2 hello world", {["!say <who> <text>"] = ":pm <who> <text>"})[1].Allowed, "Alias placeholder lost authored provenance")
assert(not submit("!fixed 2 fixed", {["!fixed <who> <text>"] = ":pm <who> fixed"})[1].Allowed, "Matching text elsewhere blessed a hardcoded alias body")
assert(not submit("!mixed 2 hello", {["!mixed <who> <text>"] = ":pm <who> fixed <text>"})[1].Allowed, "Generated prefix was treated as user text")
local batch = submit("!batch 2 hello", {["!batch <who> <text>"] = ":pm <who> <text>|:pm <who> fixed"})
assert(#batch == 2 and batch[1].Allowed and not batch[2].Allowed, "Alias batch lost per-command byte provenance")
batch = submit(":pm 2 hello|:pm 2 hello")
assert(#batch == 2 and batch[1].Allowed and batch[2].Allowed, "Repeated literal batch text lost provenance")
assert(not submit(":pm 2 hello", nil, {})[1].Allowed, "Generated loop invocation received send authorization")
local origin = server.ChatTransport.NewOrigin(actor, ":pm 2 hello")
assert(not submit(":pm 2 hello", nil, {UserCommandOrigin = origin}, other)[1].Allowed, "Sudo impersonated the original author")
assert(not submit(":pm 2 hello", nil, {UserCommandOrigin = origin, OverrideArgs = {[2] = "hello"}})[1].Allowed, "Generated argument override was accepted")
assert(not submit(":pm 2 hello", nil, {UserCommandOrigin = origin, Args = {"2", "hello"}})[1].Allowed, "Externally supplied arguments were accepted")
now = 31
assert(not submit(":pm 2 hello", nil, {UserCommandOrigin = origin})[1].Allowed, "Expired author provenance was reused")

submit(":pm 2 hello")
assert(#audits == 2 and audits[1].Metadata.Outcome == "Accepted" and audits[2].Metadata.Outcome == "Completed", "Command outcomes did not distinguish admission from completion")
assert(audits[1].Actor == actor and audits[2].Metadata.CommandKey == "PrivateMessage", "Canonical command audit identity was lost")
for _, level in {"Players", "Donors", 0} do
	commandLevel = level
	submit(":pm 2 hello")
	assert(audits[1].Metadata.NoSave and audits[2].Metadata.NoSave, "Player/donor command outcomes became persistent")
end
commandLevel, commandNoLog = nil, true
submit(":pm 2 hello")
assert(#audits == 0, "NoLog command produced an outcome record")
commandNoLog = nil
submit(":pm 2 hello", nil, {UserCommandOrigin = server.ChatTransport.NewOrigin(actor, ":pm 2 hello"), DontLog = true})
assert(#audits == 0, "DontLog command produced an outcome record")
submit(":pm 2 hello", nil, {UserCommandOrigin = server.ChatTransport.NewOrigin(actor, ":pm 2 hello"), isSystem = true}, other)
assert(audits[1].Actor == actor and audits[2].Actor == actor, "Sudo audit impersonated its execution identity")
pauseCommand = true
local pending = coroutine.create(function() submit(":pm 2 hello") end)
local resumed, state = coroutine.resume(pending)
assert(resumed and state == "pending command" and #audits == 1 and audits[1].Metadata.Outcome == "Accepted", "A yielding command was audited as complete before it returned")
assert(coroutine.resume(pending) and #audits == 2 and audits[2].Metadata.Outcome == "Completed", "Completion was not recorded after the yielding command returned")
pauseCommand, failCommand = nil, true
server.TextPolicy = {ProjectCommandError = function() return "Command failed; details are unavailable." end}
submit(":pm 2 hello")
assert(#audits == 3 and audits[2].Metadata.Outcome == "Failed" and audits[3].Category == "Errors", "A failed command was audited as completed")
print("Command provenance contracts passed: literal, alias, batch, generated, override, sudo, expiry and audit outcomes")
