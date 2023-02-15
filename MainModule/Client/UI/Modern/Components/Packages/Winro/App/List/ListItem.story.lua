local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme

local FrameVisualizer = require(Winro.Utility.FrameVisualizer)

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local ListRoot = script.Parent
local ListItem = require(ListRoot.ListItem)

local BORDER_PADDING = UDim.new(0, 8)

local ListItemStory = Roact.PureComponent:extend(script.Name)

function ListItemStory:render()
	local props = self.props

	return WithTheme(function(Theme)
		local Element = new('Frame', {
			BackgroundTransparency = props.BackgroundTransparency,
			BackgroundColor3 = Theme['colors/Background/Fill_Color/Solid_Background/Base'].Color,
			AutomaticSize = 'XY',
			Size = UDim2.fromOffset(160+16, 40+16)
		}, {
			Padding = new('UIPadding', {
				PaddingBottom = BORDER_PADDING,
				PaddingLeft = BORDER_PADDING,
				PaddingRight = BORDER_PADDING,
				PaddingTop = BORDER_PADDING,
			}),
			ListItem = new(ListItem, {
				Icon = props.Icon and 'images/roblox/icons/logo/studiologo_small/1x' or nil,
				AnchorPoint = Vector2.new(0, 0),
				Disabled = props.Disabled,
				Position = UDim2.fromScale(0, 0),
				Selected = self.state.Selected,
				[Roact.Event.Activated] = function(...)
					print(...)
					self:setState({
						Selected = not self.state.Selected
					})
				end
			})
		})

		if props.FrameVisualizer then
			return new(FrameVisualizer, {}, Element)
		else
			return Element
		end
	end)
end

return {
	controls = {
		Disabled = false,
		FrameVisualizer = false,
		Icon = true,
	},
	stories = {
		Button = function (props)
			return Roact.createFragment({
				OnBackground = new(ListItemStory, Sift.Dictionary.join({
					BackgroundTransparency = 0,
				}, props.controls)),
				NoBackground = new(ListItemStory, Sift.Dictionary.join({
					BackgroundTransparency = 1,
				}, props.controls))
			})
		end
	}
}