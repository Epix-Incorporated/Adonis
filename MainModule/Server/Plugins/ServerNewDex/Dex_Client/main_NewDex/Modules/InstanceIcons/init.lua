local ClassData = require(script.JSON)

return function(className, iconImage)
	local coords = ClassData[className] or ClassData.Configuration or { 1, 1 }
	return coords
end
