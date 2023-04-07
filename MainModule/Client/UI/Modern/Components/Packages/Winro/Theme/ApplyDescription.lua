local Packages = script.Parent.Parent.Parent
local Flipper = require(Packages.Flipper)

local function CollectKeypoints(Sequence)

	if typeof(Sequence) == 'ColorSequence' then

		-- Extract each keypoint
		local Keypoints = {}

		for Index, Keypoint in pairs(Sequence.Keypoints) do
			local Color = Keypoint.Value
			Keypoints[Index] = {
				T = Keypoint.Time,
				V = {
					R = Color.R,
					G = Color.G,
					B = Color.B,
				}
			}
		end

		return Keypoints
	else

		-- Extract each keypoint
		local Keypoints = {}

		for Index, Keypoint in pairs(Sequence.Keypoints) do
			Keypoints[Index] = {
				T = Keypoint.Time,
				V = Keypoint.Value
			}
		end

		return Keypoints
	end
end

local function SpringKeypoints(Keypoints, SpringOptions)

	-- Get springed keypoints
	local SpringedKeypoints = {}

	for Index, Keypoint in pairs(Keypoints) do
		
		SpringedKeypoints[Index] = {
			T = Flipper.Spring.new(Keypoint.T, SpringOptions)
		}

		-- Color keypoints
		if typeof(Keypoint.V) == 'table' then
			local Color = Keypoint.V

			SpringedKeypoints[Index].V = {
				R = Flipper.Spring.new(Color.R, SpringOptions),
				G = Flipper.Spring.new(Color.G, SpringOptions),
				B = Flipper.Spring.new(Color.B, SpringOptions)
			}

		-- Number keypoints
		else
			SpringedKeypoints[Index].V = Flipper.Spring.new(Keypoint.V, SpringOptions)
		end
	end

	return SpringedKeypoints
end

return function (self, Description, Theme, ColorAnimationSettings, TransparencyAnimationSettings)

	--- todo: Add a way to determine if the theme wash changed
	-- -- Skip if our current description is the same
	-- if self.Description and (Description.Name == self.Description.Name) then
	-- 	return
	-- end

	-- -- Register
	-- self.Description = Description

	-- Update each style binding
	for _, StyleBinding in pairs(self.StyleBindings) do
		
		-- Get the style key
		local StyleKey = Description[StyleBinding]

		-- Get the style
		local Style = Theme[StyleKey]

		-- Extract initial style, for animation
		local InitialStyle = self[StyleBinding]:getValue()

		-- If no initial, animation isn't noticeable
		if not (InitialStyle and InitialStyle.Color) then
			self['Set' .. StyleBinding](Style)
			continue
		end

		local InitialColor = InitialStyle.Color
		local R, G, B = InitialColor.R, InitialColor.G, InitialColor.B

		-- Remove existing motor, if found
		local ExistingMotor = self[StyleBinding .. 'Motor']
		if ExistingMotor then
			pcall(ExistingMotor.destroy, ExistingMotor)
		end

		-- Extract initial values for motor
		local InitialValues = {
			R = R,
			G = G,
			B = B,
			T = InitialStyle.Transparency,
		}

		-- Color and Transparency sequences
		if InitialStyle.ColorSequence then
			InitialValues.CS = CollectKeypoints(InitialStyle.ColorSequence)
		end

		if InitialStyle.TransparencySequence then
			InitialValues.TS = CollectKeypoints(InitialStyle.TransparencySequence)
		end

		-- Create animation motor
		local Motor = Flipper.GroupMotor.new(InitialValues)

		self[StyleBinding .. 'Motor'] = Motor

		-- Bind motor
		Motor:onStep(function(Values)
			local CS, TS = nil, nil

			-- Build ColorSequence
			if Values.CS then

				-- Build keypoints
				local Keypoints = {}

				for Index, KeypointData in pairs(Values.CS) do
					local Color = KeypointData.V

					Keypoints[Index] = ColorSequenceKeypoint.new(KeypointData.T, Color3.new(Color.R, Color.G, Color.B))
				end

				-- Create sequence
				CS = ColorSequence.new(Keypoints)
			end

			-- Build TransparencySequence
			if Values.TS then
				
				-- Build keypoints
				local Keypoints = {}

				for Index, KeypointData in pairs(Values.TS) do
					Keypoints[Index] = NumberSequenceKeypoint.new(KeypointData.T, KeypointData.V)
				end

				-- Create sequence
				TS = NumberSequence.new(Keypoints)
			end

			-- Update style
			self['Set' .. StyleBinding]({
				Color = Color3.new(Values.R, Values.G, Values.B),
				Transparency = Values.T,
				ColorSequence = Style.ColorSequence, -- todo: fix CS
				TransparencySequence = Style.TransparencySequence, -- todo: fix TS
			})
		end)

		Motor:onComplete(function()
			Motor:destroy()
			self[StyleBinding .. 'Motor'] = nil
		end)

		-- Gather goals
		local Color = Style.Color
		local R, G, B = Color.R, Color.G, Color.B
		local Goals = {
			R = Flipper.Spring.new(R, ColorAnimationSettings),
			G = Flipper.Spring.new(G, ColorAnimationSettings),
			B = Flipper.Spring.new(B, ColorAnimationSettings),
			T = Flipper.Spring.new(Style.Transparency, TransparencyAnimationSettings),
		}

		-- Color and Transparency sequences
		if Style.ColorSequence then
			--Goals.CS = SpringKeypoints(CollectKeypoints(Style.ColorSequence), ColorAnimationSettings)
		end

		if Style.TransparencySequence then
			--Goals.TS = SpringKeypoints(CollectKeypoints(Style.TransparencySequence), TransparencyAnimationSettings)
		end

		-- Play animation
		Motor:setGoal(Goals)
	end
end
