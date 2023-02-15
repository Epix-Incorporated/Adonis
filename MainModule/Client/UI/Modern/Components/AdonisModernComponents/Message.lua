-- Message: Attention grabbing on screen message

local Components = script.Parent
local Packages = Components.Parent.Packages

local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local Message = Roact.PureComponent:extend(script.Name)

Message.validateProps = t.strictInterface({

	--- @prop @optional Image string Image
	Image = t.optional(t.string),

	--- @prop @optional TitleText string Title text
	TitleText = t.optional(t.string),

	--- @prop @optional BodyText string Message content
	BodyText = t.optional(t.string),
})

function Message:render()
	local props = self.props

	self.HasThumbnailAsImage = (props.Image and props.Image:find('rbxthumb')) and true or false
	self.HasAvatarThumbnailAsImage = (self.HasThumbnailAsImage and (
		props.Image:match('type=Avatar') or
		props.Image:match('type=HeadShot')
	)) and true or false

	return new('Frame', {
		AnchorPoint = Vector2.new(0, 0.5),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromScale(1, 0),
	}, {

		Layout = new('UIListLayout', {
			Padding = UDim.new(0, 15),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		Padding = new('UIPadding', {
			PaddingBottom = UDim.new(0, 15),
			PaddingTop = UDim.new(0, 15),
		}),

		Text = new('Frame', {
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {

			Layout = new('UIListLayout', {
				Padding = UDim.new(0, 5),
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = props.Image and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Top,
			}),

			SizeConstraint = new('UISizeConstraint', {
				MaxSize = Vector2.new(500, math.huge),
			}),

			Body = props.BodyText and new('TextLabel', {
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				FontFace = Font.fromEnum(Enum.Font.SourceSans),
				RichText = true,
				Text = props.BodyText,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),

			Title = props.TitleText and new('TextLabel', {
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundTransparency = 1,
				LayoutOrder = 0,
				FontFace = Font.fromEnum(Enum.Font.SourceSansBold),
				RichText = true,
				Text = props.TitleText,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),
		}),

		Image = props.Image and new('ImageLabel', {
			BackgroundColor3 = Color3.fromRGB(45, 45, 45),
			BackgroundTransparency = self.HasThumbnailAsImage and 0 or 1,
			Size = UDim2.fromOffset(48, 48),
			Image = props.Image,
		}, {

			Corner = self.HasThumbnailAsImage and new('UICorner', {
				CornerRadius = UDim.new(self.HasAvatarThumbnailAsImage and 0.5 or 0, (not self.HasAvatarThumbnailAsImage) and 4 or 0),
			}) or nil,
		}),
	})
end

return Message