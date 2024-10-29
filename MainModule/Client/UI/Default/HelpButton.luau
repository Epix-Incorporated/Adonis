client = nil
Pcall = nil
Routine = nil
service = nil
gTable = nil

--// All global vars will be wiped/replaced except script

return function(data, env)
	if env then
		setfenv(1, env)
	end

	local UI = client.UI
	local Variables = client.Variables
	local Functions = client.Functions

	local gui = service.New("ScreenGui", {ResetOnSpawn = false})
	local gTable = UI.Register(gui)

	if UI.Get("HelpButton", gui, true) then
		gui:Destroy()
		gTable:Destroy()
		return nil
	end

	gTable.Name = "HelpButton"
	gTable.CanKeepAlive = true

	local toggle = service.New("ImageButton", {
		Parent = gui;
		Name = "Toggle";
		BackgroundTransparency = 1;
		Position = UDim2.new(1, -45, 1, -45);
		Size = UDim2.fromOffset(40, 40);
		Image = client.HelpButtonImage;
		ImageTransparency = 0.5;
	})

	--if UI.Get("Chat") then
	--	toggle.Position = UDim2.new(1, -(45+40),1, -45)
	--end

	toggle.MouseButton1Down:Connect(function()
		if (client.Functions.CheckDate(1, 4) or client.Functions.CheckDate(31, 10)) and client.Functions.PromptClown then -- OH NO!!!!! :O
			client.Functions.PromptClown()
		end

		local found = UI.Get("UserPanel", nil, true)
		if found then
			found.Object:Destroy()
		else
			UI.Make("UserPanel")
		end
	end)

	-- Preload clown assets to prevent 
	if (client.Functions.CheckDate(1, 4) or client.Functions.CheckDate(31, 10)) and not client.Variables.MaximusTrollicus and client.Functions.PreloadClown then
		local connection
		connection = toggle.MouseEnter:Connect(function()
			client.Functions.PreloadClown()
			connection:Disconnect()
		end)
	end

	gTable:Ready()
end
