client = nil
service = nil

return function(data)
	local gTable
	local getList
	local newEntry
	local lastObject = game
	local curObject = game
	local scroller, search

	local window = client.UI.Make("Window",{
		Name  = "Explorer";
		Title = "Game Explorer";
		Size  = {400, 300};
		MinSize = {150, 100};
		AllowMultiple = false;
		OnRefresh = function()
			getList(curObject)
		end
	})

	function newEntry(obj, name, numPos, isBack)
		local new = scroller:Add("TextLabel", {
			Text = "  "..tostring(name);
			ToolTip = ("Class: %s | Children: %d | Descendants: %d"):format(obj.ClassName, #obj:GetChildren(), #obj:GetDescendants());
			TextXAlignment = "Left";
			Size = UDim2.new(1, 0, 0, 26);
			Position = UDim2.new(0, 0, 0, 26*numPos);
		})
		
		local open = new:Add("TextButton", {
			Text = "Open";
			Size = UDim2.new(0, 80, 1, 0);
			Position = UDim2.new(1, -80, 0, 0);
			OnClick = function()
				lastObject = curObject
				curObject = obj
				getList(obj)
			end;
		})

		if not (obj.Parent == game and obj.Name:sub(1,1):upper() == obj.Name:sub(1,1)) then
			local del = new:Add("TextButton",{
				Text = "Delete";
				Size = UDim2.new(0, 80, 1, 0);
				Position = UDim2.new(1, -160, 0, 0);
				Visible = not isBack;
				OnClick = function(self)
					curObject = curObject.Parent or game
					client.Remote.Send("HandleExplore", obj, "Delete")
					if pcall(function() obj:Destroy() end) then
						new.TextColor3 = Color3.fromRGB(255, 48, 48)
						new.Text = new.Text.." [Deleted]"
						open:Destroy()
						self:Destroy()
					end
				end;
			})
		end
	end

	function getList(obj)
		local filter = search.Text
		local num = 1
		scroller:ClearAllChildren()
		newEntry(obj.Parent or lastObject or game, "Previous Parent (Go Up..)", 0, true)
		for i,v in next,obj:GetChildren() do
			pcall(function()
				if (v.Name:sub(1, #filter):lower() == filter:lower() or (v.ClassName:sub(1, #filter):lower() == filter:lower())) then
					newEntry(v, v.Name, num)
					num =  num+1
				end
			end)
		end
		scroller:ResizeCanvas(false, true, false, false, 5, 5)
	end

	if window then
		scroller = window:Add("ScrollingFrame",{
			List = {};
			ScrollBarThickness = 2;
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 5, 0, 30);
			Size = UDim2.new(1,-10,1,-30);
		})	

		search = window:Add("TextBox", {
			Size = UDim2.new(1, -10, 0, 20);
			Position = UDim2.new(0, 5, 0, 5);
			BackgroundTransparency = 0.5;
			BorderSizePixel = 0;
			TextColor3 = Color3.new(1, 1, 1);
			Text = "";
			PlaceholderText = "Search";
			TextStrokeTransparency = 0.8;
		})

		search.FocusLost:Connect(function(enter)
			getList(curObject, search.Text)
		end)

		getList(game)
		gTable = window.gTable
		window:Ready()
	end
end
