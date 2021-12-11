server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Special Variables
return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server;
	local service = Vargs.Service;

	local MaxLogs = 1000
	local Functions, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Settings
	local function Init()
		Functions = server.Functions;
		Admin = server.Admin;
		Anti = server.Anti;
		Core = server.Core;
		HTTP = server.HTTP;
		Logs = server.Logs;
		Remote = server.Remote;
		Process = server.Process;
		Variables = server.Variables;
		Settings = server.Settings;

		MaxLogs = Settings.MaxLogs;

		game:BindToClose(Logs.SaveCommandLogs);

		Logs.Init = nil;
		Logs:AddLog("Script", "Logging Module Initialized");
	end;

	server.Logs = {
		Init = Init;
		Chats = {};
		Joins = {};
		Script = {};
		RemoteFires = {};
		Commands = {};
		Exploit = {};
		Errors = {};
		ServerDetails = {};
		DateTime = {};
		TempUpdaters = {};
		OldCommandLogsLimit = 1000; --// Maximum number of command logs to save to the datastore (the higher the number, the longer the server will take to close)

		TabToType = function(tab)
			local indToName = {
				Chats = "Chat";
				Joins = "Join";
				Script = "Script";
				RemoteFires = "RemoteFire";
				Commands = "Command";
				Exploit = "Exploit";
				Errors = "Error";
				ServerDetails = "ServerDetails";
				DateTime = "DateTime";
			}

			for ind,t in next,server.Logs do
				if t == tab then
					return indToName[ind] or ind
				end
			end
		end;

		AddLog = function(tab, log, misc)
			if misc then tab = log log = misc end
			if type(tab) == "string" then
				tab = Logs[tab]
			end

			if type(log) == "string" then
				log = {
					Text = log;
					Desc = log;
				}
			end

			if not log.Time and not log.NoTime then
				log.Time = service.GetTime()
			end

			table.insert(tab, 1, log)
			if #tab > tonumber(MaxLogs) then
				table.remove(tab,#tab)
			end

			service.Events.LogAdded:Fire(server.Logs.TabToType(tab), log, tab)
		end;

		SaveCommandLogs = function()
			warn("Saving command logs...")

			local logsToSave = Logs.Commands --{};
			local maxLogs = Logs.OldCommandLogsLimit;
			--local numLogsToSave = 200; --// Save the last X logs from this server

			--for i = #Logs.Commands, i = math.max(#Logs.Commands - numLogsToSave, 1), -1 do
			--	table.insert(logsToSave, Logs.Commands[i]);
			--end

			Core.UpdateData("OldCommandLogs", function(oldLogs)
				local temp = {}

				for i,m in ipairs(logsToSave) do
					local newTab = (type(m) == "table" and service.CloneTable(m)) or m;
					if type(m) == "table" and newTab.Player then
						local p = newTab.Player;
						newTab.Player = {
							Name = p.Name;
							UserId = p.UserId;
						}
					end
					table.insert(temp, newTab)--{Time = m.Time; Text = m.Text..": "..m.Desc; Desc = m.Desc})
				end

				if oldLogs then
					for i,m in ipairs(oldLogs) do
						table.insert(temp, m)
					end
				end

				table.sort(temp, function(a, b)
					if a.Time and b.Time and type(a.Time) == "number" and type(b.Time) == "number" then
						return a.Time > b.Time;
					else
						return false;
					end
				end)

				--// Trim logs, starting from the oldest
				if #temp > maxLogs then
					local diff = #temp - maxLogs;

					for i = 1, diff do
						table.remove(temp, 1)
					end
				end

			 	return temp
			end)

			warn("Command logs saved!")
		end;

		ListUpdaters = {
			TempUpdate = function(plr, data)
				local updateKey = data.UpdateKey;
				local updater = Logs.TempUpdaters[updateKey];
				if updater then
					return updater(data);
				end
			end;

			ShowTasks = function(plr,arg)
				if not plr or Admin.CheckAdmin(plr) then
					if arg then
						for i,v in next,Functions.GetPlayers(plr, arg) do
							local temp = {}
							local cTasks = Remote.Get(v, "TaskManager", "GetTasks") or {}

							table.insert(temp,{
								Text = "Client Tasks",
								Desc = "Tasks their client is performing"})

							for k,t in next,cTasks do
								table.insert(temp, {
									Text = tostring(v.Name or v.Function).. "- Status: "..v.Status.." - Elapsed: ".. v.CurrentTime - v.Created,
									Desc = tostring(v.Function);
								})
							end

							return temp
						end
					else
						local tasks = service.GetTasks()
						local temp = {}
						local cTasks = Remote.Get(plr,"TaskManager","GetTasks") or {}

						table.insert(temp,{Text = "Server Tasks",Desc = "Tasks the server is performing"})

						for i,v in next,tasks do
							table.insert(temp,{
								Text = tostring(v.Name or v.Function).." - Status: "..v.Status.." - Elapsed: "..(os.time()-v.Created),
								Desc = tostring(v.Function);
							})
						end

						table.insert(temp," ")
						table.insert(temp,{
							Text = "Client Tasks",
							Desc = "Tasks your client is performing"
						})

						for i,v in pairs(cTasks) do
							table.insert(temp,{
								Text = tostring(v.Name or v.Function).." - Status: "..v.Status.." - Elapsed: "..(v.CurrentTime-v.Created),
								Desc = tostring(v.Function);
							})
						end

						return temp
					end
				end
			end;

			OldCommandLogs = function(plr)
				if not plr or Admin.CheckAdmin(plr) then
					local temp = {}
					if Core.DataStore then
						local data = Core.GetData("OldCommandLogs")
						if data then
							for i,m in pairs(data) do
								table.insert(temp, {Time = m.Time; Text = m.Text..": "..m.Desc; Desc = m.Desc})
							end
						end
					end

					return temp;
				end
			end;

			DonorList = function()
				local temptable = {}
				for i,v in pairs(service.GetPlayers()) do
					if Admin.CheckDonor(v) then
						table.insert(temptable,v.Name)
					end
				end
				return temptable
			end;

			Errors = function(plr)
				if not plr or Admin.CheckAdmin(plr) then
					local tab = {}
					for i,v in pairs(Logs.Errors) do
						table.insert(tab,{Time=v.Time;Text=v.Text..": "..tostring(v.Desc),Desc = tostring(v.Desc)})
					end
					return tab
				end
			end;

			ExploitLogs = function(plr)
				if not plr or Admin.CheckAdmin(plr) then
					--local temp={}
					--for i,v in pairs(Logs.Errors) do
					--	table.insert(tab,{Time = v.Time;Text = v.Text..": "..tostring(v.Desc):sub(1,20),Desc = v.Desc})
					--end
					return Logs.Exploit
				end
			end;

			ChatLogs = function(plr)
				if not plr or Admin.CheckAdmin(plr) then
					return Logs.Chats
				end
			end;

			JoinLogs = function(plr)
				if not plr or Admin.CheckAdmin(plr) then
					return Logs.Joins
				end
			end;

			PlayerList = function(p)
				if not p or Admin.CheckAdmin(p) then
					local plrs = {}
					local playz = Functions.GrabNilPlayers('all')

					for i,v in pairs(playz) do
						cPcall(function()
							if type(v) == "string" and v == "NoPlayer" then
								table.insert(plrs,{Text = "PLAYERLESS CLIENT", Desc="PLAYERLESS SERVERREPLICATOR. COULD BE LOADING/LAG/EXPLOITER. CHECK AGAIN IN A MINUTE!"})
							else
								local ping

								Routine(function()
									ping = Remote.Ping(v).."ms"
								end)

								for i = 0.1,5,0.1 do
									if ping then break end
									wait(0.1)
								end

								if not ping then
									ping = ">5000ms"
								end

								if v and service.Players:FindFirstChild(v.Name) then
									local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")
									table.insert(plrs, {
										Text = string.format("[%s] %s (@%s)", ping, v.Name, v.DisplayName);
										Desc = string.format("Lower: %s - Health: %d - MaxHealth: %d - WalkSpeed: %d JumpPower: %d Humanoid Name: %s", v.Name, hum and hum.Health or 0, hum and hum.MaxHealth or 0, hum and hum.WalkSpeed or 0, hum and hum.JumpPower or 0, hum and hum.Name or "?");
									})
								else
									table.insert(plrs, {
										Text = "[LOADING] "..v.Name,
										Desc = "Lower: "..string.lower(v.Name).." - Ping: "..ping
									})
								end
							end
						end)
					end

					for i = 0.1,5,0.1 do
						if Functions.CountTable(plrs) >= Functions.CountTable(playz) then break end
						wait(0.1)
					end

					return plrs
				end
			end;

			DateTime = function()
				-- NonAdmin ListUpdater, no level check
				local ostime = os.time()
				local tab = {}
				table.insert(tab,{Text = "―――――――――――――――――――――――"})

				table.insert(tab,{Text = "Date: "..os.date("%x",ostime)})
				table.insert(tab,{Text = "Time: "..os.date("%H:%M | %I:%M %p",ostime)})
				table.insert(tab,{Text = "Timezone: "..os.date("%Z",ostime)})

				table.insert(tab,{Text = "―――――――――――――――――――――――"})


				table.insert(tab,{Text = "Minute: "..os.date("%M",ostime)})
				table.insert(tab,{Text = "Hour: "..os.date("%H | %I %p",ostime)})
				table.insert(tab,{Text = "Day: "..os.date("%d %A",ostime)})
				table.insert(tab,{Text = "Week (First sunday): "..os.date("%U",ostime)})
				table.insert(tab,{Text = "Week (First monday): "..os.date("%W",ostime)})
				table.insert(tab,{Text = "Month: "..os.date("%m %B",ostime)})
				table.insert(tab,{Text = "Year: "..os.date("%Y",ostime)})

				table.insert(tab,{Text = "―――――――――――――――――――――――"})

				table.insert(tab,{Text = "Day of the year: "..os.date("%j",ostime)})
				table.insert(tab,{Text = "Day of the month: "..os.date("%d",ostime)})

				table.insert(tab,{Text = "―――――――――――――――――――――――"})
				return tab
			end;

			ServerPerfStats = function(plr)
				if not plr or Admin.CheckAdmin(plr) then
					local tab = {}
					local perfStats = {
						{"ContactsCount"; "How many parts are currently in contact with one another"},
						{"DataReceiveKbps"; "Roughly how many kB/s of data are being received by the server"},
						{"DataSendKbps"; "Roughly how many kB/s of data are being sent by the server"},
						{"HeartbeatTimeMs"; "The total amount of time in ms it takes long it takes to update all Task Scheduler jobs"},
						{"InstanceCount"; "How many Instances are currently in memory"},
						{"MovingPrimitivesCount"; "How many physically simulated components are currently moving in the game world"},
						{"PhysicsReceiveKbps"; "Roughly how many kB/s of physics data are being received by the server"},
						{"PhysicsSendKbps"; "Roughly how many kB/s of physics data are being sent by the server"},
						{"PhysicsStepTimeMs"; "How long it takes for the physics engine to update its current state, in milliseconds"},
						{"PrimitivesCount"; "How many physically simulated components currently exist in the game world"},
					};
					for _, v in ipairs(perfStats) do
						table.insert(tab, {Text = v[1]..": "..tostring(service.Stats[v[1]]):sub(1,7); Desc = v[2];})
					end
					return tab
				end
			end;

			CommandLogs = function(plr)
				if not plr or Admin.CheckAdmin(plr) then
					local temp = {}

					for i,m in pairs(Logs.Commands) do
						table.insert(temp,{Time = m.Time; Text = m.Text..": "..m.Desc; Desc = m.Desc})
					end

					return temp
				end
			end;

			ScriptLogs = function(plr)
				if not plr or Admin.CheckAdmin(plr) then
					return Logs.Script
				end
			end;

			RemoteLogs = function(p)
				if Admin.CheckAdmin(p) then
					return Logs.RemoteFires
				end
			end;

			ServerLog = function(plr)
				if not plr or Admin.CheckAdmin(plr) then
					local temp = {}
					local function toTab(str, desc, color)
						for i,v in next,service.ExtractLines(str) do
							table.insert(temp,{Text = v,Desc = desc..v, Color = color})
						end
					end
					for i,v in next,service.LogService:GetLogHistory() do
						local mType = v.messageType
						toTab(v.message, (mType  == Enum.MessageType.MessageWarning and "Warning" or mType  == Enum.MessageType.MessageInfo and "Info" or mType  == Enum.MessageType.MessageError and "Error" or "Output").." - ", mType  == Enum.MessageType.MessageWarning and Color3.new(0.866667, 0.733333, 0.0509804) or mType  == Enum.MessageType.MessageInfo and Color3.new(0.054902, 0.305882, 1) or mType  == Enum.MessageType.MessageError and Color3.new(1, 0.196078, 0.054902))
					end
					return temp
				end
			end;

			ClientLog = function(p, player)
				if not p or Admin.CheckAdmin(p) then
					local temp = {"Player is currently unreachable"}

					if player then
						temp = (player.Parent and Remote.Get(player, "ClientLog")) or temp
					end

					return temp
				end
			end;

			Instances = function(p, player)
				if not p or Admin.CheckAdmin(p) then
					if player then
						local temp = {"Player is currently unreachable"}

						if player then
							temp = Remote.Get(player, "InstanceList") or temp
						end

						return temp
					else
						local objects = service.GetAdonisObjects()
						local temp = {}

						for i,v in next,objects do
							table.insert(temp, {
								Text = v:GetFullName();
								Desc = v.ClassName;
							})
						end

						return temp
					end
				end
			end;
		};
	};

	Logs = Logs
end
