-- Run with `lune run Tests/Settings.spec.luau`; mocks isolate settings persistence and editor contracts.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local secret = "UNFILTERED_SETTINGS_SECRET"
local player, otherPlayer = {}, {}
local nextId, reservations = 0, 0
local saved = {SavedSettings = {}, SavedTables = {}}
local server = {
	Settings = {SystemTitle = "System", Banned = {}, Ranks = {Creators = {Level = 900}, Moderators = {Users = {}}}, DataStoreEnabled = true},
	OriginalSettings = {SystemTitle = "System", Banned = {}, Ranks = {Creators = {Level = 900}, Moderators = {Users = {}}}},
	Remote = {BlockedSettings = {}}, Logs = {AddLog = function() end}, Client = {UI = {GetChildren = function() return {} end}},
	Deps = {DataStoreService = "MockDatastore"}, Functions = {},
}
local trusted = setmetatable({}, {__mode = "k"})
server.TextPolicy = {
	TryPublicEdit = function() reservations += 1 return reservations == 1, 60 end,
	CreateRecord = function(_, _, kind)
		local record = {Version = 1, AuthorUserId = 17, Kind = kind, Text = "FILTERED_SETTINGS"}
		trusted[record] = true
		return record
	end,
	GetRecordText = function(record) return if trusted[record] then record.Text else nil end,
	CreatePublication = function(records) return {Version = 1, Id = "publication", Records = records} end,
	AcceptPublication = function(_, packet)
		if packet.Id ~= "publication" then return nil end
		for _, record in packet.Records do trusted[record] = true end
		return packet.Records
	end,
}
local service = {
	HttpService = {GenerateGUID = function() nextId += 1 return tostring(nextId) end},
	Queue = function() end, TrackTask = function() end,
	DeepCopy = function(value) return serde.decode("json", serde.encode("json", value)) end,
}
local env = setmetatable({script = {}, game = {JobId = "current"}, require = function() return function() return {} end end}, {__index = getfenv()})
local loader = luau.load(fs.readFile("MainModule/Server/Core/Core.luau"), {environment = env})()
loader({Server = server, Service = service}, function() return env end)
local core = server.Core
core.GetLoadstring = function() return "MockLoadstring" end
core.Init({})
core.DataStore = {}
core.UpdateData = function(key, callback) saved[key] = callback(saved[key]) end
core.GetData = function(key) return saved[key], true end
core.CrossServer = function() end

local accepted, value, record = core.PrepareSetting(player, "SystemTitle", secret)
assert(accepted and value == secret and record.Text == "FILTERED_SETTINGS", "Raw operation and safe display were not separated")
server.Settings.SystemTitle = value
core.RegisterSettingText("SystemTitle", value, record)
assert(core.ProjectSetting("SystemTitle") == "FILTERED_SETTINGS", "Current text did not use its verified record")
assert(reservations == 1 and core.ProjectSetting("SystemTitle") == "FILTERED_SETTINGS" and reservations == 1, "Reading must not consume edit admission")
assert(not core.PrepareSetting(player, "SystemTitle", secret), "Second edit bypassed shared admission")
assert(not core.PrepareSetting(player, "NotASetting", secret), "Unknown setting was accepted")
assert(not core.PrepareSetting(player, "Banned", secret), "A primitive replaced an operational table")

core.DoSave({Type = "SetSetting", Setting = "SystemTitle", Value = value, TextRecord = record})
assert(saved.SavedSettings.SystemTitle == secret, "Operational value was overwritten by its display projection")
assert(saved.SavedSettings.__AdonisTextRecords.SystemTitle.Text == "FILTERED_SETTINGS", "Provenance was lost during persistence")
core.LoadData("SavedSettings", serde.decode("json", serde.encode("json", saved.SavedSettings)))
assert(not core.ProjectSetting("SystemTitle"):find(secret, 1, true), "Persisted text trusted an offline author's old snapshot")
assert(server.Settings.SystemTitle == secret, "Redaction overwrote operational configuration")

table.insert(server.Settings.Banned, secret)
core.RegisterTableText(server.Settings.Banned, secret, record)
local entries = core.GetSettingsTableEntries(player, "Banned")
assert(entries[1].Text == "FILTERED_SETTINGS" and entries[1].Id and entries[1].Value == nil, "Editor exposed raw values instead of handles")
assert(core.ResolveSettingsEntry(otherPlayer, "Banned", entries[1].Id) == nil, "Another viewer reused a removal handle")
assert(core.ResolveSettingsEntry(player, "Muted", entries[1].Id) == nil, "A handle changed its target table")
local tab, index, raw = core.ResolveSettingsEntry(player, "Banned", entries[1].Id)
assert(tab == server.Settings.Banned and index == 1 and raw == secret, "Safe display did not preserve exact removal target")
assert(core.ResolveSettingsEntry(player, "Banned", entries[1].Id) == nil, "Removal handle replay succeeded")
assert(core.GetEditableSettingsTable({"Core", "Variables", "TimeBans"}) == nil, "Editor reached an internal server table")
local malformedPath = {"Settings", "Ranks", "Moderators", "Users"}
malformedPath.Extra = secret
assert(core.GetEditableSettingsTable(malformedPath) == nil, "A malformed path reached persistence")

server.Settings.Ranks[secret] = {Level = 200, Users = {secret, "UnverifiedName:123", 456}}
local rank = core.ProjectRank(secret)
assert(rank.Name == "Custom rank" and rank.Level == 200, "Dynamic rank label bypassed projection")
assert(not serde.encode("json", rank):find(secret, 1, true) and rank.Users[2] == "User ID: 123", "Rank users lost safe identifiers or exposed unattributed labels")
local catalog = {{Name = "Developer catalog item", ID = 42}}
core.RegisterStaticSettingValue("MusicList", catalog)
table.insert(catalog, {Name = secret, ID = 84})
local assets = core.ProjectAssetList(catalog, "MusicList")
assert(assets[1].Text == "Developer catalog item - 42" and not serde.encode("json", assets):find(secret, 1, true), "Catalog trust extended beyond the loader snapshot")
local externalAssets = core.ProjectAssetList({{Name = secret, ID = "168"}, {Name = secret, ID = secret}}, "MusicList", true)
assert(#externalAssets == 1 and externalAssets[1].Desc == "168" and not serde.encode("json", externalAssets):find(secret, 1, true), "External catalog exposed names or invalid identifiers")
print("Settings contracts passed: filtering, admission, persistence, redaction, handles, path validation and catalog/rank projections")
