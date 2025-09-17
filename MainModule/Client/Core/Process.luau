client = nil
service = nil
Pcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil
log = nil

--// Processing
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

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
	local service = Vargs.Service
	local client = Vargs.Client
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
		Process.RunLast = nil;
	end

	local function RunAfterLoaded(data)
		--// Events
		--service.NetworkClient.ChildRemoved:Connect(function() wait(30) client.Anti.Detected("crash", "Network client disconnected") end)
		--service.NetworkClient.ChildAdded:Connect(function() client.Anti.Detected("crash", "Network client reconnected?") end)
		service.TextChatService.SendingMessage:Connect(service.EventTask("Event: ProcessChat", Process.Chat))
		service.Player.CharacterRemoving:Connect(service.EventTask("Event: CharacterRemoving", Process.CharacterRemoving))
		service.Player.CharacterAdded:Connect(service.Threads.NewEventTask("Event: CharacterAdded", Process.CharacterAdded))
		service.LogService.MessageOut:Connect(Process.LogService) --service.Threads.NewEventTask("EVENT:MessageOut",client.Process.LogService,60))
		service.ScriptContext.Error:Connect(Process.ErrorMessage) --service.Threads.NewEventTask("EVENT:ErrorMessage",client.Process.ErrorMessage,60))

		--// Get RateLimits
		Process.RateLimits = Remote.Get("RateLimits") or Process.RateLimits;

		--// Hide TextChatComands
		task.defer(function()
			if Remote.Get("Variable", "ChatCreateRobloxCommands") then
				Process.HandleTextChatCommands()
			end
		end)

		Process.RunAfterLoaded = nil;
	end

	getfenv().client = nil
	getfenv().service = nil
	getfenv().script = nil

	client.Process = {
		Init = Init;
		RunLast = RunLast;
		RunAfterLoaded = RunAfterLoaded;
		TextChatCommands = {};
		RateLimits = { --// Defaults; Will be updated with server data at client run
			Remote = 0.02;
			Command = 0.1;
			Chat = 0.1;
			RateLog = 10;
		};

		Remote = function(data, com, ...)
			local args = table.pack(...)
			Remote.Received += 1
			if type(com) == "string" then
				if com == `{client.DepsName}GIVE_KEY` then
					if not Core.Key then
						log("~! Set remote key")
						Core.Key = args[1]

						log("~! Call Finish_Loading()")
						client.Finish_Loading()
					end
				elseif Core.Key then
					local comString = Remote.NewDecrypt(com,Core.Key)
					local command = (data.Mode == "Get" and Remote.Returnables[comString]) or Remote.Commands[comString]
					if command then
						local rets = table.pack(service.TrackTask(`Remote: {comString}`, command, false, args))
						if not rets[1] then
							logError(rets[2])
						else
							return table.pack(table.unpack(rets, 2))
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
			if Message and Message ~= "nil" and Message ~= "" and (string.find(Message,":: Adonis ::") or string.find(Message,script.Name) or Script == script) then
				logError(`{Message} - {Trace}`)
			end
		end;

		Chat = function(msg)
			--service.FireEvent("Chat",msg)
			if not service.Player or service.Player.Parent ~= service.Players then
				Remote.Fire("ProcessChat",msg)
			end
		end;

		CharacterAdded = function(...)
			service.Events.CharacterAdded:Fire(...)

			task.wait()
			UI.GetHolder()
		end;

		CharacterRemoving = function()
			if Variables.UIKeepAlive then
				for ind,g in client.GUIs do
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
				service.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
			end

			if Variables.PlayerListEnabled then
				service.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
			end

			local textbox = service.UserInputService:GetFocusedTextBox()
			if textbox and service.CheckProperty(textbox, "ReleaseFocus") then
				textbox:ReleaseFocus()
			end

			service.Events.CharacterRemoving:Fire()
		end;

		HandleTextChatCommands = function()
			local data = Remote.Get("PlayerData")
			local adminLevel, isDonor = data.AdminLevel, data.isDonor

			if service.TextChatService and service.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
				local function onCommandAdded(command)
					if not command:IsA("TextChatCommand") then
						return
					elseif string.sub(command.Name, 1, 7) ~= "Adonis_" then
						return
					elseif not Process.TextChatCommands[command.Name] then
						Process.TextChatCommands[command.Name] = command
					elseif Process.TextChatCommands[command.Name] ~= command then
						Process.TextChatCommands[command.Name]:Destroy()
						Process.TextChatCommands[command.Name] = command
					end

					local commandLevel = command:GetAttribute("AdminLevel")

					if type(commandLevel) == "number" and commandLevel > adminLevel or commandLevel == "Donors" and not isDonor then
						command.Parent = nil
					end
				end

				for _, v in service.TextChatService:GetDescendants() do
					onCommandAdded(v)
				end

				service.TextChatService.DescendantAdded:Connect(onCommandAdded)
			end
		end;
	}
end
