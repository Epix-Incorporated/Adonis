--!strict
local Copy = require(script.Parent.copy)

--[=[
	@function shuffle
	@within Array

	@param array {T} -- The array to shuffle.
	@return {T} -- The shuffled array.

	Randomises the order of the items in an array.

	```lua
	local array = { 1, 2, 3 }

	local new = Shuffle(array) -- { 2, 3, 1 }
	```
]=]
local function shuffle<T>(array: { T }): { T }
	local random = Random.new(os.time() * #array)
	local result = Copy(array)

	for index = #result, 1, -1 do
		local randomIndex = random:NextInteger(1, index)
		local temp = result[index]

		result[index] = result[randomIndex]
		result[randomIndex] = temp
	end

	return result
end

return shuffle
