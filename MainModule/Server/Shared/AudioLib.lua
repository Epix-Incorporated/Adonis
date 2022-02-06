local AudioLib = {}
--AudioLib.__index = function(s, i) return s[i] end

function AudioLib.new(container)
	local self = {}
	
	self.DefaultProperties = {
		Children = nil;
		--ClearAllChildren = true;

		Looped = false;
		PlaybackSpeed = 1;
		Playing = false;
		SoundId = nil;
		TimePosition = 0;
		Volume = 0.25;
	}

	self.Playlist = {}
	self.Shuffle = false
	
	function self:GetSound() -- Retrieve the sound used for playing all music
		return self.Sound
	end

	function self:UpdateSound(data) -- Loops through a table of properties used to overwrite those of an existing instance.
		for property,value in pairs(data) do
			self.Sound[property] = value
		end
	end

	function self:SoundEnded() -- Loads the next song in the playlist
		if #self.Playlist > 0 then
			local index = table.find(self.Playlist, self.Sound.SoundId)
			if self.Shuffle then index = math.random(0, #self.Playlist) end
			if (index + 1) > #self.Playlist then 
				index = 0
			end
			self.Sound.SoundId = self.Playlist[index + 1]
		end
	end
	
	local container = workspace:FindFirstChild(container.Name)
	self.Sound = container:FindFirstChild("AudioLib_Sound")
	if not self.Sound then
		self.Sound = Instance.new("Sound")
		self.Sound.Name = "AudioLib_Sound"
		self.Sound.Parent = container -- Don't ask me why I have to do this.
		self.Sound.Ended:Connect(function() self:SoundEnded() end)
		self:UpdateSound(self.DefaultProperties)
	end
	return self
end

return AudioLib
