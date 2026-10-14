-- Run with `lune run Tests/ModerationAudit.spec.luau`; exercises resolved ban targets and originating actors.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local secret = "UNFILTERED_MODERATION_INPUT"
local actor, executionPlayer, target = {UserId = 17}, {UserId = 23}, {UserId = 500, Name = secret}
local safeRecord = {Version = 1, AuthorUserId = 17, Kind = "Moderation", Text = "FILTERED_REASON"}
local audits, saves, calls = {}, {}, 0
local server = {TextPolicy = {
	GetCommandAuthor = function(player) assert(player == executionPlayer, "Execution actor unexpectedly changed"); return actor end,
	CreateRecord = function(_, author) assert(author == actor, "Reason filtering impersonated the execution identity"); calls += 1; return safeRecord end,
	GetRecordText = function(record) return record == safeRecord and record.Text end,
	CreatePublication = function(records) return {Records = records} end,
}}
local env = setmetatable({
	server = server, Settings = {Banned = {}},
	Core = {Variables = {TimeBans = {}}, DoSave = function(value) table.insert(saves, value) end, CrossServer = function() end},
	service = {FormatPlayer = function() return "Execution player" end, Events = {PlayerBanned = {Fire = function() end}}},
	Logs = {AddAudit = function(category, event, author, metadata)
		table.insert(audits, {Category = category, Event = event, AuthorUserId = author.UserId, Metadata = metadata})
	end},
}, {__index = getfenv()})
local source = fs.readFile("MainModule/Server/Core/Admin.luau")
local first = assert(source:find("\t\tAddBan = function", 1, true))
local finish = assert(source:find("\t\tDoBanCheck = function", first, true))
local methods = luau.load("return {" .. source:sub(first, finish - 1) .. "}", {environment = env})()
methods.AddBan(target, secret, true, executionPlayer)
methods.AddTimeBan(target, 60, secret, executionPlayer)
assert(calls == 2 and #audits == 2 and #saves == 2, "Resolved moderation actions lost their reason or audit producers")
for index, event in {"Ban", "TimeBan"} do
	local audit = audits[index]
	assert(audit.Event == event and audit.AuthorUserId == actor.UserId and audit.Metadata.Outcome == "Completed", "Moderation audit lost its originating actor or actual operation")
	assert(#audit.Metadata.TargetUserIds == 1 and audit.Metadata.TargetUserIds[1] == target.UserId, "Moderation audit did not retain its resolved target ID")
	assert(audit.Metadata.DetailRecord == safeRecord and saves[index].Value.Reason == safeRecord.Text, "Moderation persisted raw reason text")
end
assert(not serde.encode("json", audits):find(secret, 1, true), "Target name or raw reason escaped in an audit event")
print("Moderation audit contracts passed: originating author, resolved target, canonical operation and safe reason")
