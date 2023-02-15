local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local FrameVisualizer = require(Winro.Utility.FrameVisualizer)
local ContextMenu = require(script.Parent.ContextMenu)

local ContextMenuStory = Roact.PureComponent:extend(script.Name)

function ContextMenuStory:render()
	local Element = new(ContextMenu, Sift.Dictionary.join({
		Size = UDim2.new(0, 200, 0, 0),
		FitContents = true,
		UseIcon = self.props.Icon,
		Options = {
			{
				Selected = true,
				Text = 'Selected',
				Icon = 'images/roblox/icons/actions/randomize/1x',
				OnClicked = print
			},
			{
				Selected = false,
				Text = 'Deselected',
				Icon = 'images/roblox/icons/controls/keys/command/1x',
				OnClicked = print
			},
			{ IsDivider = true },
			{
				Disabled = true,
				Text = 'Disabled',
				Icon = 'images/roblox/icons/controls/keys/alt/1x',
				OnClicked = print
			},
			{
				Selected = true,
				Disabled = true,
				Text = 'DisabledSelected',
				Icon = 'images/roblox/icons/graphic/blocktheft_2xl/1x',
				OnClicked = print
			},
			{
				Selected = false,
				Text = 'No icon',
				OnClicked = print
			},
			{ IsDivider = true },
			{
				Selected = true,
				Text = 'No icon selected',
				OnClicked = print
			},
		}
	}, self.props.Props))

	if self.props.Wireframe then
		return new(FrameVisualizer, {}, Element)
	else
		return Element
	end
end

return {
	controls = {
		Wireframe = false,
		Icon = true,
	},
	stories = {
		ContextMenu = function (props)
			return new(ContextMenuStory, props.controls)
		end
	}
}