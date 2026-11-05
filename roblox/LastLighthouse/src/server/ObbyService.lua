--[[
	ObbyService — паркур на рушащемся острове.

	Папки в LastLighthouseWorld.Obby:
	  Checkpoints      — детали с атрибутом Index (1, 2, 3...)
	  FallingPlatforms — дрожат и падают, когда на них наступают
	  BlinkPlatforms   — мигают; атрибут Phase = 0 или 1
	  JumpPads         — батуты (подбрасывает клиент, см. Movement)
	  Finish           — финиш с наградой
	Упал ниже Config.Obby.VoidY — вернёт на последний чекпоинт.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LastLighthouse"):WaitForChild("Config"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local State = require(script.Parent:WaitForChild("ServerState"))

local ObbyService = {}

local world = workspace:WaitForChild("LastLighthouseWorld")
local obby = world:FindFirstChild("Obby")
local checkpoints = {} -- [player] = BasePart
local lastFinish = {}  -- [player] = os.clock()

local function playerFromHit(hit)
	local character = hit and hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

local function hubSpawnCFrame()
	local spawn = world:FindFirstChild("HubSpawn", true)
	if spawn then
		return spawn.CFrame + Vector3.new(0, 4, 0)
	end
	return CFrame.new(0, 10, 0)
end

local function teleport(player, cframe)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	root.AssemblyLinearVelocity = Vector3.zero
	character:PivotTo(cframe)
end

function ObbyService.ReturnToHub(player)
	checkpoints[player] = nil
	teleport(player, hubSpawnCFrame())
end

------------------------------------------------------------------------
local function setupCheckpoints()
	local folder = obby and obby:FindFirstChild("Checkpoints")
	if not folder then
		return
	end
	for _, cp in ipairs(folder:GetChildren()) do
		if cp:IsA("BasePart") then
			cp.Touched:Connect(function(hit)
				local player = playerFromHit(hit)
				if not player then
					return
				end
				local current = checkpoints[player]
				local index = cp:GetAttribute("Index") or 0
				if current == cp then
					return
				end
				if current and (current:GetAttribute("Index") or 0) >= index then
					return
				end
				checkpoints[player] = cp
				State.Remotes.Fx:FireClient(player, "Checkpoint", cp.Position, index)
			end)
		end
	end
end

local function setupFalling()
	local folder = obby and obby:FindFirstChild("FallingPlatforms")
	if not folder then
		return
	end
	for _, platform in ipairs(folder:GetChildren()) do
		if platform:IsA("BasePart") then
			local origin = platform.CFrame
			local originColor = platform.Color
			local originTransparency = platform.Transparency
			-- светящийся обод (дочерняя деталь Rim) двигаем вместе с платформой
			local rim = platform:FindFirstChild("Rim")
			local rimOffset = rim and origin:ToObjectSpace(rim.CFrame)
			local rimTransparency = rim and rim.Transparency
			local function moveRim(cf, transparency, time)
				if not rim then
					return
				end
				if time then
					TweenService:Create(rim, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						CFrame = cf * rimOffset,
						Transparency = transparency,
					}):Play()
				else
					rim.CFrame = cf * rimOffset
				end
			end
			local busy = false
			platform.Touched:Connect(function(hit)
				if busy or not playerFromHit(hit) then
					return
				end
				busy = true
				platform.Color = Color3.fromRGB(255, 110, 140)
				-- дрожь
				local shakes = math.max(2, math.floor(Config.Obby.FallWarnSeconds / 0.08))
				for i = 1, shakes do
					local shake = origin * CFrame.new((i % 2 == 0 and 0.12 or -0.12), 0, 0)
					platform.CFrame = shake
					moveRim(shake)
					task.wait(0.08)
				end
				platform.CanCollide = false
				local fallen = origin * CFrame.new(0, -25, 0) * CFrame.Angles(math.rad(25), 0, math.rad(15))
				TweenService:Create(platform, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					CFrame = fallen,
					Transparency = 1,
				}):Play()
				moveRim(fallen, 1, 0.9)
				task.wait(Config.Obby.FallRespawnSeconds)
				platform.CFrame = origin * CFrame.new(0, -3, 0)
				moveRim(origin * CFrame.new(0, -3, 0))
				platform.Color = originColor
				platform.CanCollide = true
				TweenService:Create(platform, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
					CFrame = origin,
					Transparency = originTransparency,
				}):Play()
				if rim then
					TweenService:Create(rim, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
						CFrame = origin * rimOffset,
						Transparency = rimTransparency,
					}):Play()
				end
				task.wait(0.4)
				busy = false
			end)
		end
	end
end

local function setupBlink()
	local folder = obby and obby:FindFirstChild("BlinkPlatforms")
	if not folder then
		return
	end
	local groups = { [0] = {}, [1] = {} }
	for _, platform in ipairs(folder:GetChildren()) do
		if platform:IsA("BasePart") then
			local phase = platform:GetAttribute("Phase") or 0
			table.insert(groups[phase % 2], platform)
		end
	end
	task.spawn(function()
		local phase = 0
		while true do
			for groupPhase, list in pairs(groups) do
				local solid = groupPhase == phase
				for _, platform in ipairs(list) do
					platform.CanCollide = solid
					platform.Transparency = solid and 0 or 0.8
					platform.Material = solid and Enum.Material.Neon or Enum.Material.ForceField
				end
			end
			-- предупреждение: за 0.5 сек до смены твёрдые платформы мерцают
			task.wait(Config.Obby.BlinkPeriodSeconds - 0.5)
			for _, platform in ipairs(groups[phase]) do
				platform.Transparency = 0.4
			end
			task.wait(0.5)
			phase = 1 - phase
		end
	end)
end

local function setupFinish()
	local finish = obby and obby:FindFirstChild("Finish", true)
	if not finish or not finish:IsA("BasePart") then
		return
	end
	finish.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if not player then
			return
		end
		local now = os.clock()
		if lastFinish[player] and now - lastFinish[player] < Config.Obby.FinishCooldownSeconds then
			return
		end
		lastFinish[player] = now
		local data = DataService.Get(player)
		if not data then
			return
		end
		data.obbyFinishes = data.obbyFinishes + 1
		local reward = math.floor(Config.Obby.FinishReward * State.GetMultiplier(player) + 0.5)
		State.AddLight(player, reward)
		State.AddXp(player, Config.Obby.FinishXp)
		State.Remotes.Fx:FireClient(player, "ObbyFinish", reward)
		if data.starShards < 1 then
			data.starShards = 1
			State.Remotes.Dialogue:FireClient(player, {
				speaker = "Осколок Звезды",
				lines = { Config.Story.StarShardMessage },
			})
		else
			State.Notify(player, "Паркур пройден! +" .. State.FormatNumber(reward) .. " ✦", "victory")
		end
		State.PushPlayer(player)
		task.delay(3, function()
			if player.Parent then
				ObbyService.ReturnToHub(player)
			end
		end)
	end)
end

local function setupPortals()
	-- любые детали с атрибутом Teleport = "Hub" возвращают на остров с Маяком
	for _, inst in ipairs(world:GetDescendants()) do
		if inst:IsA("BasePart") and inst:GetAttribute("Teleport") == "Hub" then
			local debounce = {}
			inst.Touched:Connect(function(hit)
				local player = playerFromHit(hit)
				if player and not debounce[player] then
					debounce[player] = true
					ObbyService.ReturnToHub(player)
					task.delay(1, function()
						debounce[player] = nil
					end)
				end
			end)
		end
	end
end

local function voidLoop()
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and root.Position.Y < Config.Obby.VoidY then
					local cp = checkpoints[player]
					if cp and cp.Parent then
						teleport(player, cp.CFrame + Vector3.new(0, 4, 0))
					else
						teleport(player, hubSpawnCFrame())
					end
					State.Remotes.Fx:FireClient(player, "Respawned")
				end
			end
		end
	end)
end

function ObbyService.Start()
	if not obby then
		warn("[Маяк] Нет папки LastLighthouseWorld.Obby — паркур отключён")
	end
	setupCheckpoints()
	setupFalling()
	setupBlink()
	setupFinish()
	setupPortals()
	voidLoop()
	Players.PlayerRemoving:Connect(function(player)
		checkpoints[player] = nil
		lastFinish[player] = nil
	end)
end

return ObbyService
