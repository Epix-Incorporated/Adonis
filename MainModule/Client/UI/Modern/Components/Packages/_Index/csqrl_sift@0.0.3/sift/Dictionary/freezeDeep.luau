--!strict
local _T = require(script.Parent.Parent.Types)

--[=[
  @function freezeDeep
  @within Dictionary

  @param dictionary T -- The dictionary to freeze.
  @return T -- The frozen dictionary.

  Freezes the entire dictionary, making it read-only, including all nested dictionaries.

  ```lua
  local dictionary = { hello = "roblox", goodbye = { world = "world" } }

  local new = FreezeDeep(dictionary)

  new.hello = "world" -- error!
  new.goodbye.world = "hello" -- error!
  ```
]=]
local function freezeDeep(dictionary: _T.AnyDictionary): _T.AnyDictionary
	local result = {}

	for key, value in pairs(dictionary) do
		if type(value) == "table" then
			result[key] = freezeDeep(value)
		else
			result[key] = value
		end
	end

	table.freeze(result)

	return result
end

return freezeDeep
