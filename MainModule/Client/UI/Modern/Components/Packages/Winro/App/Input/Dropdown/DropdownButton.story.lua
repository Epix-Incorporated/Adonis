local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local DropdownRoot = script.Parent
local DropdownButton = require(DropdownRoot.DropdownButton)

local BORDER_PADDING = UDim.new(0, 8)

local DropdownButtonStory = Roact.PureComponent:extend(script.Name)

function DropdownButtonStory:render()
	local props = self.props

	return WithTheme(function(Theme)
		return new('Frame', {
			Size = UDim2.fromOffset(120, 32) + UDim2.fromOffset(BORDER_PADDING.Offset * 2, BORDER_PADDING.Offset * 2),
			BackgroundTransparency = props.BackgroundTransparency,
			BackgroundColor3 = Theme['colors/Background/Fill_Color/Solid_Background/Base'].Color,
			AutomaticSize = 'XY'
		}, {
			Padding = new('UIPadding', {
				PaddingBottom = BORDER_PADDING,
				PaddingLeft = BORDER_PADDING,
				PaddingRight = BORDER_PADDING,
				PaddingTop = BORDER_PADDING,
			}),
			Button = new(DropdownButton, {
				AnchorPoint = Vector2.new(0, 0),
				Disabled = props.Disabled,
				Position = UDim2.fromScale(0, 0),
				[Roact.Event.Activated] = print
			})
		})
	end)
end

return {
	controls = {
		Disabled = false,
	},
	stories = {
		DropdownButton = function (props)
			return new(DropdownButtonStory, Sift.Dictionary.join({
				BackgroundTransparency = 0,
			}, props.controls))
		end,
		NoBackground = function(props)
			return new(DropdownButtonStory, Sift.Dictionary.join({
				BackgroundTransparency = 1,
			}, props.controls))
		end
	}
}