local Winro = script.Parent.Parent
local Packages = Winro.Parent

local Roact = require(Packages.Roact)
local new = Roact.createElement

local WireframeVisualizer = Roact.PureComponent:extend(script.Name)

local ClassToColor = {
	Frame = Color3.new(1, 0, 0),
	TextLabel = Color3.new(0, 1, 0),
	TextButton = Color3.new(0, 0.5, 0.5),
}

function WireframeVisualizer:init()
	self.Ref = Roact.createRef()
end

function WireframeVisualizer:didMount()
	local Frame = self.Ref:getValue()

	for _, Child: GuiObject in pairs(Frame:GetDescendants()) do
		if Child:IsA('GuiBase') then
			local TargetFrame = Instance.new('Frame')
			TargetFrame.BackgroundTransparency = 1
			TargetFrame.Size = UDim2.new(1, -2, 1, -2)
			local Stroke = Child:FindFirstChildOfClass('UIStroke') or Instance.new('UIStroke')
			Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			Stroke.Color = ClassToColor[Child.ClassName] or Color3.new(1, 0, 1)
			Stroke.Transparency = 0

			Stroke.Parent = Child
			--TargetFrame.Parent = Child
		end
	end
end

function WireframeVisualizer:render()
	return new('Frame', {
		AutomaticSize = 'XY',
		BackgroundTransparency = 1,
		Size = self.props.Size,
		[Roact.Ref] = self.Ref
	}, self.props[Roact.Children])
end

return WireframeVisualizer