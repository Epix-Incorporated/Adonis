local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local HyperlinkButton = require(script.Parent.HyperlinkButton)
local HyperlinkButtonStory = Roact.PureComponent:extend(script.Name)

function HyperlinkButtonStory:render()
	local props = self.props

	return new(HyperlinkButton, Sift.Dictionary.join({
		Disabled = props.Disabled,
		Text = 'Hyperlink Story'
	}, props.Props))
end

return {
	controls = {
		Disabled = false,
	},
	stories = {
		HyperlinkButton = function(props)
			return new(HyperlinkButtonStory, props.controls)
		end
	}
}