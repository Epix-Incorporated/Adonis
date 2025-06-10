client, service = nil, nil

return function(data, env)
	if env then
		setfenv(1, env)
	end

	-- Saving those microseconds from using the dot operator
	local Variables = client.Variables
	local Functions = client.Functions

	-- Some pre-defined "global" variables
	local gTable
	local sImg
	local gImg
	local visualiser = nil
	local isMuted = false
	local isGlobal = false
	local shuffle = false
	local loop = false
	local activeSongList = nil
	local availableSongLists = {}
	local activeSoundIdCache = {}
	local selected = nil
	local persistVolume = 0.25
	local audioLib = nil
	local controlPositionSlider = nil
	local controlVolumeSlider = nil
	local lastSoundIdEvent = nil
	local posTrackSound = nil
	local progressupdatewait = 0.05
	local canUseGlobal = data.GlobalPerms

	if not script:FindFirstChild("Signal") then
		local clone = (client.Shared:FindFirstChild("GoodSignal") or client.Shared:FindFirstChild("Signal")):Clone()
		clone.Name = "Signal"
		clone.Parent = script
	end

	-- The audio visulaiser at the top of the menu.
	local visualiserModule = require(script:FindFirstChild("Visualizer"))
	local sliderModule = require(script:FindFirstChild("Slider"))
	local audioLibModule = Functions.AudioLib or require(client.Shared:FindFirstChild("AudioLib"))
	Functions.AudioLib = audioLibModule
	local localAudioLib = audioLibModule.new(service.UnWrap(service.LocalContainer()))

	local INDEX_LOCALISE = {
		"IsLoaded",
		"IsPaused",
		"IsPlaying",
		"PlaybackLoudness",
		"TimeLength",
		"TimePosition",
		"DidLoop",
		"Ended",
		"Loaded",
		"Paused",
		"Played",
		"Playing"
	}
	-- ========= UGLY HACK to bypass metatable yield restrictions because Roblox is big dumb =========
	-- TODO: Make an RFC on the Luau repo to add yieldable metamethods and xpcall (like Lua 5.2+ has!)
	local defaultValues = localAudioLib._defaultProperties
	local propertyCache = {
		Looped = defaultValues.Looped,
		PlaybackSpeed = defaultValues.PlaybackSpeed,
		Volume = defaultValues.Volume,
		Shuffle = false,
		Autoplay = false
	}
	local fakePlaylist = {Position = 0}
	local getRequestMade = service.Signal.new()

	if canUseGlobal then
		task.spawn(client.Remote.Get, "AudioLib", {"call", "GetSound"}) -- Create default container
	end

	local function compatibilityGet(_, args)
		if args[1] == "index" then
			if propertyCache[args[2]] ~= nil then
				return propertyCache[args[2]]
			elseif args[2] == "Playlist" then
				return fakePlaylist
			else
				error(`The index {args[2]} is not supported with compatibility get!`, 2)
			end
		elseif args[1] == "newindex" then
			propertyCache[args[2]] = args[3]
			getRequestMade:Fire("AudioLib", args)
		elseif args[1] == "call" then
			table.move(args, 4, math.max(4, args.n or #args), 3) -- Get rid of self arg

			if args[2] == "GetContainer" then
				return service.UnWrap(service.SoundService:FindFirstChild("ADONIS_AUDIOLIB"))
			elseif args[2] == "GetSound" then
				return service.UnWrap(
					assert(
						assert(
							service.SoundService:FindFirstChild("ADONIS_AUDIOLIB"),
							"No server AudioLib folder found!"
						):FindFirstChild(localAudioLib._defaultSoundName),
						"No server AudioLib sound object found!"
					)
				)
			elseif args[2] == "GetTrack" then
				assert(args[3] <= #fakePlaylist, "Track position outside of playlist size")
				return fakePlaylist[args[3]]
			elseif args[2] == "SetTrack" then
				assert(args[3] <= #fakePlaylist, "Track position outside of playlist size")
				fakePlaylist.Position = args[3]
			elseif args[2] == "AddTrack" then
				assert(not args[4] or args[4] <= #fakePlaylist, "Track position outside of playlist size")

				if args[3] then
					table.insert(fakePlaylist, args[4], args[3])

					if args[3] <= fakePlaylist.Position then
						fakePlaylist.Position += 1
					end
				else
					table.insert(fakePlaylist, args[3])
				end
			elseif args[2] == "RemoveTrack" then
				assert(not args[3] or args[3] <= #fakePlaylist, "Track position outside of playlist size")
				args[3] = args[3] or #fakePlaylist

				table.remove(fakePlaylist, args[3])

				if args[3] <= fakePlaylist.Position then
					fakePlaylist.Position -= 1
				end
			elseif args[2] == "SetPlaylist" then
				table.clear(fakePlaylist)
				fakePlaylist.Position = 0
				table.move(args[3], 1, #args[3], 1, fakePlaylist)
			end

			getRequestMade:Fire("AudioLib", args)
		end
	end

	getRequestMade:Connect(client.Remote.Get)
	-- ===============================================================================================
	local globalAudioLib = setmetatable({}, {
		__index = function(_, k)
			if type(rawget(audioLibModule, k)) == "function" then
				return function(...)
					return --[[client.Remote.Get]]compatibilityGet("AudioLib", table.pack("call", k, ...))
				end
			elseif table.find(INDEX_LOCALISE, k) then
				return service.UnWrap(
					assert(
						assert(
							service.SoundService:FindFirstChild("ADONIS_AUDIOLIB"),
							"No server AudioLib folder found!"
						):FindFirstChild(localAudioLib._defaultSoundName),
						"No server AudioLib sound object found!"
					)
				)[k]
			else
				return --[[client.Remote.Get]]compatibilityGet("AudioLib", {"index", k})
			end
		end,
		__newindex = function(_, k, v)
			--[[client.Remote.Get]]compatibilityGet("AudioLib", {"newindex", k, v})
		end,
		__tostring = function()
			return "AudioLib"
		end
	})
	audioLib = localAudioLib

	-- Function to run when we close the window
	local function doOnClose()
		audioLib:Stop()
		if visualiser then
			--pcall(visualiser.UnlinkFromSound, visualiser)
			visualiser:Destroy()
			visualiser = nil
		end
		if controlPositionSlider then
			controlPositionSlider:Destroy()
		end
		if controlVolumeSlider then
			controlVolumeSlider:Destroy()
		end
		if visualiserModule then
			visualiserModule = nil
		end
		if sliderModule then
			sliderModule = nil
		end
		if getRequestMade then
			getRequestMade:Destroy()
		end
	end

	-- The when the who the when the window
	local window = client.UI.Make("Window", {
		Name = "Audio Player";
		Title = "Audio Player";
		Size = {420, 400};
		MinSize = {420, 245};
		icon = "http://www.roblox.com/asset/?id=7032721624";
		Position = UDim2.new(0, 10, 1, -410);
		OnClose = function()
			doOnClose()
		end,
		OnMinimized = function(opened)
			if opened and not visualiser.Sound then
				visualiser:LinkToSound(audioLib:GetSound())
			elseif not opened and visualiser.Sound then
				visualiser:UnlinkFromSound()
			end
		end,
	})

	-- The controls frame at the bottom of the window
	local controls = window:Add("Frame", {
		Size = UDim2.new(1, 0, 0, 75);
		Position = UDim2.new(0, 0, 1, -75);
		BackgroundColor3 = Color3.new(0.235294, 0.235294, 0.235294);
		BackgroundTransparency = 0;
	})

	-- Make the window ready before completing any code - Used to allow for delays in loading caused by MarketplaceService.
	gTable = window.gTable
	gTable:Ready()

	-- Song title and Audio Visaliser Frame.
	local heading = window:Add("TextLabel", {
		Text = "Music Player";
		Size = UDim2.new(1,0,0,20);
		BackgroundTransparency = 1;
		TextScaled = true;
		ToolTip = "Music Player";
	})

	local visualiserFrame = window:Add("Frame", {
		Size = UDim2.new(1,0,0,50);
		Position = UDim2.new(0, 0, 0, 30);
		BackgroundTransparency = 1;
		TextScaled = true;
	})

	-- Create audio visualiser
	local visualiser = visualiserModule.new(visualiserFrame, 400)
	visualiser:LinkToSound(audioLib:GetSound())

	-- Play input audio
	if data.Song then
		audioLib.AutoPlay = false
		audioLib:SetPlaylist({})
		audioLib:Play(tonumber(data.Song) and `rbxassetid://{data.Song}` or data.Song)
	end

	-- Mute button
	local muteButton = window:AddTitleButton({
		Text = "";
		OnClick = function()
			if isMuted then
				audioLib.Volume = persistVolume
				sImg.Image = "rbxassetid://1638551696"
				isMuted = false
			else
				persistVolume = audioLib.Volume
				audioLib.Volume = 0
				sImg.Image = "rbxassetid://1638584675";
				isMuted = true
			end
		end
	})

	local function registerSoundIdEvent()
		local rawSound = audioLib:GetSound()
		posTrackSound = rawSound

		if lastSoundIdEvent then
			local button = selected and selected.Button
			if button then
				button.Text = string.gsub(button.Text, "^🔊\u{202F}", "")
			end

			lastSoundIdEvent:Disconnect()
		end

		lastSoundIdEvent = rawSound:GetPropertyChangedSignal("SoundId"):Connect(function()
			local soundId = rawSound.SoundId
			local newSelected = activeSoundIdCache[soundId]
			local numericId = tonumber(string.match(soundId, "(%d+)"))
			local oldButton = selected and selected.Button
			local newButton = newSelected and newSelected.Button

			if oldButton then
				oldButton.Text = string.gsub(oldButton.Text, "^🔊\u{202F}", "")
			end

			if service.Trim(soundId) == "" then
				selected, heading.Text = nil, "Music Player - None"
				return
			elseif selected and selected.ID ~= numericId or not selected then
				heading.Text = `{newSelected and newSelected.Name.." - " or ""}Loading...`
			end

			if newButton then -- Add "Narrow NonBreaking space" to prevent conflicts with speaker emojis in name
				newButton.Text = "🔊\u{202F}" .. string.gsub(newButton.Text, "^🔊\u{202F}", "") 
			end

			local productInfo = numericId and service.GetProductInfo(numericId, Enum.InfoType.Asset)
			local text = productInfo and productInfo.Name or numericId and `[ERROR] {soundId}` or heading.Text
			heading.Text = text
			selected = newSelected or {
				ID = numericId or 0,
				Name = text
			}

			if not audioLib.IsLoaded then
				heading.Text = `({string.sub(text, 1, 10)}...) Loading...`

				audioLib.Loaded:Once(function()
					if rawSound.SoundId == soundId then
						heading.Text = text
					end
				end)
			end
		end)
	end

	local globalButton = nil

	if canUseGlobal then
		globalButton = window:AddTitleButton({
			Text = "";
			OnClick = function()
				audioLib:Stop()
				isGlobal = not isGlobal
				gImg.Image = isGlobal and "rbxassetid://8318257291" or "rbxassetid://8318256297"
				task.spawn(client.UI.Make, "Notification",{
					Title = "Global Audio";
					Icon = "rbxassetid://7541916144";
					Message = isGlobal and "Everyone can hear your music" or "Only you can hear your music";
					Time = 3;
				})
				audioLib = isGlobal and globalAudioLib or localAudioLib
				audioLib:Stop()
				visualiser:LinkToSound(audioLib:GetSound())
				registerSoundIdEvent()
			end
		})
		gImg = globalButton:Add("ImageLabel", {
			Size = UDim2.new(1, 0, 1 ,0);
			Position = UDim2.new(0, 0, 0, 0);
			Image = "rbxassetid://8318256297";
			BackgroundTransparency = 1;
		})
	end

	sImg = muteButton:Add("ImageLabel", {
		Size = UDim2.new(1, 0, 1 ,0);
		Position = UDim2.new(0, 0, 0, 0);
		Image = "rbxassetid://1638551696";
		BackgroundTransparency = 1;
	})

	local function getRawPlaylist(playlist)
		local rawPlaylist = table.create(#playlist)

		for i, v in ipairs(playlist) do
			rawPlaylist[i] = `rbxassetid://{v.ID}`
		end

		return rawPlaylist
	end

	local function fillSoundIdCache(playlist)
		for _, v in playlist do
			activeSoundIdCache[`rbxassetid://{v.ID}`] = v
		end
	end

	-- Function that makes the song list.
	local function getSongs(tab, list)
		local num = 0
		selected = nil
		availableSongLists[tab.Name] = {}
		tab:ClearAllChildren()
	
		local frame = tab:Add("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 1);
			Position = UDim2.new(0, 0, 0, 0);
			BackgroundColor3 = Color3.new(0.235294, 0.235294, 0.235294);
			BackgroundTransparency = 1;
		})
	
		local loading = frame:Add("TextLabel", {
			Text = "Loading nothing yet!";
			ToolTip = "Never gonna give you up, Never gonna let you down...";
			BackgroundTransparency = 0.5;
			Size = UDim2.new(1,0,1,0);
			Position = UDim2.new(0,0,0,0);
			ZIndex = 69420;
			--TextXAlignment = "Left";
		})
	
		local function loop(i, v)
			if type(v) == "table" then
				local productInfo = service.GetProductInfo(v.ID, Enum.InfoType.Asset)
	
				if num + 1 >= #list then
					loading:Destroy()
				elseif loading then
					loading.Text = `Loading tracks ({num + 1}/{#list})`
					loading.Active = false
				end
	
				if productInfo.AssetTypeId == 3 or productInfo.Created == false then
					local trackPos = num + 1
					table.insert(availableSongLists[tab.Name], v)
	
					v.Button = frame:Add("TextButton", {
						Text = `  {num + 1}) {productInfo.Name or `[ERROR] {v.Name}`}`;
						ToolTip = `Name: {v.Name} | ID: {v.ID}`;
						Size = UDim2.new(1, 0, 0, 25);
						Position = UDim2.new(0, 0, 0, num*25);
						BackgroundTransparency = (num%2 == 0 and 0) or 0.2;
						TextXAlignment = "Left";
						OnClicked = function(button)
							if activeSoundIdCache.listName ~= tab.Name then
								table.clear(activeSoundIdCache)
								activeSoundIdCache.listName = tab.Name
								fillSoundIdCache(availableSongLists[tab.Name])
							end
	
							heading.Text = productInfo.Name or v.Name
							audioLib.AutoPlay = true
							audioLib:SetPlaylist(getRawPlaylist(availableSongLists[tab.Name]))
							audioLib:SetTrack(trackPos)
							audioLib:Play()
						end
					})
					num = trackPos
					frame:ResizeCanvas(false, true)
				end
			end
		end
	
		for i, v in ipairs(list or {}) do
			task.spawn(xpcall, loop, warn, i, v)
		end
	
		service.Debris:AddItem(loading, 10)
	end

	-- Tabs for different playlists
	local tabFrame = window:Add("TabFrame",{
		Size = UDim2.new(1, 0, 1, -165);
		Position = UDim2.new(0, 0, 0, 90);
	})

	local personalTab = tabFrame:NewTab("Personal",{
		Text = "Personal";
		OnFocus = function()
			activeSongList = availableSongLists["Personal"] or {}
		end;
	})
	local gameTab = tabFrame:NewTab("Game",{
		Text = "Game";
		OnFocus = function()
			activeSongList = availableSongLists["Game"] or {}
		end;
	})
	local adonisTab = tabFrame:NewTab("Adonis", {
		Text = "Adonis";
		OnFocus = function()
			activeSongList = availableSongLists["Adonis"] or {}
		end;
	})
	local customTab = tabFrame:NewTab("Custom", {
		Text = "Custom";
		OnFocus = function()
			activeSongList = availableSongLists["Custom"] or {}
		end;
	})

	--  The Custom Playlists editor window
	local binderBox, playlistBox; binderBox = tabFrame:Add("Frame", {
		Visible = false;
		Size = UDim2.new(1,0,1,0);
		Position = UDim2.new(0,0,0,0);
		BackgroundTransparency = 0;
		ZIndex = 10000;
		Children = {
			{
				Class = "TextLabel";
				Text = "New Custom Playlist string:";
				Position = UDim2.new(0, 5, 0, 5);
				Size = UDim2.new(1, -10, 0, 30);
				BackgroundTransparency = 0;
				ZIndex = 10001;
			};
			{
				Class = "TextButton";
				Text = "Add";
				Position = UDim2.new(0.5, 5, 1, -35);
				Size = UDim2.new(0.5, -10, 0, 30);
				BackgroundTransparency = 0;
				ZIndex = 10002;
				OnClicked = function()
					client.Variables.Playlist = {Playlist = {}}
					table.clear(client.Variables.Playlist.Playlist)
					for name, id in string.gmatch(string.gsub(playlistBox.Text, "%s", ""), "([^:,]+):(%d+),?") do
						table.insert(client.Variables.Playlist.Playlist, {
							Name = name or "UNKNOWN",
							ID = tonumber(id) or 0
						})
					end
					binderBox.Visible = false
					getSongs(customTab, client.Variables.Playlist.Playlist or {})
					activeSongList = availableSongLists["Custom"] or {}
				end
			};
			{
				Class = "TextButton";
				Text = "Cancel";
				Position = UDim2.new(0, 5, 1, -35);
				Size = UDim2.new(0.5, -5, 0, 30);
				BackgroundTransparency = 0;
				ZIndex = 10003;
				OnClicked = function()
					binderBox.Visible = false
				end
			};
		}
	})

	playlistBox = binderBox:Add("TextBox", {
		Position = UDim2.new(0, 5, 0, 40);
		Size = UDim2.new(1, -10, 1, -80);
		TextWrapped = true;
		--TextXAlignment = "Left";
		--TextYAlignment = "Top";
		ClearTextOnFocus = false;
		PlaceholderText = "NAME:ID, SECOND:12398801, HeavyIsDead:4881542521";
		ZIndex = 10004;
	})

	playlistBox.BackgroundColor3 = playlistBox.BackgroundColor3:lerp(Color3.new(1, 1, 1), 0.1)
	binderBox.BackgroundColor3 = binderBox.BackgroundColor3:lerp(Color3.new(1, 1, 1), 0.05)

	--[[

	========================================================
	|                                                      |
	| Top control buttons (Save and load custom playlist)  |
	|                                                      |
	========================================================

	]]--

	-- Create playlist button
	local playlistLoad = controls:Add("TextButton", {
		Text = "⏫";
		TextSize = 15;
		ToolTip = "Create playlist: Create a new custom playlist from a string.";
		BackgroundTransparency = 0;
		Size = UDim2.new(0, 30, 0, 30);
		Position = UDim2.new(0, 5, 0, 5);
		TextXAlignment = "Center";
		OnClicked = function()
			playlistBox.Text = ""
			binderBox.Visible = true
			customTab:FocusTab();
			activeSongList = availableSongLists["Custom"] or {}
		end
	})

	-- Save cutom playlist
	local playlistSave = controls:Add("TextButton", {
		Text = "⬆️";
		TextSize = 15;
		ToolTip = "Upload playlist: Saves your custom playlist to the games datastore.";
		BackgroundTransparency = 0;
		Size = UDim2.new(0, 30, 0, 30);
		Position = UDim2.new(0, 40, 0, 5);
		TextXAlignment = "Center";
		OnClicked = function()
			personalTab:FocusTab();
			local Playlist = type(client.Variables.Playlist) == "table" and client.Variables.Playlist.Playlist
			if Playlist and next(Playlist) then
				client.Functions.UpdatePlaylist(client.Variables.Playlist)
				getSongs(personalTab, client.Functions.Playlist().Playlist or {})
			else
				warn("[ERROR] Cannot update empty Playlist")
			end

			activeSongList = availableSongLists["Personal"] or {}
		end
	})

	-- Stop button
	local controlStop = controls:Add("TextButton", {
		Text = "⏹";
		TextSize = 15;
		ToolTip = "Stop: Pauses the track and sets the position to 0.";
		BackgroundTransparency = 0;
		Size = UDim2.new(0, 30, 0, 30);
		Position = UDim2.new(0, 75, 0, 5);
		TextXAlignment = "Center";
		OnClick = function()
			audioLib:Stop()
		end
	})

	-- Back button
	local controlBack = controls:Add("TextButton", {
		Text = "◀️";
		TextSize = 15;
		ToolTip = "Back: Go back to the last played track.";
		BackgroundTransparency = 0;
		Size = UDim2.new(0, 30, 0, 30);
		Position = UDim2.new(0, 110, 0, 5);
		TextXAlignment = "Center";
		OnClick = function()
			local playlist = audioLib.Playlist
			audioLib:SetTrack((playlist.Position - 2) % #playlist + 1)
			audioLib:Play()
		end
	})

	-- Pause/Play button
	local controlPausePlay = controls:Add("TextButton", {
		Text = "⏯️";
		TextSize = 15;
		ToolTip = "Pause/Play: Control the tracks playing state.";
		BackgroundTransparency = 0;
		Size = UDim2.new(0, 30, 0, 30);
		Position = UDim2.new(0, 145, 0, 5);
		TextXAlignment = "Center";
		OnClick = function()
			if audioLib.Playing then
				audioLib:Pause()
			else
				audioLib:Resume()
			end
		end
	})

	-- Forward button
	local controlForward = controls:Add("TextButton", {
		Text = "▶️";
		TextSize = 15;
		ToolTip = "Forward: Skip to the next track.";
		BackgroundTransparency = 0;
		Size = UDim2.new(0, 30, 0, 30);
		Position = UDim2.new(0, 180, 0, 5);
		TextXAlignment = "Center";
		OnClick = function()
			audioLib:PlayNext()
		end
	})

	-- Shuffle button
	local controlShuffle = nil
	local controlShuffleBackgroundColor3 = nil
	local function changeShuffleColor()
		if shuffle then
			controlShuffle.BackgroundColor3 = Color3.new(0, 1, 0.6)
		else
			controlShuffle.BackgroundColor3 = controlShuffleBackgroundColor3
		end
	end
	controlShuffle = controls:Add("TextButton", {
		Text = "🔀";
		TextSize = 15;
		ToolTip = "Shuffle: Randomly pick between.";
		BackgroundTransparency = 0;
		Size = UDim2.new(0, 30, 0, 30);
		Position = UDim2.new(0, 215, 0, 5);
		TextXAlignment = "Center";
		OnClick = function()
			shuffle = not shuffle
			audioLib.Shuffle = shuffle
			changeShuffleColor()
		end
	})

	controlShuffleBackgroundColor3 = controlShuffle.BackgroundColor3

	-- Loop button
	local controlLoop = nil
	local controlLoopBackgroundColor3 = nil
	local function changeLoopColor()
		if loop then
			controlLoop.BackgroundColor3 = Color3.new(0, 1, 0.6)
		else
			controlLoop.BackgroundColor3 = controlLoopBackgroundColor3
		end
	end
	controlLoop = controls:Add("TextButton", {
		Text = "🔁";
		TextSize = 15;
		ToolTip = "Loop: Loops the song continuously.";
		BackgroundTransparency = 0;
		Size = UDim2.new(0, 30, 0, 30);
		Position = UDim2.new(0, 250, 0, 5);
		TextXAlignment = "Center";
		OnClick = function()
			loop = not loop
			changeLoopColor()
			audioLib.Looped = loop
		end
	})
	controlLoopBackgroundColor3 = controlLoop.BackgroundColor3

	-- Bottom control buttons

	-- Custom Sound ID
	local controlID = controls:Add("TextLabel", {
		Text = "  ID: ";
		ToolTip = "ID: The Sound ID from the roblox catalogue.";
		BackgroundTransparency = 0;
		Size = UDim2.new(0, 120, 0, 30);
		Position = UDim2.new(1, -125, 0, 5);
		TextXAlignment = "Left";
		Children = {
			TextBox = {
				Text = "";
				PlaceholderText = "4881542521";
				Size = UDim2.new(0, 80, 1, 0);
				Position = UDim2.new(1, -90, 0, 0);
				BackgroundTransparency = 1;
				TextXAlignment = "Right";
				TextChanged = function(text, enter, new)
					text = service.Trim(text)

					if enter then
						audioLib.AutoPlay = false
						audioLib:SetPlaylist({})
						audioLib:Play(tonumber(text) and `rbxassetid://{text}` or text)
					end
				end
			}
		}
	})

	-- Position
	--local controlPosition = controls:Add("TextLabel", {
	--	Text = "  Pos: ";
	--	ToolTip = "Position: Set the audio's position (In seconds).";
	--	BackgroundTransparency = 0;
	--	Size = UDim2.new(0, 60, 0, 30);
	--	Position = UDim2.new(1, -205, 1, -35);
	--	TextXAlignment = "Left";
	--	Children = {
	--		TextBox = {
	--			Text = "";
	--			PlaceholderText = "0";
	--			Size = UDim2.new(0, 40, 1, 0);
	--			Position = UDim2.new(1, -50, 0, 0);
	--			BackgroundTransparency = 1;
	--			TextXAlignment = "Right";
	--			TextChanged = function(text, enter, new)
	--				if enter then
	--					audioLib("UpdateSound", {
	--						TimePosition = text
	--					})
	--				end
	--			end
	--		}
	--	}
	--})

	--[[

	========================================================
	|                                                      |
	| Bottom control buttons (Position and volume slider)  |
	|                                                      |
	========================================================

	]]--

	-- Volume
	local controlVolume = controls:Add("TextLabel", {
		Text = "   ";
		ToolTip = "Volume: How loud the audio will play (0 to 10).";
		BackgroundTransparency = 0;
		Size = UDim2.new(0, 120, 0, 30);
		Position = UDim2.new(1, -125, 1, -35);
		TextXAlignment = "Left";
	})

	controlVolume:Add("ImageLabel", {
		Image = "rbxassetid://7541896266";
		Size = UDim2.new(0, 20, 0, 20);
		Position = UDim2.new(0, 5, 0, 5);
		BackgroundTransparency = 1;
	})

	local controlVolumeSliderContainer = controlVolume:Add("Frame", {
		Image = "rbxassetid://7541896266";
		Size = UDim2.new(1, -45, 0, 2);
		Position = UDim2.new(0, 30, 0, 14);
		BackgroundColor3 = Color3.new(0.454902, 0.454902, 0.454902);
		BackgroundTransparency = 0;
	})

	local controlVolumeSliderInstance = controlVolumeSliderContainer:Add("ImageButton", {
		Name = "Slider";
		AnchorPoint = Vector2.new(0.5, 0.5);
		Size = UDim2.new(0, 10, 0, 10);
		Position = UDim2.new(0, 0, 0, -4);
		BackgroundColor3 = Color3.new(1,1,1);
		BackgroundTransparency = 0;
		TextXAlignment = "Right";
		Children = {
			UICorner = {
				CornerRadius = UDim.new(1, 0);
			}
		}
	})

	controlVolumeSlider = sliderModule.new(service.UnWrap(controlVolumeSliderContainer), {
		SliderData = {Start = 0, End = 1000, Increment = 1, DefaultValue = 0.5},
		MoveInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad),
		Axis = "X",
		Padding = 0
	})
	controlVolumeSlider:Track()

	do
		local lastSliderChange = -math.huge
		controlVolumeSlider.Changed:Connect(function(value)
			if not isGlobal or os.clock() > lastSliderChange + 0.5 then -- Prevent spamming of remotes with global AudioLib
				lastSliderChange = os.clock()
				audioLib.Volume = value / 100
			end
		end)
	end

	-- Track position
	local controlPosition = controls:Add("TextLabel", {
		Text = "   ";
		ToolTip = "Position: Control where the song is playing from.";
		BackgroundTransparency = 0;
		Size = UDim2.new(1, -135, 0, 30);
		Position = UDim2.new(0, 5, 1, -35);
		TextXAlignment = "Left";
	})

	local controlPositionSliderContainer = controlPosition:Add("Frame", {
		Image = "rbxassetid://7541896266";
		Size = UDim2.new(1, -30, 0, 2);
		Position = UDim2.new(0, 14, 0, 14);
		BackgroundColor3 = Color3.new(0.454902, 0.454902, 0.454902);
		BackgroundTransparency = 0;
	})

	local controlPositionSliderInstance = controlPositionSliderContainer:Add("ImageButton", {
		Name = "Slider";
		AnchorPoint = Vector2.new(0.5, 0.5);
		Size = UDim2.new(0, 10, 0, 10);
		Position = UDim2.new(0, 0, 0, -4);
		BackgroundColor3 = Color3.new(1,1,1);
		BackgroundTransparency = 0;
		TextXAlignment = "Right";
		Children = {
			UICorner = {
				CornerRadius = UDim.new(1, 0);
			}
		}
	})

	controlPositionSlider = sliderModule.new(service.UnWrap(controlPositionSliderContainer), {
		SliderData = {Start = 0, End = 10000, Increment = 1, DefaultValue = 0.5},
		MoveInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad),
		Axis = "X",
		Padding = 0
	})
	controlPositionSlider:Track()

	do
		local lastSliderChange = -math.huge
		controlPositionSlider.Changed:Connect(function(value)
			if not isGlobal or os.clock() > lastSliderChange + 0.5 then -- Prevent spamming of remotes with global AudioLib
				local length = audioLib.TimeLength
				lastSliderChange = os.clock()
				audioLib.TimePosition = value / 10000 * length
			end
		end)
	end

	-- Used to play a sound on window open. 4881542521.

	-- Load in track lists
	local loadingMessage = function(tab)
		tab:Add("TextLabel", {
			Text = "Waiting in queue to load tracks...";
			ToolTip = "Never gonna give you up, Never gonna let you down...";
			BackgroundTransparency = 0;
			Size = UDim2.new(1,0,1,0);
			Position = UDim2.new(0,0,0,0);
			ZIndex = 69420
			--TextXAlignment = "Left";
		})
	end

	loadingMessage(personalTab)
	loadingMessage(gameTab)
	loadingMessage(adonisTab)
	registerSoundIdEvent()
	getSongs(personalTab, client.Functions.Playlist().Playlist or {})
	local musicList = client.Remote.Get("Variable", "MusicList") or {}
	getSongs(gameTab, musicList)
	getSongs(adonisTab, table.move(service.DeepCopy(musicList), 1, #musicList - #(client.Remote.Get("Setting", "MusicList") or {}), 1, {}))
	activeSongList = availableSongLists["Personal"] or {}

	task.spawn(function()
		while task.wait(progressupdatewait) do
			if posTrackSound and posTrackSound.TimeLength ~= 0 and not controlPositionSlider.IsHeld then
				controlPositionSlider:OverrideValue(posTrackSound.TimePosition / posTrackSound.TimeLength * 10000, true)
			end
		end
	end)
end
