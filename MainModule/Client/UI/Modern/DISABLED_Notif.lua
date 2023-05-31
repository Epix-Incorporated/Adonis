---@diagnostic disable: undefined-global

local Components = script.Parent.Components.AdonisModernComponents
local Packages = Components.Parent.Packages

local Maid = require(Packages.Maid)
local Signal = require(Packages.Signal)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local FadeInOutAnimationWrapper = require(Components.FadeInOutAnimationWrapper)
local Hint = require(Components.Hint)

local CurrentAppMaid = nil

return function(Data)

	-- Remove existing
	if CurrentAppMaid then
		CurrentAppMaid:Destroy()
		CurrentAppMaid = nil
	end

	-- ### REASON WHY THIS SCRIPT DISABLED: ####### Adonis does not call with an empty message arg, we cannot know when to clean up
	-- -- Ensure there is a message
	-- if typeof(Data.Message) ~= 'string' then
	-- 	return
	-- end

	-- ### REASON WHY THIS SCRIPT DISABLED: ####### "gTable" is not provided for some reason
	-- -- Cleanup
	-- Data.gTable.CustomDestroy = function()
	-- 	if CurrentAppMaid then
	-- 		CurrentAppMaid:Destroy()
	-- 	end
	-- end

	local AppMaid = Maid.new()
	local FadeInSignal = Signal.new()
	local FadeOutSignal = Signal.new()

	CurrentAppMaid = AppMaid

	AppMaid.FadeInSignal = FadeInSignal
	AppMaid.FadeOutSignal = FadeOutSignal

	-- ////////// Create Message App
	local App = new("ScreenGui", {
		DisplayOrder = Data.DisplayOrder or 100,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {

		AnimationContainer = new(FadeInOutAnimationWrapper, {
			FadeInSignal = FadeInSignal,
			FadeOutSignal = FadeOutSignal,
			FadeInVelocity = 3,
			FadeOutVelocity = 4,
			OnFadeOutCompleted = function()
				AppMaid:Destroy()
			end,
		}, {

			Hint = new(Hint, {
				BodyText = Data.Message,
				Image = Data.Image,
				TitleText = Data.Title,
				BackgroundColor3 = Color3.new(),
			}),
		}),
	})

	-- ////////// Perform Animation Tasks

	local Handle = Roact.mount(App, service.UnWrap(service.PlayerGui), "AdonisUI.Notif")

	AppMaid.RemoveHandle = function()
		Handle = Roact.unmount(Handle)
	end

	FadeInSignal:Fire()

	if Data.Time then
		task.wait(Data.Time)
		FadeOutSignal:Fire()
	end

end
