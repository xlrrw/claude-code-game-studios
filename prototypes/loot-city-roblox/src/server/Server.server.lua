--!nonstrict
-- PROTOTYPE - NOT FOR PRODUCTION
-- Loot City server: player data, economy, loot, NPCs, quests, events, plots, vehicles.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage:WaitForChild("LootCityShared")
local Config = require(Shared:WaitForChild("Config"))
local CityBuilder = require(script.Parent:WaitForChild("CityBuilder"))
local ItemFactory = require(script.Parent:WaitForChild("ItemFactory"))
local HomeBuilder = require(script.Parent:WaitForChild("HomeBuilder"))

local ITEM, RARITY, DISTRICTS = Config.ITEM_BY_ID, Config.RARITY, Config.DISTRICTS

-- ---------- remotes ----------
local function remote(class, name)
	local r = Shared:FindFirstChild(name)
	if not r then
		r = Instance.new(class)
		r.Name = name
		r.Parent = Shared
	end
	return r
end
local ActionRF: RemoteFunction = remote("RemoteFunction", "Action")
local PushRE: RemoteEvent = remote("RemoteEvent", "Push")

-- ---------- world ----------
local plan = CityBuilder.Plan()
local map = workspace:FindFirstChild("LootCityMap")
if not map then
	map = CityBuilder.Build(plan)
end
local lootFolder = workspace:FindFirstChild("LootCityLoot") or Instance.new("Folder")
lootFolder.Name = "LootCityLoot"
lootFolder.Parent = workspace
local npcFolder = workspace:FindFirstChild("LootCityNPC") or Instance.new("Folder")
npcFolder.Name = "LootCityNPC"
npcFolder:ClearAllChildren()
npcFolder.Parent = workspace
local plotsFolder = workspace:FindFirstChild("LootCityPlots") or Instance.new("Folder")
plotsFolder.Name = "LootCityPlots"
plotsFolder:ClearAllChildren()
plotsFolder.Parent = workspace

-- global world state
local World = {
	time = 0.36, -- 0..1, 0 = midnight
	day = 1,
	market = {},
	effects = {} :: { [string]: number }, -- id -> seconds left (global)
	eventTimer = 75,
}
local function rollMarket()
	for _, c in Config.CATEGORY_ORDER do
		World.market[c] = math.floor((0.75 + math.random() * 0.6) * 100) / 100
	end
end
rollMarket()
local function isNight()
	return World.time < 0.27 or World.time > 0.8
end

-- ---------- player data ----------
local store
pcall(function()
	store = DataStoreService:GetDataStore("LootCity_v1")
end)
local Data = {} -- player -> state
local Session = {} -- player -> {plot, ticket, passiveAcc, lastPos, vehicleModel}

local function fresh()
	return {
		money = Config.START_MONEY, earned = 0, inv = {}, upg = {}, vehicles = {}, vehicle = nil,
		unlocked = { true, false, false, false }, home = 1, decor = {}, biz = {}, col = {}, colDone = {},
		quests = {}, rep = 0, stats = { found = 0, sold = 0, best = 0, legend = 0 }, last = os.time(),
	}
end

local function has(list, v)
	return table.find(list, v) ~= nil
end
local function lvl(s, id)
	return s.upg[id] or 0
end
local function slots(s)
	return Config.START_SLOTS + lvl(s, "backpack") * 3 + (if has(s.colDone, "retro") then 4 else 0)
end
local function used(s)
	local n = 0
	for _, it in s.inv do
		n += ITEM[it.id].slots
	end
	return n
end
local function prestige(s)
	local p = Config.HOME_STAGES[s.home].prestige
	for _, d in s.decor do
		for _, dd in Config.DECOR do
			if dd.id == d then p += dd.prestige end
		end
	end
	return p
end
local function repLevel(s)
	return math.floor(math.sqrt(s.rep))
end
local function luck(plr)
	local s = Data[plr]
	if not s then return 0 end
	local l = lvl(s, "luck") * 0.3 * (if has(s.colDone, "jewels") then 1.25 else 1)
	if World.effects.rain then l += 0.5 end
	if World.effects.gold then l += 1.5 end
	local ses = Session[plr]
	if ses and ses.ticket and ses.ticket > 0 then l += 1.5 end
	if isNight() then l += 0.3 end
	return l
end
local function tradeMult(s)
	return (1 + lvl(s, "trade") * 0.06) * (if has(s.colDone, "coins") then 1.1 else 1) * (1 + repLevel(s) * 0.02) * (if World.effects.sale then 1.5 else 1)
end
local function ppm(s)
	local p = 0
	for _, b in Config.BUSINESSES do
		p += (s.biz[b.id] or 0) * b.income
	end
	return p * (if has(s.colDone, "art") then 1.5 else 1) * (1 + prestige(s) * 0.01)
end
local function sellMult(npcId, def)
	if npcId == "antiq" then return if def.r >= 3 then 1.3 else 1.1 end
	if npcId == "scrap" then return if def.cat == "metal" or def.cat == "junk" then 1.5 else 0.9 end
	if npcId == "shadow" then return 1.4 end
	if npcId == "jeweler" then return if def.cat == "jewelry" or def.cat == "antiques" or def.cat == "art" then 1.6 else 0.8 end
	return 1
end
local function price(s, item, npcId)
	local def = ITEM[item.id]
	return math.floor(item.value * sellMult(npcId, def) * tradeMult(s) * (World.market[def.cat] or 1) + 0.5)
end
local function needForCollection(s, def)
	return def.col ~= nil and not has(s.col[def.col] or {}, def.id)
end

-- ---------- quests ----------
local function newQuest(d)
	local r = math.random()
	local scale = ({ 1, 3, 8, 20 })[d]
	if r < 0.3 then
		local cats = ({ { "junk", "metal", "electronics" }, { "electronics", "cash", "metal" }, { "metal", "junk", "electronics" }, { "jewelry", "antiques", "art" } })[d]
		local cat = cats[math.random(1, #cats)]
		local n = math.random(2, 3)
		return { type = "cat", cat = cat, n = n, reward = math.floor((60 + math.random() * 40) * n * scale), text = ("Принеси %d предм. категории «%s»."):format(n, Config.CATEGORIES[cat]) }
	elseif r < 0.55 then
		local rar = math.min(5, 1 + d + (if math.random() < 0.3 then 1 else 0))
		return { type = "rar", rar = rar, reward = math.floor(({ 0, 150, 600, 2500, 9000 })[rar] * (1 + d * 0.3)), text = ("Принеси предмет редкости «%s» или выше."):format(RARITY[rar].name) }
	elseif r < 0.8 then
		local n = math.random(4, 8)
		return { type = "pick", d = d, n = n, prog = 0, reward = math.floor(40 * n * scale), text = ("Подбери %d предметов в районе «%s»."):format(n, DISTRICTS[d].name) }
	end
	local amt = math.floor((300 + math.random() * 500) * scale / 50) * 50
	return { type = "earn", amt = amt, prog = 0, reward = math.floor(amt * 0.4), text = ("Заработай $%d на продажах."):format(amt) }
end
local function countCat(s, cat)
	local n = 0
	for _, it in s.inv do
		local d = ITEM[it.id]
		if d.cat == cat and not d.col then n += 1 end
	end
	return n
end
local function questReady(s, q)
	if q.type == "cat" then return countCat(s, q.cat) >= q.n end
	if q.type == "rar" then
		for _, it in s.inv do
			if ITEM[it.id].r >= q.rar then return true end
		end
		return false
	end
	if q.type == "pick" then return q.prog >= q.n end
	if q.type == "earn" then return q.prog >= q.amt end
	return false
end
local function questProgress(s, q)
	if q.type == "cat" then return ("%d/%d в рюкзаке"):format(math.min(q.n, countCat(s, q.cat)), q.n) end
	if q.type == "rar" then return if questReady(s, q) then "Есть в рюкзаке" else "Нет в рюкзаке" end
	if q.type == "pick" then return ("%d/%d"):format(q.prog, q.n) end
	return ("$%d / $%d"):format(q.prog, q.amt)
end
local QUEST_GIVERS = { quest1 = 1, quest2 = 2, scrap = 3, quest4 = 4 }

-- ---------- push ----------
local function snapshot(plr)
	local s = Data[plr]
	local ses = Session[plr]
	local fx = {}
	local names = { sale = "Скупщики +50%", rain = "Дождь: удача ↑", gold = "Золотая лихорадка" }
	for k, t in World.effects do
		table.insert(fx, { name = names[k], t = math.ceil(t) })
	end
	if ses and ses.ticket and ses.ticket > 0 then
		table.insert(fx, { name = "Счастливый билет", t = math.ceil(ses.ticket) })
	end
	local quests = {}
	for id, d in QUEST_GIVERS do
		local q = s.quests[id]
		if q then
			quests[id] = { text = q.text, reward = q.reward, prog = questProgress(s, q), ready = questReady(s, q), d = d }
		else
			quests[id] = { d = d }
		end
	end
	local plot = ses and ses.plot
	return {
		money = s.money, earned = s.earned, inv = s.inv, upg = s.upg, vehicles = s.vehicles, vehicle = s.vehicle,
		unlocked = s.unlocked, home = s.home, decor = s.decor, biz = s.biz, col = s.col, colDone = s.colDone,
		rep = s.rep, repLevel = repLevel(s), stats = s.stats,
		slots = slots(s), used = used(s), detect = Config.BASE_DETECT + lvl(s, "detector") * 40,
		speed = 1 + lvl(s, "shoes") * 0.08, stamina = 4 * (1 + lvl(s, "stamina") * 0.3),
		trade = tradeMult(s), ppm = ppm(s), prestige = prestige(s), effects = fx, market = World.market,
		day = World.day, time = World.time, quests = quests,
		plot = if plot then { x = (plot.x0 + plot.x1) / 2, z = (plot.z0 + plot.z1) / 2 } else nil,
		prices = (function()
			local t = {}
			for i, it in s.inv do
				t[i] = {}
				for _, n in { "pawn", "antiq", "scrap", "shadow", "jeweler" } do
					t[i][n] = price(s, it, n)
				end
			end
			return t
		end)(),
	}
end
local function push(plr, msg)
	PushRE:FireClient(plr, msg)
end
local function sync(plr)
	if Data[plr] then push(plr, { type = "state", state = snapshot(plr) }) end
end
local function toast(plr, text, color)
	push(plr, { type = "toast", text = text, color = color })
end
local function bannerAll(title, sub)
	PushRE:FireAllClients({ type = "banner", title = title, sub = sub })
end

-- ---------- plots ----------
local plots = {}
for i, p in plan.plots do
	local m = Instance.new("Model")
	m.Name = "Plot" .. i
	m.Parent = plotsFolder
	plots[i] = { def = p, model = m, owner = nil }
	HomeBuilder.Sign(m, p, "Свободный участок")
end
local function setupPlot(plr)
	local s = Data[plr]
	for _, pl in plots do
		if not pl.owner then
			pl.owner = plr
			Session[plr].plot = pl.def
			Session[plr].plotModel = pl.model
			HomeBuilder.Sign(pl.model, pl.def, "Участок: " .. plr.DisplayName)
			HomeBuilder.SetStage(pl.model, pl.def, s.home)
			for _, d in s.decor do
				HomeBuilder.AddDecor(pl.model, pl.def, d)
			end
			return
		end
	end
end
local function freePlot(plr)
	for _, pl in plots do
		if pl.owner == plr then
			pl.owner = nil
			pl.model:ClearAllChildren()
			HomeBuilder.Sign(pl.model, pl.def, "Свободный участок")
		end
	end
end

-- ---------- NPCs ----------
local npcs = {} -- id -> {def, model, pos, prompt}
local nightStore = Instance.new("Folder")
nightStore.Name = "LootCityNightNPC"
nightStore.Parent = ServerStorage

local function makeRig(def)
	local desc = Instance.new("HumanoidDescription")
	desc.HeadColor = def.skin
	desc.LeftArmColor = def.shirt
	desc.RightArmColor = def.shirt
	desc.TorsoColor = def.shirt
	desc.LeftLegColor = Color3.fromRGB(38, 38, 44)
	desc.RightLegColor = Color3.fromRGB(38, 38, 44)
	local ok, rig = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if ok and rig then
		return rig
	end
	-- fallback: simple block figure
	local m = Instance.new("Model")
	local hrp = CityBuilder.P(m, Vector3.new(2, 2, 1), CFrame.new(0, 3, 0), Enum.Material.SmoothPlastic, def.shirt, { Transparency = 1 })
	hrp.Name = "HumanoidRootPart"
	CityBuilder.P(m, Vector3.new(2, 2.2, 1), CFrame.new(0, 3.1, 0), Enum.Material.Fabric, def.shirt)
	CityBuilder.P(m, Vector3.new(1.2, 1.2, 1.2), CFrame.new(0, 4.9, 0), Enum.Material.SmoothPlastic, def.skin).Name = "Head"
	Instance.new("Humanoid").Parent = m
	m.PrimaryPart = hrp
	return m
end

for _, def in Config.NPCS do
	local spot = plan.npcSpots[def.id]
	if spot then
		CityBuilder.Kiosk(npcFolder, spot.pos, spot.face, def.sign, def.color)
		local rig = makeRig(def)
		rig.Name = def.name
		local hum = rig:FindFirstChildOfClass("Humanoid")
		local behind = CFrame.lookAt(spot.pos, spot.pos + spot.face) * CFrame.new(0, 0, 1.5)
		rig:PivotTo(behind + Vector3.new(0, 3, 0))
		for _, p in rig:GetDescendants() do
			if p:IsA("BasePart") then p.Anchored = true end
		end
		if hum then
			hum.DisplayName = def.icon .. " " .. def.name
			hum.NameDisplayDistance = 60
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
			hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			pcall(function()
				local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
				local a = Instance.new("Animation")
				a.AnimationId = "rbxassetid://507766666"
				local tr = animator:LoadAnimation(a)
				tr.Looped = true
				tr:Play()
			end)
		end
		local hrp = rig:FindFirstChild("HumanoidRootPart") or rig.PrimaryPart
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Поговорить"
		prompt.ObjectText = def.name .. " — " .. def.role
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.Parent = hrp
		rig:SetAttribute("NPC", def.id)
		rig:SetAttribute("Icon", def.icon)
		rig.Parent = npcFolder
		npcs[def.id] = { def = def, model = rig, pos = spot.pos, prompt = prompt }
		prompt.Triggered:Connect(function(plr)
			if def.night and not isNight() then return end
			if not Data[plr] then return end
			push(plr, { type = "npc", id = def.id, greet = def.greet[math.random(1, #def.greet)] })
		end)
	end
end
local function updateNightNPCs()
	for _, n in npcs do
		if n.def.night then
			local want = if isNight() then npcFolder else nightStore
			if n.model.Parent ~= want then n.model.Parent = want end
		end
	end
end
updateNightNPCs()

-- ---------- loot ----------
local loot = {} -- model -> record
local lootCount = { 0, 0, 0, 0 }
local function rollItem(d, l, extra)
	local dist = DISTRICTS[d]
	local boost = dist.rarityBoost + l + (extra or 0)
	local w = { 100, 38 + boost * 10, 9 + boost * 6, 1.6 + boost * 2.2, 0.18 + boost * 0.55 }
	if d == 1 then w[5] *= 0.5 end
	local total = 0
	for _, x in w do total += x end
	local x = math.random() * total
	local rar = 1
	for i, wi in w do
		if x < wi then rar = i break end
		x -= wi
	end
	local pool = {}
	for _, it in Config.ITEMS do
		if it.r == rar then table.insert(pool, it) end
	end
	return pool[math.random(1, #pool)]
end

local pickup -- forward
local function spawnLoot(def, pos: Vector3, d, special, chest)
	local model = ItemFactory.Make(if chest then { id = "treasure", shape = "treasure", r = 5, name = "Сундук" } else def, CFrame.new(pos))
	local value = math.floor(def.v * DISTRICTS[d].lootMult ^ 0.35 * (0.8 + math.random() * 0.4) + 0.5)
	local rec = { def = def, value = value, d = d, special = special, chest = chest, model = model, expire = if special then 180 else nil }
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = if chest then "Открыть" else "Подобрать"
	prompt.ObjectText = if chest then "Сундук с сокровищами" else ("%s · %s · ~$%d"):format(def.name, RARITY[def.r].name, value)
	prompt.HoldDuration = if chest then 1 else 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(plr)
		pickup(plr, rec)
	end)
	model:SetAttribute("Rarity", def.r)
	model:SetAttribute("Special", special == true)
	model.Parent = lootFolder
	loot[model] = rec
	if not special then lootCount[d] += 1 end
	return rec
end
local function removeLoot(rec)
	if loot[rec.model] then
		loot[rec.model] = nil
		if not rec.special then lootCount[rec.d] -= 1 end
		rec.model:Destroy()
	end
end
local function bestLuckIn(d)
	local best = 0
	for _, plr in Players:GetPlayers() do
		local ch = plr.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if hrp and Config.districtOf(hrp.Position.X, hrp.Position.Z) == d then
			best = math.max(best, luck(plr))
		end
	end
	return best
end
local CAP = 40
local function populate()
	for d = 1, 4 do
		local sp = plan.spawns[d]
		local l = bestLuckIn(d)
		local guard = 0
		while lootCount[d] < CAP and guard < 60 do
			guard += 1
			local p = sp[math.random(1, #sp)]
			local free = true
			for _, rec in loot do
				if (rec.model.PrimaryPart.Position - p).Magnitude < 4 then free = false break end
			end
			if free then
				spawnLoot(rollItem(d, l), p + Vector3.new(math.random() * 3 - 1.5, 0, math.random() * 3 - 1.5), d, false, false)
			end
		end
	end
end

function pickup(plr, rec)
	local s = Data[plr]
	if not s or not loot[rec.model] then return end
	if rec.chest then
		local got, cash = 0, 0
		for _ = 1, 3 do
			local def = rollItem(rec.d, luck(plr), 2.5)
			local value = math.floor(def.v * (0.9 + math.random() * 0.3))
			if used(s) + def.slots <= slots(s) then
				table.insert(s.inv, { id = def.id, value = value })
				got += 1
			else
				cash += value
			end
		end
		s.money += cash
		s.earned += cash
		removeLoot(rec)
		push(plr, { type = "sfx", id = "legend" })
		toast(plr, ("Сундук открыт! %d предм. в рюкзак%s"):format(got, if cash > 0 then (", $%d наличными"):format(cash) else ""), "#ffb52e")
		sync(plr)
		return
	end
	if used(s) + rec.def.slots > slots(s) then
		push(plr, { type = "sfx", id = "error" })
		toast(plr, "Рюкзак полон! Продайте вещи или купите рюкзак побольше.", "#ff5a5a")
		return
	end
	table.insert(s.inv, { id = rec.def.id, value = rec.value })
	s.stats.found += 1
	if rec.def.r == 5 then s.stats.legend += 1 end
	for _, q in s.quests do
		if q and q.type == "pick" and q.d == rec.d then q.prog = math.min(q.n, q.prog + 1) end
	end
	removeLoot(rec)
	push(plr, { type = "sfx", id = "pickup", r = rec.def.r })
	toast(plr, ("%s · %s · ~$%d"):format(rec.def.name, RARITY[rec.def.r].name, rec.value), "#" .. RARITY[rec.def.r].color:ToHex())
	if needForCollection(s, rec.def) then
		toast(plr, "Этот предмет нужен для коллекции! Откройте телефон (Tab).", "#b26bff")
	end
	sync(plr)
end

-- ---------- vehicles ----------
local function vehicleModel(id)
	local m = Instance.new("Model")
	m.Name = "LC_Vehicle"
	local P = CityBuilder.P
	local M = Enum.Material
	local cf = CFrame.new()
	if id == "scooter" then
		P(m, Vector3.new(1.4, 0.4, 5), cf * CFrame.new(0, -2.6, 0), M.Metal, Color3.fromRGB(30, 30, 34))
		P(m, Vector3.new(0.3, 4.5, 0.3), cf * CFrame.new(0, -0.6, -2.4) * CFrame.Angles(math.rad(-10), 0, 0), M.Metal, Color3.fromRGB(200, 200, 205))
		P(m, Vector3.new(3, 0.25, 0.25), cf * CFrame.new(0, 1.6, -2.7), M.Metal, Color3.fromRGB(30, 30, 34))
		for _, z in { -2.4, 2.4 } do
			P(m, Vector3.new(0.4, 1.4, 1.4), cf * CFrame.new(0, -2.7, z), CityBuilder.RUBBER, Color3.fromRGB(20, 20, 20), { Shape = Enum.PartType.Cylinder })
		end
	elseif id == "bike" or id == "moto" then
		local body = if id == "moto" then Color3.fromRGB(20, 20, 22) else Color3.fromRGB(15, 90, 168)
		for _, z in { -2.8, 2.8 } do
			P(m, Vector3.new(0.5, if id == "moto" then 2.8 else 3.2, if id == "moto" then 2.8 else 3.2), cf * CFrame.new(0, -1.6, z), CityBuilder.RUBBER, Color3.fromRGB(20, 20, 20), { Shape = Enum.PartType.Cylinder })
		end
		P(m, Vector3.new(0.4, 0.4, 5.6), cf * CFrame.new(0, -0.8, 0), M.Metal, body)
		P(m, Vector3.new(3, 0.3, 0.3), cf * CFrame.new(0, 1.2, -2.4), M.Metal, Color3.fromRGB(200, 200, 205))
		if id == "moto" then
			P(m, Vector3.new(1.8, 1.4, 3), cf * CFrame.new(0, -0.6, -0.8), M.SmoothPlastic, body, { Reflectance = 0.2 })
			P(m, Vector3.new(1.4, 1, 3), cf * CFrame.new(0, -1.6, 0.6), M.Metal, Color3.fromRGB(150, 150, 155))
			local hl = P(m, Vector3.new(0.9, 0.9, 0.3), cf * CFrame.new(0, 0.2, -3.2), M.Neon, Color3.fromRGB(255, 244, 220))
			local sl = Instance.new("SpotLight")
			sl.Face = Enum.NormalId.Front
			sl.Range = 50
			sl.Brightness = 3
			sl.Parent = hl
		end
	elseif id == "car" then
		local red = Color3.fromRGB(176, 16, 16)
		P(m, Vector3.new(7.4, 2.6, 15), cf * CFrame.new(0, -1.2, -1), M.SmoothPlastic, red, { Reflectance = 0.2 })
		P(m, Vector3.new(7.4, 1, 4), cf * CFrame.new(0, 0.6, 3.6), M.SmoothPlastic, red, { Reflectance = 0.2 })
		P(m, Vector3.new(6.6, 2, 0.3), cf * CFrame.new(0, 1, -2.8) * CFrame.Angles(math.rad(-30), 0, 0), M.Glass, Color3.fromRGB(30, 40, 50), { Transparency = 0.5 })
		for _, o in { { 3.5, -5.5 }, { -3.5, -5.5 }, { 3.5, 3.5 }, { -3.5, 3.5 } } do
			P(m, Vector3.new(1.2, 3, 3), cf * CFrame.new(o[1], -1.5, o[2]), CityBuilder.RUBBER, Color3.fromRGB(20, 20, 20), { Shape = Enum.PartType.Cylinder })
		end
		for _, x in { -2.4, 2.4 } do
			local hl = P(m, Vector3.new(1.6, 0.5, 0.2), cf * CFrame.new(x, -0.6, -8.55), M.Neon, Color3.fromRGB(255, 244, 220))
			local sl = Instance.new("SpotLight")
			sl.Face = Enum.NormalId.Front
			sl.Range = 60
			sl.Brightness = 3
			sl.Parent = hl
		end
	end
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
			p.Massless = true
			p.CanQuery = false
		end
	end
	return m
end
local function applyVehicle(plr)
	local s, ses = Data[plr], Session[plr]
	if not s or not ses then return end
	if ses.vehicleModel then
		ses.vehicleModel:Destroy()
		ses.vehicleModel = nil
	end
	local ch = plr.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not s.vehicle or not hrp then return end
	local m = vehicleModel(s.vehicle)
	for _, p in m:GetChildren() do
		if p:IsA("BasePart") then
			local w = Instance.new("WeldConstraint")
			p.CFrame = hrp.CFrame * p.CFrame
			w.Part0 = hrp
			w.Part1 = p
			w.Parent = p
		end
	end
	m.Parent = ch
	ses.vehicleModel = m
end

-- ---------- data load/save ----------
local function load(plr)
	local s = nil
	if store then
		local ok, res = pcall(function()
			return store:GetAsync("p_" .. plr.UserId)
		end)
		if ok and type(res) == "table" then
			s = fresh()
			for k, v in res do s[k] = v end
		end
	end
	s = s or fresh()
	-- validate inventory entries against the current item list
	local clean = {}
	for _, it in s.inv do
		if ITEM[it.id] then table.insert(clean, it) end
	end
	s.inv = clean
	-- offline income (half rate, max 2h)
	local away = math.min(7200, os.time() - (s.last or os.time()))
	local p = ppm(s)
	if p > 0 and away > 60 then
		local got = math.floor(p * away / 60 * 0.5)
		s.money += got
		s.earned += got
		task.delay(4, function()
			toast(plr, ("Пока вас не было, бизнес принёс $%d"):format(got), "#5ee37a")
		end)
	end
	return s
end
local function save(plr)
	local s = Data[plr]
	if not s or not store then return end
	s.last = os.time()
	pcall(function()
		store:SetAsync("p_" .. plr.UserId, s)
	end)
end

Players.PlayerAdded:Connect(function(plr)
	Session[plr] = { passiveAcc = 0, ticket = 0 }
	Data[plr] = load(plr)
	setupPlot(plr)
	plr.CharacterAdded:Connect(function(ch)
		task.wait(0.5)
		applyVehicle(plr)
		local hum = ch:WaitForChild("Humanoid", 5)
		if hum then hum.BreakJointsOnDeath = false end
	end)
	if plr.Character then applyVehicle(plr) end
	task.delay(2, function()
		sync(plr)
		toast(plr, "Добро пожаловать в Loot City! Ищите светящиеся предметы и нажимайте E.", "#ffb52e")
		task.wait(5)
		toast(plr, "Продать находки можно Михалычу в ломбарде — прямо на рынке.", "#ffb52e")
	end)
end)
Players.PlayerRemoving:Connect(function(plr)
	save(plr)
	freePlot(plr)
	Data[plr] = nil
	Session[plr] = nil
end)
game:BindToClose(function()
	for _, plr in Players:GetPlayers() do
		save(plr)
	end
end)

-- ---------- collections ----------
local function checkCollections(plr)
	local s = Data[plr]
	for _, c in Config.COLLECTIONS do
		if not has(s.colDone, c.id) then
			local all = true
			for _, it in Config.ITEMS do
				if it.col == c.id and not has(s.col[c.id] or {}, it.id) then all = false break end
			end
			if all then
				table.insert(s.colDone, c.id)
				s.money += c.reward
				s.earned += c.reward
				push(plr, { type = "banner", title = "🏆 Коллекция «" .. c.name .. "» собрана!", sub = ("Награда $%d и бонус: %s"):format(c.reward, c.bonusText) })
			end
		end
	end
end

-- ---------- events ----------
local function randomSpawnIn(d)
	local sp = plan.spawns[d]
	return sp[math.random(1, #sp)]
end
local function openDistrictsFor()
	-- any district unlocked by at least one player (or Окраина)
	local open = { 1 }
	for d = 2, 4 do
		for _, plr in Players:GetPlayers() do
			if Data[plr] and Data[plr].unlocked[d] then table.insert(open, d) break end
		end
	end
	return open
end
local function spawnChest(d, at)
	local rec = spawnLoot(ITEM.faberge, at, d, true, true)
	rec.expire = 240
	return rec
end
local function randomEvent()
	local open = openDistrictsFor()
	local d = open[math.random(1, #open)]
	local at = randomSpawnIn(d)
	local ev = ({ "truck", "sale", "rain", "courier", "gold", "treasure" })[math.random(1, 6)]
	PushRE:FireAllClients({ type = "sfx", id = "event" })
	if ev == "truck" then
		for _ = 1, 8 do
			spawnLoot(rollItem(d, 0.5), at + Vector3.new(math.random(-12, 12), 0, math.random(-12, 12)), d, true, false)
		end
		bannerAll("🚚 Грузовик потерял груз!", ("Ценные вещи рассыпались в районе «%s». Метки на карте — 3 минуты!"):format(DISTRICTS[d].name))
	elseif ev == "sale" then
		World.effects.sale = 120
		bannerAll("💸 Ажиотаж на рынке!", "Все скупщики платят на 50% больше — 2 минуты.")
	elseif ev == "rain" then
		World.effects.rain = 160
		workspace:SetAttribute("LC_Rain", true)
		bannerAll("🌧️ Начинается ливень", "В дождь люди теряют больше ценностей. Шанс редких находок повышен.")
	elseif ev == "courier" then
		local pool = {}
		for _, it in Config.ITEMS do
			if it.r >= 4 then table.insert(pool, it) end
		end
		spawnLoot(pool[math.random(1, #pool)], at, d, true, false)
		bannerAll("📦 Курьер потерял посылку", ("Что-то очень ценное лежит в районе «%s». Метка на карте!"):format(DISTRICTS[d].name))
	elseif ev == "gold" then
		World.effects.gold = 75
		bannerAll("✨ Золотая лихорадка!", "75 секунд шанс эпических и легендарных находок резко выше.")
	else
		spawnChest(d, at)
		bannerAll("🗺️ Слухи о кладе", ("Говорят, в районе «%s» зарыт сундук. Метка на карте!"):format(DISTRICTS[d].name))
	end
end

-- ---------- actions ----------
local function nearNPC(plr, id)
	local n = npcs[id]
	local ch = plr.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not n or not hrp then return false end
	if n.def.night and not isNight() then return false end
	return (hrp.Position - n.pos).Magnitude < 30
end

local function sold(plr, p)
	local s = Data[plr]
	s.money += p
	s.earned += p
	s.stats.sold += 1
	s.stats.best = math.max(s.stats.best, p)
	for _, q in s.quests do
		if q and q.type == "earn" then q.prog = math.min(q.amt, q.prog + p) end
	end
end

local Actions = {}
function Actions.sell(plr, s, a)
	if not nearNPC(plr, a.npc) or not table.find({ "pawn", "antiq", "scrap", "shadow", "jeweler" }, a.npc) then return false end
	local it = s.inv[a.i]
	if not it then return false end
	sold(plr, price(s, it, a.npc))
	table.remove(s.inv, a.i)
	return true, "cash"
end
function Actions.sellall(plr, s, a)
	if not nearNPC(plr, a.npc) or not table.find({ "pawn", "antiq", "scrap", "shadow", "jeweler" }, a.npc) then return false end
	local keep, tot = {}, 0
	for _, it in s.inv do
		if needForCollection(s, ITEM[it.id]) then
			table.insert(keep, it)
		else
			tot += price(s, it, a.npc)
		end
	end
	s.inv = keep
	if tot > 0 then
		sold(plr, tot)
		toast(plr, ("Продано на $%d"):format(tot), "#5ee37a")
	end
	return true, "cash"
end
local function pay(s, c)
	if s.money < c then return false end
	s.money -= c
	return true
end
function Actions.upg(plr, s, a)
	if not nearNPC(plr, "gear") then return false end
	for _, u in Config.UPGRADES do
		if u.id == a.id then
			local l = lvl(s, u.id)
			if l < u.max and pay(s, Config.upgradeCost(u, l)) then
				s.upg[u.id] = l + 1
				return true, "cash"
			end
		end
	end
	return false
end
function Actions.veh(plr, s, a)
	if not nearNPC(plr, "garage") then return false end
	for _, v in Config.VEHICLES do
		if v.id == a.id and not has(s.vehicles, v.id) and pay(s, v.cost) then
			table.insert(s.vehicles, v.id)
			s.vehicle = v.id
			applyVehicle(plr)
			toast(plr, "Куплен транспорт: " .. v.name .. "! Клавиша V — сесть/слезть.", "#4aa8ff")
			return true, "cash"
		end
	end
	return false
end
function Actions.ride(plr, s, a)
	if a.id == nil then
		s.vehicle = nil
	elseif has(s.vehicles, a.id) then
		s.vehicle = a.id
	else
		return false
	end
	applyVehicle(plr)
	return true
end
function Actions.biz(plr, s, a)
	if not nearNPC(plr, "broker") then return false end
	for _, b in Config.BUSINESSES do
		local own = s.biz[b.id] or 0
		if b.id == a.id and own < b.max and pay(s, Config.businessCost(b, own)) then
			s.biz[b.id] = own + 1
			toast(plr, "Куплено: " .. b.name, "#5ee37a")
			return true, "cash"
		end
	end
	return false
end
function Actions.perm(plr, s, a)
	if not nearNPC(plr, "mayor") then return false end
	local d = DISTRICTS[a.d]
	if d and not s.unlocked[a.d] and pay(s, d.cost) then
		s.unlocked[a.d] = true
		push(plr, { type = "banner", title = "🔓 Открыт район «" .. d.name .. "»", sub = d.desc })
		return true, "cash"
	end
	return false
end
function Actions.build(plr, s, a)
	if not nearNPC(plr, "foreman") then return false end
	local st = Config.HOME_STAGES[a.stage]
	if st and s.home == a.stage - 1 and pay(s, st.cost) then
		s.home = a.stage
		local ses = Session[plr]
		if ses.plotModel then HomeBuilder.SetStage(ses.plotModel, ses.plot, s.home) end
		push(plr, { type = "banner", title = "🏗️ Стройка завершена!", sub = "Ваш новый дом: " .. st.name })
		return true, "cash"
	end
	return false
end
function Actions.decor(plr, s, a)
	if not nearNPC(plr, "foreman") then return false end
	for _, d in Config.DECOR do
		if d.id == a.id and not has(s.decor, d.id) and s.home >= d.needStage and pay(s, d.cost) then
			table.insert(s.decor, d.id)
			local ses = Session[plr]
			if ses.plotModel then HomeBuilder.AddDecor(ses.plotModel, ses.plot, d.id) end
			toast(plr, "Установлено: " .. d.name, "#5ee37a")
			return true, "cash"
		end
	end
	return false
end
function Actions.map(plr, s, _a)
	if not nearNPC(plr, "antiq") then return false end
	local c = 1500 + World.day * 100
	if not pay(s, c) then return false end
	local open = {}
	for d = 1, 4 do
		if s.unlocked[d] then table.insert(open, d) end
	end
	local d = open[math.random(1, #open)]
	spawnChest(d, randomSpawnIn(d))
	toast(plr, ("Клад отмечен на карте в районе «%s»!"):format(DISTRICTS[d].name), "#ffb52e")
	return true, "cash"
end
function Actions.ticket(plr, s, _a)
	if not nearNPC(plr, "shadow") then return false end
	if not pay(s, 2500) then return false end
	Session[plr].ticket = 180
	return true, "cash"
end
function Actions.qdone(plr, s, a)
	local d = QUEST_GIVERS[a.npc]
	if not d or not nearNPC(plr, a.npc) then return false end
	local q = s.quests[a.npc]
	if not q or not questReady(s, q) then return false end
	if q.type == "cat" then
		local n = q.n
		local keep = {}
		for _, it in s.inv do
			local def = ITEM[it.id]
			if n > 0 and def.cat == q.cat and not def.col then n -= 1 else table.insert(keep, it) end
		end
		s.inv = keep
	elseif q.type == "rar" then
		local bi, bv = nil, math.huge
		for i, it in s.inv do
			if ITEM[it.id].r >= q.rar and it.value < bv then bi, bv = i, it.value end
		end
		if bi then table.remove(s.inv, bi) end
	end
	s.money += q.reward
	s.earned += q.reward
	s.rep += d
	s.quests[a.npc] = nil
	toast(plr, ("Задание выполнено! +$%d"):format(q.reward), "#5ee37a")
	return true, "cash"
end
function Actions.quest(plr, s, a)
	local d = QUEST_GIVERS[a.npc]
	if not d or not nearNPC(plr, a.npc) then return false end
	if not s.quests[a.npc] or a.skip then s.quests[a.npc] = newQuest(d) end
	return true
end
function Actions.drop(plr, s, a)
	local it = s.inv[a.i]
	local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not it or not hrp then return false end
	table.remove(s.inv, a.i)
	local pos = hrp.Position + hrp.CFrame.LookVector * 4
	local rec = spawnLoot(ITEM[it.id], Vector3.new(pos.X, Config.CURB, pos.Z), Config.districtOf(pos.X, pos.Z), true, false)
	rec.value = it.value
	rec.expire = 120
	return true
end
function Actions.collect(plr, s, a)
	local it = s.inv[a.i]
	if not it then return false end
	local def = ITEM[it.id]
	if not needForCollection(s, def) then return false end
	s.col[def.col] = s.col[def.col] or {}
	table.insert(s.col[def.col], def.id)
	table.remove(s.inv, a.i)
	checkCollections(plr)
	return true, "legend"
end
function Actions.taxi(plr, s, _a)
	local ses = Session[plr]
	local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not ses.plot or not hrp or not pay(s, 50) then return false end
	local p = ses.plot
	local c = Vector3.new((p.x0 + p.x1) / 2, Config.CURB + 4, if p.front < 0 then p.z0 - 6 else p.z1 + 6)
	hrp.CFrame = CFrame.new(c)
	toast(plr, "Такси доставило вас к участку.", "#ffb52e")
	return true
end

ActionRF.OnServerInvoke = function(plr, name, args)
	local s = Data[plr]
	if not s or type(name) ~= "string" or not Actions[name] then return false end
	args = if type(args) == "table" then args else {}
	local ok, res, sfx = pcall(Actions[name], plr, s, args)
	if not ok then
		warn("LootCity action error", name, res)
		return false
	end
	if res and sfx then push(plr, { type = "sfx", id = sfx }) end
	sync(plr)
	return res
end

-- ---------- main loop ----------
populate()
local lastDistrictPos = {}
local acc, slow = 0, 0
RunService.Heartbeat:Connect(function(dt)
	World.time += dt / Config.DAY_LENGTH
	if World.time >= 1 then
		World.time -= 1
		World.day += 1
		rollMarket()
		for _, plr in Players:GetPlayers() do
			toast(plr, ("Наступил день %d. Цены на рынке изменились."):format(World.day), "#4aa8ff")
		end
	end
	Lighting.ClockTime = World.time * 24
	acc += dt
	if acc < 0.5 then return end
	local step = acc
	acc = 0
	-- effects
	for k, t in World.effects do
		World.effects[k] = t - step
		if World.effects[k] <= 0 then
			World.effects[k] = nil
			if k == "rain" then workspace:SetAttribute("LC_Rain", false) end
		end
	end
	-- special loot expiry
	for _, rec in loot do
		if rec.expire then
			rec.expire -= step
			if rec.expire <= 0 then removeLoot(rec) end
		end
	end
	-- per player: passive income, ticket, locked districts
	for _, plr in Players:GetPlayers() do
		local s, ses = Data[plr], Session[plr]
		if s and ses then
			ses.passiveAcc += ppm(s) * step / 60
			if ses.passiveAcc >= 1 then
				local w = math.floor(ses.passiveAcc)
				s.money += w
				s.earned += w
				ses.passiveAcc -= w
			end
			if ses.ticket > 0 then ses.ticket -= step end
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local p = hrp.Position
				local d = Config.districtOf(p.X, p.Z)
				if not s.unlocked[d] then
					local back = lastDistrictPos[plr] or plan.spawnPoint + Vector3.new(0, 4, 0)
					hrp.CFrame = CFrame.new(back)
					hrp.AssemblyLinearVelocity = Vector3.zero
				else
					lastDistrictPos[plr] = p
				end
			end
		end
	end
	World.eventTimer -= step
	if World.eventTimer <= 0 then
		World.eventTimer = 110 + math.random() * 110
		randomEvent()
	end
	slow += step
	if slow >= 3 then
		slow = 0
		updateNightNPCs()
		populate()
		for _, plr in Players:GetPlayers() do
			sync(plr)
		end
	end
end)

-- autosave
task.spawn(function()
	while true do
		task.wait(60)
		for _, plr in Players:GetPlayers() do
			save(plr)
		end
	end
end)

local _ = HttpService
print("[LootCity] server ready:", #plan.buildings, "buildings,", #plan.lamps, "lamps")
