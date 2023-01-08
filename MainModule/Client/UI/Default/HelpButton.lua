client = nil
cPcall = nil
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

	local gui = service.New("ScreenGui", { ResetOnSpawn = false })
	local gTable = UI.Register(gui)

	if UI.Get("HelpButton", gui, true) then
		gui:Destroy()
		gTable:Destroy()
		return nil
	end

	gTable.Name = "HelpButton"
	gTable.CanKeepAlive = true

	local toggle = service.New("ImageButton", {
		Parent = gui,
		Name = "Toggle",
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -45, 1, -45),
		Size = UDim2.fromOffset(40, 40),
		Image = client.HelpButtonImage,
		ImageTransparency = 0.5,
	})

	--if UI.Get("Chat") then
	--	toggle.Position = UDim2.new(1, -(45+40),1, -45)
	--end

	toggle.MouseButton1Down:Connect(function()
		local found = UI.Get("UserPanel", nil, true)
		if found then
			found.Object:Destroy()
		else
			UI.Make("UserPanel")
		end
	end)

	gTable:Ready()
end
