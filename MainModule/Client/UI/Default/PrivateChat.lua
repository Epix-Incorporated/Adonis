
client = nil
service = nil

return function(data)
  local Owner = data.FromPlayer;
  local SessionKey = data.SessionKey;
  local SessionName = data.SessionName;
  local CanManageUsers = data.CanManageUsers;

	local debounce = false
	local gTable
  local newMessage

  local window, chatlog, reply, playerList, send, layout, sessionEvent;
  local peerList = {};
  local messageObjs = {};

  local selectedPlayer = nil;

  local function sendIt()
    local text = service.Trim(reply.Text);

    if text ~= "" then
      client.Remote.Send("Session", SessionKey, "SendMessage", text);
    end
  end

  local function promptAddUser()
    local list = {}
    for i,v in next,service.Players:GetPlayers() do
      local good = true;
      for k, peer in next,peerList do
        if peer.UserId == v.UserId then
          good = false;
          break;
        end
      end

      if good then
        table.insert(list, {
          Text = string.format("%s (%s)", v.Name, v.DisplayName);
          Data = service.UnWrap(v);
        });
      end
    end

    local answer = client.UI.Make("SelectionPrompt", {
      Name = "Add User";
      Options = list;
    });

    if answer then
        client.Remote.Send("Session", SessionKey, "AddPlayerToSession", answer);
    end
  end;

  local function updatePeerList(peers)
    playerList:ClearAllChildren();
    peerList = peers;

    local lObj = service.New("UIListLayout", {
      Parent = playerList;
      FillDirection = "Vertical";
      HorizontalAlignment = "Center";
      VerticalAlignment = "Top";
      SortOrder = "LayoutOrder";
    })

    for i,peer in next,peers do
      local pBut = playerList:Add("TextButton", {
        Text = peer.Name or tostring(peer);
        Size = UDim2.new(1, 0, 0, 25);
        TextSize = 12;
        BackgroundTransparency = 1;
      })

      if CanManageUsers then
        local ogColor = pBut.BackgroundColor3;
        local lerpColor = ogColor:Lerp(Color3.new(0, 0, 150), 0.1);

        if peer.UserId and peer.UserId ~= service.Players.LocalPlayer.UserId then
          pBut.MouseButton1Down:Connect(function()
            for i,v in ipairs(playerList:GetChildren()) do
              if v:IsA("TextButton") or v:IsA("Frame") then
                v.BackgroundTransparency = 1;
              end
            end

            selectedPlayer = peer;
            pBut.BackgroundTransparency = 0;
            pBut.BackgroundColor3 = lerpColor;
          end)
        end
      end
    end

    playerList.CanvasSize = UDim2.new(0, 0, 0, lObj.AbsoluteContentSize.Y)
  end;

  local function newMessage(data)
    local pName = data.PlayerName;
    local msg = data.Message;
    local icon = data.Icon or 0;

    local newMsg = chatlog:Add("Frame", {
      Size = UDim2.new(1, 0, 0, 50);
      BackgroundTransparency = 1;
      AutomaticSize = "Y";
      Children = {
        {ClassName = "Frame";
          Name = "CHATFRAME";
          Size = UDim2.new(1, -10, 1, -10);
          Position = UDim2.new(0, 5, 0, 5);
          BackgroundTransparency = 0.5;
          AutomaticSize = "Y";
          Children = {
            {ClassName = "ImageButton";
              Name = "Icon";
              Size = UDim2.new(0, 48, 0, 48);
              Position = UDim2.new(0, 1, 0, 1);
              Image = icon;
            };

            {ClassName = "TextLabel";
              Name = "PlayerName";
              Size = UDim2.new(1, -55, 0, 15);
              Position = UDim2.new(0, 55, 0, 0);
              Text = pName;
              TextSize = "12";
              TextXAlignment = "Left";
              BackgroundTransparency = 1;
            };

            {ClassName = "TextLabel";
              Name = "Message";
              Size = UDim2.new(1, -55, 0, 10);
              Position = UDim2.new(0, 55, 0, 15);
              Text = msg;
              TextXAlignment = "Left";
              TextYAlignment = "Top";
              AutomaticSize = "Y";
              TextWrapped = true;
              TextScaled = false;
              RichText = true;
              BackgroundTransparency = 1;
            };
          }
        }
      }
    })

    table.insert(messageObjs, newMsg);

    if #messageObjs > 200 then
      messageObjs[1]:Destroy();
      table.remove(messageObjs, 1);
    end
  end

  local function systemMessage(msg)
    newMessage({
      PlayerName = "*SYSTEM*";
      Message = msg;
      Icon = 0;
    })
  end;

  if client.UI.Get("PrivateChat".. SessionName) then
    return
  end

	window = client.UI.Make("Window",{
		Name  = "PrivateChat".. SessionName;
		Title = "Private Chat";
		Size  = {500,300};
    OnClose = function()
      if sessionEvent then
        sessionEvent:Disconnect()
      end

      client.Remote.Send("Session", SessionKey, "LeaveSession");
    end;
	})

	chatlog = window:Add("ScrollingFrame",{
		Size = UDim2.new(1, -105, 1, -45);
    CanvasSize = UDim2.new(0, 0, 0, 0);
		BackgroundTransparency = 0.9;
    --AutomaticCanvasSize = "Y";
	})

	reply = window:Add("TextBox", {
		Text = ""; --"Enter reply";
		PlaceholderText = "";
		Size = UDim2.new(1, -70, 0, 30);
		Position = UDim2.new(0, 5, 1, -35);
		ClearTextOnFocus = false;--true;
		TextScaled = true;
	})

  playerList = window:Add("ScrollingFrame",{
		Size = UDim2.new(0, 100, 1, -75);
    Position = UDim2.new(1, -100, 0, 0);
		BackgroundTransparency = 0.5;
    AutomaticCanvasSize = "Y";
	})

  add = window:Add("TextButton", {
		Text = "+";
		Size = UDim2.new(0, 30, 0, 30);
		Position = UDim2.new(1, -100, 1, -70);
		OnClick = function()
      if CanManageUsers then
        promptAddUser();
      else
        systemMessage("<i>You are not allowed to manage users</i>");
      end
		end
	})

  remove = window:Add("TextButton", {
		Text = "-";
		Size = UDim2.new(0, 30, 0, 30);
		Position = UDim2.new(1, -35, 1, -70);
		OnClick = function()
      if CanManageUsers then
        if selectedPlayer then
          client.Remote.Send("Session", SessionKey, "RemovePlayerFromSession", selectedPlayer);
          selectedPlayer = nil;
        end
      else
        systemMessage("<i>You are not allowed to manage users</i>");
      end
		end
	})

	send = window:Add("TextButton", {
		Text = "Send";
		Size = UDim2.new(0, 60, 0, 30);
		Position = UDim2.new(1, -65, 1, -35);
		OnClick = function()
			sendIt()
      reply.Text = "";
		end
	})

  layout = service.New("UIListLayout", {
    Parent = chatlog;
    FillDirection = "Vertical";
    HorizontalAlignment = "Left";
    VerticalAlignment = "Bottom";
    SortOrder = "LayoutOrder";
  })

	send.BackgroundColor3 = send.BackgroundColor3:lerp(Color3.new(0,0,0), 0.1)
	reply.FocusLost:Connect(function(isEnter)
    if isEnter then
      sendIt();
      reply.Text = "";
      reply:CaptureFocus();
    end
  end)

  layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    chatlog.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
    chatlog.CanvasPosition = Vector2.new(0, layout.AbsoluteContentSize.Y)
  end)

  if data.History then
    for i,data in ipairs(data.History) do
      local p = data.Sender;
      newMessage({
        PlayerName = p.Name;
        Message = data.Message;
        Icon = p.Icon or 0; --// replace with user avatar later
      });
    end
  end

  sessionEvent = service.Events.SessionData:Connect(function(sessionKey, cmd, ...)
    local vargs = {...};
    if SessionKey == sessionKey then
      if cmd == "PlayerSentMessage" then
        local p = vargs[1];
        local message = vargs[2];

        if newMessage then
          newMessage({
            PlayerName = p.Name;
            Message = message;
            Icon = p.Icon or 0;
          })
        end
      elseif cmd == "UpdatePeerList" then
        updatePeerList(vargs[1]);
      elseif cmd == "RemovedFromSession" then
        systemMessage("<i>You have been removed from this chat session</i>");
      elseif cmd == "AddedToSession" then
        systemMessage("<i>You have been added to this chat session</i>");
      end
    end
  end)

  client.Remote.Send("Session", SessionKey, "GetPeerList");
	gTable = window.gTable
  window:Ready();
end
