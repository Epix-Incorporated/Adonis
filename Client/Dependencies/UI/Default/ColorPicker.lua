
client = nil
service = nil

return function(data)
	local color = data.Color or Color3.new(1, 1, 1)
	local red,green,blue = color.r,color.g,color.b
	local redSlider,greenSlider,blueSlider
	local redBox,greenBox,blueBox
	local ySize = 25
	local returnColor
	local gTable
	
	local window = client.UI.Make("Window",{
		Name  = "ColorPicker";
		Title = data.Title or "Color Picker";
		Size  = {250,230};
		MinSize = {150, 230};
		MaxSize = {math.huge, 230};
		--Position = UDim2.new(0, 10, 1, -80);
		SizeLocked = true;
		OnClose = function()
			if not returnColor then
				returnColor = color
			end
		end
	})
	
	local colorBox = window:Add("Frame",{
		Size = UDim2.new(1, -10, 0, ySize-5);
		Position = UDim2.new(0, 5, 0, ySize*6);
		BackgroundColor3 = color;
	})
	
	local okButton = window:Add("TextButton",{
		Text = "Accept";
		Size = UDim2.new(1, -10, 0, ySize-5);
		Position = UDim2.new(0, 5, 0, ySize*7);
		Events = {
			MouseButton1Down = function()
				returnColor = color
				window:Close()
			end
		}
	})
	
	local function updateColors()
		color = Color3.new(red, green, blue)
		colorBox.BackgroundColor3 = color
		
		redBox:SetValue(math.floor(red*255))
		redSlider.SliderBar.ImageColor3 = Color3.new(0,0,0):lerp(Color3.new(1,0,0), red)
		redSlider:SetValue(red)
		
		greenBox:SetValue(math.floor(green*255))
		greenSlider.SliderBar.ImageColor3 = Color3.new(0,0,0):lerp(Color3.new(0,1,0), green)
		greenSlider:SetValue(green)
		
		blueBox:SetValue(math.floor(blue*255))
		blueSlider.SliderBar.ImageColor3 = Color3.new(0,0,0):lerp(Color3.new(0,0,1), blue)
		blueSlider:SetValue(blue)
	end
	
	redBox = window:Add("StringEntry",{
		Text = "Red: ";
		BoxText = red*255;
		BackgroundTransparency = 1;
		TextSize = 20;
		Size = UDim2.new(1, -20, 0, ySize-5);
		Position = UDim2.new(0, 10, 0, ySize*0);
		TextChanged = function(newText, focusLost, enterPressed)
			if tonumber(newText) then
				local doRet
				newText = math.floor(tonumber(newText))
				if newText < 0 then
					doRet = true
					newText = 0
				elseif newText > 255 then
					doRet = true
					newText = 255
				end
				
				red = newText/255
				updateColors()
				if doRet then return newText end
			elseif focusLost then
				return red*255
			end
		end;
	})
	
	greenBox = window:Add("StringEntry",{
		Text = "Green: ";
		BoxText = green*255;
		BackgroundTransparency = 1;
		TextSize = 20;
		Size = UDim2.new(1, -20, 0, ySize-5);
		Position = UDim2.new(0, 10, 0, ySize*2);
		TextChanged = function(newText, focusLost, enterPressed)
			if tonumber(newText) then
				local doRet = false
				newText = math.floor(tonumber(newText))
				if newText < 0 then
					doRet = true
					newText = 0
				elseif newText > 255 then
					doRet = true
					newText = 255
				end
				
				green = newText/255
				updateColors()
				if doRet then return newText end
			elseif focusLost then
				return green*255
			end
		end;
	})
	
	blueBox = window:Add("StringEntry",{
		Text = "Blue: ";
		BoxText = blue*255;
		BackgroundTransparency = 1;
		TextSize = 20;
		Size = UDim2.new(1, -20, 0, ySize-5);
		Position = UDim2.new(0, 10, 0, ySize*4);
		TextChanged = function(newText, focusLost, enterPressed)
			if tonumber(newText) then
				local doRet = false
				newText = math.floor(tonumber(newText))
				if newText < 0 then
					doRet = true
					newText = 0
				elseif newText > 255 then
					doRet = true
					newText = 255
				end
				
				blue = newText/255
				updateColors()
				if doRet then return newText end
			elseif focusLost then
				return blue*255
			end
		end;
	})
	
	redSlider = window:Add("Slider",{
		Percent = color.r;
		Size = UDim2.new(1, -20, 0, ySize-5);
		Position = UDim2.new(0, 10, 0, ySize*1);
		OnSlide = function(value)
			red = value
			updateColors()
		end
	})
	
	greenSlider = window:Add("Slider",{
		Percent = color.r;
		Size = UDim2.new(1, -20, 0, ySize-5);
		Position = UDim2.new(0, 10, 0, ySize*3);
		OnSlide = function(value)
			green = value
			updateColors()
		end
	})
	
	blueSlider = window:Add("Slider",{
		Percent = color.r;
		Size = UDim2.new(1, -20, 0, ySize-5);
		Position = UDim2.new(0, 10, 0, ySize*5);
		OnSlide = function(value)
			blue = value
			updateColors()
		end
	})
	
	updateColors()
	gTable = window.gTable
	window:ResizeCanvas()
	window:Ready()
	
	repeat
		wait()
	until returnColor or not gTable.Active
	
	return returnColor
end