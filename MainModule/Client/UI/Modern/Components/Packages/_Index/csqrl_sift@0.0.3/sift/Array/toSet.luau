--!strict
local Sift = script.Parent.Parent
local _T = require(Sift.Types)

--[=[
	@function toSet
	@within Array

	@param array {T} -- The array to convert to a set.
	@return Set<T> -- The set.

	Converts an array to a set.

	```lua
	local array = { "a", "b", "b", "c", "d" }

	local set = ToSet(array) -- { a = true, b = true, c = true, d = true }
	```
]=]
local function toSet<T>(array: { T }): _T.Set<T>
	local set = {}

	for _, value in ipairs(array) do
		set[value] = true
	end

	return set
end

return toSet
