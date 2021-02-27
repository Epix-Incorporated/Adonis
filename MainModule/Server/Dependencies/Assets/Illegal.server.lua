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

local head = script.Parent.Parent.Head
local hum = script.Parent.Parent.Humanoid
local torso = script.Parent
local chat = game:GetService("Chat")
local val = service.New('StringValue',head)
local old = math.random()
local stop = false

hum.Died:connect(function()
stop = true
wait(0.5)
workspace.CurrentCamera.FieldOfView = 70
end)

coroutine.wrap(function()
while not stop and head and val and val.Parent==head do
local new=math.random(1,#msgs)
for k,m in pairs(msgs) do
if new==k then
if old~=new then
old=new
print(m.Msg)
chat:Chat(head,m.Msg,m.Color)
end
end
end
wait(5)
end
end)()

hum.WalkSpeed=-16

local startspaz = false

coroutine.wrap(function()
repeat
wait(0.1)
workspace.CurrentCamera.FieldOfView = math.random(20,80)
hum.Health = hum.Health-0.5
if startspaz then
hum.PlatformStand = true
torso.Velocity = Vector3.new(math.random(-10,10),-5,math.random(-10,10))
torso.RotVelocity = Vector3.new(math.random(-5,5),math.random(-5,5),math.random(-5,5))
end
until stop or not hum or not hum.Parent or hum.Health<=0 or not torso
end)()

wait(10)

local bg = service.New("BodyGyro", torso)
bg.Name = "SPINNER"
bg.maxTorque = Vector3.new(0,math.huge,0)
bg.P = 11111
bg.cframe = torso.CFrame

coroutine.wrap(function()
repeat wait(1/44)
bg.cframe = bg.cframe * CFrame.Angles(0,math.rad(30),0)
until stop or not bg or bg.Parent ~= torso
end)()

wait(20)
startspaz = true