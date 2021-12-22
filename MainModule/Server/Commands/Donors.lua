return function(Vargs, env)
	local server = Vargs.Server;
	local service = Vargs.Service;

	local Settings = server.Settings
	local Functions, Commands, Admin, Anti, Core, HTTP, Logs, Remote, Process, Variables, Deps =
		server.Functions, server.Commands, server.Admin, server.Anti, server.Core, server.HTTP, server.Logs, server.Remote, server.Process, server.Variables, server.Deps

	if env then setfenv(1, env) end

	return {
		DonorUncape = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"uncape", "removedonorcape"};
			Args = {};
			Description = "Remove donor cape";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				Functions.UnCape(plr)
			end
		};

		DonorCape = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"cape", "donorcape"};
			Args = {};
			Description = "Get donor cape (remove using "..Settings.PlayerPrefix.."uncape)";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				Functions.Donor(plr)
			end
		};

		DonorTShirt = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"tshirt", "givetshirt", "donortshirt"};
			Args = {"ID"};
			Description = "Give you the t-shirt that belongs to <ID>";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {[number]:string})
				if plr.Character then
					local ClothingId = tonumber(args[1])
					local AssetIdType = service.MarketPlace:GetProductInfo(ClothingId).AssetTypeId
					local tShirt = ((AssetIdType == 11 or AssetIdType == 2) and service.Insert(ClothingId)) or (AssetIdType == 1 and Functions.CreateClothingFromImageId("ShirtGraphic", ClothingId)) or error("Item ID passed has invalid item type")

					assert(tShirt, "Could not retrieve shirt asset for the supplied ID")

					for _, v in pairs(plr.Character:GetChildren()) do
						if v:IsA("ShirtGraphic") then v:Destroy() end
					end

					local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
					local humandescrip = humanoid and humanoid:FindFirstChildOfClass("HumanoidDescription")

					if humandescrip then
						humandescrip.GraphicTShirt = ClothingId
					end

					if tShirt:IsA("Model") then
						tShirt = tShirt:FindFirstChildOfClass("ShirtGraphic")
					end

					tShirt:Clone().Parent = plr.Character
				end
			end
		};

		DonorRemoveTShirt = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"removetshirt", "untshirt", "notshirt"};
			Args = {};
			Description = "Remove the t-shirt you are wearing, if any";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {[number]:string})
				if plr.Character then
					for _, v in pairs(plr.Character:GetChildren()) do
						if v:IsA("ShirtGraphic") then v:Destroy() end
					end
					local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
					local humandescrip = humanoid and humanoid:FindFirstChildOfClass("HumanoidDescription")

					if humandescrip then
						humandescrip.GraphicTShirt = 0
					end
				end
			end
		};

		DonorShirt = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"shirt", "giveshirt", "donorshirt"};
			Args = {"ID"};
			Description = "Give you the shirt that belongs to <ID>";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				if plr.Character then
					local ClothingId = tonumber(args[1])
					local AssetIdType = service.MarketPlace:GetProductInfo(ClothingId).AssetTypeId
					local Shirt = AssetIdType == 11 and service.Insert(ClothingId) or AssetIdType == 1 and Functions.CreateClothingFromImageId("Shirt", ClothingId) or error("Item ID passed has invalid item type")
					assert(Shirt, "Unexpected error occured; clothing is missing")
					for _, v in pairs(plr.Character:GetChildren()) do
						if v:IsA("Shirt") then v:Destroy() end
					end
					local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
					local humandescrip = humanoid and humanoid:FindFirstChildOfClass("HumanoidDescription")

					if humandescrip then
						humandescrip.Shirt = ClothingId
					end
					Shirt:Clone().Parent = plr.Character
				end
			end
		};

		DonorPants = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"pants", "givepants", "donorpants"};
			Args = {"ID"};
			Description = "Give you the pants that belongs to <ID>";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				if plr.Character then
					local ClothingId = tonumber(args[1])
					local AssetIdType = service.MarketPlace:GetProductInfo(ClothingId).AssetTypeId
					local Pants = AssetIdType == 12 and service.Insert(ClothingId) or AssetIdType == 1 and Functions.CreateClothingFromImageId("Pants", ClothingId) or error("Item ID passed has invalid item type")
					assert(Pants, "Unexpected error occured; clothing is missing")
					for _, v in pairs(plr.Character:GetChildren()) do
						if v:IsA("Pants") then v:Destroy() end
					end

					local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
					local humandescrip = humanoid and humanoid:FindFirstChildOfClass("HumanoidDescription")

					if humandescrip then
						humandescrip.Pants = ClothingId
					end

					Pants:Clone().Parent = plr.Character
				end
			end
		};

		DonorFace = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"face", "giveface", "donorface"};
			Args = {"ID"};
			Description = "Gives you the face that belongs to <ID>";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				if plr.Character and plr.Character:FindFirstChild("Head") and plr.Character.Head:FindFirstChild("face") then
					plr.Character.Head:FindFirstChild("face"):Destroy()
				end

				local id = tonumber(args[1])
				local market = service.MarketPlace
				local info = market:GetProductInfo(id)

				local humanoid = plr.Character:FindFirstChildOfClass'Humanoid'
				local humandescrip = humanoid and humanoid:FindFirstChildOfClass"HumanoidDescription"

				if humandescrip then
					humandescrip.Face = id
				end

				assert(info.AssetTypeId == 18, "Invalid face ID")
				if plr.Character:FindFirstChild("Head") then
					local face = service.Insert(args[1])
					if face then
						face.Parent = plr.Character:FindFirstChild("Head")
					end
				end
			end
		};

		DonorNeon = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"neon", "donorneon"};
			Args = {"color"};
			Description = "Changes your body material to neon and makes you the (optional) color of your choosing.";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				if plr.Character then
					for _,p in pairs(plr.Character:GetChildren()) do
						if p:IsA("BasePart") then
							if args[1] then
								p.BrickColor = BrickColor.new(args[1])
							end
							p.Material = Enum.Material.Neon
						end
					end
				end
			end
		};

		DonorFire = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"fire", "donorfire"};
			Args = {"color (optional)"};
			Description = "Gives you fire with the specified color (if you specify one)";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				if torso then
					local color = Color3.new(1,1,1)
					local secondary = Color3.new(1,0,0)
					if args[1] then
						local str = BrickColor.new('Cyan').Color
						local teststr = args[1]

						if BrickColor.new(teststr) ~= nil then
							str = BrickColor.new(teststr).Color
						end

						color = str
						secondary = str
					end

					Functions.RemoveParticle(torso, "DONOR_FIRE")
					Functions.NewParticle(torso, "Fire", {
						Name = "DONOR_FIRE";
						Color = color;
						SecondaryColor = secondary;
					})
					Functions.RemoveParticle(torso, "DONOR_FIRE_LIGHT")
					Functions.NewParticle(torso, "PointLight", {
						Name = "DONOR_FIRE_LIGHT";
						Color = color;
						Range = 15;
						Brightness = 5;
					})
				end
			end
		};

		DonorSparkles = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"sparkles", "donorsparkles"};
			Args = {"color (optional)"};
			Description = "Gives you sparkles with the specified color (if you specify one)";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				if torso then
					local color = Color3.new(1,1,1)
					if args[1] then
						local str = BrickColor.new('Bright orange').Color
						local teststr = args[1]

						if BrickColor.new(teststr) ~= nil then
							str = BrickColor.new(teststr).Color
						end

						color = str
					end

					Functions.RemoveParticle(torso, "DONOR_SPARKLES")
					Functions.RemoveParticle(torso, "DONOR_SPARKLES_LIGHT")
					Functions.NewParticle(torso, "Sparkles", {
						Name = "DONOR_SPARKLES";
						SparkleColor = color;
					})

					Functions.NewParticle(torso, "PointLight", {
						Name = "DONOR_SPARKLES_LIGHT";
						Color = color;
						Range = 15;
						Brightness = 5;
					})
				end
			end
		};

		DonorLight = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"light", "donorlight"};
			Args = {"color (optional)"};
			Description = "Gives you a PointLight with the specified color (if you specify one)";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				if torso then
					local color = Color3.new(1,1,1)
					if args[1] then
						local str = BrickColor.new('Cyan').Color
						local teststr = args[1]

						if BrickColor.new(teststr) ~= nil then
							str = BrickColor.new(teststr).Color
						end

						color = str
					end

					Functions.RemoveParticle(torso, "DONOR_LIGHT")
					Functions.NewParticle(torso, "PointLight", {
						Name = "DONOR_LIGHT";
						Color = color;
						Range = 15;
						Brightness = 5;
					})
				end
			end
		};

		DonorParticle = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"particle", "donorparticle"};
			Args = {"textureid", "startColor3", "endColor3"};
			Description = "Put a custom particle emitter on your character";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				assert(args[1], "Missing TextureId")

				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				if torso then
					local startColor = {}
					local endColor = {}

					if args[2] then
						for s in args[2]:gmatch("[%d]+") do
							table.insert(startColor,tonumber(s))
						end
					end
					if args[3] then--276138620 :)
						for s in args[3]:gmatch("[%d]+") do
							table.insert(endColor,tonumber(s))
						end
					end

					local startc = Color3.new(1,1,1)
					local endc = Color3.new(1,1,1)
					if #startColor==3 then
						startc = Color3.new(startColor[1],startColor[2],startColor[3])
					end
					if #endColor==3 then
						endc = Color3.new(endColor[1],endColor[2],endColor[3])
					end

					Functions.RemoveParticle(torso, "DONOR_PARTICLE")
					Functions.NewParticle(torso, "ParticleEmitter", {
						Name = "DONOR_PARTICLE";
						Texture = 'rbxassetid://'..Functions.GetTexture(args[1]);
						Size = NumberSequence.new({
							NumberSequenceKeypoint.new(0,0);
							NumberSequenceKeypoint.new(.1,.25,.25);
							NumberSequenceKeypoint.new(1,.5);
						});
						Transparency = NumberSequence.new({
							NumberSequenceKeypoint.new(0,1);
							NumberSequenceKeypoint.new(.1,.25,.25);
							NumberSequenceKeypoint.new(.9,.5,.25);
							NumberSequenceKeypoint.new(1,1);
						});
						Lifetime = NumberRange.new(5);
						Speed = NumberRange.new(.5,1);
						Rotation = NumberRange.new(0,359);
						RotSpeed = NumberRange.new(-90,90);
						Rate = 11;
						VelocitySpread = 180;
						Color = ColorSequence.new(startc,endc);
					})
				end
			end
		};

		DonorUnparticle = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"unparticle", "removeparticles", "undonorparticle"};
			Args = {};
			Description = "Removes donor particles on you";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				Functions.RemoveParticle(torso, "DONOR_PARTICLE")
			end
		};

		DonorUnfire = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"unfire", "undonorfire"};
			Args = {};
			Description = "Removes donor fire on you";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				Functions.RemoveParticle(torso, "DONOR_FIRE")
				Functions.RemoveParticle(torso, "DONOR_FIRE_LIGHT")
			end
		};

		DonorUnsparkles = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"unsparkles", "undonorsparkles"};
			Args = {};
			Description = "Removes donor sparkles on you";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				Functions.RemoveParticle(torso, "DONOR_SPARKLES")
				Functions.RemoveParticle(torso, "DONOR_SPARKLES_LIGHT")
			end
		};

		DonorUnlight = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"unlight", "undonorlight"};
			Args = {};
			Description = "Removes donor light on you";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				local torso = plr.Character:FindFirstChild("HumanoidRootPart")
				Functions.RemoveParticle(torso, "DONOR_LIGHT")
			end
		};

		DonorHat = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"hat", "gethat", "donorhat"};
			Args = {"ID"};
			Description = "Gives you the hat specified by <ID>";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				local id = tonumber(args[1])
				local hats = 0
				for i, v in pairs(plr.Character:GetChildren()) do if v:IsA("Accoutrement") then hats = hats+1 end end
				if id and hats<15 then
					local market = service.MarketPlace
					local info = market:GetProductInfo(id)
					if info.AssetTypeId == 8 or (info.AssetTypeId >= 41 and info.AssetTypeId <= 47) then
						local hat = service.Insert(id)
						assert(hat, "Invalid ID")
						local banned = {
							Script = true;
							LocalScript = true;
							Tool = true;
							HopperBin = true;
							ModuleScript = true;
							RemoteFunction = true;
							RemoteEvent = true;
							BindableEvent = true;
							Folder = true;
							RocketPropulsion = true;
							Explosion = true;
						}

						local removeScripts; removeScripts = function(obj)
							for i, v in pairs(obj:GetChildren()) do
								pcall(function()
									removeScripts(v)
									if banned[v.ClassName] then
										v:Destroy()
									end
								end)
							end
						end

						removeScripts(hat)
						hat.Parent = plr.Character
						hat.Changed:Connect(function()
							if hat.Parent ~= plr.Character then
								hat:Destroy()
							end
						end)
					end
				end
			end
		};
																		
		DonorHatList = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"myhats", "hatlist", "hats", "donorhats"};
			Args = {};
			Description = "Shows you a list of hats you are currently wearing";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				Remote.MakeGui(plr, "HatList", {
					PlayerPrefix = Settings.PlayerPrefix; SplitKey = Settings.SplitKey;
				})
			end
		};

		DonorRemoveHat = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"removehat", "removedonorhat"};
			Args = {"name"};
			Description = "Removes a specific accessory you are currently wearing";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				local hat = plr.Character:FindFirstChild(args[1])
				if hat and hat:IsA("Accessory") then
					hat:Destroy()
					Functions.Hint(args[1].." has been removed.", {plr})
				else
					Functions.Hint(args[1].." is not a valid accessory. Run `"..Settings.PlayerPrefix.."myhats` for a list of accessories you are wearing.", {plr})
				end

			end
		};

		DonorRemoveHats = {
			Prefix = Settings.PlayerPrefix;
			Commands = {"removehats", "nohats", "nodonorhats", "clearhats"};
			Args = {};
			Description = "Removes any hats you are currently wearing";
			Fun = false;
			Donors = true;
			AdminLevel = "Donors";
			Function = function(plr: Player, args: {string})
				for _, v in pairs(plr.Character:GetChildren()) do
					if v:IsA("Accoutrement") then
						v:Destroy()
					end
				end
			end
		};

	}
end
