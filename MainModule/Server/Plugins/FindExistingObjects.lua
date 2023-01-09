--[[
    Description: Searches the place for existing Adonis items and registers them.
    Author: Sceleratis
    Date: 4/3/2022
--]]

return function(Vargs, GetEnv)
	local env = GetEnv(nil, { script = script })
	setfenv(1, env)

	local server = Vargs.Server

	local Logs, Variables = server.Logs, server.Variables

	local OBJ_NAME_PREFIX = "Adonis_"

	for _, child in ipairs(workspace:GetDescendants()) do
		local objType, name = string.match(child.Name, `{OBJ_NAME_PREFIX}(.*): (.*)`)
		if child:IsA("BasePart") and objType and name then
			if string.lower(objType) == "camera" then
				table.insert(Variables.Cameras, { Brick = child, Name = name })
			elseif string.lower(objType) == "waypoint" then
				Variables.Waypoints[name] = child.Position
			end

			Logs.AddLog("Script", {
				Text = `Found {child.Name}`,
				Desc = `Found and registered system object of type '{objType}' with name '{name}'`,
			})
		end
	end
end
