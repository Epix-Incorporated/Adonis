--[[
	Author: github@ccuser44/ALE111_boiPNG
	Name: Sing script
	Description: This script creates a singing animation
	License: MIT
]]
--[[
	MIT License

	Copyright (c) 2023 ccuser44

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
]]

task.wait()
local head = script.Parent.Parent
local character = head.Parent
local humanoid = character:FindFirstChildOfClass("Humanoid")
local torso = character:FindFirstChild("Torso")
local neck = torso and torso:FindFirstChild("Neck") or head:FindFirstChild("Neck")
local mouth = character.ADONIS_MOUTH
local mouthMesh = mouth:FindFirstChildOfClass("SpecialMesh")
local originalSize = mouthMesh.Scale
local orgC0 = neck.C0
local isR15 = humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 or false

local SIZE_SMOOTHNESS = 0.8
local ANGLE_SMOOTHNESS = 0.1
local WIDTH_SUPRESS = 20000
local HEIGHT_SUPRESS = 1000
local ANGLE_MULTIPLY = 100

game:GetService("RunService").Heartbeat:connect(function()
	local relativeSize = head.Size / (isR15 and Vector3.new(1.2, 1.2, 1.2) or Vector3.new(2, 1, 1))
	local loudness = script.Parent.PlaybackLoudness
	mouthMesh.Scale = mouthMesh.Scale:Lerp(Vector3.new(originalSize.X + loudness/WIDTH_SUPRESS * relativeSize.X, loudness/HEIGHT_SUPRESS * relativeSize.Y, originalSize.Z), SIZE_SMOOTHNESS)
	neck.C0 = neck.C0:Lerp(orgC0 * CFrame.Angles(math.rad(mouthMesh.Scale.Y / relativeSize.Y * ANGLE_MULTIPLY) * (isR15 and 1 or -1), 0, 0), ANGLE_SMOOTHNESS)
end)
