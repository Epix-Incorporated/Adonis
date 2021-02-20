client = nil
cPcall = nil
Pcall = nil
Routine = nil
service = nil
gTable = nil

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
	toggle.Position = UDim2.new(1, -60, 1, -60)
	toggle.Size = UDim2.new(0, 55, 0, 55)
	toggle.Image = data.Image or "rbxassetid://357249130"
	toggle.ImageTransparency = 0.2

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
