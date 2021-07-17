server = nil
service = nil
cPcall = nil
Pcall = nil
Routine = nil
GetEnv = nil
logError = nil
sortedPairs = nil

--// This module is for stuff specific to cross server communication
--// NOTE: THIS IS NOT A *CONFIG/USER* PLUGIN! ANYTHING IN THE MAINMODULE PLUGIN FOLDERS IS ALREADY PART OF/LOADED BY THE SCRIPT! DO NOT ADD THEM TO YOUR CONFIG>PLUGINS FOLDER!
return function(Vargs)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Core = server.Core;
	local Admin = server.Admin;
	local Process = server.Process;
	local Settings = server.Settings;
	local Functions = server.Functions;
	local Commands = server.Commands;
	local Remote = server.Remote;
	local Logs = server.Logs;

	local ServerId = game.JobId;
	local MsgService = service.MessagingService;
	local subKey = Core.DataStoreEncode("AdonisCrossServerMessaging");
	local counter = 0;
	local lastTick;

	local oldCommands = Core.CrossServerCommands;

	--// Cross Server Commands
	Core.CrossServerCommands = {
		ServerChat = function(jobId, data)
			if data then
				for i,v in next,service.GetPlayers() do
					if Admin.GetLevel(v) > 0 then
						Remote.Send(v,"handler", "ChatHandler", data.Player, data.Message, "Cross")
					end
				end
			end
		end;

		Ping = function(jobId, data)
			Core.CrossServer("Pong", {
				JobId = game.JobId;
				NumPlayers = #service.Players:GetChildren();
			})
		end;

		Pong = function(jobId, data)
			service.Events.ServerPingReplyReceived:Fire(jobId, data);
		end;

		NewRunCommand = function(jobId, plrData, comString)
			local fakePlayer = service.Wrap(service.New("Folder"))
			local data = {
				Name = plrData.Name;
				ToString = plrData.Name;
				ClassName = "Player";
				AccountAge = 0;
				CharacterAppearanceId = plrData.UserId or -1;
				UserId = plrData.UserId or -1;
				userId = plrData.UserId or -1;
				Parent = service.Players;
				Character = Instance.new("Model");
				Backpack = Instance.new("Folder");
				PlayerGui = Instance.new("Folder");
				PlayerScripts = Instance.new("Folder");
				Kick = function() fakePlayer:Destroy() fakePlayer:SetSpecial("Parent", nil) end;
				IsA = function(ignore, arg) if arg == "Player" then return true end end;
			}

			for i,v in next,data do fakePlayer:SetSpecial(i, v) end

			Process.Command(fakePlayer, comString, {AdminLevel = plrData.AdminLevel, CrossServer = true})
		end;

		Loadstring = function(jobId, source)
			server.Core.Loadstring(source, GetEnv{})()
		end;

		DataStoreUpdate = function(jobId, type, data)
			server.Process.DataStoreUpdated(type, data)
		end;

		UpdateSetting = function(jobId, setting, newValue)
			Settings[setting] = newValue;
		end;

		LoadData = function(jobId, key, dat)
			Core.LoadData(key, dat, jobId);
		end;

		Event = function(jobId, eventId, ...)
			service.Events["CRSSRV:".. eventId]:Fire(...)
		end;

		CrossServerVote = function(jobId, data)
			local question = data.Question;
			local answers = data.Answers;
			local voteKey = data.VoteKey;

			local start = os.time()
			local players = service.GetPlayers()

			for i,v in pairs(players) do
				Routine(function()
					local response = Remote.GetGui(v, "Vote", {Question = question,Answers = answers})
					if response and os.time() - start <= 120 then
						MsgService:PublishAsync(voteKey, {PlrInfo = {Name = v.Name, UserId = v.UserId}, Response = response})
					end
				end)
			end
		end;
	}

	local function CrossEvent(eventId)
		return service.Events["CRSSRV".. eventId]
	end

	--// User Commands
	Commands.CrossServer = {
		Prefix = Settings.Prefix;
		Commands = {"crossserver","cross","allservers"};
		Args = {"command"};
		Description = "Runs the specified command string on all servers";
		AdminLevel = "HeadAdmins";
		CrossServerDenied = true; --// Makes it so this command cannot be ran via itself causing an infinite spammy loop of cross server commands...
		Function = function(plr,args)
			if not Core.CrossServer("NewRunCommand", {Name = plr.Name; UserId = plr.UserId, AdminLevel = Admin.GetLevel(plr)}, args[1]) then
				error("CrossServer Handler Not Ready");
			end
		end;
	};

	Commands.CrossServerList = {
		Prefix = Settings.Prefix;
		Commands = {"serverlist", "crossserverlist", "listservers"};
		Args = {};
		Description = "Attempts to list all active servers (at the time the command was ran)";
		AdminLevel = "Admins";
		CrossServerDenied = true;
		Function = function(plr,args)
			local disced = false;
			local updateKey = "SERVERPING".. math.random();
			local replyList = {};
			local listener = service.Events.ServerPingReplyReceived:Connect(function(jobId, data)
				if jobId then
					replyList[jobId] = data or {};
				end
			end)

			local function listUpdate()
				local tab = {}
				local totalPlayers = 0;
				local totalServers = 0;

				for jobId,data in pairs(replyList) do
					totalServers = totalServers + 1;
					totalPlayers = totalPlayers + (data.NumPlayers or 0);
					table.insert(tab, {
						Text = "Players: ".. (data.NumPlayers or 0) .. " | JobId: ".. jobId;
						Desc = "JobId: ".. jobId;
					})
				end

				table.insert(tab, 1, {
					Text = "Total Servers: ".. totalServers .." | Total Players: ".. totalPlayers;
					Desc = "The total number of servers and players";
				})

				return tab;
			end

			local function doDisconnect()
				if not disced then
					disced = true;
					Logs.TempUpdaters[updateKey] = nil;
					listener:Disconnect();
				end
			end

			if not Core.CrossServer("Ping") then
				doDisconnect();
				error("CrossServer Handler Not Ready");
			else
				local closeEvent = Remote.NewPlayerEvent(plr,updateKey, function()
					doDisconnect();
				end)

				Logs.TempUpdaters[updateKey] = listUpdate;

				Remote.MakeGui(plr,"List",{
					Title = 'Server List',
					Tab = listUpdate(),
					Update = "TempUpdate",
					UpdateArgs = {{UpdateKey = updateKey}},
					OnClose = "client.Remote.PlayerEvent('".. updateKey .."')";
					AutoUpdate = 1,
				})

				delay(500, doDisconnect)
			end
		end;
	};

	Commands.CrossServerVote = {
		Prefix = Settings.Prefix;
		Commands = {"crossservervote", "crsvote"};
		Args = {"anwser1,answer2,etc (NO SPACES)";"question";};
		Filter = true;
		Description = "Lets you ask players in all servers a question with a list of answers and get the results";
		AdminLevel = "Moderators";
		CrossServerDenied = true;
		Function = function(plr,args)
			local question = args[2]
			if not question then error("You forgot to supply a question!") end
			local answers = args[1]
			local anstab = {}
			local responses = {}
			local voteKey = "ADONISVOTE".. math.random();
			local startTime = os.time();

			local msgSub = MsgService:SubscribeAsync(voteKey, function(data)
				table.insert(responses, data.Data.Response)
			end)

			local function voteUpdate()
				local results = {}
				local total = #responses
				local tab = {
					"Question: "..question;
					"Total Responses: "..total;
					"Time Left: ".. math.max(0, 120 - (os.time()-startTime));
					--"Didn't Vote: "..#players-total;
				}

				for i,v in pairs(responses) do
					if not results[v] then results[v] = 0 end
					results[v] = results[v]+1
				end

				for i,v in pairs(anstab) do
					local ans = v
					local num = results[v]
					local percent
					if not num then
						num = 0
						percent = 0
					else
						percent = math.floor((num/total)*100)
					end

					table.insert(tab,{Text=ans.." | "..percent.."% - "..num.."/"..total,Desc="Number: "..num.."/"..total.." | Percent: "..percent})
				end

				return tab;
			end

			Logs.TempUpdaters[voteKey] = voteUpdate;

			if not answers then
				anstab = {"Yes","No"}
			else
				for ans in answers:gmatch("([^,]+)") do
					table.insert(anstab,ans)
				end
			end

			local data = {
				Answers = anstab;
				Question = question;
				VoteKey = voteKey
			}

			Core.CrossServer("CrossServerVote", data)

			Remote.MakeGui(plr,"List",{
				Title = 'Results',
				Tab = voteUpdate(),
				Update = "TempUpdate",
				UpdateArgs = {{UpdateKey = voteKey}},
				AutoUpdate = 1,
			})

			delay(120, function() Logs.TempUpdaters[voteKey] = nil; msgSub:Disconnect(); end)
		end
	};

	--// Handlers
	Core.CrossServer = function(...)
		local data = {ServerId, ...};
		service.Queue("CrossServerMessageQueue", function()
			--// rate limiting
			counter = counter+1;
			if not lastTick then lastTick = os.time() end
			if counter >= 150 + 60 * #service.Players:GetPlayers()  then
				repeat wait() until os.time()-lastTick > 60;
			end

			if os.time()-lastTick > 60 then
				lastTick = os.time();
				counter = 1;
			end

			--// publish
			MsgService:PublishAsync(subKey, data)
		end, 300, true)

		return true;
	end

	Process.CrossServerMessage = function(msg)
		local data = msg.Data;
		if not data or type(data) ~= "table" then error("CrossServer: Invalid Data Type ".. type(data)); end
		Logs:AddLog("Script", "Cross-Server Message received: ".. tostring(data and data[2] or "nil data[2]"));
		local command = data[2];

		table.remove(data, 2);

		if Core.CrossServerCommands[command] then
			Core.CrossServerCommands[command](unpack(data));
		end
	end

	Core.SubEvent = MsgService:SubscribeAsync(subKey, function(...) return Process.CrossServerMessage(...) end)

	--// Check for additions added by other modules in core before this one loaded
	for i,v in next,oldCommands do
		Core.CrossServerCommands[i] = v;
	end

	Logs:AddLog("Script", "Cross-Server Module Loaded");
end;
