--!strict
--[=[
	@function copy
	@within Array

	@param array {T} -- The array to copy.
	@return {T} -- The copied array.

	Copies an array.

	```lua
	local array = { 1, 2, 3 }

	local new = Copy(array) -- { 1, 2, 3 }

	print(new == array) -- false
	```
]=]
return table.clone
