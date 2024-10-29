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

	local playergui = service.PlayerGui
	local localplayer = service.Players.LocalPlayer
	local gui = service.New("ScreenGui")
	local toggle = service.New("ImageButton", gui)
	local gTable = client.UI.Register(gui)
	
	local useCustomIcon

	if client.UI.Get("HelpButton", gui, true) then
		gui:Destroy()
		gTable:Destroy()
		return nil
	end
	if client.HelpButtonImage == "rbxassetid://357249130" then
		useCustomIcon = false
	else
		useCustomIcon = true
	end

	gTable.Name = "HelpButton"
	gTable.CanKeepAlive = false

	toggle.Name = "Toggle"
	toggle.BackgroundTransparency = 1
	toggle.Position = UDim2.new(1, -45, 1, -45)
	toggle.Size = UDim2.new(0, 40, 0, 40)
	if useCustomIcon then
		toggle.Image = client.HelpButtonImage
	else
		toggle.Image = "http://www.roblox.com/asset/?id=7059706594"
	end
	toggle.ImageTransparency = 0

	--if client.UI.Get("Chat") then
	--	toggle.Position = UDim2.new(1, -(45+40),1, -45)
	--end

	toggle.MouseButton1Down:Connect(function()
		if (client.Functions.CheckDate(1, 4) or client.Functions.CheckDate(31, 10)) and client.Functions.PromptClown then -- OH NO!!!!! :O
			client.Functions.PromptClown()
		end

		local found = client.UI.Get("UserPanel",nil,true)
		if found then
			found.Object:Destroy()
		else
			client.UI.Make("UserPanel",{})
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
