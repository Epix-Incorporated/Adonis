local msgs={
{
Msg='We need more..... philosophy... ya know?',
Color=Enum.ChatColor.Green
},{
Msg='OH MY GOD STOP TRYING TO EAT MY SOUL',
Color=Enum.ChatColor.Red
},{
Msg='I.... CANT.... FEEL.... MY FACE',
Color=Enum.ChatColor.Red
},{
Msg='DO YOU SEE THE TURTLE?!?!',
Color=Enum.ChatColor.Red
},{
Msg='Omg puff the magic dragon!!!!',
Color=Enum.ChatColor.Green
},{
Msg='Omg double wat',
Color=Enum.ChatColor.Blue
},{
Msg='WHO STOLE MY LEGS',
Color=Enum.ChatColor.Red
},{
Msg='I... I think I might be dead....',
Color=Enum.ChatColor.Blue
},{
Msg="I'M GOING TO EAT YOUR FACE",
Color=Enum.ChatColor.Red
},{
Msg='Hey... Like... What if, like, listen, are you listening? What if.. like.. earth.. was a ball?',
Color=Enum.ChatColor.Green
},{
Msg='WHY IS EVERYBODY TALKING SO LOUD AHHHHHH',
Color=Enum.ChatColor.Red
},{
Msg='Woooo man do you see the elephent... theres an elephent man..its... PURPLE OHMY GOD ITS A SIGN FROM LIKE THE WARDROBE..',
Color=Enum.ChatColor.Blue
}}

local Chat = game:GetService("Chat")
local head = script.Parent.Parent.Head
local humanoid = script.Parent.Parent:FindFirstChildOfClass("Humanoid")
local torso = script.Parent
local val = Instance.new('StringValue')
val.Parent = head
local old = math.random()
local stop = false

humanoid.Died:Connect(function()
	stop = true
	task.wait(0.5)
	workspace.CurrentCamera.FieldOfView = 70
end)

task.spawn(function()
	while not stop and head and val and val.Parent==head do
		local new=math.random(1,#msgs)
		for k,m in pairs(msgs) do
			if new==k then
				if old ~= new then
					old=new
					print(m.Msg)
					Chat:Chat(head,m.Msg,m.Color)
				end
			end
		end
		task.wait(5)
	end
end)

humanoid.WalkSpeed=-16

local startspaz = false

task.spawn(function()
	repeat
		task.wait(0.1)
		workspace.CurrentCamera.FieldOfView = math.random(20, 80)
		humanoid.Health:TakeDamage(0.5)

		if startspaz then
			humanoid.PlatformStand = true
			torso.AssemblyLinearVelocity = Vector3.new(math.random(-10, 10), -5, math.random(-10, 10))
			torso.AssemblyAngularVelocity = Vector3.new(math.random(-5, 5), math.random(-5, 5), math.random(-5, 5))
		end
	until stop or not humanoid or not humanoid.Parent or humanoid.Health<=0 or not torso
end)

task.wait(10)

local bg = Instance.new("BodyGyro")
bg.Name = "SPINNER"
bg.maxTorque = Vector3.new(0,math.huge,0)
bg.P = 11111
bg.cframe = torso.CFrame
bg.Parent = torso

task.spawn(function()
	repeat task.wait(1/44)
		bg.cframe = bg.cframe * CFrame.Angles(0,math.rad(30),0)
	until stop or not bg or bg.Parent ~= torso
end)

task.wait(20)
startspaz = true
