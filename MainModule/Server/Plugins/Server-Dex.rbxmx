return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	local dexGui = script:WaitForChild("Dex_Explorer", 120)
	if not dexGui then
		Logs:AddLog("Script", "DexGui unable to be located?")
	else
		dexGui = dexGui:Clone()
		for _, BaseScript in ipairs(dexGui:GetDescendants()) do
			if BaseScript.ClassName == "LocalScript" then
				BaseScript.Disabled = false
			end
		end
	end

	local Event = nil;

	local Authorized = {}; --// Users who have been given Dex and are authorized to use the remote event

	local function MakeEvent()
		if not Event then
			Event =  service.New("RemoteFunction", {
				Name = "DexEvent";
				Parent = service.ReplicatedStorage;
			}, true, true)

			Event.OnServerInvoke = (function(Plr, Action, ...)
				local pData = Authorized[Plr];
				if not pData then
					Anti.Detected(Plr, "kick", "Unauthorized Dex Event");
				else
					local args = {...};
					local Suppliments = args[1];

					if (Action == "Destroy" or Action == "Delete") and args[1] then
						args[1]:Destroy();
						return true;
					elseif Action == "ClearClipboard" then
						pData.Clipboard = {};
						return true;
					elseif Action == "Duplicate" and args[1] and args[2] then
						local obj = args[1];
						local par = args[2];

						local new = obj:Clone()
						new.Parent = par;

						return new;
					elseif Action == "Copy" and args[1] then
						local obj = args[1];
						local new = obj:Clone();
						table.insert(pData.Clipboard, new)

						return new;
					elseif Action == "Paste" and args[1] then
						local parent = args[1];

						for i,v in pairs(pData.Clipboard) do
							v:Clone().Parent = parent;
						end

						return true;
					elseif Action == "SetProperty" and args[1] and args[2] then
						local obj = args[1];
						local prop = args[2];
						local value = args[3];

						if value ~= nil then
							obj[prop] = value;
							return true;
						end
					elseif Action == "InstanceNew" then
						return service.New(args[1], args[2]);
					elseif Action == "CallFunction" then
						local rets = {pcall(function() return (args[1][args[2]](args[1])) end)}
						table.remove(rets,1)
						return rets
					elseif Action == "CallRemote" then
						if args[1]:IsA("RemoteFunction") then
							return args[1]:InvokeClient(table.unpack(args[2]))
						elseif args[1]:IsA("RemoteEvent") then
							args[1]:FireClient(table.unpack(args[2]))
						elseif args[1]:IsA("BindableFunction") then
							return args[1]:Invoke(table.unpack(args[2]))
						elseif args[1]:IsA("BindableEvent") then
							args[1]:Fire(table.unpack(args[2]))
						end
					end
				end
			end)
		end
	end

	Commands.DexExplore = {
		Prefix = Settings.Prefix;
		Commands = {"dex";"dexexplorer";"dexexplorer"};
		Args = {};
		Description = "Lets you explore the game using Dex [Credit to Raspberry Pi/Raspy_Pi/raspymgx/OpenOffset(?)]";
		AdminLevel = 300;
		Function = function(plr,args)
			Authorized[plr] = {
				Clipboard = {};
			}; --// double as per-player explorer-related data

			if not Event then  MakeEvent(); end
			Remote.MakeLocal(plr, dexGui:Clone(), "PlayerGui")
		end
	};

	Logs.AddLog("Script", "Dex Plugin Loaded");
end