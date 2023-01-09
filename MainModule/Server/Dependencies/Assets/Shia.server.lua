local frames = {
	286117283,
	286117453,
	286117512,
	286117584,
	286118200,
	286118256,
	--286118366;
	286118468,
	286118598,
	286118637,
	286118670,
	286118709,
	286118755,
	286118810,
	286118862,
}

repeat
	for _, id in ipairs(frames) do
		script.Parent.Texture = `http://www.roblox.com/asset/?id={id}`
		task.wait(0.1)
	end
until false
