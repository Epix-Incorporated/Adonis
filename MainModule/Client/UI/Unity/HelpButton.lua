client = nil
Pcall = nil
Routine = nil
service = nil
gTable = nil

--// All global vars will be wiped/replaced except script

--[[ This HelpButton Theme displays by default the headshot of the LocalPlayer.
   Modes: {
          "HEADSHOT" -- LocalPlayer Headshot Thumb
          "CUSTOM" -- Loads from Settings
          }
--]]
return function(data, env)
	if env then
		setfenv(1, env)
	end
	local playergui = service.PlayerGui
	local localplayer = service.Players.LocalPlayer
	local gui = service.New("ScreenGui")

	local toggle = service.New("ImageButton", gui)
	local toggle1 = service.New("Frame", gui)

	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 6)
	round.Parent = toggle1

	local round1 = Instance.new("UICorner")
	round1.CornerRadius = UDim.new(0, 6)
	round1.Parent = toggle
	
	local useCustomIcon
	local gTable = client.UI.Register(gui)

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
	toggle1.Name = "RoundFrame"
	toggle1.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
	toggle.BackgroundTransparency = 1
	toggle1.Position = UDim2.new(1, -45, 1, -45)
	toggle.Position = UDim2.new(1, -42, 1, -38)
	toggle.Size = UDim2.new(0, 33, 0, 33) --33
	toggle.ZIndex = 67
	toggle1.Size = UDim2.new(0, 40, 0, 40)
	if useCustomIcon then
		toggle.Image = client.HelpButtonImage
	else
		toggle.Image = `https://www.roblox.com/headshot-thumbnail/image?userId={localplayer.UserId}&width=420&height=420&format=png`
	end

	toggle.ImageTransparency = 0

	--if client.UI.Get("Chat") then
	--	toggle.Position = UDim2.new(1, -(45+40),1, -45)
	--end

	toggle.MouseButton1Down:Connect(
		function()
			local found = client.UI.Get("UserPanel", nil, true)
			if found then
				found.Object:Destroy()
			else
				client.UI.Make("UserPanel", {})
			end
		end
	)

	gTable:Ready()
end
