local Humanoid = script.Parent.Humanoid

for _,v in pairs(script.Parent:GetDescendants()) do
	if v:IsA("BasePart") and (v.Name == "HumanoidRootPart" or v.Name == "UpperTorso" or v.Name == "LowerTorso" or v.Name == "Torso" or (v.Name == "Head" and script.Parent:FindFirstChild("Torso"))) then
		v.CanCollide = true
	end
end

Humanoid:ChangeState(18)		--| Enum.HumanoidStateType.None (Used so we can remove the Enum.HumanoidStateType.StrafingNoPhysics)
task.wait()
script:Destroy()
