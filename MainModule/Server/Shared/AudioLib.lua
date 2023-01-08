local AudioLib = {}

function AudioLib.new(container)
	local self = {}

	self.DefaultProperties = {
		Children = nil;

		Looped = false;
		PlaybackSpeed = 1;
		Playing = false;
		SoundId = nil;
		TimePosition = 0;
		Volume = 0.25;
	}

	self.Playlist = {}
	self.Shuffle = false

    --// Retrieve the sound used for playing all music
	function self:GetSound()
		return self.Sound
	end

    --// Loops through a table of properties used to overwrite those of an existing instance.
	function self:UpdateSound(data)
		for property,value in data do
			self.Sound[property] = value
		end
		return self.Sound
	end

    --// Loads the next song in the playlist
	function self:SoundEnded()
		if #self.Playlist > 0 then
			local index = table.find(self.Playlist, self.Sound.SoundId)
			if self.Shuffle then index = math.random(0, #self.Playlist) end
			if (index + 1) > #self.Playlist then
				index = 0
			end
			self.Sound.SoundId = self.Playlist[index + 1]
		end
	end

	container = workspace:FindFirstChild(container.Name)
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
