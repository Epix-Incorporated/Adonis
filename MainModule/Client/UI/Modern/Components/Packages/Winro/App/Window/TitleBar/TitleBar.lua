-- TitleBar: The top bar of a window component

local Winro = script.Parent.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme

local Validators = Winro.Validators
local StyleValidator = require(Validators.StyleValidator)

local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement


local GetTextSize = require(Winro.Utility.GetTextSize)
local RoundedSurface = require(Winro.App.Surface.RoundedSurface)

local TitleBarRoot = script.Parent
local CaptionClose = require(TitleBarRoot.CaptionClose)

local TITLEBAR_LABEL_FONT_STYLE = 'fonts/Caption'
local TITLEBAR_LABEL_TEXT_STYLE = 'colors/Fill_Color/Text/Primary'
local TITLEBAR_RELEASE_TEXT_STYLE = 'colors/Fill_Color/Text/Secondary'


local TitleBar = Roact.PureComponent:extend(script.Name)

TitleBar.defaultProps = {
	Height = 32, --- @defaultProp
	Text = 'TitleBar', --- @defaultProp
	CaptionButtonWidth = 48, --- @defaultProp

	BackgroundColor = {
		Color = Color3.new(),
		Transparency = 1,
	}, --- @defaultProp
}

TitleBar.validateProps = t.strictInterface({

	--- @prop @optional AlwaysShowClose boolean Always show the close button
	AlwaysShowClose = t.optional(t.boolean),
	
	--- @prop @optional CaptionButtonWidth number Caption Button's width
	CaptionButtonWidth = t.optional(t.number),

	--- @prop @optional Text string The TitleBar's text
	Text = t.optional(t.string),

	--- @prop @optional LayoutOrder number The TitleBar's layout order
	LayoutOrder = t.optional(t.number),

	--- @prop @optional Icon string|table The TitleBar's icon
	Icon = t.optional(StyleValidator),

	--- @prop @optional ReleaseText string The TitleBar's release text
	ReleaseText = t.optional(t.string),

	--- @prop @optional @style TextColor string|table The Label's text fill
	TextColor = t.optional(StyleValidator),

	--- @prop @optional @style BackgroundColor string|table The TitleBars's background fill
	BackgroundColor = t.optional(StyleValidator),

	--- @prop @optional Height number positive The TitleBar's height, in pixels
	Height = t.optional(t.numberPositive),

	--- @prop @optional OnClose function The function to call when the close button is pressed
	OnClose = t.optional(t.callback),

	--- @prop @optional Native table Native props
	Native = t.optional(t.table)
})

function TitleBar:render()
	local props = self.props

	return WithTheme(function(Theme)
		
		-- ////////// Label

		local LabelFontStyle = Theme[TITLEBAR_LABEL_FONT_STYLE]
		local LabelTextStyle = Theme[props.TextColor or TITLEBAR_LABEL_TEXT_STYLE]

		local GotLabelTextSize, LabelTextSize = GetTextSize(props.Text, LabelFontStyle.Font, LabelFontStyle.Size)

		local Label = new('TextLabel', {
			AutomaticSize = (not GotLabelTextSize) and Enum.AutomaticSize.X or nil, -- Fallback
			BackgroundTransparency = 1,
			FontFace = LabelFontStyle.Font,
			LayoutOrder = 1,
			Size = UDim2.new(0, GotLabelTextSize and LabelTextSize.X or 0, 1, 0),
			Text = props.Text,
			TextColor3 = LabelTextStyle.Color,
			TextSize = LabelFontStyle.Size,
			TextTransparency = LabelTextStyle.Transparency,
		})

		-- ////////// Release Label

		local ReleaseLabelTextStyle = Theme[TITLEBAR_RELEASE_TEXT_STYLE]

		local GotReleaseLabelTextSize, ReleaseLabelTextSize = nil, nil

		if props.ReleaseText then
			GotReleaseLabelTextSize, ReleaseLabelTextSize = GetTextSize(props.ReleaseText, LabelFontStyle.Font, LabelFontStyle.Size)
		end

		local ReleaseLabel = props.ReleaseText and new('TextLabel', {
			AutomaticSize = (not GotReleaseLabelTextSize) and Enum.AutomaticSize.X or nil, -- Fallback
			BackgroundTransparency = 1,
			FontFace = LabelFontStyle.Font,
			LayoutOrder = 2,
			Size = UDim2.new(0, GotReleaseLabelTextSize and ReleaseLabelTextSize.X or 0, 1, 0),
			Text = props.ReleaseText,
			TextColor3 = ReleaseLabelTextStyle.Color,
			TextSize = LabelFontStyle.Size,
			TextTransparency = ReleaseLabelTextStyle.Transparency,
		}) or nil

		-- ////////// Text Container

		local TextContainerWidth = LabelTextSize.X

		if GotReleaseLabelTextSize then
			TextContainerWidth += ReleaseLabelTextSize.X + 8 -- Account for 8px layout padding
		end

		local TextContainer = new('Frame', {
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Size = UDim2.new(0, TextContainerWidth, 1, 0),
		}, {
			Label = Label,
			ReleaseLabel = ReleaseLabel,

			Layout = new('UIListLayout', {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
			}),
		})

		-- ////////// Icon

		local IconImage = props.Icon and Theme[props.Icon]
		local IconImageSize = nil

		if IconImage then
			local IconImageRectSize = IconImage.ImageRectSize == Vector2.new() and Vector2.new(16, 16) or IconImage.ImageRectSize
			IconImageSize = UDim2.fromOffset(
				math.clamp(IconImageRectSize.X, 0, 9*4),
				math.clamp(IconImageRectSize.Y, 0, 9*4)
			)
		else
			IconImageSize = UDim2.fromOffset(0, 0)
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
			ImageColor3 = IconImage.ImageColor3,
			ImageTransparency = IconImage.ImageTransparency,
		})

		local Icon = IconImage and new('Frame', {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 16 + 8, 0.5, 0),
			Size = UDim2.new(0, 16, 1, 0),
		}, IconImage)

		-- ////////// Icon and Title

		local TotalPartsSize = UDim2.new(0, TextContainerWidth + (IconImage and 16 * 2 or 0) + 12, 1, 0) -- Account for 12px left padding, Account for additional 16px padding if an icon is present

		local IconAndTitle = new('Frame', {
			BackgroundTransparency = 1,
			LayoutOrder = 2,
			Size = TotalPartsSize,
		}, {
			Icon = Icon,
			TextConatainer = TextContainer,

			Layout = new('UIListLayout', {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 16),
			}),
			Padding = new('UIPadding', {
				PaddingLeft = UDim.new(0, 12),
			}),
		})

		-- ////////// TitleBar parts

		local Parts = new('Frame', {
			BackgroundTransparency = 1,
			Size = TotalPartsSize + UDim2.fromOffset(4, 0), -- Account for 4px left padding
		}, {
			IconAndTitle = IconAndTitle,

			Padding = new('UIPadding', {
				PaddingLeft = UDim.new(0, 4),
			}),
		})

		-- ////////// Caption buttons

		local CaptionContainerWidth = 0
		local CaptionButtons = {}

		if props.OnClose then
			CaptionButtons.Close = new(CaptionClose, {
				AlwaysShow = props.AlwaysShowClose,
				Width = props.CaptionButtonWidth,
				[Roact.Event.Activated] = props.OnClose,
			})
		end

		local CaptionButtonContainer = new('Frame', {
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(0, CaptionContainerWidth, 1, 0),
		}, CaptionButtons)

		-- ////////// TitleBar
		return new(RoundedSurface, {
			BackgroundColor = Theme[props.BackgroundColor],
			CornerRadius = UDim.new(0, Theme['styles/CornerRadius/Default/Outer']),
			LayoutOrder = props.LayoutOrder,
			Size = UDim2.new(1, 0, 0, props.Height),
			ShowTopLeftCorner = true,
			ShowTopRightCorner = true,
			Native = props.Native,
		}, {
			Parts = Parts,
			CaptionButtonContainer = CaptionButtonContainer,
		})
	end)
end

return TitleBar