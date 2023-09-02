local textures = {
	332277948;
	332277937;
	332277919;
	332277904;
	332277885;
	332277870;
	332277851;
	332277835;
	332277820;
	332277809;
	332277789;
	332277963;
}

while true do
	for _, v in ipairs(textures) do
		script.Parent.Texture = `http://www.roblox.com/asset/?id={v}`
		task.wait(0.1)
	end
end
