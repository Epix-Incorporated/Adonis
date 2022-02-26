client = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil
log = nil

--// Remote
return function()
	local _G, game, script, getfenv, setfenv, workspace,
		getmetatable, setmetatable, loadstring, coroutine,
		rawequal, typeof, print, math, warn, error,  pcall,
		xpcall, select, rawset, rawget, ipairs, pairs,
		next, Rect, Axes, os, time, Faces, unpack, string, Color3,
		newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
		NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
		NumberSequenceKeypoint, PhysicalProperties, Region3int16,
		Vector3int16, require, table, type, wait,
		Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay =
		_G, game, script, getfenv, setfenv, workspace,
		getmetatable, setmetatable, loadstring, coroutine,
		rawequal, typeof, print, math, warn, error,  pcall,
		xpcall, select, rawset, rawget, ipairs, pairs,
		next, Rect, Axes, os, time, Faces, unpack, string, Color3,
		newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
		NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
		NumberSequenceKeypoint, PhysicalProperties, Region3int16,
		Vector3int16, require, table, type, wait,
		Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay

	local script = script
	local service = service
	local client = client
	local Anti, Core, Functions, Process, Remote, UI, Variables
	local function Init()
		UI = client.UI;
		Anti = client.Anti;
		Core = client.Core;
		Variables = client.Variables
		Functions = client.Functions;
		Process = client.Process;
		Remote = client.Remote;

		Remote.Init = nil;
	end

	local function RunAfterLoaded()
		--// Report client finished loading
		log("~! Fire client loaded")
		client.Remote.Send("ClientLoaded")

		--// Ping loop
		log("~! Start ClientCheck loop");
		delay(5, function() service.StartLoop("ClientCheck", 30, Remote.CheckClient, true) end)

		--// Get settings
		log("Get settings");
		local settings = client.Remote.Get("Setting",{"G_API","Allowed_API_Calls","HelpButtonImage"})
		if settings then
			client.G_API = settings.G_API
			--client.G_Access = settings.G_Access
			--client.G_Access_Key = settings.G_Access_Key
			--client.G_Access_Perms = settings.G_Access_Perms
			client.Allowed_API_Calls = settings.Allowed_API_Calls
			client.HelpButtonImage = settings.HelpButtonImage
		else
			log("~! GET SETTINGS FAILED?")
			warn("FAILED TO GET SETTINGS FROM SERVER");
		end

		Remote.RunAfterLoaded = nil;
	end

	local function RunLast()
		--[[client = service.ReadOnly(client, {
				[client.Variables] = true;
				[client.Handlers] = true;
				G_API = true;
				G_Access = true;
				G_Access_Key = true;
				G_Access_Perms = true;
				Allowed_API_Calls = true;
				HelpButtonImage = true;
				Finish_Loading = true;
				RemoteEvent = true;
				ScriptCache = true;
				Returns = true;
				PendingReturns = true;
				EncodeCache = true;
				DecodeCache = true;
				Received = true;
				Sent = true;
				Service = true;
				Holder = true;
				GUIs = true;
				LastUpdate = true;
				RateLimits = true;

				Init = true;
				RunLast = true;
				RunAfterInit = true;
				RunAfterLoaded = true;
				RunAfterPlugins = true;
			}, true)--]]

			Remote.RunLast = nil;
	end

	getfenv().client = nil
	getfenv().service = nil
	getfenv().script = nil

	client.Remote = {
		Init = Init;
		RunLast = RunLast;
		RunAfterLoaded = RunAfterLoaded;
		Returns = {};
		PendingReturns = {};
		EncodeCache = {};
		DecodeCache = {};
		Received = 0;
		Sent = 0;

		CheckClient = function()
			if os.time() - Core.LastUpdate >= 10 then
				Remote.Send("ClientCheck", {
					Sent = Remote.Sent or 0;
					Received = Remote.Received;
				}, client.DepsName)
			end
		end;

		Returnables = {
			Test = function(args)
				return "HELLO FROM THE CLIENT SIDE :)! ", unpack(args)
			end;

			Ping = function(args)
				return Remote.Ping()
			end;

			ClientHooked = function(args)
				return Core.Special
			end;

			TaskManager = function(args)
				local action = args[1]
				if action == "GetTasks" then
					local tab = {}
					for i,v in next,service.GetTasks() do
						local new = {}
						new.Status = v.Status
						new.Name = v.Name
						new.Index = v.Index
						new.Created = v.Created
						new.CurrentTime = os.time()
						new.Function = tostring(v.Function)
						table.insert(tab,new)
					end
					return tab
				end
			end;

			LoadCode = function(args)
				local code = args[1]
				local func = Core.LoadCode(code, GetEnv())
				if func then
					return func()
				end
			end;

			Function = function(args)
				local func = client.Functions[args[1]]
				if func and type(func) == "function" then
					return func(unpack(args, 2))
				end
			end;

			Handler = function(args)
				local handler = client.Handlers[args[1]]
				if handler and type(handler) == "function" then
					return handler(unpack(args, 2))
				end
			end;

			UIKeepAlive = function(args)
				if Variables.UIKeepAlive then
					for ind,g in next,client.GUIs do
						if g.KeepAlive then
							if g.Class == "ScreenGui" or g.Class == "GuiMain" then
								g.Object.Parent = service.Player.PlayerGui
							elseif g.Class == "TextLabel" then
								g.Object.Parent = UI.GetHolder()
							end

							g.KeepAlive = false
						end
					end
				end

				return true;
			end;

			UI = function(args)
				local guiName = args[1]
				local themeData = args[2]
				local guiData = args[3]

				Variables.LastServerTheme = themeData or Variables.LastServerTheme;
				return UI.Make(guiName, guiData, themeData)
			end;

			InstanceList = function(args)
				local objects = service.GetAdonisObjects()
				local temp = {}
				for i,v in pairs(objects) do
					table.insert(temp, {
						Text = v:GetFullName();
						Desc = v.ClassName;
					})
				end
				return temp
			end;

			ClientLog = function(args)
				local temp={}
				local function toTab(str, desc, color)
					for i,v in next,service.ExtractLines(str) do
						table.insert(temp, {Text = v; Desc = desc..v; Color = color;})
					end
				end

				for i,v in next,service.LogService:GetLogHistory() do
					local mType = v.messageType
					toTab(v.message, (mType  == Enum.MessageType.MessageWarning and "Warning" or mType  == Enum.MessageType.MessageInfo and "Info" or mType  == Enum.MessageType.MessageError and "Error" or "Output").." - ", mType  == Enum.MessageType.MessageWarning and Color3.new(0.866667, 0.733333, 0.0509804) or mType  == Enum.MessageType.MessageInfo and Color3.new(0.054902, 0.305882, 1) or mType  == Enum.MessageType.MessageError and Color3.new(1, 0.196078, 0.054902))
				end

				return temp
			end;

			LocallyFormattedTime = function(args)
				if type(args[1]) == "table" then
					local results = {}
					for i, t in ipairs(args[1]) do
						results[i] = service.FormatTime(t, select(2, unpack(args)))
					end
					return results
				end
				return service.FormatTime(unpack(args))
			end;
		};

		UnEncrypted = {
			LightingChange = function(prop, val)
				print(prop, "TICKLE ME!?")
				Variables.LightingChanged = true
				service.Lighting[prop] = val
				Anti.LastChanges.Lighting = prop
				wait(.1)
				Variables.LightingChanged = false
				print("TICKLED :)",Variables.LightingChanged)
				if Anti.LastChanges.Lighting == prop then
					Anti.LastChanges.Lighting = nil
				end
			end
		};

		Commands = {
			GetReturn = function(args)
				print("THE SERVER IS ASKING US FOR A RETURN");
				local com = args[1]
				local key = args[2]
				local parms = {unpack(args, 3)}
				local retfunc = Remote.Returnables[com]
				local retable = (retfunc and {pcall(retfunc,parms)}) or {}
				if retable[1] ~= true then
					logError(retable[2])
					Remote.Send("GiveReturn", key, "__ADONIS_RETURN_ERROR", retable[2])
				else
					print("SENT RETURN");
					Remote.Send("GiveReturn", key, unpack(retable,2))
				end
			end;

			GiveReturn = function(args)
				print("SERVER GAVE US A RETURN")
				if Remote.PendingReturns[args[1]] then
					print("VALID PENDING RETURN")
					Remote.PendingReturns[args[1]] = nil
					service.Events[args[1]]:Fire(unpack(args, 2))
				end
			end;

			SessionData = function(args)
				local sessionKey = args[1];
				if sessionKey then
					service.Events.SessionData:Fire(sessionKey, table.unpack(args, 2))
				end
			end;

			SetVariables = function(args)
				local vars = args[1]
				for var, val in pairs(vars) do
					Variables[var] = val
				end
			end;

			Print = function(args)
				print(unpack(args))
			end;

			FireEvent = function(args)
				service.FireEvent(unpack(args))
			end;

			Test = function(args)
				print("OK WE GOT COMMUNICATION!  ORGL: "..tostring(args[1]))
			end;

			TestError = function(args)
				error("THIS IS A TEST ERROR")
			end;

			TestEvent = function(args)
				Remote.PlayerEvent(args[1],unpack(args,2))
			end;

			LoadCode = function(args)
				local code = args[1]
				local func = Core.LoadCode(code, GetEnv())
				if func then
					return func()
				end
			end;

			LaunchAnti = function(args)
				Anti.Launch(args[1],args[2])
			end;

			UI = function(args)
				local guiName = args[1]
				local themeData = args[2]
				local guiData = args[3]

				Variables.LastServerTheme = themeData or Variables.LastServerTheme;
				UI.Make(guiName,guiData,themeData)
			end;

			RemoveUI = function(args)
				UI.Remove(args[1],args[2])
			end;
				
			RefreshUI = function(args)
				local guiName = args[1]
				local ignore = args[2]
				
				UI.Remove(guiName,ignore)
				
				local themeData = args[3]
				local guiData = args[4]

				Variables.LastServerTheme = themeData or Variables.LastServerTheme;
				UI.Make(guiName,guiData,themeData)
			end;

			StartLoop = function(args)
				local name = args[1]
				local delay = args[2]
				local code = args[3]
				local func = Core.LoadCode(code, GetEnv())
				if name and delay and code and func then
					service.StartLoop(name,delay,func)
				end
			end;

			StopLoop = function(args)
				service.StopLoop(args[1])
			end;

			Function = function(args)
				local func = client.Functions[args[1]]
				if func and type(func) == "function" then
					Pcall(func,unpack(args,2))
				end
			end;

			Handler = function(args)
				local handler = client.Handlers[args[1]]
				if handler and type(handler) == "function" then
					Pcall(handler, unpack(args, 2))
				end
			end;
		};

		Fire = function(...)
			local limits = Process.RateLimits
			local limit = (limits and limits.Remote) or 0.01;
			local RemoteEvent = Core.RemoteEvent;
			local extra = {...};

			if RemoteEvent and RemoteEvent.Object then
				service.Queue("REMOTE_SEND", function()
					Remote.Sent = Remote.Sent+1;
					RemoteEvent.Object:FireServer({Mode = "Fire", Module = client.Module, Loader = client.Loader, Sent = Remote.Sent, Received = Remote.Received}, unpack(extra));
					wait(limit);
				end)
			end
		end;

		Send = function(com,...)
			Core.LastUpdate = os.time()
			Remote.Fire(Remote.Encrypt(com,Core.Key),...)
		end;

		GetFire = function(...)
			local RemoteEvent = Core.RemoteEvent;
			local limits = Process.RateLimits;
			local limit = (limits and limits.Remote) or 0.02;
			local extra = {...};
			local returns;

			if RemoteEvent and RemoteEvent.Function then
				local Yield = service.Yield();

				service.Queue("REMOTE_SEND", function()
					Remote.Sent = Remote.Sent+1;
					delay(0, function() -- Wait for return in new thread; We don't want to hold the entire fire queue up while waiting for one thing to return since we just want to limit fire speed;
						returns = {
							RemoteEvent.Function:InvokeServer({
								Mode = "Get",
								Module = client.Module,
								Loader = client.Loader,
								Sent = Remote.Sent,
								Received = Remote.Received
							}, unpack(extra))
						}

						Yield:Release(returns);
					end)

					wait(limit)
				end)

				if not returns then
					Yield:Wait();
				end

				Yield:Destroy();

				if returns then
					return unpack(returns)
				end
			end
		end;

		RawGet = function(...)
			local extra = {...};
			local RemoteEvent = Core.RemoteEvent;
			if RemoteEvent and RemoteEvent.Function then
				Remote.Sent = Remote.Sent+1;
				return RemoteEvent.Function:InvokeServer({Mode = "Get", Module = client.Module, Loader = client.Loader, Sent = Remote.Sent, Received = Remote.Received}, unpack(extra));
			end
		end;

		Get = function(com,...)
			Core.LastUpdate = os.time()
			local ret = Remote.GetFire(Remote.Encrypt(com,Core.Key),...)
			if type(ret) == "table" then
				return unpack(ret);
			else
				return ret;
			end
		end;

		OldGet = function(com,...)
			local returns
			local key = Functions:GetRandom()
			local waiter = service.New("BindableEvent");
			local event = service.Events[key]:Connect(function(...) print("WE ARE GETTING A RETURN!") returns = {...} waiter:Fire() wait() waiter:Fire() waiter:Destroy() end)

			Remote.PendingReturns[key] = true
			Remote.Send("GetReturn",com,key,...)
			print(string.format("GETTING RETURNS? %s", tostring(returns)))
			--returns = returns or {event:Wait()}
			waiter.Event:Wait();
			print(string.format("WE GOT IT! %s", tostring(returns)))

			event:Disconnect()

			if returns then
				if returns[1] == "__ADONIS_RETURN_ERROR" then
					error(returns[2])
				else
					return unpack(returns)
				end
			else
				return nil
			end
		end;

		Ping = function()
			local t = time()
			local ping = Remote.Get("Ping")
			if not ping then return false end
			local t2 = time()
			local mult = 10^3
			local ms = ((math.floor((t2-t)*mult+0.5)/mult)*1000)
			return ms
		end;

		PlayerEvent = function(event,...)
			Remote.Send("PlayerEvent",event,...)
		end;

		Encrypt = function(str, key, cache)
			cache = cache or Remote.EncodeCache or {}

			if not key or not str then
				return str
			elseif cache[key] and cache[key][str] then
				return cache[key][str]
			else
				local byte = string.byte
				local sub = string.sub
				local char = string.char

				local keyCache = cache[key] or {}				
				local endStr = {}

				for i = 1, #str do
					local keyPos = (i % #key) + 1
					endStr[i] = char(((byte(sub(str, i, i)) + byte(sub(key, keyPos, keyPos)))%126) + 1)
				end

				endStr = table.concat(endStr)
				cache[key] = keyCache
				keyCache[str] = endStr
				return endStr
			end
		end;

		Decrypt = function(str, key, cache)
			cache = cache or Remote.DecodeCache or {}

			if not key or not str then
				return str
			elseif cache[key] and cache[key][str] then
				return cache[key][str]
			else
				local keyCache = cache[key] or {}
				local byte = string.byte
				local sub = string.sub
				local char = string.char
				local endStr = {}

				for i = 1, #str do
					local keyPos = (i % #key)+1
					endStr[i] = char(((byte(sub(str, i, i)) - byte(sub(key, keyPos, keyPos)))%126) - 1)
				end

				endStr = table.concat(endStr)
				cache[key] = keyCache
				keyCache[str] = endStr
				return endStr
			end
		end;
	}
end
