server = nil
service = nil
cPcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

--// Anti-Exploit
return function()
	server.Anti = {
		RemovePlayer = function(p, info)
			info = info or "No Reason Given"
			pcall(function() service.UnWrap(p):Kick(tostring(info)) end)
			--pcall(function() server.Remote.Send(p,"Function","Kill") end)
			wait(1)
			pcall(p.Destroy, p)
			pcall(service.Delete, p)
			server.Logs.AddLog("Script",{
				Text = "Server removed "..tostring(p);
				Desc = tostring(info);
			})
		end;
		
		Sanitize = function(obj, classList)
			if server.Anti.RLocked(obj) then
				pcall(service.Delete, obj)
			else
				for i,child in next,obj:GetChildren() do
					if server.Anti.RLocked(child) or server.Functions.IsClass(child, classList) then
						pcall(service.Delete, child)
					else
						pcall(server.Anti.Sanitize, child, classList)
					end
				end
			end
		end;
		
		isFake = function(p)
			if server.Anti.ObjRLocked(p) or not p:IsA("Player") then
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
			local ran,err = pcall(function() isFake = server.Anti.isFake(p) end)
			if isFake or not ran then
				server.Anti.RemovePlayer(p)
			end
		end;
		
		FindFakePlayers = function()
			for i,v in pairs(service.Players:GetChildren()) do
				if server.Anti.isFake(v) then
					server.Anti.RemovePlayer(v, "Fake")
				end
			end
		end;
		
		GetClassName = function(obj)
			local testName = tostring(math.random()..math.random())
			local ran,err = ypcall(function()
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
			if server.Core.DebugMode then 
				warn("ANTI-EXPLOIT: "..player.Name.." "..action.." "..info)
			elseif service.NetworkServer then
				if player then
					if action:lower() == 'kick' then
						server.Anti.RemovePlayer(player, info)
						--player:Kick("Adonis; Disconnected by server; \n"..tostring(info))
					elseif action:lower() == 'kill' then
						player.Character:BreakJoints()
					elseif action:lower() == 'crash' then
						server.Remote.Send(player,'Function','Kill')
						wait(5)
						pcall(function()
							local scr = server.Core.NewScript("LocalScript",[[while true do end]])
							scr.Parent = player.Backpack
							scr.Disabled = false
						end)
						
						server.Anti.RemovePlayer(player, info)
					end
				end
			end
			
			server.Logs.AddLog(server.Logs.Script,{
				Text = "Detected "..tostring(player);
				Desc = "The Anti-Exploit system detected that "..tostring(player).." was exploiting";
			})
			
			server.Logs.AddLog(server.Logs.Exploit,{
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
						server.Anti.Detected(p,'log','Name/UserId does not match') 
					end 
					
					server.Remote.Send(p,"LaunchAnti","NameId",{RealID = realId; RealName = realName})
				end
			end 
		end;
	};
end