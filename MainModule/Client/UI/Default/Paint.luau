local buffer = buffer -- // Adonis doesnt support buffers yet!
client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end

	local Variables = client.Variables
	local mouse = service.Players.LocalPlayer:GetMouse()
	local hold = false

	local window = client.UI.Make("Window", {
		Name  = "Paint";
		Title = "Paint";
		Icon = client.MatIcons.Palette;
	})

	local topbar = window:Add("Frame", {
		Size = UDim2.new(1, 0, 0, 28);
		Position = UDim2.new(0, 0, 0, 0);
		BackgroundTransparency = 1;
	})

	local pixelCount = topbar:Add("TextLabel", {
		Size = UDim2.new(0, 100, 1, -8);
		Position = UDim2.new(1, -180 - (Variables.CanUseEditableImages and 75 or 0), 0, 4);
		Text = `Pixels: {Variables.CanUseEditableImages and "N/A" or "0"}`;
		TextXAlignment = "Right";
		BackgroundTransparency = 1;
	})

	local canvas = window:Add("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 30);
		Size = UDim2.new(1, 0, 1, -30);
		BackgroundColor3 = Color3.new(1, 1, 1);
		ClipsDescendants = true;
	})

	local rawCanvas = Variables.CanUseEditableImages and canvas:Add("ImageLabel", {
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2. new(1, 0, 1, 0);
		Active = false;
		BackgroundTransparency = 1;
		BorderSizePixel = 0;
		Image = "rbxtemp://0"; -- // TODO: Replace when EditableImage:GetContent() becomes available (without FFlag)
	})
	local editableImage = Variables.CanUseEditableImages and rawCanvas:Add("EditableImage", {
		Size = rawCanvas.AbsoluteSize;
	})

	local pointer = canvas:Add("Frame", {
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(0, 4, 0, 4);
		AnchorPoint = Vector2.new(0.5, 0.5);
		BackgroundColor3 = Color3.new(0, 0, 0);
		BackgroundTransparency = 0;
		Visible = false;
	})

	canvas.MouseEnter:Connect(function()
		pointer.Visible = true
	end)

	canvas.MouseLeave:Connect(function()
		pointer.Visible = false
	end)

	canvas.MouseMoved:Connect(function(x, y)
		local offset = Vector2.new(math.abs(x - canvas.AbsolutePosition.X), math.abs(y - canvas.AbsolutePosition.Y)) - service.GuiService:GetGuiInset()
		pointer.Position = UDim2.new(0, offset.X, 0, offset.Y)

		if hold == false then return end

		if Variables.CanUseEditableImages then
			editableImage:DrawCircle(offset, math.ceil(pointer.Size.X.Offset / 2), pointer.BackgroundColor3, 0, Enum.ImageCombineType.Overwrite)
		else
			local pixel = pointer:Clone()
			pixel.Name = "Pixel"
			pixel.Parent = canvas
			pixelCount.Text = `Pixels: {pixelCount.Text:sub(9) + 1}`
		end
	end)
	
	topbar:Add("TextButton", {
		Size = UDim2.new(0, 70, 1, -8);
		Position = UDim2.new(1, -75, 0, 4);
		Text = "Clear";
		TextXAlignment = "Center";
		OnClick = function()
			for i, child in canvas:GetChildren() do
				if child.Name == "Pixel" then
					child:Destroy()
				end
			end

			if Variables.CanUseEditableImages then
				local size = editableImage.Size
				local newImage = buffer.create(size.X * size.Y * 4)

				buffer.fill(newImage, 0, 255)
				editableImage:WritePixelsBuffer(Vector2.new(0, 0), size, buffer.create(size.X * size.Y * 4))
			end

			pixelCount.Text = `Pixels: {Variables.CanUseEditableImages and "N/A" or "0"}`
		end
	})

	if Variables.CanUseEditableImages then
		local uploadDebounce = -math.huge

		topbar:Add("TextButton", {
			Size = UDim2.new(0, 70, 1, -8);
			Position = UDim2.new(1, -150, 0, 4);
			Text = "Upload";
			ToolTip = "Upload your paint creation as decal on the creator store.";
			TextXAlignment = "Center";
			OnClick = function()
				if os.clock() > uploadDebounce + 2.5 then
					uploadDebounce = os.clock()
					local decal = service.New("Decal")

					decal.Name = "Adonis_PaintDecal"
					decal.Texture = rawCanvas.Image
					editableImage:Clone().Parent = decal

					-- // Prompt user to upload decal
					local success, reason = pcall(service.AssetService.PromptCreateAssetAsync, service.AssetService, service.Players.LocalPlayer, decal, Enum.AssetType.Decal)

					if not success then
						client.UI.Make("Notification", {
							Title = "Uploading decal failed";
							Message = `Uploading decal failed due to: {reason}.`;
							Icon = client.MatIcons["Error"];
							Time = 10;
						})
					end
				end
			end
		})
	end

	topbar:Add("TextLabel", {
		Text = " Color: ";
		Size = UDim2.new(0, 90, 1, -8);
		Position = UDim2.new(0, 5, 0, 4);
		BackgroundTransparency = 0.25;
		TextXAlignment = "Left";
		Children = {
			{
				Class = "TextButton";
				Text = "";
				Size = UDim2.new(0, 40, 1, -6);
				Position = UDim2.new(1, -45, 0, 3);
				BackgroundColor3 = Color3.new(0, 0, 0);
				TextTransparency = 0;
				BackgroundTransparency = 0;
				BorderPixelSize = 1;
				BorderColor3 = Color3.fromRGB(100, 100, 100);
				OnClick = function(new)
					local newColor = client.UI.Make("ColorPicker", {
						Color = Color3.new(0, 0, 0);
					})

					new.BackgroundColor3 = newColor
					pointer.BackgroundColor3 = newColor
				end
			}
		}
	})

	local sizeControl = topbar:Add("TextLabel", {
		Text = "  Size: ";
		BackgroundTransparency = 0;
		Size = UDim2.new(0, 70, 1, -8);
		Position = UDim2.new(0, 100, 0, 4);
		TextXAlignment = "Left";
		Children = {
			TextBox = {
				Text = "";
				PlaceholderText = "4";
				Size = UDim2.new(0, 26, 1, 0);
				Position = UDim2.new(1, -31, 0, 0);
				BackgroundTransparency = 1;
				TextXAlignment = "Right";
				ClipsDescendants = true;
				TextChanged = function(text, enter, new)
					if tonumber(text) then
						if tonumber(text) < 100 then
							pointer.Size = UDim2.new(0, text, 0, text)
						else
							pointer.Size = UDim2.new(0, 99, 0, 99)
						end
					end
				end
			}
		}
	})

	window:Ready()

	service.UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			hold = true
		end
	end)
	service.UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			hold = false
		end
	end)
end
