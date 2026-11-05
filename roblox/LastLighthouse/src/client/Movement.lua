--[[
	Movement — двойной прыжок (геймпасс «Крылья Смотрителя») и батуты.
	Физику своего персонажа считает компьютер игрока, поэтому это клиентский код.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LastLighthouse"):WaitForChild("Config"))

local player = Players.LocalPlayer
local Movement = {}

local usedDoubleJump = false
local lastPad = 0
local effects

local function wingBurst(root)
	if effects then
		effects.Burst(root.Position - Vector3.new(0, 1.5, 0), Color3.fromRGB(200, 240, 255), 18, 0.5)
	end
end

local function onCharacter(character)
	usedDoubleJump = false
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			usedDoubleJump = false
		end
	end)
end

local function setupJumpPads()
	local world = workspace:WaitForChild("LastLighthouseWorld")
	local obby = world:FindFirstChild("Obby")
	local pads = obby and obby:FindFirstChild("JumpPads")
	if not pads then
		return
	end
	for _, pad in ipairs(pads:GetChildren()) do
		if pad:IsA("BasePart") then
			pad.Touched:Connect(function(hit)
				local character = player.Character
				if not character or not hit:IsDescendantOf(character) then
					return
				end
				if os.clock() - lastPad < 0.6 then
					return
				end
				lastPad = os.clock()
				local root = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if root and humanoid then
					local v = root.AssemblyLinearVelocity
					root.AssemblyLinearVelocity = Vector3.new(v.X, Config.Obby.JumpPadVelocity, v.Z)
					humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
					usedDoubleJump = false
					if effects then
						effects.Burst(pad.Position + Vector3.new(0, 1, 0), Color3.fromRGB(110, 240, 160), 30, 0.7)
						effects.Ring(pad.Position + Vector3.new(0, 0.5, 0), Color3.fromRGB(110, 240, 160))
					end
				end
			end)
		end
	end
end

function Movement.Init(effectsModule)
	effects = effectsModule
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)

	UserInputService.JumpRequest:Connect(function()
		if not player:GetAttribute("HasWings") or usedDoubleJump then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not root then
			return
		end
		if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
			return
		end
		usedDoubleJump = true
		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(v.X, 55, v.Z)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		wingBurst(root)
	end)

	task.spawn(setupJumpPads)
end

return Movement
