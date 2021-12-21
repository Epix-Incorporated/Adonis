client, service = nil, nil

return function(data)
	local gTable
	local getList
	local newEntry
	local lastObject, curObject = game, game
	local scroller, search
	local nav: ScrollingFrame, navText: TextLabel

	local window = client.UI.Make("Window", {
		Name  = "Explorer";
		Title = "Game Explorer";
		Icon = client.MatIcons.Folder;
		Size  = {400, 300};
		MinSize = {300, 200};
		AllowMultiple = false;
		OnRefresh = function()
			getList(curObject)
		end
	})

	function newEntry(obj, name, isBack, top, color)
		local new = scroller:Add("TextLabel", {
			Text = "  "..tostring(name);
			ToolTip = ("Class: %s | Children%s"):format(obj.ClassName or "Unknown", if #obj:GetChildren() ~= 0 then ": "..#obj:GetChildren().." | Descendants: "..#obj:GetDescendants() else "/Descendants: 0");
			TextXAlignment = "Left";
			Size = UDim2.new(1, 0, 0, 26);
		})
		if color then new.TextColor3 = color end

		new:Add("UIListLayout", {
			FillDirection = "Horizontal"; 
			HorizontalAlignment = "Right";
			VerticalAlignment = "Center";
			SortOrder = "LayoutOrder";
		})

		local open = #obj:GetChildren() > 0 and new:Add("TextButton", {
			Text = "Open";
			Size = UDim2.new(0, 80, 1, 0);
			LayoutOrder = 1;
			OnClick = function()
				lastObject = curObject
				curObject = obj
				getList(obj)
			end;
		})
		if open then new.LayoutOrder -= 10 end
		if top then new.LayoutOrder -= 10 end

		if not (obj.Parent == game and obj.Name:sub(1, 1):upper() == obj.Name:sub(1, 1)) then
			local del = new:Add("TextButton", {
				Text = "Delete";
				Size = UDim2.new(0, 80, 1, 0);
				Visible = not isBack;
				LayoutOrder = 0;
				OnClick = function(self)
					curObject = curObject.Parent or game
					client.Remote.Send("HandleExplore", obj, "Delete")
					if pcall(function() obj:Destroy() end) then
						new.TextColor3 = Color3.fromRGB(255, 60, 60)
						new.Text ..= " [Deleted]"
						if open then
							open:Destroy()
						end
						self:Destroy()
					end
				end;
			})
		end
	end

	function getList(obj)
		local filter = search.Text
		scroller:ClearAllChildren()
		scroller:Add("UIListLayout", {SortOrder = "LayoutOrder"; FillDirection = "Vertical"; VerticalAlignment = "Top";})
		if obj == game then
			navText.Text = game.Name
			navText.Size = UDim2.new(0, 300, 0, 20)
		else
			nav.CanvasSize = UDim2.new(1, 0, 0, 20)
			navText.Size = UDim2.new(1, 0, 0, 20)
			navText.Text = game.Name.."."..obj:GetFullName()
			warn(navText.TextBounds)
			newEntry(obj.Parent or lastObject or game, "Previous Parent (Go Up..)", true, true, Color3.new(0.666667, 1, 1))
			navText.Size = UDim2.new(0, navText.TextBounds.X + 10, 0, 20)
		end
		nav.CanvasSize = navText.Size
		for i,v in ipairs(obj:GetChildren()) do
			pcall(function()
				if string.find(obj.Name:lower(), filter:lower()) or string.find(obj.ClassName:lower(), filter:lower()) then
					newEntry(v, v.Name)
				end
			end)
		end
		scroller:ResizeCanvas(false, true, false, false, 5, 5)
	end

	if window then
		nav = window:Add("ScrollingFrame", {
			ScrollBarThickness = 0;
			ScrollingDirection = "X";
			Size = UDim2.new(1, 0, 0, 20);
			Position = UDim2.new(0, 0, 0, 0);
			CanvasSize = UDim2.new(0, 0, 0, 20);
		})
		navText = nav:Add("TextLabel", {
			TextTruncate = "AtEnd";
			TextXAlignment = "Left";
			Text = game.Name;
			Size = UDim2.new(0, 0, 0, 20);
		})
		navText:Add("UIPadding", {PaddingLeft = UDim.new(0, 5);})

		scroller = window:Add("ScrollingFrame", {
			List = {};
			ScrollBarThickness = 2;
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 5, 0, 50);
			Size = UDim2.new(1, -10, 1, -50);
		})

		search = window:Add("TextBox", {
			Size = UDim2.new(1, -10, 0, 20);
			Position = UDim2.new(0, 5, 0, 25);
			BackgroundTransparency = 0.5;
			BorderSizePixel = 0;
			TextColor3 = Color3.new(1, 1, 1);
			Text = "";
			PlaceholderText = "Search";
			TextStrokeTransparency = 0.8;
		})
		search:Add("ImageLabel", {
			Image = client.MatIcons.Search;
			Position = UDim2.new(1, -21, 0, 3);
			Size = UDim2.new(0, 18, 0, 18);
			ImageTransparency = 0.2;
			BackgroundTransparency = 1;
		})

		search:GetPropertyChangedSignal("Text"):Connect(function()
			getList(curObject)
		end)

		getList(game)
		gTable = window.gTable
		window:Ready()
	end
end
