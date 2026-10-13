-- Run with `lune run Tests/NativeChatCommands.spec.luau`; executes the checkout's native registry.
-- These mocks cover registration and ingress ownership, not Roblox chat delivery.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("MainModule/Server/Core/Admin.luau")
local first = assert(source:find("\t\tCacheNativeChatCommands = function", 1, true))
local following = assert(source:find("\t\tGetCommand = function", first, true))
local children, sent, deferred, notices = {}, {}, {}, {}
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
		properties.IsA = function(_, class) return class == "TextChatCommand" end
		properties.Destroy = function(self) self.Destroyed = true end
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
admin.CacheNativeChatCommands = luau.load("local nativeChatRefreshQueued = false\nreturn {" .. source:sub(first, following - 1) .. "}", {environment = env})().CacheNativeChatCommands

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
core.PlayerData['1'].Aliases = {["!new <text>"] = ":pm 2 <text>"}
rebuild()
assert(not find(":secret") and find("!new"), "Alias edits must remove stale sinks and register replacements")
variables.ChatCreateRobloxCommands = false
rebuild()
assert(find(":multi") and not find(":multi").AutocompleteVisible, "Disabled autocomplete must retain ordinary native command execution")
settings.ChatCommands = false
rebuild()
assert(find(":pm") == host and find("/:pm") and not find(":multi"), "Disabled private commands must retain their sinks and preserve host ownership")
nativeSource.Parent.GetAttribute = function() return nil end
find("/:pm").Trigger(nativeSource, "/:pm 2 private-disabled")
assert(#sent == 1 and #notices == 1 and not notices[1]:find("private-disabled", 1, true), "Disabled commands must return only a fixed notice without execution")
print("Native chat registry contracts passed: prefixes, synonyms, host collision, alias scope, refresh, cleanup and author ingress")
