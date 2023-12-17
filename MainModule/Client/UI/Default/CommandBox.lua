client,service = nil,nil

return function(data,env)
	if env then
		setfenv(1, env)
	end
	
	local window = client.UI.Make("Window",{
		Title = "Command Box";
		Name = "CommandBox";
		Icon = client.MatIcons.Code;
		Size  = {300, 250};
	})
	
	local Frame: ScrollingFrame = window:Add("ScrollingFrame",{
		Name = "ComFrame";
		Size = UDim2.new(1, -10, 1, -45);
		BackgroundTransparency = 0.5;
	})
	
	local Text: TextLabel = Frame:Add("TextBox",{
		Name = "ComText";
		Size = UDim2.new(1, 0, 1, 0);
		Position = UDim2.new(0, 0, 0, 0);
		Text = "";
		BackgroundTransparency = 0.5;
		PlaceholderText = "Enter commands here";
		TextYAlignment = "Top";
		MultiLine = true;
		ClearTextOnFocus = false;
	})
	
	local Execute: TextButton = window:Add("TextButton",{
		Name = "Execute";
		Size = UDim2.new(1, -10, 0, 35);
		Position = UDim2.new(0, 5, 1, -40);
		Text = "Execute";
		OnClick = function()
			client.Remote.Send("ProcessCommand", Text.Text)
		end,
	})
	
	Text:GetPropertyChangedSignal("Text"):Connect(function()
		if Text.TextBounds.Y > Frame.AbsoluteSize.Y then
			Text:SetSize(UDim2.new(1, 0, 0, Text.TextBounds.Y+5))
			Text:SetPosition(UDim2.new(0, 0, 0, 0))
			Frame.CanvasSize = UDim2.new(0, 0, 0, Text.TextBounds.Y+5)
			Frame.CanvasPosition = Vector2.new(0, Frame.CanvasPosition.Y+21)
		else
			Frame.CanvasSize = UDim2.new(0, 0, 0, 0)
			Text:SetSize(UDim2.new(1, 0, 1, 0))
		end
	end)
	
	Frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if Text.TextBounds.Y < Frame.AbsoluteSize.Y then
			Frame.CanvasSize = UDim2.new(0, 0, 0, 0)
			Text:SetSize(UDim2.new(1, 0, 1, 0))
		end
	end)
	
	window:Ready()
end
