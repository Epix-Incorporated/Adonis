local setmetatable = setmetatable
local tostring = tostring
local getfenv = getfenv
local setfenv = setfenv
local unpack = unpack
local xpcall = xpcall 
local script = script
local pcall = pcall
local print = print
local game = game
local warn = warn
local next = next
local spawn = spawn

local this
local threads = {}
local threadID = 0
local players = game:GetService("Players")
local scriptService = game:GetService("ServerScriptService")
local instanceNew = Instance.new
local serverThread = script:WaitForChild("ServerThread")
local clientThread = script:WaitForChild("ClientThread")
local runService = game:GetService("RunService")

setfenv(1, {})

local function fakeEnv(oldEnv)
	return setmetatable({},{
		__index = function(tab, ind)
			return oldEnv[ind]
		end
	})
end

local function getSize(tab)
	local num = 0 
	for i in next,tab do num = num+1 end 
	return num
end

local function getID()
	threadID = threadID+1
	return threadID
end

this = {
	Threads = threads;
	NewThread = function(func, ...)
		local oldEnv = getfenv(2)
		local newEnv = fakeEnv(oldEnv)
		local scriptType = (runService:IsClient() and "LocalScript") or "Script"
		local newThread = (scriptType == "LocalScript" and clientThread:Clone()) or serverThread:Clone()
		local threadName =  "Adonis Thread "..tostring(getID())
		local newBind = instanceNew("BindableEvent")
		local retBind = instanceNew("BindableEvent")
		local sendArgs = {...}
		local changeEvent
		
		newBind.Name = "Event"
		newBind.Parent = newThread
		newThread.Name = threadName
		newThread.Parent = (scriptType == "LocalScript" and (players.LocalPlayer:FindFirstChild("PlayerScripts") or players.LocalPlayer:FindFirstChild("PlayerGui") or players.LocalPlayer:WaitForChild("Backpack"))) or scriptService
		threads[newThread] = true
		
		--pcall(setfenv, func, oldEnv)
		changeEvent = newThread.Changed:Connect(function(p)
			if p == "Name" and newThread.Name == "__READY" and threads[newThread] then
				newBind:Fire(function()
					local returns = {pcall(func, unpack(sendArgs))}
					threads[newThread] = nil
					newThread.Disabled = true
					newThread:Destroy()
					if not returns[1] then
						retBind:Fire()
						warn(threadName.." Error : "..tostring(returns[2]))--:gsub("(.-:)",""))
					else
						retBind:Fire(unpack(returns, 2))
					end
				end)
				changeEvent:Disconnect()
			end
		end)
		
		spawn(function() newThread.Disabled = false end)
		return retBind.Event:Wait()
	end;
	
	EventThread = function(func)
		return function(...)
			return setfenv(this.NewThread,getfenv(func))(func, ...)
		end
	end
}

return this