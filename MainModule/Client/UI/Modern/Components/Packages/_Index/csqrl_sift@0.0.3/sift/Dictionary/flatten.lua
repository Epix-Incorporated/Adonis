--!strict
local _T = require(script.Parent.Parent.Types)

--[=[
  @function flatten
  @within Dictionary

  @param dictionary T -- The dictionary to flatten.
  @param depth? number -- The depth to flatten the dictionary to.
  @return T -- The flattened dictionary.

  Flattens a dictionary. If depth is not specified, it will flatten the dictionary as far as it can go.

  ```lua
  local dictionary = {
    hello = "world",
    goodbye = {
      world = "hello",
      roblox = {
        yes = "no",
        no = "yes",
      }
    }
  }

  local new = Flatten(dictionary) -- { hello = "world", world = "hello", yes = "no", no = "yes" }
  local new = Flatten(dictionary, 1) -- { hello = "world", world = "hello", roblox = { yes = "no", no = "yes" } }
  ```
]=]
local function flatten(dictionary: _T.AnyDictionary, depth: number?): _T.AnyDictionary
	depth = if type(depth) == "number" then depth else math.huge

	local result = {}

	for key, value in pairs(dictionary :: _T.AnyDictionary) do
		if type(value) == "table" and depth > 0 then
			local nested = flatten(value, depth - 1)

			for resultKey, resultValue in pairs(result) do
				nested[resultKey] = resultValue
			end

			result = nested
		else
			result[key] = value
		end
	end

	return result
end

return flatten
