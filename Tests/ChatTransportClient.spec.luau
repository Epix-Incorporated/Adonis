-- Run with `lune run Tests/ChatTransportClient.spec.luau` from the repository root.
-- Mocks verify client transport contracts; they do not simulate Roblox delivery policy.
local loadTransport = require("../MainModule/Client/Core/ChatTransport")
local loadProcess = require("../MainModule/Client/Core/Process")
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local successes = 0
local currentTest = "client transport"

-- Adds the active contract name to assertion failures from the mock harness.
local function expect(value)
	assert(value, `Failed contract: {currentTest}`)
end

-- Provides synchronous event connections with explicit disconnection for lifecycle checks.
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

-- Installs shipped theme close and registry destruction code with inert animation substitutes.
local function installThemeClose(theme, ui, window, data, options)
	local closeBody = assert(theme:match("\tfunction doClose%(%)\n(.-)\n\tfunction isVisible"), "Missing theme close implementation")
	local customDestroyBody = assert(theme:match("\tgTable.CustomDestroy = function%(%)\n(.-)\n\tfor i,child"), "Missing theme destruction implementation")
	local destroyBody = assert(ui:match("\t\t\t\tDestroy = function%(%)\n(.-)\n\t\t\t\tUnRegister"), "Missing UI destruction implementation"):gsub(",%s*$", "")
	local clearEventsBody = assert(ui:match("\t\t\t\tClearEvents = function%(%)\n(.-)\n\t\t\t\tDestroy"), "Missing UI cleanup implementation"):gsub(",%s*$", "")
	local environment = setmetatable({
		gTable = window.gTable, gIndex = data.Name, GUI = window.gTable.Object, onClose = data.OnClose,
		client = {Variables = {}, GUIs = {[data.Name] = window.gTable}},
		service = {UnWrap = function(value) return value end}, Mouse = {},
		Drag = {GetChildren = function() return {} end, TweenSize = function() end},
		Main = {TweenSize = function() end},
		UDim2 = {new = function() return {} end},
		Enum = {EasingDirection = {Out = "Out"}, EasingStyle = {Quad = "Quad"}},
		task = {wait = function() if options.DuringAnimation then options.DuringAnimation() end end},
	}, {__index = getfenv()})
	window.Close = luau.load("local isClosed = false\n"
		.. "gTable.ClearEvents = function()\n" .. clearEventsBody .. "\n"
		.. "gTable.Destroy = function()\n" .. destroyBody .. "\n"
		.. "gTable.CustomDestroy = function()\n" .. customDestroyBody .. "\n"
		.. "local function doClose()\n" .. closeBody .. "\nreturn doClose", {environment = environment})()
end

-- Creates an isolated client with controllable engine events and optional real theme cleanup.
local function fixture(options)
	options = options or {}
	local theme = options.Theme and fs.readFile(`MainModule/Client/UI/{options.Theme}/Window.rbxmx`)
	local ui = theme and fs.readFile("MainModule/Client/Core/UI.luau")
	local now = 0
	local enum = {TextChatMessageStatus = {}, ChatVersion = {TextChatService = "TextChatService"}}
	for _, name in {"Success", "Sending", "TextFilterFailed"} do
		enum.TextChatMessageStatus[name] = {Name = name}
	end
	local players = {
		[1] = {UserId = 1, Name = "LocalUser", DisplayName = "Local User", Character = {}},
		[2] = {UserId = 2, Name = "Sender", DisplayName = "Sender", Character = {}},
	}
	local channels, remotes, uiCalls, nativeSends, bubbles, speechCalls = {}, {}, {}, {}, {}, {}
	local textChatService = {
		MessageReceived = signal(),
		DescendantAdded = signal(),
		DescendantRemoving = signal(),
		ChatVersion = enum.ChatVersion.TextChatService,
		Commands = {},
		GetDescendants = function(self) return self.Commands end,
		FindFirstChild = function(_, name) return channels[name] end,
		DisplayBubble = function(_, adornee, text) table.insert(bubbles, {adornee, text}) end,
	}
	local service = {
		UnWrap = function(value) return type(value) == "table" and value.WrappedObject or value end,
		TextChatService = textChatService,
		Player = players[1],
		Players = {GetPlayerByUserId = function(_, id) return players[id] end},
		Trim = function(value) return value:match("^%s*(.-)%s*$") end,
	}
	local client = {
		Remote = {
			Commands = {},
			Send = function(...) table.insert(remotes, {...}) end,
			Get = function(name)
				if name == "PlayerData" then return {AdminLevel = 0, isDonor = false} end
			end,
		},
		UI = {Make = function(name, data)
			local call = {Name = name, Data = data, Children = {}}
			table.insert(uiCalls, call)
			if name == "Window" then
				local window = {
					Add = function(_, class, properties) table.insert(call.Children, {Class = class, Data = properties}) end,
					Ready = function() end,
					Close = function() if data.OnClose then data.OnClose() end end,
				}
				window.gTable = {Events = {}, Object = {Destroy = function()
					if options.BeforeDestroy then options.BeforeDestroy() end
					call.Destroyed = true
				end}}
				if theme then installThemeClose(theme, ui, window, data, options) end
				call.Window = window
				return window
			end
		end},
		Functions = {TextToSpeech = function(text, shouldContinue, registerSound)
			local call = {Text = text, ShouldContinue = shouldContinue, Stopped = false, StopCount = 0}
			table.insert(speechCalls, call)
			registerSound({Stop = function() call.Stopped = true; call.StopCount += 1 end, Destroy = function() end})
			if options.ActiveSpeech then coroutine.yield() end
		end},
	}
	local env = setmetatable({
		typeof = function(value) return type(value) == "table" and value.Native and "Instance" or typeof(value) end,
		Enum = enum,
		UDim2 = {new = function(...) return {...} end},
		os = {clock = function() return now end, time = function() return math.floor(now) end, date = os.date},
		task = {
			spawn = function(callback, ...)
				local thread = coroutine.create(callback)
				local ok, err = coroutine.resume(thread, ...)
				assert(ok, tostring(err))
				return thread
			end,
			defer = function(callback, ...) return callback(...) end,
			cancel = coroutine.close,
			delay = function() end,
			wait = function(duration) now += duration end,
		},
	}, {__index = getfenv()})
	loadTransport({Client = client, Service = service}, function() return env end)
	client.ChatTransport.Init()
	loadProcess({Client = client, Service = service}, function() return env end)
	client.Process.Init()

	-- Creates a managed channel and source independently of the open notification.
	local function channel(id, canSend)
		local source = {UserId = 1, CanSend = canSend ~= false, AncestryChanged = signal(), IsA = function(_, name) return name == "TextSource" end}
		local instance = {
			Name = id,
			Parent = textChatService,
			MessageReceived = signal(),
			AncestryChanged = signal(),
			IsA = function(_, name) return name == "TextChannel" end,
			GetAttribute = function() return id end,
			GetChildren = function() return {source} end,
			IsDescendantOf = function(self, parent) return self.Parent == parent end,
			SendAsync = function(self, text, metadata)
				table.insert(nativeSends, {Text = text, Metadata = metadata})
				local message = {
					MessageId = `sent-{#nativeSends}`,
					Text = "FILTERED",
					TextSource = source,
					Status = self.SendStatus or enum.TextChatMessageStatus.Success,
				}
				if self.DeliverOnSend then self.MessageReceived:Fire(message) end
				return message
			end,
		}
		source.Parent = instance
		channels[id] = instance
		return instance, source
	end

	-- Opens the client side using the server's agreed descriptor fields.
	local function open(id, kind, canSend, presentToSender)
		client.Remote.Commands.ChatChannelOpened({{
			ChannelId = id, ChannelName = id, Kind = kind or "PrivateMessage", CanSend = canSend ~= false,
			RequesterUserId = 2, ParticipantUserIds = {1, 2}, PresentToSender = presentToSender,
		}})
	end

	-- Delivers a chosen final or provisional message through a native channel event.
	local function receive(instance, id, text, status, senderId)
		instance.MessageReceived:Fire({
			MessageId = id, Text = text, TextSource = {UserId = senderId or 2},
			Status = enum.TextChatMessageStatus[status or "Success"],
		})
	end
	return {
		Client = client, Transport = client.ChatTransport, Channel = channel, Open = open, Receive = receive,
		Remotes = remotes, UI = uiCalls, NativeSends = nativeSends, Chat = textChatService, Enum = enum,
		Players = players, Bubbles = bubbles, SpeechCalls = speechCalls,
	}
end

-- Reports each independent contract so failures identify the boundary under test.
local function test(name, callback)
	currentTest = name
	callback()
	successes += 1
	print(`PASS {name}`)
end

test("readiness precedes sends and does not carry message text", function()
	local f = fixture()
	f.Channel("one")
	f.Open("one")
	expect(f.Remotes[1][1] == "ChatChannelReady" and f.Remotes[1][2] == "one")
	expect(f.Transport.Send("one", "raw draft"))
	expect(f.NativeSends[1].Text == "raw draft")
	expect(#f.UI == 0 and #f.Transport.GetHistory("one") == 0)
	expect(#f.Remotes == 1)
end)

test("only successful native receipts are rendered and duplicate ids are ignored", function()
	local f = fixture()
	local channel = f.Channel("one")
	f.Open("one")
	f.Receive(channel, "pending", "RAW", "Sending")
	f.Receive(channel, "failed", "RAW", "TextFilterFailed")
	f.Receive(channel, "denied-empty", "", "Success")
	expect(#f.UI == 0 and #f.Transport.GetHistory("one") == 0)
	f.Receive(channel, "received", "FILTERED")
	f.Receive(channel, "received", "FILTERED")
	expect(#f.UI == 1 and f.UI[1].Data.Message == "FILTERED")
	expect(#f.Transport.GetHistory("one") == 1)
end)

test("initial command dispatch is idempotent and results contain no draft", function()
	local f = fixture()
	f.Channel("one")
	f.Open("one")
	f.Client.Remote.Commands.ChatSend({"operation", "one", "raw draft"})
	f.Client.Remote.Commands.ChatSend({"operation", "one", "raw draft"})
	expect(#f.NativeSends == 1)
	local result = f.Remotes[2]
	expect(result[1] == "ChatSendResult" and result[2] == "operation" and result[3] == "Success")
	expect(result[4] == "sent-1" and result[5] == nil)
end)

test("unconfirmed Sending is neither rendered nor automatically retried", function()
	local f = fixture()
	local channel = f.Channel("one")
	channel.SendStatus = f.Enum.TextChatMessageStatus.Sending
	f.Open("one")
	local ok, status = f.Transport.Send("one", "raw draft")
	expect(not ok and status == "DeliveryUnconfirmed")
	expect(#f.NativeSends == 1 and #f.UI == 0)
end)

test("a hanging SendAsync is bounded and later native delivery remains visible", function()
	local f = fixture()
	local channel = f.Channel("one")
	local attempts = 0
	channel.SendAsync = function()
		attempts += 1
		coroutine.yield()
	end
	f.Open("one")
	local ok, status = f.Transport.Send("one", "raw draft")
	expect(not ok and status == "DeliveryUnconfirmed" and attempts == 1)
	expect(#f.UI == 0)
	f.Receive(channel, "late-success", "FILTERED LATE")
	expect(#f.UI == 1 and f.Transport.GetHistory("one")[1].Text == "FILTERED LATE")
end)

test("read-only participants and empty drafts cannot invoke SendAsync", function()
	local f = fixture()
	f.Channel("one", false)
	f.Open("one")
	local ok, status = f.Transport.Send("one", "draft")
	expect(not ok and status == "ReadOnly")
	f.Channel("two")
	f.Open("two", "PrivateMessage", false)
	expect(not f.Transport.Send("two", "draft"))
	f.Channel("three")
	f.Open("three")
	expect(not f.Transport.Send("three", "  "))
	expect(#f.NativeSends == 0)
end)

test("channel removal closes subscribers and rejects stale drafts", function()
	local f = fixture()
	local channel, source = f.Channel("one")
	f.Open("one")
	local closed = 0
	f.Transport.Subscribe("one", function(event) if event == "Closed" then closed += 1 end end)
	source.Parent = nil
	source.AncestryChanged:Fire()
	expect(closed == 1 and f.Transport.GetDescriptor("one") == nil)
	expect(not f.Transport.Send("one", "draft"))
	f.Receive(channel, "late", "FILTERED")
	expect(#f.UI == 0)
end)

test("unsubscribed windows receive no later messages", function()
	local f = fixture()
	local channel = f.Channel("one")
	f.Open("one", "PrivateChat")
	local count = 0
	local unsubscribe = f.Transport.Subscribe("one", function() count += 1 end)
	unsubscribe()
	f.Receive(channel, "one", "FILTERED")
	expect(count == 0)
end)

test("managed history is bounded and callers cannot edit stored entries", function()
	local f = fixture()
	local channel = f.Channel("one")
	f.Open("one", "PrivateChat")
	for i = 1, 210 do f.Receive(channel, tostring(i), "FILTERED") end
	local result = f.Transport.GetHistory("one")
	expect(#result == 200 and result[1].MessageId == "11")
	result[1].Text = "CHANGED"
	expect(f.Transport.GetHistory("one")[1].Text == "FILTERED")
end)

test("public and managed history contains only actual successful receipts", function()
	local f = fixture()
	f.Chat.MessageReceived:Fire({MessageId = "public", Text = "PUBLIC FILTERED", TextSource = {UserId = 2}, Status = f.Enum.TextChatMessageStatus.Success})
	f.Chat.MessageReceived:Fire({MessageId = "failed", Text = "RAW", TextSource = {UserId = 2}, Status = f.Enum.TextChatMessageStatus.TextFilterFailed})
	f.Client.Remote.Commands.ChatHistory()
	expect(#f.UI[1].Data.Table == 1 and f.UI[1].Data.Table[1].Text == "Sender: PUBLIC FILTERED")
end)

test("own echoes require explicit presentation and bubbles identify the real speaker", function()
	local f = fixture()
	local channel = f.Channel("one")
	f.Open("one", "Bubble")
	f.Receive(channel, "own", "FILTERED", "Success", 1)
	expect(#f.Bubbles == 0)
	f.Receive(channel, "other", "FILTERED", "Success", 2)
	expect(#f.Bubbles == 1 and f.Bubbles[1][1] == f.Players[2].Character)
	f.Open("one", "Bubble", true, true)
	f.Receive(channel, "own-targeted", "FILTERED", "Success", 1)
	expect(#f.Bubbles == 2)
end)

test("help acceptance carries a channel id and no received reason text", function()
	local f = fixture()
	local channel = f.Channel("one")
	f.Open("one", "Help", false)
	f.Receive(channel, "help", "FILTERED HELP")
	f.UI[1].Data.OnClick()
	expect(f.Remotes[2][1] == "ChatHelpAccept" and f.Remotes[2][2] == "one" and f.Remotes[2][3] == nil)
	f.Client.Remote.Commands.ChatChannelClosed({"one"})
	f.UI[1].Data.OnClick()
	expect(#f.Remotes == 2)
end)

test("speech uses filtered captions, replaces playback, and honors session mute", function()
	local f = fixture()
	local channel = f.Channel("one")
	f.Open("one", "Speech")
	f.Receive(channel, "first", "FILTERED FIRST")
	expect(f.SpeechCalls[1].Text == "FILTERED FIRST")
	expect(f.UI[1].Children[1].Data.Text == "FILTERED FIRST")
	f.Receive(channel, "second", "FILTERED SECOND")
	expect(f.SpeechCalls[1].Stopped and not f.SpeechCalls[1].ShouldContinue())
	expect(f.SpeechCalls[2].ShouldContinue())
	f.UI[2].Children[3].Data.OnClick()
	expect(f.SpeechCalls[2].Stopped and not f.SpeechCalls[2].ShouldContinue())
	f.Receive(channel, "third", "FILTERED THIRD")
	expect(#f.SpeechCalls == 2 and #f.UI == 2)
end)

-- Starts a pending utterance so real window destruction can be checked before playback finishes.
local function speechFixture(themeName, options)
	options = options or {}
	options.Theme = themeName
	options.ActiveSpeech = true
	local f = fixture(options)
	local channel = f.Channel("speech")
	f.Open("speech", "Speech")
	f.Receive(channel, "first", "FILTERED FIRST")
	expect(f.SpeechCalls[1].ShouldContinue())
	return f, channel
end

for _, themeName in {"Default", "Unity", "Aero"} do
	test(`{themeName} manual and registry speech closure cancel playback once`, function()
		for _, closeViaRegistry in {false, true} do
			local options = {}
			local f = speechFixture(themeName, options)
			local speech = f.SpeechCalls[1]
			options.BeforeDestroy = function()
				expect(not speech.ShouldContinue() and speech.Stopped)
			end
			local window = f.UI[1].Window
			if closeViaRegistry then window.gTable:Destroy() else window:Close() end
			window:Close()
			window.gTable:Destroy()
			expect(f.UI[1].Destroyed and window.gTable.Destroyed)
			expect(not speech.ShouldContinue() and speech.StopCount == 1)
		end
	end)

	test(`{themeName} replacement and stop preserve the current speech lifecycle`, function()
		local f, channel = speechFixture(themeName)
		f.Receive(channel, "second", "FILTERED SECOND")
		expect(f.UI[1].Destroyed and f.SpeechCalls[1].StopCount == 1)
		expect(f.SpeechCalls[2].ShouldContinue())
		f.UI[1].Window.gTable:Destroy()
		expect(f.SpeechCalls[2].ShouldContinue())
		f.UI[2].Children[2].Data.OnClick()
		f.UI[2].Window.gTable:Destroy()
		expect(f.UI[2].Destroyed and not f.SpeechCalls[2].ShouldContinue())
		expect(f.SpeechCalls[2].StopCount == 1)
	end)

	test(`{themeName} channel expiry and mute close speech without recursive destruction`, function()
		local expired = speechFixture(themeName)
		expired.Client.Remote.Commands.ChatChannelClosed({"speech", "Expired"})
		expired.UI[1].Window.gTable:Destroy()
		expect(expired.UI[1].Destroyed and expired.SpeechCalls[1].StopCount == 1)
		expect(not expired.SpeechCalls[1].ShouldContinue())
		local muted, channel = speechFixture(themeName)
		muted.UI[1].Children[3].Data.OnClick()
		muted.UI[1].Window.gTable:Destroy()
		muted.Receive(channel, "muted", "FILTERED MUTED")
		expect(muted.UI[1].Destroyed and muted.SpeechCalls[1].StopCount == 1)
		expect(not muted.SpeechCalls[1].ShouldContinue() and #muted.SpeechCalls == 1)
	end)
end

test("channel expiry during Aero's close animation cancels the pending utterance", function()
	local options = {}
	local f = speechFixture("Aero", options)
	options.DuringAnimation = function()
		expect(not f.UI[1].Destroyed)
		f.Client.Remote.Commands.ChatChannelClosed({"speech", "Expired"})
	end
	f.UI[1].Window:Close()
	expect(f.UI[1].Destroyed and f.SpeechCalls[1].StopCount == 1)
	expect(not f.SpeechCalls[1].ShouldContinue())
end)

test("conversation replies cannot invoke registered native commands", function()
	local f = fixture()
	f.Channel("one")
	f.Open("one")
	table.insert(f.Chat.Commands, {
		IsA = function(_, class) return class == "TextChatCommand" end,
		Enabled = true, PrimaryAlias = "/native", SecondaryAlias = "",
	})
	local sent, status = f.Transport.Send("one", "/NATIVE argument")
	expect(not sent and status == "CommandText" and #f.NativeSends == 0)
	expect(f.Transport.Send("one", "/nativeword is ordinary text"))
end)

test("native sends never replay public or managed text as a private command", function()
	local f = fixture()
	table.insert(f.Chat.Commands, {
		IsA = function(_, class) return class == "TextChatCommand" end,
		Enabled = true, PrimaryAlias = "/:pm", SecondaryAlias = "",
	})
	local message = {
		Native = true, IsA = function(_, class) return class == "TextChatMessage" end,
		TextSource = {UserId = 1}, Text = ":pm target body",
		TextChannel = {GetAttribute = function() return nil end},
	}
	f.Client.Process.Chat(message)
	expect(#f.Remotes == 0)
	message.Text = "/:pm target body"
	f.Client.Process.Chat(message)
	expect(#f.Remotes == 0)
	message.Text = ":pm target body"
	message.TextChannel.GetAttribute = function() return "managed" end
	f.Client.Process.Chat(message)
	expect(#f.Remotes == 0)
	message.TextChannel.GetAttribute = function() return nil end
	message.TextSource.UserId = 2
	f.Client.Process.Chat(message)
	expect(#f.Remotes == 0)
	f.Client.Process.Chat({Text = ":pm target forged"})
	expect(#f.Remotes == 0)
	message.TextSource.UserId = 1
	f.Client.Process.Chat({WrappedObject = message})
	expect(#f.Remotes == 0)
end)

test("inaccessible native commands stay parented to consume private command text", function()
	local f = fixture()
	local command = {
		Name = "Adonis_PrivateMessage_1_1", Parent = f.Chat, AutocompleteVisible = true,
		IsA = function(_, class) return class == "TextChatCommand" end,
		GetAttribute = function() return 100 end,
	}
	table.insert(f.Chat.Commands, command)
	f.Client.Process.HandleTextChatCommands()
	expect(command.Parent == f.Chat and not command.AutocompleteVisible)
end)

test("small directed messages preserve the Notify presentation", function()
	local f = fixture()
	local channel = f.Channel("one")
	f.Client.Remote.Commands.ChatChannelOpened({{
		ChannelId = "one", ChannelName = "one", Kind = "Notification", Presentation = "Notify",
		RequesterUserId = 2, ParticipantUserIds = {1, 2}, CanSend = false,
	}})
	f.Receive(channel, "notify", "FILTERED NOTICE")
	expect(#f.UI == 1 and f.UI[1].Name == "Notify" and f.UI[1].Data.Message == "FILTERED NOTICE")
end)

print(`{successes} client transport contracts passed`)
