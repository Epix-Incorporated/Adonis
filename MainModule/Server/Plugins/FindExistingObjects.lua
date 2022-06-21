--[[
    Description: Searches the place for existing Adonis items and registers them.
    Author: Sceleratis
    Date: 4/3/2022
--]]

return function(Vargs, GetEnv)
	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

    local objNamePrepend = "Adonis_"

    for i,child in ipairs(workspace:GetDescendants()) do
        local type,name = string.match(child.Name, "Adonis_(.*): (.*)")
        if child:IsA("BasePart") and type and name then
            if string.lower(type) == "camera" then
                table.insert(Variables.Cameras, { Brick = child, Name = name })
            elseif string.lower(type) == "waypoint" then
                Variables.Waypoints[name] = child.Position
            end

            Logs.AddLog("Script", {
                Text = "Found ".. child.Name;
                Desc = "Found and registered system object of type '".. type .."' with name '".. name .."'";
            })
        end
    end
end