client = nil
service = nil
cPcall = nil
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

	local script, getfenv, pcall, unpack, string, tostring,
		type, Enum =
		script, getfenv, pcall, unpack, string, tostring,
		type, Enum

	local service = Vargs.Service
	local client = Vargs.Client
	local Core, Process, Remote, UI, Variables
	local function Init()
		UI = client.UI;
		Core = client.Core;
		Variables = client.Variables
		Process = client.Process;
		Remote = client.Remote;

		Process.Init = nil;
	end

	local function RunLast()
			Process.RunLast = nil;
	end

	local function RunAfterLoaded()
		--// Events
		service.Player.Chatted:Connect(service.EventTask("Event: ProcessChat", Process.Chat))
		service.Player.CharacterRemoving:Connect(service.EventTask("Event: CharacterRemoving", Process.CharacterRemoving))
		service.Player.CharacterAdded:Connect(service.Threads.NewEventTask("Event: CharacterAdded", Process.CharacterAdded))
		service.LogService.MessageOut:Connect(Process.LogService)
		service.ScriptContext.Error:Connect(Process.ErrorMessage)

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

		Remote = function(data, com, ...)
			local args = {...}
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
					local comString = Remote.Decrypt(com,Core.Key)
					local command = (data.Mode == "Get" and Remote.Returnables[comString]) or Remote.Commands[comString]
					if command then
						local rets = {service.TrackTask(`Remote: {comString}`, command, args)}
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
		end;

		ErrorMessage = function(Message, Trace, Script)
			if Message and Message ~= "nil" and Message ~= "" and (string.find(Message,":: Adonis ::") or string.find(Message,script.Name) or Script == script) then
				logError(`{tostring(Message)} - {tostring(Trace)}`)
			end
		end;

		Chat = function(msg)
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
				for _,g in client.GUIs do
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
			if textbox then
				textbox:ReleaseFocus()
			end

			service.Events.CharacterRemoving:Fire()
		end
	}
end
