client = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Processing
return function()
	local _G, game, script, getfenv, setfenv, workspace,
		getmetatable, setmetatable, loadstring, coroutine,
		rawequal, typeof, print, math, warn, error,  pcall,
		xpcall, select, rawset, rawget, ipairs, pairs,
		next, Rect, Axes, os, tick, Faces, unpack, string, Color3,
		newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
		NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
		NumberSequenceKeypoint, PhysicalProperties, Region3int16,
		Vector3int16, elapsedTime, require, table, type, wait,
		Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay =
		_G, game, script, getfenv, setfenv, workspace,
		getmetatable, setmetatable, loadstring, coroutine,
		rawequal, typeof, print, math, warn, error,  pcall,
		xpcall, select, rawset, rawget, ipairs, pairs,
		next, Rect, Axes, os, tick, Faces, unpack, string, Color3,
		newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
		NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
		NumberSequenceKeypoint, PhysicalProperties, Region3int16,
		Vector3int16, elapsedTime, require, table, type, wait,
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

		Process.Init = nil;
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

			Process.RunLast = nil;
	end

	local function RunAfterLoaded(data)
		--// Events
		--service.NetworkClient.ChildRemoved:Connect(function() wait(30) client.Anti.Detected("crash", "Network client disconnected") end)
		--service.NetworkClient.ChildAdded:Connect(function() client.Anti.Detected("crash", "Network client reconnected?") end)
		service.Player.Chatted:Connect(service.EventTask("Event: ProcessChat", Process.Chat))
		service.Player.CharacterRemoving:Connect(service.EventTask("Event: CharacterRemoving", Process.CharacterRemoving))
		service.Player.CharacterAdded:Connect(service.Threads.NewEventTask("Event: CharacterAdded", Process.CharacterAdded))
		service.LogService.MessageOut:Connect(Process.LogService) --service.Threads.NewEventTask("EVENT:MessageOut",client.Process.LogService,60))
		service.ScriptContext.Error:Connect(Process.ErrorMessage) --service.Threads.NewEventTask("EVENT:ErrorMessage",client.Process.ErrorMessage,60))

		--// Get RateLimits
		Process.RateLimits = Remote.Get("RateLimits") or Process.RateLimits;

		Process.RunAfterLoaded = nil;
	end

	getfenv().client = nil
	getfenv().service = nil
	getfenv().script = nil

	client.Process = {
		Init = Init;
		RunLast = RunLast;
		RunAfterLoaded = RunAfterLoaded;
		RateLimits = { --// Defaults; Will be updated with server data at client run
			Remote = 0.02;
			Command = 0.1;
			Chat = 0.1;
			RateLog = 10;
		};

		Remote = function(data,com,...)
			local args = {...}
			Remote.Received = Remote.Received+1
			if type(com) == "string" then
				if com == client.DepsName.."GIVE_KEY" then
					if not Core.Key then
						log("~! Set remote key")
						Core.Key = args[1]

						log("~! Call Finish_Loading()")
						client.Finish_Loading()
					end
				elseif Remote.UnEncrypted[com] then
					return {Remote.UnEncrypted[com](...)}
				elseif Core.Key then
					local comString = Remote.Decrypt(com,Core.Key)
					local command = (data.Mode == "Get" and Remote.Returnables[comString]) or Remote.Commands[comString]
					if command then
						--local ran,err = pcall(command, args) --task service.Threads.RunTask("REMOTE:"..comString,command,args)
						local rets = {service.TrackTask("Remote: ".. comString, command, args)}
						if not rets[1] then
							logError(rets[2])
						else
							return {unpack(rets, 2)};
						end
					end
				end
			end
		end;

		LogService = function(Message, Type)
			--service.FireEvent("Output", Message, Type)
		end;

		ErrorMessage = function(Message, Trace, Script)
			--service.FireEvent("ErrorMessage", Message, Trace, Script)
			if Message and Message ~= "nil" and Message ~= "" and (string.find(Message,"::Adonis::") or string.find(Message,script.Name) or Script == script) then
				logError(tostring(Message).." - "..tostring(Trace))
			end

			if (Script == nil or (not Trace or Trace == "")) and not (Trace and string.find(Trace,"CoreGui.RobloxGui")) then
				--Anti.Detected("log","Scriptless/Traceless error found. Script: "..tostring(Script).." - Trace: "..tostring(Trace))
			end
		end;

		Chat = function(msg)
			--service.FireEvent("Chat",msg)
			if not service.Player or service.Player.Parent ~= service.Players then
				Remote.Fire("ProcessChat",msg)
			end
		end;

		CharacterAdded = function()
			UI.GetHolder()
			service.Events.CharacterAdded:fire()
		end;

		CharacterRemoving = function()
			if Variables.UIKeepAlive then
				for ind,g in next,client.GUIs do
					if g.Class == "ScreenGui" or g.Class == "GuiMain" or g.Class == "TextLabel" then
						if not (g.Object:IsA("ScreenGui") and not g.Object.ResetOnSpawn) and g.CanKeepAlive then
							g.KeepAlive = true
							g.KeepParent = g.Object.Parent
							g.Object.Parent = nil
						elseif not g.CanKeepAlive then
							pcall(g.Destroy, g)
						end
					end
				end
			end

			if Variables.GuiViewFolder then
				Variables.GuiViewFolder:Destroy()
				Variables.GuiViewFolder = nil
			end

			if Variables.ChatEnabled then
				service.StarterGui:SetCoreGuiEnabled("Chat",true)
			end

			if Variables.PlayerListEnabled then
				service.StarterGui:SetCoreGuiEnabled('PlayerList',true)
			end

			local textbox = service.UserInputService:GetFocusedTextBox()
			if textbox then
				textbox:ReleaseFocus()
			end

			service.Events.CharacterRemoving:fire()
		end
	}
end
