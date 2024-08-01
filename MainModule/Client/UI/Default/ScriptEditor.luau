client,service = nil,nil
return function(data, env)
	if env then
		setfenv(1, env)
	end
	
	local Save = nil
	local Run = nil
	
	local window = client.UI.Make("Window",{
		Title = `Editing - {data.Name}`;
		Name = "CommandBox";
		Icon = client.MatIcons.Code;
		Size  = {500, 300};
		MinSize = {300,250};
		OnClose = function()
			Save()
		end,
	})
	
	local Frame: ScrollingFrame = window:Add("ScrollingFrame",{
		Name = "Editor";
		Size = UDim2.new(1, -10, 1, -10);
		BackgroundTransparency = 1;
	})
	
	local Text: TextBox = Frame:Add("TextBox",{
		Name = "Script";
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
		BackgroundTransparency = 1;
		Text = data.Script or [[print("Hello World")]];
		PlaceholderText = "";
		TextYAlignment = "Top";
		TextXAlignment = "Left";
		MultiLine = true;
		ClearTextOnFocus = false;
		Font = Enum.Font.Code;
		TextSize = 16;
	})
	
	local SaveButton: TextButton = window:Add("TextButton",{
		Name = "Save";
		Text = "Save";
		Size = UDim2.new(0, 40, 0, 20);
		Position = UDim2.new(1, 0, 1, -25);
		AnchorPoint = Vector2.new(1, 1);
	})
	
	local RunButton: TextButton = window:Add("TextButton",{
		Name = "Run";
		Text = "Run";
		Size = UDim2.new(0, 40, 0, 20);
		Position = UDim2.new(1, 0, 1, 0);
		AnchorPoint = Vector2.new(1, 1);
	})
	
	Text:GetPropertyChangedSignal("TextBounds"):Connect(function()
		Frame:ResizeCanvas(true,true)
	end)
	
	Save = function()
		client.Remote.Send("SaveScript",{
			Name = data.Name;
			Text = Text.Text
		})
	end
	
	Run = function()
		client.Remote.Send("SaveScript",{
			Name = data.Name;
			Text = Text.Text
		})
		client.Remote.Send("RunScript",{data.Name})
	end
	
	SaveButton.MouseButton1Click:Connect(function()
		Save()
	end)
	
	RunButton.MouseButton1Click:Connect(function()
		Run()
	end)
	
	window:Ready()
end
