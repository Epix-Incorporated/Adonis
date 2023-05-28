-- TitleBar: The top bar of a window component

local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local FrameVisualizer = require(Winro.Utility.FrameVisualizer)

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local Dialog = require(script.Parent.Dialog)

local DialogStory = Roact.PureComponent:extend(script.Name)

function DialogStory:render()
	local props = self.props

	local Dialog = new(Dialog, Sift.Dictionary.join({
		TitleText = 'Title',
		BodyText = props.BodyText,
		
		Buttons = props.Buttons and {
			[1] = {
				Text = 'Accept',
				Style = 'Accent',
				[Roact.Event.Activated] = print,
			},
			[2] = {
				Text = 'Cancel',
				Style = 'Standard',
				[Roact.Event.Activated] = print,
			},
			[3] = {
				Disabled = true,
				Text = 'Disabled',
				Style = 'Standard',
				[Roact.Event.Activated] = print,
			},
		},
		-- ButtonStackProps = {
		-- 	StackWidth = UDim.new(0, 300),
		-- },
		TitleBarProps = {
			Icon = 'images/roblox/icons/logo/studiologo_small/1x',
			Text = 'App name',
			ReleaseText = 'Preview',
			OnClose = print,
		},
		WindowProps = {
			FooterHeight = 80,
		}
	}, self.props.Props))

	if self.props.Wireframe then
		return new(FrameVisualizer, {
			Size = UDim2.new(1, 0, 1, 0),
		}, Dialog)
	else
		return Dialog
	end
end

return {
	controls = {
		Wireframe = false,
		Buttons = true,
		BodyText = [[This is body text. Windows 11 marks a visual evolution of the operating system. We have evolved our design language alongside with Fluent to create a design which is human, universal and truly feels like Windows. 

The design principles below have guided us throughout the journey of making Windows the best-in-class implementation of Fluent.]]
	},
	stories = {
		Dialog = function(props)
			return new(DialogStory, props.controls)
		end
	}
}