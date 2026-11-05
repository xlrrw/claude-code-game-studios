--[[
	ShopService — покупки за звёздный свет: улучшения и духи.
	Все проверки (хватает ли света, есть ли уже дух) — на сервере.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LastLighthouse"):WaitForChild("Config"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local State = require(script.Parent:WaitForChild("ServerState"))
local PetService = require(script.Parent:WaitForChild("PetService"))

local ShopService = {}

function ShopService.BuyUpgrade(player, upgradeId)
	local def = Config.Upgrades[upgradeId]
	local data = DataService.Get(player)
	if not def or not data then
		return
	end
	local level = data.upgrades[upgradeId] or 0
	if level >= def.maxLevel then
		State.Notify(player, def.name .. ": уже максимальный уровень!", "info")
		return
	end
	local cost = Config.GetUpgradeCost(upgradeId, level)
	if not State.SpendLight(player, cost) then
		State.Notify(player, "Не хватает света: нужно " .. State.FormatNumber(cost) .. " ✦", "warn")
		return
	end
	data.upgrades[upgradeId] = level + 1
	State.Notify(player, def.icon .. " " .. def.name .. " — уровень " .. (level + 1) .. "!", "upgrade")
	State.Remotes.Fx:FireClient(player, "Upgrade", upgradeId)
	State.ApplyCharacterPerks(player)
	State.PushPlayer(player)
end

function ShopService.BuyPet(player, petId)
	local def = Config.PetById[petId]
	local data = DataService.Get(player)
	if not def or not data or def.currency ~= "Light" then
		return
	end
	if data.pets[petId] then
		State.Notify(player, def.name .. " уже с тобой", "info")
		return
	end
	if not State.SpendLight(player, def.price) then
		State.Notify(player, "Не хватает света: нужно " .. State.FormatNumber(def.price) .. " ✦", "warn")
		return
	end
	data.pets[petId] = true
	if #data.equipped < State.GetSlots(player) then
		table.insert(data.equipped, petId)
	end
	State.Notify(player, "✨ " .. def.name .. " теперь твой дух!", "pet")
	State.Remotes.Fx:FireClient(player, "NewPet", def.name)
	PetService.Refresh(player)
	State.PushPlayer(player)
end

function ShopService.EquipPet(player, petId)
	local def = Config.PetById[petId]
	local data = DataService.Get(player)
	if not def or not data or not data.pets[petId] then
		return
	end
	for index, equippedId in ipairs(data.equipped) do
		if equippedId == petId then
			table.remove(data.equipped, index)
			PetService.Refresh(player)
			State.PushPlayer(player)
			return
		end
	end
	local slots = State.GetSlots(player)
	if #data.equipped >= slots then
		if slots == 1 then
			-- с одним слотом просто меняем духа
			data.equipped = { petId }
		else
			State.Notify(player, "Все слоты заняты. Убери одного духа или купи «Ещё два духа»", "warn")
			return
		end
	else
		table.insert(data.equipped, petId)
	end
	PetService.Refresh(player)
	State.PushPlayer(player)
end

-- Если слотов стало меньше (например, в Studio выключили тестовые пассы) — убираем лишних.
function ShopService.ClampEquipped(player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local valid = {}
	local slots = State.GetSlots(player)
	for _, petId in ipairs(data.equipped) do
		if data.pets[petId] and Config.PetById[petId] and #valid < slots then
			table.insert(valid, petId)
		end
	end
	data.equipped = valid
end

return ShopService
