local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local TextInput = require(script.Parent.TextInput)
local TextInputStory = Roact.PureComponent:extend(script.Name)

function TextInputStory:render()
	local props = self.props

	return new(TextInput, Sift.Dictionary.join({

	}, props.Props))
end

return {
	controls = {},
	stories = {
		TextInput = function(props)
			return new(TextInputStory, props.controls)
		end
	}
}