local function usingNewIAS()
	local playerScripts = game.Players.LocalPlayer.PlayerScripts
	local starterPlayer = game.StarterPlayer

	local playerScriptsModule = playerScripts:FindFirstChild("PlayerModule")
	local starterPlayerModule = starterPlayer:FindFirstChild("PlayerModule")

	if playerScriptsModule and not starterPlayerModule then
		return false

	elseif starterPlayerModule and not playerScriptsModule then
		return true

	else
		-- ??
		return false
	end
end

if usingNewIAS() then
	script.FreecamNew.Enabled = true
else
	script.FreecamLegacy.Enabled = true
end