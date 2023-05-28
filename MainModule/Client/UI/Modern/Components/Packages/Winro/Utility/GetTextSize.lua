local TextService = game:GetService("TextService")

return function(String, Font, Size, LineHeight)

	local GotTextSize, TextSize = pcall(function()

		local Params = Instance.new('GetTextBoundsParams')
		Params.Text = String
		Params.Font = Font
		Params.Size = Size
		Params.Width = math.huge

		local TextSize = TextService:GetTextBoundsAsync(Params)

		-- Account for LineHeight
		if LineHeight then
			TextSize = Vector2.new(TextSize.X, TextSize.Y * LineHeight)
		end

		return TextSize
	end)
	
	if GotTextSize then
		return GotTextSize, TextSize
	else
		return GotTextSize, Vector2.new()
	end
end