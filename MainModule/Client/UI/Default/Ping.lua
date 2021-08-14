
client = nil
service = nil

return function(data)
	local pinging = true
	local gTable
	
	local window = client.UI.Make("Window",{
		Name  = "Ping";
		Title = "Ping";
		Size  = {150,70};
		Position = UDim2.new(0, 10, 1, -80);
		AllowMultiple = false;
		OnClose = function()
			pinging = false
		end
	})
	
	if window then
		local label = window:Add("TextLabel",{
			Text = "...";
			BackgroundTransparency = 1;
			TextSize = 20;
			Size = UDim2.new(1, 0, 1, 0);
			Position = UDim2.new(0, 0, 0, 0);
			--TextScaled = true;
			--TextWrapped = true;
		})
		
		gTable = window.gTable
		window:Ready()
		
		repeat
			label.Text = client.Remote.Ping().."ms"
			task.wait(2)
		until not pinging or not gTable.Active
	end
end