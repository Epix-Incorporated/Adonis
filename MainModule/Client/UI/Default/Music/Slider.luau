--------------------------------------------------------------------------------------------
-------------------------------------- Slider Module ---------------------------------------
-- [Adonis Maintainer]: P3tray
-- [Author]: Krypt
-- [Description]: Creates a slider based on a start, end and incremental value. Allows ...
-- ... sliders to be moved, tracked/untracked, reset, and have specific properties such ...
-- ... as their current value and increment to be overriden.

-- [Version]: 2.1.1
-- [Created]: 22/12/2021
-- [Updated]: 23/11/2022
-- [Dev Forum Link]: https://devforum.roblox.com/t/1597785/
--------------------------------------------------------------------------------------------

--!nonstrict
local Slider = {Sliders = {}}

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

assert(RunService:IsClient(), "Slider module can only be used on the Client!")

local SliderFuncs = {}
do
	function SliderFuncs.snapToScale(val: number, step: number): number
		return math.clamp(math.round(val / step) * step, 0, 1)
	end

	function lerp(start: number, finish: number, percent: number): number
		return (1 - percent) * start + percent * finish
	end

	function SliderFuncs.map(value: number, start: number, stop: number, newStart: number, newEnd: number, constrain: boolean): number
		local newVal = lerp(newStart, newEnd, SliderFuncs.getAlphaBetween(start, stop, value))
		if not constrain then
			return newVal
		end

		if newStart < newEnd then
			newStart, newEnd = newEnd, newStart
		end

		return math.max(math.min(newVal, newStart), newEnd)
	end

	function SliderFuncs.getNewPosition(self): UDim2
		local absoluteSize = self._data.Button.AbsoluteSize[self._config.Axis]
		local holderSize = self._holder.AbsoluteSize[self._config.Axis]

		local anchorPoint = self._data.Button.AnchorPoint[self._config.Axis]

		local paddingScale = (self._config.Padding / holderSize)

		local minScale = ((anchorPoint * absoluteSize) / holderSize + paddingScale)
		local decrement = ((2 * absoluteSize) * anchorPoint) - absoluteSize
		local maxScale = (1 - minScale) + (decrement / holderSize)

		local newPercent = SliderFuncs.map(self._data._percent, 0, 1, minScale, maxScale, true)

		return 
			if self._config.Axis == "X" then UDim2.fromScale(newPercent, self._data.Button.Position.Y.Scale)
			else UDim2.fromScale(self._data.Button.Position.X.Scale, newPercent)
	end

	function SliderFuncs.getScaleIncrement(self)
		return 1 / ((self._config.SliderData.End - self._config.SliderData.Start) / self._config.SliderData.Increment)
	end

	function SliderFuncs.getAlphaBetween(a: number, b: number, c: number): number
		return (c - a) / (b - a)
	end

	function SliderFuncs.getNewValue(self)
		local newValue = lerp(self._config.SliderData.Start, self._config.SliderData.End, self._data._percent)
		local incrementScale = (1 / self._config.SliderData.Increment)

		newValue = math.round(newValue * incrementScale) / incrementScale
		return newValue
	end
end

local Signal = require(script.Parent.Signal)

Slider.__index = function(object, indexed)
	local deprecated = {
		{".OnChange", ".Changed", rawget(object, "Changed")}
	}

	for _, tbl in ipairs(deprecated) do
		local deprecatedStr = string.sub(tbl[1], 2)

		if deprecatedStr == indexed then
			warn(string.format("%s is deprecated, please use %s instead", tbl[1], tbl[2]))
			return tbl[3]	
		end
	end

	return Slider[indexed]
end

export type configDictionary = {
	SliderData: {Start: number, End: number, Increment: number, DefaultValue: number | nil},
	MoveType: "Tween" | "Instant" | nil,
	MoveInfo: TweenInfo | nil,
	Axis: string | nil,
	Padding: number | nil,
	AllowBackgroundClick: boolean
}

function Slider.new(holder: GuiBase2d, config: configDictionary)
	assert(pcall(function()
		return holder.AbsoluteSize, holder.AbsolutePosition
	end), "Holder argument does not have an AbsoluteSize/AbsolutePosition")
	
	local duplicate = false
	for _, slider in ipairs(Slider.Sliders) do
		if slider._holder == holder then
			duplicate = true
			break
		end
	end
	
	assert(not duplicate, "Cannot set two sliders with same frame!")
	assert(config.SliderData.Increment ~= nil, "Failed to find Increment in SliderData table")
	assert(config.SliderData.Start ~= nil, "Failed to find Start in SliderData table")
	assert(config.SliderData.End ~= nil, "Failed to find End in SliderData table")
	assert(config.SliderData.Increment > 0, "SliderData.Increment must be greater than 0")
	assert(config.SliderData.End > config.SliderData.Start, string.format("Slider end value must be greater than its start value! (%.1f <= %.1f)", config.SliderData.End, config.SliderData.Start))
	
	local self = setmetatable({}, Slider)
	self._holder = holder
	self._data = {
		-- Buttons
		Button = nil,
		HolderButton = nil,
		
		-- Clicking
		_clickOverride = false,
		
		_mainConnection = nil,
		_clickConnections = {},
		_otherConnections = {},
		
		_inputPos = nil,
		
		-- Internal
		_percent = 0,
		_value = 0,
		_scaleIncrement = 0,
		_currentTween = nil,
		_allowBackgroundClick = if config.AllowBackgroundClick == false then false else true
	}
	
	self._config = config
	self._config.Axis = string.upper(config.Axis or "X")
	self._config.Padding = config.Padding or 5
	self._config.MoveInfo = config.MoveInfo or TweenInfo.new(0.2)
	self._config.MoveType = config.MoveType or "Tween"
	self.IsHeld = false
	
	local sliderBtn = holder:FindFirstChild("Slider")
	assert(sliderBtn ~= nil, "Failed to find slider button.")
	assert(sliderBtn:IsA("GuiButton"), "Slider is not a GuiButton")
	
	self._data.Button = sliderBtn
	
	-- Holder button --
	if self._data._allowBackgroundClick then
		local holderClickButton = Instance.new("TextButton")
		holderClickButton.BackgroundTransparency = 1
		holderClickButton.Text = ""
		holderClickButton.Name = "HolderClickButton"
		holderClickButton.Size = UDim2.fromScale(1, 1)
		holderClickButton.ZIndex = -1
		holderClickButton.Parent = self._holder
		self._data.HolderButton = holderClickButton
	end
	
	-- Finalise --
	
	self._data._percent = 0
	if config.SliderData.DefaultValue then
		config.SliderData.DefaultValue = math.clamp(config.SliderData.DefaultValue, config.SliderData.Start, config.SliderData.End)
		self._data._percent = SliderFuncs.getAlphaBetween(config.SliderData.Start, config.SliderData.End, config.SliderData.DefaultValue) 
	end
	
	self._data._percent = math.clamp(self._data._percent, 0, 1)

	self._data._value = SliderFuncs.getNewValue(self)
	self._data._increment = config.SliderData.Increment
	self._data._scaleIncrement = SliderFuncs.getScaleIncrement(self)
	
	self.Changed = Signal.new()
	self.Dragged = Signal.new()
	self.Released = Signal.new()
	
	self._data._percent = SliderFuncs.snapToScale(self._data._percent, self._data._scaleIncrement)
	self:Move()
	
	table.insert(self._data._otherConnections, sliderBtn:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:Move("Instant")
	end))
	
	table.insert(Slider.Sliders, self)
	
	return self
end

function Slider:Track()
	for _, connection in ipairs(self._data._clickConnections) do
		connection:Disconnect()
	end

	table.insert(self._data._clickConnections, self._data.Button.MouseButton1Down:Connect(function()
		self.IsHeld = true
	end))

	table.insert(self._data._clickConnections, self._data.Button.MouseButton1Up:Connect(function()
		if self.IsHeld then
			self.Released:Fire(self._data._value)
		end
		self.IsHeld = false
	end))

	if self._data._allowBackgroundClick then
		table.insert(self._data._clickConnections, self._data.HolderButton.Activated:Connect(function(inputObject: InputObject)
			if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
				self._data._inputPos = inputObject.Position
				self._data._clickOverride = true
				self:Update()
				self._data._clickOverride = false
			end
		end))
	end

	if self.Changed then
		self.Changed:Fire(self._data._value)
	end

	if self._data._mainConnection then
		self._data._mainConnection:Disconnect()
	end

	self._data._mainConnection = UserInputService.InputChanged:Connect(function(inputObject, gameProcessed)
		if inputObject.UserInputType == Enum.UserInputType.MouseMovement or inputObject.UserInputType == Enum.UserInputType.Touch then
			self._data._inputPos = inputObject.Position
			self:Update()
		end
	end)
end

function Slider:Update()
	if (self.IsHeld or self._data._clickOverride) and self._data._inputPos then
		local sliderSize = self._holder.AbsoluteSize[self._config.Axis]
		local sliderPos = self._holder.AbsolutePosition[self._config.Axis]
		
		local mousePos = self._data._inputPos[self._config.Axis]

		if mousePos then
			local relativePos = (mousePos - sliderPos)
			local newPos = SliderFuncs.snapToScale(relativePos / sliderSize, self._data._scaleIncrement)

			local percent = math.clamp(newPos, 0, 1)
			self._data._percent = percent
			self.Dragged:Fire(self._data._value)
			self:Move()
		end
	end
end

function Slider:Untrack()
	for _, connection in ipairs(self._data._clickConnections) do
		connection:Disconnect()
	end
	if self._data._mainConnection then
		self._data._mainConnection:Disconnect()
	end
	self.IsHeld = false
end

function Slider:Reset()
	for _, connection in ipairs(self._data._clickConnections) do
		connection:Disconnect()
	end
	if self._data._mainConnection then
		self._data._mainConnection:Disconnect()
	end

	self.IsHeld = false

	self._data._percent = 0
	if self._config.SliderData.DefaultValue then 
		self._data._percent = SliderFuncs.getAlphaBetween(self._config.SliderData.Start, self._config.SliderData.End, self._config.SliderData.DefaultValue)
	end
	self._data._percent = math.clamp(self._data._percent, 0, 1)
	self:Move()
end

function Slider:OverrideValue(newValue: number, supressEvent: boolean?) -- Patch by ccuser44 to prevent music glitching
	self.IsHeld = false
	self._data._percent = SliderFuncs.getAlphaBetween(self._config.SliderData.Start, self._config.SliderData.End, newValue)
	self._data._percent = math.clamp(self._data._percent, 0, 1)
	self._data._percent = SliderFuncs.snapToScale(self._data._percent, self._data._scaleIncrement)
	self:Move(nil, supressEvent)
end

function Slider:Move(override: string, supressEvent: boolean?)
	self._data._value = SliderFuncs.getNewValue(self)
	
	local moveType = if override ~= nil then override else self._config.MoveType
	if moveType == "Tween" or moveType == nil then
		if self._data._currentTween then
			self._data._currentTween:Cancel()
		end
		self._data._currentTween = TweenService:Create(self._data.Button, self._config.MoveInfo, {
			Position = SliderFuncs.getNewPosition(self)
		})
		self._data._currentTween:Play()
	elseif moveType == "Instant" then
		self._data.Button.Position = SliderFuncs.getNewPosition(self)
	end

	if not supressEvent then
		self.Changed:Fire(self._data._value)
	end
end

function Slider:OverrideIncrement(newIncrement: number)
	self._config.SliderData.Increment = newIncrement
	self._data._increment = newIncrement
	self._data._scaleIncrement = SliderFuncs.getScaleIncrement(self)
	self._data._percent = math.clamp(self._data._percent, 0, 1)
	self._data._percent = SliderFuncs.snapToScale(self._data._percent, self._data._scaleIncrement)
	self:Move()
end

function Slider:GetValue()
	return self._data._value
end

function Slider:GetIncrement()
	return self._data._increment
end

function Slider:Destroy()
	for _, connection in ipairs(self._data._clickConnections) do
		connection:Disconnect()
	end
	for _, connection in ipairs(self._data._otherConnections) do
		connection:Disconnect()
	end

	if self._data._mainConnection then
		self._data._mainConnection:Disconnect()
	end
	
	if self._data.HolderButton then
		self._data.HolderButton:Destroy()
		self._data.HolderButton = nil
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

UserInputService.InputEnded:Connect(function(inputObject: InputObject, internallyProcessed: boolean)
	if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
		for _, slider in ipairs(Slider.Sliders) do
			if slider.IsHeld then
				slider.Released:Fire(slider._data._value)
			end
			slider.IsHeld = false
		end
	end 
end)
	
return Slider
-----------------------------------------------------------------------------------------
