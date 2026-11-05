--[[
	ПОСЛЕДНИЙ МАЯК — точка входа клиента.
	Связывает интерфейс, эффекты, катсцену и движение с сервером.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("LastLighthouse")
local Remotes = Shared:WaitForChild("Remotes")
local folder = script.Parent

local UI = require(folder:WaitForChild("UI"))
local Effects = require(folder:WaitForChild("Effects"))
local Intro = require(folder:WaitForChild("Intro"))
local Movement = require(folder:WaitForChild("Movement"))
local Sound = require(folder:WaitForChild("Sound"))

local player = Players.LocalPlayer

local Action = Remotes:WaitForChild("Action")
local function send(actionName, arg)
	Action:FireServer(actionName, arg)
end

UI.Init({ send = send })
Effects.Init()
Movement.Init(Effects)

------------------------------------------------------------------------
local introStarted = false
local lastRank = nil

Remotes:WaitForChild("PlayerState").OnClientEvent:Connect(function(state)
	UI.SetPlayerState(state)
	lastRank = state.rankIndex
	if not state.introSeen and not introStarted then
		introStarted = true
		task.spawn(function()
			local ok, err = pcall(Intro.Play, UI)
			if not ok then
				warn("[Маяк] Ошибка катсцены: " .. tostring(err))
				local camera = workspace.CurrentCamera
				camera.CameraType = Enum.CameraType.Custom
				UI.SetHudVisible(true)
			end
			send("IntroDone")
		end)
	end
end)

Remotes:WaitForChild("WorldState").OnClientEvent:Connect(function(state)
	UI.SetWorldState(state)
	Effects.SetWorldState(state)
end)

Remotes:WaitForChild("Notify").OnClientEvent:Connect(function(text, kind)
	UI.Notify(text, kind)
end)

Remotes:WaitForChild("Dialogue").OnClientEvent:Connect(function(entry)
	UI.ShowDialogue(entry)
end)

local fx = {}
fx.Pickup = function(position, amount)
	Effects.Pickup(position, amount)
	UI.BumpLight()
end
fx.OpenDeposit = function()
	UI.OpenDeposit()
end
fx.Deposit = function(amount)
	local lighthouse = workspace:FindFirstChild("LastLighthouseWorld") and workspace.LastLighthouseWorld:FindFirstChild("Lighthouse")
	local lantern = lighthouse and lighthouse:FindFirstChild("Lantern", true)
	if lantern then
		Effects.Burst(lantern.Position, Color3.fromRGB(255, 220, 120), 50, 1.2)
	end
	Effects.Celebrate(Color3.fromRGB(255, 211, 107))
end
fx.RankUp = function(rankName)
	Sound.Play("LevelUp")
	UI.Banner("НОВЫЙ РАНГ!", rankName, Color3.fromRGB(110, 240, 160))
	Effects.Celebrate()
	Effects.ScreenFlash(Color3.fromRGB(200, 255, 220), 0.25)
end
fx.LighthouseLevel = function(level)
	Sound.Play("LevelUp")
	UI.Banner("МАЯК: УРОВЕНЬ " .. level, "Свет стал сильнее для всех!", Color3.fromRGB(255, 211, 107))
	Effects.ScreenFlash(Color3.fromRGB(255, 240, 200), 0.35)
end
fx.ShadowStart = function()
	UI.Banner("ТЕНЬ НАСТУПАЕТ", "Несите свет в Маяк!", Color3.fromRGB(150, 110, 255))
end
fx.ShadowEnd = function(success)
	if success then
		UI.Banner("ТЕНЬ ОТСТУПИЛА!", "Вы спасли Маяк ☀️", Color3.fromRGB(110, 240, 160))
		Effects.Celebrate()
		Effects.ScreenFlash(Color3.fromRGB(255, 250, 220), 0.4)
	else
		UI.Banner("МАЯК ПОТУСКНЕЛ", "В следующий раз — вместе!", Color3.fromRGB(150, 110, 255))
	end
end
fx.Checkpoint = function(position, index)
	Sound.Play("Pickup")
	Effects.Ring(position + Vector3.new(0, 1, 0), Color3.fromRGB(110, 240, 160))
	UI.Notify("🚩 Чекпоинт " .. tostring(index), "victory")
end
fx.ObbyFinish = function(reward)
	Sound.Play("LevelUp")
	UI.Banner("ПАРКУР ПРОЙДЕН!", "+" .. UI.FormatNumber(reward) .. " ✦", Color3.fromRGB(255, 122, 217))
	Effects.Celebrate()
end
fx.Purchase = function(name)
	Sound.Play("Purchase")
	UI.Banner("СПАСИБО!", name, Color3.fromRGB(255, 211, 107))
	Effects.Celebrate()
end
fx.NewPet = function(name)
	Sound.Play("Purchase")
	UI.Banner("НОВЫЙ ДУХ!", name, Color3.fromRGB(255, 122, 217))
	Effects.Celebrate(Color3.fromRGB(255, 122, 217))
end
fx.Upgrade = function()
	Sound.Play("Purchase")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		Effects.Ring(root.Position - Vector3.new(0, 2.5, 0), Color3.fromRGB(107, 228, 255))
	end
end
fx.GlobalBoost = function(byName)
	UI.Banner("🔥 x2 СВЕТ ДЛЯ ВСЕХ!", "Спасибо, " .. tostring(byName) .. "!", Color3.fromRGB(255, 160, 70))
	Effects.ScreenFlash(Color3.fromRGB(255, 220, 160), 0.3)
end
fx.Respawned = function()
	Effects.ScreenFlash(Color3.fromRGB(200, 180, 255), 0.4)
end

Remotes:WaitForChild("Fx").OnClientEvent:Connect(function(kind, ...)
	local handler = fx[kind]
	if handler then
		local ok, err = pcall(handler, ...)
		if not ok then
			warn("[Маяк] Ошибка эффекта " .. tostring(kind) .. ": " .. tostring(err))
		end
	end
end)

-- на случай, если сервер отправил данные раньше, чем мы подписались
send("RequestState")
