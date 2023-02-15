-- Tooltip: A flyout style label

local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Theme = require(Winro.Theme)
local WithTheme = Theme.WithTheme

local Validators = Winro.Validators
local StyleValidator = require(Validators.StyleValidator)

local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local GetTextSize = require(Winro.Utility.GetTextSize)
local DropShadow = require(Winro.App.Effect.DropShadow)
local Acrylic = require(Winro.App.Surface.Acrylic)

local Tooltip = Roact.PureComponent:extend(script.Name)

Tooltip.defaultProps = {
	AutomaticSize = Enum.AutomaticSize.XY, --- @defaultProp
	Position = UDim2.new(), --- @defaultProp
	Size = UDim2.fromOffset(0, 28), --- @defaultProp
	DropShadowEnabled = true, --- @defaultProp
}

Tooltip.validateProps = t.strictInterface({

	--- @prop @optional AutomaticSize Enum.AutomaticSize The Tooltip's automatic scaling
	AutomaticSize = t.optional(t.enum(Enum.AutomaticSize)),

	--- @prop @optional AnchorPoint Vector2 Anchor point
	AnchorPoint = t.optional(t.Vector2),

	--- @prop @optional DropShadowEnabled boolan Drop shadow's enabled status
	DropShadowEnabled = t.optional(t.boolean),

	--- @prop @optional Position UDim2 Position
	Position = t.optional(t.UDim2),

	--- @prop @optional Size UDim2 Size
	Size = t.optional(t.UDim2),

	--- @prop Text string The Tooltip's text
	Text = t.string,

	--- @prop @optional Icon string|table The Tooltip's icon
	Icon = t.optional(StyleValidator),

	--- @prop @optional Native table Native props
	Native = t.optional(t.table),
})

function Tooltip:init()
	
	-- Size binding, for `AutomaticSize`
	self.Size, self.SetSize = Roact.createBinding(UDim2.new())
end

function Tooltip:render()
	local props = self.props

	return WithTheme(function(Theme)
		
		-- ////////// Text label

		local LabelFontStyle = Theme['fonts/Caption']
		local LabelTextStyle = Theme['colors/Fill_Color/Text/Primary']
		
		local GotTextSize, TextSize = GetTextSize(props.Text, LabelFontStyle.Font, LabelFontStyle.Size)

		-- Fallback TextSize
		if not GotTextSize then
			warn('GetTextSize() Failed:', TextSize)
			TextSize = Vector2.new(0, 100)
		end

		local Label = new('TextLabel', {
			AutomaticSize = if GotTextSize then props.AutomaticSize else Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			FontFace = LabelFontStyle.Font,
			LayoutOrder = 2,
			Size = UDim2.fromOffset(TextSize.X, TextSize.Y),
			Text = props.Text,
			TextColor3 = LabelTextStyle.Color,
			TextSize = LabelFontStyle.Size,
			TextTransparency = LabelTextStyle.Transparency,
			TextXAlignment = Enum.TextXAlignment.Left,
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
			IconImageSize = UDim2.fromOffset(16, 16)
		end
		
		local Icon = IconImage and new('ImageLabel', {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = IconImage.Image,
			ImageColor3 = LabelTextStyle.Color,
			ImageRectOffset = IconImage.ImageRectOffset,
			ImageRectSize = IconImage.ImageRectSize,
			ImageTransparency = LabelTextStyle.Transparency,
			Position = UDim2.fromScale(0.5, 0.5),
			ResampleMode = IconImage.ResampleMode,
			Size = IconImageSize,
		})

		-- ////////// Text and Icon Wrapper

		local Wrapper = new('Frame', {
			AutomaticSize = props.AutomaticSize,
			BackgroundTransparency = 1,
		}, {
			Text = Label,
			Icon = Icon,

			Layout = new('UIListLayout', {
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 8),
			}),
		})

		-- ////////// Stroke

		local StrokeStyle = Theme['colors/Stroke_Color/Surface_Stroke/Flyout']

		local Stroke = new('UIStroke', {
			Color = StrokeStyle.Color,
			Transparency = StrokeStyle.Transparency,
		})

		-- ////////// Tooltip

		local TooltipStyle = Theme['colors/Background/Fill_Color/Acrylic_Background/Default']

		local Tooltip = new(Acrylic, {
			AutomaticSize = props.AutomaticSize,
			AnchorPoint = props.DropShadowEnabled and Vector2.new(0.5, 0.5) or props.AnchorPoint,
			BackgroundColor3 = TooltipStyle.Color,
			BackgroundTransparency = TooltipStyle.Transparency,
			Position = props.DropShadowEnabled and UDim2.fromScale(0.5, 0.5) or props.Position,
			Size = props.Size,

			[Roact.Change.AbsoluteSize] = function (rbx)
				local AbsoluteSize = rbx.AbsoluteSize

				self.SetSize(UDim2.fromOffset(AbsoluteSize.X, AbsoluteSize.Y) - UDim2.fromOffset(8 + 8, 7 + 5)) -- Account for padding
			end
		}, {
			TextAndIconWrapper = Wrapper,
			Stroke = Stroke,

			Corners = new('UICorner', {
				CornerRadius = UDim.new(0, Theme['styles/CornerRadius/Default/Inner']),
			}),
			Layout = new('UIListLayout', {
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 10),
			}),
			Padding = new('UIPadding', {
				PaddingBottom = UDim.new(0, 7),
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 5),
			}),
		})

		if props.DropShadowEnabled then
			return new(DropShadow, {
				AnchorPoint = props.AnchorPoint,
				Position = props.Position - UDim2.fromOffset(20 / 2, 20 / 2),
				CornerRadius = UDim.new(0, Theme['styles/CornerRadius/Default/Inner']),
				Size = self.Size:map(function(Size)
					return Size + UDim2.fromOffset(20, 20) + UDim2.fromOffset(8 + 8, 7 + 5) -- Accont for padding
				end),
			}, Tooltip)
		else
			return Tooltip
		end
	end)
end

return Tooltip