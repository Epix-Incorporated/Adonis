--------------------------------------------------------------------------------------------
-------------------------------------- Slider Module ---------------------------------------
-- [Adonis Maintainer]: P3tray
-- [Author]: Krypt
-- [Description]: Creates a slider based on a start, end and incremental value. Allows ...
-- ... sliders to be moved, tracked/untracked, reset, and have specific properties such ...
-- ... as their current value and increment to be overriden.

-- [Created]: 22/12/2021
-- [Edited]: 18/01/2022
-- [Dev Forum Link]: https://devforum.roblox.com/t/1597785/
--------------------------------------------------------------------------------------------

--!nonstrict
local Slider = {
	Sliders = {}
}

local RunService = game:GetService("RunService")

if not RunService:IsClient() then
	error("Slider module can only be used on the Client!", 2)
	return nil
end

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Clamp = math.clamp
local Floor = math.floor
local Min = math.min
local Max = math.max
local Round = math.round

local Lower = string.lower
local Upper = string.upper
local Sub = string.sub
local Format = string.format

local Signal = require(script.Parent.Signal)

Slider.__index = function(object, indexed)
	local deprecated = {
		{".OnChange", ".Changed", object.Changed}
	}

	for _, tbl in ipairs(deprecated) do
		local deprecatedStr = Sub(tbl[1], 2)

		if deprecatedStr == indexed then
			warn(Format("%s is deprecated, please use %s instead", tbl[1], tbl[2]))
			return tbl[3]
		end
	end

	return Slider[indexed]
end

export type sliderConfigDictionary = {[string]: number}

function snapToScale(val, step)
	return Clamp(Floor(val / step) * step, 0, 1)
end

function lerp(start, finish, percent)
	return (1 - percent) * start + percent * finish
end

function map(value, start, stop, newStart, newEnd, constrain)
	local newVal = lerp(newStart, newEnd, getAlphaBetween(start, stop, value))
	if not constrain then
		return newVal
	end

	if newStart < newEnd then
		newStart, newEnd = newEnd, newStart
	end

	return Max(Min(newVal, newStart), newEnd)
end

function getNewPosition(self, percent)
	local absoluteSize = self._button.AbsoluteSize[self._axis]
	local holderSize = self._holder.AbsoluteSize[self._axis]

	local anchorPoint = self._button.AnchorPoint[self._axis]

	local paddingScale = (self._padding / holderSize)

	local minScale = (
		(anchorPoint * absoluteSize) / holderSize +
		paddingScale
	)

	local decrement = ((2 * absoluteSize) * anchorPoint) - absoluteSize
	local maxScale = (1 - minScale) + (decrement / holderSize)

	local newPercent = map(percent or self._percent, 0, 1, minScale, maxScale, true)

	if self._axis == "X" then
		return UDim2.new(newPercent, self._button.Position.X.Offset, self._button.Position.Y.Scale, self._button.Position.Y.Offset)
	elseif self._axis == "Y" then
		return UDim2.fromScale(self._button.Position.X.Scale, newPercent)
	end
end

function getScaleIncrement(self)
	return 1 / ((self._config.End - self._config.Start) / self._config.Increment)
end

function getAlphaBetween(a, b, c)
	return (c - a) / (b - a)
end

function getNewValue(self)
	local newValue = lerp(self._config.Start, self._config.End, self._percent)
	local incrementScale = (1 / self._config.Increment)

	newValue = Floor(newValue * incrementScale) / incrementScale
	return newValue
end

function Slider.new(holder: any, configuration: sliderConfigDictionary, moveTweenInfo: TweenInfo, axis: string, padding: number)
	assert(pcall(function()
		return holder.AbsoluteSize, holder.AbsolutePosition
	end), "Holder argument does not have an AbsoluteSize/AbsolutePosition")

	local sliderBtn = holder:FindFirstChild("Slider")
	assert(sliderBtn ~= nil, "Failed to find slider button.")
	assert(sliderBtn:IsA("GuiButton"), "Slider is not a GuiButton")

	local duplicate = false
	for _, slider in ipairs(Slider.Sliders) do
		if slider._holder == holder then
			duplicate = true
			break
		end
	end

	assert(not duplicate, "Cannot set two sliders with same frame!")
	assert(configuration.Increment ~= nil, "Failed to find Increment in configuration table")
	assert(configuration.Start ~= nil, "Failed to find Start in configuration table")
	assert(configuration.End ~= nil, "Failed to find End in configuration table")
	assert(configuration.Increment > 0, "Increment must be greater than 0")
	assert(configuration.End > configuration.Start, `Config.End must be greater than Config.Start ({configuration.End} <= {configuration.Start})`)

	axis = axis or "x"
	axis = Lower(axis)
	assert(axis == "x" or axis == "y", "Axis must be X or Y!")

	assert(typeof(moveTweenInfo) == "TweenInfo", "MoveTweenInfo must be a TweenInfo object!")

	padding = padding or 5
	assert(type(padding) == "number", "Padding variable must be a number!")

	local self = setmetatable({}, Slider)

	self._holder = holder
	self._button = sliderBtn
	self._config = configuration
	self._axis = Upper(axis)
	self._padding = padding

	self.IsHeld = false
	self._mainConnection = nil
	self._buttonConnections = {}
	self._inputPos = nil

	self._percent = 0
	if configuration.DefaultValue then
		configuration.DefaultValue = Clamp(configuration.DefaultValue, configuration.Start, configuration.End)
		self._percent = getAlphaBetween(configuration.Start, configuration.End, configuration.DefaultValue)
	end
	self._percent = Clamp(self._percent, 0, 1)

	self._value = getNewValue(self)
	self._scaleIncrement = getScaleIncrement(self)

	self._currentTween = nil
	self._tweenInfo = moveTweenInfo or TweenInfo.new(1)

	self.Changed = Signal.new()
	self.Dragged = Signal.new()
	self.Released = Signal.new()

	self:Move()
	table.insert(Slider.Sliders, self)

	return self
end

function Slider:Track()
	for _, connection in ipairs(self._buttonConnections) do
		connection:Disconnect()
	end

	table.insert(self._buttonConnections, self._button.MouseButton1Down:Connect(function()
		self.IsHeld = true
	end))

	table.insert(self._buttonConnections, self._button.MouseButton1Up:Connect(function()
		if self.IsHeld then
			self.Released:Fire(self._value)
		end
		self.IsHeld = false
	end))

	if self.Changed then
		self.Changed:Fire(self._value)
	end

	if self._mainConnection then
		self._mainConnection:Disconnect()
	end

	self._mainConnection = UserInputService.InputChanged:Connect(function(inputObject, gameProcessed)
		if inputObject.UserInputType == Enum.UserInputType.MouseMovement or inputObject.UserInputType == Enum.UserInputType.Touch then
			self._inputPos = inputObject.Position
			self:Update()
		end
	end)
end

function Slider:Update()
	if self.IsHeld and self._inputPos then
		local mousePos = self._inputPos[self._axis]

		local sliderSize = self._holder.AbsoluteSize[self._axis]
		local sliderPos = self._holder.AbsolutePosition[self._axis]
		local newPos = snapToScale((mousePos - sliderPos) / sliderSize, self._scaleIncrement)

		local percent = Clamp(newPos, 0, 1)
		self._percent = percent
		self:Move()
		self.Dragged:Fire(self._value)
	end
end

function Slider:Untrack()
	for _, connection in ipairs(self._buttonConnections) do
		connection:Disconnect()
	end
	if self._mainConnection then
		self._mainConnection:Disconnect()
	end
	self.IsHeld = false
end

function Slider:Reset()
	for _, connection in ipairs(self._buttonConnections) do
		connection:Disconnect()
	end
	if self._mainConnection then
		self._mainConnection:Disconnect()
	end

	self.IsHeld = false

	self._percent = 0
	if self._config.DefaultValue then
		self._percent = getAlphaBetween(self._config.Start, self._config.End, self._config.DefaultValue)
	end
	self._percent = Clamp(self._percent, 0, 1)
	self:Move()
end

function Slider:OverrideValue(newValue: number)
	self.IsHeld = false
	self._percent = getAlphaBetween(self._config.Start, self._config.End, newValue)
	self._percent = Clamp(self._percent, 0, 1)
	self._percent = snapToScale(self._percent, self._scaleIncrement)
	self:Move()
end

function Slider:Move()
	self._value = getNewValue(self)

	if self._currentTween then
		self._currentTween:Cancel()
	end
	self._currentTween = TweenService:Create(self._button, self._tweenInfo, {
		Position = getNewPosition(self)
	})

	self._currentTween:Play()
	self.Changed:Fire(self._value)
end

function Slider:OverrideVisualValue(newValue: number)
	if self.IsHeld then
		return false
	end

	local percent = getAlphaBetween(self._config.Start, self._config.End, newValue)
	percent = Clamp(percent, 0, 1)
	percent = snapToScale(percent, self._scaleIncrement)

	if self._currentTween then
		self._currentTween:Cancel()
	end
	self._currentTween = TweenService:Create(self._button, self._tweenInfo, {
		Position = getNewPosition(self, percent)
	})

	self._currentTween:Play()
end

function Slider:OverrideIncrement(newIncrement: number)
	self._config.Increment = newIncrement
	self._scaleIncrement = getScaleIncrement(self)
	self._percent = Clamp(self._percent, 0, 1)
	self._percent = snapToScale(self._percent, self._scaleIncrement)
	self:Move()
end

function Slider:GetValue()
	return self._value
end

function Slider:GetIncrement()
	return self._increment
end

function Slider:Destroy()
	for _, connection in ipairs(self._buttonConnections) do
		connection:Disconnect()
	end
	if self._mainConnection then
		self._mainConnection:Disconnect()
	end
	self.Changed:Destroy()
	self.Dragged:Destroy()
	self.Released:Destroy()

	for index = 1, #Slider.Sliders do
		if Slider.Sliders[index] == self then
			table.remove(Slider.Sliders, index)
		end
	end

	setmetatable(self, nil)
	self = nil
end

UserInputService.InputEnded:Connect(function(inputObject, internallyProcessed)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
		for _, slider in ipairs(Slider.Sliders) do
			if slider.IsHeld then
				slider.Released:Fire(slider._value)
			end
			slider.IsHeld = false
		end
	end
end)

return Slider

-----------------------------------------------------------------------------------------
