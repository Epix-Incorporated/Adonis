-- ContextMenu: A Context menu element

local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme

local Validators = Winro.Validators
local StyleValidator = require(Validators.StyleValidator)

local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local ListDivider = require(Winro.App.List.ListDivider)
local ListItem = require(Winro.App.List.ListItem)

local Acrylic = require(Winro.App.Surface.Acrylic)

local CONTEXTMENU_BACKGROUND_STYLE = "colors/Background/Fill_Color/Acrylic_Background/Default"
local CONTEXTMENU_BORDER_STYLE = "colors/Stroke_Color/Surface_Stroke/Flyout"

local ContextMenu = Roact.PureComponent:extend(script.Name)

ContextMenu.defaultProps = {
	AnchorPoint = Vector2.new(), --- @defaultProp
	Position = UDim2.new(), --- @defaultProp
	Size = UDim2.fromOffset(150, 150), --- @defaultProp
	FitContents = true, --- @defaultProp
}

ContextMenu.validateProps = t.strictInterface({

	--- @prop @optional AnchorPoint Vector2 The Context Menu's anchor point
	AnchorPoint = t.optional(t.Vector2),

	--- @prop @optional BackgroundTransparency number Background Transparency
	BackgroundTransparency = t.optional(t.number),

	--- @prop @optional Position UDim2 The Context Menu's position
	Position = t.optional(t.UDim2),

	--- @prop @optional Size UDim2 The Context Menu's size
	Size = t.optional(t.UDim2),

	--- @prop @optional UseIcon boolean Determines the visibility of an icon on each option
	UseIcon = t.optional(t.boolean),

	--- @prop @optional FitContents boolean Determines if the Context Menu will resize to fit it's contents
	FitContents = t.optional(t.boolean),

	--- @prop Options array The options to display
	Options = t.array(t.strictInterface({
		Disabled = t.optional(t.boolean),
		IsDivider = t.optional(t.boolean),
		LayoutOrder = t.optional(t.numberPositive),
		OnClicked = t.optional(t.callback),
		Selected = t.optional(t.boolean),
		Text = t.optional(t.string),
		Icon = t.optional(StyleValidator)
	}))
})

function ContextMenu:init()

	-- Content size binding
	self.ContentSize, self.SetContentSize = Roact.createBinding(self.props.Size)
end

function ContextMenu:GetOptions()
	local props = self.props

	-- Create a list of all options to display
	local Children = {}

	-- Go through each option, creating it
	for LayoutOrder, OptionProps in pairs(props.Options) do

		-- Create divider, if set
		if OptionProps.IsDivider then
			Children[LayoutOrder] = new(ListDivider, {
				LayoutOrder = OptionProps.LayoutOrder or LayoutOrder,
				Size = UDim2.fromScale(1, 0)
			})

		-- Create list items
		else
			Children[LayoutOrder] = new(ListItem, {
				ShowIndicator = OptionProps.Selected,
				Disabled = OptionProps.Disabled,
				LayoutOrder = OptionProps.LayoutOrder or LayoutOrder,
				[Roact.Event.Activated] = OptionProps.OnClicked,
				Selected = OptionProps.Selected,
				Width = UDim.new(1, 0),
				Text = OptionProps.Text,
				Icon = props.UseIcon and (OptionProps.Icon or {
					Image = '',
					ImageRectSize = Vector2.new(),
					ImageRectOffset = Vector2.new()
				}) or nil
			})
		end
	end

	return Roact.createFragment(Children)
end

function ContextMenu:render()
	local props = self.props

	return WithTheme(function(Theme)

		-- Create a list items container
		local Container = new('Frame', {
			AutomaticSize = props.FitContents and 'Y' or 'None',
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 2),
			Size = UDim2.fromScale(1, props.FitContents and 0 or 1),

			[Roact.Change.AbsoluteSize] = function(rbx)
				if props.FitContents then
					self.SetContentSize(UDim2.fromOffset(rbx.AbsoluteSize.X, rbx.AbsoluteSize.Y + 2 * 2)) -- Accont for Vertical padding
				end
			end
		}, {

			Layout = new('UIListLayout', {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Bottom
			}),

			Contents = self:GetOptions()
		})

		local BaseStyle = Theme[CONTEXTMENU_BACKGROUND_STYLE]
		local StrokeStyle = Theme[CONTEXTMENU_BORDER_STYLE]

		local Base = new(Acrylic, {
			BackgroundColor3 = BaseStyle.Color,
			BackgroundTransparency = props.BackgroundTransparency or BaseStyle.Transparency,
			BorderSizePixel = 0,
			Size = self.ContentSize,
		}, {

			Corners = new('UICorner', {
				CornerRadius = UDim.new(0, Theme['styles/CornerRadius/Default/Outer'] - 1), -- -1px to account for stroke
			}),

			Stroke = new('UIStroke', {
				Color = StrokeStyle.Color,
				Transparency = StrokeStyle.Transparency,
				Thickness = 1
			}),
		})

		return new('Frame', {
			AutomaticSize = props.FitContents and 'Y' or 'None',
			AnchorPoint = props.AnchorPoint,
			BackgroundTransparency = 1,
			Position = props.Position,
			Size = self.ContentSize
		}, {
			Container = Container,
			Base = Base,
		})
	end)
end

return ContextMenu