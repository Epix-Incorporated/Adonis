-- Simple divider, with theme

local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local WithTheme = require(Winro.Theme).WithTheme
local Roact = require(Packages.Roact)
local new = Roact.createElement

local ListDivider = Roact.PureComponent:extend(script.Name)

function ListDivider:render()
	local props = self.props

	return WithTheme(function(Theme)
		local DividerStyle = Theme["colors/Stroke_Color/Divider_Stroke/Default"]
		return new('Frame', {
			BackgroundTransparency = 1,
			LayoutOrder = props.LayoutOrder,
			Position = props.Position,
			Size = UDim2.new(
				props.Size.X.Scale,
				props.Size.X.Offset,
				props.Size.Y.Scale,
				props.Size.Y.Offset == 0 and 4 or props.Size.Y.Offset
			),
		}, {
			Divider = new('Frame', {
				AnchorPoint = Vector2.new(0, 1),
				BorderSizePixel = 0,
				BackgroundColor3 = DividerStyle.Color,
				BackgroundTransparency = DividerStyle.Transparency,
				Position = UDim2.new(0, 1, 0.5, 0),
				Size = UDim2.new(1, -2, 0, 1)
			})
		})
	end)
end

return ListDivider