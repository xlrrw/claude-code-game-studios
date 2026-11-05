--[[
	MonetizationService — донат.

	• Геймпассы (покупаются один раз): VIP, Крылья, Ещё два духа.
	• Developer Products (можно покупать много раз): свет, буст сервера, Феникс.
	• ProcessReceipt сделан по правилам Roblox: товар выдаётся ровно один раз,
	  покупка записывается в сохранение, и только после успешного сохранения
	  Roblox получает ответ «PurchaseGranted». Если что-то пошло не так —
	  Roblox повторит попытку позже, и игрок не потеряет робуксы.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("LastLighthouse")
local Config = require(Shared:WaitForChild("Config"))
local Ids = require(Shared:WaitForChild("MonetizationIds"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local State = require(script.Parent:WaitForChild("ServerState"))

local Monetization = {}

local passKeyById = {}
for key, id in pairs(Ids.GamePasses) do
	if type(id) == "number" and id > 0 then
		passKeyById[id] = key
	end
end

local productKeyById = {}
for key, id in pairs(Ids.Products) do
	if type(id) == "number" and id > 0 then
		productKeyById[id] = key
	end
end

local function idMissingMessage(name)
	return "«" .. name .. "» ещё не создан. Создай товар на create.roblox.com и вставь его ID в MonetizationIds (см. КАК_ЗАПУСТИТЬ)."
end

------------------------------------------------------------------------
-- Выдача Developer Products. Каждая функция меняет только данные игрока.
------------------------------------------------------------------------
local handlers = {}

local function lightPack(key)
	return function(player)
		local def = Config.Products[key]
		State.AddLight(player, def.light)
		State.Notify(player, "Спасибо! +" .. State.FormatNumber(def.light) .. " ✦ звёздного света", "purchase")
		State.Remotes.Fx:FireClient(player, "Purchase", def.name)
	end
end
handlers.LightSmall = lightPack("LightSmall")
handlers.LightMedium = lightPack("LightMedium")
handlers.LightLarge = lightPack("LightLarge")

handlers.GlobalBoost = function(player)
	local def = Config.Products.GlobalBoost
	local now = State.Now()
	State.World.globalBoostUntil = math.max(State.World.globalBoostUntil, now) + def.minutes * 60
	State.World.globalBoostBy = player.DisplayName
	State.NotifyAll("🔥 " .. player.DisplayName .. " зажёг Маяк для всех! x2 свет на " .. def.minutes .. " минут!", "boost")
	State.Remotes.Fx:FireAllClients("GlobalBoost", player.DisplayName)
	State.PushWorld()
	State.PushAllPlayers()
	-- когда буст закончится — обновим множители у всех
	task.delay(def.minutes * 60 + 1, function()
		State.PushWorld()
		State.PushAllPlayers()
	end)
end

handlers.PhoenixSpirit = function(player, data)
	local def = Config.Products.PhoenixSpirit
	if data.pets[def.pet] then
		State.AddLight(player, def.refundLightIfOwned)
		State.Notify(player, "Феникс уже с тобой — вместо него +" .. State.FormatNumber(def.refundLightIfOwned) .. " ✦", "purchase")
		return
	end
	data.pets[def.pet] = true
	if #data.equipped < State.GetSlots(player) then
		table.insert(data.equipped, def.pet)
	end
	State.Notify(player, "🌈 Аврора-Феникс теперь твой! Призови его в меню «Духи»", "purchase")
	State.Remotes.Fx:FireClient(player, "Purchase", Config.PetById[def.pet].name)
	State.PushPlayer(player)
	if Monetization.OnPetsChanged then
		Monetization.OnPetsChanged(player)
	end
end

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- игрок вышел — Roblox повторит, когда он зайдёт снова
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = DataService.WaitFor(player, 15)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if data.purchases[receiptInfo.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local key = productKeyById[receiptInfo.ProductId]
	local handler = key and handlers[key]
	if not handler then
		warn("[Маяк] Неизвестный товар " .. tostring(receiptInfo.ProductId) .. " — проверь MonetizationIds")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, err = pcall(handler, player, data)
	if not ok then
		warn("[Маяк] Ошибка выдачи товара " .. key .. ": " .. tostring(err))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	DataService.RecordPurchase(player, receiptInfo.PurchaseId)

	if DataService.CanSave(player) then
		if not DataService.Save(player) then
			-- запись о покупке осталась в памяти: при повторе Roblox товар не выдастся дважды
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

------------------------------------------------------------------------
-- Геймпассы
------------------------------------------------------------------------
function Monetization.LoadPasses(player)
	local passes = {}
	local giveAll = RunService:IsStudio() and Config.Debug.GiveAllPassesInStudio
	for key, id in pairs(Ids.GamePasses) do
		if giveAll then
			passes[key] = true
		elseif type(id) == "number" and id > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
			end)
			passes[key] = ok and owns == true
		else
			passes[key] = false
		end
	end
	State.Passes[player] = passes
	return passes
end

local function onPassPurchased(player, passId, wasPurchased)
	if not wasPurchased then
		return
	end
	local key = passKeyById[passId]
	if not key then
		return
	end
	local passes = State.Passes[player] or {}
	passes[key] = true
	State.Passes[player] = passes

	local def = Config.Passes[key]
	State.Notify(player, def.icon .. " " .. def.name .. " активирован! Спасибо за поддержку!", "purchase")
	State.Remotes.Fx:FireClient(player, "Purchase", def.name)
	State.ApplyCharacterPerks(player)
	State.PushPlayer(player)
	if key == "PetSlots" and Monetization.OnPetsChanged then
		Monetization.OnPetsChanged(player)
	end
end

------------------------------------------------------------------------
-- Запросы от клиента
------------------------------------------------------------------------
function Monetization.PromptPass(player, key)
	local def = Config.Passes[key]
	if not def then
		return
	end
	if (State.Passes[player] or {})[key] then
		State.Notify(player, "У тебя уже есть «" .. def.name .. "»", "info")
		return
	end
	local id = Ids.GamePasses[key]
	if type(id) ~= "number" or id <= 0 then
		State.Notify(player, idMissingMessage(def.name), "warn")
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, id)
end

function Monetization.PromptProduct(player, key)
	local def = Config.Products[key]
	if not def then
		return
	end
	if def.pet then
		local data = DataService.Get(player)
		if data and data.pets[def.pet] then
			State.Notify(player, "Этот дух уже с тобой!", "info")
			return
		end
	end
	local id = Ids.Products[key]
	if type(id) ~= "number" or id <= 0 then
		State.Notify(player, idMissingMessage(def.name), "warn")
		return
	end
	MarketplaceService:PromptProductPurchase(player, id)
end

function Monetization.Start()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onPassPurchased)
end

return Monetization
