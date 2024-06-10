local Components = script.Parent
local Packages = Components.Parent.Packages

local Roact = require(Packages.Roact)
local new = Roact.createElement

local Hint = require(script.Parent.Hint)
local HintStory = Roact.PureComponent:extend(script.Name)

function HintStory:render()
	local props = self.props
	local Image = props.Image and "rbxthumb://type=AvatarHeadShot&id=649787117&w=48&h=48" or nil

	if Image and not props.ThumbnailAsImage then
		Image = "rbxassetid://8303332379"
	end

	return new(Hint, {
		TitleText = props.Title and "<i>subtle</i> hint" or nil,
		BodyText = "Hints shouldnt have that much text",
		Image = Image,
	})
end

return {
	controls = {
		Title = false,
		ThumbnailAsImage = true,
		Image = true,
	},
	story = function(StoryProps)
		return new(HintStory, StoryProps.controls)
	end,
}
