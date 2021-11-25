client = nil
service = nil

return function(data)
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
		Position = UDim2.new(1, -180, 0, 4);
		Text = "Pixels: 0";
		TextXAlignment = "Right";
		BackgroundTransparency = 1;
	})

	local canvas = window:Add("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 30);
		Size = UDim2.new(1, 0, 1, -30);
		BackgroundColor3 = Color3.new(1, 1, 1);
		ClipsDescendants = true;
	})
	
	local pointer = canvas:Add("Frame", {
		Position = UDim2.new(0, 0, 0, 0);
		Size = UDim2.new(0, 4, 0, 4);
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
		local offset = Vector2.new(math.abs(x - canvas.AbsolutePosition.X), math.abs(y - canvas.AbsolutePosition.Y - 36))
		pointer.Position = UDim2.new(0, offset.X, 0, offset.Y)

		if hold == false then return end

		local pixel = pointer:Clone()
		pixel.Name = "Pixel"
		pixel.Parent = canvas
		pixelCount.Text = "Pixels: "..tostring(pixelCount.Text:sub(9) + 1)
	end)
	
	local clearButton = topbar:Add("TextButton", {
		Size = UDim2.new(0, 70, 1, -8);
		Position = UDim2.new(1, -75, 0, 4);
		Text = "Clear";
		TextXAlignment = "Center";
		OnClick = function()
			local children = canvas:GetChildren()
			for i, child in pairs (children) do
				if child.Name == "Pixel" then
					child:Destroy()
				end
			end
			pixelCount.Text = "Pixels: 0"
		end
	})

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
					if enter and tonumber(text) then
						if tonumber(text) < 100 then
							pointer.Size = UDim2.new(0, text, 0, text);
						else
							pointer.Size = UDim2.new(0, 99, 0, 99);
						end
					end
				end
			}
		}
	})

	window:Ready()

	service.UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			hold = true
		end
	end)
	service.UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			hold = false
		end
	end)
end
