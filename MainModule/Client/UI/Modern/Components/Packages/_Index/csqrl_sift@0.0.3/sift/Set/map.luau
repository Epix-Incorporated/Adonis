--!strict
--[=[
  @function map
  @within Set

  @param set { [T]: boolean } -- The set to map.
  @param mapper (T, {[T]: boolean}) -> U -- The mapper function.
  @return {[U]: boolean} -- The mapped set.

  Iterates over a set, calling a mapper function for each item.

  ```lua
  local set = { hello = true, world = true }

  local mappedSet = Map(set, function(value)
    return value .. "!"
  end) -- { ["hello!"] = true, ["world!"] = true }
  ```
]=]
local function map<T, U>(set: { [T]: boolean }, mapper: (T, { [T]: boolean }) -> U): { [U]: boolean }
	local result = {}

	for key, _ in pairs(set) do
		local mappedKey = mapper(key, set)

		if mappedKey ~= nil then
			result[mappedKey] = true
		end
	end

	return result
end

return map
