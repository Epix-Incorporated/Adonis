--[[
 Properties App Module
 
 The main properties interface
]]

-- ADONIS
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Dex_RemoteFunction = ReplicatedStorage:WaitForChild("NewDex_Event") :: RemoteFunction

-- Common Locals
local Main, Lib, Apps, Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notebook -- Major Apps
local API, RMD, env, service, plr, create, createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
end

local function main()
	local Properties = {}

	local window, toolBar, propsFrame
	local scrollV, scrollH
	local categoryOrder
	local props, viewList, expanded, indexableProps, propEntries, autoUpdateObjs = {}, {}, {}, {}, {}, {}
	local inputBox, inputTextBox, inputProp
	local checkboxes, propCons = {}, {}
	local table, string = table, string
	local getPropChangedSignal = game.GetPropertyChangedSignal
	local getAttributeChangedSignal = game.GetAttributeChangedSignal
	local isa = game.IsA
	local getAttribute = game.GetAttribute
	local setAttribute = game.SetAttribute

	Properties.GuiElems = {}
	Properties.Index = 0
	Properties.ViewWidth = 0
	Properties.MinInputWidth = 100
	Properties.EntryIndent = 16
	Properties.EntryOffset = 4
	Properties.NameWidthCache = {}
	Properties.SubPropCache = {}
	Properties.ClassLists = {}
	Properties.SearchText = ""

	Properties.ViewTagsProp = {
		Name = "Add Tag...",
		DisplayName = "Add Tag...",
		Category = "Tags",
		Class = "Instance",
		ValueType = { Name = "string", Category = "Primitive" },
		Tags = {},
		SpecialRow = "AddTag",
		IsAddTagButton = true,
	}
	Properties.AddAttributeProp =
		{ Category = "Attributes", Class = "", Name = "", SpecialRow = "AddAttribute", Tags = {} }
	Properties.SoundPreviewProp = {
		Category = "Data",
		ValueType = { Name = "SoundPlayer" },
		Class = "Sound",
		Name = "Preview",
		Tags = {},
		IsSoundPreview = true,
	}

	-- silencer
	Properties.Refresh = nil
	Properties.Update = nil
	Properties.UpdateView = nil
	Properties.ShowExplorerProps = nil
	Properties.ComputeConflicts = nil
	Properties.MakeSubProp = nil
	Properties.GetExpandedProps = nil
	Properties.NewPropEntry = nil
	Properties.GetSoundPreviewEntry = nil
	Properties.SetSoundPreview = nil
	Properties.DisplayAttributeContext = nil
	Properties.DisplayAddAttributeWindow = nil
	Properties.DisplayAddTagWindow = nil
	Properties.IsTextEditable = nil
	Properties.DisplayEnumDropdown = nil
	Properties.DisplayBrickColorEditor = nil
	Properties.DisplayColorEditor = nil
	Properties.DisplayNumberSequenceEditor = nil
	Properties.DisplayColorSequenceEditor = nil
	Properties.GetFirstPropVal = nil
	Properties.GetPropVal = nil
	Properties.SelectObject = nil
	Properties.DisplayProp = nil
	Properties.SetProp = nil
	Properties.InitInputBox = nil
	Properties.SetInputProp = nil
	Properties.InitSearch = nil
	Properties.InitEntryStuff = nil
	Properties.Init = nil
	Properties.EditingAttribute = nil
	Properties.EnumContext = nil
	Properties.BrickColorEditor = nil
	Properties.ColorEditor = nil
	Properties.NumberSequenceEditor = nil
	Properties.ColorSequenceEditor = nil
	Properties.FullNameFrame = nil
	Properties.FullNameFrameAttach = nil
	Properties.Window = nil
	Properties.EntryTemplate = nil
	Properties.PreviewSound = nil
	Properties.AttributeContext = nil
	Properties.AddAttributeWindow = nil

	Properties.IgnoreProps = {
		["DataModel"] = {
			["PrivateServerId"] = true,
			["PrivateServerOwnerId"] = true,
			["VIPServerId"] = true,
			["VIPServerOwnerId"] = true,
		},
	}

	Properties.ExpandableTypes = {
		["Vector2"] = true,
		["Vector3"] = true,
		["UDim"] = true,
		["UDim2"] = true,
		["CFrame"] = true,
		["Rect"] = true,
		["PhysicalProperties"] = true,
		["Ray"] = true,
		["NumberRange"] = true,
		["Faces"] = true,
		["Axes"] = true,
	}

	Properties.ExpandableProps = {
		["Sound.SoundId"] = true,
		["AudioPlayer.Asset"] = true,
	}

	Properties.CollapsedCategories = {
		["Surface Inputs"] = true,
		["Surface"] = true,
	}

	Properties.ConflictSubProps = {
		["Vector2"] = { "X", "Y" },
		["Vector3"] = { "X", "Y", "Z" },
		["UDim"] = { "Scale", "Offset" },
		["UDim2"] = { "X", "X.Scale", "X.Offset", "Y", "Y.Scale", "Y.Offset" },
		["CFrame"] = {
			"Position",
			"Position.X",
			"Position.Y",
			"Position.Z",
			"RightVector",
			"RightVector.X",
			"RightVector.Y",
			"RightVector.Z",
			"UpVector",
			"UpVector.X",
			"UpVector.Y",
			"UpVector.Z",
			"LookVector",
			"LookVector.X",
			"LookVector.Y",
			"LookVector.Z",
		},
		["Rect"] = { "Min.X", "Min.Y", "Max.X", "Max.Y" },
		["PhysicalProperties"] = { "Density", "Elasticity", "ElasticityWeight", "Friction", "FrictionWeight" },
		["Ray"] = {
			"Origin",
			"Origin.X",
			"Origin.Y",
			"Origin.Z",
			"Direction",
			"Direction.X",
			"Direction.Y",
			"Direction.Z",
		},
		["NumberRange"] = { "Min", "Max" },
		["Faces"] = { "Back", "Bottom", "Front", "Left", "Right", "Top" },
		["Axes"] = { "X", "Y", "Z" },
	}

	Properties.ConflictIgnore = {
		["BasePart"] = {
			["ResizableFaces"] = true,
		},
	}

	Properties.RoundableTypes = {
		["float"] = true,
		["double"] = true,
		["Color3"] = true,
		["UDim"] = true,
		["UDim2"] = true,
		["Vector2"] = true,
		["Vector3"] = true,
		["NumberRange"] = true,
		["Rect"] = true,
		["NumberSequence"] = true,
		["ColorSequence"] = true,
		["Ray"] = true,
		["CFrame"] = true,
	}

	Properties.TypeNameConvert = {
		["number"] = "double",
		["boolean"] = "bool",
	}

	Properties.ToNumberTypes = {
		["int"] = true,
		["int64"] = true,
		["float"] = true,
		["double"] = true,
	}

	Properties.DefaultPropValue = {
		string = "",
		bool = false,
		double = 0,
		UDim = UDim.new(0, 0),
		UDim2 = UDim2.new(0, 0, 0, 0),
		BrickColor = BrickColor.new("Medium stone grey"),
		Color3 = Color3.new(1, 1, 1),
		Vector2 = Vector2.new(0, 0),
		Vector3 = Vector3.new(0, 0, 0),
		NumberSequence = NumberSequence.new(1),
		ColorSequence = ColorSequence.new(Color3.new(1, 1, 1)),
		NumberRange = NumberRange.new(0),
		Rect = Rect.new(0, 0, 0, 0),
	}

	Properties.AllowedAttributeTypes = {
		"string",
		"boolean",
		"number",
		"UDim",
		"UDim2",
		"BrickColor",
		"Color3",
		"Vector2",
		"Vector3",
		"NumberSequence",
		"ColorSequence",
		"NumberRange",
		"Rect",
	}

	Properties.StringToValue = function(prop, str)
		local typeData = prop.ValueType
		local typeName = typeData.Name

		if typeName == "string" or typeName == "Content" then
			return str
		elseif Properties.ToNumberTypes[typeName] then
			return tonumber(str)
		elseif typeName == "Vector2" then
			local vals = str:split(",")
			local x, y = tonumber(vals[1]), tonumber(vals[2])
			if x and y and #vals >= 2 then
				return Vector2.new(x, y)
			end
		elseif typeName == "Vector3" then
			local vals = str:split(",")
			local x, y, z = tonumber(vals[1]), tonumber(vals[2]), tonumber(vals[3])
			if x and y and z and #vals >= 3 then
				return Vector3.new(x, y, z)
			end
		elseif typeName == "UDim" then
			local vals = str:split(",")
			local scale, offset = tonumber(vals[1]), tonumber(vals[2])
			if scale and offset and #vals >= 2 then
				return UDim.new(scale, offset)
			end
		elseif typeName == "UDim2" then
			local vals = str:gsub("[{}]", ""):split(",")
			local xScale, xOffset, yScale, yOffset =
				tonumber(vals[1]), tonumber(vals[2]), tonumber(vals[3]), tonumber(vals[4])
			if xScale and xOffset and yScale and yOffset and #vals >= 4 then
				return UDim2.new(xScale, xOffset, yScale, yOffset)
			end
		elseif typeName == "CFrame" then
			local vals = str:split(",")
			local s, result = pcall(CFrame.new, unpack(vals))
			if s and #vals >= 12 then
				return result
			end
		elseif typeName == "Rect" then
			local vals = str:split(",")
			local s, result = pcall(Rect.new, unpack(vals))
			if s and #vals >= 4 then
				return result
			end
		elseif typeName == "Ray" then
			local vals = str:gsub("[{}]", ""):split(",")
			local s, origin = pcall(Vector3.new, unpack(vals, 1, 3))
			local s2, direction = pcall(Vector3.new, unpack(vals, 4, 6))
			if s and s2 and #vals >= 6 then
				return Ray.new(origin, direction)
			end
		elseif typeName == "NumberRange" then
			local vals = str:split(",")
			local s, result = pcall(NumberRange.new, unpack(vals))
			if s and #vals >= 1 then
				return result
			end
		elseif typeName == "Color3" then
			local vals = str:gsub("[{}]", ""):split(",")
			local s, result = pcall(Color3.fromRGB, unpack(vals))
			if s and #vals >= 3 then
				return result
			end
		end

		return nil
	end

	Properties.ValueToString = function(prop, val)
		local typeData = prop.ValueType
		local typeName = typeData.Name

		if typeName == "Color3" then
			return Lib.ColorToBytes(val)
		elseif typeName == "NumberRange" then
			return val.Min .. ", " .. val.Max
		end

		return tostring(val)
	end

	Properties.GetIndexableProps = function(obj, classData)
		if not Main.Elevated then
			if not pcall(function()
				return obj.ClassName
			end) then
				return nil
			end
		end

		local ignoreProps = Properties.IgnoreProps[classData.Name] or {}

		local result = {}
		local count = 1
		local props = classData.Properties
		for i = 1, #props do
			local prop = props[i]
			if not ignoreProps[prop.Name] then
				local s = pcall(function()
					return obj[prop.Name]
				end)
				if s then
					result[count] = prop
					count = count + 1
				end
			end
		end

		return result
	end

	Properties.FindFirstObjWhichIsA = function(class)
		local classList = Properties.ClassLists[class] or {}
		if classList and #classList > 0 then
			return classList[1]
		end

		return nil
	end

	Properties.ComputeConflicts = function(p)
		local maxConflictCheck = Settings.Properties.MaxConflictCheck
		local sList = Explorer.Selection.List
		local classLists = Properties.ClassLists
		local stringSplit = string.split
		local t_clear = table.clear
		local conflictIgnore = Properties.ConflictIgnore
		local conflictMap = {}
		local propList = p and { p } or props

		if p then
			local gName = p.Class .. "." .. p.Name
			autoUpdateObjs[gName] = nil
			local subProps = Properties.ConflictSubProps[p.ValueType.Name] or {}
			for i = 1, #subProps do
				autoUpdateObjs[gName .. "." .. subProps[i]] = nil
			end
		else
			table.clear(autoUpdateObjs)
		end

		if #sList > 0 then
			for i = 1, #propList do
				local prop = propList[i]
				local propName, propClass = prop.Name, prop.Class
				local typeData = prop.RootType or prop.ValueType
				local typeName = typeData.Name
				local attributeName = prop.AttributeName
				local gName = propClass .. "." .. propName

				local checked = 0
				local subProps = Properties.ConflictSubProps[typeName] or {}
				local subPropCount = #subProps
				local toCheck = subPropCount + 1
				local conflictsFound = 0
				local indexNames = {}
				local ignored = conflictIgnore[propClass] and conflictIgnore[propClass][propName]
				local truthyCheck = (typeName == "PhysicalProperties")
				local isAttribute = prop.IsAttribute
				local isMultiType = prop.MultiType

				t_clear(conflictMap)

				-- safeRead: return the object's property value safely, but skip Dex "virtual" props (Tags / AddTag)
				local function safeRead(o, name, p)
					-- If there's no object, nothing to read
					if not o then
						return nil
					end

					-- If prop table indicates it's a tag or the Add Tag pseudo-row, skip reading from the instance.
					-- This avoids Roblox attempting `instance["Add Tag..."]` which errors.
					if p and (p.IsTag or p.IsAddTagButton or p.SpecialRow == "AddTag" or p.Category == "Tags") then
						return nil
					end

					-- Otherwise do a protected read
					local ok, res = pcall(function()
						return o[name]
					end)
					return ok and res or nil
				end

				if not isMultiType then
					local firstVal, firstObj, firstSet
					local classList = classLists[prop.Class] or {}
					for c = 1, #classList do
						local obj = classList[c]
						if not firstSet then
							if isAttribute then
								firstVal = getAttribute(obj, attributeName)
								if firstVal ~= nil then
									firstObj = obj
									firstSet = true
								end
							else
								firstVal = safeRead(obj, propName, prop)
								firstObj = obj
								firstSet = true
							end
							if ignored then
								break
							end
						else
							local propVal, skip
							if isAttribute then
								propVal = getAttribute(obj, attributeName)
								if propVal == nil then
									skip = true
								end
							else
								propVal = safeRead(obj, propName, prop)
							end

							if not skip then
								if not conflictMap[1] then
									if truthyCheck then
										if (firstVal and true or false) ~= (propVal and true or false) then
											conflictMap[1] = true
											conflictsFound = conflictsFound + 1
										end
									elseif firstVal ~= propVal then
										conflictMap[1] = true
										conflictsFound = conflictsFound + 1
									end
								end

								if subPropCount > 0 then
									for sPropInd = 1, subPropCount do
										local indexes = indexNames[sPropInd]
										if not indexes then
											indexes = stringSplit(subProps[sPropInd], ".")
											indexNames[sPropInd] = indexes
										end

										local firstValSub = firstVal
										local propValSub = propVal

										for j = 1, #indexes do
											if not firstValSub or not propValSub then
												break
											end -- PhysicalProperties
											local indexName = indexes[j]
											firstValSub = firstValSub[indexName]
											propValSub = propValSub[indexName]
										end

										local mapInd = sPropInd + 1
										if not conflictMap[mapInd] and firstValSub ~= propValSub then
											conflictMap[mapInd] = true
											conflictsFound = conflictsFound + 1
										end
									end
								end

								if conflictsFound == toCheck then
									break
								end
							end
						end

						checked = checked + 1
						if checked == maxConflictCheck then
							break
						end
					end

					if not conflictMap[1] then
						autoUpdateObjs[gName] = firstObj
					end
					for sPropInd = 1, subPropCount do
						if not conflictMap[sPropInd + 1] then
							autoUpdateObjs[gName .. "." .. subProps[sPropInd]] = firstObj
						end
					end
				end
			end
		end

		if p then
			Properties.Refresh()
		end
	end

	-- Fetches the properties to be displayed based on the explorer selection
	Properties.ShowExplorerProps = function()
		local maxConflictCheck = Settings.Properties.MaxConflictCheck
		local sList = Explorer.Selection.List
		local foundClasses = {}
		local propCount = 1
		local elevated = Main.Elevated
		local showDeprecated, showHidden = Settings.Properties.ShowDeprecated, Settings.Properties.ShowHidden
		local Classes = API.Classes
		local classLists = {}
		local lower = string.lower
		local RMDCustomOrders = RMD.PropertyOrders
		local getAttributes = game.GetAttributes
		local maxAttrs = Settings.Properties.MaxAttributes
		local showingAttrs = Settings.Properties.ShowAttributes
		local foundAttrs = {}
		local attrCount = 0
		local typeof = typeof
		local typeNameConvert = Properties.TypeNameConvert

		table.clear(props)

		for i = 1, #sList do
			local node = sList[i]
			local obj = node.Obj
			local class = node.Class
			if not class then
				class = obj.ClassName
				node.Class = class
			end

			local apiClass = Classes[class]
			while apiClass do
				local APIClassName = apiClass.Name
				if not foundClasses[APIClassName] then
					local apiProps = indexableProps[APIClassName]
					if not apiProps then
						apiProps = Properties.GetIndexableProps(obj, apiClass)
						indexableProps[APIClassName] = apiProps
					end

					for i = 1, #apiProps do
						local prop = apiProps[i]
						local tags = prop.Tags
						if (not tags.Deprecated or showDeprecated) and (not tags.Hidden or showHidden) then
							props[propCount] = prop
							propCount = propCount + 1
						end
					end
					foundClasses[APIClassName] = true
				end

				local classList = classLists[APIClassName]
				if not classList then
					classList = {}
					classLists[APIClassName] = classList
				end
				classList[#classList + 1] = obj

				apiClass = apiClass.Superclass
			end

			if showingAttrs and attrCount < maxAttrs then
				local attrs = getAttributes(obj)
				for name, val in pairs(attrs) do
					local typ = typeof(val)
					if not foundAttrs[name] then
						local category = (typ == "Instance" and "Class") or (typ == "EnumItem" and "Enum") or "Other"
						local valType = { Name = typeNameConvert[typ] or typ, Category = category }
						local attrProp = {
							IsAttribute = true,
							Name = "ATTR_" .. name,
							AttributeName = name,
							DisplayName = name,
							Class = "Instance",
							ValueType = valType,
							Category = "Attributes",
							Tags = {},
						}
						props[propCount] = attrProp
						propCount = propCount + 1
						attrCount = attrCount + 1
						foundAttrs[name] = { typ, attrProp }
						if attrCount == maxAttrs then
							break
						end
					elseif foundAttrs[name][1] ~= typ then
						foundAttrs[name][2].MultiType = true
						foundAttrs[name][2].Tags.ReadOnly = true
						foundAttrs[name][2].ValueType = { Name = "string" }
					end
				end
			end
		end

		-- Gather tags from selected instances
		if Settings.Properties.ShowTags then
			for i = 1, #sList do
				local obj = sList[i].Obj
				local tags = obj:GetTags()

				for _, tagName in ipairs(tags) do
					local tagProp = {
						Name = "TAG_" .. tagName,
						DisplayName = tagName,
						Class = obj.ClassName,
						ValueType = { Name = "string", Category = "Primitive" },
						Category = "Tags",
						Tags = {},
						IsTag = true,
						TagName = tagName,
						Depth = 1,
					}
					props[propCount] = tagProp
					propCount = propCount + 1
				end
			end

			-- Add "Add Tag" button
			props[propCount] = Properties.ViewTagsProp
			propCount = propCount + 1
		end

		table.sort(props, function(a, b)
			if a.Category ~= b.Category then
				return (categoryOrder[a.Category] or 9999) < (categoryOrder[b.Category] or 9999)
			else
				local aOrder = (RMDCustomOrders[a.Class] and RMDCustomOrders[a.Class][a.Name]) or 9999999
				local bOrder = (RMDCustomOrders[b.Class] and RMDCustomOrders[b.Class][b.Name]) or 9999999
				if aOrder ~= bOrder then
					return aOrder < bOrder
				else
					return lower(a.Name) < lower(b.Name)
				end
			end
		end)

		-- Find conflicts and get auto-update instances
		Properties.ClassLists = classLists
		Properties.ComputeConflicts()
		--warn("CONFLICT",tick()-start)
		if #props > 0 then
			props[#props + 1] = Properties.AddAttributeProp
		end

		Properties.Update()
		Properties.Refresh()
	end

	Properties.UpdateView = function()
		local maxEntries = math.ceil(propsFrame.AbsoluteSize.Y / 23)
		local maxX = propsFrame.AbsoluteSize.X
		local totalWidth = Properties.ViewWidth + Properties.MinInputWidth

		scrollV.VisibleSpace = maxEntries
		scrollV.TotalSpace = #viewList + 1
		scrollH.VisibleSpace = maxX
		scrollH.TotalSpace = totalWidth

		scrollV.Gui.Visible = #viewList + 1 > maxEntries
		scrollH.Gui.Visible = Settings.Properties.ScaleType == 0 and totalWidth > maxX

		local oldSize = propsFrame.Size
		propsFrame.Size = UDim2.new(1, (scrollV.Gui.Visible and -16 or 0), 1, (scrollH.Gui.Visible and -39 or -23))
		if oldSize ~= propsFrame.Size then
			Properties.UpdateView()
		else
			scrollV:Update()
			scrollH:Update()

			if scrollV.Gui.Visible and scrollH.Gui.Visible then
				scrollV.Gui.Size = UDim2.new(0, 16, 1, -39)
				scrollH.Gui.Size = UDim2.new(1, -16, 0, 16)
				Properties.Window.GuiElems.Content.ScrollCorner.Visible = true
			else
				scrollV.Gui.Size = UDim2.new(0, 16, 1, -23)
				scrollH.Gui.Size = UDim2.new(1, 0, 0, 16)
				Properties.Window.GuiElems.Content.ScrollCorner.Visible = false
			end

			Properties.Index = scrollV.Index
		end
	end

	Properties.MakeSubProp = function(prop, subName, valueType, displayName)
		local subProp = {}
		for i, v in pairs(prop) do
			subProp[i] = v
		end
		subProp.RootType = subProp.RootType or subProp.ValueType
		subProp.ValueType = valueType
		subProp.SubName = subProp.SubName and (subProp.SubName .. subName) or subName
		subProp.DisplayName = displayName

		return subProp
	end

	Properties.GetExpandedProps = function(prop) -- TODO: Optimize using table
		local result = {}
		local typeData = prop.ValueType
		local typeName = typeData.Name
		local makeSubProp = Properties.MakeSubProp

		if typeName == "Vector2" then
			result[1] = makeSubProp(prop, ".X", { Name = "float" })
			result[2] = makeSubProp(prop, ".Y", { Name = "float" })
		elseif typeName == "Vector3" then
			result[1] = makeSubProp(prop, ".X", { Name = "float" })
			result[2] = makeSubProp(prop, ".Y", { Name = "float" })
			result[3] = makeSubProp(prop, ".Z", { Name = "float" })
		elseif typeName == "CFrame" then
			result[1] = makeSubProp(prop, ".Position", { Name = "Vector3" })
			result[2] = makeSubProp(prop, ".RightVector", { Name = "Vector3" })
			result[3] = makeSubProp(prop, ".UpVector", { Name = "Vector3" })
			result[4] = makeSubProp(prop, ".LookVector", { Name = "Vector3" })
		elseif typeName == "UDim" then
			result[1] = makeSubProp(prop, ".Scale", { Name = "float" })
			result[2] = makeSubProp(prop, ".Offset", { Name = "int" })
		elseif typeName == "UDim2" then
			result[1] = makeSubProp(prop, ".X", { Name = "UDim" })
			result[2] = makeSubProp(prop, ".Y", { Name = "UDim" })
		elseif typeName == "Rect" then
			result[1] = makeSubProp(prop, ".Min.X", { Name = "float" }, "X0")
			result[2] = makeSubProp(prop, ".Min.Y", { Name = "float" }, "Y0")
			result[3] = makeSubProp(prop, ".Max.X", { Name = "float" }, "X1")
			result[4] = makeSubProp(prop, ".Max.Y", { Name = "float" }, "Y1")
		elseif typeName == "PhysicalProperties" then
			result[1] = makeSubProp(prop, ".Density", { Name = "float" })
			result[2] = makeSubProp(prop, ".Elasticity", { Name = "float" })
			result[3] = makeSubProp(prop, ".ElasticityWeight", { Name = "float" })
			result[4] = makeSubProp(prop, ".Friction", { Name = "float" })
			result[5] = makeSubProp(prop, ".FrictionWeight", { Name = "float" })
		elseif typeName == "Ray" then
			result[1] = makeSubProp(prop, ".Origin", { Name = "Vector3" })
			result[2] = makeSubProp(prop, ".Direction", { Name = "Vector3" })
		elseif typeName == "NumberRange" then
			result[1] = makeSubProp(prop, ".Min", { Name = "float" })
			result[2] = makeSubProp(prop, ".Max", { Name = "float" })
		elseif typeName == "Faces" then
			result[1] = makeSubProp(prop, ".Back", { Name = "bool" })
			result[2] = makeSubProp(prop, ".Bottom", { Name = "bool" })
			result[3] = makeSubProp(prop, ".Front", { Name = "bool" })
			result[4] = makeSubProp(prop, ".Left", { Name = "bool" })
			result[5] = makeSubProp(prop, ".Right", { Name = "bool" })
			result[6] = makeSubProp(prop, ".Top", { Name = "bool" })
		elseif typeName == "Axes" then
			result[1] = makeSubProp(prop, ".X", { Name = "bool" })
			result[2] = makeSubProp(prop, ".Y", { Name = "bool" })
			result[3] = makeSubProp(prop, ".Z", { Name = "bool" })
		end

		if
			(prop.Name == "SoundId" and prop.Class == "Sound") or (prop.Name == "Asset" and prop.Class == "AudioPlayer")
		then
			local preview = {}
			local preview = {}
			for k, v in pairs(Properties.SoundPreviewProp) do
				preview[k] = v
			end
			preview.Class = prop.Class
			preview.Category = prop.Category
			preview.IsSoundPreview = true
			result[1] = preview
		end

		return result
	end

	Properties.Update = function()
		table.clear(viewList)

		local nameWidthCache = Properties.NameWidthCache
		local lastCategory
		local count = 1
		local maxWidth, maxDepth = 0, 1

		local textServ = service.TextService
		local getTextSize = textServ.GetTextSize
		local font = Enum.Font.SourceSans
		local size = Vector2.new(math.huge, 20)
		local stringSplit = string.split
		local entryIndent = Properties.EntryIndent
		local isFirstScaleType = Settings.Properties.ScaleType == 0
		local find, lower = string.find, string.lower
		local searchText = (#Properties.SearchText > 0 and lower(Properties.SearchText))

		local function recur(props, depth)
			for i = 1, #props do
				local prop = props[i]
				local propName = prop.Name
				local subName = prop.SubName
				local category = prop.Category

				local visible
				if searchText and depth == 1 then
					if find(lower(propName), searchText, 1, true) then
						visible = true
					end
				else
					visible = true
				end

				if visible and lastCategory ~= category then
					viewList[count] = { CategoryName = category }
					count = count + 1
					lastCategory = category
				end

				if (expanded["CAT_" .. category] and visible) or prop.SpecialRow then
					if depth > 1 then
						prop.Depth = depth
						if depth > maxDepth then
							maxDepth = depth
						end
					end

					if isFirstScaleType then
						local nameArr = subName and stringSplit(subName, ".")
						local displayName = prop.DisplayName or (nameArr and nameArr[#nameArr]) or propName

						local nameWidth = nameWidthCache[displayName]
						if not nameWidth then
							nameWidth = getTextSize(textServ, displayName, 14, font, size).X
							nameWidthCache[displayName] = nameWidth
						end

						local totalWidth = nameWidth + entryIndent * depth
						if totalWidth > maxWidth then
							maxWidth = totalWidth
						end
					end

					viewList[count] = prop
					count = count + 1

					local fullName = prop.Class .. "." .. prop.Name .. (prop.SubName or "")
					if not prop.IsTag and expanded[fullName] then
						local nextDepth = depth + 1
						local expandedProps = Properties.GetExpandedProps(prop)
						if #expandedProps > 0 then
							recur(expandedProps, nextDepth)
						end
					end
				end
			end
		end
		recur(props, 1)

		inputProp = nil
		Properties.ViewWidth = maxWidth + 9 + Properties.EntryOffset
		Properties.UpdateView()
	end

	Properties.NewPropEntry = function(index)
		local newEntry = Properties.EntryTemplate:Clone()
		local nameFrame = newEntry.NameFrame
		local valueFrame = newEntry.ValueFrame
		local newCheckbox = Lib.Checkbox.new(0)
		newCheckbox.Gui.Position = UDim2.new(0, 3, 0, 3)
		newCheckbox.Gui.Parent = valueFrame
		newCheckbox.OnInput:Connect(function()
			local prop = viewList[index + Properties.Index]
			if not prop then
				return
			end

			if prop.ValueType.Name == "PhysicalProperties" then
				Properties.SetProp(prop, newCheckbox.Toggled and true or nil)
			else
				Properties.SetProp(prop, newCheckbox.Toggled)
			end
		end)
		checkboxes[index] = newCheckbox

		local iconFrame = Main.MiscIcons:GetLabel()
		iconFrame.Position = UDim2.new(0, 2, 0, 3)
		iconFrame.Parent = newEntry.ValueFrame.RightButton

		newEntry.Position = UDim2.new(0, 0, 0, 23 * (index - 1))

		nameFrame.Expand.InputBegan:Connect(function(input)
			local prop = viewList[index + Properties.Index]
			if not prop or input.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end

			local fullName = (prop.CategoryName and "CAT_" .. prop.CategoryName)
				or prop.Class .. "." .. prop.Name .. (prop.SubName or "")

			Main.MiscIcons:DisplayByKey(
				newEntry.NameFrame.Expand.Icon,
				expanded[fullName] and "Collapse_Over" or "Expand_Over"
			)
		end)

		nameFrame.Expand.InputEnded:Connect(function(input)
			local prop = viewList[index + Properties.Index]
			if not prop or input.UserInputType ~= Enum.UserInputType.MouseMovement then
				return
			end

			local fullName = (prop.CategoryName and "CAT_" .. prop.CategoryName)
				or prop.Class .. "." .. prop.Name .. (prop.SubName or "")

			Main.MiscIcons:DisplayByKey(newEntry.NameFrame.Expand.Icon, expanded[fullName] and "Collapse" or "Expand")
		end)

		nameFrame.Expand.MouseButton1Down:Connect(function()
			local prop = viewList[index + Properties.Index]
			if not prop then
				return
			end

			local fullName = (prop.CategoryName and "CAT_" .. prop.CategoryName)
				or prop.Class .. "." .. prop.Name .. (prop.SubName or "")
			if
				not prop.CategoryName
				and not Properties.ExpandableTypes[prop.ValueType and prop.ValueType.Name]
				and not Properties.ExpandableProps[fullName]
			then
				return
			end

			expanded[fullName] = not expanded[fullName]
			Properties.Update()
			Properties.Refresh()
		end)

		nameFrame.PropName.InputBegan:Connect(function(input)
			local prop = viewList[index + Properties.Index]
			if not prop then
				return
			end
			if input.UserInputType == Enum.UserInputType.MouseMovement and not nameFrame.PropName.TextFits then
				local fullNameFrame = Properties.FullNameFrame
				local nameArr = string.split(prop.Class .. "." .. prop.Name .. (prop.SubName or ""), ".")
				local dispName = prop.DisplayName or nameArr[#nameArr]
				local sizeX =
					service.TextService:GetTextSize(dispName, 14, Enum.Font.SourceSans, Vector2.new(math.huge, 20)).X

				fullNameFrame.TextLabel.Text = dispName
				--fullNameFrame.Position = UDim2.new(0,Properties.EntryIndent*(prop.Depth or 1) + Properties.EntryOffset,0,23*(index-1))
				fullNameFrame.Size = UDim2.new(0, sizeX + 4, 0, 22)
				fullNameFrame.Visible = true
				Properties.FullNameFrameIndex = index
				Properties.FullNameFrameAttach.SetData(fullNameFrame, { Target = nameFrame })
				Properties.FullNameFrameAttach.Enable()
			end
		end)

		nameFrame.PropName.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement and Properties.FullNameFrameIndex == index then
				Properties.FullNameFrame.Visible = false
				Properties.FullNameFrameAttach.Disable()
			end
		end)

		valueFrame.ValueBox.MouseButton1Down:Connect(function()
			local prop = viewList[index + Properties.Index]
			if not prop then
				return
			end

			Properties.SetInputProp(prop, index)
		end)

		valueFrame.ColorButton.MouseButton1Down:Connect(function()
			local prop = viewList[index + Properties.Index]
			if not prop then
				return
			end

			Properties.SetInputProp(prop, index, "color")
		end)

		valueFrame.RightButton.MouseButton1Click:Connect(function()
			local prop = viewList[index + Properties.Index]
			if not prop then
				return
			end

			local fullName = prop.Class .. "." .. prop.Name .. (prop.SubName or "")
			local inputFullName = inputProp and (inputProp.Class .. "." .. inputProp.Name .. (inputProp.SubName or ""))

			if fullName == inputFullName and inputProp.ValueType.Category == "Class" then
				inputProp = nil
				Properties.SetProp(prop, nil)
			else
				-- If this is a tag row and user clicked the right-button, remove tag
				if prop.IsTag then
					-- right-button click: remove tag
					Properties.RemoveTag(prop.TagName)
				else
					Properties.SetInputProp(prop, index, "right")
				end
			end
		end)

		nameFrame.ToggleAttributes.MouseButton1Click:Connect(function()
			Settings.Properties.ShowAttributes = not Settings.Properties.ShowAttributes
			Properties.ShowExplorerProps()
		end)

		newEntry.RowButton.MouseButton1Click:Connect(function()
			local prop = viewList[index + Properties.Index]
			if not prop then
				return
			end

			if prop.SpecialRow == "AddAttribute" then
				Properties.DisplayAddAttributeWindow()
			elseif prop.SpecialRow == "AddTag" then
				Properties.DisplayAddTagWindow()
			end
		end)

		newEntry.EditAttributeButton.MouseButton1Down:Connect(function()
			local prop = viewList[index + Properties.Index]
			if not prop then
				return
			end

			Properties.DisplayAttributeContext(prop)
		end)

		valueFrame.SoundPreview.ControlButton.MouseButton1Click:Connect(function()
			if Properties.PreviewSound and Properties.PreviewSound.Playing then
				Properties.SetSoundPreview(false)
			else
				local soundObj = Properties.FindFirstObjWhichIsA("Sound")
					or Properties.FindFirstObjWhichIsA("AudioPlayer")
				if soundObj then
					Properties.SetSoundPreview(soundObj)
				end
			end
		end)

		valueFrame.SoundPreview.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end

			local releaseEvent, mouseEvent
			releaseEvent = service.UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
					return
				end
				releaseEvent:Disconnect()
				mouseEvent:Disconnect()
			end)

			local timeLine = newEntry.ValueFrame.SoundPreview.TimeLine
			local soundObj = Properties.FindFirstObjWhichIsA("Sound") or Properties.FindFirstObjWhichIsA("AudioPlayer")
			if soundObj then
				Properties.SetSoundPreview(soundObj, true)
			end

			local function update(input)
				local sound = Properties.PreviewSound
				if not sound or sound.TimeLength == 0 then
					return
				end

				local mouseX = input.Position.X
				local timeLineSize = timeLine.AbsoluteSize
				local relaX = mouseX - timeLine.AbsolutePosition.X

				if timeLineSize.X <= 1 then
					return
				end
				if relaX < 0 then
					relaX = 0
				elseif relaX >= timeLineSize.X then
					relaX = timeLineSize.X - 1
				end

				local perc = (relaX / (timeLineSize.X - 1))
				sound.TimePosition = perc * sound.TimeLength
				timeLine.Slider.Position = UDim2.new(perc, -4, 0, -8)
			end
			update(input)

			mouseEvent = service.UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseMovement then
					update(input)
				end
			end)
		end)

		newEntry.Parent = propsFrame

		return {
			Gui = newEntry,
			GuiElems = {
				NameFrame = nameFrame,
				ValueFrame = valueFrame,
				PropName = nameFrame.PropName,
				ValueBox = valueFrame.ValueBox,
				Expand = nameFrame.Expand,
				ColorButton = valueFrame.ColorButton,
				ColorPreview = valueFrame.ColorButton.ColorPreview,
				Gradient = valueFrame.ColorButton.ColorPreview.UIGradient,
				EnumArrow = valueFrame.EnumArrow,
				Checkbox = valueFrame.Checkbox,
				RightButton = valueFrame.RightButton,
				RightButtonIcon = iconFrame,
				RowButton = newEntry.RowButton,
				EditAttributeButton = newEntry.EditAttributeButton,
				ToggleAttributes = nameFrame.ToggleAttributes,
				SoundPreview = valueFrame.SoundPreview,
				SoundPreviewSlider = valueFrame.SoundPreview.TimeLine.Slider,
			},
		}
	end

	Properties.GetSoundPreviewEntry = function()
		for i = 1, #viewList do
			local p = viewList[i]
			if type(p) == "table" and p.IsSoundPreview then
				return propEntries[i - Properties.Index]
			end
		end
	end

	Properties.SetSoundPreview = function(soundObj: Sound?, noplay: boolean)
		local sound = Properties.PreviewSound
		if not sound then
			sound = Instance.new("Sound")
			sound.Name = "Preview"
			sound.Paused:Connect(function()
				local entry = Properties.GetSoundPreviewEntry()
				if entry then
					Main.MiscIcons:DisplayByKey(entry.GuiElems.SoundPreview.ControlButton.Icon, "Play")
				end
			end)
			sound.Resumed:Connect(function()
				Properties.Refresh()
			end)
			sound.Ended:Connect(function()
				local entry = Properties.GetSoundPreviewEntry()
				if entry then
					entry.GuiElems.SoundPreviewSlider.Position = UDim2.new(0, -4, 0, -8)
				end
				Properties.Refresh()
			end)
			sound.Parent = window.Gui
			Properties.PreviewSound = sound
		end

		if not soundObj then
			sound:Pause()
			for i, v in pairs(sound:GetChildren()) do
				v:Destroy()
			end
		else
			local newId
			if soundObj:IsA("Sound") then
				newId = sound.SoundId ~= soundObj.SoundId
				sound.SoundId = soundObj.SoundId
				sound.PlaybackSpeed = soundObj.PlaybackSpeed
				sound.Volume = soundObj.Volume
			elseif soundObj:IsA("AudioPlayer") then
				newId = sound.SoundId ~= soundObj.Asset
				sound.SoundId = soundObj.Asset
				if soundObj:FindFirstChild("PlaybackSpeed") then
					sound.PlaybackSpeed = soundObj.PlaybackSpeed
				end
				if soundObj:FindFirstChild("Volume") then
					sound.Volume = soundObj.Volume
				end
			else
				return
			end
			if newId then
				for _, v in ipairs(sound:GetChildren()) do
					v:Destroy()
				end
				sound.TimePosition = 0
			end
			for _, v in ipairs(soundObj:GetChildren()) do
				v:Clone().Parent = sound
			end
			if not noplay then
				sound:Resume()
			end
			task.spawn(function()
				local previewTime = tick()
				Properties.SoundPreviewTime = previewTime
				while previewTime == Properties.SoundPreviewTime and sound.Playing do
					local entry = Properties.GetSoundPreviewEntry()
					if entry then
						local tl = sound.TimeLength
						local perc = sound.TimePosition / (tl == 0 and 1 or tl)
						entry.GuiElems.SoundPreviewSlider.Position = UDim2.new(perc, -4, 0, -8)
					end
					Lib.FastWait()
				end
			end)
			Properties.Refresh()
		end
	end

	Properties.DisplayAttributeContext = function(prop)
		local context = Properties.AttributeContext
		if not context then
			context = Lib.ContextMenu.new()
			context.Iconless = true
			context.Width = 80
		end
		context:Clear()

		context:Add({
			Name = "Edit",
			OnClick = function()
				Properties.DisplayAddAttributeWindow(prop)
			end,
		})
		context:Add({
			Name = "Delete",
			OnClick = function()
				Properties.SetProp(prop, nil, true)
				Properties.ShowExplorerProps()
			end,
		})

		context:Show()
	end

	Properties.DisplayAddAttributeWindow = function(editAttr)
		local win = Properties.AddAttributeWindow
		if not win then
			win = Lib.Window.new()
			win.Alignable = false
			win.Resizable = false
			win:SetTitle("Add Attribute")
			win:SetSize(200, 130)

			local saveButton = Lib.Button.new()
			local nameLabel = Lib.Label.new()
			nameLabel.Text = "Name"
			nameLabel.Position = UDim2.new(0, 30, 0, 10)
			nameLabel.Size = UDim2.new(0, 40, 0, 20)
			win:Add(nameLabel)

			local nameBox = Lib.ViewportTextBox.new()
			nameBox.Position = UDim2.new(0, 75, 0, 10)
			nameBox.Size = UDim2.new(0, 120, 0, 20)
			win:Add(nameBox, "NameBox")
			nameBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
				saveButton:SetDisabled(#nameBox:GetText() == 0)
			end)

			local typeLabel = Lib.Label.new()
			typeLabel.Text = "Type"
			typeLabel.Position = UDim2.new(0, 30, 0, 40)
			typeLabel.Size = UDim2.new(0, 40, 0, 20)
			win:Add(typeLabel)

			local typeChooser = Lib.DropDown.new()
			typeChooser.CanBeEmpty = false
			typeChooser.Position = UDim2.new(0, 75, 0, 40)
			typeChooser.Size = UDim2.new(0, 120, 0, 20)
			typeChooser:SetOptions(Properties.AllowedAttributeTypes)
			win:Add(typeChooser, "TypeChooser")

			local errorLabel = Lib.Label.new()
			errorLabel.Text = ""
			errorLabel.Position = UDim2.new(0, 5, 1, -45)
			errorLabel.Size = UDim2.new(1, -10, 0, 20)
			errorLabel.TextColor3 = Settings.Theme.Important
			win.ErrorLabel = errorLabel
			win:Add(errorLabel, "Error")

			local cancelButton = Lib.Button.new()
			cancelButton.Text = "Cancel"
			cancelButton.Position = UDim2.new(1, -97, 1, -25)
			cancelButton.Size = UDim2.new(0, 92, 0, 20)
			cancelButton.OnClick:Connect(function()
				win:Close()
			end)
			win:Add(cancelButton)

			saveButton.Text = "Save"
			saveButton.Position = UDim2.new(0, 5, 1, -25)
			saveButton.Size = UDim2.new(0, 92, 0, 20)
			saveButton.OnClick:Connect(function()
				local name = nameBox:GetText()
				if #name > 100 then
					errorLabel.Text = "Error: Name over 100 chars"
					return
				elseif name:sub(1, 3) == "RBX" then
					errorLabel.Text = "Error: Name begins with 'RBX'"
					return
				end

				local typ = typeChooser.Selected
				local valType = { Name = Properties.TypeNameConvert[typ] or typ, Category = "DataType" }
				local attrProp = {
					IsAttribute = true,
					Name = "ATTR_" .. name,
					AttributeName = name,
					DisplayName = name,
					Class = "Instance",
					ValueType = valType,
					Category = "Attributes",
					Tags = {},
				}

				Settings.Properties.ShowAttributes = true
				Properties.SetProp(
					attrProp,
					Properties.DefaultPropValue[valType.Name],
					true,
					Properties.EditingAttribute
				)
				Properties.ShowExplorerProps()
				win:Close()
			end)
			win:Add(saveButton, "SaveButton")

			Properties.AddAttributeWindow = win
		end

		Properties.EditingAttribute = editAttr
		win:SetTitle(editAttr and "Edit Attribute " .. editAttr.AttributeName or "Add Attribute")
		win.Elements.Error.Text = ""
		win.Elements.NameBox:SetText("")
		win.Elements.SaveButton:SetDisabled(true)
		win.Elements.TypeChooser:SetSelected(1)
		win:Show()
	end

	Properties.DisplayAddTagWindow = function()
		local win = Properties.AddTagWindow
		if not win then
			win = Lib.Window.new()
			win.Alignable = false
			win.Resizable = false
			win:SetTitle("Add Tag")
			win:SetSize(200, 100)

			-- Label: Tag Name
			local nameLabel = Lib.Label.new()
			nameLabel.Text = "Tag"
			nameLabel.Position = UDim2.new(0, 30, 0, 10)
			nameLabel.Size = UDim2.new(0, 40, 0, 20)
			win:Add(nameLabel)

			-- Textbox: Tag Name input
			local nameBox = Lib.ViewportTextBox.new()
			nameBox.Position = UDim2.new(0, 75, 0, 10)
			nameBox.Size = UDim2.new(0, 110, 0, 20)
			win:Add(nameBox, "NameBox")

			-- Error label (below textbox)
			local errorLabel = Lib.Label.new()
			errorLabel.Text = ""
			errorLabel.Position = UDim2.new(0, 5, 1, -45)
			errorLabel.Size = UDim2.new(1, -10, 0, 20)
			errorLabel.TextColor3 = Settings.Theme.Important
			win.ErrorLabel = errorLabel
			win:Add(errorLabel, "Error")

			-- Cancel Button
			local cancelButton = Lib.Button.new()
			cancelButton.Text = "Cancel"
			cancelButton.Position = UDim2.new(1, -97, 1, -25)
			cancelButton.Size = UDim2.new(0, 92, 0, 20)
			cancelButton.OnClick:Connect(function()
				win:Close()
			end)
			win:Add(cancelButton)

			-- Save Button
			local saveButton = Lib.Button.new()
			saveButton.Text = "Save"
			saveButton.Position = UDim2.new(0, 5, 1, -25)
			saveButton.Size = UDim2.new(0, 92, 0, 20)
			win:Add(saveButton, "SaveButton")

			-- Enable/disable save button based on text
			nameBox.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
				saveButton:SetDisabled(#nameBox:GetText() == 0)
			end)
			saveButton:SetDisabled(true)

			-- Save logic
			saveButton.OnClick:Connect(function()
				local tagName = nameBox:GetText()

				if #tagName > 100 then
					errorLabel.Text = "Error: Tag name over 100 chars"
					return
				elseif tagName:sub(1, 3) == "RBX" then
					errorLabel.Text = "Error: Tag cannot start with 'RBX'"
					return
				end

				Properties.AddTag(tagName)
				win:Close()
			end)

			Properties.AddTagWindow = win
		end

		win:SetTitle("Add Tag")
		win.Elements.Error.Text = ""
		win.Elements.NameBox:SetText("")
		win.Elements.SaveButton:SetDisabled(true)
		win:Show()
	end

	Properties.AddTag = function(tagName)
		if not tagName or #tagName == 0 then
			return
		end

		-- Validate
		if #tagName > 100 then
			return Properties.DisplayError and Properties.DisplayError("Tag name over 100 chars")
		elseif tagName:sub(1, 3) == "RBX" then
			return Properties.DisplayError and Properties.DisplayError("Tag cannot start with 'RBX'")
		end

		local selection = Explorer.Selection.List
		if not selection or #selection == 0 then
			return
		end

		-- Make server calls and locally apply tags where possible.
		for i = 1, #selection do
			local node = selection[i]
			local obj = node and node.Obj
			if obj and obj:IsA("Instance") then
				-- Prevent duplicates locally
				local ok, tags = pcall(function()
					return obj:GetTags()
				end)
				local already = false
				if ok and tags then
					for _, t in ipairs(tags) do
						if t == tagName then
							already = true
							break
						end
					end
				end

				if not already then
					-- Try to invoke server to add the tag (use existing Dex remote)
					local s, res = pcall(function()
						return Dex_RemoteFunction:InvokeServer("addtag", obj, tagName)
					end)

					-- If server returns true or we succeeded, try local add (pcall to be safe)
					if s then
						pcall(function()
							obj:AddTag(tagName)
						end)
					else
						warn("AddTag server call failed:", res)
					end
				end
			end
		end

		-- Refresh the properties UI to show the new tags
		Properties.ShowExplorerProps()
	end

	-- Removes a tag from all selected instances, calls server, updates UI
	Properties.RemoveTag = function(tagName)
		if not tagName or #tagName == 0 then
			return
		end

		local selection = Explorer.Selection.List
		if not selection or #selection == 0 then
			return
		end

		for i = 1, #selection do
			local node = selection[i]
			local obj = node and node.Obj
			if obj and obj:IsA("Instance") then
				-- Check existence first
				local ok, tags = pcall(function()
					return obj:GetTags()
				end)
				local found = false
				if ok and tags then
					for _, t in ipairs(tags) do
						if t == tagName then
							found = true
							break
						end
					end
				end

				if found then
					local s, res = pcall(function()
						return Dex_RemoteFunction:InvokeServer("removetag", obj, tagName)
					end)

					if s then
						pcall(function()
							obj:RemoveTag(tagName)
						end)
					else
						warn("RemoveTag server call failed:", res)
					end
				end
			end
		end

		-- Refresh the properties UI
		Properties.ShowExplorerProps()
	end

	Properties.IsTextEditable = function(prop)
		local typeData = prop.ValueType
		local typeName = typeData.Name

		return typeName ~= "bool"
			and typeData.Category ~= "Enum"
			and typeData.Category ~= "Class"
			and typeName ~= "BrickColor"
	end

	Properties.DisplayEnumDropdown = function(entryIndex)
		local context = Properties.EnumContext
		if not context then
			context = Lib.ContextMenu.new()
			context.Iconless = true
			context.MaxHeight = 200
			context.ReverseYOffset = 22
			Properties.EnumDropdown = context
		end

		if not inputProp or inputProp.ValueType.Category ~= "Enum" then
			return
		end
		local prop = inputProp

		local entry = propEntries[entryIndex]
		local valueFrame = entry.GuiElems.ValueFrame

		local enum = Enum[prop.ValueType.Name]
		if not enum then
			return
		end

		local sorted = {}
		for name, enum in next, enum:GetEnumItems() do
			sorted[#sorted + 1] = enum
		end
		table.sort(sorted, function(a, b)
			return a.Name < b.Name
		end)

		context:Clear()

		local function onClick(name)
			if prop ~= inputProp then
				return
			end

			local enumItem = enum[name]
			inputProp = nil
			Properties.SetProp(prop, enumItem)
		end

		for i = 1, #sorted do
			local enumItem = sorted[i]
			context:Add({ Name = enumItem.Name, OnClick = onClick })
		end

		context.Width = valueFrame.AbsoluteSize.X
		context:Show(valueFrame.AbsolutePosition.X, valueFrame.AbsolutePosition.Y + 22)
	end

	Properties.DisplayBrickColorEditor = function(prop, entryIndex, col)
		local editor = Properties.BrickColorEditor
		if not editor then
			editor = Lib.BrickColorPicker.new()
			editor.Gui.DisplayOrder = Main.DisplayOrders.Menu
			editor.ReverseYOffset = 22

			editor.OnSelect:Connect(function(col)
				if not editor.CurrentProp or editor.CurrentProp.ValueType.Name ~= "BrickColor" then
					return
				end

				if editor.CurrentProp == inputProp then
					inputProp = nil
				end
				Properties.SetProp(editor.CurrentProp, BrickColor.new(col))
			end)

			editor.OnMoreColors:Connect(function() -- TODO: Special Case BasePart.BrickColor to BasePart.Color
				editor:Close()
				local colProp
				for i, v in pairs(API.Classes.BasePart.Properties) do
					if v.Name == "Color" then
						colProp = v
						break
					end
				end
				Properties.DisplayColorEditor(colProp, editor.SavedColor.Color)
			end)

			Properties.BrickColorEditor = editor
		end

		local entry = propEntries[entryIndex]
		local valueFrame = entry.GuiElems.ValueFrame

		editor.CurrentProp = prop
		editor.SavedColor = col
		if prop and prop.Class == "BasePart" and prop.Name == "BrickColor" then
			editor:SetMoreColorsVisible(true)
		else
			editor:SetMoreColorsVisible(false)
		end
		editor:Show(valueFrame.AbsolutePosition.X, valueFrame.AbsolutePosition.Y + 22)
	end

	Properties.DisplayColorEditor = function(prop, col)
		local editor = Properties.ColorEditor
		if not editor then
			editor = Lib.ColorPicker.new()

			editor.OnSelect:Connect(function(col)
				if not editor.CurrentProp then
					return
				end
				local typeName = editor.CurrentProp.ValueType.Name
				if typeName ~= "Color3" and typeName ~= "BrickColor" then
					return
				end

				local colVal = (typeName == "Color3" and col or BrickColor.new(col))

				if editor.CurrentProp == inputProp then
					inputProp = nil
				end
				Properties.SetProp(editor.CurrentProp, colVal)
			end)

			Properties.ColorEditor = editor
		end

		editor.CurrentProp = prop
		if col then
			editor:SetColor(col)
		else
			local firstVal = Properties.GetFirstPropVal(prop)
			if firstVal then
				editor:SetColor(firstVal)
			end
		end
		editor:Show()
	end

	Properties.DisplayNumberSequenceEditor = function(prop, seq)
		local editor = Properties.NumberSequenceEditor
		if not editor then
			editor = Lib.NumberSequenceEditor.new()

			editor.OnSelect:Connect(function(val)
				if not editor.CurrentProp or editor.CurrentProp.ValueType.Name ~= "NumberSequence" then
					return
				end

				if editor.CurrentProp == inputProp then
					inputProp = nil
				end
				Properties.SetProp(editor.CurrentProp, val)
			end)

			Properties.NumberSequenceEditor = editor
		end

		editor.CurrentProp = prop
		if seq then
			editor:SetSequence(seq)
		else
			local firstVal = Properties.GetFirstPropVal(prop)
			if firstVal then
				editor:SetSequence(firstVal)
			end
		end
		editor:Show()
	end

	Properties.DisplayColorSequenceEditor = function(prop, seq)
		local editor = Properties.ColorSequenceEditor
		if not editor then
			editor = Lib.ColorSequenceEditor.new()

			editor.OnSelect:Connect(function(val)
				if not editor.CurrentProp or editor.CurrentProp.ValueType.Name ~= "ColorSequence" then
					return
				end

				if editor.CurrentProp == inputProp then
					inputProp = nil
				end
				Properties.SetProp(editor.CurrentProp, val)
			end)

			Properties.ColorSequenceEditor = editor
		end

		editor.CurrentProp = prop
		if seq then
			editor:SetSequence(seq)
		else
			local firstVal = Properties.GetFirstPropVal(prop)
			if firstVal then
				editor:SetSequence(firstVal)
			end
		end
		editor:Show()
	end

	Properties.GetFirstPropVal = function(prop)
		local first = Properties.FindFirstObjWhichIsA(prop.Class)
		if first then
			return Properties.GetPropVal(prop, first)
		end
	end

	Properties.GetPropVal = function(prop, obj)
		-- PATCH: Prevent Dex from reading pseudo tag properties
		if prop.IsTag or prop.IsAddTagButton or prop.SpecialRow == "AddTag" or prop.Category == "Tags" then
			return nil
		end

		if prop.MultiType then
			return "<Multiple Types>"
		end
		if not obj then
			return
		end

		local propVal
		if prop.IsAttribute then
			propVal = getAttribute(obj, prop.AttributeName)
			if propVal == nil then
				return nil
			end

			local typ = typeof(propVal)
			local currentType = Properties.TypeNameConvert[typ] or typ
			if prop.RootType then
				if prop.RootType.Name ~= currentType then
					return nil
				end
			elseif prop.ValueType.Name ~= currentType then
				return nil
			end
		else
			propVal = obj[prop.Name]
		end
		if prop.SubName then
			local indexes = string.split(prop.SubName, ".")
			for i = 1, #indexes do
				local indexName = indexes[i]
				if #indexName > 0 and propVal then
					propVal = propVal[indexName]
				end
			end
		end

		return propVal
	end

	Properties.SelectObject = function(obj)
		if inputProp and inputProp.ValueType.Category == "Class" then
			local prop = inputProp
			inputProp = nil

			if isa(obj, prop.ValueType.Name) then
				Properties.SetProp(prop, obj)
			else
				Properties.Refresh()
			end

			return true
		end

		return false
	end

	Properties.DisplayProp = function(prop, entryIndex)
		if prop.IsTag or prop.IsAddTagButton or prop.Category == "Tags" and prop.SpecialRow then
			-- Hide all value UI elements for Add Tag row
			local entryData = propEntries[entryIndex]
			if entryData and entryData.GuiElems then
				local g = entryData.GuiElems
				if g.ValueBox then
					g.ValueBox.Visible = false
				end
				if g.ColorButton then
					g.ColorButton.Visible = false
				end
				if g.EnumArrow then
					g.EnumArrow.Visible = false
				end
				if g.Checkbox then
					g.Checkbox.Visible = false
				end
				if g.RightButton then
					g.RightButton.Visible = false
				end
				if g.SoundPreview then
					g.SoundPreview.Visible = false
				end
			end
			return
		end
		local propName = prop.Name
		local typeData = prop.ValueType
		local typeName = typeData.Name
		local tags = prop.Tags
		local gName = prop.Class .. "." .. prop.Name .. (prop.SubName or "")
		local propObj = autoUpdateObjs[gName]
		local entryData = propEntries[entryIndex]
		local UDim2 = UDim2

		local guiElems = entryData.GuiElems
		local valueFrame = guiElems.ValueFrame
		local valueBox = guiElems.ValueBox
		local colorButton = guiElems.ColorButton
		local colorPreview = guiElems.ColorPreview
		local gradient = guiElems.Gradient
		local enumArrow = guiElems.EnumArrow
		local checkbox = guiElems.Checkbox
		local rightButton = guiElems.RightButton
		local soundPreview = guiElems.SoundPreview

		local propVal = Properties.GetPropVal(prop, propObj)
		local inputFullName = inputProp and (inputProp.Class .. "." .. inputProp.Name .. (inputProp.SubName or ""))

		local offset = 4
		local endOffset = 6

		-- Offsetting the ValueBox for ValueType specific buttons
		if typeName == "Color3" or typeName == "BrickColor" or typeName == "ColorSequence" then
			colorButton.Visible = true
			enumArrow.Visible = false
			if propVal then
				gradient.Color = (typeName == "Color3" and ColorSequence.new(propVal))
					or (typeName == "BrickColor" and ColorSequence.new(propVal.Color))
					or propVal
			else
				gradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
			end
			colorPreview.BorderColor3 = (typeName == "ColorSequence" and Color3.new(1, 1, 1) or Color3.new(0, 0, 0))
			offset = 22
			endOffset = 24 + (typeName == "ColorSequence" and 20 or 0)
		elseif typeData.Category == "Enum" then
			colorButton.Visible = false
			enumArrow.Visible = not prop.Tags.ReadOnly
			endOffset = 22
		elseif (gName == inputFullName and typeData.Category == "Class") or typeName == "NumberSequence" then
			colorButton.Visible = false
			enumArrow.Visible = false
			endOffset = 26
		else
			colorButton.Visible = false
			enumArrow.Visible = false
		end

		if prop.IsTag then
			-- Tag Name Display
			valueBox.Visible = false
			checkbox.Visible = false
			soundPreview.Visible = false
			colorButton.Visible = false
			enumArrow.Visible = false

			-- Show the tag name as static text
			valueBox.Visible = true
			valueBox.Text = prop.TagName
			valueBox.TextColor3 = Settings.Theme.Text
			valueBox.ClearTextOnFocus = false
			valueBox.Active = false

			-- Show X button on right side to remove tag
			rightButton.Visible = true
			rightButton.Text = "X"
			rightButton.MouseButton1Click:Connect(function()
				Properties.RemoveTag(prop)
			end)

			return
		end

		valueBox.Position = UDim2.new(0, offset, 0, 0)
		valueBox.Size = UDim2.new(1, -endOffset, 1, 0)

		-- Right button
		if inputFullName == gName and typeData.Category == "Class" then
			Main.MiscIcons:DisplayByKey(guiElems.RightButtonIcon, "Delete")
			guiElems.RightButtonIcon.Visible = true
			rightButton.Text = ""
			rightButton.Visible = true
		elseif typeName == "NumberSequence" or typeName == "ColorSequence" then
			guiElems.RightButtonIcon.Visible = false
			rightButton.Text = "..."
			rightButton.Visible = true
		else
			rightButton.Visible = false
		end

		-- Displays the correct ValueBox for the ValueType, and sets it to the prop value
		if typeName == "bool" or typeName == "PhysicalProperties" then
			valueBox.Visible = false
			checkbox.Visible = true
			soundPreview.Visible = false
			checkboxes[entryIndex].Disabled = tags.ReadOnly
			if typeName == "PhysicalProperties" and autoUpdateObjs[gName] then
				checkboxes[entryIndex]:SetState(propVal and true or false)
			else
				checkboxes[entryIndex]:SetState(propVal)
			end
		elseif typeName == "SoundPlayer" then
			valueBox.Visible = false
			checkbox.Visible = false
			soundPreview.Visible = true
			local playing = Properties.PreviewSound and Properties.PreviewSound.Playing
			Main.MiscIcons:DisplayByKey(soundPreview.ControlButton.Icon, playing and "Pause" or "Play")
		else
			valueBox.Visible = true
			checkbox.Visible = false
			soundPreview.Visible = false

			if propVal ~= nil then
				if typeName == "Color3" then
					valueBox.Text = "[" .. Lib.ColorToBytes(propVal) .. "]"
				elseif typeData.Category == "Enum" then
					valueBox.Text = propVal.Name
				elseif Properties.RoundableTypes[typeName] and Settings.Properties.NumberRounding then
					local rawStr = Properties.ValueToString(prop, propVal)
					valueBox.Text = rawStr:gsub("-?%d+%.%d+", function(num)
						return tostring(tonumber(("%." .. Settings.Properties.NumberRounding .. "f"):format(num)))
					end)
				else
					valueBox.Text = Properties.ValueToString(prop, propVal)
				end
			else
				valueBox.Text = ""
			end

			valueBox.TextColor3 = tags.ReadOnly and Settings.Theme.PlaceholderText or Settings.Theme.Text
		end
	end

	function Properties.RemoveTag(prop)
		local obj = Explorer.Selection.List[1].Obj
		if not obj then
			return
		end

		local tag = prop.TagName
		Properties.Remote:InvokeServer("removetag", obj, tag)
		Properties.Refresh()
	end

	Properties.Refresh = function()
		local maxEntries = math.max(math.ceil(propsFrame.AbsoluteSize.Y / 23), 0)
		local maxX = propsFrame.AbsoluteSize.X
		local valueWidth = math.max(Properties.MinInputWidth, maxX - Properties.ViewWidth)
		local inputPropVisible = false
		local isa = game.IsA
		local UDim2 = UDim2
		local stringSplit = string.split
		local scaleType = Settings.Properties.ScaleType

		-- Clear connections
		for i = 1, #propCons do
			propCons[i]:Disconnect()
		end
		table.clear(propCons)

		-- Hide full name viewer
		Properties.FullNameFrame.Visible = false
		Properties.FullNameFrameAttach.Disable()

		for i = 1, maxEntries do
			local entryData = propEntries[i]
			if not propEntries[i] then
				entryData = Properties.NewPropEntry(i)
				propEntries[i] = entryData
			end

			local entry = entryData.Gui
			local guiElems = entryData.GuiElems
			local nameFrame = guiElems.NameFrame
			local propNameLabel = guiElems.PropName
			local valueFrame = guiElems.ValueFrame
			local expand = guiElems.Expand
			local valueBox = guiElems.ValueBox
			local propNameBox = guiElems.PropName
			local rightButton = guiElems.RightButton
			local editAttributeButton = guiElems.EditAttributeButton
			local toggleAttributes = guiElems.ToggleAttributes

			local prop = viewList[i + Properties.Index]
			if prop then
				local entryXOffset = (scaleType == 0 and scrollH.Index or 0)
				entry.Visible = true
				entry.Position = UDim2.new(0, -entryXOffset, 0, entry.Position.Y.Offset)
				entry.Size = UDim2.new(
					scaleType == 0 and 0 or 1,
					scaleType == 0 and Properties.ViewWidth + valueWidth or 0,
					0,
					22
				)

				if prop.SpecialRow then
					if prop.SpecialRow == "AddAttribute" then
						nameFrame.Visible = false
						valueFrame.Visible = false
						guiElems.RowButton.Visible = true
						guiElems.RowButton.Text = "Add Attribute"
						guiElems.RowButton.TextColor3 = Settings.Theme.Text
					elseif prop.SpecialRow == "AddTag" then
						nameFrame.Visible = false
						valueFrame.Visible = false
						guiElems.RowButton.Visible = true
						guiElems.RowButton.Text = "Add Tag..."
						guiElems.RowButton.TextColor3 = Settings.Theme.Text
					end
				else
					-- Revert special row stuff
					nameFrame.Visible = true
					guiElems.RowButton.Visible = false

					local depth = Properties.EntryIndent * (prop.Depth or 1)
					local leftOffset = depth + Properties.EntryOffset
					nameFrame.Position = UDim2.new(0, leftOffset, 0, 0)
					propNameLabel.Size = UDim2.new(1, -2 - (scaleType == 0 and 0 or 6), 1, 0)

					local gName = (prop.CategoryName and "CAT_" .. prop.CategoryName)
						or prop.Class .. "." .. prop.Name .. (prop.SubName or "")

					if prop.CategoryName then
						entry.BackgroundColor3 = Settings.Theme.Main1
						valueFrame.Visible = false

						propNameBox.Text = prop.CategoryName
						propNameBox.Font = Enum.Font.SourceSansBold
						expand.Visible = true
						propNameBox.TextColor3 = Settings.Theme.Text
						nameFrame.BackgroundTransparency = 1
						nameFrame.Size = UDim2.new(1, 0, 1, 0)
						editAttributeButton.Visible = false

						local showingAttrs = Settings.Properties.ShowAttributes
						toggleAttributes.Position = UDim2.new(1, -85 - leftOffset, 0, 0)
						toggleAttributes.Text = (showingAttrs and "[Setting: ON]" or "[Setting: OFF]")
						toggleAttributes.TextColor3 = Settings.Theme.Text
						toggleAttributes.Visible = (prop.CategoryName == "Attributes")
					else
						local propName = prop.Name
						local typeData = prop.ValueType
						local typeName = typeData.Name
						local tags = prop.Tags
						local propObj = autoUpdateObjs[gName]

						local attributeOffset = (prop.IsAttribute and 20 or 0)
						editAttributeButton.Visible = (prop.IsAttribute and not prop.RootType)
						toggleAttributes.Visible = false

						-- Moving around the frames
						if scaleType == 0 then
							nameFrame.Size = UDim2.new(0, Properties.ViewWidth - leftOffset - 1, 1, 0)
							valueFrame.Position = UDim2.new(0, Properties.ViewWidth, 0, 0)
							valueFrame.Size = UDim2.new(0, valueWidth - attributeOffset, 1, 0)
						else
							nameFrame.Size = UDim2.new(0.5, -leftOffset - 1, 1, 0)
							valueFrame.Position = UDim2.new(0.5, 0, 0, 0)
							valueFrame.Size = UDim2.new(0.5, -attributeOffset, 1, 0)
						end

						local nameArr = stringSplit(gName, ".")
						propNameBox.Text = prop.DisplayName or nameArr[#nameArr]
						propNameBox.Font = Enum.Font.SourceSans
						entry.BackgroundColor3 = Settings.Theme.Main2
						valueFrame.Visible = true

						expand.Visible = typeData.Category == "DataType" and Properties.ExpandableTypes[typeName]
							or Properties.ExpandableProps[gName]
						propNameBox.TextColor3 = tags.ReadOnly and Settings.Theme.PlaceholderText or Settings.Theme.Text

						-- Display property value
						Properties.DisplayProp(prop, i)
						if propObj then
							if prop.IsAttribute then
								propCons[#propCons + 1] = getAttributeChangedSignal(propObj, prop.AttributeName):Connect(
									function()
										Properties.DisplayProp(prop, i)
									end
								)
							else
								propCons[#propCons + 1] = getPropChangedSignal(propObj, propName):Connect(function()
									Properties.DisplayProp(prop, i)
								end)
							end
						end

						-- Tag display
						if prop.IsTag then
							valueBox.Text = prop.TagName

							local deleteButton = entryFrame.ValueFrame.RightButton
							deleteButton.Visible = true
							deleteButton.Icon.Image = "rbxassetid://5034718129"
							deleteButton.Icon.ImageRectSize = Vector2.new(16, 16)
						end

						-- "Add Tag" special row
						if prop.SpecialRow == "AddTag" then
							valueBox.Text = "+"
							valueBox.TextColor3 = Settings.Theme.Main1
						end

						-- Position and resize Input Box
						local beforeVisible = valueBox.Visible
						local inputFullName = inputProp
							and (inputProp.Class .. "." .. inputProp.Name .. (inputProp.SubName or ""))
						if gName == inputFullName then
							nameFrame.BackgroundColor3 = Settings.Theme.ListSelection
							nameFrame.BackgroundTransparency = 0
							if
								typeData.Category == "Class"
								or typeData.Category == "Enum"
								or typeName == "BrickColor"
							then
								valueFrame.BackgroundColor3 = Settings.Theme.TextBox
								valueFrame.BackgroundTransparency = 0
								valueBox.Visible = true
							else
								inputPropVisible = true
								local scale = (scaleType == 0 and 0 or 0.5)
								local offset = (scaleType == 0 and Properties.ViewWidth - scrollH.Index or 0)
								local endOffset = 0

								if typeName == "Color3" or typeName == "ColorSequence" then
									offset = offset + 22
								end

								if typeName == "NumberSequence" or typeName == "ColorSequence" then
									endOffset = 20
								end

								inputBox.Position = UDim2.new(scale, offset, 0, entry.Position.Y.Offset)
								inputBox.Size = UDim2.new(1 - scale, -offset - endOffset - attributeOffset, 0, 22)
								inputBox.Visible = true
								valueBox.Visible = false
							end
						else
							nameFrame.BackgroundColor3 = Settings.Theme.Main1
							nameFrame.BackgroundTransparency = 1
							valueFrame.BackgroundColor3 = Settings.Theme.Main1
							valueFrame.BackgroundTransparency = 1
							valueBox.Visible = beforeVisible
						end
					end

					-- Expand
					if
						prop.CategoryName
						or Properties.ExpandableTypes[prop.ValueType and prop.ValueType.Name]
						or Properties.ExpandableProps[gName]
					then
						if Lib.CheckMouseInGui(expand) then
							Main.MiscIcons:DisplayByKey(
								expand.Icon,
								expanded[gName] and "Collapse_Over" or "Expand_Over"
							)
						else
							Main.MiscIcons:DisplayByKey(expand.Icon, expanded[gName] and "Collapse" or "Expand")
						end
						expand.Visible = true
					else
						expand.Visible = false
					end
				end
				entry.Visible = true
			else
				entry.Visible = false
			end
		end

		if not inputPropVisible then
			inputBox.Visible = false
		end

		for i = maxEntries + 1, #propEntries do
			propEntries[i].Gui:Destroy()
			propEntries[i] = nil
			checkboxes[i] = nil
		end
	end

	Properties.SetProp = function(prop, val, noupdate, prevAttribute)
		local sList = Explorer.Selection.List
		local propName = prop.Name
		local subName = prop.SubName
		local propClass = prop.Class
		local typeData = prop.ValueType
		local typeName = typeData.Name
		local attributeName = prop.AttributeName
		local rootTypeData = prop.RootType
		local rootTypeName = rootTypeData and rootTypeData.Name
		local fullName = prop.Class .. "." .. prop.Name .. (prop.SubName or "")
		local Vector3 = Vector3

		for i = 1, #sList do
			local node = sList[i]
			local obj = node.Obj

			if isa(obj, propClass) then
				pcall(function()
					local setVal = val
					local root
					if prop.IsAttribute then
						root = getAttribute(obj, attributeName)
					else
						root = obj[propName]
					end

					if prevAttribute then
						if prevAttribute.ValueType.Name == typeName then
							setVal = getAttribute(obj, prevAttribute.AttributeName) or setVal
						end
						setAttribute(obj, prevAttribute.AttributeName, nil)

						-- ADONIS
						Dex_RemoteFunction:InvokeServer("SetPropertyAttribute", obj, attributeName, setVal)
					end

					if rootTypeName then
						if rootTypeName == "Vector2" then
							setVal = Vector2.new(
								(subName == ".X" and setVal) or root.X,
								(subName == ".Y" and setVal) or root.Y
							)
						elseif rootTypeName == "Vector3" then
							setVal = Vector3.new(
								(subName == ".X" and setVal) or root.X,
								(subName == ".Y" and setVal) or root.Y,
								(subName == ".Z" and setVal) or root.Z
							)
						elseif rootTypeName == "UDim" then
							setVal = UDim.new(
								(subName == ".Scale" and setVal) or root.Scale,
								(subName == ".Offset" and setVal) or root.Offset
							)
						elseif rootTypeName == "UDim2" then
							local rootX, rootY = root.X, root.Y
							local X_UDim = (subName == ".X" and setVal)
								or UDim.new(
									(subName == ".X.Scale" and setVal) or rootX.Scale,
									(subName == ".X.Offset" and setVal) or rootX.Offset
								)
							local Y_UDim = (subName == ".Y" and setVal)
								or UDim.new(
									(subName == ".Y.Scale" and setVal) or rootY.Scale,
									(subName == ".Y.Offset" and setVal) or rootY.Offset
								)
							setVal = UDim2.new(X_UDim, Y_UDim)
						elseif rootTypeName == "CFrame" then
							local rootPos, rootRight, rootUp, rootLook =
								root.Position, root.RightVector, root.UpVector, root.LookVector
							local pos = (subName == ".Position" and setVal)
								or Vector3.new(
									(subName == ".Position.X" and setVal) or rootPos.X,
									(subName == ".Position.Y" and setVal) or rootPos.Y,
									(subName == ".Position.Z" and setVal) or rootPos.Z
								)
							local rightV = (subName == ".RightVector" and setVal)
								or Vector3.new(
									(subName == ".RightVector.X" and setVal) or rootRight.X,
									(subName == ".RightVector.Y" and setVal) or rootRight.Y,
									(subName == ".RightVector.Z" and setVal) or rootRight.Z
								)
							local upV = (subName == ".UpVector" and setVal)
								or Vector3.new(
									(subName == ".UpVector.X" and setVal) or rootUp.X,
									(subName == ".UpVector.Y" and setVal) or rootUp.Y,
									(subName == ".UpVector.Z" and setVal) or rootUp.Z
								)
							local lookV = (subName == ".LookVector" and setVal)
								or Vector3.new(
									(subName == ".LookVector.X" and setVal) or rootLook.X,
									(subName == ".RightVector.Y" and setVal) or rootLook.Y,
									(subName == ".RightVector.Z" and setVal) or rootLook.Z
								)
							setVal = CFrame.fromMatrix(pos, rightV, upV, -lookV)
						elseif rootTypeName == "Rect" then
							local rootMin, rootMax = root.Min, root.Max
							local min = Vector2.new(
								(subName == ".Min.X" and setVal) or rootMin.X,
								(subName == ".Min.Y" and setVal) or rootMin.Y
							)
							local max = Vector2.new(
								(subName == ".Max.X" and setVal) or rootMax.X,
								(subName == ".Max.Y" and setVal) or rootMax.Y
							)
							setVal = Rect.new(min, max)
						elseif rootTypeName == "PhysicalProperties" then
							local rootProps = PhysicalProperties.new(obj.Material)
							local density = (subName == ".Density" and setVal)
								or (root and root.Density)
								or rootProps.Density
							local friction = (subName == ".Friction" and setVal)
								or (root and root.Friction)
								or rootProps.Friction
							local elasticity = (subName == ".Elasticity" and setVal)
								or (root and root.Elasticity)
								or rootProps.Elasticity
							local frictionWeight = (subName == ".FrictionWeight" and setVal)
								or (root and root.FrictionWeight)
								or rootProps.FrictionWeight
							local elasticityWeight = (subName == ".ElasticityWeight" and setVal)
								or (root and root.ElasticityWeight)
								or rootProps.ElasticityWeight
							setVal =
								PhysicalProperties.new(density, friction, elasticity, frictionWeight, elasticityWeight)
						elseif rootTypeName == "Ray" then
							local rootOrigin, rootDirection = root.Origin, root.Direction
							local origin = (subName == ".Origin" and setVal)
								or Vector3.new(
									(subName == ".Origin.X" and setVal) or rootOrigin.X,
									(subName == ".Origin.Y" and setVal) or rootOrigin.Y,
									(subName == ".Origin.Z" and setVal) or rootOrigin.Z
								)
							local direction = (subName == ".Direction" and setVal)
								or Vector3.new(
									(subName == ".Direction.X" and setVal) or rootDirection.X,
									(subName == ".Direction.Y" and setVal) or rootDirection.Y,
									(subName == ".Direction.Z" and setVal) or rootDirection.Z
								)
							setVal = Ray.new(origin, direction)
						elseif rootTypeName == "Faces" then
							local faces = {}
							local faceList = { "Back", "Bottom", "Front", "Left", "Right", "Top" }
							for _, face in pairs(faceList) do
								local val
								if subName == "." .. face then
									val = setVal
								else
									val = root[face]
								end
								if val then
									faces[#faces + 1] = Enum.NormalId[face]
								end
							end
							setVal = Faces.new(unpack(faces))
						elseif rootTypeName == "Axes" then
							local axes = {}
							local axesList = { "X", "Y", "Z" }
							for _, axe in pairs(axesList) do
								local val
								if subName == "." .. axe then
									val = setVal
								else
									val = root[axe]
								end
								if val then
									axes[#axes + 1] = Enum.Axis[axe]
								end
							end
							setVal = Axes.new(unpack(axes))
						elseif rootTypeName == "NumberRange" then
							setVal = NumberRange.new(
								subName == ".Min" and setVal or root.Min,
								subName == ".Max" and setVal or root.Max
							)
						end
					end

					if typeName == "PhysicalProperties" and setVal then
						setVal = root or PhysicalProperties.new(obj.Material)
					end

					if prop.IsAddTagButton or prop.IsTag or prop.IsSpecial then
						return -- NEVER write to this pseudo-property
					end

					if prop.IsAttribute then
						setAttribute(obj, attributeName, setVal)

						-- ADONIS
						Dex_RemoteFunction:InvokeServer("SetPropertyAttribute", obj, attributeName, setVal)
					else
						obj[propName] = setVal

						-- ADONIS
						Dex_RemoteFunction:InvokeServer("SetProperty", obj, propName, setVal)
					end
				end)
			end
		end

		if not noupdate then
			Properties.ComputeConflicts(prop)
		end
	end

	Properties.InitInputBox = function()
		inputBox = create({
			{
				1,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.14901961386204, 0.14901961386204, 0.14901961386204),
					BorderSizePixel = 0,
					Name = "InputBox",
					Size = UDim2.new(0, 200, 0, 22),
					Visible = false,
					ZIndex = 2,
				},
			},
			{
				2,
				"TextBox",
				{
					BackgroundColor3 = Color3.new(0.17647059261799, 0.17647059261799, 0.17647059261799),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.new(0.062745101749897, 0.51764708757401, 1),
					BorderSizePixel = 0,
					ClearTextOnFocus = false,
					Font = 3,
					Parent = { 1 },
					PlaceholderColor3 = Color3.new(0.69803923368454, 0.69803923368454, 0.69803923368454),
					Position = UDim2.new(0, 3, 0, 0),
					Size = UDim2.new(1, -6, 1, 0),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					TextXAlignment = 0,
					ZIndex = 2,
				},
			},
		})
		inputTextBox = inputBox.TextBox
		inputBox.BackgroundColor3 = Settings.Theme.TextBox
		inputBox.Parent = Properties.Window.GuiElems.Content.List

		inputTextBox.FocusLost:Connect(function()
			if not inputProp then
				return
			end

			local prop = inputProp
			inputProp = nil
			local val = Properties.StringToValue(prop, inputTextBox.Text)
			if val then
				Properties.SetProp(prop, val)
			else
				Properties.Refresh()
			end
		end)

		inputTextBox.Focused:Connect(function()
			inputTextBox.SelectionStart = 1
			inputTextBox.CursorPosition = #inputTextBox.Text + 1
		end)

		Lib.ViewportTextBox.convert(inputTextBox)
	end

	Properties.SetInputProp = function(prop, entryIndex, special)
		local typeData = prop.ValueType
		local typeName = typeData.Name
		local fullName = prop.Class .. "." .. prop.Name .. (prop.SubName or "")
		local propObj = autoUpdateObjs[fullName]
		local propVal = Properties.GetPropVal(prop, propObj)

		if prop.Tags.ReadOnly then
			return
		end

		inputProp = prop
		if special then
			if special == "color" then
				if typeName == "Color3" then
					inputTextBox.Text = propVal and Properties.ValueToString(prop, propVal) or ""
					Properties.DisplayColorEditor(prop, propVal)
				elseif typeName == "BrickColor" then
					Properties.DisplayBrickColorEditor(prop, entryIndex, propVal)
				elseif typeName == "ColorSequence" then
					inputTextBox.Text = propVal and Properties.ValueToString(prop, propVal) or ""
					Properties.DisplayColorSequenceEditor(prop, propVal)
				end
			elseif special == "right" then
				if typeName == "NumberSequence" then
					inputTextBox.Text = propVal and Properties.ValueToString(prop, propVal) or ""
					Properties.DisplayNumberSequenceEditor(prop, propVal)
				elseif typeName == "ColorSequence" then
					inputTextBox.Text = propVal and Properties.ValueToString(prop, propVal) or ""
					Properties.DisplayColorSequenceEditor(prop, propVal)
				end
			end
		else
			if Properties.IsTextEditable(prop) then
				-- TODO: A setting maybe.
				--inputTextBox.Text = propVal and Properties.ValueToString(prop,propVal) or ""
				local rawStr = propVal and Properties.ValueToString(prop, propVal) or ""
				inputTextBox.Text = rawStr:gsub("-?%d+%.%d+", function(num)
					return tostring(tonumber(("%." .. Settings.Properties.NumberRounding .. "f"):format(num)))
				end)
				inputTextBox:CaptureFocus()
			elseif typeData.Category == "Enum" then
				Properties.DisplayEnumDropdown(entryIndex)
			elseif typeName == "BrickColor" then
				Properties.DisplayBrickColorEditor(prop, entryIndex, propVal)
			end
		end
		Properties.Refresh()
	end

	Properties.InitSearch = function()
		local searchBox = Properties.GuiElems.ToolBar.SearchFrame.SearchBox

		Lib.ViewportTextBox.convert(searchBox)

		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			Properties.SearchText = searchBox.Text
			Properties.Update()
			Properties.Refresh()
		end)
	end

	Properties.InitEntryStuff = function()
		Properties.EntryTemplate = create({
			{
				1,
				"TextButton",
				{
					AutoButtonColor = false,
					BackgroundColor3 = Color3.new(0.17647059261799, 0.17647059261799, 0.17647059261799),
					BackgroundTransparency = 0.2,
					BorderColor3 = Color3.new(0.1294117718935, 0.1294117718935, 0.1294117718935),
					Font = 3,
					Name = "Entry",
					Position = UDim2.new(0, 1, 0, 1),
					Size = UDim2.new(0, 250, 0, 22),
					Text = "",
					TextSize = 14,
				},
			},
			{
				2,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.04313725605607, 0.35294118523598, 0.68627452850342),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.new(0.33725491166115, 0.49019610881805, 0.73725491762161),
					BorderSizePixel = 0,
					Name = "NameFrame",
					Parent = { 1 },
					Position = UDim2.new(0, 20, 0, 0),
					Size = UDim2.new(1, -40, 1, 0),
				},
			},
			{
				3,
				"TextLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Font = 3,
					Name = "PropName",
					Parent = { 2 },
					Position = UDim2.new(0, 2, 0, 0),
					Size = UDim2.new(1, -2, 1, 0),
					Text = "Anchored",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					TextTransparency = 0.10000000149012,
					TextTruncate = 1,
					TextXAlignment = 0,
				},
			},
			{
				4,
				"TextButton",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Font = 3,
					Name = "Expand",
					Parent = { 2 },
					Position = UDim2.new(0, -20, 0, 1),
					Size = UDim2.new(0, 20, 0, 20),
					Text = "",
					TextSize = 14,
					Visible = false,
				},
			},
			{
				5,
				"ImageLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Image = "rbxassetid://5642383285",
					ImageRectOffset = Vector2.new(144, 16),
					ImageRectSize = Vector2.new(16, 16),
					Name = "Icon",
					Parent = { 4 },
					Position = UDim2.new(0, 2, 0, 2),
					ScaleType = 4,
					Size = UDim2.new(0, 16, 0, 16),
				},
			},
			{
				6,
				"TextButton",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Font = 4,
					Name = "ToggleAttributes",
					Parent = { 2 },
					Position = UDim2.new(1, -85, 0, 0),
					Size = UDim2.new(0, 85, 0, 22),
					Text = "[SETTING: OFF]",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					TextTransparency = 0.10000000149012,
					Visible = false,
				},
			},
			{
				7,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.04313725605607, 0.35294118523598, 0.68627452850342),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.new(0.33725491166115, 0.49019607901573, 0.73725491762161),
					BorderSizePixel = 0,
					Name = "ValueFrame",
					Parent = { 1 },
					Position = UDim2.new(1, -100, 0, 0),
					Size = UDim2.new(0, 80, 1, 0),
				},
			},
			{
				8,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.14117647707462, 0.14117647707462, 0.14117647707462),
					BorderColor3 = Color3.new(0.33725491166115, 0.49019610881805, 0.73725491762161),
					BorderSizePixel = 0,
					Name = "Line",
					Parent = { 7 },
					Position = UDim2.new(0, -1, 0, 0),
					Size = UDim2.new(0, 1, 1, 0),
				},
			},
			{
				9,
				"TextButton",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Font = 3,
					Name = "ColorButton",
					Parent = { 7 },
					Size = UDim2.new(0, 20, 0, 22),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					Visible = false,
				},
			},
			{
				10,
				"Frame",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BorderColor3 = Color3.new(0, 0, 0),
					Name = "ColorPreview",
					Parent = { 9 },
					Position = UDim2.new(0, 5, 0, 6),
					Size = UDim2.new(0, 10, 0, 10),
				},
			},
			{ 11, "UIGradient", { Parent = { 10 } } },
			{
				12,
				"Frame",
				{
					BackgroundTransparency = 1,
					Name = "EnumArrow",
					Parent = { 7 },
					Position = UDim2.new(1, -16, 0, 3),
					Size = UDim2.new(0, 16, 0, 16),
					Visible = false,
				},
			},
			{
				13,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.86274510622025, 0.86274510622025, 0.86274510622025),
					BorderSizePixel = 0,
					Parent = { 12 },
					Position = UDim2.new(0, 8, 0, 9),
					Size = UDim2.new(0, 1, 0, 1),
				},
			},
			{
				14,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.86274510622025, 0.86274510622025, 0.86274510622025),
					BorderSizePixel = 0,
					Parent = { 12 },
					Position = UDim2.new(0, 7, 0, 8),
					Size = UDim2.new(0, 3, 0, 1),
				},
			},
			{
				15,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.86274510622025, 0.86274510622025, 0.86274510622025),
					BorderSizePixel = 0,
					Parent = { 12 },
					Position = UDim2.new(0, 6, 0, 7),
					Size = UDim2.new(0, 5, 0, 1),
				},
			},
			{
				16,
				"TextButton",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Font = 3,
					Name = "ValueBox",
					Parent = { 7 },
					Position = UDim2.new(0, 4, 0, 0),
					Size = UDim2.new(1, -8, 1, 0),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					TextTransparency = 0.10000000149012,
					TextTruncate = 1,
					TextXAlignment = 0,
				},
			},
			{
				17,
				"TextButton",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Font = 3,
					Name = "RightButton",
					Parent = { 7 },
					Position = UDim2.new(1, -20, 0, 0),
					Size = UDim2.new(0, 20, 0, 22),
					Text = "...",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					Visible = false,
				},
			},
			{
				18,
				"TextButton",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Font = 3,
					Name = "SettingsButton",
					Parent = { 7 },
					Position = UDim2.new(1, -20, 0, 0),
					Size = UDim2.new(0, 20, 0, 22),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					Visible = false,
				},
			},
			{
				19,
				"Frame",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Name = "SoundPreview",
					Parent = { 7 },
					Size = UDim2.new(1, 0, 1, 0),
					Visible = false,
				},
			},
			{
				20,
				"TextButton",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Font = 3,
					Name = "ControlButton",
					Parent = { 19 },
					Size = UDim2.new(0, 20, 0, 22),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
				},
			},
			{
				21,
				"ImageLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Image = "rbxassetid://5642383285",
					ImageRectOffset = Vector2.new(144, 16),
					ImageRectSize = Vector2.new(16, 16),
					Name = "Icon",
					Parent = { 20 },
					Position = UDim2.new(0, 2, 0, 3),
					ScaleType = 4,
					Size = UDim2.new(0, 16, 0, 16),
				},
			},
			{
				22,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.3137255012989, 0.3137255012989, 0.3137255012989),
					BorderSizePixel = 0,
					Name = "TimeLine",
					Parent = { 19 },
					Position = UDim2.new(0, 26, 0.5, -1),
					Size = UDim2.new(1, -34, 0, 2),
				},
			},
			{
				23,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.2352941185236, 0.2352941185236, 0.2352941185236),
					BorderColor3 = Color3.new(0.1294117718935, 0.1294117718935, 0.1294117718935),
					Name = "Slider",
					Parent = { 22 },
					Position = UDim2.new(0, -4, 0, -8),
					Size = UDim2.new(0, 8, 0, 18),
				},
			},
			{
				24,
				"TextButton",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Font = 3,
					Name = "EditAttributeButton",
					Parent = { 1 },
					Position = UDim2.new(1, -20, 0, 0),
					Size = UDim2.new(0, 20, 0, 22),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
				},
			},
			{
				25,
				"ImageLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Image = "rbxassetid://5034718180",
					ImageTransparency = 0.20000000298023,
					Name = "Icon",
					Parent = { 24 },
					Position = UDim2.new(0, 2, 0, 3),
					Size = UDim2.new(0, 16, 0, 16),
				},
			},
			{
				26,
				"TextButton",
				{
					AutoButtonColor = false,
					BackgroundColor3 = Color3.new(0.2352941185236, 0.2352941185236, 0.2352941185236),
					BorderSizePixel = 0,
					Font = 3,
					Name = "RowButton",
					Parent = { 1 },
					Size = UDim2.new(1, 0, 1, 0),
					Text = "Add Attribute",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					TextTransparency = 0.10000000149012,
					Visible = false,
				},
			},
		})

		local fullNameFrame = Lib.Frame.new()
		local label = Lib.Label.new()
		label.Parent = fullNameFrame.Gui
		label.Position = UDim2.new(0, 2, 0, 0)
		label.Size = UDim2.new(1, -4, 1, 0)
		fullNameFrame.Visible = false
		fullNameFrame.Parent = window.Gui

		Properties.FullNameFrame = fullNameFrame
		Properties.FullNameFrameAttach = Lib.AttachTo(fullNameFrame)
	end

	Properties.Init = function() -- TODO: MAKE BETTER
		local guiItems = create({
			{ 1, "Folder", { Name = "Items" } },
			{
				2,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.20392157137394, 0.20392157137394, 0.20392157137394),
					BorderSizePixel = 0,
					Name = "ToolBar",
					Parent = { 1 },
					Size = UDim2.new(1, 0, 0, 22),
				},
			},
			{
				3,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.14901961386204, 0.14901961386204, 0.14901961386204),
					BorderColor3 = Color3.new(0.1176470592618, 0.1176470592618, 0.1176470592618),
					BorderSizePixel = 0,
					Name = "SearchFrame",
					Parent = { 2 },
					Position = UDim2.new(0, 3, 0, 1),
					Size = UDim2.new(1, -6, 0, 18),
				},
			},
			{
				4,
				"TextBox",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					ClearTextOnFocus = false,
					Font = 3,
					Name = "SearchBox",
					Parent = { 3 },
					PlaceholderColor3 = Color3.new(0.39215689897537, 0.39215689897537, 0.39215689897537),
					PlaceholderText = "Search properties",
					Position = UDim2.new(0, 4, 0, 0),
					Size = UDim2.new(1, -24, 0, 18),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					TextXAlignment = 0,
				},
			},
			{ 5, "UICorner", { CornerRadius = UDim.new(0, 2), Parent = { 3 } } },
			{
				6,
				"TextButton",
				{
					AutoButtonColor = false,
					BackgroundColor3 = Color3.new(0.12549020349979, 0.12549020349979, 0.12549020349979),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Font = 3,
					Name = "Reset",
					Parent = { 3 },
					Position = UDim2.new(1, -17, 0, 1),
					Size = UDim2.new(0, 16, 0, 16),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
				},
			},
			{
				7,
				"ImageLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Image = "rbxassetid://5034718129",
					ImageColor3 = Color3.new(0.39215686917305, 0.39215686917305, 0.39215686917305),
					Parent = { 6 },
					Size = UDim2.new(0, 16, 0, 16),
				},
			},
			{
				8,
				"TextButton",
				{
					AutoButtonColor = false,
					BackgroundColor3 = Color3.new(0.12549020349979, 0.12549020349979, 0.12549020349979),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Font = 3,
					Name = "Refresh",
					Parent = { 2 },
					Position = UDim2.new(1, -20, 0, 1),
					Size = UDim2.new(0, 18, 0, 18),
					Text = "",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					Visible = false,
				},
			},
			{
				9,
				"ImageLabel",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Image = "rbxassetid://5642310344",
					Parent = { 8 },
					Position = UDim2.new(0, 3, 0, 3),
					Size = UDim2.new(0, 12, 0, 12),
				},
			},
			{
				10,
				"Frame",
				{
					BackgroundColor3 = Color3.new(0.15686275064945, 0.15686275064945, 0.15686275064945),
					BorderSizePixel = 0,
					Name = "ScrollCorner",
					Parent = { 1 },
					Position = UDim2.new(1, -16, 1, -16),
					Size = UDim2.new(0, 16, 0, 16),
					Visible = false,
				},
			},
			{
				11,
				"Frame",
				{
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Name = "List",
					Parent = { 1 },
					Position = UDim2.new(0, 0, 0, 23),
					Size = UDim2.new(1, 0, 1, -23),
				},
			},
		})

		-- Vars
		categoryOrder = API.CategoryOrder
		for category, _ in next, categoryOrder do
			if not Properties.CollapsedCategories[category] then
				expanded["CAT_" .. category] = true
			end
		end
		expanded["Sound.SoundId"] = true
		expanded["AudioPlayer.Asset"] = true

		-- Init window
		window = Lib.Window.new()
		Properties.Window = window
		window:SetTitle("Properties")

		toolBar = guiItems.ToolBar
		propsFrame = guiItems.List

		Properties.GuiElems.ToolBar = toolBar
		Properties.GuiElems.PropsFrame = propsFrame

		Properties.InitEntryStuff()

		-- Window events
		window.GuiElems.Main:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if Properties.Window:IsContentVisible() then
				Properties.UpdateView()
				Properties.Refresh()
			end
		end)
		window.OnActivate:Connect(function()
			Properties.UpdateView()
			Properties.Update()
			Properties.Refresh()
		end)
		window.OnRestore:Connect(function()
			Properties.UpdateView()
			Properties.Update()
			Properties.Refresh()
		end)

		-- Init scrollbars
		scrollV = Lib.ScrollBar.new()
		scrollV.WheelIncrement = 3
		scrollV.Gui.Position = UDim2.new(1, -16, 0, 23)
		scrollV:SetScrollFrame(propsFrame)
		scrollV.Scrolled:Connect(function()
			Properties.Index = scrollV.Index
			Properties.Refresh()
		end)

		scrollH = Lib.ScrollBar.new(true)
		scrollH.Increment = 5
		scrollH.WheelIncrement = 20
		scrollH.Gui.Position = UDim2.new(0, 0, 1, -16)
		scrollH.Scrolled:Connect(function()
			Properties.Refresh()
		end)

		-- Setup Gui
		window.GuiElems.Line.Position = UDim2.new(0, 0, 0, 22)
		toolBar.Parent = window.GuiElems.Content
		propsFrame.Parent = window.GuiElems.Content
		guiItems.ScrollCorner.Parent = window.GuiElems.Content
		scrollV.Gui.Parent = window.GuiElems.Content
		scrollH.Gui.Parent = window.GuiElems.Content
		Properties.InitInputBox()
		Properties.InitSearch()
	end

	return Properties
end

return { InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main }
