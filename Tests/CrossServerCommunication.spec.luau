-- Exercises actual cross-server handlers with an isolated bus; no Roblox services or network calls run.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local secret = "PRIVATE_CROSS_SERVER_MESSAGE"
local unsupported = "Cross-server player messages are not supported; send the message in the current server."
local now, sequence, filterCalls = 0, 0, 0
local packets, executions, displays, deferred = {}, {}, {}, {}
local actor = {UserId = 101, Name = "Actor", DisplayName = "Actor", AccountAge = 100}
actor.IsA = function(_, class) return class == "Player" end
local service = {
	UnWrap = function(value) return value end,
	GetPlayers = function() return {actor} end,
	FormatPlayer = function() return "User 101" end,
	Queue = function(_, callback) callback() end,
	Players = {GetPlayers = function() return {actor} end, GetPlayerByUserId = function(_, id) return id == actor.UserId and actor or nil end},
	HttpService = {GenerateGUID = function() sequence += 1; return `publication-{sequence}` end},
	TryFilter = function(text) filterCalls += 1; return `filtered:{text}` end,
	MessagingService = {
		PublishAsync = function(_, topic, data) table.insert(packets, {Topic = topic, Data = data}) end,
		SubscribeAsync = function() return {Disconnect = function() end} end,
	},
	Threads = {Tasks = {}, NewTask = function(_, callback) return callback, {R_Status = "Running"} end},
}
local settings = {Prefix = ":", PlayerPrefix = "!", SplitKey = " ", BatchKey = "|", LocalDatastore = true, CrossServerCommands = true}
local commands, core, admin = {}, {CrossServerCommands = {}, SubEvent = true, DataStoreEncode = function(value) return value end}, {}
local functions = {
	GetFakePlayer = function(value) return table.clone(value) end,
	Trim = function(value) return value:match("^%s*(.-)%s*$") end,
	Message = function(...) table.insert(displays, {...}) end,
	Hint = function(text) table.insert(displays, {Name = "Hint", Text = text}) end,
	LogAdminAction = function() end,
}
-- Uses the production parser so compatibility checks include quotation and final-argument behavior.
local splitSource = assert(fs.readFile("MainModule/Server/Core/Functions.luau"):match("\n\t\tSplit = (function.-\n\t\tend);"))
functions.Split = luau.load(`return {splitSource}`)()
admin.GetLevel = function() return 900 end
admin.RunCommand = function(command, reason) table.insert(executions, {Text = command, Reason = reason}) end
admin.GetCommand = function(value)
	if type(value) ~= "string" then return nil end
	local token = value:match("^(%S+)")
	for key, definition in commands do
		for _, name in definition.Commands do
			if token and token:lower() == definition.Prefix .. name then return key, definition, token end
		end
	end
end
local server = {
	Settings = settings, Commands = commands, Admin = admin, Functions = functions, Core = core,
	Variables = {IsStudio = true}, MatIcons = {},
	Logs = {AddLog = function() end, TempUpdaters = {}},
	Remote = {
		MakeGui = function(_, name, data) table.insert(displays, {Name = name, Data = data}) end,
		GetGui = function(_, name, data)
			table.insert(displays, {Name = name, Data = data})
			return data.Answers and data.Answers[1] or "Yes"
		end,
	},
	Process = {Command = function(player, text, options) table.insert(executions, {Player = player, Text = text, Options = options}) end},
}
local env = setmetatable({
	game = {JobId = "fixture-origin"}, os = {clock = function() return now end},
	typeof = function(value) return value == actor and "Instance" or typeof(value) end,
	task = {defer = function(callback) table.insert(deferred, callback) end, delay = function() end, wait = function(seconds) return seconds end},
}, {__index = getfenv()})
luau.load(fs.readFile("MainModule/Server/Core/TextPolicy.luau"), {environment = env})()({Server = server, Service = service})
local policy = server.TextPolicy
local headAdmins = luau.load(fs.readFile("MainModule/Server/Commands/HeadAdmins.luau"), {environment = env})()({Server = server, Service = service})
for key, definition in headAdmins do commands[key] = definition end
commands.Speed = {Prefix = ":", Commands = {"speed", "ws"}, Args = {"player", "speed"}}
commands.ForcePlace = {Prefix = ":", Commands = {"forceplace"}, Args = {"player", "placeId"}}
commands.Repeat = {Prefix = ":", Commands = {"repeat", "loop"}, Args = {"amount", "interval", "command"}}
commands.ChatMessage = {Prefix = ":", Commands = {"m"}, Args = {"message"}, UserText = {Kind = "Chat", Args = {1}}}
commands.LegacyMessage = {Prefix = ":", Commands = {"oldm"}, Args = {"message"}, UserText = {Kind = "Announcement", Audience = "Broadcast", Args = {1}}}
commands.SharedLabel = {Prefix = ":", Commands = {"label"}, Args = {"text"}, UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {1}}}
commands.Shutdown = {Prefix = ":", Commands = {"shutdown"}, Args = {"reason"}, UserText = {Kind = "Moderation", Audience = "Broadcast", Args = {1}}}
luau.load(fs.readFile("MainModule/Server/Plugins/Cross_Server.luau"), {environment = env})()({Server = server, Service = service})
local handlers = core.CrossServerCommands
local count = 0

-- Models older receivers that dispatch only the command string and ignore extra packet arguments.
local function legacyReceive(jobId, plrData, comString)
	local _, command = admin.GetCommand(comString)
	if command and command.UserText then return end
	server.Process.Command(functions.GetFakePlayer(plrData), comString, {
		AdminLevel = plrData.AdminLevel,
		CrossServer = true,
	})
end

-- Executes the real lock command with the same argument selection used by Process.Command.
local lockSource = assert(fs.readFile("MainModule/Server/Commands/Admins.luau"):match("\n\t\tServerLock = ({.-\n\t\t});"))
commands.ServerLock = luau.load(`return {lockSource}`, {environment = setmetatable({
	Settings = settings, Variables = server.Variables, Functions = functions, service = service,
}, {__index = env})})()

-- Reports each independent boundary assertion without swallowing the original failure.
local function check(name, callback)
	table.clear(packets); table.clear(executions); table.clear(displays)
	callback()
	count += 1
	print(`PASS {name}`)
end

-- Builds a trusted non-chat record so tests also cover formerly accepted typed announcements.
local function publication(kind, key, text)
	return assert(policy.CreatePublication({[key] = assert(policy.CreateRecord(text, actor, kind))}))
end

check("global message commands reject without publishing their bodies", function()
	for _, entry in {{"GlobalMessage", {secret}, 1}, {"GlobalTimeMessage", {"5", secret}, 2}} do
		local definition = commands[entry[1]]
		local ok, err = pcall(definition.Function, actor, entry[2], {UserTextRecords = {[entry[3]] = policy.CreateRecord(secret, actor, "Announcement")}})
		assert(not ok and tostring(err):find(unsupported, 1, true), "Global announcements need fixed unsupported feedback")
		assert(definition.UserText.Kind == "Chat", "Global message bodies must remain native-command chat sinks")
	end
	assert(#packets == 0 and #displays == 0, "A rejected global message reached the bus or UI")
end)

check("legacy announcement and conversation bus routes cannot display or publish", function()
	local record = publication("Announcement", "Message", secret)
	handlers.Message("old-server", "Actor", record, 10)
	handlers.ServerChat("old-server", actor, secret)
	assert(not core.CrossServer("Message", "Actor", record), "Legacy Message must be rejected before queueing")
	assert(not core.CrossServer("ServerChat", actor, secret), "Legacy ServerChat must be rejected before queueing")
	assert(#displays == 0 and #packets == 0, "A retired cross-server route relayed conversation")
end)

check("chat, legacy announcements, aliases, batches and nested repeats cannot be forwarded", function()
	for _, text in {":m " .. secret, ":oldm " .. secret, ":unknown " .. secret, ":speed all 20|:m " .. secret, ":repeat 2 1 :m " .. secret, ":gm " .. secret} do
		local ok = pcall(commands.CrossServer.Function, actor, {text})
		assert(not ok, "Unsupported command strings require fixed failure feedback")
		assert(not core.CrossServer("NewRunCommand", actor, text), "Direct raw forwarding bypassed validation")
		handlers.NewRunCommand("old-server", actor, text)
	end
	assert(#packets == 0 and #executions == 0, "Unsupported command content reached the bus or executor")
end)

check("operational packets retain arguments for legacy and structured receivers", function()
	commands.CrossServer.Function(actor, {"  :ws all 24  "})
	assert(#packets == 1, "Operational commands should still publish")
	local data = packets[1].Data
	assert(data[2] == "NewRunCommand" and data[4] == ":speed all 24", "Legacy receivers need the complete canonical command")
	assert(data[5][1] == "all" and data[5][2] == "24", "Positional operational arguments were lost")
	handlers.NewRunCommand("remote", data[3], data[4], data[5])
	assert(executions[1].Text == ":speed" and executions[1].Options.Args[2] == "24", "Destination must execute the parsed arguments without reparsing text")
	legacyReceive(data[1], table.unpack(data, 3))
	assert(executions[2].Text == ":speed all 24" and executions[2].Options.Args == nil, "Legacy dispatch lost positional arguments")
	assert(core.CrossServer("NewRunCommand", actor, ":forceplace all 123"), "GlobalPlace's existing caller must remain supported")
	assert(packets[2].Data[4] == ":forceplace all 123" and packets[2].Data[5][2] == "123", "Raw operational callers must use the same compatible transport")
end)

check("unlock commands keep their meaning in mixed-version servers", function()
	commands.CrossServer.Function(actor, {":slock off"})
	local data = packets[1].Data
	for _, receiver in {legacyReceive, handlers.NewRunCommand} do
		table.clear(executions)
		receiver("remote", data[3], data[4], data[5])
		local dispatched = assert(executions[1], "The receiver did not dispatch the command")
		local argumentString = dispatched.Text:match(`^.-{settings.SplitKey}(.+)`) or ""
		local args = dispatched.Options.Args or functions.Split(argumentString, settings.SplitKey, #commands.ServerLock.Args)
		for _, initiallyLocked in {false, true} do
			server.Variables.ServerLock = initiallyLocked
			commands.ServerLock.Function(actor, args)
			assert(server.Variables.ServerLock == false, "An unlock command became a toggle on a legacy receiver")
		end
	end
	-- Incoming legacy strings and earlier structured packets remain accepted by updated receivers.
	handlers.NewRunCommand("old-server", actor, ":serverlock off")
	assert(executions[#executions].Text == ":slock" and executions[#executions].Options.Args[1] == "off", "Incoming legacy commands lost their arguments")
	handlers.NewRunCommand("structured-server", actor, ":slock", {"off"})
	assert(executions[#executions].Text == ":slock" and executions[#executions].Options.Args[1] == "off", "Earlier structured packets no longer dispatch correctly")
end)

check("compatible serialization preserves parsed text and rejects changed arguments", function()
	for _, text in {":ws all 24", ":ws all value with spaces", ':ws "all players" 24', ":slock"} do
		commands.CrossServer.Function(actor, {text})
		local packet = packets[#packets].Data
		local _, definition = admin.GetCommand(packet[4])
		local legacyArgs = functions.Split(packet[4]:match(`^.-{settings.SplitKey}(.+)`) or "", settings.SplitKey, #definition.Args)
		assert(serde.encode("json", legacyArgs) == serde.encode("json", packet[5]), "Legacy parsing changed submitted arguments")
	end
	assert(core.CrossServer("NewRunCommand", actor, ":speed", {"all", "24"}), "Representable structured arguments should still publish")
	local publishedCount = #packets
	for _, args in {{[2] = "off"}, {"", "24"}, {"all players", "24"}, {"all", "24 "}, {"all", "24|:m injected"}, {'"all"', "24"}} do
		assert(not core.CrossServer("NewRunCommand", actor, ":speed", args), "Lossy or executable argument serialization must be rejected")
	end
	assert(#packets == publishedCount, "Rejected arguments reached the messaging bus")
end)

check("published commands allow public edits and moderation but never announcements", function()
	for _, key in {"ChatMessage", "LegacyMessage", "GlobalMessage"} do
		handlers.RunPublishedCommand("remote", actor, key, {secret}, publication("Announcement", "1", secret))
		assert(not core.CrossServer("RunPublishedCommand", actor, key, {secret}, publication("Announcement", "1", secret)), "Outgoing published chat was accepted")
	end
	assert(#executions == 0 and #packets == 0, "Typed announcement records bypassed the chat transport requirement")
	for _, entry in {{"SharedLabel", "PublicEdit"}, {"Shutdown", "Moderation"}} do
		handlers.RunPublishedCommand("remote", actor, entry[1], {secret}, publication(entry[2], "1", "safe detail"))
		local executed = executions[#executions]
		assert(executed and executed.Options.Args[1] == "filtered:safe detail" and executed.Options.TextPublication, "Allowed records must retain authenticated publication binding")
	end
	assert(#executions == 2, "Public edits or moderation were disabled")
end)

check("poll publication keeps filtering, shared edit admission, and accepted answer records", function()
	local poll = commands.CrossServerVote
	policy.WrapCommand(poll, "CrossServerVote")
	local before = filterCalls
	poll.Function(actor, {"yes,no", "poll question"})
	assert(filterCalls >= before + 3 and #packets == 1, "Poll fields must still use the filter pipeline")
	local data = packets[1].Data[3]
	assert(data.Publication.Records.Question.Kind == "PublicEdit" and data.AnswerCount == 2, "Poll must keep its non-chat publication schema")
	assert(not serde.encode("json", data):find('"poll question"', 1, true), "Poll question was published without the filter result")
	local ok, err = pcall(poll.Function, actor, {"yes,no", "another question"})
	assert(not ok and tostring(err):find("Wait 60 seconds", 1, true), "Polls must retain the shared edit cooldown")
	now = 60
	poll.Function(actor, {"yes,no", "accepted question"})
	assert(#packets == 2, "The edit cooldown must permit a new poll at 60 seconds")
	local start = #deferred
	handlers.CrossServerVote("remote", data)
	assert(#deferred == start + 1, "Accepted polls should reach the local voter")
	deferred[#deferred]()
	assert(displays[#displays].Name == "Vote" and displays[#displays].Data.Question == "filtered:poll question", "The voter must receive only accepted filtered fields")
end)

check("global restart progress never broadcasts the moderator's reason", function()
	for _, countdown in {false, 2, 61} do
		handlers.GlobalRestartRequest("remote", publication("Moderation", "Reason", secret), countdown, true)
		assert(executions[#executions].Reason == "filtered:" .. secret, "Restart must retain its accepted moderation reason")
	end
	assert(#executions == 3 and #displays > 3, "Immediate and countdown restart branches were not exercised")
	for _, display in displays do
		assert(display.Name == "Hint" and not display.Text:find(secret, 1, true), "A progress announcement relayed the moderator's reason")
	end
end)

print(`Cross-server communication: {count} assertion groups passed`)
