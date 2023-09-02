local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local Tooltip = require(script.Parent.Tooltip)
local TooltipStory = Roact.PureComponent:extend(script.Name)

function TooltipStory:render()
	local props = self.props

	return new(Tooltip, Sift.Dictionary.join({
		Text = props.Text .. (props.Wrapped and '\nThat is wrapped' or ''),
		Icon = props.Icon and 'images/roblox/icons/logo/studiologo_small/1x' or nil,
	}, props.Props))
end

return {
	controls = {
		Text = 'Tooltip Text',
		Icon = false,
		Wrapped = false,
	},
	stories = {
		Tooltip = function(props)
			return new(TooltipStory, props.controls)
		end,
	}
}