-- Expander: An expandable list collector

local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme

local GetTextSize = require(Winro.Utility.GetTextSize)

local Sift = require(Packages.Sift)
local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local RoundedSurface = require(Winro.App.Surface.RoundedSurface)

local Expander = Roact.PureComponent:extend(script.Name)

Expander.defaultProps = {
	Size = UDim2.new(1, 0, 0, 62), --- @defaultProp
}

function Expander:render()
	local props = self.props

	-- ////////// Expander
	return WithTheme(function(Theme)
		
		-- ////////// LeftContent/Icon

		local IconImageStyle = props.Icon and Theme[props.Icon]
		local IconStyle = Theme[IconImageStyle and IconImageStyle.Color or 'colors/Fill_Color/Text/Primary']

		local IconImage = props.Icon and new('ImageLabel', {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = IconImageStyle.Image,
			ImageColor3 = IconStyle.Color,
			ImageRectOffset = IconImageStyle.ImageRectOffset,
			ImageRectSize = IconImageStyle.ImageRectSize,
			ImageTransparency = IconStyle.Transparency,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(IconImageStyle.ImageRectSize.X, IconImageStyle.ImageRectSize.Y),
		}) or nil

		local Icon = IconImage and new('Frame', {
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.fromOffset(16, 16),
		}, IconImage)

		-- ////////// LeftContent/Text/Heading

		local HeadingTextStyle = Theme['colors/Fill_Color/Text/Primary']
		local HeadingFontStyle = Theme['fonts/Body']

		local GotHeadingTextSize, HeadingTextSize = GetTextSize(
			props.Heading,
			HeadingFontStyle.Font,
			HeadingFontStyle.Size
		)

		local Heading = props.Heading and new('TextLabel', {
			AutomaticSize = (not GotHeadingTextSize) and Enum.AutomaticSize.XY or Enum.AutomaticSize.None,
			BackgroundTransparency = 1,
			FontFace = HeadingFontStyle.Font,
			LayoutOrder = 1,
			LineHeight = HeadingFontStyle.LineHeight,
			Size = UDim2.fromOffset(HeadingTextSize.X, HeadingTextSize.Y),
			Text = props.Heading,
			TextColor3 = HeadingTextStyle.Color,
			TextTransparency = HeadingTextStyle.Transparency,
			TextSize = HeadingFontStyle.Size,
		}) or nil
		
		-- ////////// LeftContent/Text/Caption

		local CaptionTextStyle = Theme['colors/Fill_Color/Text/Secondary']
		local CaptionFontStyle = Theme['fonts/Caption']

		local GotCaptionTextSize, CaptionTextSize = GetTextSize(
			props.Caption,
			CaptionFontStyle.Font,
			CaptionFontStyle.Size
		)
		
		local Caption = props.Caption and new('TextLabel', {
			AutomaticSize = (not GotCaptionTextSize) and Enum.AutomaticSize.XY or Enum.AutomaticSize.None,
			BackgroundTransparency = 1,
			FontFace = CaptionFontStyle.Font,
			LayoutOrder = 2,
			LineHeight = CaptionFontStyle.LineHeight,
			Size = UDim2.fromOffset(CaptionTextSize.X, CaptionTextSize.Y),
			Text = props.Caption,
			TextColor3 = CaptionTextStyle.Color,
			TextTransparency = CaptionTextStyle.Transparency,
			TextSize = CaptionFontStyle.Size,
		}) or nil

		-- ////////// LeftContent/Text

		local Text = new('Frame', {
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0, 0),
			LayoutOrder = 2,
		}, {
			Heading = Heading,
			Caption = Caption,

			Layout = new('UIListLayout', {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		})

		-- ////////// LeftContent

		local LeftContent = new('Frame', {
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0, 1),
		}, {
			Icon = Icon,
			Text = Text,

			Layout = new('UIListLayout', {
				Padding = UDim.new(0, 16),
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			Padding = new('UIPadding', {
				PaddingLeft = UDim.new(0, 15),
				PaddingTop = UDim.new(0, 13),
				PaddingBottom = UDim.new(0, 13),
			}),
		})

		-- ////////// RightContent/
		
		-- ////////// Expander

		local ExpanderStyle = Theme['colors/Fill_Color/Subtle/Tertiary']

		return new(RoundedSurface, {
			BackgroundColor = ExpanderStyle,
			BackgroundTransparency = 0,
			CornerRadius = UDim.new(0, 3),
			Size = props.Size,
			LayoutOrder = 1,
			ShowTopLeftCorner = true,
			ShowTopRightCorner = true,
			ShowBottomLeftCorner = not props.Expanded,
			ShowBottomRightCorner = not props.Expanded,
		}, LeftContent)
	end)
end

return Expander