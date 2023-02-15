-- Window: A component that is the base structure for a UI Window

local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme

local Sift = require(Packages.Sift)
local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local HyperlinkButton = require(Winro.App.Input.Hyperlink.HyperlinkButton)
local ButtonStack = require(Winro.App.Input.Button.ButtonStack)

local WindowRoot = script.Parent
local Window = require(WindowRoot.Window)

local Dialog = Roact.PureComponent:extend(script.Name)

Dialog.defaultProps = {
	AutomaticSize = Enum.AutomaticSize.Y, --- @defaultProp
	Position = UDim2.fromScale(0.5, 0.5), --- @defaultProp
	Size = UDim2.fromOffset(540, 0), --- @defaultProp
	TitleBarProps = {}, --- @defaultProp
	WindowProps = {}, --- @defaultProp
}

Dialog.validateProps = t.strictInterface({

	--- @prop @optional AnchorPoint Vector2 The Window's anchor point
	AnchorPoint = t.optional(t.Vector2),

	--- @prop @optional AutomaticSize Enum.AutomaticSize Auto sizing
	AutomaticSize = t.optional(t.EnumItem),

	--- @prop @optional Butttons table The buttons to be displayed
	Buttons = t.optional(t.table),

	--- @prop @optional Position UDim2 The Window's position
	Position = t.optional(t.UDim2),

	--- @prop @optional RichText boolean Body text Rich Text
	RichText = t.optional(t.boolean),

	--- @prop @optional Size UDim2 The Window's size
	Size = t.optional(t.UDim2),

	--- @prop @optional DetailTitle string The detail section's tile text
	DetailTitle = t.optional(t.string),

	--- @prop @optional DetailBody string The detail section's body text
	DetailBody = t.optional(t.string),

	--- @prop @optional DetailContents table The contents to display in the detail section
	DetailContents = t.optional(t.table),

	--- @prop @optional BodyText string Body text
	BodyText = t.optional(t.string),

	--- @prop @optional TitleText string Title text
	TitleText = t.optional(t.string),

	--- @prop @optional TitleBarProps table The props to be provided to the Title Bar
	TitleBarProps = t.optional(t.table),

	--- @prop @optional WindowProps table The props to be provided to the Window
	WindowProps = t.optional(t.table),

	--- @prop @optional [Roact.Children] table The contents to display in the window area
	[Roact.Children] = t.optional(t.table),

	--- @prop @optional ButtonStackProps table ButtonStackProps
	ButtonStackProps = t.optional(t.table),

	--- @prop @optional Native table Native props
	Native = t.optional(t.table),
})

function Dialog:render()
	local props = self.props
	local state = self.state

	return WithTheme(function(Theme)
	
		-- ////////// Title

		local TitleFontStyle = Theme['fonts/Subtitle']
		local TitleTextStyle = Theme['colors/Fill_Color/Text/Primary']

		local Title = props.TitleText and new('TextLabel', {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			FontFace = TitleFontStyle.Font,
			LayoutOrder = 1,
			LineHeight = TitleFontStyle.LineHeight,
			Size = UDim2.fromScale(1, 0),
			Text = props.TitleText,
			TextSize = TitleFontStyle.Size,
			TextColor3 = TitleTextStyle.Color,
			TextTransparency = TitleTextStyle.Transparency,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		})

		-- ////////// Body

		local BodyFontStyle = Theme['fonts/Body']
		local BodyTextStyle = Theme['colors/Fill_Color/Text/Primary']

		local Body = props.BodyText and new('TextLabel', {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			FontFace = BodyFontStyle.Font,
			LayoutOrder = 2,
			LineHeight = BodyFontStyle.LineHeight,
			RichText = props.RichText,
			Size = UDim2.fromScale(1, 0),
			Text = props.BodyText,
			TextSize = BodyFontStyle.Size,
			TextColor3 = BodyTextStyle.Color,
			TextTransparency = BodyTextStyle.Transparency,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		})

		-- ////////// Detail Hyperlink
		
		-- Check if the detail container should be craeted
		local DetailContainerEnabled = props.DetailTitle or props.DetailBody or props.DetailContents

		local DetailHyperlink = DetailContainerEnabled and new(HyperlinkButton, {
			AutomaticSize = Enum.AutomaticSize.XY,
			LayoutOrder = state.DetailShown and 4 or 3,
			Size = UDim2.fromScale(0, 0),
			Text = props.DetailButtonText,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		-- ////////// Buttons

		local Buttons = props.Buttons and new(ButtonStack, Sift.Dictionary.join({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Buttons = props.Buttons,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, 0, 1, 0),
			PaddingLeft = UDim.new(0, Theme['styles/Padding/Default/Outer/Left']),
			PaddingRight = UDim.new(0, Theme['styles/Padding/Default/Outer/Right']),
		}, props.ButtonStackProps))

		-- ////////// Dialog
		return new(Window, Sift.Dictionary.join({
			AnchorPoint = props.AnchorPoint,
			AutomaticSize = props.AutomaticSize,
			ContentBackgroundColor = 'colors/Background/Fill_Color/Layer/Alt',
			Position = props.Position,
			Size = props.Size,
			Native = props.Native,

			FooterHeight = Buttons and 80 or 0,
			FooterContents = Buttons,

			TitleBarProps = Sift.Dictionary.join({
				BackgroundColor = 'colors/Background/Fill_Color/Layer/Alt',
			}, props.TitleBarProps),
		}, props.WindowProps), {
			Title = Title,
			Body = Body,
			DetailHyperlink = DetailHyperlink,

			Layout = new('UIListLayout', {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 12),
			}),
			Padding = new('UIPadding', {
				PaddingBottom = UDim.new(0, Theme['styles/Padding/Content/Outer/Bottom']),
				PaddingLeft = UDim.new(0, Theme['styles/Padding/Content/Outer/Left']),
				PaddingRight = UDim.new(0, Theme['styles/Padding/Content/Outer/Right']),
				PaddingTop = UDim.new(0, Theme['styles/Padding/Content/Outer/Top']),
			}),
		})
	end)
end

return Dialog