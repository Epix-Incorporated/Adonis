-- TitleBar: The top bar of a window component

local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local FrameVisualizer = require(Winro.Utility.FrameVisualizer)

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local TitleBar = require(script.Parent.TitleBar)

local TitleBarStory = Roact.PureComponent:extend(script.Name)

function TitleBarStory:render()
	
	local TitleBar = new(TitleBar, Sift.Dictionary.join({
		Icon = self.props.Icon and 'images/roblox/icons/logo/studiologo_small/1x' or nil,
		ReleaseText = 'Story',
		AlwaysShowClose = self.props.AlwaysShowClose,
		BackgroundColor = 'colors/Background/Fill_Color/Solid_Background/Base',
		Height = self.props.Size == 'Standard' and 32 or self.props.Size == 'Large' and 48 or 29,
		OnClose = print,
		CaptionButtonWidth = self.props.Size == 'Small' and 29 or 32
	}, self.props.Props))

	if self.props.Wireframe then
		return new(FrameVisualizer, {
			Size = UDim2.new(1, 0, 1, 0),
		}, TitleBar)
	else
		return TitleBar
	end
end

return {
	controls = {
		AlwaysShowClose = false,
		Wireframe = false,
		Icon = false,
		Size = {'Standard', 'Large', 'Small'},
	},
	stories = {
		TitleBar = function(props)
			return new(TitleBarStory, props.controls)
		end
	}
}