--[[
	A way to dynamically fetch the F3X module with require()'s ModuleScript sandboxing.
]]

script:Destroy()
script = nil

return select(2, pcall(function()
	return require(580330877)()
end)) or true
