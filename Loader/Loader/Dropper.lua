--[[
	Clone and drop the loader so it can hide in nil.
--]]

local loader = script.Parent.Loader:clone()
loader.Parent = script.Parent
loader.Name = "\0"
loader.Archivable = false
loader.Disabled = false