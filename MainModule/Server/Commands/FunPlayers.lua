return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	return {
		wat = { --// wat??
			Prefix = "!";
			Commands = {"wat"};
			Args = {};
			Hidden = true;
			Description = "???";
			Fun = true;
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local wot = {3657191505, 754995791, 160715357, 4881542521, 227499602, 217714490, 130872377, 142633540, 259702986, 6884041159}
				Remote.Send(plr, "Function", "PlayAudio", wot[math.random(1,#wot)])
			end
		};

		YouBeenTrolled = {
			Prefix = "?";
			Commands = {"trolled", "freebobuc", "freedonor", "adminpls", "enabledonor"};--//add more :)
			Args = {};
			Fun = true;
			Hidden = true;
			Description = "You've Been Trolled You've Been Trolled Yes You've Probably Been Told...";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Effect", {Mode = "trolling";})
			end
		};

        iloveyou = {
			Prefix = "?";
			Commands = {"iloveyou", "alwaysnear", "alwayswatching"};
			Args = {};
			Fun = true;
			Hidden = true;
			Description = "I love you. You are mine. Do not fear; I will always be near.";
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "Effect", {Mode = "lifeoftheparty";})
			end
		};

        Pets = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"pets"};
			Args = {"follow/float/swarm/attack", "player"};
			Hidden = false;
			Description = "Makes your hat pets do the specified command (follow/float/swarm/attack)";
			Fun = true;
			AdminLevel = "Players";
			Function = function(plr: Player, args: {string})
				local hats = plr.Character:FindFirstChild("ADONIS_HAT_PETS")
				if hats then
					for i, v in pairs(service.GetPlayers(plr, args[2])) do
						if v.Character:FindFirstChild("HumanoidRootPart") and v.Character.HumanoidRootPart:IsA("Part") then
							if args[1]:lower() == "follow" then
								hats.Mode.Value = "Follow"
								hats.Target.Value = v.Character.HumanoidRootPart
							elseif args[1]:lower() == "float" then
								hats.Mode.Value = "Float"
								hats.Target.Value = v.Character.HumanoidRootPart
							elseif args[1]:lower() == "swarm" then
								hats.Mode.Value = "Swarm"
								hats.Target.Value = v.Character.HumanoidRootPart
							elseif args[1]:lower() == "attack" then
								hats.Mode.Value = "Attack"
								hats.Target.Value = v.Character.HumanoidRootPart
							end
						end
					end
				else
					Functions.Hint("You don't have any hat pets! If you are an admin use the :hatpets command to get some", {plr})
				end
			end
		};
    }
end