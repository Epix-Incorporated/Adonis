server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Special Variables
return function(Vargs)
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

		game:BindToClose(function()
			Logs.SaveCommandLogs()
		end);

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
			Core.UpdateData("OldCommandLogs", function(oldLogs)
				local temp = {}

				for i,m in ipairs(Logs.Commands) do
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
					return a.Time > b.Time;
				end)

				for i,v in ipairs(temp) do
					if i > MaxLogs then
						temp[i] = nil;
					end
				end

			 	return temp
			end)
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
									Text = tostring(v.Function).. "- Status: "..v.Status.." - Elapsed: ".. v.CurrentTime - v.Created,
									Desc = v.Name;
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
								Text = tostring(v.Function).." - Status: "..v.Status.." - Elapsed: "..(os.time()-v.Created),
								Desc = v.Name
							})
						end

						table.insert(temp," ")
						table.insert(temp,{
							Text = "Client Tasks",
							Desc = "Tasks your client is performing"
						})

						for i,v in pairs(cTasks) do
							table.insert(temp,{
								Text = tostring(v.Function).." - Status: "..v.Status.." - Elapsed: "..(v.CurrentTime-v.Created),
								Desc = v.Name
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
									local h = ""
									local mh = ""
									local ws = ""
									local jp = ""
									local hn = ""
									local hum = v.Character and v.Character:FindFirstChildOfClass("Humanoid")

									if v.Character and hum then
										h = hum.Health
										mh = hum.MaxHealth
										ws = hum.WalkSpeed
										jp = hum.JumpPower
										hn = hum.Name
									else
										h = "NO CHARACTER/HUMANOID"
									end

									table.insert(plrs,{Text = "["..ping.."] "..v.Name.. " (".. v.DisplayName ..")", Desc = 'Lower: '..v.Name:lower()..' - Health: '..h..((not hum and "") or " - MaxHealth: "..mh.." - WalkSpeed: "..ws.." - JumpPower: "..jp.." - Humanoid Name: "..hum.Name)})
								else
									table.insert(plrs,{Text = '[LOADING] '..v.Name, Desc = 'Lower: '..v.Name:lower()..' - Ping: '..ping})
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

			ServerDetails = function(plr)
				if not plr or Admin.CheckAdmin(plr) then
					local tab, nilplayers, nonnumber, adminnumber = {}, 0, 0, 0

					for i,v in pairs(service.NetworkServer:GetChildren()) do
						if v and v:GetPlayer() and not service.Players:FindFirstChild(v:GetPlayer().Name) then
							nilplayers+=1
						end
					end
					for i,v in pairs(service.Players:GetPlayers()) do
						if Admin.CheckAdmin(v,false) then
							adminnumber+=1
						else
							nonnumber+=1
						end
					end

					table.insert(tab,{Text = "―――――――――――――――――――――――"})
					table.insert(tab,{Text = "Place Name: "..service.MarketPlace:GetProductInfo(game.PlaceId).Name})
					table.insert(tab,{Text = "Place Owner: "..service.MarketPlace:GetProductInfo(game.PlaceId).Creator.Name})
					table.insert(tab,{Text = "―――――――――――――――――――――――"})
					table.insert(tab,{Text = "Server Speed: "..service.Round(service.Workspace:GetRealPhysicsFPS())})
					table.insert(tab,{Text = "Server Start Time: "..service.GetTime(server.ServerStartTime)})
					table.insert(tab,{Text = "Server Age: "..service.GetTime(os.time()-server.ServerStartTime)})
					table.insert(tab,{Text = "―――――――――――――――――――――――"})

					--[[
					if workspace.AllowThirdPartySales == true then
						table.insert(tab,{Text = "Third Party Sales: [ON]"})
					else
						table.insert(tab,{Text = "Third Party Sales: [OFF]"})
					end
					]]

					local LoadstringEnabled = HTTP.LoadstringEnabled and "ON" or "OFF"
					local StreamingEnabled =  workspace.StreamingEnabled and "ON" or "OFF"
					local HttpEnabled = HTTP.CheckHttp() and "ON" or "OFF"

					table.insert(tab,{Text = "Loadstring: [".. LoadstringEnabled .."]"})
					table.insert(tab,{Text = "Streaming: [".. StreamingEnabled .."]"})
					table.insert(tab,{Text = "HttpEnabled: [".. HttpEnabled .."]"})

					table.insert(tab,{Text = "―――――――――――――――――――――――"})
					table.insert(tab,{Text = "In-Game Admins: "..adminnumber})
					table.insert(tab,{Text = "In-Game Non Admins: "..nonnumber})
					table.insert(tab,{Text = "―――――――――――――――――――――――"})
					table.insert(tab,{Text = "Nil Players: "..nilplayers})
					table.insert(tab,{Text = "Objects: "..#Variables.Objects})
					table.insert(tab,{Text = "Cameras: "..#Variables.Cameras})
					table.insert(tab,{Text = "Gravity: "..tostring(workspace.Gravity)})
					table.insert(tab,{Text = "Fallen Parts Destroy Height: "..tostring(workspace.FallenPartsDestroyHeight)})
					table.insert(tab,{Text = "―――――――――――――――――――――――"})
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
				if Admin.CheckAdmin(p) or HTTP.Trello.CheckAgent(p) then
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
