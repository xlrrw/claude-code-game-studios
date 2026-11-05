--[[
	ПОСЛЕДНИЙ МАЯК — точка входа сервера.
	Запускает все сервисы и обрабатывает вход игроков и их действия.
]]

local Players = game:GetService("Players")

local folder = script.Parent
local DataService = require(folder:WaitForChild("DataService"))
local State = require(folder:WaitForChild("ServerState"))
local Monetization = require(folder:WaitForChild("MonetizationService"))
local LightService = require(folder:WaitForChild("LightService"))
local PetService = require(folder:WaitForChild("PetService"))
local ShopService = require(folder:WaitForChild("ShopService"))
local ObbyService = require(folder:WaitForChild("ObbyService"))
local StoryService = require(folder:WaitForChild("StoryService"))

DataService.Start()
Monetization.Start()
LightService.Start()
PetService.Start()
ObbyService.Start()
StoryService.Start()

Monetization.OnPetsChanged = function(player)
	ShopService.ClampEquipped(player)
	PetService.Refresh(player)
	State.PushPlayer(player)
end

------------------------------------------------------------------------
-- Действия игрока (всё проверяется на сервере)
------------------------------------------------------------------------
local actions = {
	BuyUpgrade = function(player, id)
		ShopService.BuyUpgrade(player, id)
	end,
	BuyPet = function(player, id)
		ShopService.BuyPet(player, id)
	end,
	EquipPet = function(player, id)
		ShopService.EquipPet(player, id)
	end,
	Deposit = function(player, fraction)
		LightService.Deposit(player, fraction)
	end,
	PromptPass = function(player, key)
		Monetization.PromptPass(player, key)
	end,
	PromptProduct = function(player, key)
		Monetization.PromptProduct(player, key)
	end,
	IntroDone = function(player)
		StoryService.IntroDone(player)
	end,
	ReturnToHub = function(player)
		ObbyService.ReturnToHub(player)
	end,
	RequestState = function(player)
		State.PushPlayer(player)
		State.PushWorld(player)
	end,
}

local rate = {} -- [player] = { windowStart, count }
local MAX_ACTIONS_PER_SECOND = 10

State.Remotes.Action.OnServerEvent:Connect(function(player, actionName, arg)
	if type(actionName) ~= "string" then
		return
	end
	local handler = actions[actionName]
	if not handler then
		return
	end
	if arg ~= nil and type(arg) ~= "string" and type(arg) ~= "number" then
		return
	end
	local now = os.clock()
	local r = rate[player]
	if not r or now - r[1] > 1 then
		r = { now, 0 }
		rate[player] = r
	end
	r[2] = r[2] + 1
	if r[2] > MAX_ACTIONS_PER_SECOND then
		return
	end
	if not DataService.Get(player) then
		return
	end
	local ok, err = pcall(handler, player, arg)
	if not ok then
		warn("[Маяк] Ошибка действия " .. actionName .. " от " .. player.Name .. ": " .. tostring(err))
	end
end)

------------------------------------------------------------------------
-- Вход игрока
------------------------------------------------------------------------
local function onCharacterAdded(player, character)
	character:WaitForChild("HumanoidRootPart", 10)
	character:WaitForChild("Head", 10)
	if player.Parent == nil or player.Character ~= character then
		return
	end
	State.ApplyCharacterPerks(player)
	PetService.Refresh(player)
end

local function onPlayerAdded(player)
	State.SetupLeaderstats(player)
	Monetization.LoadPasses(player)
	local data = DataService.Load(player)
	if not data then
		return
	end
	ShopService.ClampEquipped(player)

	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end

	State.PushPlayer(player)
	State.PushWorld(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	rate[player] = nil
end)

print("[Маяк] Сервер «Последний Маяк» v" .. State.Config.Version .. " запущен ✦")
