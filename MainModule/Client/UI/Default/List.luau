client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end

	local Name = data.Name
	local Title = data.Title
	local TitleButtons = data.TitleButtons or {}
	local Icon = data.Icon
	local Tabs = data.Tabs
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
	local PagesEnabled = (data.PagesEnabled ~= nil and data.PagesEnabled) or (data.PagesEnabled == nil and true)
	local PageSize = data.PageSize or 100
	local PageNumber = data.PageNumber or 1
	local PageCounter = PageNumber or 1
	local RichText = data.RichTextSupported or data.RichTextAllowed or data.RichText
	local TextSelectable = data.TextSelectable
	local TimeOptions = data.TimeOptions
	local getListTab, getPage
	local doSearch, genList
	local window, scroller, search
	local lastPageButton, nextPageButton, pageCounterLabel;
	local currentListTab
	local pageDebounce
	local genDebounce = false

	function getPage(tab, pageNum)
		if not PagesEnabled then
			return tab
		end

		local pageNum = pageNum or 1
		local startPos = (pageNum-1) * PageSize
		local endPos = pageNum *PageSize
		local pageList = {}

		for i = startPos, endPos do
			if tab[i] ~= nil then
				table.insert(pageList, tab[i])
			end
		end

		return pageList
	end

	function getListTab(Tab)
		local newTab = {}

		for i, v in ipairs(Tab) do
			if type(v) == "table" then
				newTab[i] = {
					Text = v.Text;
					Desc = v.Desc;
					Color = v.Color;
					Time = v.Time;
					Filter = v.Filter;
					Duplicates = v.Duplicates;
					OnClick = v.OnClick;
				}
			elseif type(v) == "string" then
				newTab[i] = {
					Text = v;
					Desc = v;
				}
			end
		end

		if Stacking then
			local oldNewTab = newTab
			newTab = {}
			local lastTab
			for _, ent in ipairs(oldNewTab) do
				ent.Text = service.EscapeControlCharacters(service.Trim(ent.Text))
				ent.Desc = service.EscapeControlCharacters(service.Trim(ent.Desc))
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

		for _, v in ipairs(newTab) do
			v.Text = (data.Sanitize and service.SanitizeString(v.Text)) or v.Text

			if v.Duplicates then
				v.Text = `(x{v.Duplicates}) {v.Text}`
			end

			if v.Time then
				v.Text = `[{type(v.Time) == "number" and service.FormatTime(v.Time, TimeOptions) or v.Time}] {v.Text}`
			end
		end

		return newTab
	end

	function doSearch(tab, query)
		if query == "" then
			return tab
		end
	
		local priorities = {{}, {}, {}, {}, {}, {}}
		local total = 0
		query = string.lower(query)
	
		for _, v in ipairs(tab) do
			local isTable = type(v) == "table"
			local text = (isTable and v.Text) and string.lower(v.Text) or string.lower(tostring(v))
			local desc = (isTable and v.Desc) and string.lower(v.Desc)
			local filter = (isTable and v.Filter) and string.lower(v.Filter)
	
			if text == search then
				total += 1
				table.insert(priorities[1], v)
			elseif string.find(text, query, 1, true) then
				total += 1
				table.insert(priorities[2], v)
			elseif desc == search then
				total += 1
				table.insert(priorities[3], v)
			elseif desc and string.find(desc, query, 1, true) then
				total += 1
				table.insert(priorities[4], v)
			elseif filter == search then
				total += 1
				table.insert(priorities[5], v)
			elseif filter and string.find(filter, query, 1, true) then
				total += 1
				table.insert(priorities[6], v)
			end
		end
	
		local found = table.create(total)
	
		for _, v in ipairs(priorities) do
			table.move(v, 1, #v, #found + 1, found)
		end
	
		return found
	end

	function genList(Tab)
		local gotList = Tab

		if not genDebounce then
			genDebounce = true

			if search.Text ~= "" then
				PageCounter = 1
				gotList = getListTab(doSearch(Tab, search.Text))
			else
				PageCounter = PageNumber
				search.Text = ""
				search.PlaceholderText = "Search (" .. (#Tab == 1 and "1 Item" or #Tab .. " Items") .. ")";
				gotList = getListTab(Tab)
			end

			if PagesEnabled and #gotList > PageSize then


				scroller.Size = UDim2.new(1, -10, 1, -60)
				nextPageButton.Visible = true
				pageCounterLabel.Visible = true
				if currentListTab then
					local maxPages = math.ceil(#currentListTab/PageSize)
					pageCounterLabel.Text = `Page: {PageCounter}/{maxPages}`
				else
					pageCounterLabel.Text = `Page: {PageCounter}`
				end

				if PageCounter > 1 then
					lastPageButton.Visible = true
				else
					lastPageButton.Visible = false
				end
			else
				scroller.Size = UDim2.new(1, -10, 1, -30)
				nextPageButton.Visible = false
				lastPageButton.Visible = false
				pageCounterLabel.Visible = false
			end

			scroller:ClearAllChildren()

			currentListTab = gotList
			scroller:GenerateList(getPage(gotList, PageCounter), {
				RichTextAllowed = RichText;
				TextSelectable = TextSelectable;
			})

			genDebounce = false
		end
	end

	window = client.UI.Make("Window", {
		Name = data.Name or "List";
		Title = Title;
		Icon = Icon;
		Size = Size or {300, 250};
		MinSize = {200, 120};
		OnRefresh = Update and function()
			Tab = client.Remote.Get("UpdateList", Update, unpack(UpdateArgs or {UpdateArg}))
			if Tab then
				currentListTab = Tab
				genList(Tab)
			end
		end;
		RichTextSupport = data.RichTextSupport or data.SupportRichText or false;
	})

	scroller = window:Add("ScrollingFrame", {
		List = {};
		ScrollBarThickness = 2;
		BackgroundTransparency = 1;
		Position = UDim2.new(0, 5, 0, 30);
		Size = UDim2.new(1,-10,1,-30); -- UDim2.new(1,-10,1,-60); when paging
		--LabelProps = {
		--	TextXAlignment = "Left";
		--}
	})

	pageCounterLabel = window:Add("TextLabel", {
		Size = UDim2.new(0, 60, 0, 20);
		Position = UDim2.new(0.5, -30, 1, -25);
		Text = "Page: 1";
		BackgroundTransparency = 1;
		TextTransparency = 0.5;
		TextWrapped = false;
		ClipsDescendants = false;
		TextXAlignment = "Center";
	})

	nextPageButton = window:Add("TextButton", {
		Size = UDim2.new(0, 50, 0, 20);
		Position = UDim2.new(1, -60, 1, -25);
		Text = ">";
		Visible = false;
		Debounce = true;
		OnClick = function()
			if not pageDebounce then
				pageDebounce = true
				local origLTrans = nextPageButton.BackgroundTransparency
				lastPageButton.BackgroundTransparency = origLTrans + 0.35

				local origNTrans = nextPageButton.BackgroundTransparency
				nextPageButton.BackgroundTransparency = origNTrans + 0.35

				lastPageButton.TextTransparency = 0.8
				nextPageButton.TextTransparency = 0.8

				if currentListTab then
					local maxPages = math.ceil(#currentListTab/PageSize);
					PageCounter = math.clamp(PageCounter+1, 1, maxPages);

					pageCounterLabel.Text = `Page: {PageCounter}/{maxPages}`

					if PageCounter > 1 then
						lastPageButton.Visible = true
					end

					if PageCounter == maxPages then
						nextPageButton.Visible = false
					end

					scroller:ClearAllChildren()

					scroller.CanvasPosition = Vector2.new(0, 0)
					scroller:GenerateList(getPage(currentListTab, PageCounter), {
						RichTextAllowed = RichText;
						TextSelectable = TextSelectable;
					})
				end

				lastPageButton.BackgroundTransparency = origLTrans
				nextPageButton.BackgroundTransparency = origNTrans

				lastPageButton.TextTransparency = 0
				nextPageButton.TextTransparency = 0

				pageDebounce = false
			end
		end
	})

	lastPageButton = window:Add("TextButton", {
		Size = UDim2.new(0, 50, 0, 20);
		Position = UDim2.new(0, 10, 1, -25);
		Text = "<";
		Visible = false;
		Debounce = true;
		OnClick = function()
			if not pageDebounce then
				pageDebounce = true
				local origLTrans = nextPageButton.BackgroundTransparency
				lastPageButton.BackgroundTransparency = origLTrans + 0.2

				local origNTrans = nextPageButton.BackgroundTransparency
				nextPageButton.BackgroundTransparency = origNTrans + 0.2

				lastPageButton.TextTransparency = 0.8
				nextPageButton.TextTransparency = 0.8

				if currentListTab then
					local maxPages = math.ceil(#currentListTab/PageSize)
					PageCounter = math.clamp(PageCounter-1, 1, maxPages)

					pageCounterLabel.Text = `Page: {PageCounter}/{maxPages}`

					if PageCounter == 1 then
						lastPageButton.Visible = false
					end

					if PageCounter == maxPages then
						nextPageButton.Visible = false
					else
						nextPageButton.Visible = true
					end

					scroller:ClearAllChildren()

					scroller.CanvasPosition = Vector2.new(0, 0)
					scroller:GenerateList(getPage(currentListTab, PageCounter), {
						RichTextAllowed = RichText;
						TextSelectable = TextSelectable;
					})
				end

				lastPageButton.BackgroundTransparency = origLTrans
				nextPageButton.BackgroundTransparency = origNTrans

				lastPageButton.TextTransparency = 0
				nextPageButton.TextTransparency = 0

				pageDebounce = false
			end
		end
	})

	for i, v in ipairs(TitleButtons) do
		window:AddTitleButton(v)
	end

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

	search:GetPropertyChangedSignal("Text"):Connect(function()
		currentListTab = Tab
		genList(Tab)
	end)

	--window:SetPosition(UDim2.new(0.25, 0, 0.5, -window.AbsoluteSize.Y/2))
	gTable = window.gTable
	window:Ready()
	currentListTab = Tab
	genList(Tab)

	if Update and AutoUpdate then
		while gTable.Active and wait(AutoUpdate) do
			window:Refresh()
		end
	end
end
