-- Hint: Subtle hint appearing on the top of the screen

local Components = script.Parent
local Packages = Components.Parent.Packages

local t = require(Packages.t)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local Hint = Roact.PureComponent:extend(script.Name)

Hint.validateProps = t.strictInterface({

	--- @prop @optional Image string Image
	Image = t.optional(t.string),

	--- @prop @optional TitleText string Title text
	TitleText = t.optional(t.string),

	--- @prop @optional BodyText string Message content
	BodyText = t.optional(t.string),
})

function Hint:render()
	local props = self.props

	self.HasThumbnailAsImage = (props.Image and props.Image:find("rbxthumb")) and true or false
	self.HasAvatarThumbnailAsImage = (
		self.HasThumbnailAsImage and (props.Image:match("type=Avatar") or props.Image:match("type=HeadShot"))
	)
	and true or false

	return new("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(43, 43, 43),
		BackgroundTransparency = 0.2,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0),
	}, {

		Layout = new("UIListLayout", {
			Padding = UDim.new(0, 10),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		Padding = new("UIPadding", {
			PaddingBottom = UDim.new(0, 5),
			PaddingTop = UDim.new(0, 5),
		}),

		Text = new("Frame", {
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {

			Layout = new("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Top,
			}),

			SizeConstraint = new("UISizeConstraint", {
				MaxSize = Vector2.new(500, math.huge),
			}),

			Body = props.BodyText and new("TextLabel", {
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

			Title = props.TitleText and new("TextLabel", {
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

		Image = props.Image and new("ImageLabel", {
			BackgroundColor3 = Color3.fromRGB(45, 45, 45),
			BackgroundTransparency = self.HasThumbnailAsImage and 0 or 1,
			Size = UDim2.fromOffset(48/2, 48/2),
			Image = props.Image,
		}, {

			Corner = self.HasThumbnailAsImage and new("UICorner", {
				CornerRadius = UDim.new(
					self.HasAvatarThumbnailAsImage and 0.5 or 0,
					(not self.HasAvatarThumbnailAsImage) and 4 or 0
				),
			}) or nil,
		}),
	})
end

return Hint
