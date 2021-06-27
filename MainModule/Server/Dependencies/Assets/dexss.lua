local remote =  Instance.new("RemoteEvent",game.Workspace)
remote.Name = "dothepro"
remote.OnServerEvent:Connect(function(Plr,Action,Suppliments)
	if not game.Players:FindFirstChild(Plr.Name):FindFirstChild("Dex_Explorer") then
		Plr:Kick("Exploiter")
	else
	
	
	
	if Action == "destroy" then
		for i,v in pairs(Suppliments) do
			pcall(v:Destroy())
		end
	end

	if Action == "setproperty" then
		Suppliments["#PART"][Suppliments["#SETTING"]] = Suppliments["#NEWSETTING"]
	end
	if Action == "duplicate" then
		for i,v in pairs(Suppliments) do
			pcall(function()
				v:Clone().Parent = v.Parent or workspace
			end)
		end
	end
	if Action == "insert part" then
		
		for i,v in pairs(Suppliments) do
			
			pcall(function()
				
				local Part = Instance.new("Part")
				
				Part.Parent = Suppliments["#PARENT"]
			end)
		end
	end
	if Action == "group" then
		
		local Model = Instance.new("Model")
		
		
		Model.Parent = Suppliments["#MODEL_PARENT"]
		
		for i,v in pairs(Suppliments["#ITEMS"]) do
			
			v.Parent = Model
			
		end
		
		
		

	end	
	

	if Action == "ungroup" then
		
		for i,v in pairs(Suppliments["#ITEMS"]) do
			
			if v:IsA("Model") then
				
				for i,Part in pairs(v:GetChildren()) do
					
					Part.Parent = v.Parent
					
				end
				
				v:Destroy()

			end
		end
	end	
	if Action == "setparent" then
		Suppliments["#ITEM"].Parent = Suppliments["#PARENT"]
		
		end	
	end
end)

