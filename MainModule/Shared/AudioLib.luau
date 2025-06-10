--[[
	Name: AudioLib
	Description: An simple and versatile audio library with getter&setter functions and an immutable data structure.
	Authors: Github@ccuser44/VortexColor & P3tray
	Contributors: Github@ccuser44/VortexColor, P3tray
	Date: 2024
	License: MIT
]]

local AudioLib = {}

function AudioLib.new(object)
	local self = {
		-- // Internal variables
		_sound = nil,
		_defaultSoundName = "AudioLib_Sound",
		_container = nil,
		_connections = {},
		_rawPlaylist = {
			Position = 0
		},
		_proxyProperties = {
			-- // Properties
			"IsLoaded",
			"IsPaused",
			"IsPlaying",
			"Looped",
			"PlaybackLoudness",
			"PlaybackSpeed",
			"Playing",
			"TimeLength",
			"TimePosition",
			"Volume",
			-- // Events
			"DidLoop",
			"Ended",
			"Loaded",
			"Paused",
			"Played"
		},
		_defaultProperties = {
			Looped = false,
			PlaybackSpeed = 1,
			Playing = false,
			SoundId = "",
			TimePosition = 0,
			Volume = 1
		},
		-- // External Variables
		Shuffle = false,
		AutoPlay = false,
		Playlist = {}
	}

	setmetatable(self, {
		__index = AudioLib.__index,
		__newindex = AudioLib.__newindex,
		__tostring = AudioLib.__tostring
	})

	rawset(self, "Playlist", table.freeze(setmetatable(self.Playlist, {
		__index = self._rawPlaylist,
		__len = function()
			return #self._rawPlaylist
		end
	})))

	-- // Allow convienient initializing of AudioLib without having to use setters
	if object:IsA("Sound") then
		self:SetSound(object)
	else
		self:LoadDefault(object)
	end

	return self
end

function AudioLib:__index(k)
	if AudioLib[k] then
		return AudioLib[k]
	elseif table.find(rawget(self, "_proxyProperties"), k) then
		return assert(rawget(self, "_sound"), "Sound missing from audiolib")[k]
	elseif k ~= "_sound" and k ~= "_container" then
		error(tostring(k).." is not a valid member of AudioLib")
	else
		return nil
	end
end

function AudioLib:__newindex(k, v)
	if table.find(rawget(self, "_proxyProperties"), k) then
		assert(rawget(self, "_sound"), "Sound missing from audiolib")[k] = v
	elseif k ~= "_sound" and k ~= "_container" then
		error(tostring(k).." is not a valid member of AudioLib")
	else
		rawset(self, k, v)
	end
end

function AudioLib:__tostring()
	return "AudioLib"
end

function AudioLib:_updateSound(data)
	for k, v in data do
		self._sound[k] = v
	end
end

function AudioLib:GetTrack(position)
	assert(position <= #self._rawPlaylist, "Track position outside of playlist size")
	return self.Playlist[position]
end

function AudioLib:SetTrack(position)
	assert(position <= #self._rawPlaylist, "Track position outside of playlist size")
	self._rawPlaylist.Position = position
	self._sound.SoundId = self.Playlist[position] or ""

	if position == 0 then
		self:Stop()
	end
end

function AudioLib:AddTrack(track, position)
	assert(not position or position <= #self._rawPlaylist, "Track position outside of playlist size")

	if position then
		table.insert(self._rawPlaylist, position, track)

		if position <= self._rawPlaylist.Position then
			self._rawPlaylist.Position += 1
			self:SetTrack(self._rawPlaylist.Position)
		end
	else
		table.insert(self._rawPlaylist, track)
	end
end

function AudioLib:RemoveTrack(position)
	assert(not position or position <= #self._rawPlaylist, "Track position outside of playlist size")
	position = position or #self._rawPlaylist

	table.remove(self._rawPlaylist, position)

	if position <= self._rawPlaylist.Position then
		self._rawPlaylist.Position -= 1
		self:SetTrack(self._rawPlaylist.Position)
	end
end

function AudioLib:SetPlaylist(playlist)
	self:SetTrack(0)
	table.clear(self._rawPlaylist)
	self._rawPlaylist.Position = 0
	table.move(playlist, 1, #playlist, 1, self._rawPlaylist)
end

function AudioLib:GetSound()
	return self._sound
end

function AudioLib:SetSound(sound)
	for _, v in self._connections do -- // Disconnect events from past sounds
		v:Disconnect()
	end

	table.clear(self._connections)
	self._sound = sound
	self:_updateSound(self._defaultProperties)
	table.insert(self._connections, sound.Ended:Connect(function()
		if not self.Looped and self.AutoPlay then
			self:PlayNext()
		end
	end))
end

function AudioLib:Play(soundId)
	if soundId then
		local foundPos = table.find(self._rawPlaylist, soundId)

		if foundPos then
			self:SetTrack(foundPos)
		else
			self:AddTrack(soundId)
			self:SetTrack(#self._rawPlaylist)
		end
	end

	self.TimePosition = 0
	self._sound:Play()
end

function AudioLib:Stop()
	self._sound:Stop()
end

function AudioLib:Pause()
	self._sound:Pause()
end

function AudioLib:Resume()
	self._sound:Resume()
end

function AudioLib:PlayNext()
	if #self.Playlist > 0 then
		self:SetTrack(self.Shuffle and math.random(1, #self.Playlist) or self.Playlist.Position % #self.Playlist + 1)
		self:Play()
	end
end

function AudioLib:GetContainer()
	return self._container
end

function AudioLib:SetContainer(container)
	self._container = container
end

function AudioLib:LoadDefault(container)
	local sound = container:FindFirstChild(self._defaultSoundName)

	if not sound then
		sound = Instance.new("Sound")
		sound.Name = self._defaultSoundName
		sound.Archivable = false
	end

	self:SetSound(sound)
	sound.Parent = container
end

return AudioLib
