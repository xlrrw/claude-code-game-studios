--[[
	ServerState — общее состояние сервера и связь с клиентами.

	Тут: RemoteEvent'ы, кэш купленных геймпассов, состояние Маяка,
	формулы множителя света / радиуса сбора, отправка данных игрокам,
	табличка над головой и VIP-сияние.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("LastLighthouse")
local Config = require(Shared:WaitForChild("Config"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local State = {}
State.Config = Config
State.Passes = {} -- [player] = { VIP = true, Wings = false, ... }
State.World = {
	lighthouseTotal = 0,
	level = 1,
	nextThreshold = Config.Lighthouse.LevelThresholds[2],
	prevThreshold = 0,
	globalBoostUntil = 0,
	globalBoostBy = "",
	shadowBoostUntil = 0,
	shadow = { active = false, progress = 0, goal = 0, endsAt = 0, nextAt = 0 },
}

function State.Now()
	return workspace:GetServerTimeNow()
end

------------------------------------------------------------------------
-- Remotes
------------------------------------------------------------------------
local remotesFolder = Shared:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = Shared
end

local function remote(name)
	local r = remotesFolder:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remotesFolder
	end
	return r
end

State.Remotes = {
	Notify = remote("Notify"),           -- S→C: всплывающее сообщение
	PlayerState = remote("PlayerState"), -- S→C: данные игрока
	WorldState = remote("WorldState"),   -- S→C: состояние Маяка и событий
	Fx = remote("Fx"),                   -- S→C: эффекты (сбор, награды, окна)
	Dialogue = remote("Dialogue"),       -- S→C: показать диалог
	Action = remote("Action"),           -- C→S: действия игрока (покупки и т.п.)
}

------------------------------------------------------------------------
-- Формулы
------------------------------------------------------------------------
function State.GetRank(xp)
	local index = 1
	for i, rank in ipairs(Config.Ranks) do
		if xp >= rank.xp then
			index = i
		end
	end
	local nextRank = Config.Ranks[index + 1]
	return index, Config.Ranks[index], nextRank
end

function State.GetMultiplier(player)
	local data = DataService.Get(player)
	local passes = State.Passes[player] or {}
	local now = State.Now()
	local mult = 1

	if passes.VIP then
		mult = mult + Config.Passes.VIP.lightBonus
	end
	if player.MembershipType == Enum.MembershipType.Premium then
		mult = mult + Config.Premium.LightBonus
	end
	mult = mult + (State.World.level - 1) * Config.Lighthouse.BonusPerLevel
	if State.World.globalBoostUntil > now then
		mult = mult + Config.Products.GlobalBoost.bonus
	end
	if State.World.shadowBoostUntil > now then
		mult = mult + Config.ShadowEvent.SuccessBonus
	end
	if data then
		local rankIndex = State.GetRank(data.keeperXp)
		mult = mult + (rankIndex - 1) * Config.RankBonus
		for _, petId in ipairs(data.equipped) do
			local pet = Config.PetById[petId]
			if pet then
				mult = mult + pet.lightBonus
			end
		end
	end
	return mult
end

function State.GetRadius(player)
	local data = DataService.Get(player)
	local radius = Config.Light.BasePickupRadius
	if data then
		radius = radius + (data.upgrades.Radius or 0) * Config.Upgrades.Radius.perLevel
		for _, petId in ipairs(data.equipped) do
			local pet = Config.PetById[petId]
			if pet then
				radius = radius + pet.radiusBonus
			end
		end
	end
	return radius
end

function State.GetWalkSpeed(player)
	local data = DataService.Get(player)
	local level = data and data.upgrades.Speed or 0
	return 16 + level * Config.Upgrades.Speed.perLevel
end

function State.GetSlots(player)
	local passes = State.Passes[player] or {}
	if passes.PetSlots then
		return Config.PassEquipSlots
	end
	return Config.BaseEquipSlots
end

------------------------------------------------------------------------
-- Изменение валюты
------------------------------------------------------------------------
function State.AddLight(player, amount)
	local data = DataService.Get(player)
	if not data or amount <= 0 then
		return false
	end
	data.light = data.light + amount
	data.totalLight = data.totalLight + amount
	State.PushPlayer(player)
	return true
end

function State.SpendLight(player, amount)
	local data = DataService.Get(player)
	if not data or amount < 0 or data.light < amount then
		return false
	end
	data.light = data.light - amount
	State.PushPlayer(player)
	return true
end

function State.AddXp(player, amount)
	local data = DataService.Get(player)
	if not data or amount <= 0 then
		return
	end
	local before = State.GetRank(data.keeperXp)
	data.keeperXp = data.keeperXp + amount
	local after, rank = State.GetRank(data.keeperXp)
	if after > before then
		State.Notify(player, "Новый ранг: " .. rank.name .. "! Свет +" .. math.floor(Config.RankBonus * 100) .. "% навсегда", "rank")
		State.Remotes.Fx:FireClient(player, "RankUp", rank.name)
		State.UpdateOverhead(player)
	end
	State.PushPlayer(player)
end

------------------------------------------------------------------------
-- Сообщения
------------------------------------------------------------------------
function State.Notify(player, text, kind)
	State.Remotes.Notify:FireClient(player, text, kind or "info")
end

function State.NotifyAll(text, kind)
	State.Remotes.Notify:FireAllClients(text, kind or "info")
end

------------------------------------------------------------------------
-- Отправка состояния клиентам (склеивает много изменений за кадр в одно)
------------------------------------------------------------------------
local pendingPlayers = {}

local function buildSnapshot(player, data)
	local rankIndex, rank, nextRank = State.GetRank(data.keeperXp)
	return {
		light = data.light,
		totalLight = data.totalLight,
		keeperXp = data.keeperXp,
		rankIndex = rankIndex,
		rankName = rank.name,
		rankXp = rank.xp,
		nextRankXp = nextRank and nextRank.xp or nil,
		upgrades = data.upgrades,
		pets = data.pets,
		equipped = data.equipped,
		notes = data.notes,
		starShards = data.starShards,
		introSeen = data.introSeen,
		passes = State.Passes[player] or {},
		multiplier = State.GetMultiplier(player),
		radius = State.GetRadius(player),
		slots = State.GetSlots(player),
	}
end

function State.PushPlayer(player)
	if pendingPlayers[player] then
		return
	end
	pendingPlayers[player] = true
	task.defer(function()
		pendingPlayers[player] = nil
		if player.Parent == nil then
			return
		end
		local data = DataService.Get(player)
		if not data then
			return
		end
		State.Remotes.PlayerState:FireClient(player, buildSnapshot(player, data))
		State.UpdateLeaderstats(player, data)
	end)
end

function State.PushAllPlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		State.PushPlayer(player)
	end
end

local function worldSnapshot()
	local w = State.World
	return {
		lighthouseTotal = w.lighthouseTotal,
		level = w.level,
		maxLevel = #Config.Lighthouse.LevelThresholds,
		nextThreshold = w.nextThreshold,
		prevThreshold = w.prevThreshold,
		globalBoostUntil = w.globalBoostUntil,
		globalBoostBy = w.globalBoostBy,
		shadowBoostUntil = w.shadowBoostUntil,
		shadow = {
			active = w.shadow.active,
			progress = w.shadow.progress,
			goal = w.shadow.goal,
			endsAt = w.shadow.endsAt,
			nextAt = w.shadow.nextAt,
		},
	}
end

local worldPending = false
function State.PushWorld(player)
	if player then
		State.Remotes.WorldState:FireClient(player, worldSnapshot())
		return
	end
	if worldPending then
		return
	end
	worldPending = true
	task.defer(function()
		worldPending = false
		State.Remotes.WorldState:FireAllClients(worldSnapshot())
	end)
end

------------------------------------------------------------------------
-- Таблица лидеров и табличка над головой
------------------------------------------------------------------------
local function formatNumber(n)
	n = math.floor(n)
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 10000 then
		return string.format("%.1fK", n / 1000)
	end
	return tostring(n)
end
State.FormatNumber = formatNumber

function State.SetupLeaderstats(player)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local light = Instance.new("StringValue")
	light.Name = "✦ Свет"
	light.Value = "0"
	light.Parent = stats
	local rank = Instance.new("StringValue")
	rank.Name = "Ранг"
	rank.Value = Config.Ranks[1].name
	rank.Parent = stats
	stats.Parent = player
end

function State.UpdateLeaderstats(player, data)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return
	end
	local light = stats:FindFirstChild("✦ Свет")
	if light then
		light.Value = formatNumber(data.light)
	end
	local rankValue = stats:FindFirstChild("Ранг")
	if rankValue then
		local _, rank = State.GetRank(data.keeperXp)
		rankValue.Value = rank.name
	end
end

function State.UpdateOverhead(player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local data = DataService.Get(player)
	if not head or not data then
		return
	end
	local gui = head:FindFirstChild("KeeperTag")
	if not gui then
		gui = Instance.new("BillboardGui")
		gui.Name = "KeeperTag"
		gui.Size = UDim2.fromOffset(220, 46)
		gui.StudsOffset = Vector3.new(0, 2.6, 0)
		gui.MaxDistance = 80
		gui.AlwaysOnTop = false
		gui.LightInfluence = 0

		local rankLabel = Instance.new("TextLabel")
		rankLabel.Name = "Rank"
		rankLabel.BackgroundTransparency = 1
		rankLabel.Size = UDim2.new(1, 0, 0.5, 0)
		rankLabel.Position = UDim2.fromScale(0, 0.5)
		rankLabel.Font = Enum.Font.FredokaOne
		rankLabel.TextScaled = true
		rankLabel.TextStrokeTransparency = 0.4
		rankLabel.Parent = gui

		local vipLabel = Instance.new("TextLabel")
		vipLabel.Name = "VIP"
		vipLabel.BackgroundTransparency = 1
		vipLabel.Size = UDim2.new(1, 0, 0.5, 0)
		vipLabel.Font = Enum.Font.FredokaOne
		vipLabel.TextScaled = true
		vipLabel.Text = "👑 VIP"
		vipLabel.TextColor3 = Color3.fromRGB(255, 215, 90)
		vipLabel.TextStrokeTransparency = 0.3
		vipLabel.Parent = gui

		gui.Parent = head
	end
	local _, rank = State.GetRank(data.keeperXp)
	gui.Rank.Text = rank.name
	gui.Rank.TextColor3 = rank.color
	gui.VIP.Visible = (State.Passes[player] or {}).VIP == true
end

function State.ApplyCharacterPerks(player)
	local character = player.Character
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = State.GetWalkSpeed(player)
	end

	local passes = State.Passes[player] or {}
	player:SetAttribute("HasWings", passes.Wings == true)

	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		local aura = root:FindFirstChild("VipAura")
		if passes.VIP and not aura then
			local attachment = Instance.new("Attachment")
			attachment.Name = "VipAura"
			attachment.Parent = root

			local sparkles = Instance.new("ParticleEmitter")
			sparkles.Name = "GoldSparkles"
			sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 170, 60))
			sparkles.LightEmission = 1
			sparkles.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.35),
				NumberSequenceKeypoint.new(1, 0),
			})
			sparkles.Transparency = NumberSequence.new(0.2, 1)
			sparkles.Lifetime = NumberRange.new(0.8, 1.4)
			sparkles.Rate = 14
			sparkles.Speed = NumberRange.new(1, 2.5)
			sparkles.SpreadAngle = Vector2.new(180, 180)
			sparkles.Parent = attachment

			local glow = Instance.new("PointLight")
			glow.Color = Color3.fromRGB(255, 210, 110)
			glow.Range = 10
			glow.Brightness = 1.2
			glow.Parent = attachment
		elseif not passes.VIP and aura then
			aura:Destroy()
		end
	end
	State.UpdateOverhead(player)
end

Players.PlayerRemoving:Connect(function(player)
	State.Passes[player] = nil
	pendingPlayers[player] = nil
end)

return State
