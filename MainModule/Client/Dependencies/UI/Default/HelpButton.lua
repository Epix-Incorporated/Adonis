client = nil
cPcall = nil
Pcall = nil
Routine = nil
service = nil
gTable = nil

--// All global vars will be wiped/replaced except script

return function(data)
	local playergui = service.PlayerGui
	local localplayer = service.Players.LocalPlayer
	local gui = service.New("ScreenGui")
	local toggle = service.New("ImageButton", gui)
	local gTable = client.UI.Register(gui)
	
	if client.UI.Get("HelpButton", gui, true) then
		gui:Destroy()
		gTable:Destroy()
		return nil
	end
	
	gTable.Name = "HelpButton"
	gTable.CanKeepAlive = false
	
	toggle.Name = "Toggle"
	toggle.BackgroundTransparency = 1
	toggle.Position = UDim2.new(1, -45, 1, -45)
	toggle.Size = UDim2.new(0, 40, 0, 40)
	toggle.Image = settings.HelpButtonImage
	toggle.ImageTransparency = 0.5
	
	--if client.UI.Get("Chat") then
	--	toggle.Position = UDim2.new(1, -(45+40),1, -45)
	--end
	
	toggle.MouseButton1Down:connect(function()
		local found = client.UI.Get("UserPanel",nil,true)
		if found then
			found.Object:Destroy()
		else
			client.UI.Make("UserPanel",{})
		end
	end)
	
	gTable:Ready()
end
