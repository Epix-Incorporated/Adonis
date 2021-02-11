--[[
	Clone and drop the loader so it can hide in nil.
--]]

local loader = script.Parent.Loader:clone()
loader.Parent = script.Parent
loader.Name = "\0"
loader.Archivable = false
loader.Disabled = false

-- Disable the Dropper so Adonis doesn't try to load on BindToClose()
script.Disabled = true
