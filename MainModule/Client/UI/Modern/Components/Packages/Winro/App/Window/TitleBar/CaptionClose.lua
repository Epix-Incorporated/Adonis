-- CaptionClose: The TitleBar close button

local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme
local RegisterStateAction = Theme.RegisterStateAction

local Validators = Winro.Validators
local StyleValidator = require(Validators.StyleValidator)

local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local RoundedSurface = require(Winro.App.Surface.RoundedSurface)

local CAPTIONCLOSE_TEXT_REST = 'colors/Fill_Color/Text/Primary'
local CAPTIONCLOSE_TEXT_PRIMARY = 'colors/Shell/Fill_Color/Caption_Close_Text/Primary'
local CAPTIONCLOSE_TEXT_SECONDARY = 'colors/Shell/Fill_Color/Caption_Close_Text/Secondary'
local CAPTIONCLOSE_FILL_REST = 'colors/Fill_Color/Subtle/Transparent'
local CAPTIONCLOSE_FILL_PRIMARY = 'colors/Shell/Fill_Color/Caption_Control_Close_Fill/Primary'
local CAPTIONCLOSE_FILL_SECONDARY = 'colors/Shell/Fill_Color/Caption_Control_Close_Fill/Secondary'
local CAPTIONCLOSE_ICON = 'images/roblox/icons/navigation/close/1x'

local CaptionClose = Roact.PureComponent:extend(script.Name)

CaptionClose.defaultProps = {
	Width = 48, --- @defaultProp
}

CaptionClose.validateProps = t.strictInterface({

	--- @prop @optional @style TextColor string|table X icon color
	TextColor = t.optional(StyleValidator),

	--- @prop @optional AlwaysShow boolean Determines if the caption close button is always shown
	AlwaysShow = t.optional(t.boolean),

	--- @prop @optional Width number positive The Button's width in pixels
	Width = t.optional(t.numberPositive),

	--- @prop @optional [Roact.Event.Activated] function Roact.Event.Activated
	[Roact.Event.Activated] = t.optional(t.callback),

	--- @prop @optional [Roact.Event.MouseButton1Down] function Roact.Event.MouseButton1Down
	[Roact.Event.MouseButton1Down] = t.optional(t.callback),

	--- @prop @optional [Roact.Event.MouseButton1Up] function Roact.Event.MouseButton1Up
	[Roact.Event.MouseButton1Up] = t.optional(t.callback),

	--- @prop @optional [Roact.Event.MouseEnter] function Roact.Event.MouseEnter
	[Roact.Event.MouseEnter] = t.optional(t.callback),

	--- @prop @optional [Roact.Event.MouseLeave] function Roact.Event.MouseLeave
	[Roact.Event.MouseLeave] = t.optional(t.callback),
})

function CaptionClose:init()
	
	-- Actions
	RegisterStateAction(self, Roact.Event.Activated, nil)
	RegisterStateAction(self, Roact.Event.MouseButton1Down, 'Pressed')
	RegisterStateAction(self, Roact.Event.MouseButton1Up, 'Hover')
	RegisterStateAction(self, Roact.Event.MouseEnter, 'Hover')
	RegisterStateAction(self, Roact.Event.MouseLeave, 'Rest')

	-- Initial state
	self:setState({
		State = 'Rest'
	})
end

function CaptionClose:render()
	local props = self.props
	local state = self.state

	return WithTheme(function(Theme)
		
		-- ////////// Button

		local FillStyle = nil
		local TextStyle = nil

		if state.State == 'Rest' then
			
			if props.AlwaysShow then
				TextStyle = Theme[CAPTIONCLOSE_TEXT_PRIMARY]
				FillStyle = Theme[CAPTIONCLOSE_FILL_PRIMARY]

			else
				TextStyle = Theme[props.TextColor or CAPTIONCLOSE_TEXT_REST]
				FillStyle = Theme[CAPTIONCLOSE_FILL_REST]
			end

		elseif state.State == 'Hover' then
			TextStyle = Theme[CAPTIONCLOSE_TEXT_PRIMARY]
			FillStyle = Theme[CAPTIONCLOSE_FILL_PRIMARY]

		else
			TextStyle = Theme[CAPTIONCLOSE_TEXT_SECONDARY]
			FillStyle = Theme[CAPTIONCLOSE_FILL_SECONDARY]
		end
		
		return new(RoundedSurface, {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor = FillStyle,
			CornerRadius = UDim.new(0, Theme['styles/CornerRadius/Default/Outer']),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(0, props.Width, 1, 0),
			ShowTopRightCorner = true,
		}, {
			Button = new('ImageButton', {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),

				[Roact.Event.Activated] = self[Roact.Event.Activated],
				[Roact.Event.MouseButton1Down] = self[Roact.Event.MouseButton1Down],
				[Roact.Event.MouseButton1Up] = self[Roact.Event.MouseButton1Up],
				[Roact.Event.MouseEnter] = self[Roact.Event.MouseEnter],
				[Roact.Event.MouseLeave] = self[Roact.Event.MouseLeave],
			}),
			Icon = new('ImageLabel', {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(18, 18),
				ImageColor3 = TextStyle.Color,
				ImageTransparency = TextStyle.Transparency,
				Image = Theme[CAPTIONCLOSE_ICON].Image,
				ImageRectSize = Theme[CAPTIONCLOSE_ICON].ImageRectSize,
				ImageRectOffset = Theme[CAPTIONCLOSE_ICON].ImageRectOffset,
				ScaleType = Enum.ScaleType.Fit,
				--ResampleMode = Enum.ResamplerMode.Pixelated,
			})
		})
	end)
end

return CaptionClose