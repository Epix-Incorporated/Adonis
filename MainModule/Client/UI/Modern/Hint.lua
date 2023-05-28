---@diagnostic disable: undefined-global

local Components = script.Parent.Components.AdonisModernComponents
local Packages = Components.Parent.Packages

local Maid = require(Packages.Maid)
local Signal = require(Packages.Signal)
local Roact = require(Packages.Roact)
local new = Roact.createElement

local FadeInOutAnimationWrapper = require(Components.FadeInOutAnimationWrapper)
local Hint = require(Components.Hint)

return function(Data)
	local AppMaid = Maid.new()
	local FadeInSignal = Signal.new()
	local FadeOutSignal = Signal.new()

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
			}),
		}),
	})

	-- ////////// Perform Animation Tasks

	local Handle = Roact.mount(App, service.UnWrap(service.PlayerGui), "AdonisUI.Hint")

	AppMaid.RemoveHandle = function()
		Handle = Roact.unmount(Handle)
	end

	FadeInSignal:Fire()

	if Data.Time then
		task.wait(Data.Time)
	else
		-- Estimated read time
		task.wait((("%s%s"):format(Data.Message or "", Data.Title or ""):len() / 19) + 2.5)
	end

	FadeOutSignal:Fire()
end
