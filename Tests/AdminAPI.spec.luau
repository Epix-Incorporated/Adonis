-- Run with `lune run Tests/AdminAPI.spec.luau` from the repository root.
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local source = fs.readFile("MainModule/Server/Core/Core.luau")
local startMarker = "\t\tStartAPI = function()"
local start = assert(source:find(startMarker, 1, true), "Core.StartAPI was not found")
local finishMarker = "\n\t\tend;\n\t};\nend"
local finish = assert(source:find(finishMarker, start, true), "Core.StartAPI boundary was not found")
local implementation = source:sub(start + #"\t\tStartAPI = ", finish + #"\n\t\tend;" - 1)

local function alwaysValid()
	return function()
		return true
	end
end

local function instanceOf(className)
	return function(value)
		return type(value) == "table" and value.ClassName == className
	end
end

local typechecker = {
	string = alwaysValid(),
	number = alwaysValid(),
	boolean = alwaysValid(),
	any = alwaysValid(),
	array = function() return alwaysValid() end,
	map = function() return alwaysValid() end,
	optional = function() return alwaysValid() end,
	instanceOf = instanceOf,
	instanceIsA = instanceOf,
	union = function(...)
		local checks = {...}
		return function(value)
			for _, check in checks do
				if check(value) then
					return true
				end
			end
			return false
		end
	end,
	strictInterface = function()
		return function(value)
			if type(value) ~= "table" or type(value.UserId) ~= "number" or value.UserId % 1 ~= 0 then
				return false
			end
			if value.Name ~= nil and type(value.Name) ~= "string" then
				return false
			end
			for key in value do
				if key ~= "UserId" and key ~= "Name" then
					return false
				end
			end
			return true
		end
	end,
	integer = function(value)
		return type(value) == "number" and value % 1 == 0
	end,
}

local function makeProxy(meta)
	return setmetatable({}, meta)
end

local readOnlyWarnings = {}
local function readOnly(value)
	return setmetatable({}, {
		__index = function(_, key)
			local result = value[key]
			return if type(result) == "table" then readOnly(result) else result
		end,
		__newindex = function(_, key)
			table.insert(readOnlyWarnings, `Read-only write blocked: {key}`)
		end,
	})
end

local function makeMetaFunc(callback, filterArguments, argumentTypes)
	return makeProxy({
		__call = function(_, ...)
			local arguments = table.pack(...)
			if filterArguments then
				for index, argument in arguments do
					local check = argumentTypes[index]
					if check and not check(argument) then
						return nil
					end
				end
			end
			return callback(...)
		end,
	})
end

local function runAPI(gAPIEnabled)
	table.clear(readOnlyWarnings)
	local player = {ClassName = "Player", UserId = 42, Name = "Fixture"}
	local allowedValue = {Value = "available"}
	local settings = {
		G_API = gAPIEnabled,
		G_Access = true,
		G_Access_Key = "fixture-key",
		G_Access_Perms = "Read",
		Allowed_API_Calls = {
			Variables = true,
			API_Specific = true,
		},
	}
	local calls, logs, loops = {}, {}, {}
	local admin = {
		CheckAdmin = function(target) calls.CheckAdmin = target; return true end,
		CheckBan = function(target) calls.CheckBan = target; return false end,
		IsMuted = function(target) calls.IsMuted = target; return false end,
		CheckDonor = function(target) calls.CheckDonor = target; return true end,
		GetLevel = function(target) calls.GetLevel = target; return 100 end,
	}
	local server = {Admin = admin, Variables = {Value = allowedValue.Value, Nested = {Value = "nested"}}}
	local serverCore = {DebugMode = false}
	local service = {
		MetaFunc = makeMetaFunc,
		NewProxy = makeProxy,
		ReadOnly = readOnly,
		StartLoop = function(...) table.insert(loops, {...}) end,
	}
	local logCategory = {}
	local logsService = {Script = logCategory}
	local addLog = function(category, data)
		table.insert(logs, {Category = category, Data = data})
	end
	local globalTable = {}
	local tableLibrary = table.clone(table)
	tableLibrary.isfrozen = function()
		return false
	end
	local apiEnvironment = setmetatable({
		_G = globalTable,
		Settings = settings,
		service = service,
		server = server,
		Core = serverCore,
		Admin = admin,
		Functions = {},
		Remote = {},
		t = typechecker,
		Logs = logsService,
		AddLog = addLog,
		StartLoop = service.StartLoop,
		env = {Routine = {}},
		table = tableLibrary,
	}, {__index = getfenv()})
	local factorySource = "return function(Settings, service, server, Core, Admin, Functions, Remote, t, Logs, AddLog, StartLoop, env, Vargs)\n"
		.. "return " .. implementation .. "\nend"
	local factory = luau.load(factorySource, {environment = apiEnvironment})()
	local startAPI = factory(
		settings, service, server, serverCore, admin, {}, {}, typechecker,
		logsService, addLog, service.StartLoop, apiEnvironment.env, {Server = server}
	)
	startAPI()
	return globalTable.Adonis, player, calls, settings, logs, loops, server
end

local api, player, calls, settings, logs, loops = runAPI(true)
assert(api.CheckAdmin(player) == true and calls.CheckAdmin == player, "CheckAdmin did not delegate to Admin.CheckAdmin")
assert(api.IsAdmin(player) == true and calls.CheckAdmin == player, "IsAdmin did not delegate to Admin.CheckAdmin")
assert(api.IsBanned(player) == false and calls.CheckBan == player, "IsBanned did not delegate to Admin.CheckBan")
assert(api.IsMuted(player) == false and calls.IsMuted == player, "IsMuted did not delegate to Admin.IsMuted")
assert(api.CheckDonor(player) == true and calls.CheckDonor == player, "CheckDonor did not delegate to Admin.CheckDonor")
assert(api.GetLevel(player) == 100 and calls.GetLevel == player, "GetLevel did not delegate to Admin.GetLevel")
assert(api.CheckAdmin({ClassName = "Folder"}) == nil, "CheckAdmin accepted a non-player argument")

local variables = api.Access("fixture-key", "Variables")
assert(variables.Value == "available", "Access did not expose an allowed variable")
assert(not pcall(function()
	variables.Value = "changed"
end) and variables.Value == "available", "Read-only Access allowed a top-level write")
local nested = variables.Nested
nested.Value = "changed"
assert(nested.Value == "nested" and #readOnlyWarnings > 0, "Nested read-only access did not block and report a write")
assert(not pcall(function()
	api.Access("wrong-key", "Variables")
end), "Access accepted an invalid key")
assert(settings.G_Access and #logs > 0 and #loops == 1, "API startup did not initialize its access checks")

local disabledAPI = runAPI(false)
assert(not pcall(function()
	return disabledAPI.CheckAdmin
end), "The public _G API remained available when disabled")
assert(disabledAPI.Scripts ~= nil, "The script API disappeared when the public _G API was disabled")

print("Admin _G API contracts passed")
