
client = nil
service = nil

return function(data)
	local Title = data.Title
	local Tab = data.Table or data.Tab
	local Update = data.Update
	local UpdateArg = data.UpdateArg
	local UpdateArgs = data.UpdateArgs
	local AutoUpdate = data.AutoUpdate
	local LoadTime = data.LoadTime
	local gIndex = data.gIndex
	local gTable = data.gTable
	local Dots = data.Dots
	local Size = data.Size
	local Sanitize = data.Sanitize
	local Stacking = data.Stacking
	local getListTab
	local doSearch, genList
	local window, scroller, search
	
	function getListTab(Tab)
		local newTab = {}
		
		for i,v in next,Tab do
			if type(v) == "table" then
				newTab[i] = {
					Text = v.Text;
					Desc = v.Desc;
					Time = v.Time;
					Filter = v.Filter;
					Duplicates = v.Duplicates;
				}
			elseif type(v) == "string" then
				newTab[i] = {
					Text = v;
					Desc = v;
				}
			end
		end
		
		if Stacking then
			local oldNewTab = newTab;
			newTab = {}
			local lastTab
			for ind,ent in next,oldNewTab do
				ent.Text = service.Trim(ent.Text)
				ent.Desc = service.Trim(ent.Desc)
				if not lastTab then
					lastTab = ent
					table.insert(newTab, ent)
				else
					if lastTab.Text == ent.Text and lastTab.Desc == ent.Desc then
						lastTab.Duplicates = (lastTab.Duplicates and lastTab.Duplicates+1) or 2
					else
						lastTab = ent
						table.insert(newTab, ent)
					end
				end
			end
		end
		
		for i,v in next,newTab do
			v.Text = (data.Sanitize and service.SanitizeString(v.Text)) or v.Text
			
			if v.Duplicates then
				v.Text = "(x"..v.Duplicates..") "..v.Text
			end
			
			if v.Time then 
				v.Text = "["..v.Time.."] "..v.Text
			end
		end
		
		return newTab
	end
	
	function doSearch(tab, text)
		local found = {}
		text = text:lower()
		for i,v in next,tab do
			if text == "" or (type(v) == "string" and v:lower():find(text)) or (type(v) == "table" and ((v.Text and v.Text:lower():find(text)) or (v.Filter and v.Filter:lower():find(text)))) then
				table.insert(found, v)
			end
		end
		
		return found
	end
	
	function genList(Tab)
		if search.Text ~= "Search" and search.Text ~= "" then
			scroller:GenerateList(getListTab(doSearch(Tab, search.Text)))
		else
			search.Text = "Search"
			scroller:GenerateList(getListTab(Tab))
		end
	end
	
	window = client.UI.Make("Window",{
		Name  = "List";
		Title = Title;
		Size  = Size or {225, 200};
		MinSize = {150, 100};
		OnRefresh = Update and function()
			Tab = client.Remote.Get("UpdateList", Update, unpack(UpdateArgs or {UpdateArg}))
			if Tab then
				genList(Tab)
			end
		end
	})
	
	scroller = window:Add("ScrollingFrame",{
		List = {};
		ScrollBarThickness = 2;
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 5, 0, 30);
		Size = UDim2.new(1,-10,1,-30);
		--LabelProps = {
		--	TextXAlignment = "Left";
		--}
	})	
	
	search = window:Add("TextBox", {
		Size = UDim2.new(1, -10, 0, 20);
		Position = UDim2.new(0, 5, 0, 5);
		BackgroundTransparency = 0.5;
		BorderSizePixel = 0;
		TextColor3 = Color3.new(1, 1, 1);
		Text = "Search";
		PlaceholderText = "Search";
		TextStrokeTransparency = 0.8;
	})
	
	search.FocusLost:connect(function(enter)
		genList(Tab)
	end)
	
	--window:SetPosition(UDim2.new(0.25, 0, 0.5, -window.AbsoluteSize.Y/2))
	gTable = window.gTable
	window:Ready()
	genList(Tab)
	
	if Update and AutoUpdate then
		while gTable.Active and wait(AutoUpdate) do
			window:Refresh()
		end
	end
end