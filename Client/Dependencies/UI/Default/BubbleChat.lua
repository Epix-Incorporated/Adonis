
client = nil
service = nil

return function(data)
	local gTable
	local color = data.Color
	
	if color == "off" then
		client.UI.Remove("BubbleChat")
	else
		local window = client.UI.Make("Window",{
			Name  = "BubbleChat";
			Title = "Bubble Chat";
			Size  = {260,57};
			Position = UDim2.new(0, 10, 1, -80);
			AllowMultiple = false;
		})
		
		if window then
			local box = window:Add("TextBox",{
				Text = "Click here or press \";\" to chat";
				PlaceholderText = "Click here or press \";\" to chat";
				BackgroundTransparency = 1;
				TextScaled = true;
				TextSize = 20;
			})
			
			box.FocusLost:connect(function(enterPressed)
				if enterPressed and service.Player.Character:FindFirstChild('Head') and color and box.Text~='Click here or press ";" to chat' then
					if #box.Text > 0 then
						service.ChatService:Chat(service.Player.Character.Head, service.LaxFilter(box.Text), color)
					end
					box.Text = 'Click here or press ";" to chat'
				end
			end)
			
			window:BindEvent(service.UserInputService.InputBegan, function(inputObject, gameProcessed)
				if not gameProcessed and inputObject.UserInputType == Enum.UserInputType.Keyboard and inputObject.KeyCode == Enum.KeyCode.Semicolon then
					box:CaptureFocus()
				end
			end)
			
			gTable = window.gTable
			window:Ready()
		end
	end
end