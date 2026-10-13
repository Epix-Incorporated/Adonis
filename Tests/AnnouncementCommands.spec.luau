-- Exercises shipped announcement and warning handlers with the real text policy and native transport.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("MainModule/Server/Commands/Moderators.luau")
local adminSource = fs.readFile("MainModule/Server/Commands/Admins.luau")
local transportFixture = fs.readFile("Tests/ChatTransportServer.spec.luau")
local fixtureEnd = assert(transportFixture:find("-- Runs all contracts", 1, true), "Missing server transport fixture boundary")
local dependencies = {
	["@lune/fs"] = fs,
	["@lune/luau"] = luau,
	["../MainModule/Server/Core/ChatTransport"] = require("../MainModule/Server/Core/ChatTransport"),
}
local newTransport = luau.load(transportFixture:sub(1, fixtureEnd - 1) .. "\nreturn fixture", {environment = {
	-- Resolves fixture dependencies explicitly because dynamically loaded chunks have no module path.
	require = function(name) return assert(dependencies[name], "Unexpected fixture dependency") end,
}})()
local rawBody = "PRIVATE_ANNOUNCEMENT_BODY"
local rawTitle = "PRIVATE_ANNOUNCEMENT_TITLE"
local passed = 0

-- Finds leaked text in outward payloads while tolerating the mock players' cyclic parent references.
local function contains(value, needle, seen)
	if type(value) == "string" then return value:find(needle, 1, true) ~= nil end
	if type(value) ~= "table" then return false end
	seen = seen or {}
	if seen[value] then return false end
	seen[value] = true
	for key, child in value do
		if contains(key, needle, seen) or contains(child, needle, seen) then return true end
	end
	return false
end

-- Adds command dependencies without replacing authorization, native channel setup, or text policy.
local function fixture()
	local f = newTransport()
	f.Targets = {f.Players[2], f.Players[3]}
	f.PlayerData, f.Notices, f.FilterCalls, f.WarningEvents, f.Saved = {}, {}, {}, {}, {}
	f.Unauthorized = {}
	f.Service.GetPlayers = function(actor)
		return if actor then f.Targets else {f.Players[1], f.Players[2], f.Players[3]}
	end
	f.Service.FormatPlayer = function(player) return player.Name end
	f.Service.Wrapped = function(player) return player.Offline == true end
	f.Service.TryFilter = function(text, author, _, broadcast)
		assert(broadcast == true, "Moderation records require broadcast filtering")
		table.insert(f.FilterCalls, {Text = text, Author = author})
		return if f.FailFilter then nil else "FILTERED_REASON"
	end
	f.Service.Events = {WarningAdded = {Fire = function(_, ...)
		table.insert(f.WarningEvents, {...})
	end}}
	f.Server.Admin.CheckAuthority = function(_, target) return not f.Unauthorized[target.UserId] end
	f.Server.Core = {
		GetPlayer = function(player)
			f.PlayerData[player] = f.PlayerData[player] or {Warnings = {}}
			return f.PlayerData[player]
		end,
		SavePlayerData = function(player) table.insert(f.Saved, player) end,
		Bytecode = function(value) return value end,
	}
	f.Server.Functions = {
		GetMainPrefix = function() return ":" end,
		Message = function() error("Announcement used a recipient body helper") end,
		Hint = function() error("Announcement used a recipient body helper") end,
		Notify = function(title, body, recipients)
			assert(title == "Warning" and body == "A moderator recorded a warning for your account.", "Only the fixed warning status may bypass native chat")
			table.insert(f.Notices, {Title = title, Message = body, Recipients = recipients})
		end,
		Notification = function(title, body) table.insert(f.Notices, {Title = title, Message = body}) end,
		LogAdminAction = function(_, _, _, reason)
			assert(reason == "FILTERED_REASON" or reason == "Reason unavailable", "Moderation logging received raw input")
		end,
	}
	local env = {
		server = f.Server, service = f.Service, Settings = {Prefix = ":"},
		Functions = f.Server.Functions, Core = f.Server.Core, Admin = f.Server.Admin,
		Remote = f.Server.Remote, Logs = f.Server.Logs,
		typeof = function(value) return if type(value) == "table" and value.Native then "Instance" else typeof(value) end,
		task = {defer = function(callback, ...) callback(...) end},
	}
	luau.load(fs.readFile("MainModule/Server/Core/TextPolicy.luau"), {environment = env})()({Server = f.Server, Service = f.Service})
	f.Commands = {}
	for _, name in {"Message", "Notify", "Hint", "TimeMessage", "TimeHint", "CustomNotify", "Warn", "Broadcast", "CustomMessage", "SystemNotify", "SystemMessage"} do
		local definition = assert((source .. adminSource):match("\n\t\t" .. name .. " = {(.-)\n\t\t};"), "Missing command: " .. name)
		local command = luau.load("return {" .. definition .. "}", {environment = env})()
		assert(command.UserText.Kind == "Chat", name .. " must declare native chat input")
		f.Server.TextPolicy.WrapCommand(command, name)
		f.Commands[name] = command
	end
	-- Mirrors dispatcher input authorization before invoking the registered command function.
	f.Run = function(name, args, options, actor)
		actor, options = actor or f.Players[1], options or {}
		options.UserCommandOrigin = options.UserCommandOrigin or f.Transport.NewOrigin(actor, ":command " .. table.concat(args, " "))
		local command = f.Commands[name]
		local input = f.Transport.CommandInput(actor, command, args, options)
		return command.Function(actor, args, {Options = options, ChatInput = input})
	end
	return f
end

-- Verifies that recipient control/UI payloads contain no authored announcement or warning text.
local function assertNoRecipientRelay(f)
	for _, event in f.Sent do
		if event.Command == "ChatSend" then
			assert(event.Player == f.Players[1], "Initial raw chat input left its actual author's client")
		else
			assert(not contains(event, rawBody) and not contains(event, rawTitle), "A control remote relayed authored text")
		end
	end
	assert(not contains(f.Outputs, rawBody) and not contains(f.Notices, rawBody), "A fallback UI relayed authored text")
end

-- Reports one independent routing or moderation invariant.
local function check(name, callback)
	callback()
	passed += 1
	print("PASS " .. name)
end

check("all announcement styles issue one native send without non-chat filtering or body remotes", function()
	for _, case in {
		{"Message", {rawBody}, "Message"}, {"Notify", {rawBody}, "Notify"}, {"Hint", {rawBody}, "Hint"},
		{"TimeMessage", {"73", rawBody}, "Message", 73}, {"TimeHint", {"91", rawBody}, "Hint", 91},
		{"CustomNotify", {rawTitle, rawBody}, "Notify"}, {"CustomMessage", {rawTitle, rawBody}, "Message"},
		{"Broadcast", {rawBody}, "ChatMessage"}, {"SystemNotify", {rawBody}, "Notify"}, {"SystemMessage", {rawBody}, "Message"},
	} do
		local f = fixture()
		f.Run(case[1], case[2])
		assert(#f.Sends() == 1 and #f.FilterCalls == 0 and #f.Notices == 0, "Announcement bypassed native transport or used non-chat filtering")
		local custom = case[1] == "CustomNotify" or case[1] == "CustomMessage"
		local expected = if custom then rawTitle .. "\n" .. rawBody else rawBody
		assert(f.Sends()[1].Args[3] == expected, "Native send changed the authenticated message fields")
		local opened = 0
		for _, event in f.Sent do
			if event.Command == "ChatChannelOpened" then
				opened += 1
				local descriptor = event.Args[1]
				assert(descriptor.Presentation == case[3] and descriptor.Kind == "Notification", "Announcement lost its display style")
				assert(descriptor.PresentToSender == true, "An all-player announcement excluded its author")
				if case[4] then
					assert(descriptor.Duration == case[4], "Timed announcement lost its requested duration")
				elseif case[1] ~= "Broadcast" then
					assert(descriptor.AutoDuration == true, "Announcement lost delivered-text duration calculation")
				end
				if custom then assert(descriptor.TitleMode == "Custom", "Custom title mode was lost") end
				if case[1] == "Broadcast" then assert(descriptor.TitleMode == "Broadcast", "Broadcast title mode was lost") end
			end
		end
		assert(opened >= 3, "The all-player announcement did not include every available player")
		assertNoRecipientRelay(f)
	end
end)

check("announcements reject generated, missing and substituted inputs without fallback delivery", function()
	for _, name in {"Message", "Notify", "Hint", "TimeMessage", "TimeHint", "CustomNotify", "Broadcast", "CustomMessage", "SystemNotify", "SystemMessage"} do
		local f = fixture()
		local args = if name == "CustomNotify" or name == "CustomMessage" then {rawTitle, rawBody} elseif name == "TimeMessage" or name == "TimeHint" then {"5", rawBody} else {rawBody}
		assert(not pcall(f.Commands[name].Function, f.Players[1], args), "A direct helper manufactured chat input")
		assert(not pcall(f.Run, name, args, {isSystem = true}), "A generated command manufactured chat input")
		assert(not pcall(f.Run, name, args, {OverrideArgs = {[1] = "forged"}}), "An overridden command manufactured chat input")
		assert(#f.Sends() == 0 and #f.Notices == 0, "Rejected input produced a fallback message")
		assertNoRecipientRelay(f)
	end
end)

check("announcement aliases retain chat metadata and incomplete broadcasts never invent text", function()
	local f = fixture()
	local aliases = {
		Message = {"m", "message"}, Notify = {"n", "smallmessage", "nmessage", "nmsg", "smsg", "smessage"},
		Hint = {"h", "hint"}, TimeMessage = {"tm", "timem", "timedmessage", "timemessage"},
		TimeHint = {"th", "timehint", "thint"}, CustomNotify = {"cn", "customsmallmessage", "cnmessage"},
		Broadcast = {"broadcast", "bc"}, CustomMessage = {"cm", "custommessage"},
		SystemNotify = {"sn", "systemnotify", "sysnotif", "sysnotify", "systemsmallmessage", "snmessage", "snmsg", "ssmsg", "ssmessage"},
		SystemMessage = {"sm", "systemmessage", "sysmsg"}, Warn = {"warn", "warning"},
	}
	for name, expected in aliases do
		local command = f.Commands[name]
		assert(command.Filter == nil and #command.Commands == #expected, "A command retained legacy filtering or lost aliases")
		for _, alias in expected do assert(table.find(command.Commands, alias), "Missing alias: " .. alias) end
		assert(command.UserText.Kind == "Chat" and command.UserText.Audience == (if name == "Warn" then "SelectedPlayers" else "AllPlayers"), "An alias bypasses the declared native route")
	end
	assert(not pcall(f.Run, "Broadcast", {}), "An empty broadcast manufactured a default message")
	assert(not pcall(f.Run, "CustomMessage", {rawTitle}), "A custom message accepted a missing body")
	assert(not pcall(f.Run, "CustomNotify", {rawTitle}), "A custom notification accepted a missing body")
	assert(#f.Sends() == 0 and #f.Notices == 0 and #f.Outputs == 0, "Missing arguments produced fallback content")
end)

check("warnings persist safe reasons before independently submitting a native message", function()
	local f = fixture()
	f.Unauthorized[f.Players[3].UserId] = true
	f.Run("Warn", {"targets", rawBody})
	local warning = f.PlayerData[f.Players[2]].Warnings[1]
	assert(warning.Message == "FILTERED_REASON" and warning.ReasonRecord.AuthorUserId == 1, "Warning lost safe content or real authorship")
	assert(f.PlayerData[f.Players[3]] == nil and #f.WarningEvents == 1 and f.WarningEvents[1][2] == "FILTERED_REASON", "Warning ignored authority or exposed raw event text")
	assert(#f.Sends() == 1 and f.Sends()[1].Args[3] == rawBody, "Warning did not submit its literal reason through native chat")
	assert(#f.Audits == 1 and f.Audits[1][4].DetailRecord == warning.ReasonRecord, "Warning lost its approved moderation audit")
	assertNoRecipientRelay(f)
end)

check("filter and chat failures do not cancel warnings or expose fallback reasons", function()
	local f = fixture()
	f.FailFilter = true
	f.Denied[2], f.Denied[3] = true, true
	f.Run("Warn", {"targets", rawBody})
	for _, player in f.Targets do
		local warning = f.PlayerData[player].Warnings[1]
		assert(warning.Message == "Reason unavailable" and warning.ReasonRecord == nil, "Filter outage retained raw moderation text")
	end
	assert(#f.Sends() == 0 and #f.WarningEvents == 2, "Chat unavailability cancelled moderation or caused fallback submission")
	assertNoRecipientRelay(f)
end)

check("sudo and offline warnings preserve action provenance without manufacturing speech", function()
	local f = fixture()
	f.Targets = {f.Players[3], {UserId = 99, Name = "Offline", Offline = true}}
	local origin = f.Transport.NewOrigin(f.Players[1], ":sudo actor :warn targets " .. rawBody)
	f.Run("Warn", {"targets", rawBody}, {isSystem = true, UserCommandOrigin = origin}, f.Players[2])
	for _, player in f.Targets do
		assert(f.PlayerData[player].Warnings[1].ReasonRecord.AuthorUserId == 1, "Sudo reattributed a warning's stored reason")
	end
	assert(#f.FilterCalls == 1 and f.FilterCalls[1].Author == f.Players[1], "Sudo filtered against its execution actor")
	assert(#f.Saved == 1 and f.Saved[1].UserId == 99, "Offline warning persistence was lost")
	assert(#f.Sends() == 0, "Sudo generated another player's chat message")
	assertNoRecipientRelay(f)
end)

check("warning detail audits respect invocation logging opt-outs", function()
	local f = fixture()
	f.Run("Warn", {"targets", rawBody}, {DontLog = true})
	assert(#f.Audits == 0 and #f.WarningEvents == 2, "Logging preference altered moderation or was ignored")
end)

print(`Announcement commands: {passed} checks passed`)
