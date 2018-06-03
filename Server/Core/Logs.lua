server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Special Variables
return function()
	local Settings = server.Settings
	local MaxLogs = Settings.MaxLogs
	local Logs
	
	server.Logs = {
		Chats = {};
		Joins = {};
		Script = {};
		Replications = {};
		NetworkOwners = {};
		RemoteFires = {};
		Commands = {};
		Exploit = {};
		Errors = {};
		
		TabToType = function(tab)
			local indToName = {
				Joins = "Join";
				Chats = "Chat";
				Errors = "Error";
				Commands = "Command";
				RemoteFires = "RemoteFire";
				Replications = "Replication";
				NetworkOwners = "NetworkOwner";
			}
			
			for ind,t in next,Logs do
				if t == tab then
					return indToName[ind] or ind
				end
			end
		end;
		
		AddLog = function(tab, dat)
			local log = dat
			
			if type(tab) == "string" then
				tab = Logs[tab]
			end
			
			if dat.Time then 
				log.Time = dat.Time 
			elseif not dat.NoTime then
				log.Time = service.GetTime() 
			end
			
			table.insert(tab, 1, log)
			if #tab > tonumber(MaxLogs) then
				table.remove(tab,#tab)
			end
			
			service.Events.LogAdded:Fire(tab, log) --server.Logs.TabToType(tab))
		end;
		
		ListUpdaters = {
			ShowTasks = function(plr,arg)
				if arg then
					for i,v in next,server.Functions.GetPlayers(plr, arg) do
						local temp = {}
						local cTasks = server.Remote.Get(v, "TaskManager", "GetTasks") or {}
						
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
					local cTasks = server.Remote.Get(plr,"TaskManager","GetTasks") or {}
					
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
			
			DonorList = function()
				local temptable={}
				for i,v in pairs(service.Players:children()) do
					if server.Admin.CheckDonor(v) then
						table.insert(temptable,v.Name)
					end
				end
				return temptable
			end;
			
			Errors = function()
				local tab = {}
				for i,v in pairs(server.Logs.Errors) do
					table.insert(tab,{Time=v.Time;Text=v.Text..": "..tostring(v.Desc),Desc = tostring(v.Desc)})
				end
				return tab
			end;
			
			ReplicationLogs = function()
				local tab = {}
				for i,v in pairs(server.Logs.Replications) do
					table.insert(tab,{Text=v.Player.." "..v.Action.." "..v.ClassName;Desc = v.Path})
				end
				return tab
			end;
			
			NetworkOwners = function()
				local tab = {}
				for i,v in pairs(server.Logs.NetworkOwners) do
					table.insert(tab,{Text = tostring(v.Player).." made "..tostring(v.Part),Desc = v.Path})
				end
				return tab
			end;
			
			ExploitLogs = function()
				--local temp={}
				--for i,v in pairs(server.Logs.Errors) do
				--	table.insert(tab,{Time = v.Time;Text = v.Text..": "..tostring(v.Desc):sub(1,20),Desc = v.Desc})
				--end
				return server.Logs.Exploit
			end;
			
			ChatLogs = function()
				return server.Logs.Chats
			end;
			
			JoinLogs = function()
				return server.Logs.Joins
			end;
			
			PlayerList = function(p)
				local plrs={}
				local playz=server.Functions.GrabNilPlayers('all')
				server.Function.Hint('Pinging players. Please wait. No ping = Ping > 5sec.',{p})
				for i,v in pairs(playz) do
					cPcall(function()
						if type(v)=="String" and v=="NoPlayer" then
							table.insert(plrs,{Text="PLAYERLESS CLIENT",Desc="PLAYERLESS SERVERREPLICATOR. COULD BE LOADING/LAG/EXPLOITER. CHECK AGAIN IN A MINUTE!"})
						else	
							local ping
							Routine(function()	
								ping = server.Ping(v).."ms"
							end)
							for i=0.1,5,0.1 do
								if ping then break end
								wait(0.1)
							end
							if v and service.Players:FindFirstChild(v.Name) then
								local h = ""
								local mh = ""
								local ws = ""
								local jp = ""
								local hn = ""
								local hum = server.Functions.FindClass(v.Character,"Humanoid")
								if v.Character and hum then
									h = hum.Health
									mh = hum.MaxHealth
									ws = hum.WalkSpeed
									jp = hum.JumpPower	
									hn = hum.Name
								else
									h = "NO CHARACTER/HUMANOID"
								end
								
								table.insert(plrs,{Text=v.Name.." - "..ping..'s',Desc='Lower: '..v.Name:lower()..' - Health: '..h.." - MaxHealth: "..mh.." - WalkSpeed: "..ws.." - JumpPower: "..jp.." - Humanoid Name: "..hum.Name})
							else
								table.insert(plrs,{Text='[NIL] '..v.Name,Desc='Lower: '..v.Name:lower()..' - Ping: '..ping})
							end
						end
					end)
				end
				
				for i=0.1,5,0.1 do
					if server.Functions.CountTable(plrs)>=server.Functions.CountTable(playz) then break end
					wait(0.1)
				end
				return plrs
			end;
			
			ServerDetails = function()
				local det={}
				local nilplayers=0
				for i,v in pairs(service.NetworkServer:children()) do
					if v and v:GetPlayer() and not service.Players:FindFirstChild(v:GetPlayer().Name) then
						nilplayers=nilplayers+1
					end
				end
				if server.HTTP.CheckHttp() then
					det.Http='Enabled'
				else
					det.Http='Disabled'
				end
				if pcall(function() loadstring("local hi = 'test'") end) then
					det.Loadstring='Enabled'
				else
					det.Loadstring='Disabled'
				end
				if service.Workspace.FilteringEnabled then
					det.Filtering="Enabled"
				else
					det.Filtering="Disabled"
				end
				if service.Workspace.StreamingEnabled then
					det.Streaming="Enabled"
				else
					det.Streaming="Disabled"
				end
				det.NilPlayers = nilplayers
				det.PlaceName = service.MarketPlace:GetProductInfo(game.PlaceId).Name
				det.PlaceOwner = service.MarketPlace:GetProductInfo(game.PlaceId).Creator.Name
				det.ServerSpeed = service.Round(service.Workspace:GetRealPhysicsFPS())
				--det.AdminVersion = server.version
				det.ServerStartTime = service.GetTime(server.ServerStartTime)
				local nonnumber=0
				for i,v in pairs(service.NetworkServer:children()) do
					if v and v:GetPlayer() and not server.Admin.CheckAdmin(v:GetPlayer(),false) then
						nonnumber=nonnumber+1
					end
				end
				det.NonAdmins=nonnumber
				local adminnumber=0
				for i,v in pairs(service.NetworkServer:children()) do
					if v and v:GetPlayer() and server.Admin.CheckAdmin(v:GetPlayer(),false) then
						adminnumber=adminnumber+1
					end
				end
				det.CurrentTime=service.GetTime()
				det.ServerAge=service.GetTime(os.time()-server.Variables.ServerStartTime)
				det.Admins=adminnumber
				det.Objects=#server.Variables.Objects
				det.Cameras=#server.Variables.Cameras
				
				local tab = {}
				for i,v in pairs(det) do
					table.insert(tab,{Text = i..": "..tostring(v),Desc = tostring(v)})
				end
				return tab
			end;
			
			CommandLogs = function()
				local temp={}
				for i,m in pairs(server.Logs.Commands) do
					table.insert(temp,{Time = m.Time;Text = m.Text..": "..m.Desc;Desc = m.Desc})
				end
		 		return temp
			end;
			
			ScriptLogs = function()
				return server.Logs.Script
			end;
			
			RemoteLogs = function(p)
				if server.Admin.CheckAdmin(p) or server.HTTP.Trello.CheckAgent(p) then
					return server.Logs.RemoteFires
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
						toTab(v.message, "Output: ")
					elseif v.messageType == Enum.MessageType.MessageWarning then
						toTab(v.message, "Warning: ", Color3.new(1,1,0))
					elseif v.messageType == Enum.MessageType.MessageInfo then
						toTab(v.message, "Info: ", Color3.new(0,0,1))
					elseif v.messageType == Enum.MessageType.MessageError then
						toTab(v.message, "Error: ", Color3.new(1,0,0))
					end
				end
				
				return temp
			end;
			
			ClientLog = function(p, player)
				local temp = {"Player is currently unreachable"}
				
				if player then
					temp = server.Remote.Get(player, "ClientLog") or temp
				end
				
				return temp
			end;
			
			Instances = function(p, player)
				if player then
					local temp = {"Player is currently unreachable"}
					
					if player then
						temp = server.Remote.Get(player, "InstanceList") or temp
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
	
	Logs = server.Logs
end