local textures = {
	332288373;
	332288356;
	332288314;
	332288287;
	332288276;
	332288249;
	332288224;
	332288207;
	332288184;
	332288163;
	332288144;
	332288125;
}

while true do
	for _, v in ipairs(textures) do
		script.Parent.Texture = `http://www.roblox.com/asset/?id={v}`
		task.wait(0.1)
	end
end
