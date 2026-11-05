--[[
	LightService — звёздный свет, Маяк и событие «Тень наступает».

	• Осколки света появляются на точках из папки ShardSpawns.
	• Сервер сам проверяет расстояние до игрока (читерам сложнее).
	• Свет можно вложить в Маяк: игрок получает опыт Смотрителя (ранги дают
	  вечный бонус), а Маяк растёт в уровне и усиливает весь сервер.
	• Время от времени наступает Тень: сервер должен вместе вложить свет,
	  иначе Маяк потускнеет.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LastLighthouse"):WaitForChild("Config"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local State = require(script.Parent:WaitForChild("ServerState"))

local LightService = {}

local world = workspace:WaitForChild("LastLighthouseWorld")
local shards = {} -- { part = Part, spawn = BasePart, value = number, active = bool }
local activeFolder
local contributors = {}
local rng = Random.new()

------------------------------------------------------------------------
-- Осколки
------------------------------------------------------------------------
local SHARD_COLORS = {
	Color3.fromRGB(120, 230, 255),
	Color3.fromRGB(255, 225, 120),
	Color3.fromRGB(200, 160, 255),
}

local function makeShardPart(spawnPart, value)
	local part = Instance.new("Part")
	part.Name = "LightShard"
	part.Size = value > Config.Light.ShardValue and Vector3.new(1.3, 1.3, 1.3) or Vector3.new(0.9, 0.9, 0.9)
	part.Material = Enum.Material.Neon
	if value > Config.Light.ShardValue then
		part.Color = Color3.fromRGB(255, 120, 220)
	else
		part.Color = SHARD_COLORS[rng:NextInteger(1, #SHARD_COLORS)]
	end
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.CFrame = CFrame.new(spawnPart.Position) * CFrame.Angles(math.rad(45), 0, math.rad(45))
	part:SetAttribute("Value", value)

	local attachment = Instance.new("Attachment")
	attachment.Parent = part
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(part.Color)
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkle.Transparency = NumberSequence.new(0.1, 1)
	sparkle.Lifetime = NumberRange.new(0.6, 1)
	sparkle.Rate = 5
	sparkle.Speed = NumberRange.new(0.5, 1.5)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Parent = attachment

	return part
end

local function setupShards()
	activeFolder = world:FindFirstChild("ActiveShards")
	if not activeFolder then
		activeFolder = Instance.new("Folder")
		activeFolder.Name = "ActiveShards"
		activeFolder.Parent = world
	end
	local spawns = world:FindFirstChild("ShardSpawns")
	if not spawns then
		warn("[Маяк] Нет папки LastLighthouseWorld.ShardSpawns — осколков не будет")
		return
	end
	for _, spawnPart in ipairs(spawns:GetDescendants()) do
		if spawnPart:IsA("BasePart") then
			spawnPart.Transparency = 1
			spawnPart.CanCollide = false
			spawnPart.CanTouch = false
			spawnPart.CanQuery = false
			local value = spawnPart:GetAttribute("Value") or Config.Light.ShardValue
			local part = makeShardPart(spawnPart, value)
			part.Parent = activeFolder
			table.insert(shards, { part = part, spawn = spawnPart, value = value, active = true })
		end
	end
end

local function collect(player, shard)
	shard.active = false
	local position = shard.part.Position
	shard.part.Parent = nil
	local amount = math.max(1, math.floor(shard.value * State.GetMultiplier(player) + 0.5))
	State.AddLight(player, amount)
	State.Remotes.Fx:FireClient(player, "Pickup", position, amount)
	task.delay(Config.Light.ShardRespawnSeconds, function()
		shard.active = true
		shard.part.Parent = activeFolder
	end)
end

local function pickupLoop()
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator = accumulator + dt
		if accumulator < Config.Light.PickupCheckInterval then
			return
		end
		accumulator = 0
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 and DataService.Get(player) then
				local radius = State.GetRadius(player)
				local position = root.Position
				for _, shard in ipairs(shards) do
					if shard.active and (shard.part.Position - position).Magnitude <= radius then
						collect(player, shard)
					end
				end
			end
		end
	end)
end

------------------------------------------------------------------------
-- Маяк
------------------------------------------------------------------------
local function applyLighthouseVisuals()
	local lighthouse = world:FindFirstChild("Lighthouse")
	if not lighthouse then
		return
	end
	local level = State.World.level
	lighthouse:SetAttribute("Level", level)
	local lantern = lighthouse:FindFirstChild("Lantern", true)
	if lantern then
		local light = lantern:FindFirstChildOfClass("PointLight")
		if light then
			light.Range = math.min(60, 28 + level * 4)
			light.Brightness = 1.5 + level * 0.35
		end
		local t = (level - 1) / math.max(1, #Config.Lighthouse.LevelThresholds - 1)
		lantern.Color = Color3.fromRGB(255, 200, 90):Lerp(Color3.fromRGB(255, 250, 230), t)
	end
end

local function recomputeLevel(announce)
	local thresholds = Config.Lighthouse.LevelThresholds
	local w = State.World
	local oldLevel = w.level
	local level = 1
	for i, threshold in ipairs(thresholds) do
		if w.lighthouseTotal >= threshold then
			level = i
		end
	end
	w.level = level
	w.prevThreshold = thresholds[level]
	w.nextThreshold = thresholds[level + 1]
	applyLighthouseVisuals()
	if level ~= oldLevel then
		State.PushAllPlayers()
		if announce and level > oldLevel then
			State.NotifyAll("🗼 Маяк разгорелся до уровня " .. level .. "! Весь сервер получает +" .. math.floor((level - 1) * Config.Lighthouse.BonusPerLevel * 100 + 0.5) .. "% света", "level")
			State.Remotes.Fx:FireAllClients("LighthouseLevel", level)
		end
	end
	State.PushWorld()
end

function LightService.Deposit(player, fraction)
	if type(fraction) ~= "number" then
		return
	end
	if fraction ~= 0.25 and fraction ~= 0.5 and fraction ~= 1 then
		return
	end
	local data = DataService.Get(player)
	if not data then
		return
	end
	local amount = math.floor(data.light * fraction)
	if amount < 1 then
		State.Notify(player, "У тебя пока нет света. Собирай сияющие осколки!", "warn")
		return
	end
	if not State.SpendLight(player, amount) then
		return
	end
	State.AddXp(player, amount * Config.Lighthouse.XpPerLight)
	State.World.lighthouseTotal = State.World.lighthouseTotal + amount

	local shadow = State.World.shadow
	if shadow.active then
		shadow.progress = shadow.progress + amount
		contributors[player] = true
	end

	State.Remotes.Fx:FireClient(player, "Deposit", amount)
	State.Notify(player, "Ты отдал Маяку " .. State.FormatNumber(amount) .. " ✦ и получил столько же опыта Смотрителя", "deposit")
	recomputeLevel(true)
end

local function setupDepositPrompt()
	local lighthouse = world:FindFirstChild("Lighthouse")
	local pad = lighthouse and lighthouse:FindFirstChild("DepositPad", true)
	if not pad then
		warn("[Маяк] Не найден DepositPad у Маяка")
		return
	end
	local prompt = pad:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Отдать свет"
		prompt.ObjectText = "Маяк"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = pad
	end
	prompt.Triggered:Connect(function(player)
		State.Remotes.Fx:FireClient(player, "OpenDeposit")
	end)
end

------------------------------------------------------------------------
-- Событие «Тень наступает»
------------------------------------------------------------------------
local function runShadowEvent()
	local cfg = Config.ShadowEvent
	local shadow = State.World.shadow
	contributors = {}
	shadow.active = true
	shadow.progress = 0
	shadow.goal = math.max(cfg.GoalMin, #Players:GetPlayers() * cfg.GoalPerPlayer)
	shadow.endsAt = State.Now() + cfg.Duration
	State.NotifyAll("🌑 ТЕНЬ НАСТУПАЕТ! Вложите в Маяк " .. shadow.goal .. " ✦ за " .. math.floor(cfg.Duration / 60) .. " минуты!", "shadow")
	State.Remotes.Fx:FireAllClients("ShadowStart")
	State.PushWorld()

	while State.Now() < shadow.endsAt and shadow.progress < shadow.goal do
		task.wait(0.5)
		State.PushWorld()
	end

	shadow.active = false
	if shadow.progress >= shadow.goal then
		State.World.shadowBoostUntil = State.Now() + cfg.SuccessBoostMinutes * 60
		State.NotifyAll("☀️ Тень отступила! Весь сервер получает +" .. math.floor(cfg.SuccessBonus * 100) .. "% света на " .. cfg.SuccessBoostMinutes .. " минут!", "victory")
		for player in pairs(contributors) do
			if player.Parent then
				State.AddLight(player, cfg.RewardLight)
				State.AddXp(player, cfg.RewardLight)
				State.Notify(player, "Награда героя: +" .. cfg.RewardLight .. " ✦", "purchase")
			end
		end
		State.Remotes.Fx:FireAllClients("ShadowEnd", true)
		task.delay(cfg.SuccessBoostMinutes * 60 + 1, function()
			State.PushAllPlayers()
			State.PushWorld()
		end)
	else
		State.World.lighthouseTotal = math.floor(State.World.lighthouseTotal * (1 - cfg.FailPenalty))
		State.NotifyAll("💨 Тень погасила часть огня... Маяк потускнел. В следующий раз — вместе!", "shadow")
		State.Remotes.Fx:FireAllClients("ShadowEnd", false)
	end
	contributors = {}
	State.PushAllPlayers()
	recomputeLevel(false)
end

local function shadowLoop()
	local cfg = Config.ShadowEvent
	task.spawn(function()
		local delaySeconds = cfg.FirstDelaySeconds
		while true do
			State.World.shadow.nextAt = State.Now() + delaySeconds
			State.PushWorld()
			task.wait(delaySeconds)
			if #Players:GetPlayers() > 0 then
				runShadowEvent()
			end
			delaySeconds = rng:NextInteger(cfg.IntervalMin, cfg.IntervalMax)
		end
	end)
end

function LightService.Start()
	setupShards()
	setupDepositPrompt()
	recomputeLevel(false)
	pickupLoop()
	shadowLoop()
end

return LightService
