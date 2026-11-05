--[[
	DataService — загрузка и сохранение прогресса игроков (DataStore).

	• Прогресс сохраняется при выходе, каждые 2 минуты и сразу после доната.
	• Если DataStore недоступен (например, в Studio без доступа к API),
	  игра работает, но ничего не сохраняет и пишет предупреждение в Output.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LastLighthouse"):WaitForChild("Config"))

local DataService = {}

local AUTOSAVE_SECONDS = 120
local MAX_PURCHASE_LOG = 100

local TEMPLATE = {
	light = 0,
	totalLight = 0,
	keeperXp = 0,
	upgrades = { Radius = 0, Speed = 0 },
	pets = {},        -- [petId] = true
	equipped = {},    -- { petId, ... }
	notes = {},       -- ["1"] = true
	introSeen = false,
	starShards = 0,
	obbyFinishes = 0,
	purchases = {},   -- [purchaseId] = true (защита от двойной выдачи)
	purchaseLog = {}, -- порядок покупок, чтобы чистить старые записи
	firstJoin = 0,
}

local profiles = {} -- [player] = { data = {}, canSave = bool, saving = bool }
local loadedEvent = Instance.new("BindableEvent")
DataService.Loaded = loadedEvent.Event

local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[Маяк] DataStore недоступен — прогресс не будет сохраняться. Включи: Game Settings → Security → Enable Studio Access to API Services. Ошибка: " .. tostring(result))
	end
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end
	return copy
end

local function reconcile(data, template)
	for key, value in pairs(template) do
		if data[key] == nil then
			data[key] = deepCopy(value)
		elseif type(value) == "table" and type(data[key]) == "table" then
			-- для словарей с фиксированными ключами (upgrades) добиваем недостающие
			if next(value) ~= nil and #value == 0 then
				reconcile(data[key], value)
			end
		end
	end
	return data
end

local function keyFor(player)
	return "player_" .. player.UserId
end

function DataService.Load(player)
	local data = nil
	local loadedOk = false

	if store then
		-- в Studio одна попытка, чтобы не ждать, если доступ к API выключен
		local attempts = RunService:IsStudio() and 1 or 4
		for attempt = 1, attempts do
			local ok, result = pcall(function()
				return store:GetAsync(keyFor(player))
			end)
			if ok then
				data = result
				loadedOk = true
				break
			end
			warn("[Маяк] Не удалось загрузить данные " .. player.Name .. " (попытка " .. attempt .. "): " .. tostring(result))
			if attempt < attempts then
				task.wait(attempt * 1.5)
			end
		end
	end

	if player.Parent == nil then
		return nil
	end

	if type(data) ~= "table" then
		data = deepCopy(TEMPLATE)
		data.firstJoin = os.time()
		if RunService:IsStudio() then
			data.light = Config.Debug.StartingLightInStudio or 0
		end
	end
	reconcile(data, TEMPLATE)

	profiles[player] = {
		data = data,
		-- если загрузка упала, НЕ сохраняем, иначе перезапишем настоящий прогресс пустым
		canSave = store ~= nil and loadedOk,
		saving = false,
	}
	if store and not loadedOk then
		warn("[Маяк] Прогресс " .. player.Name .. " не загрузился — в этой сессии он не будет сохраняться.")
	end

	loadedEvent:Fire(player, data)
	return data
end

function DataService.Get(player)
	local profile = profiles[player]
	return profile and profile.data or nil
end

-- Ждёт загрузки профиля (нужно для обработки покупок).
function DataService.WaitFor(player, timeout)
	local deadline = os.clock() + (timeout or 10)
	while os.clock() < deadline do
		local profile = profiles[player]
		if profile then
			return profile.data
		end
		if player.Parent == nil then
			return nil
		end
		task.wait(0.2)
	end
	return nil
end

function DataService.CanSave(player)
	local profile = profiles[player]
	return profile ~= nil and profile.canSave
end

-- Возвращает true, если сохранение прошло успешно.
function DataService.Save(player)
	local profile = profiles[player]
	if not profile or not profile.canSave then
		return false
	end
	while profile.saving do
		task.wait(0.1)
	end
	profile.saving = true
	local success = false
	for attempt = 1, 3 do
		local ok, err = pcall(function()
			store:UpdateAsync(keyFor(player), function()
				return profile.data
			end)
		end)
		if ok then
			success = true
			break
		end
		warn("[Маяк] Ошибка сохранения " .. player.Name .. " (попытка " .. attempt .. "): " .. tostring(err))
		task.wait(attempt)
	end
	profile.saving = false
	return success
end

function DataService.RecordPurchase(player, purchaseId)
	local data = DataService.Get(player)
	if not data then
		return
	end
	data.purchases[purchaseId] = true
	table.insert(data.purchaseLog, purchaseId)
	while #data.purchaseLog > MAX_PURCHASE_LOG do
		local oldest = table.remove(data.purchaseLog, 1)
		data.purchases[oldest] = nil
	end
end

function DataService.Release(player)
	DataService.Save(player)
	profiles[player] = nil
end

function DataService.Start()
	Players.PlayerRemoving:Connect(function(player)
		DataService.Release(player)
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player in pairs(profiles) do
				task.spawn(DataService.Save, player)
			end
		end
	end)

	game:BindToClose(function()
		if RunService:IsStudio() and not store then
			return
		end
		local pending = 0
		for player in pairs(profiles) do
			pending = pending + 1
			task.spawn(function()
				DataService.Save(player)
				pending = pending - 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.2)
		end
	end)
end

return DataService
