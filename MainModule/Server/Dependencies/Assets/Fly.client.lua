local players = game:GetService("Players")
local inputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local contextService = game:GetService("ContextActionService")

local part = script.Parent

if not part then
	script:Destroy()
end

local player = players.LocalPlayer
local char = player.Character

local human = char:FindFirstChildOfClass("Humanoid")
local bPos = part:WaitForChild("ADONIS_FLIGHT_POSITION")
local bGyro = part:WaitForChild("ADONIS_FLIGHT_GYRO")

local speedVal = script:WaitForChild("Speed")
local noclip = script:WaitForChild("Noclip")
local Create = Instance.new
local flying = true

local keyTab = {}
local dir = {}

local antiLoop, humChanged, conn
local Check, getCF, dirToCom, Start, Stop, Toggle, HandleInput, listenConnection

local RBXConnections = {}
function listenConnection(Connection, callback)
	local RBXConnection = Connection:Connect(callback)
	table.insert(RBXConnections, RBXConnection)
	return RBXConnection
end

function Check()
	if script.Parent == part then
		return true
	end
end

function getCF(part, isFor)
	local cframe = part.CFrame
	local noRot = CFrame.new(cframe.p)
	local x, y, z = (workspace.CurrentCamera.CoordinateFrame - workspace.CurrentCamera.CoordinateFrame.p):toEulerAnglesXYZ()
	return noRot * CFrame.Angles(isFor and z or x, y, z)
end

function dirToCom(part, mdir)
	local dirs = {
		Forward = ((getCF(part, true)*CFrame.new(0, 0, -1)) - part.CFrame.p).p;
		Backward = ((getCF(part, true)*CFrame.new(0, 0, 1)) - part.CFrame.p).p;
		Right = ((getCF(part)*CFrame.new(1, 0, 0)) - part.CFrame.p).p;
		Left = ((getCF(part)*CFrame.new(-1, 0, 0)) - part.CFrame.p).p;
	}

	for i,v in next,dirs do
		if (v - mdir).Magnitude <= 1.05 and mdir ~= Vector3.new(0,0,0) then
			dir[i] = true
		elseif not keyTab[i] then
			dir[i] = false
		end
	end
end

function Start()
	local curSpeed = 0
	local topSpeed = speedVal.Value
	local speedInc = topSpeed/25
	local camera = workspace.CurrentCamera
	local antiReLoop = {}
	local realPos = part.CFrame

	listenConnection(speedVal.Changed, function()
		topSpeed = speedVal.Value
		speedInc = topSpeed/25
	end)

	bPos.Position = part.Position
	bPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

	bGyro.CFrame = part.CFrame
	bGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)

	antiLoop = antiReLoop

	if noclip.Value then
		conn = runService.Stepped:Connect(function()
			for _,v in pairs(char:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CanCollide = false
				end
			end
		end)
	end

	while flying and antiLoop == antiReLoop do
		if not Check() then
			break
		end

		local new = bGyro.cframe - bGyro.cframe.p + bPos.position
		if not dir.Forward and not dir.Backward and not dir.Up and not dir.Down and not dir.Left and not dir.Right then
			curSpeed = 1
		else
			if dir.Up then
				new = new * CFrame.new(0, curSpeed, 0)
				curSpeed = curSpeed + speedInc
			end

			if dir.Down then
				new = new * CFrame.new(0, -curSpeed, 0)
				curSpeed = curSpeed + speedInc
			end

			if dir.Forward then
				new = new + camera.CoordinateFrame.LookVector * curSpeed
				curSpeed = curSpeed + speedInc
			end

			if dir.Backward then
				new = new - camera.CoordinateFrame.LookVector * curSpeed
				curSpeed = curSpeed + speedInc
			end

			if dir.Left then
				new = new * CFrame.new(-curSpeed, 0, 0)
				curSpeed = curSpeed + speedInc
			end

			if dir.Right then
				new = new * CFrame.new(curSpeed, 0, 0)
				curSpeed = curSpeed + speedInc
			end

			if curSpeed > topSpeed then
				curSpeed = topSpeed
			end
		end

		human.PlatformStand = true
		bPos.position = new.p

		if dir.Forward then
			bGyro.cframe = camera.CoordinateFrame*CFrame.Angles(-math.rad(curSpeed*7.5), 0, 0)
		elseif dir.Backward then
			bGyro.cframe = camera.CoordinateFrame*CFrame.Angles(math.rad(curSpeed*7.5), 0, 0)
		else
			bGyro.cframe = camera.CoordinateFrame
		end

		runService.RenderStepped:Wait()
	end

	Stop()
end

function Stop()
	flying = false
	human.PlatformStand = false

	if humChanged then
		humChanged:Disconnect()
	end

	if bPos then
		bPos.maxForce = Vector3.new(0, 0, 0)
	end

	if bGyro then
		bGyro.maxTorque = Vector3.new(0, 0, 0)
	end

	if conn then
		conn:Disconnect()
	end
end

local debounce = false
function Toggle()
	if not debounce then
		debounce = true
		if not flying then
			flying = true
			coroutine.wrap(Start)()
		else
			flying = false
			Stop()
		end
		wait(0.5)
		debounce = false
	end
end

function HandleInput(input, isGame, bool)
	if not isGame then
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.W then
				keyTab.Forward = bool
				dir.Forward = bool
			elseif input.KeyCode == Enum.KeyCode.A then
				keyTab.Left = bool
				dir.Left = bool
			elseif input.KeyCode == Enum.KeyCode.S then
				keyTab.Backward = bool
				dir.Backward = bool
			elseif input.KeyCode == Enum.KeyCode.D then
				keyTab.Right = bool
				dir.Right = bool
			elseif input.KeyCode == Enum.KeyCode.Q then
				keyTab.Down = bool
				dir.Down = bool
			elseif input.KeyCode == Enum.KeyCode.Space then
				keyTab.Up = bool
				dir.Up = bool
			elseif input.KeyCode == Enum.KeyCode.E and bool == true then
				Toggle()
			end
		end
	end
end

listenConnection(part.DescendantRemoving, function(Inst)
	if Inst == bPos or Inst == bGyro or Inst == speedVal or Inst == noclip then
		if conn then
				conn:Disconnect()
		end

		for _, Signal in pairs(RBXConnections) do
			Signal:Disconnect()
		end

		Stop()
	end
end)

listenConnection(inputService.InputBegan, function(input, isGame)
	HandleInput(input, isGame, true)
end)

listenConnection(inputService.InputEnded, function(input, isGame)
	HandleInput(input, isGame, false)
end)

coroutine.wrap(Start)()

if not inputService.KeyboardEnabled then
	listenConnection(human.Changed, function()
		dirToCom(part, human.MoveDirection)
	end)

	contextService:BindAction("Toggle Flight", Toggle, true)

	while true do
		if not Check() then
			break
		end

		runService.Stepped:Wait()
	end

	contextService:UnbindAction("Toggle Flight")
end

--[[
if a=='KFly' then
	a=Curr.Fly
	if a then
		a.Value=nil
		a.Parent.BodyVelocity:Destroy()
		a.Parent.BodyGyro:Destroy()
		a:Destroy()
		Curr.Fly=nil
	end

	if b then
		local hum,root=FindChild(char,'Humanoid'),FindChild(char,'HumanoidRootPart')
		if not (hum and root) then
			return
		end
		local maxspd,m,acc,dir,CF=100,5,v3()
		local bg,bv=new'BodyGyro'{Parent=root;D=200;P=5000;cframe=root.CFrame},new'BodyVelocity'{Parent=root}
		b=new'BoolValue'{Parent=root;Name='KFly'}
		Curr.Fly=b
		b.Changed:Connect(function(a)
			if b==Curr.Fly then
			a=b.Value
			local f=a and v3(9e9,9e9,9e9) or v3()
			hum.PlatformStand,bg.MaxTorque,bv.MaxForce=a,f,f
		end
	end)
	b.Value=true
	wrap(function()
		repeat
			if b.Value then
				local dir = hum.MoveDirection
				local CF = cam.CoordinateFrame
				dir = (CF:inverse() * CFrame.new(CF.p + dir)).p
				rwait()
				dir,CF = hum.MoveDirection,cam.CoordinateFrame
				dir=(CF:inverse()*cf(CF.p+dir)).p
				acc=acc*.95
				acc=v3(max(-maxspd,min(maxspd,acc.x+dir.x*m)),max(-maxspd,min(maxspd,not isTyping and (f.KeyDown(Enum.KeyCode.Space) and acc.y+m or f.KeyDown(Enum.KeyCode.LeftControl) and acc.y-m) or acc.y)),max(-maxspd,min(maxspd,acc.z+dir.z*m)))
				bg.cframe,bv.velocity=CF,(CF*cf(acc)).p-CF.p
			else
				wait()
			end
		until not b or b~=Curr.Fly or not hum or not root
	end)
end--]]
--[[
local humPart = script.Parent
local flightVal = humPart:FindFirstChild("FLIGHT_VAL")
local localplayer = game:GetService("Players").LocalPlayer
local mouse = localplayer:GetMouse()
local torso = script.Parent
local human = torso.Parent:FindFirstChildOfClass("Humanoid")
local flying = true
local speed = 0
local keys = {}

local function check()
  if flightVal and flightVal.Parent and flightVal.Parent == humPart then
    return true
  end
end

local function start()
  local pos = Instance.new("BodyPosition",torso)
  local gyro = Instance.new("BodyGyro",torso)
  pos.Name = "ADONIS_FLIGHTPOS"
  pos.maxForce = Vector3.new(math.huge, math.huge, math.huge)
  pos.position = torso.Position
  gyro.Name = "ADONIS_GYRO"
  gyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
  gyro.cframe = torso.CFrame
  human.Died:Connect(function()
  if gyro then gyro:Destroy() end
  if pos then pos:Destroy() end
  	flying = false
 	 human.PlatformStand = false
  	speed = 0
  end)

  repeat
    localplayer.Character.Humanoid.PlatformStand = true
    local new = gyro.cframe - gyro.cframe.p + pos.position

    if not keys.w and not keys.s and not keys.a and not keys.d then
      speed = 1
    end

    if keys.w then
      new = new + workspace.CurrentCamera.CoordinateFrame.LookVector * speed
      speed = speed+0.15
    end
    if keys.a then
      new = new * CFrame.new(-speed,0,0)
      speed = speed+0.15
    end
    if keys.s then
      new = new - workspace.CurrentCamera.CoordinateFrame.LookVector * speed
      speed = speed+0.15
    end
    if keys.d then
      new = new * CFrame.new(speed,0,0)
      speed = speed+0.15
    end

    if speed>10 then
      speed=10
    end
    pos.position=new.p
    if keys.w then
      gyro.cframe = workspace.CurrentCamera.CoordinateFrame*CFrame.Angles(-math.rad(speed*7.5),0,0)
    elseif keys.s then
      gyro.cframe = workspace.CurrentCamera.CoordinateFrame*CFrame.Angles(math.rad(speed*7.5),0,0)
    else
      gyro.cframe = workspace.CurrentCamera.CoordinateFrame
    end
  until not check() or not flying or not gyro or not pos or not pos.Parent or not wait()
  if gyro then gyro:Destroy() end
  if pos then pos:Destroy() end
  flying = false
  human.PlatformStand = false
  speed = 0
end

mouse.KeyDown:Connect(function(key)
if check() then
  if key=="w" then
    keys.w = true
  elseif key=="s" then
    keys.s = true
  elseif key=="a" then
    keys.a = true
  elseif key=="d" then
    keys.d = true
  elseif key=="e" then
    if flying then
      flying = false
    else
      flying = true
      start()
    end
  end
end
end)

mouse.KeyUp:Connect(function(key)
if check() then
  if key=="w" then
    keys.w = false
  elseif key=="s" then
    keys.s = false
  elseif key=="a" then
    keys.a = false
  elseif key=="d" then
    keys.d = false
  end
end
end)

start()
--]]
