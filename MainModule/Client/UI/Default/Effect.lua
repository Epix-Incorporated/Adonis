client = nil
cPcall = nil
Pcall = nil
Routine = nil
service = nil
gTable = nil

--// All global vars will be wiped/replaced except script
--// All guis are autonamed using client.Functions.GetRandom()

return function(data, env)
	if env then
		setfenv(1, env)
	end
	
	local gui = service.New("ScreenGui")
	local mode = data.Mode
	local gTable = client.UI.Register(gui, {Name = "Effect"})
	local BindEvent = gTable.BindEvent

	client.UI.Remove("Effect", gui)
	gTable:Ready()

	if mode == "Off" or not mode then
		gTable:Destroy()
	elseif mode == "Pixelize" then
		local frame = Instance.new("Frame")
		frame.Parent = gui
		local camera = workspace.CurrentCamera
		local pixels = {}

		local resY = data.Resolution or 20
		local resX = data.Resolution or 20
		local depth = 0
		local distance = data.Distance or 80

		local function renderScreen()
			for _, pixel in pairs(pixels) do
				local ray = camera:ScreenPointToRay(pixel.X, pixel.Y, depth)
				local result = workspace:Raycast(ray.Origin, ray.Direction * distance)
				local part, endPoint = result.Instance, result.Position
				if part and part.Transparency < 1 then
					pixel.Pixel.BackgroundColor3 = part.BrickColor.Color
				else
					pixel.Pixel.BackgroundColor3 = Color3.fromRGB(105, 170, 255)
				end
			end
		end

		frame.Size = UDim2.new(1, 0, 1, 40)
		frame.Position = UDim2.new(0, 0, 0, -35)
		for y = 0, gui.AbsoluteSize.Y+50, resY do
			for x = 0, gui.AbsoluteSize.X+30, resX do
				local pixel = service.New("TextLabel", {
					Parent = frame;
					Text = "";
					BorderSizePixel = 0;
					Size = UDim2.fromOffset(resX, resY);
					Position = UDim2.fromOffset(x-(resX/2), y-(resY/2));
					BackgroundColor3 = Color3.fromRGB(105, 170, 255);
				})
				table.insert(pixels, {Pixel = pixel, X = x, Y = y})
			end
		end

		while wait() and not gTable.Destroyed and gui.Parent do
			if not gTable.Destroyed and not gTable.Active then
				wait(5)
			else
				renderScreen()
			end
		end

		gTable:Destroy()
	elseif mode == "FadeOut" then
		service.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		service.UserInputService.MouseIconEnabled = false

		for _, v in pairs(service.PlayerGui:GetChildren()) do
			pcall(function() if v ~= gui then v:Destroy() end end)
		end

		local blur = service.New("BlurEffect", {
			Name = "Adonis_FadeOut_Blur";
			Parent = service.Lighting;
			Size = 0;
		})

		local bg = service.New("Frame", {
			Parent = gui;
			BackgroundTransparency = 1;
			BackgroundColor3 = Color3.new(0,0,0);
			Size = UDim2.new(2,0,2,0);
			Position = UDim2.new(-0.5,0,-0.5,0);
		})

		for i = 1, 0, -0.01 do
			bg.BackgroundTransparency = i
			blur.Size = 56 * (1 - i);
			wait(0.1)
		end

		bg.BackgroundTransparency = 0
	elseif mode == "Trippy" then
		local v = service.Player
		local bg = Instance.new("Frame")

		bg.BackgroundColor3 = Color3.new(0,0,0)
		bg.BackgroundTransparency = 0
		bg.Size = UDim2.new(10,0,10,0)
		bg.Position = UDim2.new(-5,0,-5,0)
		bg.ZIndex = 10
		bg.Parent = gui

		while gui and gui.Parent do
			wait(1/44)
			bg.BackgroundColor3 = Color3.new(math.random(255)/255, math.random(255)/255, math.random(255)/255)
		end

		if gui then gui:Destroy() end
	elseif mode == "Spooky" then
		local frame = Instance.new("Frame")
		frame.BackgroundColor3=Color3.new(0,0,0)
		frame.Size=UDim2.new(1,0,1,50)
		frame.Position=UDim2.new(0,0,0,-50)
		frame.Parent = gui
		local img = Instance.new("ImageLabel")
		img.Position = UDim2.new(0,0,0,0)
		img.Size = UDim2.new(1,0,1,0)
		img.BorderSizePixel = 0
		img.BackgroundColor3 = Color3.new(0,0,0)
		img.Parent = frame
		local textures = {
			299735022;
			299735054;
			299735082;
			299735103;
			299735133;
			299735156;
			299735177;
			299735198;
			299735219;
			299735245;
			299735269;
			299735289;
			299735304;
			299735320;
			299735332;
			299735361;
			299735379;
		}

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://174270407"
		sound.Looped = true
		sound.Parent = gui
		sound:Play()

		while gui and gui.Parent do
			for i=1,#textures do
				img.Image = "rbxassetid://"..textures[i]
				wait(0.1)
			end
		end
		sound:Stop()
	elseif mode == "lifeoftheparty" then
		local frame = Instance.new("Frame")
		frame.BackgroundColor3 = Color3.new(0,0,0)
		frame.Size = UDim2.new(1,0,1,50)
		frame.Position = UDim2.new(0,0,0,-50)
		frame.Parent = gui
		local img = Instance.new("ImageLabel")
		img.Position = UDim2.new(0,0,0,0)
		img.Size = UDim2.new(1,0,1,0)
		img.BorderSizePixel = 0
		img.BackgroundColor3 = Color3.new(0,0,0)
		img.Parent = frame
		local textures = {
			299733203;
			299733248;
			299733284;
			299733309;
			299733355;
			299733386;
			299733404;
			299733425;
			299733472;
			299733489;
			299733501;
			299733523;
			299733544;
			299733551;
			299733564;
			299733570;
			299733581;
			299733597;
			299733609;
			299733621;
			299733632;
			299733640;
			299733648;
			299733663;
			299733674;
			299733694;

		}
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://172906410"
		sound.Looped = true
		sound.Parent = gui
		sound:Play()

		while gui and gui.Parent do
			for i=1,#textures do
				img.Image = "rbxassetid://"..textures[i]
				wait(0.1)
			end
		end

		sound:Stop()
	elseif mode == "trolling" then
		local frame = Instance.new("Frame")
		frame.BackgroundColor3 = Color3.new(0,0,0)
		frame.Size = UDim2.new(1,0,1,50)
		frame.Position = UDim2.new(0,0,0,-50)
		frame.Parent = gui
		local img = Instance.new("ImageLabel")
		img.Position = UDim2.new(0,0,0,0)
		img.Size = UDim2.new(1,0,1,0)
		img.BorderSizePixel = 0
		img.BackgroundColor3 = Color3.new(0,0,0)
		img.Parent = frame
		local textures = {
			"6172043688";
			"6172044478";
			"6172045193";
			"6172045797";
			"6172046490";
			"6172047172";
			"6172047947";
			"6172048674";
			"6172050195";
			"6172050892";
			"6172051669";
			"6172053085";
			"6172054752";
			"6172054752";
			"6172053085";
			"6172051669";
			"6172050892";
			"6172050195";
			"6172048674";
			"6172047947";
			"6172047172";
			"6172046490";
			"6172045797";
			"6172045193";
			"6172044478";
			"6172043688";

		}
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://229681899"
		sound.Looped = true
		sound.Parent = gui
		sound:Play()

		while gui and gui.Parent do
			for i=1,#textures do
				img.Image = "rbxassetid://"..textures[i]
				wait(0.13)
			end
		end

		sound:Stop()
	elseif mode == "Strobe" then
		local bg = Instance.new("Frame")
		bg.BackgroundColor3 = Color3.new(0,0,0)
		bg.BackgroundTransparency = 0
		bg.Size = UDim2.new(10,0,10,0)
		bg.Position = UDim2.new(-5,0,-5,0)
		bg.ZIndex = 10
		bg.Parent = gui

		while gui and gui.Parent do
			wait(1/44)
			bg.BackgroundColor3 = Color3.new(1,1,1)
			wait(1/44)
			bg.BackgroundColor3 = Color3.new(0,0,0)
		end
		if gui then gui:Destroy() end
	elseif mode == "Blind" then
		local bg = Instance.new("Frame")
		bg.BackgroundColor3 = Color3.new(0,0,0)
		bg.BackgroundTransparency = 0
		bg.Size = UDim2.new(10,0,10,0)
		bg.Position = UDim2.new(-5,0,-5,0)
		bg.ZIndex = 10
		bg.Parent = gui
	elseif mode == "ScreenImage" then
		local bg = Instance.new("ImageLabel")
		bg.Image="rbxassetid://"..data.Image
		bg.BackgroundColor3 = Color3.new(0,0,0)
		bg.BackgroundTransparency = 0
		bg.Size = UDim2.new(1,0,1,0)
		bg.Position = UDim2.new(0,0,0,0)
		bg.ZIndex = 10
		bg.Parent = gui
	elseif mode == "ScreenVideo" then
		local bg = Instance.new("VideoFrame")
		bg.Video="rbxassetid://"..data.Video
		bg.BackgroundColor3 = Color3.new(0,0,0)
		bg.BackgroundTransparency = 0
		bg.Size = UDim2.new(1,0,1,0)
		bg.Position = UDim2.new(0,0,0,0)
		bg.ZIndex = 10
		bg.Parent = gui
		bg:Play()
	end
end
