
client = nil
service = nil

return function(data)
	local window = client.UI.Make("Window",{
		Name  = "Credits";
		Title = "Credits";
		Size  = {280, 300};
		AllowMultiple = false;
	})
	local tabFrame = window:Add("TabFrame",{
		Size = UDim2.new(1, -10, 1, -10);
		Position = UDim2.new(0, 5, 0, 5);
	})


	for _, tab in ipairs({
		[1] = tabFrame:NewTab("Main", {Text = "Main"}),
		[2] = tabFrame:NewTab("GitHub", {Text = "Contributors"}),
		[3] = tabFrame:NewTab("Misc", {Text = "Everyone Else"})
		})
	do
		local scroller = tab:Add("ScrollingFrame",{
			List = {};
			ScrollBarThickness = 3;
			BackgroundTransparency = 1;
			Position = UDim2.new(0, 0, 0, 28);
			Size = UDim2.new(1, 0, 1, -28);
		})

		local search = tab:Add("TextBox", {
			Position = UDim2.new(0, 5, 0, 5);
			Size = UDim2.new(1, -10, 0, 20);
			BackgroundTransparency = 0.25;
			BorderSizePixel = 0;
			TextColor3 = Color3.new(1, 1, 1);
			Text = "";
			PlaceholderText = "Search";
			TextStrokeTransparency = 0.8;
		})

		local function generate()
			local i = 1
			local filter = search.Text
			scroller:ClearAllChildren()
			for _,credit in ipairs(require(client.Shared.Credits)[tab.Name]) do
				if (credit.Text:sub(1, #filter):lower() == filter:lower()) or (tab.Name == "GitHub" and credit.Text:sub(9, 8+#filter):lower() == filter:lower()) then
					scroller:Add("TextLabel", {
						Text = "  "..credit.Text.." ";
						ToolTip = credit.Desc;
						BackgroundTransparency = (i%2 == 0 and 0) or 0.2;
						Size = UDim2.new(1, -10, 0, 30);
						Position = UDim2.new(0, 5, 0, (30*(i-1)));
						TextXAlignment = "Left";
					})
					i += 1
				end
			end
			scroller:ResizeCanvas(false, true, false, false, 5, 5)
		end

		search.FocusLost:Connect(generate)
		generate()
	end

	window:Ready()
end
