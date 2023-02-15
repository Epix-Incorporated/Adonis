local Components = script.Parent
local Packages = Components.Parent.Packages

local Roact = require(Packages.Roact)
local new = Roact.createElement

local Message = require(script.Parent.Message)
local MessageStory = Roact.PureComponent:extend(script.Name)

function MessageStory:render()
	local props = self.props
	local Image = props.Image and 'rbxthumb://type=AvatarHeadShot&id=649787117&w=48&h=48' or nil

	if Image and not props.ThumbnailAsImage then
		Image = 'rbxassetid://8303332379'
	end

	return new(Message, {
		TitleText = 'Message from <b>omwot</b>',
		BodyText = 'Dont we all love text wrapping because it is so great and this text should be wrapped, if it is not wrapped then something is wrong or it is just bad design. We all know about the things that we have to do but this is just some nonsense text in order to test some stuff. Blah blah blah is all i hear right now because yes and the yeaaou aou afouwa elf oug.',
		Image = Image,
	})
end

return {
	controls = {
		ThumbnailAsImage = true,
		Image = true,
	},
	story = function(StoryProps)
		return new(MessageStory, StoryProps.controls)
	end
}