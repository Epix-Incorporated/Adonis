--!strict
--[=[
  @function copyDeep
  @within Dictionary

  @param dictionary T -- The dictionary to copy.
  @return T -- The copied dictionary.

  Copies a dictionary recursively.

  ```lua
  local dictionary = { hello = { world = "goodbye" } }

  local new = CopyDeep(dictionary) -- { hello = { world = "goodbye" } }

  print(new == dictionary) -- false
  print(new.hello == dictionary.hello) -- false
  ```
]=]
local function copyDeep<T>(dictionary: T): T
	local new = {}

	for key, value in pairs(dictionary) do
		if type(value) == "table" then
			new[key] = copyDeep(value)
		else
			new[key] = value
		end
	end

	return new
end

return copyDeep
