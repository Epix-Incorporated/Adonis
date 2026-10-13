-- Executes the real filtering and policy functions with deterministic engine-service substitutes.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local task = require("@lune/task")
local now = 0
local calls = 0
local failure = false
local outputFailure = false
local suspend = false
local nextId = 0
local online = {}
local service = {}
local author = {UserId = 101, IsA = function(_, class) return class == "Player" end}
local recipient = {UserId = 202, IsA = author.IsA}
online[101], online[202] = author, recipient

-- Identifies only the mock objects that represent actual engine players.
local function mockType(value)
	return if value == author or value == recipient then "Instance" else typeof(value)
end

service.UnWrap = function(value) return value end
service.Players = {GetPlayerByUserId = function(_, id) return online[id] end}
service.HttpService = {GenerateGUID = function() nextId += 1; return `publication-{nextId}` end}
service.ExtractLines = function(text) return string.split(text, "\n") end
service.TextService = {
	-- Produces different audience results and can pause inside the actual yielding filter seam.
	FilterStringAsync = function(_, text, userId)
		calls += 1
		assert(userId == author.UserId, "Filtering must use the real originating author")
		if suspend then coroutine.yield("filter pending") end
		if failure then error("backend failure contains untrusted source") end
		return {
			GetNonChatStringForBroadcastAsync = function()
				if outputFailure then error("broadcast conversion failed with private source") end
				return `public:{text}`
			end,
			GetNonChatStringForUserAsync = function(_, id)
				if outputFailure then error("recipient conversion failed with private source") end
				return `recipient-{id}:{text}`
			end,
		}
	end,
}
local env = {
	service = service,
	typeof = mockType,
	Enum = {TextFilterContext = {PublicChat = "PublicChat"}},
	os = {clock = function() return now end},
	task = task,
}
local sharedSource = fs.readFile("MainModule/Shared/Service.luau")
local filterSource = assert(sharedSource:match("TryFilter = (function.-\n\t\tend);"), "Missing shared filter implementation")
service.TryFilter = luau.load(`return {filterSource}`, {environment = env})()
local server = {}
luau.load(fs.readFile("MainModule/Server/Core/TextPolicy.luau"), {environment = env})()({Server = server, Service = service})
local policy = server.TextPolicy
local count = 0

-- Runs one named assertion group and annotates failures without hiding their original stack.
local function check(name, callback)
	callback()
	count += 1
	print(`PASS {name}`)
end

check("whole multiline and numeric text are actually filtered", function()
	local before = calls
	assert(policy.FilterBroadcast("12345\nsecond line", author) == "public:12345\nsecond line", "Multiline numeric text must use broadcast filtering")
	assert(calls == before + 1, "Whole text must use exactly one filter request")
	assert(policy.FilterForUser("hello", author, recipient) == "recipient-202:hello", "Recipient text must use the recipient conversion")
end)

check("invalid authors, receivers, and UTF-8 fail without filtering", function()
	local before = calls
	assert(policy.FilterBroadcast("raw", {UserId = 101}) == nil, "Fabricated authors must be rejected")
	assert(policy.FilterForUser("raw", author, {}) == nil, "Invalid recipients must be rejected")
	assert(policy.FilterBroadcast(string.char(255), author) == nil, "Malformed UTF-8 must be rejected")
	assert(calls == before, "Invalid inputs must not reach the filter service")
end)

check("filter failures never return source text or backend details", function()
	failure = true
	local value, code = policy.FilterBroadcast("private raw source", author)
	assert(value == nil and code == "FilterUnavailable", "Filter failures must return the fixed unavailable code")
	failure = false
end)

check("safe records retain real authorship and distinguish storage from live trust", function()
	local record = assert(policy.CreateRecord("note", author, "Audit"), "An approved audit record must be created")
	assert(record.Text == "public:note" and record.AuthorUserId == author.UserId and record.Kind == "Audit", "Records must contain filtered text and original author identity")
	assert(not pcall(function() record.Text = "raw replacement" end), "Trusted records must be immutable")
	online[101] = nil
	assert(policy.GetRecordText(record) == "public:note", "Trusted session records must survive author departure")
	assert(policy.GetRecordText(table.clone(record)) == nil, "Serialized records must be unavailable while the author is offline")
	assert(policy.ProjectRecord("legacy raw note") == nil, "Legacy raw notes must not project")
	online[101] = author
	assert(policy.ProjectRecord(table.clone(record)) == "public:public:note", "Persisted records must be freshly filtered with their online author")
	assert(policy.CreateRecord("chat", author, "Chat") == nil, "Conversational text must not create nonchat records")
end)

check("both second-stage filter conversions fail closed", function()
	outputFailure = true
	local broadcast, broadcastCode = policy.FilterBroadcast("private raw source", author)
	local personal, personalCode = policy.FilterForUser("private raw source", author, recipient)
	assert(broadcast == nil and broadcastCode == "FilterUnavailable", "Broadcast conversion failures must return no text")
	assert(personal == nil and personalCode == "FilterUnavailable", "Recipient conversion failures must return no text")
	assert(policy.CreateRecord("private raw source", author, "PublicEdit") == nil, "Failed conversions must not create records")
	outputFailure = false
end)

check("direct command calls share one sixty-second allowance across surfaces", function()
	local output = {}
	local commandA = {UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {2}}, Function = function(_, args) table.insert(output, args[2]) end}
	local commandB = {UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {1}}, Function = function(_, args) table.insert(output, args[1]) end}
	policy.WrapCommand(commandA)
	policy.WrapCommand(commandB)
	commandA.Function(author, {"all", "123"})
	assert(output[1] == "public:123", "Public edits must filter their displayed arguments")
	assert(not pcall(commandB.Function, author, {"other surface"}), "Shared admission must reject a different surface within the same minute")
	now = 59.999
	assert(not pcall(commandB.Function, author, {"too soon"}), "Admission must reject edits before the full minute expires")
	now = 60
	commandB.Function(author, {"boundary"})
	assert(output[2] == "public:boundary", "Admission must accept edits at the exact minute boundary")
end)

check("cooldown is reserved before a yielding filter and cannot race", function()
	now = 120
	suspend = true
	local command = {UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {1}}, Function = function(_, args) return args[1] end}
	policy.WrapCommand(command)
	local pending = coroutine.create(function() return command.Function(author, {"first"}) end)
	local ok, status = coroutine.resume(pending)
	assert(ok and status == "filter pending", "The first filter request must yield")
	assert(not pcall(command.Function, author, {"concurrent"}), "A yielded filter must retain its admission reservation")
	suspend = false
	local resumed, output = coroutine.resume(pending)
	assert(resumed and output == "public:first", "The admitted request must resume with filtered text")
end)

check("non-chat audit records do not consume edit admission and moderation survives outages", function()
	local command = {UserText = {Kind = "Audit", Audience = "Broadcast", Args = {1}}, Function = function(_, args) return args[1] end}
	policy.WrapCommand(command)
	assert(command.Function(author, {"one"}) == "public:one", "Audit details must publish filtered text")
	assert(command.Function(author, {"two"}) == "public:two", "Audit details must not consume the shared public edit allowance")
	failure = true
	assert(not pcall(command.Function, author, {"failed audit detail"}), "Failed audit filtering must suppress publication")
	local moderation = {UserText = {Kind = "Moderation", Audience = "Broadcast", Args = {2}}, Function = function(_, args) return args[2] end}
	policy.WrapCommand(moderation)
	assert(moderation.Function(author, {"target", "secret reason"}) == "Reason unavailable", "Moderation must retain its action with a fixed unavailable reason")
	failure = false
end)

check("parser controls can remove text during cooldown and arguments remain unmodified", function()
	local command = {UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {2}, ExemptValues = {[2] = {off = true}}}, Function = function(_, args) return args[2] end}
	policy.WrapCommand(command)
	local args = {"target", "off"}
	assert(command.Function(author, args) == "off" and args[2] == "off", "Control arguments must retain their parser values")
	local chat = {UserText = {Kind = "Chat", Args = {2}}, Function = function(_, values) return values[2] end}
	policy.WrapCommand(chat)
	assert(chat.Function(author, {"target", "raw typed chat"}) == "raw typed chat", "Chat input must remain raw until the channel transport handles it")
end)

check("server publications reject forged local records and duplicate deliveries", function()
	local record = assert(policy.CreateRecord("audit detail", author, "Audit"), "A valid audit record must be created")
	assert(policy.CreatePublication({Message = table.clone(record)}) == nil, "Copied records must not gain origin publication trust")
	local publication = assert(policy.CreatePublication({Message = record}), "Trusted records must create a publication")
	local received = assert(policy.AcceptPublication("origin-server", publication), "A valid origin publication must be accepted")
	assert(policy.GetRecordText(received.Message) == record.Text, "Accepted publications must preserve their safe snapshot")
	local duplicate, code = policy.AcceptPublication("origin-server", publication)
	assert(duplicate == nil and code == "DuplicatePublication", "Repeated publication identifiers must be rejected")
	assert(policy.AcceptPublication("origin-server", {Version = 1, Id = "bad", Records = {Message = "raw"}}) == nil, "Raw publication records must be rejected")
end)

check("a published command requires a private exact-invocation authorization", function()
	local command = {UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {1}}, Function = function(_, args, data) return args[1], data.UserTextRecords[1] end}
	policy.WrapCommand(command)
	local record = assert(policy.CreateRecord("name", author, "PublicEdit"), "A valid public edit record must be created")
	local received = assert(policy.AcceptPublication("origin-server", assert(policy.CreatePublication({["1"] = record}), "A trusted public edit must create a publication")), "A valid public edit publication must be accepted")
	local fake = {UserId = author.UserId}
	local token, args = policy.AuthorizePublishedCommand(command, fake, {"untrusted packet text"}, received)
	local result, saved = command.Function(fake, args, {Options = {TextPublication = token}})
	assert(result == record.Text and saved == received["1"], "Published command arguments must match the authorized record")
	assert(not pcall(command.Function, fake, args, {Options = {TextPublication = token}}), "A consumed publication capability must not be replayed")
end)

check("undeclared helper text uses a yielding command author without context leaks", function()
	local nested = {Function = function() error("nested failure", 0) end}
	policy.WrapCommand(nested)
	local command = {Function = function()
		assert(not pcall(nested.Function, recipient, {}), "The nested command must fail as arranged")
		return policy.GetPublicationText("12345")
	end}
	policy.WrapCommand(command)
	suspend = true
	local pending = coroutine.create(function() return command.Function(author, {}) end)
	local ok, status = coroutine.resume(pending)
	assert(ok and status == "filter pending", "The helper filter must yield within its command context")
	assert(policy.GetPublicationText("system outside suspended invocation") == "system outside suspended invocation", "Suspended command context must not leak into another coroutine")
	suspend = false
	local resumed, output = coroutine.resume(pending)
	assert(resumed and output == "public:12345", "The resumed helper must use its command author")
	assert(policy.GetPublicationText("system after completion") == "system after completion", "Completed command context must be cleared")
	assert(not pcall(nested.Function, author, {}), "The nested failure must propagate")
	assert(policy.GetPublicationText("system after error") == "system after error", "Failed command context must be cleared")
end)

check("nested prepared arguments are reusable only during their original invocation", function()
	now = 240
	local savedArgs, savedData
	local depth = 0
	local command = {UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {1}}}
	command.Function = function(player, args, data)
		savedArgs, savedData = args, data
		if depth == 0 then
			depth += 1
			return command.Function(player, args, data)
		end
		return args[1]
	end
	policy.WrapCommand(command)
	assert(command.Function(author, {"label"}) == "public:label", "Recursive prepared calls must reuse the safe argument")
	assert(not pcall(command.Function, author, savedArgs, savedData), "Completed invocation was replayed without admission")
end)

check("actual publication helpers filter title and body with legacy arity preserved", function()
	local displayed = {}
	local helperEnv = table.clone(env)
	helperEnv.server = server
	helperEnv.Core = {GetSettingText = function() return "System Message" end}
	helperEnv.Remote = {
		MakeGui = function(_, _, data) table.insert(displayed, data) end,
		RemoveGui = function() end,
	}
	helperEnv.task = {defer = function(callback) callback() end}
	local source = fs.readFile("MainModule/Server/Core/Functions.luau")
	local helpers = {}
	for _, name in {"Hint", "Message", "Notify", "Notification"} do
		local implementation = assert(source:match(`{name} = (function.-\n\t\tend);`), "Missing helper implementation")
		helpers[name] = luau.load(`return {implementation}`, {environment = helperEnv})()
	end
	local command = {Function = function()
		helpers.Hint("raw hint", {recipient}, nil, 123)
		helpers.Message("legacy title", "legacy body", {recipient}, false, 5)
		helpers.Notify("notify title", "notify body", {recipient})
		helpers.Notification("notification title", "notification body", {recipient}, nil, "rbxassetid://1")
	end}
	policy.WrapCommand(command)
	command.Function(author, {})
	assert(displayed[1].Title == "public:123" and displayed[1].Message == "public:raw hint", "Hint must filter its numeric title and message")
	assert(displayed[2].Title == "public:legacy title" and displayed[2].Message == "public:legacy body" and displayed[2].Time == 5, "Legacy Message arguments must preserve title, body and duration")
	assert(displayed[3].Title == "public:notify title" and displayed[3].Message == "public:notify body", "Notify must filter its title and message")
	assert(displayed[4].Title == "public:notification title" and displayed[4].Message == "public:notification body", "Notification must filter its title and message")
	local record = assert(policy.CreateRecord("record body", author, "Audit"), "A valid explicit audit record must be created")
	helpers.Hint(record.Text, {recipient}, nil, nil, nil, record)
	assert(displayed[5].Message == "public:record body", "Explicit body records must preserve their safe snapshot")
	failure = true
	helpers.Notify("secret title", "secret body", {recipient}, nil, author)
	assert(displayed[6].Title == "Text unavailable" and displayed[6].Message == "Text unavailable", "Explicit helper filter failures must use fixed placeholders")
	failure = false
	helpers.Hint("explicit hint", {recipient}, nil, 456, nil, author)
	assert(displayed[7].Title == "public:456" and displayed[7].Message == "public:explicit hint", "Explicit Hint authors must filter numeric titles and messages")
	helpers.Message(nil, "explicit title", "explicit body", nil, {recipient}, false, 5, author)
	assert(displayed[8].Title == "public:explicit title" and displayed[8].Message == "public:explicit body", "Explicit Message authors must filter titles and messages")
end)

check("the actual note command stores only safe records and shares edit admission", function()
	now = 300
	local source = fs.readFile("MainModule/Server/Commands/Admins.luau")
	local definition = assert(source:match("\n\t\tNote = {(.-)\n\t\t};"), "Missing note definition")
	local metadata = assert(definition:match("UserText = ([^\n]+);"), "Missing note metadata")
	local implementation = assert(definition:match("Function = (function.-\n\t\t\tend)"), "Missing note handler")
	local playerData = {}
	local noteEnv = table.clone(env)
	noteEnv.service = table.clone(service)
	noteEnv.service.GetPlayers = function() return {recipient} end
	noteEnv.service.FormatPlayer = function() return "Recipient" end
	noteEnv.Core = {GetPlayer = function() return playerData end, SavePlayer = function() end}
	noteEnv.Functions = {Hint = function() end}
	local command = {UserText = luau.load(`return {metadata}`)(), Function = luau.load(`return {implementation}`, {environment = noteEnv})()}
	policy.WrapCommand(command, "Note")
	command.Function(author, {"target", "raw note"})
	assert(#playerData.AdminNotes == 1 and playerData.AdminNotes[1].Text == "public:raw note", "Note must store only its filtered record")
	assert(playerData.AdminNotes[1].Kind == "PublicEdit" and playerData.AdminNotes[1].AuthorUserId == author.UserId, "Note records must retain public edit kind and original author")
	assert(not policy.TryPublicEdit(author), "A note did not consume the shared public edit allowance")
	assert(not pcall(command.Function, author, {"target", "second note"}) and #playerData.AdminNotes == 1, "A second note within the minute must not be stored")
end)

check("non-chat metadata requires an explicit broadcast-safe filtering audience", function()
	local before = calls
	assert(not pcall(policy.PrepareArguments, author, {"raw"}, {Kind = "Audit", Args = {1}}), "Missing audience metadata must be rejected")
	assert(not pcall(policy.PrepareArguments, author, {"raw"}, {Kind = "Audit", Audience = "SelectedPlayers", Args = {1}}), "Unsupported audience metadata must be rejected")
	assert(calls == before, "Invalid audience reached the filtering service")
	local declarations = 0
	for _, path in {
		"MainModule/Server/Commands/Admins.luau", "MainModule/Server/Commands/Creators.luau",
		"MainModule/Server/Commands/HeadAdmins.luau", "MainModule/Server/Commands/Moderators.luau",
		"MainModule/Server/Plugins/Cross_Server.luau", "MainModule/Server/Plugins/Server-SoftShutdown.luau",
	} do
		for line in fs.readFile(path):gmatch("[^\n]+") do
			local kind = line:match('UserText = {Kind = "([^"]+)"')
			if kind and kind ~= "Chat" then
				declarations += 1
				assert(line:find('Audience = "Broadcast"', 1, true), `Missing broadcast audience in {path}`)
			end
		end
	end
	assert(declarations > 0, "The first-party non-chat command inventory was not loaded")
end)

check("actual sudo preserves the original author without changing execution identity", function()
	now = 360
	author.Parent, recipient.Parent = service.Players, service.Players
	local transportEnv = setmetatable(table.clone(env), {__index = getfenv()})
	transportEnv.script = {}
	luau.load(fs.readFile("MainModule/Server/Core/ChatTransport.luau"), {environment = transportEnv})()({Server = server, Service = service}, function() return transportEnv end)
	local queued = {}
	local sudoEnv = table.clone(env)
	sudoEnv.service = table.clone(service)
	sudoEnv.service.GetPlayers = function() return {recipient} end
	sudoEnv.task = {defer = function(callback, ...) table.insert(queued, {Callback = callback, Args = table.pack(...)}) end}
	local received
	local command = {UserText = {Kind = "PublicEdit", Audience = "Broadcast", Args = {1}}, Function = function(actor, args, data)
		received = {Actor = actor, Text = args[1], Record = data.UserTextRecords[1], Helper = policy.GetPublicationText("helper text", actor)}
	end}
	policy.WrapCommand(command)
	sudoEnv.Process = {Command = function(actor, text, options) command.Function(actor, {text}, {Options = options}) end}
	local source = fs.readFile("MainModule/Server/Commands/Creators.luau")
	local definition = assert(source:match("\n\t\tSudo = {(.-)\n\t\t};"), "Missing sudo definition")
	local implementation = assert(definition:match("Function = (function.-\n\t\t\tend)"), "Missing sudo handler")
	local sudo = {Function = luau.load(`return {implementation}`, {environment = sudoEnv})()}
	policy.WrapCommand(sudo)
	local origin = server.ChatTransport.NewOrigin(author, ":sudo target shared label")
	assert(server.ChatTransport.ResolveOriginAuthor(origin) == author, "A valid private origin must resolve its actual author")
	assert(server.ChatTransport.ResolveOriginAuthor({Player = author}) == nil, "A serialized identity forged an origin")
	sudo.Function(author, {"target", "shared label"}, {Options = {UserCommandOrigin = origin}})
	queued[1].Callback(table.unpack(queued[1].Args, 1, queued[1].Args.n))
	assert(received.Actor == recipient and received.Record.AuthorUserId == author.UserId, "Sudo must preserve execution actor and original text author")
	assert(received.Text == "public:shared label" and received.Helper == "public:helper text", "Sudo arguments and helper text must use the original author")
	assert(not policy.TryPublicEdit(author), "Sudo did not consume the original author's allowance")
	assert(policy.TryPublicEdit(recipient), "Sudo consumed the execution target's allowance")
	local published = false
	local audit = {UserText = {Kind = "Audit", Audience = "Broadcast", Args = {1}}, Function = function() published = true end}
	policy.WrapCommand(audit)
	now = 421
	local before = calls
	assert(server.ChatTransport.ResolveOriginAuthor(origin) == nil, "Expired origins must not resolve an author")
	assert(not pcall(audit.Function, recipient, {"raw"}, {Options = {isSystem = true, UserCommandOrigin = origin}}), "Expired sudo origins must suppress audit text")
	assert(not pcall(command.Function, recipient, {"raw"}, {Options = {isSystem = true}}), "System commands without origins must suppress public edits")
	assert(not published and calls == before, "Missing or expired provenance reached publication or filtering")
	local moderation = {UserText = {Kind = "Moderation", Audience = "Broadcast", Args = {1}}, Function = function(actor, args)
		assert(actor == recipient and args[1] == "Reason unavailable", "Unattributed moderation must keep the actor and fixed reason")
		assert(policy.GetPublicationText("raw helper", actor) == "Text unavailable", "An execution actor must not replace an unavailable text author")
	end}
	policy.WrapCommand(moderation)
	moderation.Function(recipient, {"raw reason"}, {Options = {isSystem = true}})
	local liveOrigin = server.ChatTransport.NewOrigin(author, "before leaving")
	author.Parent = nil
	assert(server.ChatTransport.ResolveOriginAuthor(liveOrigin) == nil, "Departed origin authors must not resolve")
	assert(server.ChatTransport.NewOrigin(author, "disconnected") == nil, "Disconnected players must not receive new origins")
	author.Parent = service.Players
end)

check("personal raw text cannot be redirected through another execution identity", function()
	local source = fs.readFile("MainModule/Server/Commands/Players.luau")
	local shown, saved = {}, 0
	local personalEnv = table.clone(env)
	personalEnv.server = server
	server.MatIcons = {}
	personalEnv.Core = {GetPlayer = function() return {} end, SavePlayer = function() saved += 1 end}
	personalEnv.Remote = {
		MakeGui = function(player, gui, data) table.insert(shown, {Player = player, Gui = gui, Data = data}) end,
		Send = function() end,
	}
	local inputs = {Notepad = {"PRIVATE_DRAFT"}, NotifyMe = {"5", "PRIVATE_DRAFT"}, Theme = {"PRIVATE_DRAFT"}}
	for name, args in inputs do
		local definition = assert(source:match("\n\t\t" .. name .. " = {(.-)\n\t\t};"), "Missing personal command")
		local implementation = assert(definition:match("Function = (function.-\n\t\t\tend)"), "Missing personal command handler")
		local command = {Function = luau.load(`return {implementation}`, {environment = personalEnv})()}
		policy.WrapCommand(command)
		local origin = server.ChatTransport.NewOrigin(author, "personal command PRIVATE_DRAFT")
		command.Function(recipient, args, {Options = {isSystem = true, UserCommandOrigin = origin}})
		local rejected = shown[#shown]
		assert(rejected.Player == recipient and rejected.Gui == "Output" and not rejected.Data.Message:find("PRIVATE_DRAFT", 1, true), "Sudo personal tools must show a fixed explanation without private drafts")
		command.Function(author, args)
		assert(shown[#shown].Player == author and shown[#shown].Gui ~= "Output", "Own personal text was blocked")
	end
	assert(saved == 1, "A sudo call changed another player's personal theme")
end)

check("the script editor keeps raw drafts with their actual execution actor", function()
	local source = fs.readFile("MainModule/Server/Commands/Creators.luau")
	local definition = assert(source:match("\n\t\tScriptEditor = {(.-)\n\t\t}[;,]"), "Missing script editor definition")
	local implementation = assert(definition:match("Function = (function.-\n\t\t\tend)"), "Missing script editor handler")
	local shown = {}
	local editorEnv = table.clone(env)
	editorEnv.server = server
	editorEnv.Settings = {CodeExecution = true}
	editorEnv.Variables = {ScriptEditor = {[tostring(author.UserId)] = {PRIVATE_NAME = {Script = "PRIVATE_CODE"}}}}
	editorEnv.service = table.clone(service)
	editorEnv.service.Wrapped = function() return false end
	editorEnv.Remote = {MakeGui = function(player, gui, data) table.insert(shown, {Player = player, Gui = gui, Data = data}) end}
	local command = {Function = luau.load(`return {implementation}`, {environment = editorEnv})()}
	policy.WrapCommand(command)
	local origin = server.ChatTransport.NewOrigin(author, "scripteditor edit PRIVATE_NAME")
	command.Function(recipient, {"edit", "PRIVATE_NAME"}, {Options = {isSystem = true, UserCommandOrigin = origin}})
	assert(shown[1].Player == recipient and shown[1].Gui == "Output" and shown[1].Data.Script == nil and shown[1].Data.Name == nil, "Sudo ScriptEditor must suppress private names and source")
	command.Function(author, {"edit", "PRIVATE_NAME"})
	assert(shown[2].Player == author and shown[2].Gui == "ScriptEditor" and shown[2].Data.Script == "PRIVATE_CODE", "Self ScriptEditor must preserve its private source")
end)

check("safe detail audits preserve command and invocation logging preferences", function()
	local audits = {}
	server.Logs = {AddAudit = function(category, kind, actor, detail)
		table.insert(audits, {Category = category, Kind = kind, Actor = actor, Detail = detail})
	end}
	local command = {
		CommandKey = "FixtureAudit", AdminLevel = "Moderators",
		UserText = {Kind = "Audit", Audience = "Broadcast", Args = {1}},
		Function = function() end,
	}
	policy.WrapCommand(command)
	command.Function(author, {"ordinary audit detail"})
	assert(#audits == 1 and audits[1].Actor == author and audits[1].Detail.DetailRecord.Text == "public:ordinary audit detail", "Successful authored details must retain their safe record")
	command.Function(author, {"unlogged audit detail"}, {Options = {DontLog = true}})
	assert(#audits == 1, "Invocation logging opt-out must suppress safe detail audits")
	command.NoLog = true
	command.Function(author, {"unlogged command"})
	assert(#audits == 1, "Command logging opt-out must suppress safe detail audits")
	command.NoLog = nil
	command.Donors = true
	command.Function(author, {"donor audit detail"})
	assert(#audits == 2 and audits[2].Detail.NoSave, "Donor detail audits must remain session-only")
	server.Logs = nil
end)

check("announcement declarations cannot bypass native chat or cross-server rejection", function()
	local invoked = false
	local legacy = {UserText = {Kind = "Announcement", Audience = "Broadcast", Args = {1}}, Function = function() invoked = true end}
	policy.WrapCommand(legacy, "LegacyAnnouncement")
	local allowed, err = pcall(legacy.Function, author, {"private announcement"})
	assert(not allowed and tostring(err):find("User messages must be sent through TextChannels.", 1, true) and not invoked, "Legacy announcement metadata must not publish through non-chat filtering")
	local record = assert(policy.CreateRecord("accepted legacy announcement", author, "Announcement"))
	assert(policy.AuthorizePublishedCommand(legacy, author, {record.Text}, {["1"] = record}) == nil, "Cross-server authorization resurrected an announcement declaration")
	for _, name in {"Hint", "TimeHint", "Message", "TimeMessage", "Notify", "CustomNotify", "Warn"} do
		local source = fs.readFile("MainModule/Server/Commands/Moderators.luau")
		local definition = assert(source:match("\n\t\t" .. name .. " = {(.-)\n\t\t};"), "Missing message command")
		local metadata = assert(definition:match("UserText = ([^\n]+);"), "Missing chat policy")
		local command = {UserText = luau.load(`return {metadata}`)()}
		assert(command.UserText.Kind == "Chat" and policy.AuthorizePublishedCommand(command, author, {}, {}) == nil, "User messages must not acquire a non-chat publication permit")
	end
end)

check("published formatting cannot bless forged, unrelated, or arbitrary text", function()
	local record = assert(policy.CreateRecord("accepted text", author, "Audit"))
	local unrelated = assert(policy.CreateRecord("other invocation", author, "Audit"))
	assert(policy.FormatPublishedRecord(record, "Hint") == nil, "A record outside a published invocation gained formatting authority")
	local retained
	local command = {UserText = {Kind = "Audit", Audience = "Broadcast", Args = {1}}, Function = function(_, _, data)
		local accepted = data.UserTextRecords[1]
		assert(policy.FormatPublishedRecord(table.clone(accepted), "Hint") == nil, "A copied record gained formatting authority")
		assert(policy.FormatPublishedRecord(unrelated, "Hint") == nil, "A different invocation supplied a formatted record")
		assert(policy.FormatPublishedRecord(accepted, "ARBITRARY_UNFILTERED_PREFIX") == nil, "An arbitrary presentation string was authorized")
		assert(policy.GetPublicationText("ARBITRARY_UNFILTERED_BODY") == "Text unavailable", "Published formatting authorized unrelated fake-author text")
		retained = assert(policy.FormatPublishedRecord(accepted, "Hint"))
		assert(not pcall(function() retained.Text = "ARBITRARY_UNFILTERED_BODY" end), "Formatted records must be immutable")
	end}
	policy.WrapCommand(command)
	local records = assert(policy.AcceptPublication("format-origin", assert(policy.CreatePublication({["1"] = record}))))
	local fake = {UserId = author.UserId}
	local token, args = policy.AuthorizePublishedCommand(command, fake, {record.Text}, records)
	command.Function(fake, args, {Options = {TextPublication = token}})
	assert(policy.GetRecordText(retained) == "User 101: public:accepted text", "Formatted records did not retain safe content and original authorship")
	assert(retained.AuthorUserId == author.UserId and retained.Kind == "Audit", "Formatted records lost author or kind")
	assert(policy.FormatPublishedRecord(records["1"], "Hint") == nil, "Completed publication formatting authority leaked")
end)

check("filtered tag collisions merge membership and preserve edit admission", function()
	local source = fs.readFile("MainModule/Server/Commands/Moderators.luau")
	local definition = assert(source:match("\n\t\tTag = {(.-)\n\t\t};"), "Missing tag command")
	local metadata = assert(definition:match("UserText = ([^\n]+);"), "Missing tag policy")
	local implementation = assert(definition:match("Function = (function.-\n\t\t\tend)"), "Missing tag handler")
	local tagEnv = table.clone(env)
	tagEnv.server = server
	tagEnv.Variables = {Tags = {}}
	tagEnv.service = table.clone(service)
	tagEnv.service.GetPlayers = function(_, selector) return {if selector == "first" then author else recipient} end
	tagEnv.Functions = {Trim = function(text) return text:match("^%s*(.-)%s*$") end, Hint = function() end}
	local command = {UserText = luau.load(`return {metadata}`)(), Function = luau.load(`return {implementation}`, {environment = tagEnv})()}
	policy.WrapCommand(command, "Tag")
	local originalFilter = service.TextService.FilterStringAsync
	service.TextService.FilterStringAsync = function(...)
		local result = originalFilter(...)
		result.GetNonChatStringForBroadcastAsync = function() return "####" end
		return result
	end
	now = 500
	command.Function(author, {"first", "first-label"})
	local members = tagEnv.Variables.Tags["####"]
	local originalRecord = tagEnv.Variables.TagTextRecords["####"]
	assert(#members == 1 and members[1] == author, "The first filtered tag was not created")
	assert(not pcall(command.Function, author, {"second", "first-label"}) and #members == 1, "An unadmitted label changed tag membership")
	now = 560
	command.Function(author, {"second", "first-label"})
	assert(tagEnv.Variables.Tags["####"] == members and #members == 2 and table.find(members, author) and table.find(members, recipient), "Repeating a filtered label replaced existing members")
	now = 620
	command.Function(author, {"second", "different-label"})
	assert(#members == 2 and tagEnv.Variables.TagTextRecords["####"] == originalRecord, "A colliding label duplicated members or replaced existing provenance")
	assert(not policy.TryPublicEdit(author), "Resolving a new label bypassed public-edit admission")
	local before = calls
	command.Function(author, {"first", "####"})
	assert(#members == 2 and calls == before, "Selecting an existing displayed label filtered again or duplicated membership")
	service.TextService.FilterStringAsync = originalFilter
end)

check("actual removal controls ignore case while near-matches remain filtered public edits", function()
	local humanoid = {DisplayName = "original"}
	local target = {Character = {FindFirstChildOfClass = function() return humanoid end}}
	local commandEnv = table.clone(env)
	commandEnv.server, commandEnv.Settings, commandEnv.Variables = server, {Prefix = ":"}, {}
	commandEnv.service = table.clone(service)
	commandEnv.service.GetPlayers = function() return {target} end
	commandEnv.Remote = {MakeGui = function() end, RemoveGui = function() end}
	local commands = {}
	for key, path in {Name = "MainModule/Server/Commands/Moderators.luau", Notif = "MainModule/Server/Commands/Admins.luau"} do
		local definition = assert(fs.readFile(path):match("\n\t\t" .. key .. " = {(.-)\n\t\t};"), "Missing removal-control command")
		commands[key] = luau.load("return {" .. definition .. "}", {environment = commandEnv})()
		policy.WrapCommand(commands[key], key)
	end
	now = 1000
	assert(policy.TryPublicEdit(author), "The fixture must reserve the public edit allowance")
	local before = calls
	for _, control in {"hide", "HIDE", "HiDe"} do
		humanoid.DisplayName = "original"
		commands.Name.Function(author, {"target", control})
		assert(humanoid.DisplayName == " ", "Every exempt hide spelling must remove the display name")
	end
	for _, control in {"off", "OFF", "OfF", "false", "FALSE", "FaLsE"} do
		commandEnv.Variables.NotifMessage = "original"
		commands.Notif.Function(author, {control})
		assert(commandEnv.Variables.NotifMessage == nil, "Every exempt off/false spelling must remove the persistent message")
	end
	assert(calls == before, "Removal controls must not filter or reserve another edit")
	for _, ordinary in {"hider", "hide ", "hide\n"} do
		assert(not pcall(commands.Name.Function, author, {"target", ordinary}), "Near-match display names must obey the shared cooldown")
	end
	for _, ordinary in {"offset", "off ", " false"} do
		assert(not pcall(commands.Notif.Function, author, {ordinary}), "Near-match persistent messages must obey the shared cooldown")
	end
	assert(humanoid.DisplayName == " " and commandEnv.Variables.NotifMessage == nil and calls == before, "Rejected near-matches must not change displayed text")
	now = 1060
	commands.Name.Function(author, {"target", "hide "})
	assert(humanoid.DisplayName == "public:hide " and calls == before + 1, "An admitted near-match name must be filtered as text")
	now = 1120
	commands.Notif.Function(author, {"OFFice"})
	assert(commandEnv.Variables.NotifMessage == "public:OFFice" and calls == before + 2, "An admitted near-match message must be filtered as text")
	assert(not policy.TryPublicEdit(author), "An admitted near-match must consume the shared allowance")
end)

check("actual debug filter diagnostics keep raw input with its originating author", function()
	local displayed, pending, diagnosticCalls = {}, {}, 0
	local commandEnv = table.clone(env)
	commandEnv.server, commandEnv.Settings = server, {Prefix = ":"}
	commandEnv.service = table.clone(service)
	commandEnv.service.GetPlayers = function() return {recipient} end
	commandEnv.service.RunService = {IsStudio = function() return false end}
	commandEnv.service.TextService = {FilterStringAsync = function()
		diagnosticCalls += 1
		return {
			GetChatForUserAsync = function() return "FILTERED" end,
			GetNonChatStringForBroadcastAsync = function() return "FILTERED" end,
			GetNonChatStringForUserAsync = function() return "FILTERED" end,
		}
	end}
	commandEnv.Remote = {MakeGui = function(player, gui, data) table.insert(displayed, {Player = player, Gui = gui, Data = data}) end}
	local definition = assert(fs.readFile("MainModule/Server/Plugins/Debug_Specific.luau"):match("\n\tCommands.TestFilter = {(.-)\n\t};"), "Missing debug filtering command")
	local command = luau.load("return {" .. definition .. "}", {environment = commandEnv})()
	policy.WrapCommand(command, "TestFilter")
	local sudoEnv = table.clone(commandEnv)
	sudoEnv.task = {defer = function(callback, ...) table.insert(pending, {Callback = callback, Args = table.pack(...)}) end}
	sudoEnv.Process = {Command = function(actor, _, options) command.Function(actor, {"recipient", "PRIVATE_DIAGNOSTIC"}, {Options = options}) end}
	local sudoDefinition = assert(fs.readFile("MainModule/Server/Commands/Creators.luau"):match("\n\t\tSudo = {(.-)\n\t\t};"), "Missing sudo command")
	local sudoImplementation = assert(sudoDefinition:match("Function = (function.-\n\t\t\tend)"), "Missing sudo handler")
	local sudo = {Function = luau.load("return " .. sudoImplementation, {environment = sudoEnv})()}
	policy.WrapCommand(sudo, "Sudo")
	local origin = server.ChatTransport.NewOrigin(author, ":sudo recipient :testfilter recipient PRIVATE_DIAGNOSTIC")
	sudo.Function(author, {"recipient", ":testfilter recipient PRIVATE_DIAGNOSTIC"}, {Options = {UserCommandOrigin = origin}})
	assert(#pending == 1, "The actual sudo handler must defer one target invocation")
	pending[1].Callback(table.unpack(pending[1].Args, 1, pending[1].Args.n))
	local rejected = displayed[1]
	assert(rejected.Player == recipient and rejected.Gui == "Output" and rejected.Data.Tab == nil and not rejected.Data.Message:find("PRIVATE_DIAGNOSTIC", 1, true), "Sudo must not redirect raw filtering diagnostics to another viewer")
	assert(diagnosticCalls == 0, "Rejected diagnostics must not run filtering as another player")
	command.Function(recipient, {"recipient", "PRIVATE_DIAGNOSTIC"}, {Options = {isSystem = true}})
	assert(displayed[2].Gui == "Output" and diagnosticCalls == 0, "Unattributed system diagnostics must not expose raw input")
	command.Function(author, {"recipient", "PRIVATE_DIAGNOSTIC"})
	local own = displayed[3]
	assert(own.Player == author and own.Gui == "List" and own.Data.Tab[1].Desc == "PRIVATE_DIAGNOSTIC", "Self-run diagnostics must preserve the author's original input")
	assert(diagnosticCalls == 3 and #own.Data.Tab == 5, "Self-run diagnostics must retain all filtering results")
end)

print(`TextPolicy: {count} assertion groups passed`)
