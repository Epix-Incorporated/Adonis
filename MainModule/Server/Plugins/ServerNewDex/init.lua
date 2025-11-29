return function(Vargs)
	local Server = Vargs.Server
	local Service = Vargs.Service

	local Variables = Server.Variables
	local Commands = Server.Commands

	local Settings = Server.Settings
	local Anti = Server.Anti
	local Functions = Server.Functions
	local Logs = Server.Logs
	local Remote = Server.Remote
	local Admin = Server.Admin
	local Core = Server.Core

	local HttpService = Service.HttpService
	local Success, APIDump, Reflection = nil
	local ServerNewDex = {}

	local newDex_main = script:WaitForChild("Dex_Client", 120)
	local Event = ServerNewDex.Event

	if not newDex_main then
		warn("New Dex unable to be located?")
	else
		newDex_main = newDex_main:Clone()
		for _, BaseScript in ipairs(newDex_main:GetDescendants()) do
			if BaseScript.ClassName == "LocalScript" then
				BaseScript.Disabled = false
			end
		end
	end

	task.delay(0.25, function() -- Load Dex instance data asynchronously
		if Server.HTTP.HttpEnabled then
			while true do
				Success, APIDump = pcall(function()
					return HttpService:GetAsync(
						"https://github.com/MaximumADHD/Roblox-Client-Tracker/raw/roblox/API-Dump.json"
					)
				end)
				if Success and APIDump then
					break
				end
				task.wait(1)
			end
			Logs:AddLog("Script", "Successfully loaded instance API dump to Dex")
			while true do
				Success, Reflection = pcall(function()
					return HttpService:GetAsync(
						"https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/ReflectionMetadata.xml"
					)
				end)
				if Success and Reflection then
					break
				end
				task.wait(1)
			end
			Logs:AddLog("Script", "Successfully loaded reflection metadata to Dex")
		else
			Logs:AddLog("Script", "Access to HttpService is not enabled! Dex API dump could not be fetched!")
			Logs:AddLog("Errors", "Access to HttpService is not enabled! Dex API dump could not be fetched!")
			--logError("Access to HttpService is not enabled! Dex api dump could not be fetched!")
		end
	end)

	ServerNewDex.newDex_main = newDex_main
	ServerNewDex.Event = nil
	ServerNewDex.Authorized = {} --// Users who have been given Dex and are authorized to use the remote event
	ServerNewDex.ServerLogs = {} --// Store server logs for each player

	-- Server-side log capturing
	local LogService = Service.LogService
	local ServerLogHistory = {} -- Shared log history
	local MAX_LOG_HISTORY = 500

	-- Capture server logs
	LogService.MessageOut:Connect(function(message, messageType)
		local logEntry = {
			message = message,
			messageType = messageType,
			timestamp = os.time()
		}
		table.insert(ServerLogHistory, logEntry)

		-- Keep log history under limit
		if #ServerLogHistory > MAX_LOG_HISTORY then
			table.remove(ServerLogHistory, 1)
		end
	end)

	local Actions = {
		destroy = function(p: Player, args, realPlr: Player)
			if args[1]:IsA("Player") then
				if Admin.GetLevel(args[1]) < Admin.GetLevel(realPlr) then
					args[1]:Destroy()
				else
					Remote.MakeGui(realPlr, "Output", {
						Title = "Missing Permissions",
						Message = `You do not have the permission to delete player {args[1].DisplayName} (@{args[1].Name})`,
					})
				end
			else
				args[1]:Destroy()
			end
			return true
		end,
		clearclipboard = function(Player: Player, args)
			Player.Clipboard = {}
			return true
		end,
		duplicate = function(Player: Player, args)
			local obj = args[1]
			local par = args[2]

			local new = obj:Clone()
			new.Parent = par

			return new
		end,
		copy = function(Player: Player, args)
			local obj = args[1]
			local new = obj:Clone()
			table.insert(Player.Clipboard, new)

			return new -- It seems like this returns nil to the client, if the parent is nil.
		end,
		paste = function(Player: Player, args)
			local parent = args[1]
			local pastedObjects = {}

			for _, v in pairs(Player.Clipboard) do
				local cloned = v:Clone()
				cloned.Parent = parent
				table.insert(pastedObjects, cloned)
			end

			return pastedObjects
		end,
		setproperty = function(Player: Player, args)
			local obj = args[1]
			local prop = args[2]
			local value = args[3]

			if value ~= nil then
				-- Auto-add rbxassetid:// prefix for asset ID properties if user just entered a number
				if type(value) == "string" then
					local propLower = prop:lower()
					-- Check if this is an asset ID property
					local isAssetIdProp = propLower:match("id$")
						or propLower:match("texture")
						or propLower:match("image")
						or propLower:match("sound")
						or propLower:match("mesh")
						or propLower:match("skybox")
						or propLower:match("decal")

					-- If it's an asset property and the value is just digits, add the prefix
					if isAssetIdProp and value:match("^%d+$") then
						value = "rbxassetid://" .. value
					end
				end

				obj[prop] = value
				return true
			end
		end,
		setpropertyattribute = function(Player: Player, args)
			local obj = args[1]
			local attributeName = args[2]
			local value = args[3]

			if value ~= nil then
				obj:SetAttribute(attributeName, value)
				return true
			end
		end,
		instancenew = function(Player: Player, args)
			return Service.New(args[1], args[2])
		end,
		callfunction = function(Player: Player, args)
			local rets = { pcall(function()
				return (args[1][args[2]](args[1]))
			end) }
			table.remove(rets, 1)
			return rets
		end,
		callremote = function(Player: Player, args)
			if args[1]:IsA("RemoteFunction") then
				return args[1]:InvokeClient(table.unpack(args[2]))
			elseif args[1]:IsA("RemoteEvent") then
				args[1]:FireClient(table.unpack(args[2]))
			elseif args[1]:IsA("BindableFunction") then
				return args[1]:Invoke(table.unpack(args[2]))
			elseif args[1]:IsA("BindableEvent") then
				args[1]:Fire(table.unpack(args[2]))
			end
		end,
		fetchapi = function(Player: Player)
			return APIDump or false
		end,
		fetchrmd = function(Player: Player)
			return Reflection or false
		end,
		addtag = function(Player: Player, args)
			local obj = args[1]
			local tag = args[2]

			if typeof(obj) ~= "Instance" then
				return "Invalid target."
			end

			if type(tag) ~= "string" or tag == "" then
				return "Invalid tag."
			end

			local CollectionService = game:GetService("CollectionService")
			CollectionService:AddTag(obj, tag)

			return true
		end,

		removetag = function(Player: Player, args)
			local obj = args[1]
			local tag = args[2]

			if typeof(obj) ~= "Instance" then
				return "Invalid target."
			end

			local CollectionService = game:GetService("CollectionService")
			CollectionService:RemoveTag(obj, tag)

			return true
		end,

		loadstring = function(Player: Player, args)
			assert(Settings.CodeExecution, "CodeExecution must be enabled for this to work.")
			local func, err = Core.Loadstring(args[1])
			if func then
				local Succ, Err = pcall(function()
					func()
				end)
				if Succ then
					return true
				else
					return false, Err
				end
			else
				return false, err
			end
		end,

		loadstringclient = function(Player: Player, args, realPlr: Player)
			assert(Settings.CodeExecution, "CodeExecution must be enabled for this to work.")
			-- Use Adonis's Remote.LoadCode to execute on client
			-- This handles bytecode compilation and client execution automatically
			Remote.LoadCode(realPlr, args[1], false)
			return true
		end,

		getserverlogs = function(_Player: Player, _args, realPlr: Player)
			-- Initialize last index for this player if not exists
			if not ServerNewDex.ServerLogs[realPlr.UserId] then
				ServerNewDex.ServerLogs[realPlr.UserId] = 0
			end

			-- Return all current server logs
			return ServerLogHistory
		end,

		pollserverlogs = function(_Player: Player, _args, realPlr: Player)
			-- Initialize last index for this player if not exists
			if not ServerNewDex.ServerLogs[realPlr.UserId] then
				ServerNewDex.ServerLogs[realPlr.UserId] = 0
			end

			local lastIndex = ServerNewDex.ServerLogs[realPlr.UserId]
			local newLogs = {}

			-- Get logs since last poll
			for i = lastIndex + 1, #ServerLogHistory do
				table.insert(newLogs, ServerLogHistory[i])
			end

			-- Update last index
			ServerNewDex.ServerLogs[realPlr.UserId] = #ServerLogHistory

			return newLogs
		end,
	}

	function ServerNewDex.MakeEvent()
		if not Event then
			Event = Service.New("RemoteFunction", {
				Name = "NewDex_Event",
				Parent = game:GetService("ReplicatedStorage"),
			}, true, true)

			Event.OnServerInvoke = function(Plr: Player, Action, ...)
				local pData = ServerNewDex.Authorized[Plr]

				if not pData then
					return Anti.Detected(Plr, "kick", "Unauthorized to use the dex event")
				end

				local args = { ... }
				local Suppliments = args[1]

				local Action = string.lower(assert(Action, "Method argument missing!"))
				local MethodFunction =
					assert(Actions[Action], `{Plr.Name} attempted to use an action that wasn't defined: {Action}`)

				return MethodFunction(pData, args, Plr)
			end
		end
	end

	function ServerNewDex.MakeLocalDexForPlayer(ply, dexGui, destination)
		if ply then
			if dexGui and destination then
				dexGui.Parent = destination
			end
		end
	end

	-- Function used to give Dex to a player.
	function ServerNewDex.GiveDexToPlayer(ply)
		if ply then
			ServerNewDex.Authorized[ply] = {
				Clipboard = {},
			} --// double as per-player explorer-related data

			if not ServerNewDex.Event then
				ServerNewDex.MakeEvent()
			end
			ServerNewDex.MakeLocalDexForPlayer(ply, ServerNewDex.newDex_main:Clone(), ply:FindFirstChild("PlayerGui"))
		end
	end

	Commands.DexExplorerNew = {
		Prefix = Settings.Prefix,
		Commands = { "dexnew", "dexnewexplorer", "newdex", "dex", "dexexplorer" },
		Args = {}, --// kept for backwards compatibility
		Description = "Lets you explore the game using new Dex [Credits to LorekeeperZinnia]",
		AdminLevel = 300,
		Function = function(plr, args)
			ServerNewDex.Authorized[plr] = {
				Clipboard = {},
			} --// double as per-player explorer-related data

			if not ServerNewDex.Event then
				ServerNewDex.MakeEvent()
			end
			Remote.MakeLocal(plr, newDex_main:Clone(), "PlayerGui")
		end,
	}
	Logs:AddLog("Script", "NewDex Module Loaded")
end
