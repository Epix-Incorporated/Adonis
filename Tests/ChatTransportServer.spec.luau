-- Run with `lune run Tests/ChatTransportServer.spec.luau` from the repository root.
-- These mocks verify server authorization/lifecycle contracts, not Roblox privacy policy.
local loadTransport = require("../MainModule/Server/Core/ChatTransport")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local currentTest = "server transport"
local passed, failed = 0, 0

-- Associates assertion failures with the contract currently under test.
local function expect(value)
	assert(value, `Failed contract: {currentTest}`)
end

-- Implements server lifecycle signals used by the transport.
local function signal()
	local callbacks = {}
	return {
		Connect = function(_, callback)
			callbacks[callback] = true
			return {Disconnect = function() callbacks[callback] = nil end}
		end,
		Fire = function(_, ...)
			for callback in callbacks do callback(...) end
		end,
	}
end

-- Creates controlled server players, native channel methods, remotes and cleanup clock.
local function fixture()
	local now, guid = 0, 0
	local sent, outputs, audits, nativeChannels = {}, {}, {}, {}
	local muted, denied = {}, {}
	local state = {AutoReady = true}
	local timers = {}
	local mainThread = coroutine.running()
	local scheduler = {}

	-- Resumes a mock task and schedules only explicit timed yields.
	local function resume(thread, ...)
		local ok, duration = coroutine.resume(thread, ...)
		assert(ok, tostring(duration))
		if coroutine.status(thread) == "suspended" and type(duration) == "number" then
			table.insert(timers, {Time = now + duration, Thread = thread})
		end
	end

	-- Advances virtual time while interleaving pending native completions and timers.
	local function advance(seconds)
		local target = now + seconds
		while true do
			local index, earliest
			for i, timer in timers do
				if timer.Time <= target and (not earliest or timer.Time < earliest) then index, earliest = i, timer.Time end
			end
			if not index then break end
			local timer = table.remove(timers, index)
			now = timer.Time
			resume(timer.Thread)
		end
		now = target
	end
	-- Provides deterministic task behavior without wall-clock sleeps.
	scheduler.spawn = function(callback, ...)
		local thread = coroutine.create(callback)
		resume(thread, ...)
		return thread
	end
	scheduler.wait = function(seconds)
		if coroutine.running() == mainThread then advance(seconds) else coroutine.yield(seconds) end
	end
	scheduler.delay = function(seconds, callback)
		table.insert(timers, {Time = now + seconds, Thread = coroutine.create(callback)})
	end
	local players = {PlayerRemoving = signal()}
	for id = 1, 3 do
		players[id] = {Native = true, UserId = id, Name = `Player{id}`, Parent = players, IsA = function(_, class) return class == "Player" end}
	end
	players.GetPlayerByUserId = function(_, id) return players[id] end
	local textChatService = {Commands = {}}
	textChatService.GetDescendants = function() return textChatService.Commands end
	local server = {
		Admin = {IsMuted = function(player) return muted[player] == true end, CheckAdmin = function(player) return player == players[2] end},
		Logs = {AddAudit = function(...) table.insert(audits, {...}) end},
		Remote = {Commands = {}, MakeGui = function(...) table.insert(outputs, {...}) end},
	}
	server.Remote.Send = function(player, command, ...)
		table.insert(sent, {Player = player, Command = command, Args = {...}})
		if command == "ChatChannelOpened" and state.AutoReady then
			server.Remote.Commands.ChatChannelReady(player, {({...})[1].ChannelId})
		end
	end

	-- Models requester-created sources and injection points around yielding AddUserAsync.
	local function newChannel()
		local channel = {Native = true, Sources = {}, Attributes = {}, Destroyed = false}
		channel.SetAttribute = function(_, name, value) channel.Attributes[name] = value end
		channel.GetAttribute = function(_, name) return channel.Attributes[name] end
		channel.IsA = function(_, class) return class == "TextChannel" end
		channel.Destroy = function()
			channel.Destroyed = true
			channel.Parent = nil
			for _, source in channel.Sources do source:Destroy() end
		end
		channel.AddUserAsync = function(_, id)
			if denied[id] then return nil, false end
			local source = channel.Sources[id]
			local created = source == nil
			if not source then
				source = {Native = true, UserId = id, CanSend = true, Parent = channel, Destroyed = false}
				source.Destroy = function() source.Destroyed = true; source.Parent = nil end
				channel.Sources[id] = source
			end
			if state.AddHook then state.AddHook(channel, id) end
			return source, created
		end
		channel.SetDirectChatRequester = function(_, requester)
			if state.FailRequester then error("mock requester failure") end
			expect(channel.Parent == textChatService and next(channel.Sources) == nil)
			channel.Requester = requester
			channel:AddUserAsync(requester.UserId)
		end
		table.insert(nativeChannels, channel)
		return channel
	end

	local service = {
		UnWrap = function(value) return value end,
		Players = players, TextChatService = textChatService,
		HttpService = {GenerateGUID = function() guid += 1; return `guid-{guid}` end},
		StartLoop = function(_, _, callback) state.Cleanup = callback end,
	}
	local env = setmetatable({
		typeof = function(value) return type(value) == "table" and value.Native and "Instance" or typeof(value) end,
		Instance = {new = function(class) expect(class == "TextChannel"); return newChannel() end},
		os = {clock = function() return now end},
		task = scheduler,
	}, {__index = getfenv()})
	loadTransport({Server = server, Service = service}, function() return env end)
	server.ChatTransport.Init()
	for id = 1, 3 do server.Remote.Commands.ChatTransportReady(players[id]) end

	-- Obtains a server-owned input token from an actual actor and matching submitted body.
	local function input(player, text, options)
		options = options or {}
		options.UserCommandOrigin = options.UserCommandOrigin or server.ChatTransport.NewOrigin(player, `:pm target {text}`)
		return server.ChatTransport.CommandInput(player, {UserText = {Args = {2}}}, {"target", text}, options)
	end

	-- Creates a command conversation using the real transport API and mock clients.
	local function submit(kind, text, recipients, options)
		text = text or "message"
		return server.ChatTransport.SubmitCommand(players[1], recipients or {players[2]}, text, input(players[1], text), kind or "PrivateMessage", nil, options)
	end

	-- Counts only command-send permits, excluding body-free channel descriptors.
	local function sends()
		local result = {}
		for _, event in sent do if event.Command == "ChatSend" then table.insert(result, event) end end
		return result
	end
	return {
		Server = server, Transport = server.ChatTransport, Players = players, Channels = nativeChannels,
		State = state, Sent = sent, Audits = audits, Outputs = outputs, Muted = muted, Denied = denied,
		Input = input, Submit = submit, Sends = sends, Chat = textChatService,
		Advance = advance, Scheduler = scheduler,
		Service = service,
	}
end

-- Runs all contracts so one failure does not conceal unrelated lifecycle regressions.
local function test(name, callback)
	currentTest = name
	local ok, err = pcall(callback)
	if ok then passed += 1; print(`PASS {name}`) else failed += 1; warn(err) end
end

test("origin tokens reject forged actors, overrides and expired submissions", function()
	local f = fixture()
	expect(f.Transport.NewOrigin({UserId = 1}, "text") == nil)
	local origin = f.Transport.NewOrigin(f.Players[1], ":pm target message")
	local command = {UserText = {Args = {2}}}
	expect(f.Transport.CommandInput(f.Players[2], command, {"target", "message"}, {UserCommandOrigin = origin}) == nil)
	expect(f.Transport.CommandInput(f.Players[1], command, {"target", "invented"}, {UserCommandOrigin = origin}) == nil)
	expect(f.Transport.CommandInput(f.Players[1], command, {"target", "message"}, {UserCommandOrigin = origin, isSystem = true}) == nil)
	expect(f.Transport.CommandInput(f.Players[1], command, {"target", "message"}, {UserCommandOrigin = origin, OverrideArgs = {[2] = "changed"}}) == nil)
	f.Advance(31)
	expect(f.Transport.CommandInput(f.Players[1], command, {"target", "message"}, {UserCommandOrigin = origin}) == nil)
end)

test("initial body is sent only to its author and the input token is single use", function()
	local f = fixture()
	local token = f.Input(f.Players[1], "private body")
	local id = f.Transport.SubmitCommand(f.Players[1], {f.Players[2]}, "private body", token, "PrivateMessage")
	expect(id ~= nil and #f.Sends() == 1)
	expect(f.Sends()[1].Player == f.Players[1] and f.Sends()[1].Args[3] == "private body")
	for _, event in f.Sent do
		if event.Player == f.Players[2] then expect(event.Command ~= "ChatSend") end
	end
	expect(not pcall(f.Transport.SubmitCommand, f.Players[1], {f.Players[2]}, "private body", token, "PrivateMessage"))
end)

test("forged readiness and send-result remotes grant no authority", function()
	local f = fixture()
	local id, records = f.Submit()
	local record = records[1]
	f.Server.Remote.Commands.ChatChannelReady(f.Players[3], {id})
	expect(record.Members[f.Players[3]] == nil)
	local operation = f.Sends()[1].Args[1]
	f.Server.Remote.Commands.ChatSendResult(f.Players[3], {operation, "Success"})
	expect(#f.Audits == 0)
	f.Server.Remote.Commands.ChatSendResult(f.Players[1], {operation, "Success"})
	f.Server.Remote.Commands.ChatSendResult(f.Players[1], {operation, "Success"})
	expect(#f.Audits == 1)
	expect(f.Audits[1][3] == f.Players[1] and #f.Audits[1][4].TargetUserIds == 1 and f.Audits[1][4].TargetUserIds[1] == 2)
end)

test("chat audit targets retain admitted selections and include an explicitly selected author", function()
	local f = fixture()
	f.Denied[3] = true
	f.Submit("Notification", "body", {f.Players[1], f.Players[2], f.Players[3]})
	f.Server.Remote.Commands.ChatSendResult(f.Players[1], {f.Sends()[1].Args[1], "Success"})
	local ids = f.Audits[1][4].TargetUserIds
	expect(#ids == 2 and table.find(ids, 1) and table.find(ids, 2) and not table.find(ids, 3))
end)

test("delivery requires ready membership and rejects unknown senders", function()
	local f = fixture()
	local _, records = f.Submit()
	local record = records[1]
	local channel = record.Channel
	expect(channel.ShouldDeliverCallback({TextSource = {UserId = 1}}, {UserId = 2}))
	expect(not channel.ShouldDeliverCallback({TextSource = {UserId = 3}}, {UserId = 2}))
	record.Members[f.Players[2]].Ready = false
	expect(not channel.ShouldDeliverCallback({TextSource = {UserId = 1}}, {UserId = 2}))
end)

test("mute restoration never gives receive-only help members send permission", function()
	local f = fixture()
	local _, records = f.Submit("Help")
	local record = records[1]
	expect(not record.Members[f.Players[2]].Source.CanSend)
	f.Muted[f.Players[1]] = true
	f.Muted[f.Players[2]] = true
	f.State.Cleanup()
	expect(not record.Members[f.Players[1]].Source.CanSend)
	expect(not record.Channel.ShouldDeliverCallback({TextSource = {UserId = 1}}, {UserId = 2}))
	f.Muted[f.Players[1]] = nil
	f.Muted[f.Players[2]] = nil
	f.State.Cleanup()
	expect(record.Members[f.Players[1]].Source.CanSend and not record.Members[f.Players[2]].Source.CanSend)
	record.Members[f.Players[2]].Source.CanSend = true
	expect(not record.Channel.ShouldDeliverCallback({TextSource = {UserId = 2}}, {UserId = 1}))
end)

test("only one eligible help member accepts even when its callback yields", function()
	local f = fixture()
	f.Server.Admin.CheckAdmin = function(player) return player == f.Players[2] or player == f.Players[3] end
	local winners = {}
	local id, records = f.Submit("Help", "reason", {f.Players[2], f.Players[3]}, {
		OnAccept = function(player) table.insert(winners, player); f.Scheduler.wait(1) end,
	})
	f.Server.Remote.Commands.ChatHelpAccept(f.Players[1], {id})
	expect(#winners == 0)
	f.Scheduler.spawn(f.Server.Remote.Commands.ChatHelpAccept, f.Players[2], {id})
	f.Scheduler.spawn(f.Server.Remote.Commands.ChatHelpAccept, f.Players[3], {id})
	expect(#winners == 1 and winners[1] == f.Players[2])
	f.Advance(2)
	expect(records[1].Channel.Destroyed)
	f.Server.Remote.Commands.ChatHelpAccept(f.Players[2], {id})
	expect(#winners == 1)
end)

test("help acceptance rejects nonmembers and expired requests", function()
	local f = fixture()
	f.Server.Admin.CheckAdmin = function() return true end
	local accepted = 0
	local id = f.Submit("Help", "reason", {f.Players[2]}, {OnAccept = function() accepted += 1 end})
	f.Server.Remote.Commands.ChatHelpAccept(f.Players[3], {id})
	expect(accepted == 0)
	f.Advance(30)
	f.Server.Remote.Commands.ChatHelpAccept(f.Players[2], {id})
	expect(accepted == 0)
end)

test("actual privatechat controls enforce membership and manager authority", function()
	local f = fixture()
	local session = {Users = {}, SessionKey = "group-session", Ended = false}
	-- Models body-free session controls while the real transport owns native membership.
	session.AddUser = function(self, player) self.Users[player] = true end
	session.RemoveUser = function(self, player)
		self.Users[player] = nil
		self.Callback(player, "RemovedFromSession")
	end
	session.End = function(self) self.Ended = true; table.clear(self.Users) end
	session.ConnectEvent = function(self, callback) self.Callback = callback end
	session.SendToUser = function() end
	session.SendToUsers = function() end
	f.Server.Remote.NewSession = function() return session end
	f.Service.GetPlayers = function() return {f.Players[2]} end
	local source = fs.readFile("MainModule/Server/Commands/Moderators.luau")
	local start = assert(source:find("\t\tPrivateChat = {", 1, true))
	local finish = assert(source:find("\t\tPrivateMessage = {", start, true))
	local env = setmetatable({
		server = f.Server, service = f.Service, Remote = f.Server.Remote, Admin = f.Server.Admin,
		Settings = {Prefix = ":"}, Functions = {Hint = function() end},
	}, {__index = getfenv()})
	local command = luau.load("return {" .. source:sub(start, finish - 1) .. "}", {environment = env})().PrivateChat
	command.Function(f.Players[1], {"target", "hello"}, {ChatInput = f.Input(f.Players[1], "hello")})
	expect(session.Users[f.Players[1]] and session.Users[f.Players[2]])
	session.Callback(f.Players[3], "EndSession")
	session.Callback(f.Players[3], "AddPlayerToSession", f.Players[3])
	expect(not session.Ended and not session.Users[f.Players[3]])
	session.Callback(f.Players[1], "AddPlayerToSession", f.Players[3])
	expect(session.Users[f.Players[3]])
	session.Callback(f.Players[3], "RemovePlayerFromSession", {UserId = 2})
	session.Callback(f.Players[3], "EndSession")
	expect(session.Users[f.Players[2]] and not session.Ended)
	session.Callback(f.Players[2], "RemovePlayerFromSession", {UserId = 3})
	expect(not session.Users[f.Players[3]] and f.Channels[1].Sources[3].Destroyed)
	session.Callback(f.Players[3], "AddPlayerToSession", f.Players[3])
	expect(not session.Users[f.Players[3]])
	session.Callback(f.Players[1], "EndSession")
	expect(session.Ended and f.Channels[1].Destroyed)
end)

test("owner departure destroys groups and revokes pending permits", function()
	local f = fixture()
	local id, records = f.Submit("PrivateChat")
	local operation = f.Sends()[1].Args[1]
	f.Players.PlayerRemoving:Fire(f.Players[1])
	expect(records[1].Channel.Destroyed and next(records[1].Members) == nil)
	f.Server.Remote.Commands.ChatSendResult(f.Players[1], {operation, "Success"})
	expect(#f.Audits == 0)
	f.Transport.Close(id)
end)

test("add-member completion after closure cannot restore membership", function()
	local f = fixture()
	local id, records = f.Submit("PrivateChat")
	f.State.AddHook = function(_, userId) if userId == 3 then f.Transport.Close(id) end end
	expect(not f.Transport.AddMember(id, f.Players[3], true))
	expect(records[1].Channel.Sources[3].Destroyed and next(records[1].Members) == nil)
end)

test("timed-out AddUserAsync destroys a late native source", function()
	local f = fixture()
	local id, records = f.Submit("PrivateChat")
	f.State.AddHook = function(_, userId) if userId == 3 then f.Scheduler.wait(11) end end
	expect(not f.Transport.AddMember(id, f.Players[3], true))
	expect(records[1].Members[f.Players[3]] == nil)
	f.Advance(2)
	expect(records[1].Channel.Sources[3].Destroyed and records[1].Members[f.Players[3]] == nil)
end)

test("concurrent submissions share one pending PM pair", function()
	local f = fixture()
	local ids = {}
	local held = false
	f.State.AddHook = function(_, userId)
		if userId == 2 and not held then held = true; f.Scheduler.wait(1) end
	end
	f.Scheduler.spawn(function() ids[1] = f.Submit() end)
	f.Scheduler.spawn(function() ids[2] = f.Submit() end)
	f.Advance(2)
	expect(ids[1] ~= nil and ids[1] == ids[2])
	expect(#f.Channels == 1 and #f.Sends() == 2)
end)

test("requester setup failure destroys all partially created channel state", function()
	local f = fixture()
	f.State.FailRequester = true
	local id = f.Submit()
	expect(id == nil and f.Channels[1].Destroyed and #f.Sends() == 0)
end)

test("denied sole recipient does not leave an author-only successful conversation", function()
	local f = fixture()
	f.Denied[2] = true
	local id = f.Submit()
	expect(id == nil and f.Channels[1].Destroyed and #f.Sends() == 0)
end)

test("native command-looking bodies are rejected before any channel is created", function()
	local f = fixture()
	table.insert(f.Chat.Commands, {IsA = function(_, name) return name == "TextChatCommand" end, Enabled = true, PrimaryAlias = "/native", SecondaryAlias = ""})
	expect(not pcall(f.Submit, "PrivateMessage", "/NATIVE argument"))
	expect(#f.Channels == 0)
end)

test("pending initial-send permits are bounded per author and freed by acknowledgments", function()
	local f = fixture()
	for _ = 1, 32 do f.Submit() end
	expect(not pcall(f.Submit))
	expect(#f.Sends() == 32)
	f.Server.Remote.Commands.ChatSendResult(f.Players[1], {f.Sends()[1].Args[1], "Success"})
	f.Submit()
	expect(#f.Sends() == 33)
end)

test("one-shot channels expire and idle PM pairs are eventually released", function()
	local f = fixture()
	local _, records = f.Submit("Notification")
	f.Advance(31)
	f.State.Cleanup()
	expect(records[1].Channel.Destroyed)
	local _, pairs = f.Submit("PrivateMessage")
	f.Advance(901)
	f.State.Cleanup()
	expect(pairs[1].Channel.Destroyed)
end)

test("empty privatechat setup still has a bounded readiness deadline", function()
	local f = fixture()
	f.State.AutoReady = false
	local _, records = f.Submit("PrivateChat", "")
	f.Advance(11)
	f.State.Cleanup()
	expect(records[1].Channel.Destroyed)
end)

test("channel capacity is bounded and cleanup releases capacity", function()
	local f = fixture()
	for _ = 1, 1024 do f.Submit("Notification", "") end
	expect(not pcall(f.Submit, "Notification", ""))
	expect(#f.Channels == 1024)
	f.Advance(31)
	f.State.Cleanup()
	expect(pcall(f.Submit, "Notification", ""))
	expect(#f.Channels == 1025)
end)

test("custom announcements keep authenticated title and body inside the originating native send", function()
	local f = fixture()
	local title, body = "Original\r\nTitle", "Private body\ncontinued"
	local origin = f.Transport.NewOrigin(f.Players[1], `:cm {title} {body}`)
	local input = f.Transport.CommandInput(f.Players[1], {UserText = {Args = {1, 2}}}, {title, body}, {UserCommandOrigin = origin})
	f.Transport.SubmitCommand(f.Players[1], {f.Players[2]}, title .. "\n" .. body, input, "Notification", "Message", {TitleMode = "Custom", Duration = 75})
	expect(#f.Channels == 1 and f.Channels[1].Requester == f.Players[1])
	expect(f.Channels[1].Sources[2].CanSend == false)
	local sends = f.Sends()
	expect(#sends == 1 and sends[1].Player == f.Players[1] and sends[1].Args[3] == "Original Title\nPrivate body\ncontinued")
	for _, event in f.Sent do
		if event.Command == "ChatChannelOpened" then
			local descriptor = event.Args[1]
			expect(descriptor.TitleMode == "Custom" and descriptor.Duration == 75)
			for _, value in descriptor do
				expect(value ~= title and value ~= body and value ~= title .. "\n" .. body)
			end
		end
	end
end)

test("custom announcement framing requires exactly two authenticated fields", function()
	local f = fixture()
	local token = f.Input(f.Players[1], "title\nbody")
	expect(not pcall(f.Transport.SubmitCommand, f.Players[1], {f.Players[2]}, "title\nbody", token,
		"Notification", "Message", {TitleMode = "Custom"}))
	expect(#f.Channels == 0 and #f.Sends() == 0)
	local invalidMode = f.Input(f.Players[1], "body")
	expect(not pcall(f.Transport.SubmitCommand, f.Players[1], {f.Players[2]}, "body", invalidMode,
		"Notification", "Message", {TitleMode = "untrusted title"}))
	expect(#f.Channels == 0)
end)

test("denied announcement recipients never receive body-bearing fallback controls", function()
	for _, presentation in {"Message", "Notify", "Hint"} do
		local f = fixture()
		f.Denied[2] = true
		f.Transport.SubmitCommand(f.Players[1], {f.Players[2]}, "private announcement", f.Input(f.Players[1], "private announcement"),
			"Notification", presentation, {Duration = math.huge})
		expect(#f.Sends() == 0 and f.Channels[1].Destroyed)
		for _, event in f.Sent do expect(event.Player ~= f.Players[2]) end
		for _, output in f.Outputs do expect(output[1] == f.Players[1]) end
	end
end)

test("normalized custom titles cannot turn native payloads into registered commands", function()
	for _, title in {":pm\r\nrecipient", ":pm", ":pm\trecipient"} do
		local f = fixture()
		table.insert(f.Chat.Commands, {Enabled = true, PrimaryAlias = ":pm", SecondaryAlias = "", IsA = function(_, name) return name == "TextChatCommand" end})
		local body = "secret"
		local origin = f.Transport.NewOrigin(f.Players[1], `:cm {title} {body}`)
		local input = f.Transport.CommandInput(f.Players[1], {UserText = {Args = {1, 2}}}, {title, body}, {UserCommandOrigin = origin})
		expect(not pcall(f.Transport.SubmitCommand, f.Players[1], {f.Players[2]}, title .. "\n" .. body, input,
			"Notification", "Message", {TitleMode = "Custom"}))
		expect(#f.Channels == 0 and #f.Sends() == 0)
	end
end)

test("announcement timing metadata is bounded while Roblox notifications retain their range", function()
	for _, case in {{"Message", 9000, 3600}, {"Message", math.huge, nil}, {"Message", 0 / 0, nil},
		{"Message", -1, nil}, {"RobloxNotification", 9000, 30}, {"RobloxNotification", -1, 1}, {"RobloxNotification", nil, 5}} do
		local f = fixture()
		f.Transport.SubmitCommand(f.Players[1], {f.Players[2]}, "body", f.Input(f.Players[1], "body"),
			"Notification", case[1], {Duration = case[2], AutoDuration = true})
		for _, event in f.Sent do
			if event.Command == "ChatChannelOpened" then
				expect(event.Args[1].Duration == case[3] and event.Args[1].AutoDuration == true)
			end
		end
	end
end)

print(`{passed} server transport contracts passed; {failed} failed`)
assert(failed == 0, "Server transport contract failures require review")
