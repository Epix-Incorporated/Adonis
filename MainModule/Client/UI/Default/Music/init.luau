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
	local song = data.Song
	local sImg
	local gImg
	local visualiserModule = nil
	local visualiser = nil
	local isMuted = false
	local isGlobal = false
	local activeSongList = nil
	local availableSongLists = {}
	local selected = nil
	local shuffle = false
	local loop = false
	local soundInstanceEndedEvent = nil
	local persistVolume = 0.25
	local audioLib = nil
	local controlPositionSlider = nil
	local progressupdatewait = 0.05
	local canUseGlobal = data.GlobalPerms

	-- The audio visulaiser at the top of the menu.

	local visualiserModule = require(script:FindFirstChild("Visualizer"))
	local sliderModule = require(script:FindFirstChild("Slider"))
	local localAudioLib = client.Shared:FindFirstChild("AudioLib")
	localAudioLib = require(localAudioLib).new(service.UnWrap(service.LocalContainer()))

	local localAudioLibFunction = function(func, args)
		return localAudioLib[func](localAudioLib, args)
	end
	audioLib = localAudioLibFunction


	-- Function to run when we close the window

	local function doOnClose()
		if visualiser then
			visualiser:UnlinkFromSound()
			visualiser:Destroy()
			visualiser = nil
		end
		if visualiserModule then
			visualiserModule = nil
		end
		audioLib("UpdateSound", {
			Playing = false;
		})
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
		end
	})

	-- The controls frame at the bottom of the window

	local controls = window:Add("Frame", {
		Size = UDim2.new(1, 0, 0, 75);
		Position = UDim2.new(0, 0, 1, -75);
		BackgroundColor3 = Color3.new(0.235294, 0.235294, 0.235294);
		BackgroundTransparency = 0;
	})

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
		--Text = "";
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

	local controlVolumeSlider = sliderModule.new(service.UnWrap(controlVolumeSliderContainer), {Start = 0, End = 1000, Increment = 1, DefaultValue = 0.5}, TweenInfo.new(0.1, Enum.EasingStyle.Quad), "X", 0)
	controlVolumeSlider:Track()

	controlVolumeSlider.Changed:Connect(function(value)
		audioLib("UpdateSound", {
			Volume = value / 100;
		})
	end)

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

	local controlPositionSlider = sliderModule.new(service.UnWrap(controlPositionSliderContainer), {Start = 0, End = 10000, Increment = 1, DefaultValue = 0.5}, TweenInfo.new(0.1, Enum.EasingStyle.Quad), "X", 0)
	controlPositionSlider:Track()

	controlPositionSlider.Changed:Connect(function(value)
		local length = audioLib("GetSound").TimeLength
		audioLib("UpdateSound", {
			TimePosition = value / 10000 * length;
		})
	end)

	-- Make the window ready before completing any code - Used to allow for delays in loading caused by MarketplaceService.

	gTable = window.gTable
	gTable:Ready()

	local function newTrackSelected(v)
		local sound = audioLib("UpdateSound", {
			SoundId = `rbxassetid://{v.ID}`;
			Playing = true;
			TimePosition = 0;
		})
	end
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

	-- Create audio vislualiser

	local visualiser = visualiserModule.new(visualiserFrame, 400)
	visualiser:LinkToSound(audioLib("GetSound"))
	if song then audioLib("UpdateSound", {
		SoundId = `rbxassetid://{song}`;
		Playing = true;
		TimePosition = 0;
		})
	end

	-- Mute button

	local muteButton = window:AddTitleButton({
		Text = "";
		OnClick = function()

			if isMuted then
				audioLib("UpdateSound", {
					Volume = persistVolume;
				})
				sImg.Image = "rbxassetid://1638551696"
				isMuted = false
			else
				persistVolume = audioLib("GetSound").Volume
				audioLib("UpdateSound", {
					Volume = 0;
				})
				sImg.Image = "rbxassetid://1638584675";
				isMuted = true
			end
		end
	})

	local globalButton = nil

	if canUseGlobal then
		globalButton = window:AddTitleButton({
			Text = "";
			OnClick = function()
				audioLib("UpdateSound", {
					Playing = false;
					TimePosition = 0;
				})
				if isGlobal then
					gImg.Image = "rbxassetid://8318256297"
					isGlobal = false
					task.spawn(client.UI.Make, "Notification",{
						Title = "Global Audio";
						Icon = "rbxassetid://7541916144";
						Message = "Only you can hear your music";
						Time = 3;
					})

					audioLib = localAudioLibFunction
					audioLib("UpdateSound", {
						Playing = false;
						TimePosition = 0;
					})
					visualiser:LinkToSound(audioLib("GetSound"))
					progressupdatewait = 0.05

				else
					--updateAudio({Global = true})
					gImg.Image = "rbxassetid://8318257291";
					isGlobal = true
					task.spawn(client.UI.Make, "Notification",{
						Title = "Global Audio";
						Icon = "rbxassetid://7541916144";
						Message = "Everyone can hear your music";
						Time = 3;
					})
					audioLib = function(func, args)
						return client.Remote.Get("AudioLib", {func, args})
					end
					audioLib("UpdateSound", {
						Playing = false;
						TimePosition = 0;
					})
					visualiser:LinkToSound(audioLib("GetSound"))
					progressupdatewait = 2
				end
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

	-- Function that makes the song list.

	local function getSongs(tab, list)
		local num = 0
		selected = nil
		if availableSongLists and availableSongLists[tab.Name] then availableSongLists[tab.Name] = nil end
		if soundInstanceEndedEvent then soundInstanceEndedEvent:Disconnect() end

		tab:ClearAllChildren();

		local frame = tab:Add("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 1);
			Position = UDim2.new(0, 0, 0, 0);
			BackgroundColor3 = Color3.new(0.235294, 0.235294, 0.235294);
			BackgroundTransparency = 1;
		})

		local loading = frame:Add("TextLabel", {
			Text = "Loading nothing yet!";
			ToolTip = "Never gonna give you up, Never gonna let you down...";
			BackgroundTransparency = 0;
			Size = UDim2.new(1,0,1,0);
			Position = UDim2.new(0,0,0,0);
			ZIndex = 69420
			--TextXAlignment = "Left";
		})

		availableSongLists[tab.Name] = {}

		local function loop(i,v)
			if type(v) == "table" then
				loading.Text = `Loading tracks ({i}/{#list})`;
				local success, product_info = pcall(function()
					return service.MarketplaceService:GetProductInfo(v.ID, Enum.InfoType.Asset)
				end)
				if product_info.AssetTypeId == 3 then
					table.insert(availableSongLists[tab.Name], v)
					frame:Add("TextButton", {
						Text = `  {num + 1}) {success and product_info.Name or `[ERROR] {v.Name}`}`;
						ToolTip = `Name: {v.Name} | ID: {v.ID}`;
						Size = UDim2.new(1, 0, 0, 25);
						Position = UDim2.new(0, 0, 0, num*25);
						BackgroundTransparency = (num%2 == 0 and 0) or 0.2;
						TextXAlignment = "Left";
						OnClicked = function(button)
							if selected and selected.Button then
								selected.Button.BackgroundTransparency = 0
							end
							button.BackgroundTransparency = 0.5

							heading.Text = success and product_info.Name or v.Name
							selected = {
								ID = v.ID,
								Name = v.Name,
								Button = button,
								Index = i
							}

							newTrackSelected(v)
						end
					})
					frame:ResizeCanvas(false, true)
				end
			end
			num = num + 1
		end

		for i,v in next,(list  or {}) do
			task.spawn(loop, i, v)
		end

		local sound = Variables.localSounds["AUDIO_PLAYER_SOUND"]

		if sound then
			soundInstanceEndedEvent = sound.Ended:Connect(function()
				if activeSongList and selected then
					if shuffle then
						local rnum
						repeat rnum = math.random(#activeSongList) until (rnum ~= selected.Index or #activeSongList <= 1)
						local toPlay = activeSongList[(rnum)]
						if toPlay then
							audioLib("UpdateSound", {
								SoundId = `rbxassetid://{toPlay.ID}`;
								Playing = true;
								TimePosition = 0;
							})
							local success, product_info = pcall(function()
								return service.MarketplaceService:GetProductInfo(toPlay.ID, Enum.InfoType.Asset)
							end)
							heading.Text = success and product_info.Name or `[ERROR] {toPlay.Name}`
							selected = {
								ID = toPlay.ID,
								Name = toPlay.Name,
								Button = nil,
								Index = rnum
							}
						end
					else
						local toPlay = activeSongList[(selected.Index +1)]
						if toPlay then
							audioLib("UpdateSound", {SoundId = `rbxassetid://{toPlay.ID}`;
								Playing = true;
								TimePosition = 0;
							})

							local success, product_info
							local count = 0 --1

							while not success do --2
								if count >= 1 then
									wait(1) --4
								end

								success, product_info = pcall(service.MarketplaceService.GetProductInfo, service.MarketplaceService, toPlay.ID, Enum.InfoType.Asset) --5
								count = count + 1 --6
							end

							--local success, product_info = nil, nil
							--repeat pcall(function()
							--	success, product_info = service.MarketplaceService:GetProductInfo(toPlay.ID, Enum.InfoType.Asset)
							--	return success, product_info
							--end) until success == true
							heading.Text = success and product_info.Name or `[ERROR] {toPlay.Name}`
							selected = {
								ID = toPlay.ID,
								Name = toPlay.Name,
								Button = nil,
								Index = selected.Index +1
							}
						end
					end
				end
			end)
		end
		loading:Destroy()
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

	local binderBox; binderBox = tabFrame:Add("Frame", {
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

	local PlaylistBox = binderBox:Add("TextBox", {
		Position = UDim2.new(0, 5, 0, 40);
		Size = UDim2.new(1, -10, 1, -80);
		TextWrapped = true;
		--TextXAlignment = "Left";
		--TextYAlignment = "Top";
		ClearTextOnFocus = false;
		PlaceholderText = "NAME:ID, SECOND:12398801, HeavyIsDead:4881542521";
		ZIndex = 10004;
		TextChanged = function(newText, enter, box)
			client.Variables.Playlist = {Playlist = {}}
			for v in pairs(client.Variables.Playlist.Playlist) do
				client.Variables.Playlist.Playlist[v] = nil
			end
			for i,v in next,(string.split(string.gsub(newText, " ", ""), ",")) do
				local split = string.split(v, ":")
				table.insert(client.Variables.Playlist.Playlist, (#client.Variables.Playlist.Playlist + 1), {
					Name = tostring(split[1]),
					ID = tonumber(split[2])
				})
			end
			binderBox.Visible = false
			getSongs(customTab, (client.Variables.Playlist.Playlist or {}))
			activeSongList = availableSongLists["Custom"] or {}
		end
	})

	PlaylistBox.BackgroundColor3 = PlaylistBox.BackgroundColor3:lerp(Color3.new(1, 1, 1), 0.1)
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
			PlaylistBox.Text = ""
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
				getSongs(personalTab, ((client.Functions.Playlist()).Playlist or {}))
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
			audioLib("UpdateSound", {
				Playing = false;
				TimePosition = 0;
			})
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
			if audioLib("GetSound") then
				audioLib("UpdateSound", {
					Playing = not audioLib("GetSound").Playing
				})
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

		end
	})

	-- Forward button

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
			audioLib("UpdateSound", {
				Looped = loop;
			})
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
					if enter then
						audioLib("UpdateSound", {
							SoundId = `rbxassetid://{text}`;
							Playing = true;
							TimePosition = 0;
						})
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
		--Text = "";
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

	local controlVolumeSlider = sliderModule.new(service.UnWrap(controlVolumeSliderContainer), {Start = 0, End = 1000, Increment = 1, DefaultValue = 0.5}, TweenInfo.new(0.1, Enum.EasingStyle.Quad), "X", 0)
	controlVolumeSlider:Track()

	controlVolumeSlider.Changed:Connect(function(value)
		audioLib("UpdateSound", {
			Volume = value / 100;
		})
	end)

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

	local controlPositionSlider = sliderModule.new(service.UnWrap(controlPositionSliderContainer), {Start = 0, End = 10000, Increment = 1, DefaultValue = 0.5}, TweenInfo.new(0.1, Enum.EasingStyle.Quad), "X", 0)
	controlPositionSlider:Track()

	controlPositionSlider.Changed:Connect(function(value)
		local length = audioLib("GetSound").TimeLength
		audioLib("UpdateSound", {
			TimePosition = value / 10000 * length;
		})
	end)

	-- Used to play a sound on window open. 4881542521.

	-- Create OnClose event after everything has been initialised

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
	getSongs(personalTab, ((client.Functions.Playlist()).Playlist or {}))
	getSongs(gameTab, (client.Remote.Get("Variable", "MusicList") or {}))
	getSongs(adonisTab, (client.Remote.Get("Variable", "MusicList") or {}))
	activeSongList = availableSongLists["Personal"] or {}

	task.spawn(function()
		local tempsound = audioLib("GetSound")
		while task.wait(progressupdatewait) do
			tempsound = audioLib("GetSound")
			if tempsound and tempsound.TimeLength ~= 0 then
				controlPositionSlider:OverrideVisualValue(tempsound.TimePosition / tempsound.TimeLength * 10000)
			end
		end
	end)
end
