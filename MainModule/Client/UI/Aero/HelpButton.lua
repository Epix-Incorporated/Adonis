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

	local clickSound = service.New("Sound")
	clickSound.Parent = toggle
	clickSound.Volume = 0.25
	clickSound.SoundId = "rbxassetid://156286438"

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
	toggle.Image = client.HelpButtonImage
	toggle.ImageTransparency = 0.35
	toggle.Modal = client.Variables.ModalMode
	toggle.ClipsDescendants = true

	--if client.UI.Get("Chat") then
	--	toggle.Position = UDim2.new(1, -(45+40),1, -45)
	--end

	toggle.MouseButton1Down:Connect(function()
		task.spawn(function()
			local effect = Instance.new("ImageLabel")
			effect.Parent = toggle
			effect.AnchorPoint = Vector2.new(0.5, 0.5)
			effect.BorderSizePixel = 0
			effect.ZIndex = toggle.ZIndex + 1
			effect.BackgroundTransparency = 1
			effect.ImageTransparency = 0.8
			effect.Image = "rbxasset://textures/whiteCircle.png"
			effect.Position = UDim2.new(0.5, 0, 0.5, 0)
			effect:TweenSize(UDim2.new(0, toggle.AbsoluteSize.X * 2.5, 0, toggle.AbsoluteSize.X * 2.5), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.2)
			task.wait(0.2)
			effect:Destroy()
		end)
		local found = client.UI.Get("UserPanel",nil,true)
		if found then
			found.Object:Destroy()
		else
			clickSound:Play()
			client.UI.Make("UserPanel",{})
		end
	end)

	gTable:Ready()
end
