
client = nil
service = nil

return function(data)
	local gTable, window, commslog, layout;
	local messageObjs = {};

	local function newMessage(Type, Title, Message, Icon, Time, Function)
		print(Icon)

		local newMsg = commslog:Add("Frame", {
			Size = UDim2.new(1, 0, 0, 50);
			BackgroundTransparency = 1;
			AutomaticSize = "Y";
			Children = {
				{ClassName = "Frame";
					Name = "LoggedItem";
					Size = UDim2.new(1, -10, 1, -10);
					Position = UDim2.new(0, 5, 0, 5);
					BackgroundTransparency = 0.5;
					AutomaticSize = "Y";
					Children = {
						{ClassName = "ImageButton";
							Name = "Icon";
							Size = UDim2.new(0, 48, 0, 48);
							Position = UDim2.new(0, 1, 0, 1);
							Image = Icon;
							OnClick = Function;
							BackgroundTransparency = 1;
						};

						{ClassName = "TextButton";
							Name = "Title";
							Size = UDim2.new(1, -55, 0, 15);
							Position = UDim2.new(0, 55, 0, 0);
							Text = Title;
							TextSize = "14";
							TextXAlignment = "Left";
							BackgroundTransparency = 1;
							OnClick = Function;
						};
						
						{ClassName = "TextButton";
							Name = "Type";
							Size = UDim2.new(1, -55, 0, 15);
							Position = UDim2.new(0, 55, 0, 0);
							Text = Type;
							TextSize = "14";
							TextXAlignment = "Right";
							BackgroundTransparency = 1;
							OnClick = Function;
						};
						
						{ClassName = "TextButton";
							Name = "Time";
							Size = UDim2.new(1, -55, 0, 15);
							Position = UDim2.new(0, 55, 0, 15);
							Text = Time;
							TextSize = "14";
							TextXAlignment = "Right";
							BackgroundTransparency = 1;
							OnClick = Function;
						};
						
						{ClassName = "TextButton";
							Name = "Function";
							Size = UDim2.new(1, -55, 0, 15);
							Position = UDim2.new(0, 55, 0, 30);
							Text = Function and "Clickable" or "Not clickable";
							TextSize = "14";
							TextXAlignment = "Right";
							BackgroundTransparency = 1;
							OnClick = Function;
						};

						{ClassName = "TextButton";
							Name = "Message";
							Size = UDim2.new(1, -55, 0, 10);
							Position = UDim2.new(0, 55, 0, 15);
							Text = Message;
							TextXAlignment = "Left";
							TextYAlignment = "Top";
							AutomaticSize = "Y";
							TextWrapped = true;
							TextScaled = false;
							RichText = true;
							BackgroundTransparency = 1;
							OnClick = Function;
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
	
	local result, code = pcall(function()
		service.LocalizationService:GetCountryRegionForPlayerAsync(game.Players.LocalPlayer)
	end)
	
	window = client.UI.Make("Window",{
		Name  = "CommunicationsCentre";
		Title =  (result and code == "US") and "Communications Center" or "Communications Centre";
		Icon = client.MatIcons.Forum;
		Size  = {500,300};
		OnClose = function()
			client.Variables.CommsCentreBindableEvent = nil;
		end;
	})

	commslog = window:Add("ScrollingFrame",{
		Size = UDim2.new(1, 0, 1, 0);
		Position = UDim2.new(0, 0, 0, 0);
		CanvasSize = UDim2.new(0, 0, 0, 0);
		BackgroundTransparency = 0.9;
	})

	layout = service.New("UIListLayout", {
		Parent = commslog;
		FillDirection = "Vertical";
		HorizontalAlignment = "Left";
		VerticalAlignment = "Bottom";
		SortOrder = "LayoutOrder";
	})

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		commslog.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y)
		commslog.CanvasPosition = Vector2.new(0, layout.AbsoluteContentSize.Y)
	end)

	if client.Variables.CommunicationsHistory then
		for i,v in ipairs(client.Variables.CommunicationsHistory) do
			newMessage(v.Type, v.Title, v.Message, v.Icon, v.Time, v.Function);
		end
	end
	
	service.HookEvent('CommsCentre', function(v)
		newMessage(v.Type, v.Title, v.Message, v.Icon, v.Time, v.Function)
	end)

	gTable = window.gTable
	window:Ready();
end
