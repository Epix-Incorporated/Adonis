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
		
		Logs:AddLog("Script", "Logging Module Initialized");
	end;
	
	server.Logs = {
		Init = Init;
		Chats = {};
		Joins = {};
		Script = {};
		Replications = {};
		NetworkOwners = {};
		RemoteFires = {};
		Commands = {};
		Exploit = {};
		Errors = {};
		ServerDetails = {};
		TempUpdaters = {};
		TabToType = function(tab)
			local indToName = {
				Chats = "Chat";
				Joins = "Join";
				Script = "Script";
				Replications = "Replication";
				PrivateMessages = "PrivateMessages";
				NetworkOwners = "NetworkOwner";
				RemoteFires = "RemoteFire";
				Commands = "Command";
				Exploit = "Exploit";
				Errors = "Error";
				ServerDetails = "ServerDetails"
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
					table.insert(temp, m)--{Time = m.Time; Text = m.Text..": "..m.Desc; Desc = m.Desc})
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
				if arg then
					for i,v in next,Functions.GetPlayers(plr, arg) do
						local temp = {}
						local cTasks = Remote.Get(v, "TaskManager", "GetTasks") or {}
						
						table.insert(temp,{
							Text = "Client Tasks",
							Desc = "Current tasks performed by the client"})
						
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
					
					table.insert(temp,{Text = "Server Tasks",Desc = "Current tasks performed by the server"})
					
					for i,v in next,tasks do
						table.insert(temp,{
							Text = tostring(v.Function).." - Status: "..v.Status.." - Elapsed: "..(os.time()-v.Created),
							Desc = v.Name
						})
					end
					
					table.insert(temp," ")
					table.insert(temp,{
						Text = "Client Tasks",
						Desc = "Current tasks performed by the client"
					})
					
					for i,v in pairs(cTasks) do 
						table.insert(temp,{
							Text = tostring(v.Function).." - Status: "..v.Status.." - Elapsed: "..(v.CurrentTime-v.Created),
							Desc = v.Name
						})
					end
					
					return temp
				end
			end;
			
			OldCommandLogs = function()
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
			end;
			
			DonorList = function()
				local temptable = {}
				for i,v in pairs(service.Players:children()) do
					if Admin.CheckDonor(v) then
						table.insert(temptable,v.Name)
					end
				end
				return temptable
			end;
			
			
			Errors = function()
				local tab = {}
				for i,v in pairs(Logs.Errors) do
					table.insert(tab,{Time=v.Time;Text=v.Text..": "..tostring(v.Desc),Desc = tostring(v.Desc)})
				end
				return tab
			end;
			
			ReplicationLogs = function()
				local tab = {}
				for i,v in pairs(Logs.Replications) do
					table.insert(tab,{Text=v.Player.." "..v.Action.." "..v.ClassName;Desc = v.Path})
				end
				return tab
			end;
			
			NetworkOwners = function()
				local tab = {}
				for i,v in pairs(Logs.NetworkOwners) do
					table.insert(tab,{Text = tostring(v.Player).." made "..tostring(v.Part),Desc = v.Path})
				end
				return tab
			end;
			
			ExploitLogs = function()
				--local temp={}
				--for i,v in pairs(Logs.Errors) do
				--	table.insert(tab,{Time = v.Time;Text = v.Text..": "..tostring(v.Desc):sub(1,20),Desc = v.Desc})
				--end
				return Logs.Exploit
			end;
			
			ChatLogs = function()
				return Logs.Chats
			end;
			
			JoinLogs = function()
				return Logs.Joins
			end;
			
			PlayerList = function(p)
				local plrs = {}
				local playz = Functions.GrabNilPlayers('all')
				
				for i,v in pairs(playz) do
					cPcall(function()
						if type(v) == "string" and v == "NoPlayer" then
							table.insert(plrs,{Text = "[PLAYERLESS CLIENT]", Desc="PLAYERLESS SERVERREPLICATOR. COULD BE LOADING/LAG/EXPLOITER. CHECK AGAIN IN A MINUTE!"})
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
			end;
			
			ServerDetails = function()
				local tab={}
				local nilplayers=0
				for i,v in pairs(service.NetworkServer:children()) do
					if v and v:GetPlayer() and not service.Players:FindFirstChild(v:GetPlayer().Name) then
						nilplayers=nilplayers+1
					end
				end
				local nonnumber=0
				for i,v in pairs(service.NetworkServer:children()) do
					if v and v:GetPlayer() and not Admin.CheckAdmin(v:GetPlayer(),false) then
						nonnumber=nonnumber+1
					end
				end
				local adminnumber=0
				for i,v in pairs(service.NetworkServer:children()) do
					if v and v:GetPlayer() and Admin.CheckAdmin(v:GetPlayer(),false) then
						adminnumber=adminnumber+1
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
				if HTTP.CheckHttp() then
					table.insert(tab,{Text = "HTTPService: [ON]"})
				else
					table.insert(tab,{Text = "HTTPService: [OFF]"})
				end
				if game.Workspace.AllowThirdPartySales == true then
					table.insert(tab,{Text = "Third Party Sales: [ON]"})
				else
					table.insert(tab,{Text = "Third Party Sales: [OFF]"})
				end

				if pcall(function() loadstring("local hi = 'test'") end) then
					table.insert(tab,{Text = "Loadstring: [ON]"})

				else
					table.insert(tab,{Text = "Loadstring: [OFF]"})

				end

				if service.Workspace.StreamingEnabled == true then
					table.insert(tab,{Text = "Streaming: [ON]"})
				else
					table.insert(tab,{Text = "Streaming: [OFF]"})
				end
				table.insert(tab,{Text = "―――――――――――――――――――――――"})
				table.insert(tab,{Text = "Admins: "..adminnumber})
				table.insert(tab,{Text = "Non Admins: "..nonnumber})
				table.insert(tab,{Text = "―――――――――――――――――――――――"})
				table.insert(tab,{Text = "Nil Players: "..nilplayers})
				table.insert(tab,{Text = "Objects: "..#Variables.Objects})
				table.insert(tab,{Text = "Cameras: "..#Variables.Cameras})
				table.insert(tab,{Text = "Gravity: "..tostring(game.Workspace.Gravity)})
				table.insert(tab,{Text = "Fallen Parts Destroy Height: "..tostring(game.Workspace.FallenPartsDestroyHeight)})
				table.insert(tab,{Text = "―――――――――――――――――――――――"})
				return tab
			end;
			
			CommandLogs = function()
				local temp = {}
				
				for i,m in pairs(Logs.Commands) do
					table.insert(temp,{Time = m.Time; Text = m.Text..": "..m.Desc; Desc = m.Desc})
				end
				
		 		return temp
			end;
			
			ScriptLogs = function()
				return Logs.Script
			end;
			
			RemoteLogs = function(p)
				if Admin.CheckAdmin(p) or HTTP.Trello.CheckAgent(p) then
					return Logs.RemoteFires
				end
			end;
				
			ServerLog = function()
				local temp = {}
				local function toTab(str, desc, color)
					for i,v in next,service.ExtractLines(str) do
						table.insert(temp,{Text = v,Desc = desc..v, Color = color})
					end
				end
				
				for i,v in next,service.LogService:GetLogHistory() do
					if v.messageType == Enum.MessageType.MessageOutput then
						toTab(v.message, "Output - ")
					elseif v.messageType == Enum.MessageType.MessageWarning then
						toTab(v.message, "Warning - ", Color3.new(0.866667, 0.733333, 0.0509804))
					elseif v.messageType == Enum.MessageType.MessageInfo then
						toTab(v.message, "Info - ", Color3.new(0.054902, 0.305882, 1))
					elseif v.messageType == Enum.MessageType.MessageError then
						toTab(v.message, "Error - ", Color3.new(1, 0.196078, 0.054902))
					end
				end
				
				return temp
			end;
			
			ClientLog = function(p, player)
				local temp = {"[Unreachable Client]"}
				
				if player then
					temp = (player.Parent and Remote.Get(player, "ClientLog")) or temp
				end
				
				return temp
			end;
			
			Instances = function(p, player)
				if player then
					local temp = {"[Unreachable Player]"}
					
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
			end;
		};
	};
	
	Logs = Logs
end
