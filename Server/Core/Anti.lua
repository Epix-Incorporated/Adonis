server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Anti-Exploit
return function()
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
		
		Logs:AddLog("Script", "AntiExploit Module Initialized")
	end;
	
	server.Anti = {
		Init = Init;
		RemovePlayer = function(p, info)
			info = info or "No Reason Given"
			pcall(function() service.UnWrap(p):Kick(tostring(info)) end)
			--pcall(function() Remote.Send(p,"Function","Kill") end)
			wait(1)
			pcall(p.Destroy, p)
			pcall(service.Delete, p)
			Logs.AddLog("Script",{
				Text = "Server removed "..tostring(p);
				Desc = tostring(info);
			})
		end;
		
		UserNameCheck = function(p)
			local ran,name = pcall(function()
				return service.Players:GetNameFromUserIdAsync(p.UserId);
			end)
			--print(name)
			--if p.DisplayName ~= p.Name then
			--	return false;
			--end
			
			if ran and name == p.Name then 
				return true;
			end
		end;
		
		Sanitize = function(obj, classList)
			if Anti.RLocked(obj) then
				pcall(service.Delete, obj)
			else
				for i,child in next,obj:GetChildren() do
					if Anti.RLocked(child) or Functions.IsClass(child, classList) then
						pcall(service.Delete, child)
					else
						pcall(Anti.Sanitize, child, classList)
					end
				end
			end
		end;
		
		isFake = function(p)
			if Anti.ObjRLocked(p) or not p:IsA("Player") then
				return true,1
			else
				local players = service.Players:GetChildren()
				local found = 0
				
				if service.NetworkServer then
					local net = false
					for i,v in pairs(service.NetworkServer:GetChildren()) do
						if v:IsA("NetworkReplicator") and v:GetPlayer() == p then
							net = true
						end 
					end
					if not net then
						return true,1
					end
				end
				
				for i,v in pairs(players) do
					if tostring(v) == tostring(p) then
						found = found+1
					end
				end
				
				if found>1 then
					return true,found
				else
					return false
				end
			end
		end;
		
		RemoveIfFake = function(p)
			local isFake
			local ran,err = pcall(function() isFake = Anti.isFake(p) end)
			if isFake or not ran then
				Anti.RemovePlayer(p)
			end
		end;
		
		FindFakePlayers = function()
			for i,v in pairs(service.Players:GetChildren()) do
				if Anti.isFake(v) then
					Anti.RemovePlayer(v, "Fake")
				end
			end
		end;
		
		GetClassName = function(obj)
			local testName = tostring(math.random()..math.random())
			local ran,err = pcall(function()
				local test = obj[testName]
			end)
			if err then
				local class = err:match(testName.." is not a valid member of (.*)")
				if class then
					return class
				end
			end
		end;
		
		RLocked = function(obj)
			return not pcall(function() return obj.GetFullName(obj) end)
			--[[local ran,err = pcall(function() service.New("StringValue", obj):Destroy() end)
			if ran then
				return false
			else
				return true
			end--]]
		end;
		
		ObjRLocked = function(obj)
			return not pcall(function() return obj.GetFullName(obj) end)
			--[[local ran,err = pcall(function() obj.Parent = obj.Parent end)
			if ran then
				return false
			else
				return true
			end--]]
		end;
		
		AssignName = function()
			local name = math.random(100000,999999)
			return name
		end;
		
		Detected = function(player,action,info)
			if Core.DebugMode or service.RunService:IsStudio() then 
				warn("ANTI-EXPLOIT: "..player.Name.." "..action.." "..info)
			elseif service.NetworkServer then
				if player then
					if action:lower() == 'kick' then
						Anti.RemovePlayer(player, info)
						--player:Kick("Adonis; Disconnected by server; \n"..tostring(info))
					elseif action:lower() == 'kill' then
						player.Character:BreakJoints()
					elseif action:lower() == 'crash' then
						Remote.Send(player,'Function','Kill')
						wait(5)
						pcall(function()
							local scr = Core.NewScript("LocalScript",[[while true do end]])
							scr.Parent = player.Backpack
							scr.Disabled = false
						end)
						
						Anti.RemovePlayer(player, info)
					end
				end
			end
			
			Logs.AddLog(Logs.Script,{
				Text = "AE Detected "..tostring(player);
				Desc = "The Anti-Exploit system detected strange activity from "..tostring(player);
			})
			
			Logs.AddLog(Logs.Exploit,{
				Text = "[Action: "..tostring(action).."] "..tostring(player);
				Desc = tostring(info);
			})
		end;
		
		CheckNameID = function(p)
			if p.userId > 0 and p.userId ~= game.CreatorId and p.Character then 
				local realId = service.Players:GetUserIdFromNameAsync(p.Name) or p.userId
				local realName = service.Players:GetNameFromUserIdAsync(p.userId) or p.Name
				
				if realName and realId then
					if (tonumber(realId) and realId~=p.userId) or (tostring(realName)~="nil" and realName~=p.Name) then 
						Anti.Detected(p,'log','Name/UserId does not match') 
					end 
					
					Remote.Send(p,"LaunchAnti","NameId",{RealID = realId; RealName = realName})
				end
			end 
		end;
	};
end