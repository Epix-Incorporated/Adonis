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
		RemoteFires = {};
		Commands = {};
		Exploit = {};
		Errors = {};
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
			end;
			
			DateTime = function()

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
			
ServerDetails = function()
				local det={}
				local nilplayers=0
				for i,v in pairs(service.NetworkServer:children()) do
					if v and v:GetPlayer() and not service.Players:FindFirstChild(v:GetPlayer().Name) then
						nilplayers=nilplayers+1
					end
				end
				if HTTP.CheckHttp() then
					det["HTTPService"]='[ON]'
				else
					det["HTTPService"]='[OFF]'
				end
				if pcall(function() loadstring("local hi = 'test'") end) then
					det["Loadstring"]='[ON]'
				else
					det["Loadstring"]='[OFF]'
				end
			
				if service.Workspace.StreamingEnabled then
					det["StreamingEnabled"]="[ON]"
				else
					det["StreamingEnabled"]="[OFF]"
				end
				det["NilPlayers"] = nilplayers
				det["Place Name"] = service.MarketPlace:GetProductInfo(game.PlaceId).Name
				det["Place Owner"] = service.MarketPlace:GetProductInfo(game.PlaceId).Creator.Name
				det["Server Speed"] = service.Round(service.Workspace:GetRealPhysicsFPS())
				--det.AdminVersion = version
				det["Server Start Time"] = service.GetTime(server.ServerStartTime)
				local nonnumber=0
				for i,v in pairs(service.NetworkServer:children()) do
					if v and v:GetPlayer() and not Admin.CheckAdmin(v:GetPlayer(),false) then
						nonnumber=nonnumber+1
					end
				end
				det["Non-Admins"]=nonnumber
				local adminnumber=0
				for i,v in pairs(service.NetworkServer:children()) do
					if v and v:GetPlayer() and Admin.CheckAdmin(v:GetPlayer(),false) then
						adminnumber=adminnumber+1
					end
				end
				det["Current Time"]=service.GetTime()
				det["Server Age"]=service.GetTime(os.time()-server.ServerStartTime)
				det["Admins"]=adminnumber
				det["Objects"]=#Variables.Objects
				det["Cameras"]=#Variables.Cameras
				
				local tab = {}
				for i,v in pairs(det) do
					table.insert(tab,{Text = i..": "..tostring(v),Desc = tostring(v)})
				end
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
					local mType = v.messageType
					toTab(v.message, (mType  == Enum.MessageType.MessageWarning and "Warning" or mType  == Enum.MessageType.MessageInfo and "Info" or mType  == Enum.MessageType.MessageError and "Error" or "Output").." - ", mType  == Enum.MessageType.MessageWarning and Color3.new(0.866667, 0.733333, 0.0509804) or mType  == Enum.MessageType.MessageInfo and Color3.new(0.054902, 0.305882, 1) or mType  == Enum.MessageType.MessageError and Color3.new(1, 0.196078, 0.054902))
				end
				return temp
			end;
			
			ClientLog = function(p, player)
				local temp = {"Player is currently unreachable"}
				
				if player then
					temp = (player.Parent and Remote.Get(player, "ClientLog")) or temp
				end
				
				return temp
			end;
			
			Instances = function(p, player)
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
			end;
		};
	};
	
	Logs = Logs
end
