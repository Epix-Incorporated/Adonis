--// You can use modules like this to alter guis without making a new theme
--// This makes it so you don't need to make an entire gui folder n all that
--// If the theme is set to this module, it will use the default guis
--// The default requested gui will be passed to and modified by this module
--// before it runs. This lets you change things in anyway you want without
--// needing to change the guis by hand or their code.
--// This is also generally safer and update proof.
--// Alternatively if this returns anything, it will be assumed
--// that this module created and registered it's own screenguis
--// It will assume that any return is from those guis
--// For instance the YesNoPrompt returns Yes or No depending on
--// what button the player presses.
--// Any non-nil return will be returned by the script
--// IF YOU MAKE YOUR OWN SCREENGUIS IT IS UP TO YOU TO REGISTER THEM!
--// If you plan to make your own guis you must return something from this module
--// and you must register them using client.UI.Register(ScreenGuiObjectHere)
--// Register will return gTable and gIndex, when destroying your gui
--// use gTable:Destroy(); If your gui needs to be removed in a special way
--// you can define a custom destroy function by doing
--// gTable.CustomDestroy = function() doStuffHere end

--// If this module returns a ScreenGui object, the script will use that as the gui and 
--// take care of registering and running the code module n all that.
--// RETURNED SCREENGUI MUST CONTAIN A "Config" FOLDER; 
--// If no Code module is given the default code module will be used.

--[[
	~= EXAMPLE CODE =~
	return function(gui,gTable,guiData)
		local name = gTable.Name
		if name == "YesNoPrompt" then
			local new = Instance.new("ScreenGui")
			local frame = Instance.new("Frame",new)
			frame.Size = UDim2.new(0,400,0,400)
			local yes = Instance.new("TextButton",frame)
			yes.Size = UDim2.new(0.5,0,1,0)
			yes.Text = "Yes"
			local no = yes:Clone()
			no.Text = "No"
			no.Position = UDim2.new(0.5,0,0,0)
			
			local gTable,gIndex = client.UI.Register(new)
			
			local ans
			local waiting = true
			
			gTable.CustomDestroy = function()
				waiting = false
			end
			
			yes.MouseButton1Click:connect(function()
				ans = "Yes"
				gTable:Destroy()
			end)
			
			no.MouseButton1Click:connect(function()
				ans = "No"
				gTable:Destroy()
			end)
			
			repeat wait() until ans or not waiting  --// Wait until answer
			return ans or false
		end
	end
	
--]]

service = nil
Routine = nil
client = nil

return function(gui, guiData, gTable)
	local contents = {}
	local lerper = 0.5
	local switch = false
	local targetColor = Color3.new(math.random(),math.random(),math.random())
	local classes = {
		Frame = true;
		TextBox = true;
		TextLabel = true;
		TextButton = true;
		ImageLabel = true;
		ImageButton = true; 
		ScrollingFrame = true;
	}
	
	local function getCont(obj)
		for i,v in pairs(obj:GetChildren()) do 
			if classes[v.ClassName] then
				table.insert(contents,v)
				getCont(v)
			end
		end
	end
	
	if classes[gui.ClassName] then
		table.insert(contents,gui)
	end
	
	getCont(gui)
	
	if gTable.Name == "List" then
		gui.Drag.Main.BackgroundTransparency = 0
	end
	
	local increment = 0.001
	local max = 0.7
	local min = 0.1
	local r,g,b = 0.1,0.5,0.8
	local rt,gt,bt = true,true,true 
	local sequence = {
		Color3.fromRGB(255, 85, 88), 
		Color3.fromRGB(78, 140, 255), 
		Color3.fromRGB(78, 255, 149)
	}
	
	local function lerpToColor(color1, color2, inc, time)
		local inc = inc or 0.1
		for i = 0, 1, inc do
			for i2,v in next,contents do
				if v.Name ~= "CapeColor" and v.Name ~= "Color" then
					v.BackgroundColor3 = color1:lerp(color2, i)
					if v:IsA("ImageLabel") or v:IsA("ImageButton") then
						v.ImageColor3 = color1:lerp(color2, i)
					end
				end
			end
			wait(time/(1/inc))
		end
	end
	
	service.TrackTask("Thread: Colorize_"..tostring(gTable.Name),function()
		while ((gTable.Active and wait()) or wait(1)) and not gTable.Destroyed do
			for i,v in next,sequence do
				local one, two = sequence[i], sequence[1]
				
				if i == #sequence then
					two = sequence[1]
				else
					two = sequence[i+1]
				end
				
				lerpToColor(one, two, 0.01, 2)
			end
		end
	end)
end