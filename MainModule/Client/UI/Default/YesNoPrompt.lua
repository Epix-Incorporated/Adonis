
client = nil
service = nil

return function(data)
	local gTable
	local answer
	
	local window = client.UI.Make("Window",{
		Name  = "Prompt";
		Title = "Prompt";
		Size  = {225,150};
		SizeLocked = true;
		--Icon = "rbxassetid://136615916";
		OnClose = function()
			if not answer then
				answer = "No"
			end
		end
	})
	
	local label = window:Add("TextLabel",{
		Text = data.Question;
		Font = "SourceSans";
		TextScaled = true;
		BackgroundTransparency = 1;
		TextWrapped = true;
		Size = UDim2.new(1, -10, 0.7, -5);
	})
	
	local yes = window:Add("TextButton",{
		Text = "Yes";
		Font = "Arial";
		TextSize = 18;
		Size = UDim2.new(0.5, -5, 0.3, -5);
		Position = UDim2.new(0,5,0.7,0);
		BackgroundColor3 = Color3.fromRGB(74, 195, 56);
		BackgroundTransparency = 0.5;
	})
	
	local no = window:Add("TextButton",{
		Text = "No";
		Font = "Arial";
		TextSize = 18;
		Size = UDim2.new(0.5, -5, 0.3, -5);
		Position = UDim2.new(0.5,0,0.7,0);
		BackgroundColor3 = Color3.fromRGB(206, 72, 45);
		BackgroundTransparency = 0.5;
	})
	
	yes.MouseButton1Down:Connect(function()
		answer = "Yes"
		window:Close()
	end)
	
	no.MouseButton1Down:Connect(function()
		answer = "No"
		window:Close()
	end)
	
	gTable = window.gTable
	window:Ready()
	repeat wait() until answer 
	return answer
end