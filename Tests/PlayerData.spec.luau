-- Run with `lune run Tests/PlayerData.spec.luau`; verifies the actual private-preferences remote DTO.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local secret = "OTHER_AUTHORS_PRIVATE_MODERATION_TEXT"
local stored = {
	AdminLevel = 10, AdminRank = secret, PluginExtra = {Text = secret},
	AdminNotes = {secret}, Warnings = {{Message = secret}}, Banned = {Reason = secret},
	Aliases = {[":own <text>"] = ":pm me <text>", Unknown = {Text = secret}},
	Keybinds = {["101"] = ":fly me", Unknown = {Text = secret}},
	Donor = {Enabled = true, Unknown = secret, Cape = {Color = {0.2, 0.3, 0.4}, Image = "123", Material = "Neon", Unknown = secret}},
}
local env = setmetatable({
	Core = {GetPlayer = function() return stored end},
	Admin = {GetLevel = function() return 300 end, CheckDonor = function() return true end},
}, {__index = getfenv()})
local source = fs.readFile("MainModule/Server/Core/Remote.luau")
local first = assert(source:find("\t\t\tPlayerData = function", 1, true))
local finish = assert(source:find("\t\t\tCheckAdmin = function", first, true))
local getData = luau.load("return {" .. source:sub(first, finish - 1) .. "}", {environment = env})().PlayerData
local result = getData({}, {})
assert(not serde.encode("json", result):find(secret, 1, true), "The player-data response exposed other-authored records or unknown fields")
assert(result.AdminLevel == 300 and result.isDonor and result.Donor.Enabled, "Native command visibility or donor UI metadata was lost")
assert(result.Aliases[":own <text>"] == ":pm me <text>" and result.Keybinds["101"] == ":fly me", "The caller's command preferences were discarded")
assert(result.Donor.Cape.Image == "123" and result.Donor.Cape.Color[1] == 0.2, "Supported cape preferences were discarded")
result.Donor.Cape.Color[1], result.Aliases[":own <text>"] = 1, "changed"
assert(stored.Donor.Cape.Color[1] == 0.2 and stored.Aliases[":own <text>"] == ":pm me <text>", "A response mutated persisted private preferences")
print("Player data contracts passed: UI allowlist, moderation/plugin exclusion, own preferences and copied response")
