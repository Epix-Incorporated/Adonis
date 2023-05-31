-- UIStroke: A custom UIStroke wrapper with support for stroke inset

local Winro = script.Parent.Parent.Parent
local Packages = Winro.Parent

local Sift = require(Packages.Sift)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local UIStroke = Roact.PureComponent:extend(script.Name)

UIStroke.defaultProps = {
	Thickness = 1, --- @defaultProp
	BorderMode = Enum.BorderMode.Inset, --- @defaultProp
}

function UIStroke:ClearConnections()
	
	if self.SizeChangedConnection then
		self.SizeChangedConnection = self.SizeChangedConnection:Disconnect()
	end

	if self.CornerChangedConnection then
		self.CornerChangedConnection = self.CornerChangedConnection:Disconnect()
	end
	
	if self.ChildAddedConnection then
		self.ChildAddedConnection = self.ChildAddedConnection:Disconnect()
	end
end

function UIStroke:willUnmount()
	self:ClearConnections()
end

function UIStroke:ApplyChanges(rbx)
	local props = self.props
	local Parent = rbx and rbx.Parent

	if rbx and Parent and Parent:IsA('GuiObject') then
		
		-- Apply the size
		local AbsoluteSize = Parent.AbsoluteSize
		rbx.Size = UDim2.fromOffset(AbsoluteSize.X, AbsoluteSize.Y)
		- (props.BorderMode == Enum.BorderMode.Inset and UDim2.fromOffset(props.Thickness * 2, props.Thickness * 2) or UDim2.new()) -- Account for stroke width and inset

		-- Apply corner radius
		local Corner = Parent:FindFirstChildOfClass('UICorner')
		if Corner then

			if not self.CornerChangedConnection then
				self.CornerChangedConnection = Corner:GetPropertyChangedSignal('CornerRadius'):Connect(function()
					self:ApplyChanges(rbx)
				end)
			end

			rbx.Corner.CornerRadius = Corner.CornerRadius - (props.BorderMode == Enum.BorderMode.Inset and UDim.new(0, props.Thickness) or UDim.new()) -- Account for stroke width
		end
	end
end

function UIStroke:render()
	local props = self.props

	local SafeProps = Sift.Dictionary.copy(props)
	SafeProps.BorderMode = nil

	return new('Frame', {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.5),

		-- Used for size and corner detection
		[Roact.Ref] = function (rbx: GuiObject)

			if rbx and rbx.Parent and rbx.Parent:IsA('GuiObject') then

				-- Prepare
				self:ClearConnections()
				self:ApplyChanges(rbx)

				-- Detect whenever an applicable UI modifier is added
				self.ChildAddedConnection = rbx.Parent.ChildAdded:Connect(function()
					self:ApplyChanges(rbx)
				end)

				-- Detect whenever the parent frame's size is changed
				self.SizeChangedConnection = rbx.Parent:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
					self:ApplyChanges(rbx)
				end)
			end
		end
	}, {
		Stroke = new('UIStroke', SafeProps),

		Corner = new('UICorner', {
			CornerRadius = UDim.new(0, 0),
		}),
	})
end

return UIStroke