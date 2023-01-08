client = nil
service = nil

return function(data, env)
	if env then
		setfenv(1, env)
	end

	local termLines = {}
	local gTable

	local window = client.UI.Make("Window", {
		Name = "Terminal",
		Title = "Terminal",
		Icon = client.MatIcons.Code,
		Size = { 500, 300 },
		AllowMultiple = false,
		OnClose = function() end,
	})

	local scroller = window:Add("ScrollingFrame", {
		Size = UDim2.new(1, -10, 1, -40),
		BackgroundTransparency = 1,
		List = {},
	})

	local textbox = window:Add("TextBox", {
		Text = "",
		Size = UDim2.new(1, 0, 0, 30),
		Position = UDim2.new(0, 0, 1, -30),
		PlaceholderText = "Enter command",
		TextXAlignment = "Left",
		ClearTextOnFocus = false,
	})
	textbox:Add("UIPadding", { PaddingLeft = UDim.new(0, 6) })

	local function out(put, lines)
		table.insert(lines, put)
		if #lines > 500 then
			table.remove(lines, 1)
		end
	end

	window:BindEvent(service.Events.TerminalLive, function(rData)
		local data = rData.Data
		local rType = rData.Type

		out(data, termLines)
	end)

	textbox.FocusLost:Connect(function(enterPressed)
		service.Debounce("_TERMINAL_BOX_FOCUSLOST", function()
			if enterPressed and textbox.Text ~= "" and textbox.Text ~= "Enter command" then
				local com = textbox.Text
				local ret
				textbox.Text = ""
				out(">" .. com, termLines)
				ret = client.Remote.Get("Terminal", com, {
					Time = time(),
				})

				if ret and type(ret) == "table" then
					for i, ent in ipairs(ret) do
						out(ent, termLines)
					end
				end

				--scroller:GenerateList(termLines, nil, true)
				textbox:CaptureFocus()
				--textbox.Text = "Enter command"
			end

			wait(0.1)
		end)
	end)

	out(string.format("Adonis Terminal [%s]", string.match(client.Changelog[5], "%[(.+)%].+")), termLines)

	gTable = window.gTable
	window:Ready()

	local last = 0
	while gTable.Active and wait(0.5) do
		if #termLines > last then
			last = #termLines
			scroller:GenerateList(termLines, nil, true)
		end
	end
end
