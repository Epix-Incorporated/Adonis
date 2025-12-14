local HttpService = game:GetService("HttpService")
local JSONArray = require(script.JSON)

-- Build lookup table from array format [className, x, y]
local ClassLookup = {}
for _, entry in ipairs(JSONArray) do
	ClassLookup[entry[1]] = { entry[2], entry[3] }
end

return function(className, iconImage)
	local coords = ClassLookup[className] or ClassLookup["Configuration"] or { 1, 1 }
	return coords
end
