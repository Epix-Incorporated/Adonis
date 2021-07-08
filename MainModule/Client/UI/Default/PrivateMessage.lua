
client = nil
service = nil

return function(data)
	local localplayer = service.Player
	local player = data.Player
	local message = data.Message
	local title = data.Title
	local debounce = false
	local gTable
	
	local window = client.UI.Make("Window",{
		Name  = "PrivateMessage";
		Title = tostring(player);
		Size  = {300,150};
	})
	
	local label = window:Add("TextLabel",{
		Text = data.Message;
		Size = UDim2.new(1, -10, 1, -40);
		BackgroundTransparency = 1;
		TextScaled = true;
		TextWrapped = true;
	})
	
	local reply = window:Add("TextBox", {
		Text = ""; --"Enter reply";
		PlaceholderText = "Enter reply";
		Size = UDim2.new(1, -65, 0, 30);
		Position = UDim2.new(0, 5, 1, -35);
		ClearTextOnFocus = false;
		TextScaled = true;
	})
	
	local function sendIt(enter)
		if not debounce then
			debounce = true
			if enter then
				window:Close()
				client.Remote.Send('PrivateMessage','Reply from '..localplayer.Name, player, localplayer, reply.Text)
				client.UI.Make("Hint", {Message = "Reply sent"})
			end
			debounce = false
		end
	end
	
	local send = window:Add("TextButton", {
		Text = "Send";
		Size = UDim2.new(0, 60, 0, 30);
		Position = UDim2.new(1, -65, 1, -35);
		OnClick = function()
			sendIt(true)
		end
	})
	
	send.BackgroundColor3 = send.BackgroundColor3:lerp(Color3.new(0,0,0), 0.1)
	reply.FocusLost:Connect(sendIt)
	
	gTable = window.gTable
	client.UI.Make("Notification",{
		Title = "New Message";
		Message = "Message from "..player.Name;
		Time = false;
		OnClick = function() window:Ready() end;
		OnClose = function() window:Destroy() end;
		OnIgnore = function() window:Destroy() end;
	})
end