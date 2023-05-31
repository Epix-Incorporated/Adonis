local Components = script.Parent
local Packages = Components.Parent.Packages

local Maid = require(Packages.Maid)
local Flipper = require(Packages.Flipper)
local Roact = require(Packages.Roact)
local new = Roact.createElement

-- ////////// AnimationWrapper for Message component

local AnimationWrapper = Roact.PureComponent:extend(script.Name)

function AnimationWrapper:init()
	local props = self.props

	self.Maid = Maid.new()
	self.CurrentAnimationState = 'Rest'

	self.TransparencyMotor = Flipper.SingleMotor.new(1)
	self.Transparency, self.SetTransparency = Roact.createBinding(1)

	self.Maid.TransparencyMotor = function()
		self.TransparencyMotor:destroy()
	end

	-- ////////// Animation

	self.TransparencyMotor:onStep(function(Value)
		self.SetTransparency(Value)
	end)

	self.TransparencyMotor:onComplete(function()
		if self.CurrentAnimationState == 'FadeOut' then
			props.OnFadeOutCompleted()
		end

		self.CurrentAnimationState = 'Rest'
	end)

	self.Maid.FadeIn = props.FadeInSignal:Connect(function()
		self.CurrentAnimationState = 'FadeIn'
		self.TransparencyMotor:setGoal(Flipper.Linear.new(0, {
			velocity = props.FadeInVelocity,
		}))
	end)

	self.Maid.FadeOut = props.FadeOutSignal:Connect(function()
		self.CurrentAnimationState = 'FadeOut'
		self.TransparencyMotor:setGoal(Flipper.Linear.new(1, {
			velocity = props.FadeOutVelocity,
		}))
	end)
end

function AnimationWrapper:willUnmount()
	self.Maid:Destroy()
end

function AnimationWrapper:render()
	local props = self.props

	return new('CanvasGroup', {
		GroupTransparency = self.Transparency,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
	}, props[Roact.Children])
end

return AnimationWrapper