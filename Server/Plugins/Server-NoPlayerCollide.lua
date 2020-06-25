server = nil 
service = nil

------------------------------------------------------------------------------------------------
--// Adds a command to enable or disable player to player character collisions (per player) //--
--// This is a plugin to handle the events required outside of the command 					//--
------------------------------------------------------------------------------------------------

return function()
	local cGroups = {}
	
	service.Players.PlayerAdded:Connect(function(p)
		local group = p.Name .. p.UserId
		service.PhysicsService:CreateCollisionGroup(group)
		cGroups[p] = group
		
		p.CharacterAdded:Connect(function()
			p.Character.DescendantAdded:Connect(function(c)
				if c:IsA("BasePart") then
					service.PhysicsService:SetPartCollisionGroup(c, group)
				end
			end)
		
			for i,v in next,p.Character:GetChildren() do
				if v:IsA("BasePart") then
					service.PhysicsService:SetPartCollisionGroup(v, group)
				end
			end
		end)
	end)	
	
	service.Players.PlayerRemoving:Connect(function(p)
		local group = cGroups[p]
		if group then
			service.PhysicsService:RemoveCollisionGroup(group)
			cGroups[p] = nil
		end
	end)
	
	server.Commands.SetPlayerCollision = {
		Prefix = server.Settings.Prefix;
		Commands = {"nocollide"};
		Args = {"player", "true/false"};
		Description = "Makes it so the player doesn't collide with other player's characters; Disable with :nocollide PlayerHere false";
		AdminLevel = "Moderators";
		Function = function(plr,args)
			assert(args[1], "Missing player argument")
			
			local collide = (args[2] == "false")
			for i,v in next,server.Functions.GetPlayers(plr, args[1]) do
				local tGroup = cGroups[v]
				if tGroup then
					for p,n in next,cGroups do
						service.PhysicsService:CollisionGroupSetCollidable(tGroup, n, collide)
					end
				end
			end
		end
	}
	
	--print("NoPlayerCollide Plugin Loaded");
end