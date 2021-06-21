
client = nil
service = nil

return function(data)
  local Owner = data.FromPlayer;
  local SessionKey = data.SessionKey;

	local debounce = false
	local gTable

  local sessionEvent = service.Events.SessionData:Connect(function(sessionKey, cmd, ...)
    local vargs = {...};
    print("we got session thing!");
    if SessionKey == sessionKey then
      print("SESSION KEY VALID")
      if cmd == "PlayerSentChat" then
        local p = vargs[1];
        local message = vargs[2];

        print("got chat: ".. p.Name, "Message: ".. message)
      end
    end
  end)

	local window = client.UI.Make("Window",{
		Name  = "PrivateChat";
		Title = "Private Chat";
		Size  = {300,200};
    OnClose = function()
    end;
	})

	local chatlog = window:Add("ScrollingFrame",{
		Size = UDim2.new(1, -10, 1, -40);
		BackgroundTransparency = 1;
	})

	local reply = window:Add("TextBox", {
		Text = ""; --"Enter reply";
		PlaceholderText = "Enter reply";
		Size = UDim2.new(1, -65, 0, 30);
		Position = UDim2.new(0, 5, 1, -35);
		ClearTextOnFocus = false;
		TextScaled = true;
	})

	local send = window:Add("TextButton", {
		Text = "Send";
		Size = UDim2.new(0, 60, 0, 30);
		Position = UDim2.new(1, -65, 1, -35);
		OnClick = function()
			sendIt(true)
		end
	})

	send.BackgroundColor3 = send.BackgroundColor3:lerp(Color3.new(0,0,0), 0.1)
	reply.FocusLost:connect(sendIt)

	gTable = window.gTable
  window:Ready();
end
