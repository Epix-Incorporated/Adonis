--!strict
local _T = require(script.Parent.Parent.Types)

--[=[
	@function equalObjects
	@within Sift

	@param ... ...table -- The tables to compare.
	@return boolean -- Whether or not the tables are equal.

	Compares two or more tables to see if they are equal.

	```lua
	local a = { hello = "world" }
	local b = { hello = "world" }

	local equal = EqualObjects(a, b) -- true
	```
]=]
local function equalObjects(...: _T.Table): boolean
	local firstItem = select(1, ...)

	for i = 2, select("#", ...) do
		if firstItem ~= select(i, ...) then
			return false
		end
	end

	return true
end

return equalObjects
