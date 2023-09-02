-- TitleBar: The top bar of a window component

local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local FrameVisualizer = require(Winro.Utility.FrameVisualizer)

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local Flyout = require(Winro.App.Flyout.Flyout)
local Window = require(script.Parent.Window)

local WindowStory = Roact.PureComponent:extend(script.Name)

function WindowStory:render()
	local props = self.props

	local Window = new(Window, Sift.Dictionary.join({
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(400, 200),
		ContentBackgroundColor = 'colors/Background/Fill_Color/Layer/Default',
		FooterHeight = props.FooterHeight,
		TitleBarProps = {
			Icon = 'images/roblox/icons/logo/studiologo_small/1x',
			-- BackgroundColor = 'colors/Background/Fill_Color/Layer/Alt',
			Text = 'Window',
			ReleaseText = 'Story',
			OnClose = props.CanClose and print or nil,
		},
		FooterContents = {
			Label = new('TextLabel', {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = '`FooterContents` goes here',
				TextColor3 = Color3.new(1, 1, 1),
				TextStrokeTransparency = 0,
			})
		}
	}, self.props.Props), {
		Label = new('TextLabel', {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = '\n\n\n\n\n\n\n\n\n`[Roact.Children]` goes here',
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0,
			ZIndex = 2,
		}),
		Flyout = new(Flyout, {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 25),
			RichText = true,
			Text = '<b>Note:</b>\nWindow dragging will not work while inside a plugin widget window.'
		}),
	})

	if self.props.Wireframe then
		return new(FrameVisualizer, {
			Size = UDim2.new(1, 0, 1, 0),
		}, Window)
	else
		return Window
	end
end

return {
	controls = {
		Wireframe = false,
		CanClose = true,
		FooterHeight = 80,
	},
	stories = {
		Window = function(props)
			return new(WindowStory, props.controls)
		end
	}
}