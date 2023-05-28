-- Internally used roblox icons

local FallbackImages = require(script.FallbackImages)
local GetImageSetData = require(script.GetImageSetData)

-- Format each image
local Images = {}
for ImagePath, ImageData in pairs(GetImageSetData(1)) do
	local Image = {
		Image = FallbackImages[ImageData.ImageSet],
		ImageRectOffset = ImageData.ImageRectOffset,
		ImageRectSize = ImageData.ImageRectSize,
		ResampleMode = Enum.ResamplerMode.Default
	}

	-- Only 1x is available
	Images['images/roblox/'..ImagePath..'/1x'] = Image
	Images['images/roblox/'..ImagePath..'/2x'] = Image
	Images['images/roblox/'..ImagePath..'/3x'] = Image
end

return Images