-- ListItem: A list item
-- Assets/Lists & Collections/Lists & Collections/List View/List Item

local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme
local ApplyDescription = Theme.ApplyDescription
local RegisterStateAction = Theme.RegisterStateAction

local Validators = Winro.Validators
local StyleValidator = require(Validators.StyleValidator)

local Flipper = require(Packages.Flipper)
local Sift = require(Packages.Sift)
local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local ListRoot = script.Parent
local Descriptions = require(ListRoot.Descriptions.ListItemDescriptions)

local LISTITEM_COLOR_ANIMATION_SPRING_SETTINGS = "styles/AnimationSpringParams/Control/List/ListItem/Color"
local LISTITEM_TRANSPARENCY_ANIMATION_SPRING_SETTINGS = "styles/AnimationSpringParams/Control/List/ListItem/Transparency"
local LISTITEM_INDICATOR_SIZE_ANIMATION_SPRING_SETTINGS = "styles/AnimationSpringParams/Control/List/ListItem/Indicator"

local ListItem = Roact.PureComponent:extend(script.Name)

ListItem.StyleBindings = {
	'Fill',
	'Indicator',
	'Stroke',
	'Text',
}

ListItem.defaultProps = {
	Width = UDim.new(0, 160), --- @defaultProp
	Height = UDim.new(0, 40), --- @defaultProp
	ShowIndicator = true, --- @defaultProp
	Font = "fonts/Body", --- @defaultProp
}

ListItem.validateProps = t.strictInterface({

	--- @prop @optional Selected boolean The ListItem's selected state
	Selected = t.optional(t.boolean),

	--- @prop @optional Size UDim2 The ListItem's size
	Size = t.optional(t.UDim2),

	--- @prop @optional ShowIndicator boolean Determines indicator visability
	ShowIndicator = t.optional(t.boolean),

	--- @prop @optional @style Font string|table The label's font style
	Font = t.optional(StyleValidator),

	--- @prop @optional AnchorPoint Vector2 The ListItem's anchor point
	AnchorPoint = t.optional(t.Vector2),

	--- @prop @optional Disabled boolean Determines if the item is shown as disabled
	Disabled = t.optional(t.boolean),

	--- @prop @optional LayoutOrder number The ListItem's layout order
	LayoutOrder = t.optional(t.number),

	--- @prop @optional Position UDim2 The ListItem's position
	Position = t.optional(t.UDim2),

	--- @prop @optional Width UDim The ListItem's Width @depricated Use Size instead
	Width = t.optional(t.UDim),

	--- @prop @optional Height UDim The ListItem's Height @depricated Use Size instead
	Height = t.optional(t.UDim),

	--- @prop @optional Text string The ListItem's text
	Text = t.optional(t.string),

	--- @prop @optional @style Icon string|table The ListItem's icon
	Icon = t.optional(StyleValidator),

	--- @prop @optional Native table The native props
	Native = t.optional(t.table),

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

function ListItem:init()
	
	-- Indicator size binding
	self.IndicatorHeight, self.SetIndicatorHeight = Roact.createBinding(0)

	-- Create Style Bindings
	for _, StyleBinding in pairs(self.StyleBindings) do
		self[StyleBinding], self['Set' .. StyleBinding] = Roact.createBinding({})
	end

	-- Actions
	RegisterStateAction(self, Roact.Event.Activated, nil)
	RegisterStateAction(self, Roact.Event.MouseButton1Down, 'Pressed')
	RegisterStateAction(self, Roact.Event.MouseButton1Up, 'Hover')
	RegisterStateAction(self, Roact.Event.MouseEnter, 'Hover')
	RegisterStateAction(self, Roact.Event.MouseLeave, 'Rest')

	-- Initial State
	self:setState({
		State = 'Rest'
	})
end

function ListItem:willUnmount()
	
	-- Clear motors for each style binding
	for _, StyleBinding in pairs(self.StyleBindings) do

		-- Look for a motor
		local Motor = self[StyleBinding .. 'Motor']

		-- Remove motor if found
		if Motor then
			pcall(Motor.Destroy, Motor)
			self[StyleBinding .. 'Motor'] = nil
		end
	end
end

function ListItem:ApplyDescription(Description, Theme)
	local props = self.props
	Description = Sift.Dictionary.copy(Description)
	
	-- Prop Overrides
	local FillOverride = props.BackgroundColor
	local TextOverride = props.TextColor

	if FillOverride then
		Description.Fill = FillOverride
	end

	if TextOverride then
		Description.Text = TextOverride
	end

	-- Set Indicator Size
	local InitialIndicatorHeight = self.IndicatorHeight:getValue()
	
	-- Animate
	if InitialIndicatorHeight then

		-- Remove exiting motor
		local Existing = self.IndicatorHeightMotor

		if Existing then
			pcall(Existing.destroy, Existing)
		end

		-- Create a new motor
		local Motor = Flipper.SingleMotor.new(InitialIndicatorHeight)
		self.IndicatorHeightMotor = Motor

		-- Bind
		Motor:onStep(self.SetIndicatorHeight)
		Motor:onComplete(function()
			Motor:destroy()
			self.IndicatorHeightMotor = nil
		end)

		-- Animate
		Motor:setGoal(Flipper.Spring.new(Description.IndicatorHeight,
			Theme[LISTITEM_INDICATOR_SIZE_ANIMATION_SPRING_SETTINGS])
		)
	else
		self.SetIndicatorHeight(Description.IndicatorHeight)
	end

	ApplyDescription(self, Description, Theme, LISTITEM_COLOR_ANIMATION_SPRING_SETTINGS, LISTITEM_TRANSPARENCY_ANIMATION_SPRING_SETTINGS)
end

function ListItem:render()
	local props = self.props
	local state = self.state

	return WithTheme(function(Theme)

		-- Apply Description
		if not props.Selected then
			if props.Disabled then
				self:ApplyDescription(Descriptions.NoFill.Disabled, Theme)
			elseif state.State == 'Rest' then
				self:ApplyDescription(Descriptions.NoFill.Rest, Theme)
			elseif state.State == 'Hover' then
				self:ApplyDescription(Descriptions.NoFill.Hover, Theme)
			else
				self:ApplyDescription(Descriptions.NoFill.Pressed, Theme)
			end
		else
			if props.Disabled then
				self:ApplyDescription(Descriptions.Fill.Disabled, Theme)
			elseif state.State == 'Rest' then
				self:ApplyDescription(Descriptions.Fill.Rest, Theme)
			elseif state.State == 'Hover' then
				self:ApplyDescription(Descriptions.Fill.Hover, Theme)
			else
				self:ApplyDescription(Descriptions.Fill.Pressed, Theme)
			end
		end

		-- ///////// ListItem Label

		local LabelFontStyle = Theme[props.Font]

		local Label = new('TextLabel', {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			FontFace = LabelFontStyle.Font,
			Position = UDim2.new(0, 16 + (props.Icon and 28 or 0), 0.5, 0),
			Size = UDim2.new(0, 10, 1, 0),
			Text = props.Text,
			TextSize = LabelFontStyle.Size,
			TextXAlignment = 'Left',

			TextColor3 = self.Text:map(function(Style)
				return Style.Color
			end),
			TextTransparency = self.Text:map(function(Style)
				return Style.Transparency
			end),
		})

		-- ////////// ListItem Indicator

		local Indicator = new('Frame', {
			Visible = props.ShowIndicator,
			AnchorPoint = Vector2.new(0, 0.5),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 5, 0.5, 0),

			BackgroundColor3 = self.Indicator:map(function(Style)
				return Style.Color
			end),
			BackgroundTransparency = self.Indicator:map(function(Style)
				return Style.Transparency
			end),
			Size = self.IndicatorHeight:map(function(Height)
				return UDim2.fromOffset(3, Height)
			end),
		}, {

			Corners = new('UICorner', {
				CornerRadius = UDim.new(1, 0)
			}),
		})

		-- ////////// ListItem Base

		local Base = new('ImageButton', {
			AnchorPoint = Vector2.new(0, 0.5),
			AutoButtonColor = false,
			Size = UDim2.new(1, -(4 * 2), 1, -(2 * 2)) - UDim2.fromOffset(2, 2), -- Account for stroke thickness
			Position = UDim2.new(0, 4, 0.5, 0) + UDim2.fromOffset(1, 0), -- Accont for stroke thickness

			BackgroundColor3 = self.Fill:map(function(Style)
				return Style.Color
			end),
			BackgroundTransparency = self.Fill:map(function(Style)
				return Style.Transparency
			end),

			[Roact.Event.Activated] = self[Roact.Event.Activated],
			[Roact.Event.MouseButton1Down] = self[Roact.Event.MouseButton1Down],
			[Roact.Event.MouseButton1Up] = self[Roact.Event.MouseButton1Up],
			[Roact.Event.MouseEnter] = self[Roact.Event.MouseEnter],
			[Roact.Event.MouseLeave] = self[Roact.Event.MouseLeave],
		}, {

			Corners = new('UICorner', {
				CornerRadius = UDim.new(0, Theme['styles/CornerRadius/Default/Inner'] - 1) -- Account for 1px added by stroke
			}),
			Stroke = new('UIStroke', {
				Thickness = 1,
				Color = self.Stroke:map(function(Style)
					return Style.Color
				end),
				Transparency = self.Stroke:map(function(Style)
					return Style.Transparency
				end)
			})
		})
		
		-- ////////// ListItem Icon

		local IconImage = props.Icon and Theme[props.Icon]
		local IconImageSize = nil

		if IconImage then
			local IconImageRectSize = IconImage.ImageRectSize == Vector2.new() and Vector2.new(16, 16) or IconImage.ImageRectSize
			IconImageSize = UDim2.fromOffset(
				math.clamp(IconImageRectSize.X, 0, 9*4),
				math.clamp(IconImageRectSize.Y, 0, 9*4)
			)
		else
			IconImageSize = UDim2.fromOffset(16, 16)
		end
		
		local IconImage = IconImage and new('ImageLabel', {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = IconImage.Image,
			ImageRectOffset = IconImage.ImageRectOffset,
			ImageRectSize = IconImage.ImageRectSize,
			Position = UDim2.fromScale(0.5, 0.5),
			ResampleMode = IconImage.ResampleMode,
			Size = IconImageSize,

			ImageColor3 = self.Text:map(function(Style)
				return Style.Color
			end),
			ImageTransparency = self.Text:map(function(Style)
				return Style.Transparency
			end),
		})

		local Icon = new('Frame', {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 16 + 8, 0.5, 0),
			Size = UDim2.new(0, 0, 1, 0),
		}, IconImage)

		return new('Frame', Sift.Dictionary.join({
			AnchorPoint = props.AnchorPoint,
			BackgroundTransparency = 1,
			Position = props.Position,
			Size = props.Size or UDim2.new(props.Width.Scale, props.Width.Offset, props.Height.Scale, props.Height.Offset),
			LayoutOrder = props.LayoutOrder
		}), {
			Text = Label,
			Indicator = Indicator,
			Base = Base,
			Icon = Icon
		})
	end)
end

return ListItem