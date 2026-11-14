-- Run with `lune run Tests/AdminCommandWrappers.spec.luau` from the repository root.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("MainModule/Server/Core/Admin.luau")

local function loadMethods(methodNames, environment)
	local definitions = {}
	for _, methodName in methodNames do
		local start = assert(source:find(`\t\t{methodName} = function`, 1, true), `Missing Admin.{methodName}`)
		local finish = source:find("\n\t\t[%a_][%w_]* = function", start) or #source + 1
		table.insert(definitions, source:sub(start, finish - 1))
	end
	local chunk = "return {\n" .. table.concat(definitions, "\n") .. "\n}"
	return luau.load(chunk, {environment = environment})()
end

local player = {Name = "Player", UserId = 11}
local commands = {
	privileged = {
		AdminLevel = 50,
		AllowDonors = true,
		Args = {"target", "message"},
		Function = function() end,
	},
	public = {
		AdminLevel = 0,
		Args = {"message"},
		Function = function() end,
	},
	["player-table-level"] = {
		AdminLevel = {0},
		Args = {"message"},
		Function = function() end,
	},
}
local calls = {}
local admin = {
	GetCommand = function(command) return command, commands[command] end,
	GetLevel = function(target) assert(target == player, "Wrapper requested level for a different player"); return 75 end,
	CheckDonor = function(target) assert(target == player, "Wrapper requested donor state for a different player"); return true end,
	GetArgs = function(command, count, ...)
		local args = table.pack(...)
		assert(count == #commands[command].Args, "Wrapper requested the wrong argument count")
		return args
	end,
}
local settings = {DonorCommands = false}
local trackTask = function(name, callback, onError, actor, args, options)
	table.insert(calls, {
		Name = name,
		Callback = callback,
		OnError = onError,
		Actor = actor,
		Args = args,
		Options = options,
	})
end
local environment = setmetatable({
	Admin = admin,
	Settings = settings,
	TrackTask = trackTask,
	Remote = {},
	Color3 = {new = function() return {} end},
}, {__index = getfenv()})
local methods = loadMethods({"RunCommandAsPlayer", "RunCommandAsNonAdmin"}, environment)

methods.RunCommandAsPlayer("privileged", player, "target-name", "two words")
local invocation = calls[1]
assert(invocation.Actor == player and invocation.Callback == commands.privileged.Function, "Player wrapper used the wrong execution actor or command")
assert(invocation.Args[1] == "target-name" and invocation.Args[2] == "two words", "Player wrapper changed parsed command arguments")
assert(invocation.Options.PlayerData.Player == player and invocation.Options.PlayerData.Level == 75, "Player wrapper lost the target player's admin context")
assert(invocation.Options.PlayerData.isDonor, "Player wrapper lost eligible donor status")

commands.privileged.AllowDonors = false
methods.RunCommandAsPlayer("privileged", player)
assert(not calls[2].Options.PlayerData.isDonor, "Player wrapper granted donor status when the command did not opt in")

methods.RunCommandAsNonAdmin("public", player, "public argument")
invocation = calls[3]
assert(invocation.Actor == player and invocation.Callback == commands.public.Function, "Non-admin wrapper did not execute the public command as the player")
assert(invocation.Options.PlayerData.Player == player and invocation.Options.PlayerData.Level == 0 and not invocation.Options.PlayerData.isDonor, "Non-admin wrapper elevated the execution context")
assert(invocation.Args[1] == "public argument", "Non-admin wrapper changed parsed command arguments")

methods.RunCommandAsNonAdmin("privileged", player, "ignored")
methods.RunCommandAsNonAdmin("player-table-level", player, "ignored")
assert(#calls == 3, "Non-admin wrapper executed a command that was not exactly player-level")

print("Admin command wrapper contracts passed")
