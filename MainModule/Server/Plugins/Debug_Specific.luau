--// This module is for stuff specific to debugging
--// Most of this only runs when DebugMode is enabled
--// NOTE: THIS IS NOT A *CONFIG/USER* PLUGIN! ANYTHING IN THE MAINMODULE PLUGIN FOLDERS IS ALREADY PART OF/LOADED BY THE SCRIPT! DO NOT ADD THEM TO YOUR CONFIG>PLUGINS FOLDER!

return function(Vargs, GetEnv)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if not Core.DebugMode then -- Nothing in this built-in plugin will be ran in normal environments, it's only ran if DebugMode is enabled.
		return
	end

	if server.Data and server.Data.NightlyMode then
		--// Unfortunately not viable
		--// TODO: Make this viable perhaps? If done so, expose as a :terminal command
		Commands.Reboot = {
			Prefix = Settings.Prefix;
			Commands = {"rebootadonis", "reloadadonis"};
			Args = {};
			Description = "Attempts to force Adonis to reload";
			AdminLevel = "Creators";
			Function = function(plr: Player, args: {string}, data: {any})
				local rebootHandler = server.Deps.RebootHandler:Clone();

				if server.Runner then
					rebootHandler.mParent.Value = service.UnWrap(server.ModelParent);
					rebootHandler.Runner.Value = service.UnWrap(server.Runner);
					rebootHandler.Model.Value = service.UnWrap(server.Model);
					rebootHandler.Mode.Value = "REBOOT";
					task.wait(0.03)
					rebootHandler.Parent = service.ServerScriptService;
					rebootHandler.Disabled = false;
					task.wait(0.03)
					server.CleanUp();
				else
					error("Unable to reload: Runner missing");
				end
			end;
		};
	end

	Commands.DebugUsage = {
		Prefix = Settings.PlayerPrefix;
		Commands = {"debugusage"};
		Args = {};
		Description = "Shows you how to use some syntax related things";
		Hidden = true;
		AdminLevel = "Players";
		Function = function(plr: Player, args: {string})
			local usage = {
				"This instance of Adonis is in DebugMode";
				"Meaning, you have access to various debug commands, as shown in the list below.";
				"You can also run scripts thru the env in the command or devconsole with :debugadonisenvscript";
				"or directly in game thru :debugloadstring"
			}
			Remote.MakeGui(plr, "List", {
				Title = "Usage";
				Tab = usage;
				Size = {300, 250};
				RichText = true;
				TitleButtons = {
					{
						Text = "?";
						OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.PlayerPrefix}usage')`)
					}
				};
			})
		end
	};

	Commands.ViewDebugCommands = {
		Prefix = Settings.Prefix;
		Commands = {"debugcmds", "debugcommands", "debugcmdlist"};
		Args = {};
		Description = "Lists all available debug commands regardless of hidden status";
		Hidden = true;
		AdminLevel = "Players";
		Function = function(plr: Player, args: {string})
			local tab = {}
			local cmdCount = 0

			for _, cmd in Admin.SearchCommands(plr, "all") do
				if not cmd.Debug then
					continue
				end

				local permissionDesc = Admin.FormatCommandAdminLevel(cmd)
				table.insert(tab, {
					Text = Admin.FormatCommand(cmd),
					Desc = string.format("[%s] %s", permissionDesc, cmd.Description or "(No description provided)"),
					Filter = permissionDesc
				})
				cmdCount += 1
			end

			table.sort(tab, function(a, b) return a.Text < b.Text end)

			Remote.MakeGui(plr, "List", {
				Title = `Debug Commands ({cmdCount})`;
				Table = tab;
				TitleButtons = {
					{
						Text = "?";
						OnClick = Core.Bytecode(`client.Remote.Send('ProcessCommand','{Settings.PlayerPrefix}debugusage')`)
					}
				};
			})
		end
	}

	Commands.TestFilter = {
		Prefix = Settings.Prefix;
		Commands = {"testfilter", "filtertest", "tfilter"};
		Args = {"player", "text"};
		NoFilter = true;
		Debug = true;
		Description = "Test out Roblox's text filtering on a player";
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string})
			assert(args[1], "Missing player name")
			assert(args[2], "Missing text to filter")
			local temp = {{Text=`Original: {args[2]}`, Desc = args[2]}}
			if service.RunService:IsStudio() then
				table.insert(temp, {Text="!! The string has not been filtered !!", Desc="Text filtering does not work in studio"})
			end
			for _, v in service.GetPlayers(plr, args[1]) do
				table.insert(temp, {Text = `-- {v.DisplayName} --`, Desc = `{v.UserId} ({v.Name})`})
				table.insert(temp, {Text = `ChatForUser: {service.TextService:FilterStringAsync(args[2], v.UserId):GetChatForUserAsync(v.UserId)}`})
				table.insert(temp, {Text = `NonChatForBroadcast: {service.TextService:FilterStringAsync(args[2], v.UserId):GetNonChatStringForBroadcastAsync()}`})
				table.insert(temp, {Text = `NonChatForUser: {service.TextService:FilterStringAsync(args[2], v.UserId):GetNonChatStringForUserAsync(v.UserId)}`})

			end
			Remote.MakeGui(plr, "List", {Title = "Filtering Results", Tab = temp})
		end
	};

	Commands.GetDebugAdonisEnvScript = {
		Prefix = Settings.Prefix;
		Commands = {"debugadonisenvscript"};
		Args = {};
		Description = "Provides a script in a notepad to you to copy and paste into the studio command bar or developer console to access the Adonis Env";
		Hidden = true;
		Debug = true;
		NoFilter = true;
		AdminLevel = "Creators";
		Function = function(plr: Player, args: {string})
			local ScriptSrcTxt = ""
			Remote.MakeGui(plr, "Notepad", {
				Text = [[-- Made by your friendly moo1210, to make debugging the adonis env not a pain. :)
local IS_RUNNING_IN_SAME_SCRIPT_IDENTITY = false -- If you're running as a normal user-space script (aka the script identity is 2 when you use printidentity), you may toggle this to true, to prevent needing to wrap instances. This may prevent any minor incompatiblies caused by the wrapping logic, if any. This will not work in the command bar, run script button, or plugins.

----
local DebugApiBindable = assert(IS_RUNNING_IN_SAME_SCRIPT_IDENTITY and nil or game:GetService("ReplicatedStorage"):WaitForChild("Adonis_Debug_API", 15), "Adonis Debug API not found within 15 seconds! Is DebugMode enabled?")
local DebugApi
if IS_RUNNING_IN_SAME_SCRIPT_IDENTITY then
	pcall(function()
	   DebugApi = _G.Adonis.Debug
	end)
	if not DebugApi then
		warn("The IS_RUNNING_IN_SAME_SCRIPT_IDENTITY option is enabled, however _G.Adonis.Debug was unable to be accessed. Is DebugMode and the _G API enabled? Falling back to BindableEvent")
		DebugApiBindable = assert(game:GetService("ReplicatedStorage"):WaitForChild("Adonis_Debug_API", 15), "Adonis Debug API not found within 15 seconds! Is DebugMode enabled?")
		DebugApi = DebugApiBindable:Invoke("GetApi")
	end
else
	DebugApi = DebugApiBindable:Invoke("GetApi") -- Calls the bindable and will wrap around a metatable to call it everytime you call a function outside this lua vm
end
-- We can't always directly call the API's functions in some places, namely different Lua VMs, such as the command bar. This allows the script run the functions.
function WrapAdonisEnv(toWrap, chain)
	if chain == nil then
		chain = ""
	end

	if type(toWrap) == "userdata" or type(toWrap) == "table" then
		local wrapped = newproxy(true)
		local wrappedMeta = getmetatable(wrapped)
		local existingMeta = DebugApiBindable:Invoke("GetEnvTableMeta", chain:sub(1, #chain - 3))
		local existingMetaClone
		if existingMeta == nil then
			existingMeta = {}
		elseif type(existingMeta) == "string" then
			error(`The metatable ${chain} is locked, it provided the following message :${existingMeta}`) -- If you hit this, some code in Adonis likely needs to be updated to not lock metatables when DebugMode is on.
		else
			existingMetaClone = table.clone(existingMeta)
		end
		wrappedMeta.__index = function(s, k)
			local curChain = tonumber(chain) and chain or chain .. k .. "/.\\"
			if k == "GetObject" then
				return toWrap
			elseif type(toWrap[k]) == "function" then
				return function(...)
					local args = table.pack(...)
					local unwrappedArgs = table.create(args.n)

					for i, arg in args do
						if (type(arg) == "table" or type(arg) == "userdata") and arg.GetObject then
							unwrappedArgs[i] = arg.GetObject
						else
							unwrappedArgs[i] = arg
						end
					end
					--print(unwrappedArgs)
					DebugApiBindable:Invoke("RunEnvFunc", tonumber(chain) and chain or curChain:sub(1, #curChain - 3), table.unpack(unwrappedArgs))
				end
			else
				if existingMeta.__index then
					local result, resultPointer = DebugApiBindable:Invoke("RunEnvTableMetaFunc", tonumber(chain) and chain or chain:sub(1, #chain - 3), "__index", k)
					if result then
						return WrapAdonisEnv(result, resultPointer)
					else
						return WrapAdonisEnv(toWrap[k], curChain)
					end
				else
					return WrapAdonisEnv(toWrap[k], curChain)
				end
			end
		end

		wrappedMeta.__newindex = function(s, k, v)
			toWrap[k] = v
		end

		return wrapped
	else
		return toWrap
	end
end
local wrappedEnv = DebugApiBindable == nil and DebugApi.Env or WrapAdonisEnv(DebugApi.Env)
local server = wrappedEnv.Server
local client = wrappedEnv.Client
local service = wrappedEnv.Service
---- Your code with access to the Adonis Env below! Both server/client supported depending on which type of script your running
]],
				ReadOnly = true,
				AutoSelectAll = true
			})
		end
	}

	Commands.TestError = {
		Prefix = Settings.Prefix;
		Commands = {"debugtesterror"};
		Args = {"optional type (error/assert)", "optional message"};
		Description = "Test Error";
		Hidden = true;
		Debug = true;
		NoFilter = true;
		AdminLevel = "Players";
		Function = function(plr: Player, args: {string})
			--assert(args[1] and args[2],"Argument missing or nil")
			Remote.Send(plr, "TestError")
			task.defer(function() plr.Bobobobobobobo.Hi = 1 end)
			if not args[1] then
				error("This is an intentional test error")
			elseif args[1]:lower() == "error" then
				error(args[2])
			elseif args[1]:lower() == "assert" then
				assert(false, args[2])
			end
		end;
	};

	Commands.TestBigList = {
		Prefix = Settings.Prefix;
		Commands = {"debugtestbiglist"};
		Args = {};
		Description = "Test Big List";
		Hidden = true;
		Debug = true;
		AdminLevel = "Admins";
		Function = function(plr: Player, args: {string})
			local list = {}

			for i = 1, 5000 do
				table.insert(list, {Text = i})
			end

			Remote.MakeGui(plr,"List",{
				Title = "DebugBigList_PageSize250",
				Table = list,
				Font = "Code",
				PageSize = 250;
				Size = {500, 400},
			})

			Remote.MakeGui(plr,"List",{
				Title = "DebugBigList_PageSize100",
				Table = list,
				Font = "Code",
				PageSize = 100;
				Size = {500, 400},
			})

			Remote.MakeGui(plr,"List",{
				Title = "DebugBigList_PageSize25",
				Table = list,
				Font = "Code",
				PageSize = 25;
				Size = {500, 400},
			})
		end;
	};

	Commands.TestGet = {
		Prefix = Settings.Prefix;
		Commands = {"debugtestget"};
		Args = {};
		Description = "Remote Test";
		Hidden = true;
		Debug = true;
		AdminLevel = "Creators";
		Function = function(plr: Player, args: {string})
			print(Remote.Get(plr,"Test"))

			local tab = {
				{
					Children = {
						{
							Class = "sdfhasdfjkasjdf"
						}
					}
				},
				{Something = "hi"}
			}

			local FuncTime = os.clock();

			local _, ret = Remote.Get(plr, "Test", tab)

			print(`Remote.Get RETURN:`, ret)

			warn(`Remote.Get TOOK: {os.clock() - FuncTime}`)

			print("TESTING UI EVENTS..")

			Remote.MakeGui(plr, "Settings", {
				IsOwner = true
			})

			local RemoteTime;

			local testColor = Remote.GetGui(plr, "ColorPicker", {Color = Color3.new(1, 1, 1)})
			print(testColor)

			local ans,event = Remote.GetGui(plr, "YesNoPrompt", {
				Icon = server.MatIcons["Bug report"];
				Question = "Is this a test question?";
			}), Remote.NewPlayerEvent(plr, "TestEvent", function(...)
				print("RemoteEvent Return:", ...)
				warn(`Remote.Send TOOK: {os.clock() - RemoteTime}`)
				print("THAT'D BE ALL")
			end)
			print(`PLAYER ANSWER: {ans}`)

			task.wait(0.5)

			print("RemoteEvent Sending..")

			RemoteTime = os.clock();

			Remote.Send(plr, "TestEvent", "TestEvent", "hi mom I went thru the interwebs")

			print("RemoteEvent Fired successfully")
		end;
	};

	Commands.DebugLoadstring = {
		Prefix = Settings.Prefix;
		Commands = {"debugloadstring"};
		Args = {"code";};
		Description = "DEBUG LOADSTRING";
		Hidden = true;
		Debug = true;
		NoFilter = true;
		AdminLevel = "Creators";
		Function = function(plr: Player, args: {string})
			--[[local ans = Remote.GetGui(plr, "YesNoPrompt", {
				Icon = server.MatIcons.Warning;
				Question = "Are you sure you want to load this script into the server env?";
				Title = "Adonis DebugLoadstring";
				Delay = 5;
			}) As this is only available within DebugMode now, this has no real usecase. ]]
			--if ans == "Yes" then
			local func,err = Core.Loadstring(args[1],GetEnv())
			if func then
				func()
				Functions.Hint("Ran script", {plr}, 3)
			else
				server.LogError("DEBUG",err)
				Functions.Hint(err,{plr}, 6)
			end
			--end
		end
	};

	Commands.DebugAnti = {
		Prefix = Settings.Prefix;
		Commands = {"debuganti", "debuganticheat", "debugcheat", "debugantiexploit", "debugexploit", "debugantihack", "debughack"};
		Args = {"player", "action", "info"};
		Description = "Allows you to make a mock anti cheat detection";
		Hidden = true;
		Debug = true;
		NoFilter = true;
		AdminLevel = "HeadAdmins";
		Function = function(plr: Player, args: {string})
			for _, v in service.GetPlayers(plr, args[1], {UseFakePlayer = true}) do
				Anti.Detected(v, table.unpack(args, 2))
			end
		end
	};

	Commands.DebugDonor = {
		Prefix = Settings.Prefix;
		Commands = {"debugdonor", "debugadddonor", "debugsetdonor", "debuggetdoor"};
		Args = {"player", "useids"};
		Description = "Allows you to temporarily add donors";
		Hidden = true;
		Debug = true;
		NoFilter = true;
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string})
			local useIds = args[2] and string.lower(args[2]) == "true"

			for _, v in useIds and string.split(args[1], ",") or service.GetPlayers(plr, args[1]) do
				Variables.CachedDonors[tostring(not useIds and v.UserId or tonumber(v))] = os.time()
			end
		end
	};

	Commands.DebugRemoveDonor = {
		Prefix = Settings.Prefix;
		Commands = {"debugremovedonor", "debugdeletedonor", "debugunsetdonor", "debugantidonor"};
		Args = {"player", "useids"};
		Description = "Allows you to temporarily remove donors";
		Hidden = true;
		Debug = true;
		NoFilter = true;
		AdminLevel = "Moderators";
		Function = function(plr: Player, args: {string})
			local useIds = args[2] and string.lower(args[2]) == "true"

			for _, v in useIds and string.split(args[1], ",") or service.GetPlayers(plr, args[1]) do
				Variables.CachedDonors[tostring(not useIds and v.UserId or tonumber(v))] = nil
			end
		end
	};

	Logs:AddLog("Script", "Debug Built-in Plugin Module Loaded as DebugMode was on");
end;
