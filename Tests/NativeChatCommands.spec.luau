-- Run with `lune run Tests/NativeChatCommands.spec.luau`; executes the checkout's native registry.
-- These mocks cover registration and ingress ownership, not Roblox chat delivery.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("MainModule/Server/Core/Admin.luau")
local first = assert(source:find("\t\tGetNativeAliasToken = function", 1, true))
local following = assert(source:find("\t\tGetCommand = function", first, true))
local children, sent, deferred, notices = {}, {}, {}, {}
local failNextCreation = false
local settings = {ChatCommands = true, Prefix = {":", ";"}, PlayerPrefix = "!"}
local player = {UserId = 1}
local core = {PlayerData = {['1'] = {Aliases = {[":secret <text>"] = ":pm 2 <text>", ["hello <text>"] = ":pm 2 <text>"}}}}
local variables = {ChatCreateRobloxCommands = true, Aliases = {["global <text>"] = ":pm 2 <text>"}}
local admin = {CheckAliasBlacklist = function() return false end, StringToComLevel = function() return nil end}
local container = {}

-- Exposes live instances while retaining destroyed objects for cleanup assertions.
local function liveChildren()
	local result = {}
	for _, child in children do if not child.Destroyed then table.insert(result, child) end end
	return result
end
container.GetChildren = liveChildren
local textChatService = {
	ChatVersion = "Modern",
	FindFirstChild = function() return container end,
	GetDescendants = liveChildren,
}
local service = {
	TextChatService = textChatService,
	Players = {GetPlayers = function() return {player} end, GetPlayerByUserId = function(_, id) return id == 1 and player end},
	-- Creates a native command whose trigger can be invoked without copying registry logic.
	New = function(_, properties)
		if failNextCreation then failNextCreation = false; error("fixture creation failure") end
		properties.IsA = function(_, class) return class == "TextChatCommand" end
		properties.Destroy = function(self) self.Destroyed = true; self.Parent = nil end
		properties.SetAttribute = function(self, key, value)
			assert(type(value) ~= "table", "Native attributes cannot contain permission tables")
			self[key] = value
		end
		properties.Triggered = {Connect = function(_, callback) properties.Trigger = callback end}
		table.insert(children, properties)
		return properties
	end,
}
local host = service.New("TextChatCommand", {Name = "HostPM", PrimaryAlias = ":pm", SecondaryAlias = ""})
local env = setmetatable({
	Admin = admin, Core = core, Settings = settings, Variables = variables, service = service,
	Commands = {
		PrivateMessage = {Prefix = {":", ";"}, Commands = {"pm", "privatemessage"}, AdminLevel = 100, UserText = {Kind = "Chat"}},
		TablePermission = {Prefix = ":", Commands = {"multi"}, AdminLevel = {100, 200}},
	},
	Remote = {
		Commands = {ProcessCommand = function(actor, args) table.insert(sent, {Actor = actor, Text = args[1]}) end},
		MakeGui = function(_, _, data) table.insert(notices, data.Message) end,
	},
	Enum = {ChatVersion = {TextChatService = "Modern"}},
	task = {defer = function(callback) table.insert(deferred, callback) end},
	stripArgPlaceholders = function(alias) return alias:gsub("<%S+>", ""):match("^%s*(.-)%s*$") end,
}, {__index = getfenv()})
local implementation = luau.load("local nativeChatRefreshQueued, nativeChatReady = false, false\nlocal nativeChatRegistry, nativeChatSequence = {}, 0\nreturn {" .. source:sub(first, following - 1) .. "}", {environment = env})()
admin.GetNativeAliasToken = implementation.GetNativeAliasToken
admin.CacheNativeChatCommands = implementation.CacheNativeChatCommands

-- Rebuilds on the deferred boundary used by player load and alias edit hooks.
local function rebuild()
	admin.CacheNativeChatCommands()
	admin.CacheNativeChatCommands()
	assert(#deferred == 1, "Repeated refreshes should coalesce")
	table.remove(deferred, 1)()
end

-- Looks up either native spelling without assuming unordered registry iteration order.
local function find(alias)
	for _, command in liveChildren() do
		if command.PrimaryAlias == alias or command.SecondaryAlias == alias then return command end
	end
end

rebuild()
assert(find(":pm") == host and find("/:pm") ~= host, "A host collision must preserve the free slash variant")
assert(find(";pm") and find("/;pm") and find(":privatemessage"), "Every prefix and synonym must be registered")
assert(find(":secret") and not find(":secret").AutocompleteVisible, "Saved prefixed aliases need hidden native interception")
assert(find("global") and not find("hello"), "Unprefixed personal aliases must not intercept ordinary speech")
local names = {}
for _, command in liveChildren() do assert(not names[command.Name], "Native command names must be unique"); names[command.Name] = true end
local nativeSource = {UserId = 1, Parent = {GetAttribute = function() return nil end}}
find("/:pm").Trigger(nativeSource, "/:pm 2 literal")
assert(#sent == 1 and sent[1].Actor == player and sent[1].Text == ":pm 2 literal", "Native ingress must preserve author and submitted text")
nativeSource.Parent.GetAttribute = function() return "managed-channel" end
find("/:pm").Trigger(nativeSource, "/:pm 2 forbidden")
assert(#sent == 1, "Managed conversation messages must not execute commands")
local retainedPM, previousAllocations = find("/:pm"), #children
core.PlayerData['1'].Aliases = {["!new <text>"] = ":pm 2 <text>"}
rebuild()
assert(not find(":secret") and find("!new"), "Alias edits must remove stale sinks and register replacements")
assert(find("/:pm") == retainedPM and #children == previousAllocations + 1, "An alias edit must reuse unrelated native instances")
previousAllocations = #children
admin.CacheNativeChatCommands(true)
assert(#children == previousAllocations, "An unchanged registry must allocate no new instances")
admin.CacheNativeChatCommands()
core.PlayerData['1'].Aliases = {[":ready <text>"] = ":pm 2 <text>"}
admin.CacheNativeChatCommands(true, true)
assert(find(":ready") and not find("!new"), "An immediate refresh must install aliases before returning")
previousAllocations = #children
table.remove(deferred, 1)()
assert(#children == previousAllocations, "A superseded deferred refresh must be a no-op")
admin.CacheNativeChatCommands(true, true)
assert(#children == previousAllocations, "Flushing an already-ready registry must remain a no-op")
core.PlayerData['1'].Aliases = {[":recover <text>"] = ":pm 2 <text>"}
failNextCreation = true
admin.CacheNativeChatCommands()
assert(not pcall(table.remove(deferred, 1)) and not find(":recover"), "The fixture must fail during deferred native registration")
admin.CacheNativeChatCommands(true, true)
assert(find(":recover"), "An identical save must recover a failed refresh before reporting ready")
local legacy = {}
for index = 1, 64 do legacy[":legacy" .. index .. " <text>"] = ":pm 2 <text>" end
core.PlayerData['1'].Aliases = legacy
rebuild()
for index = 1, 64 do assert(find(":legacy" .. index), "Every admitted technical alias needs a native sink") end
legacy[":legacy65"] = ":pm 2 <text>"
rebuild()
for index = 1, 65 do assert(not find(":legacy" .. index), "Oversized legacy maps must be wholly command-bar-only") end
assert(not admin.GetNativeAliasToken(":bad! <text>") and not admin.GetNativeAliasToken(":" .. string.rep("x", 64)), "Native technical tokens must enforce syntax and byte limits")
assert(admin.GetNativeAliasToken(":valid-name_2 <text>") == ":valid-name_2", "Supported native identifiers must remain usable")
variables.ChatCreateRobloxCommands = false
rebuild()
assert(find(":multi") and not find(":multi").AutocompleteVisible, "Disabled autocomplete must retain ordinary native command execution")
settings.ChatCommands = false
rebuild()
assert(find(":pm") == host and find("/:pm") and not find(":multi"), "Disabled private commands must retain their sinks and preserve host ownership")
nativeSource.Parent.GetAttribute = function() return nil end
find("/:pm").Trigger(nativeSource, "/:pm 2 private-disabled")
assert(#sent == 1 and #notices == 1 and not notices[1]:find("private-disabled", 1, true), "Disabled commands must return only a fixed notice without execution")

-- Exercises native ingress through the real remote handler, parser, aliases and permission check.
local process, functions, executions = {MsgStringLimit = 500}, {}, {}
local server = {Settings = settings}
local aliases, rateAllowed, commandRateChecks = {}, true, 0
settings.SplitKey, settings.BatchKey, settings.ChatCommands = " ", "|", true
settings.Ranks, settings.PlayerCommands = {Creators = {Level = 900}}, true
player.Name, player.Parent = "Author", service.Players
player.IsA = function(_, class) return class == "Player" end
service.UnWrap = function(value) return value end
service.HttpService = {GenerateGUID = function() return "invocation" end}
service.Events = {CommandRan = {Fire = function() end}}
service.Trim = function(text) return text:match("^%s*(.-)%s*$") end
service.SanitizePattern = function(text) return text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") end
env.server, env.script, env.Process, env.Functions = server, {}, process, functions
env.Logs = {AddAudit = function() end}
env.typeof = function(value) return if value == player then "Instance" else typeof(value) end
env.TrackTask = function(_, callback, onError, ...)
	local result = table.pack(pcall(callback, ...))
	if not result[1] then onError(result[2]) end
	return table.unpack(result, 1, result.n)
end
process.RateLimit = function(_, kind)
	if kind ~= "Command" then return false end
	commandRateChecks += 1
	return rateAllowed
end

-- Loads a complete declaration from the implementation without duplicating its behavior.
local function declaration(text, startMarker, endMarker)
	local start = assert(text:find(startMarker, 1, true), `Missing declaration: {startMarker}`)
	local finish = assert(text:find(endMarker, start + #startMarker, true), `Missing boundary: {endMarker}`)
	return text:sub(start, finish - 1)
end

local processSource = fs.readFile("MainModule/Server/Core/Process.luau")
local remoteSource = fs.readFile("MainModule/Server/Core/Remote.luau")
local functionsSource = fs.readFile("MainModule/Server/Core/Functions.luau")
functions.Trim = service.Trim
functions.Split = luau.load("return {" .. declaration(functionsSource, "\t\tSplit = function", "\t\tIsValidTexture = function") .. "}", {environment = env})().Split
admin.GetArgs = luau.load("return {" .. declaration(source, "\t\tGetArgs = function", "\t\tAliasFormat = function") .. "}", {environment = env})().GetArgs
admin.AliasFormat = luau.load(declaration(source, "\tlocal function stripArgPlaceholders", "\tserver.Admin = {") .. "\nreturn {"
	.. declaration(source, "\t\tAliasFormat = function", "\t\tStringToComLevel = function") .. "}", {environment = env})().AliasFormat
admin.CheckPermission = luau.load("return {" .. declaration(source, "\t\tCheckPermission = function", "\t\tUpdateCooldown = function") .. "}", {environment = env})().CheckPermission
admin.GetAliases = function() return aliases end
admin.GetLevel = function() return 100 end
admin.IsPlaceOwner = function() return false end
admin.IsBlacklisted = function() return false end
admin.CheckComLevel = function(level, required) return level >= required end
admin.CheckAdmin = function() return true end
admin.UpdateCooldown = function() end
local restricted = {
	Prefix = ":", Commands = {"restricted"}, Args = {}, AdminLevel = 100, NonChattable = true,
	-- Records successful execution and verifies that explicit submission author context survives dispatch.
	Function = function(actor, _, data)
		assert(server.ChatTransport.ResolveOriginAuthor(data.Options.UserCommandOrigin) == actor, "Ingress lost its original author")
		table.insert(executions, {Chat = data.Options.Chat})
	end,
}
env.Commands.Restricted = restricted
admin.GetCommand = function(text)
	if text:match("^(%S+)") == ":restricted" then return "Restricted", restricted, ":restricted" end
end
local transportLoader = luau.load(fs.readFile("MainModule/Server/Core/ChatTransport.luau"), {environment = env})()
transportLoader({Server = server, Service = service}, function() return env end)
process.GetOverrideMap = luau.load("return {" .. declaration(processSource, "\t\tGetOverrideMap = function", "\t\tCommand = function") .. "}", {environment = env})().GetOverrideMap
process.Command = luau.load("return {" .. declaration(processSource, "\t\tCommand = function", "\t\tCrossServerChat = function") .. "}", {environment = env})().Command
env.Remote.Commands.ProcessCommand = luau.load("return {" .. declaration(remoteSource, "\t\t\tProcessCommand = function", "\t\t\tProcessChat = function") .. "}", {environment = env})().ProcessCommand
aliases = {[":shortcut"] = ":restricted"}
core.PlayerData['1'].Aliases = aliases
rebuild()
for _, input in {":restricted", "/:restricted", ":shortcut", ":restricted | :restricted"} do
	local token = input:match("^(%S+)")
	find(token).Trigger(nativeSource, input)
end
assert(#executions == 0 and commandRateChecks == 4, "Native commands, slash variants, aliases and batches must preserve NonChattable checks")
local noticeCount = #notices
local clientArgs = {":restricted"}
clientArgs.Chat = true
env.Remote.Commands.ProcessCommand(player, clientArgs)
assert(#executions == 1 and executions[1].Chat == false and #notices == noticeCount, "Command-bar requests must remain usable and ignore client-supplied origin flags")
restricted.NonChattable = false
find(":restricted").Trigger(nativeSource, ":restricted")
assert(#executions == 2 and executions[2].Chat == true, "Ordinary native commands must retain their chat and author context")
rateAllowed = false
find(":restricted").Trigger(nativeSource, ":restricted")
assert(#executions == 2 and commandRateChecks == 7, "Native ingress must retain command rate limiting")

-- Exercises literal broadcast submission through native and command-bar ingress.
local broadcastSource = fs.readFile("MainModule/Server/Commands/Admins.luau")
local broadcast = luau.load("return {" .. declaration(broadcastSource, "\t\tBroadcast = {", "\t\tShutdownLogs = {") .. "}", {environment = env})().Broadcast
broadcast.AdminLevel = 100
-- Supplies the connected audience for the real broadcast handler.
service.GetPlayers = function() return {player} end
local broadcastInput = [[<b>source</b> &lt; & "quoted" 'single']]
local broadcasts = {}
-- Rejects the former non-chat filtering and remote-body delivery paths.
service.TryFilter = function()
	error("Broadcast user messages must use native chat filtering")
end
local policyLoader = luau.load(fs.readFile("MainModule/Server/Core/TextPolicy.luau"), {environment = env})()
policyLoader({Server = server, Service = service}, function() return env end)
server.TextPolicy.WrapCommand(broadcast, "Broadcast")
env.Commands.Broadcast = broadcast
-- Resolves the broadcast definition while leaving parsing and permission checks intact.
admin.GetCommand = function(text)
	if text:match("^(%S+)") == ":broadcast" then return "Broadcast", broadcast, ":broadcast" end
end
-- Captures the actual parser-produced author capability at the transport boundary.
server.ChatTransport.SubmitCommand = function(actor, recipients, text, input, kind, presentation, options)
	assert(actor == player and recipients[1] == player and text == broadcastInput, "Broadcasts must preserve their literal input and actor")
	assert(type(input) == "table" and kind == "Notification" and presentation == "ChatMessage" and options.TitleMode == "Broadcast", "Broadcasts need an authenticated native send and selected presentation")
	table.insert(broadcasts, input)
end
env.Remote.Send = function()
	error("Broadcasts cannot relay message bodies through display remotes")
end
rateAllowed = true
rebuild()
find(":broadcast").Trigger(nativeSource, ":broadcast " .. broadcastInput)
find("/:broadcast").Trigger(nativeSource, "/:broadcast " .. broadcastInput)
env.Remote.Commands.ProcessCommand(player, {":broadcast " .. broadcastInput})
assert(#broadcasts == 3 and broadcasts[1] ~= broadcasts[2] and broadcasts[2] ~= broadcasts[3], "Every explicit ingress must receive its own native send capability")

-- Canonical cross-server operations must not expand aliases from the receiving server.
local receivedCrossArgs
local operation = {Prefix = ":", Commands = {"operation"}, Args = {"value"}, AdminLevel = 100,
	Function = function(_, args) receivedCrossArgs = args end,
}
aliases[":operation"] = ":broadcast injected text"
admin.GetCommand = function(text)
	if text == ":operation" then return "Operation", operation, ":operation" end
	if text:match("^(%S+)") == ":broadcast" then return "Broadcast", broadcast, ":broadcast" end
end
process.Command(player, ":operation", {CrossServer = true, Args = {"validated operation"}, AdminLevel = 100})
assert(receivedCrossArgs and receivedCrossArgs[1] == "validated operation" and #broadcasts == 3, "Destination aliases changed a validated cross-server operation")

-- Exercises actual plugin registration, including the loader's removal of startup hooks before Init.
local registrationAdmin = {
	PrefixCache = {}, CommandCache = {},
	CheckAliasBlacklist = admin.CheckAliasBlacklist,
	StringToComLevel = admin.StringToComLevel,
}
local registrationErrors, registrationSubmissions = {}, {}
local registrationServer = {
	Settings = {Prefix = ":", PlayerPrefix = "!", ChatCommands = true},
	Admin = registrationAdmin,
	Core = {PlayerData = {}},
	Variables = {Aliases = {}, ChatCreateRobloxCommands = true},
	Logs = {AddLog = function() end, ListUpdaters = {}},
	Typechecker = luau.load(fs.readFile("MainModule/Shared/Typechecker.luau"))(),
	Remote = {Commands = {
		-- Records the submitted text and chat provenance supplied by the native handler.
		ProcessCommand = function(actor, args, fromChat)
			table.insert(registrationSubmissions, {Actor = actor, Text = args[1], FromChat = fromChat})
		end,
	}},
}
local registrationEnv = setmetatable({
	script = {}, Enum = env.Enum, task = env.task,
	stripArgPlaceholders = env.stripArgPlaceholders,
	-- Collects validation failures without concealing unexpected runtime errors.
	logError = function(...) table.insert(registrationErrors, {...}) end,
}, {__index = getfenv()})
local registryLoader = luau.load(fs.readFile("MainModule/Server/Core/Commands.luau"), {environment = registrationEnv})()
registryLoader({Server = registrationServer, Service = service}, function() return registrationEnv end)
registrationEnv.Admin, registrationEnv.Commands = registrationAdmin, registrationServer.Commands
registrationEnv.Settings, registrationEnv.Variables = registrationServer.Settings, registrationServer.Variables
registrationEnv.Core, registrationEnv.Remote = registrationServer.Core, registrationServer.Remote
registrationEnv.service = service
-- The module clears exported globals before returning its loader, as in the real server environment.
registrationEnv.logError = function(...) table.insert(registrationErrors, {...}) end
local cacheFirst = assert(source:find("\t\tCacheCommands = function", 1, true))
local registrationCache = luau.load("local nativeChatRefreshQueued, nativeChatReady = false, false\nlocal nativeChatRegistry, nativeChatSequence = {}, 0\nreturn {"
	.. source:sub(cacheFirst, following - 1) .. "}", {environment = registrationEnv})()
for key, value in registrationCache do registrationAdmin[key] = value end
local afterPlugins = registrationServer.Commands.RunAfterPlugins
rawset(registrationServer.Commands, "RunAfterPlugins", nil)
registrationServer.Commands.Init()

-- Produces a valid plugin definition while leaving default filling and validation to the registry.
local function pluginCommand(alias)
	return {Prefix = ":", Commands = {alias}, Args = {}, Description = "Plugin command", AdminLevel = 100, Function = function() end}
end

registrationServer.Commands.StartupPlugin = pluginCommand("startupplugin")
registrationServer.Settings.Commands = {SettingsPlugin = pluginCommand("settingsplugin")}
assert(#deferred == 0, "Startup registrations must not queue per-command native refreshes")
afterPlugins()
assert(#deferred == 1, "Startup must coalesce its final native interception refresh")
table.remove(deferred, 1)()
assert(find(":startupplugin") and find(":settingsplugin"), "Startup interception must include both plugin loading paths")
local retainedStartup = find(":startupplugin")

registrationServer.Commands.LatePlugin = pluginCommand("lateplugin")
registrationServer.Commands.AnotherLatePlugin = pluginCommand("anotherlateplugin")
assert(registrationAdmin.CommandCache[":lateplugin"] == "LatePlugin", "Late registration must update the internal dispatcher")
assert(#deferred == 1 and not find(":lateplugin"), "Late plugin additions must queue one native refresh")
table.remove(deferred, 1)()
assert(find(":lateplugin") and find("/:lateplugin") and find(":anotherlateplugin"), "Late plugin aliases need both native spellings")
assert(find(":startupplugin") == retainedStartup, "Late registration must retain unchanged native handlers")
find(":lateplugin").Trigger(nativeSource, ":lateplugin literal")
find("/:lateplugin").Trigger(nativeSource, "/:lateplugin literal")
assert(#registrationSubmissions == 2, "Both native spellings must dispatch the late plugin command")
for _, submission in registrationSubmissions do
	assert(submission.Actor == player and submission.Text == ":lateplugin literal" and submission.FromChat,
		"Late command interception must preserve its caller, literal text and chat provenance")
end

local invalidPlugin = pluginCommand("invalidplugin")
invalidPlugin.Function = "invalid"
registrationServer.Commands.InvalidPlugin = invalidPlugin
assert(#registrationErrors == 1 and rawget(registrationServer.Commands, "InvalidPlugin") == nil,
	"Invalid definitions must not remain in the command registry")
assert(#deferred == 0, "Rejected registrations must not schedule a native refresh")
registrationAdmin.CacheNativeChatCommands(true)
assert(not find(":invalidplugin") and find(":lateplugin"), "Rejected definitions must never acquire native interception")
print("Native chat registry contracts passed: aliases, lifecycle, provenance, permissions, rate limiting, native broadcasts, cross-server canonical dispatch and late plugin registration")
