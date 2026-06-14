local restore = {}

repeat
	task.wait()
	local char = script.Parent.Parent
	for i, v in next, char:GetChildren() do
		if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
			if not restore[v] then
				restore[v] = v.Color
			end
			v.Color = Color3.fromHSV(os.clock() % 1, 1, 1)
		end
	end
until not char or script.Name == "Stop" -- signal to unrainbowify

if script.Name == "Stop" then
	for item, clr in next, restore do
		item.Color = clr -- restore old colors
	end
	script:Destroy()
end