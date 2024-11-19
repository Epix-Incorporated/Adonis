local RunService = game:GetService("RunService")

local module = {}

local function AlphaColorSequence(Sequence, Alpha)
	local Keypoints = Sequence.Keypoints
	local StartKeypoint, EndKeypoint = 1, #Keypoints

	for i, Keypoint in ipairs(Keypoints) do
		if Keypoint.Time >= Alpha then
			EndKeypoint = Keypoint
			StartKeypoint = Keypoints[math.max(1, i-1)]
			break
		end
	end

	local StartTime, EndTime = StartKeypoint.Time, EndKeypoint.Time
	local StartValue, EndValue = StartKeypoint.Value, EndKeypoint.Value

	local KeyframeAlpha = (Alpha - StartTime) / (EndTime - StartTime)

	return StartValue:Lerp(EndValue, KeyframeAlpha)
end

function module.new(Frame, BarCount)

	-- Determine settings
	local BAR_COUNT = math.clamp(type(BarCount) == "number" and BarCount or 41, 11,601)
	local SAMPLE_HZ = math.clamp(BAR_COUNT/2,10,500)

	if BAR_COUNT%2==0 then
		BAR_COUNT += 1
	end

	local BAR_SIZE = 1/BAR_COUNT
	local BUFFER_COUNT = math.ceil(BAR_COUNT/2)
	local BAR_TO_BUFFER = table.create(BAR_COUNT)
	local BAR_TO_MULTIPLIER = table.create(BAR_COUNT)

	for i=1, BAR_COUNT do
		BAR_TO_BUFFER[i] = math.abs(BUFFER_COUNT- (i+ (i<=BUFFER_COUNT and -1 or 1) ))
		BAR_TO_MULTIPLIER[i] = 1-(math.clamp(math.abs(BUFFER_COUNT- (i+ (i<=BUFFER_COUNT and -1 or 1) ))/BUFFER_COUNT, 0.01,1)^2)
	end

	local UPDATE_WAIT = 1/SAMPLE_HZ

	-- Setup visualizer

	local Visualizer = {
		Frame = Frame;
		VolumeBuffer = table.create(BUFFER_COUNT+1);
		Bars = {};
		BufferConnection = nil;
		PlayingConnection = nil;
		Sound = nil;
	}

	-- Create the bar guis
	for i=1, BAR_COUNT do

		local Bar = Frame:Add("Frame", {
			BorderSizePixel = 0;
			BackgroundColor3 = Color3.new(0.98,0.98,0.99);
			AnchorPoint = Vector2.new(0,0.5);
			Size = UDim2.new(BAR_SIZE,0,0.02,0);
			Position = UDim2.new(BAR_SIZE* (i-1), 0,0.5,0);
		})

		Visualizer.Bars[i] = Bar
	end

	local function HandlePlaying()
		if Visualizer.BufferConnection then
			Visualizer.BufferConnection:Disconnect()
			Visualizer.BufferConnection = nil
		end

		local Sound = Visualizer.Sound
		if not Sound then return end

		if Sound.Playing then
			local LastStored = os.clock()
			Visualizer.BufferConnection = RunService.Heartbeat:Connect(function()
				local success, void = pcall(function()
					Visualizer.VolumeBuffer[1] = Sound.PlaybackLoudness
					Visualizer.Bars[BUFFER_COUNT]:TweenSize(
						UDim2.new(
							BAR_SIZE,0,
							math.clamp((Sound.PlaybackLoudness/400), 0.02,1),0
						),
						Enum.EasingDirection.Out, Enum.EasingStyle.Linear, 0.014, true
					)

					if os.clock()-LastStored > UPDATE_WAIT then
						LastStored = os.clock()

						table.insert(Visualizer.VolumeBuffer,1,Sound.PlaybackLoudness)
						local Length = #Visualizer.VolumeBuffer
						if Length > BUFFER_COUNT then
							Visualizer.VolumeBuffer[#Visualizer.VolumeBuffer] = nil
						end

						local Color = Visualizer.Color
						local ColorType = typeof(Color)

						for i,Bar in ipairs(Visualizer.Bars) do

							local Alpha = math.clamp(
								((Visualizer.VolumeBuffer[BAR_TO_BUFFER[i]] or 0)/400),
								0.02, 1
							)

							Bar:TweenSize(
								UDim2.new(
									BAR_SIZE,0,
									Alpha,0
								),
								Enum.EasingDirection.Out, Enum.EasingStyle.Linear, UPDATE_WAIT, true
							)

							if Color then
								if ColorType == "Color3" then
									Bar.BackgroundColor3 = Color
								elseif ColorType == "ColorSequence" then
									Bar.BackgroundColor3 = AlphaColorSequence(Color, Alpha)
								end
							end

						end
					end
				end)
				if not success then Visualizer:UnlinkFromSound() end
			end)
		else
			table.clear(Visualizer.VolumeBuffer)
			for i,Bar in ipairs(Visualizer.Bars) do
				Bar:TweenSize(
					UDim2.new(BAR_SIZE,0,0.02,0),
					Enum.EasingDirection.Out, Enum.EasingStyle.Linear, UPDATE_WAIT, true
				)
			end
		end
	end

	function Visualizer:LinkToSound(Sound)

		Visualizer:UnlinkFromSound()

		table.clear(Visualizer.VolumeBuffer)

		Visualizer.Sound = Sound

		HandlePlaying()
		Visualizer.PlayingConnection = Sound:GetPropertyChangedSignal("Playing"):Connect(HandlePlaying)
	end

	function Visualizer:UnlinkFromSound()

		if Visualizer.PlayingConnection then
			Visualizer.PlayingConnection:Disconnect()
			Visualizer.PlayingConnection = nil
		end
		if Visualizer.BufferConnection then
			Visualizer.BufferConnection:Disconnect()
			Visualizer.BufferConnection = nil
		end

		Visualizer.Sound = nil

		for i,Bar in ipairs(Visualizer.Bars) do
			Bar:TweenSize(
				UDim2.new(BAR_SIZE,0,0.02,0),
				Enum.EasingDirection.Out, Enum.EasingStyle.Linear, UPDATE_WAIT, true
			)
		end

	end

	function Visualizer:Destroy()
		if Visualizer.PlayingConnection then
			Visualizer.PlayingConnection:Disconnect()
			Visualizer.PlayingConnection = nil
		end
		if Visualizer.BufferConnection then
			Visualizer.BufferConnection:Disconnect()
			Visualizer.BufferConnection = nil
		end
		for i,Bar in ipairs(Visualizer.Bars) do
			Bar:Destroy()
		end
		table.clear(Visualizer.VolumeBuffer)
	end


	return Visualizer
end

return module
