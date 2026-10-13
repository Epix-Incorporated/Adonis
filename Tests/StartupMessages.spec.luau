-- Run with `lune run Tests/StartupMessages.spec.luau`; executes the startup projection and recipient sink.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local serde = require("@lune/serde")
local secret = "UNATTRIBUTED_STARTUP_TEXT"
local record = {Version = 1, Kind = "Audit", AuthorUserId = 17, Text = "FILTERED_STARTUP_TEXT"}
local server = {Messages = {}, TextPolicy = {GetRecordText = function(value) return if value == record then record.Text else nil end}}
local env = setmetatable({server = server, startupMessages = {}}, {__index = getfenv()})
local source = fs.readFile("MainModule/Server/Server.luau")
local first = assert(source:find("\tAddSystemMessage = function", 1, true))
local following = assert(source:find("\tRunning = true", first, true))
local methods = luau.load("return {" .. source:sub(first, following - 1) .. "}", {environment = env})()
server.AddSystemMessage, server.ProjectSystemMessage = methods.AddSystemMessage, methods.ProjectSystemMessage

local configured = {Title = "Developer title", Message = "Developer message", Time = 10}
server.AddSystemMessage(configured)
configured.Title, configured.Message = secret, secret
local projected = server.ProjectSystemMessage(configured)
assert(projected.Title == "Developer title" and projected.Message == "Developer message", "A registered notice changed with its mutable source")
projected.Message = secret
assert(server.ProjectSystemMessage(configured).Message == "Developer message", "A returned projection mutated the retained snapshot")
server.AddSystemMessage("Developer string")
assert(server.ProjectSystemMessage("Developer string").Message == "Developer string", "Registered developer text was discarded")
for _, untrusted in {secret, {Title = secret, Message = secret, onClick = secret}, {MessageRecord = table.clone(record)}} do
	assert(not serde.encode("json", server.ProjectSystemMessage(untrusted)):find(secret, 1, true), "An unknown startup notice exposed raw fields")
end
assert(server.ProjectSystemMessage({Title = secret, MessageRecord = record}).Message == record.Text, "A verified nonchat record was discarded")
assert(server.ProjectSystemMessage({MessageRecord = table.clone(record)}).Message == "Notice text unavailable", "Persisted/offline text reused runtime trust")

local displayed = {}
local processSource = fs.readFile("MainModule/Server/Core/Process.luau")
local start = assert(processSource:find("\t\t\t\t\tif Settings.Notification then", 1, true))
local finish = assert(processSource:find("\t\t\t\t\tif Process.SaveDatastoreVersionDebounce then", start, true))
env.Settings = {Notification = true}
env.Functions = {Notification = function(title, message) table.insert(displayed, {Title = title, Message = message}) end}
env.Core = {
	ProjectRank = function(name) return if name == "Moderators" then {Name = "Moderators"} else nil end,
	Bytecode = function(text) return text end,
}
env.task = {wait = function() end, delay = function(_, callback, ...) callback(...) end}
env.p = {}
table.insert(server.Messages, {Title = secret, Message = secret})
local show = luau.load("return function(rank, level)\n" .. processSource:sub(start, finish - 1) .. "\nend", {environment = env})()
for _, rank in {"Place Owner", "Moderators", secret} do
	show(rank, if rank == "Place Owner" then 1000 else 300)
end
show(nil, 300)
assert(#displayed == 16, "A missing rank interrupted welcome or startup notice delivery")
assert(not serde.encode("json", displayed):find(secret, 1, true), "The actual startup sink bypassed the safe projection")
print("Startup message contracts passed: immutable snapshots, unknown notices, record trust, recipient projection and special ranks")
