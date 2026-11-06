-- ================================================================
-- LOOT CITY: Город возможностей — установщик для Roblox Studio
-- 1) Откройте пустое место (шаблон Baseplate) в Roblox Studio
-- 2) Вкладка View -> Command Bar
-- 3) Вставьте ВЕСЬ этот текст в Command Bar и нажмите Enter
-- 4) Дождитесь сообщения "Loot City установлен" в Output и нажмите Play
-- Повторная установка безопасна: старая версия удаляется.
-- ================================================================
local ok, err = pcall(function()
	local RS = game:GetService("ReplicatedStorage")
	local SSS = game:GetService("ServerScriptService")
	local SP = game:GetService("StarterPlayer")
	local Lighting = game:GetService("Lighting")
	local SPS = SP:WaitForChild("StarterPlayerScripts")
	print("[LootCity] установка…")
	for _, o in { RS:FindFirstChild("LootCityShared"), SSS:FindFirstChild("LootCityServer"), SPS:FindFirstChild("LootCityClient"),
		workspace:FindFirstChild("LootCityMap"), workspace:FindFirstChild("LootCityLoot"), workspace:FindFirstChild("LootCityNPC"),
		workspace:FindFirstChild("LootCityPlots"), workspace:FindFirstChild("Baseplate"), workspace:FindFirstChild("SpawnLocation") } do
		if o then o:Destroy() end
	end
	local function script(class, name, parent, source)
		local s = Instance.new(class)
		s.Name = name
		s.Source = source
		s.Parent = parent
		return s
	end
	local shared = Instance.new("Folder")
	shared.Name = "LootCityShared"
	shared.Parent = RS
	script("ModuleScript", "Config", shared, [========[
--!strict
-- PROTOTYPE - NOT FOR PRODUCTION
-- Loot City: all gameplay data, tuning values and map layout (shared by server and client).
local Config = {}

Config.RARITY = {
	{ name = "Обычный", color = Color3.fromRGB(201, 206, 214), light = 0 },
	{ name = "Необычный", color = Color3.fromRGB(94, 227, 122), light = 0.6 },
	{ name = "Редкий", color = Color3.fromRGB(74, 168, 255), light = 1.2 },
	{ name = "Эпический", color = Color3.fromRGB(178, 107, 255), light = 2.0 },
	{ name = "Легендарный", color = Color3.fromRGB(255, 181, 46), light = 3.0 },
}

Config.CATEGORIES = {
	junk = "Хлам", metal = "Металл", electronics = "Электроника", jewelry = "Драгоценности",
	antiques = "Антиквариат", art = "Искусство", cash = "Наличные",
}
Config.CATEGORY_ORDER = { "junk", "metal", "electronics", "jewelry", "antiques", "art", "cash" }

export type ItemDef = { id: string, name: string, r: number, v: number, cat: string, shape: string, slots: number, col: string?, mat: string? }

-- r = rarity index 1..5
Config.ITEMS = {
	{ id = "bottle", name = "Пустая бутылка", r = 1, v = 4, cat = "junk", shape = "bottle", slots = 1 },
	{ id = "can", name = "Алюминиевая банка", r = 1, v = 3, cat = "metal", shape = "can", slots = 1 },
	{ id = "cardboard", name = "Коробка с барахлом", r = 1, v = 9, cat = "junk", shape = "box", slots = 2 },
	{ id = "scrap", name = "Медный провод", r = 1, v = 14, cat = "metal", shape = "coil", slots = 1 },
	{ id = "oldphone", name = "Разбитый телефон", r = 1, v = 12, cat = "electronics", shape = "phone", slots = 1 },
	{ id = "trashbag", name = "Пакет со всячиной", r = 1, v = 7, cat = "junk", shape = "bag", slots = 2 },
	{ id = "tire", name = "Старая покрышка", r = 1, v = 11, cat = "junk", shape = "tire", slots = 2 },
	{ id = "headphones", name = "Наушники", r = 2, v = 45, cat = "electronics", shape = "headphones", slots = 1 },
	{ id = "toolbox", name = "Ящик с инструментами", r = 2, v = 70, cat = "metal", shape = "toolbox", slots = 2 },
	{ id = "wallet", name = "Кожаный кошелёк", r = 2, v = 60, cat = "cash", shape = "wallet", slots = 1 },
	{ id = "radio", name = "Транзисторный радиоприёмник", r = 2, v = 55, cat = "electronics", shape = "radio", slots = 1 },
	{ id = "silverspoon", name = "Серебряная ложка", r = 2, v = 80, cat = "metal", shape = "spoon", slots = 1 },
	{ id = "laptop", name = "Ноутбук", r = 3, v = 260, cat = "electronics", shape = "laptop", slots = 2 },
	{ id = "gpu", name = "Видеокарта", r = 3, v = 380, cat = "electronics", shape = "gpu", slots = 1 },
	{ id = "cashstack", name = "Пачка купюр", r = 3, v = 300, cat = "cash", shape = "cash", slots = 1 },
	{ id = "silverbar", name = "Серебряный слиток", r = 3, v = 420, cat = "metal", shape = "bar", slots = 1, mat = "silver" },
	{ id = "goldwatch", name = "Золотые часы", r = 4, v = 1300, cat = "jewelry", shape = "watch", slots = 1, col = "jewels" },
	{ id = "briefcase", name = "Кейс с деньгами", r = 4, v = 1800, cat = "cash", shape = "case", slots = 2 },
	{ id = "goldbar", name = "Золотой слиток", r = 4, v = 1600, cat = "metal", shape = "bar", slots = 1, mat = "gold" },
	{ id = "diamond", name = "Бриллиант «Звезда Севера»", r = 5, v = 9000, cat = "jewelry", shape = "gem", slots = 1, col = "jewels", mat = "diamond" },
	{ id = "faberge", name = "Императорское яйцо", r = 5, v = 12000, cat = "antiques", shape = "egg", slots = 1 },
	-- collections
	{ id = "c_ruble", name = "Царский рубль", r = 3, v = 350, cat = "antiques", shape = "coin", slots = 1, col = "coins", mat = "silver" },
	{ id = "c_denar", name = "Римский денарий", r = 3, v = 420, cat = "antiques", shape = "coin", slots = 1, col = "coins", mat = "silver" },
	{ id = "c_dublon", name = "Испанский дублон", r = 4, v = 1100, cat = "antiques", shape = "coin", slots = 1, col = "coins", mat = "gold" },
	{ id = "c_dollar", name = "Серебряный доллар 1804", r = 4, v = 1400, cat = "antiques", shape = "coin", slots = 1, col = "coins", mat = "silver" },
	{ id = "c_byzant", name = "Византийский солид", r = 5, v = 4200, cat = "antiques", shape = "coin", slots = 1, col = "coins", mat = "gold" },
	{ id = "r_camera", name = "Плёночная камера", r = 2, v = 120, cat = "electronics", shape = "camera", slots = 1, col = "retro" },
	{ id = "r_cassette", name = "Кассетный плеер", r = 2, v = 95, cat = "electronics", shape = "radio", slots = 1, col = "retro" },
	{ id = "r_vinyl", name = "Редкая пластинка", r = 3, v = 280, cat = "art", shape = "record", slots = 1, col = "retro" },
	{ id = "r_console", name = "Карманная консоль", r = 3, v = 340, cat = "electronics", shape = "console", slots = 1, col = "retro" },
	{ id = "r_phone", name = "Дисковый телефон", r = 4, v = 900, cat = "antiques", shape = "rotary", slots = 2, col = "retro" },
	{ id = "j_ring", name = "Кольцо с рубином", r = 4, v = 1500, cat = "jewelry", shape = "ring", slots = 1, col = "jewels" },
	{ id = "j_pearl", name = "Жемчужное ожерелье", r = 4, v = 1900, cat = "jewelry", shape = "necklace", slots = 1, col = "jewels" },
	{ id = "j_emerald", name = "Изумруд", r = 5, v = 6000, cat = "jewelry", shape = "gem", slots = 1, col = "jewels", mat = "emerald" },
	{ id = "a_paint", name = "Картина маслом", r = 4, v = 2200, cat = "art", shape = "frame", slots = 2, col = "art" },
	{ id = "a_statue", name = "Бронзовая статуэтка", r = 4, v = 1700, cat = "art", shape = "statue", slots = 2, col = "art" },
	{ id = "a_vase", name = "Фарфоровая ваза", r = 3, v = 600, cat = "art", shape = "vase", slots = 2, col = "art" },
	{ id = "a_box", name = "Антикварная шкатулка", r = 3, v = 520, cat = "antiques", shape = "chest", slots = 1, col = "art" },
	{ id = "a_master", name = "Утерянный шедевр", r = 5, v = 15000, cat = "art", shape = "frame", slots = 2, col = "art" },
} :: { ItemDef }

Config.ITEM_BY_ID = {} :: { [string]: ItemDef }
for _, it in Config.ITEMS do
	Config.ITEM_BY_ID[it.id] = it
end

Config.COLLECTIONS = {
	{ id = "coins", name = "Старинные монеты", bonusText = "+10% к цене продажи", reward = 5000 },
	{ id = "retro", name = "Ретро-техника", bonusText = "+4 места в рюкзаке", reward = 3000 },
	{ id = "jewels", name = "Драгоценности", bonusText = "+25% к удаче", reward = 15000 },
	{ id = "art", name = "Искусство", bonusText = "×1.5 пассивный доход", reward = 25000 },
}

-- Quadrant districts. 1 = Окраина (x<0, z>=0), 2 = Центр (x>=0, z>=0), 3 = Промзона (x<0, z<0), 4 = Холмы (x>=0, z<0)
Config.DISTRICTS = {
	{ name = "Окраина", cost = 0, lootMult = 1.0, rarityBoost = 0, color = Color3.fromRGB(201, 139, 74), desc = "Старые кирпичные дома, гаражи и пустыри." },
	{ name = "Центр", cost = 3000, lootMult = 1.6, rarityBoost = 0.6, color = Color3.fromRGB(74, 168, 255), desc = "Стеклянные небоскрёбы, офисы и магазины." },
	{ name = "Промзона", cost = 15000, lootMult = 2.4, rarityBoost = 1.2, color = Color3.fromRGB(154, 161, 168), desc = "Склады и контейнеры. Ночью — чёрный рынок." },
	{ name = "Золотые холмы", cost = 75000, lootMult = 4.0, rarityBoost = 2.2, color = Color3.fromRGB(255, 181, 46), desc = "Виллы, бассейны и элитные башни." },
}

Config.UPGRADES = {
	{ id = "backpack", name = "Рюкзак побольше", desc = "+3 места в рюкзаке", base = 150, growth = 1.85, max = 10 },
	{ id = "shoes", name = "Беговые кроссовки", desc = "+8% к скорости", base = 120, growth = 1.7, max = 8 },
	{ id = "detector", name = "Сканер добычи", desc = "+40 к радиусу обнаружения", base = 250, growth = 1.9, max = 8 },
	{ id = "luck", name = "Талисман удачи", desc = "+ шанс редких находок", base = 400, growth = 2.0, max = 10 },
	{ id = "stamina", name = "Выносливость", desc = "+30% к запасу бега", base = 100, growth = 1.6, max = 6 },
	{ id = "trade", name = "Навык торговли", desc = "+6% к цене продажи", base = 300, growth = 1.95, max = 10 },
}
function Config.upgradeCost(u: any, lvl: number): number
	return math.floor(u.base * u.growth ^ lvl + 0.5)
end

Config.VEHICLES = {
	{ id = "scooter", name = "Самокат", cost = 600, speed = 1.6, desc = "Тихий и шустрый." },
	{ id = "bike", name = "Велосипед", cost = 2200, speed = 2.1, desc = "Классика городских улиц." },
	{ id = "moto", name = "Мотоцикл", cost = 14000, speed = 3.0, desc = "Рёв мотора и ветер в лицо." },
	{ id = "car", name = "Спорткар", cost = 65000, speed = 4.2, desc = "Быстрее всех в городе." },
}

Config.HOME_STAGES = {
	{ name = "Пустой участок", cost = 0, prestige = 0 },
	{ name = "Палатка", cost = 250, prestige = 1 },
	{ name = "Строительный вагончик", cost = 2500, prestige = 3 },
	{ name = "Кирпичный дом", cost = 16000, prestige = 8 },
	{ name = "Двухэтажный коттедж", cost = 70000, prestige = 20 },
	{ name = "Особняк", cost = 300000, prestige = 60 },
}

Config.DECOR = {
	{ id = "fence", name = "Деревянный забор", cost = 400, prestige = 1, needStage = 2 },
	{ id = "lamps", name = "Садовые фонари", cost = 700, prestige = 1, needStage = 2 },
	{ id = "garden", name = "Сад и деревья", cost = 1500, prestige = 2, needStage = 3 },
	{ id = "bench", name = "Беседка", cost = 3000, prestige = 3, needStage = 3 },
	{ id = "garage", name = "Гараж", cost = 9000, prestige = 5, needStage = 4 },
	{ id = "pool", name = "Бассейн", cost = 30000, prestige = 10, needStage = 5 },
	{ id = "fountain", name = "Фонтан", cost = 45000, prestige = 12, needStage = 5 },
	{ id = "statue", name = "Золотая статуя", cost = 120000, prestige = 25, needStage = 6 },
}

Config.BUSINESSES = {
	{ id = "vending", name = "Автомат с газировкой", cost = 900, income = 12, max = 5 },
	{ id = "laundry", name = "Прачечная", cost = 6000, income = 70, max = 5 },
	{ id = "carwash", name = "Автомойка", cost = 24000, income = 260, max = 5 },
	{ id = "parking", name = "Платная парковка", cost = 80000, income = 800, max = 5 },
	{ id = "market", name = "Мини-маркет", cost = 220000, income = 2100, max = 5 },
	{ id = "tower", name = "Бизнес-центр", cost = 900000, income = 8000, max = 3 },
}
function Config.businessCost(b: any, owned: number): number
	return math.floor(b.cost * 1.45 ^ owned + 0.5)
end

-- NPCs: id, name, role, icon, district, look (shirt/pants/skin colors), shop tabs
Config.NPCS = {
	{ id = "pawn", name = "Михалыч", role = "Скупщик · Ломбард", icon = "💰", d = 1, sign = "ЛОМБАРД", color = Color3.fromRGB(138, 28, 28),
		shirt = Color3.fromRGB(107, 74, 42), skin = Color3.fromRGB(216, 166, 136),
		greet = { "Чего притащил? Покажи, оценю по-честному… почти.", "Всё скупаю: от бутылок до бриллиантов." } },
	{ id = "gear", name = "Кирилл", role = "Магазин снаряжения", icon = "🎒", d = 1, sign = "СНАРЯЖЕНИЕ", color = Color3.fromRGB(28, 90, 138),
		shirt = Color3.fromRGB(28, 90, 138), skin = Color3.fromRGB(234, 184, 146),
		greet = { "Хороший рюкзак — половина успеха.", "Новый сканер ловит блеск за полквартала!" } },
	{ id = "garage", name = "Гоша", role = "Механик · Транспорт", icon = "🛵", d = 1, sign = "ТРАНСПОРТ", color = Color3.fromRGB(51, 51, 51),
		shirt = Color3.fromRGB(42, 58, 42), skin = Color3.fromRGB(196, 140, 105),
		greet = { "Пешком далеко не уйдёшь. Глянь мои колёса!", "Самокат, мотик… а есть и кое-что для серьёзных людей." } },
	{ id = "broker", name = "Аркадий", role = "Брокер · Бизнес", icon = "📈", d = 1, sign = "БИЗНЕС", color = Color3.fromRGB(28, 106, 58),
		shirt = Color3.fromRGB(32, 40, 56), skin = Color3.fromRGB(230, 180, 150),
		greet = { "Деньги должны работать, пока ты спишь.", "С автомата газировки начинали все магнаты." } },
	{ id = "mayor", name = "Пётр Ильич", role = "Мэрия · Пропуска в районы", icon = "🏛️", d = 1, sign = "МЭРИЯ", color = Color3.fromRGB(90, 74, 28),
		shirt = Color3.fromRGB(58, 58, 58), skin = Color3.fromRGB(226, 176, 146),
		greet = { "Проход в другие районы — только по пропуску.", "Город большой, но не бесплатный." } },
	{ id = "quest1", name = "Бабушка Зина", role = "Заказы Окраины", icon = "👵", d = 1, sign = "ЗАКАЗЫ", color = Color3.fromRGB(106, 44, 106),
		shirt = Color3.fromRGB(138, 58, 90), skin = Color3.fromRGB(230, 190, 160),
		greet = { "Внучок, помоги старушке, а я в долгу не останусь!" } },
	{ id = "foreman", name = "Степаныч", role = "Прораб · Ваш участок", icon = "🏗️", d = 1, sign = "СТРОЙКА", color = Color3.fromRGB(199, 122, 28),
		shirt = Color3.fromRGB(208, 138, 28), skin = Color3.fromRGB(200, 150, 115),
		greet = { "Построим что угодно, были бы деньги.", "Участок хороший. Тут бы особнячок…" } },
	{ id = "antiq", name = "Вера", role = "Антиквар · Центр", icon = "🏺", d = 2, sign = "АНТИКВАРИАТ", color = Color3.fromRGB(90, 28, 58),
		shirt = Color3.fromRGB(90, 28, 58), skin = Color3.fromRGB(240, 200, 170),
		greet = { "Редкие вещи — моя страсть. Плачу щедрее Михалыча.", "Есть у меня одна карта клада…" } },
	{ id = "quest2", name = "Детектив Лёва", role = "Заказы Центра", icon = "🕵️", d = 2, sign = "ДЕТЕКТИВ", color = Color3.fromRGB(58, 48, 32),
		shirt = Color3.fromRGB(74, 64, 48), skin = Color3.fromRGB(220, 170, 135),
		greet = { "Тсс… есть работёнка. Деликатная." } },
	{ id = "scrap", name = "Толик", role = "Металлобаза · Промзона", icon = "🔩", d = 3, sign = "МЕТАЛЛОБАЗА", color = Color3.fromRGB(74, 90, 106),
		shirt = Color3.fromRGB(74, 90, 106), skin = Color3.fromRGB(190, 140, 110),
		greet = { "Металл и хлам беру по лучшей цене!" } },
	{ id = "shadow", name = "Тень", role = "Чёрный рынок · только ночью", icon = "🌙", d = 3, sign = "ЧЁРНЫЙ РЫНОК", color = Color3.fromRGB(17, 17, 17), night = true,
		shirt = Color3.fromRGB(12, 12, 12), skin = Color3.fromRGB(160, 122, 96),
		greet = { "Вопросов не задаю. Плачу наличными." } },
	{ id = "jeweler", name = "Изабелла", role = "Ювелирный салон · Холмы", icon = "💎", d = 4, sign = "ЮВЕЛИР", color = Color3.fromRGB(192, 160, 64),
		shirt = Color3.fromRGB(240, 240, 240), skin = Color3.fromRGB(245, 205, 180),
		greet = { "Драгоценности и искусство — только лучшее." } },
	{ id = "quest4", name = "Леди Маргарита", role = "Заказы Холмов", icon = "👒", d = 4, sign = "ЗАКАЗЫ", color = Color3.fromRGB(122, 28, 42),
		shirt = Color3.fromRGB(122, 28, 42), skin = Color3.fromRGB(240, 205, 180),
		greet = { "Дорогуша, мне нужна помощь в одном изысканном деле." } },
}

-- ===== Map layout (studs) =====
Config.CELL = 180 -- block + road
Config.ROAD = 44 -- asphalt width between blocks
Config.SIDEWALK = 10
Config.CURB = 0.6
Config.N = 6 -- blocks per side
Config.HALF = Config.CELL * Config.N / 2 -- 540
Config.FLOOR = 12 -- storey height
Config.MARKET_BLOCK = { 2, 3 } -- Окраина, next to the central crossing
Config.PLOTS_BLOCK = { 2, 4 } -- 4 player home plots
Config.PLAZA_BLOCKS = { [2] = { 3, 3 }, [3] = { 2, 2 }, [4] = { 3, 2 } }

function Config.roadLine(k: number): number
	return -Config.HALF + k * Config.CELL
end
function Config.districtOf(x: number, z: number): number
	return (if x < 0 then 1 else 2) + (if z < 0 then 2 else 0)
end

Config.DAY_LENGTH = 720 -- seconds per in-game day
Config.START_MONEY = 20
Config.START_SLOTS = 6
Config.BASE_DETECT = 120 -- studs

return Config
]========])
	local server = Instance.new("Folder")
	server.Name = "LootCityServer"
	server.Parent = SSS
	local cityBuilder = script("ModuleScript", "CityBuilder", server, [========[
--!nonstrict
-- PROTOTYPE - NOT FOR PRODUCTION
-- Deterministic city planner + builder. Plan() is pure data (used every server start for
-- spawn points / NPC spots); Build() instantiates parts (run once from the installer or at runtime).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("LootCityShared"):WaitForChild("Config"))

local CityBuilder = {}

local CELL, ROAD, SIDE, CURB, N, HALF, FLOOR = Config.CELL, Config.ROAD, Config.SIDEWALK, Config.CURB, Config.N, Config.HALF, Config.FLOOR
local roadLine = Config.roadLine
local M = Enum.Material

local function mat(name: string, fallback: Enum.Material): Enum.Material
	local ok, v = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	return if ok and v then v else fallback
end
local PLASTER = mat("Plaster", M.Concrete)
local CARDBOARD = mat("Cardboard", M.Fabric)
local RUBBER = mat("Rubber", M.Fabric)
local ROOFTILES = mat("ClayRoofTiles", M.Slate)
CityBuilder.PLASTER, CityBuilder.CARDBOARD, CityBuilder.RUBBER, CityBuilder.ROOFTILES = PLASTER, CARDBOARD, RUBBER, ROOFTILES

local function snap(v, s)
	return math.max(s, math.floor(v / s + 0.5) * s)
end

-- ============ PLAN ============
function CityBuilder.Plan()
	local rng = Random.new(1337)
	local plan = {
		buildings = {}, garages = {}, containers = {}, trees = {}, dumpsters = {}, pools = {}, hedges = {},
		lamps = {}, cars = {}, lots = {}, spawns = { {}, {}, {}, {} }, npcSpots = {}, plots = {}, fountains = {},
	}
	local function spawn(d, x, z)
		table.insert(plan.spawns[d], Vector3.new(x, CURB, z))
	end
	local function sidewalkSpawns(bx0, bz0, bx1, bz1, d, n)
		for _ = 1, n do
			local side = rng:NextInteger(0, 3)
			local t = 10 + rng:NextNumber() * (bx1 - bx0 - 20)
			local o = 2 + rng:NextNumber() * (SIDE - 4)
			if side == 0 then spawn(d, bx0 + t, bz0 + o)
			elseif side == 1 then spawn(d, bx0 + t, bz1 - o)
			elseif side == 2 then spawn(d, bx0 + o, bz0 + t)
			else spawn(d, bx1 - o, bz0 + t) end
		end
	end
	local function building(x0, z0, w, d, floors, style)
		table.insert(plan.buildings, { x0 = x0, z0 = z0, w = w, d = d, floors = floors, style = style })
	end

	for i = 0, N - 1 do
		for j = 0, N - 1 do
			local bx0, bz0 = roadLine(i) + ROAD / 2, roadLine(j) + ROAD / 2
			local bx1, bz1 = roadLine(i + 1) - ROAD / 2, roadLine(j + 1) - ROAD / 2
			local cx, cz = (bx0 + bx1) / 2, (bz0 + bz1) / 2
			local dist = Config.districtOf(cx, cz)
			local ix0, iz0, ix1, iz1 = bx0 + SIDE, bz0 + SIDE, bx1 - SIDE, bz1 - SIDE
			local W = ix1 - ix0
			local ground = ({ "Ground", "Pavement", "Concrete", "Grass" })[dist]
			local lot = { x0 = ix0, z0 = iz0, x1 = ix1, z1 = iz1, ground = ground, d = dist }
			table.insert(plan.lots, lot)

			local isMarket = i == Config.MARKET_BLOCK[1] and j == Config.MARKET_BLOCK[2]
			local isPlots = i == Config.PLOTS_BLOCK[1] and j == Config.PLOTS_BLOCK[2]
			local plazaD = nil
			for dd, b in Config.PLAZA_BLOCKS do
				if b[1] == i and b[2] == j then plazaD = dd end
			end

			if isMarket then
				lot.ground = "Pavement"
				local spots = {
					{ "pawn", cx - 36, cz - 42, 0, 1 }, { "gear", cx, cz - 42, 0, 1 }, { "garage", cx + 36, cz - 42, 0, 1 },
					{ "broker", cx - 36, cz + 42, 0, -1 }, { "mayor", cx, cz + 42, 0, -1 }, { "quest1", cx + 36, cz + 42, 0, -1 },
					{ "foreman", cx + 44, cz, -1, 0 },
				}
				for _, s in spots do
					plan.npcSpots[s[1]] = { pos = Vector3.new(s[2], CURB, s[3]), face = Vector3.new(s[4], 0, s[5]) }
				end
				table.insert(plan.fountains, Vector3.new(cx, CURB, cz))
				table.insert(plan.trees, { cx - 50, cz - 50, 1.2 }); table.insert(plan.trees, { cx - 50, cz + 50, 1.2 })
				table.insert(plan.trees, { cx + 50, cz - 50, 1.2 }); table.insert(plan.trees, { cx + 50, cz + 50, 1.2 })
				plan.spawnPoint = Vector3.new(cx - 20, CURB, cz)
				sidewalkSpawns(bx0, bz0, bx1, bz1, dist, 4)
			elseif isPlots then
				lot.ground = "Grass"
				local pw = (W - 8) / 2
				for a = 0, 1 do
					for b = 0, 1 do
						local px0 = ix0 + a * (pw + 8)
						local pz0 = iz0 + b * (pw + 8)
						-- plots face the street on their outer z side
						local front = if b == 0 then -1 else 1
						table.insert(plan.plots, { x0 = px0, z0 = pz0, x1 = px0 + pw, z1 = pz0 + pw, front = front })
					end
				end
				sidewalkSpawns(bx0, bz0, bx1, bz1, dist, 4)
			elseif plazaD then
				lot.ground = "Pavement"
				local ids = ({ [2] = { "antiq", "quest2" }, [3] = { "scrap", "shadow" }, [4] = { "jeweler", "quest4" } })[plazaD]
				plan.npcSpots[ids[1]] = { pos = Vector3.new(cx - 34, CURB, cz), face = Vector3.new(1, 0, 0) }
				plan.npcSpots[ids[2]] = { pos = Vector3.new(cx + 34, CURB, cz), face = Vector3.new(-1, 0, 0) }
				for _, t in { { -48, -48 }, { 48, -48 }, { -48, 48 }, { 48, 48 }, { 0, -48 }, { 0, 48 } } do
					table.insert(plan.trees, { cx + t[1], cz + t[2], 1.2 })
				end
				for _ = 1, 4 do spawn(dist, cx + rng:NextNumber(-20, 20), cz + rng:NextNumber(-40, 40)) end
				sidewalkSpawns(bx0, bz0, bx1, bz1, dist, 3)
			else
				sidewalkSpawns(bx0, bz0, bx1, bz1, dist, 7)
				if dist == 1 then
					local sw = W / 2
					for a = 0, 1 do
						for b = 0, 1 do
							local sx0, sz0 = ix0 + a * sw, iz0 + b * sw
							local roll = rng:NextNumber()
							if roll < 0.62 then
								local w, d = snap(rng:NextNumber(30, 46), 10), snap(rng:NextNumber(30, 46), 10)
								local fl = rng:NextInteger(2, 5)
								local x = if a == 0 then sx0 + 2 else sx0 + sw - w - 2
								local z = if b == 0 then sz0 + 2 else sz0 + sw - d - 2
								local styles = { "brick", "brick2", "plaster", "plaster2" }
								building(x, z, w, d, fl, styles[rng:NextInteger(1, 4)])
								local yx = if a == 0 then x + w + 5 else x - 5
								spawn(1, yx, z + d / 2)
								table.insert(plan.dumpsters, { if a == 0 then x + w + 4 else x - 10, if b == 0 then z + d + 3 else z - 8 })
							elseif roll < 0.82 then
								table.insert(plan.garages, { sx0 + 4, sz0 + 4, 5 })
								for _ = 1, 3 do spawn(1, sx0 + rng:NextNumber(8, sw - 8), sz0 + rng:NextNumber(24, sw - 6)) end
							else
								for _ = 1, 4 do spawn(1, sx0 + rng:NextNumber(6, sw - 6), sz0 + rng:NextNumber(6, sw - 6)) end
								table.insert(plan.trees, { sx0 + sw / 2 + rng:NextNumber(-10, 10), sz0 + sw / 2 + rng:NextNumber(-10, 10), 1 })
							end
						end
					end
				elseif dist == 2 then
					if rng:NextNumber() < 0.5 then
						local w, d = snap(rng:NextNumber(60, 84), 10), snap(rng:NextNumber(60, 84), 10)
						building(ix0 + (W - w) / 2, iz0 + (W - d) / 2, w, d, rng:NextInteger(12, 30), if rng:NextNumber() < 0.5 then "glass" else "darkglass")
						for _ = 1, 3 do spawn(2, ix0 + rng:NextNumber(4, 12), iz0 + rng:NextNumber(10, W - 10)) end
					else
						for a = 0, 1 do
							local w, d = snap(rng:NextNumber(40, 48), 10), snap(rng:NextNumber(80, 100), 10)
							local x = if a == 0 then ix0 + 2 else ix1 - w - 2
							local styles = { "glass", "darkglass", "plaster" }
							building(x, iz0 + (W - d) / 2, w, d, rng:NextInteger(6, 20), styles[rng:NextInteger(1, 3)])
						end
						for _ = 1, 4 do spawn(2, ix0 + W / 2 + rng:NextNumber(-8, 8), iz0 + rng:NextNumber(10, W - 10)) end
						table.insert(plan.trees, { ix0 + W / 2, iz0 + 14, 1.1 }); table.insert(plan.trees, { ix0 + W / 2, iz1 - 14, 1.1 })
					end
				elseif dist == 3 then
					if rng:NextNumber() < 0.6 then
						local w, d = snap(rng:NextNumber(90, 110), 10), snap(rng:NextNumber(50, 64), 10)
						building(ix0 + 2, iz0 + 2, w, d, 2, if rng:NextNumber() < 0.5 then "metal" else "metal2")
						for k = 0, 5 do
							local cxx, czz = ix0 + 10 + k * 17, iz1 - 22
							table.insert(plan.containers, { cxx, czz, rng:NextInteger(1, 3), rng:NextInteger(1, 6) })
						end
						for _ = 1, 6 do spawn(3, ix0 + rng:NextNumber(6, W - 6), iz0 + d + rng:NextNumber(6, 22)) end
					else
						for a = 0, 1 do
							local x = if a == 0 then ix0 + 2 else ix1 - 46
							building(x, iz0 + 4, 44, 106, 2, if a == 0 then "metal" else "metal2")
						end
						for _ = 1, 5 do spawn(3, ix0 + W / 2 + rng:NextNumber(-6, 6), iz0 + rng:NextNumber(8, W - 8)) end
						table.insert(plan.dumpsters, { ix0 + W / 2 - 4, iz0 + 14 }); table.insert(plan.dumpsters, { ix0 + W / 2 - 4, iz1 - 20 })
					end
				else
					if rng:NextNumber() < 0.25 then
						building(ix0 + (W - 60) / 2, iz0 + (W - 60) / 2, 60, 60, rng:NextInteger(18, 36), "darkglass")
						for _, t in { { 8, 8 }, { W - 8, 8 }, { 8, W - 8 }, { W - 8, W - 8 } } do
							table.insert(plan.trees, { ix0 + t[1], iz0 + t[2], 1.3 })
						end
						for _ = 1, 4 do spawn(4, ix0 + rng:NextNumber(4, 14), iz0 + rng:NextNumber(20, W - 20)) end
					else
						local sw = W / 2
						for a = 0, 1 do
							local sx0 = ix0 + a * sw
							local w, d = snap(rng:NextNumber(36, 44), 10), snap(rng:NextNumber(30, 38), 10)
							building(sx0 + (sw - w) / 2, iz0 + 6, w, d, rng:NextInteger(2, 3), "villa")
							local pz = iz0 + d + 16
							table.insert(plan.pools, { sx0 + 8, pz, sw - 16, 18 })
							table.insert(plan.hedges, { sx0 + 1, iz1 - 4, sw - 2, 3 })
							table.insert(plan.trees, { sx0 + 6, iz0 + 6, 1.2 }); table.insert(plan.trees, { sx0 + sw - 6, iz1 - 12, 1.2 })
							for _ = 1, 3 do spawn(4, sx0 + rng:NextNumber(4, sw - 4), pz + rng:NextNumber(21, 28)) end
						end
					end
				end
			end
			-- sidewalk trees in center & hills
			if dist == 2 or dist == 4 then
				local t = bx0 + 16
				while t < bx1 - 10 do
					table.insert(plan.trees, { t, bz0 + 4, 1 })
					t += 34
				end
			end
		end
	end

	-- street lamps and parked cars along every road segment
	for k = 0, N do
		local c = roadLine(k)
		for s = 0, N - 1 do
			local a, b = roadLine(s) + ROAD / 2 + 14, roadLine(s + 1) - ROAD / 2 - 14
			local t = a
			while t <= b do
				table.insert(plan.lamps, { c + ROAD / 2 + 2, t, Vector3.new(-1, 0, 0) })
				table.insert(plan.lamps, { c - ROAD / 2 - 2, t + 30, Vector3.new(1, 0, 0) })
				table.insert(plan.lamps, { t, c + ROAD / 2 + 2, Vector3.new(0, 0, -1) })
				table.insert(plan.lamps, { t + 30, c - ROAD / 2 - 2, Vector3.new(0, 0, 1) })
				t += 60
			end
			t = a + 6
			while t < b do
				if k ~= N / 2 then
					if rng:NextNumber() < 0.2 then table.insert(plan.cars, { c + 17, t, Vector3.new(0, 0, -1) }) end
					if rng:NextNumber() < 0.2 then table.insert(plan.cars, { c - 17, t, Vector3.new(0, 0, 1) }) end
					if rng:NextNumber() < 0.2 then table.insert(plan.cars, { t, c + 17, Vector3.new(1, 0, 0) }) end
					if rng:NextNumber() < 0.2 then table.insert(plan.cars, { t, c - 17, Vector3.new(-1, 0, 0) }) end
				end
				t += 20
			end
		end
	end
	return plan
end

-- ============ BUILD ============
local function P(parent: Instance, size: Vector3, cf: CFrame, material: Enum.Material, color: Color3, props: { [string]: any }?): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Material = material
	p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props then
		for k, v in props do
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end
CityBuilder.P = P

local function box(parent, x0, y0, z0, x1, y1, z1, material, color, props)
	return P(parent, Vector3.new(x1 - x0, y1 - y0, z1 - z0), CFrame.new((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2), material, color, props)
end
CityBuilder.box = box

local function cyl(parent, radius, height, cf, material, color, props)
	-- Roblox cylinders are along X; rotate so axis is Y
	return P(parent, Vector3.new(height, radius * 2, radius * 2), cf * CFrame.Angles(0, 0, math.rad(90)), material, color, (function()
		local t = props or {}
		t.Shape = Enum.PartType.Cylinder
		return t
	end)())
end
CityBuilder.cyl = cyl

local STYLE = {
	brick = { mat = M.Brick, color = Color3.fromRGB(140, 70, 52), win = "small" },
	brick2 = { mat = M.Brick, color = Color3.fromRGB(112, 88, 74), win = "small" },
	plaster = { mat = PLASTER, color = Color3.fromRGB(206, 188, 152), win = "small" },
	plaster2 = { mat = PLASTER, color = Color3.fromRGB(170, 180, 175), win = "small" },
	glass = { mat = M.Glass, color = Color3.fromRGB(70, 110, 140), win = "curtain" },
	darkglass = { mat = M.Glass, color = Color3.fromRGB(34, 42, 52), win = "curtain" },
	metal = { mat = M.CorrodedMetal, color = Color3.fromRGB(140, 150, 156), win = "strip" },
	metal2 = { mat = M.Metal, color = Color3.fromRGB(78, 108, 128), win = "strip" },
	villa = { mat = PLASTER, color = Color3.fromRGB(238, 234, 226), win = "big" },
}

local GLASS = Color3.fromRGB(30, 40, 48)
local function window(parent, cf, w, h)
	local p = P(parent, Vector3.new(w, h, 0.4), cf, M.Glass, GLASS, { Reflectance = 0.25, CastShadow = false })
	p:AddTag("LC_Window")
	return p
end

function CityBuilder.Building(parent: Instance, b)
	local st = STYLE[b.style]
	local model = Instance.new("Model")
	model.Name = "Building"
	local x0, z0, w, d = b.x0, b.z0, b.w, b.d
	local h = b.floors * FLOOR + 2
	local cx, cz = x0 + w / 2, z0 + d / 2
	local y0 = CURB
	-- plinth
	box(model, x0 - 0.4, y0, z0 - 0.4, x0 + w + 0.4, y0 + 2, z0 + d + 0.4, M.Concrete, Color3.fromRGB(110, 108, 104))
	if st.win == "curtain" then
		local glass = box(model, x0 + 0.5, y0 + 2, z0 + 0.5, x0 + w - 0.5, y0 + h, z0 + d - 0.5, M.Glass, st.color, { Reflectance = 0.32, Transparency = 0.18 })
		glass.CastShadow = true
		local core = box(model, x0 + 3, y0 + 2, z0 + 3, x0 + w - 3, y0 + h - 1, z0 + d - 3, M.SmoothPlastic, Color3.fromRGB(26, 28, 32), { CastShadow = false })
		core:AddTag("LC_TowerCore")
		for f = 1, b.floors do
			local y = y0 + 2 + f * FLOOR
			box(model, x0, y - 1.2, z0, x0 + w, y, z0 + d, M.Concrete, Color3.fromRGB(62, 64, 68), { CastShadow = false })
		end
		-- vertical fins every 10 studs
		local fx = x0 + 10
		while fx < x0 + w - 2 do
			box(model, fx - 0.3, y0 + 2, z0 - 0.4, fx + 0.3, y0 + h, z0 + 0.6, M.Metal, Color3.fromRGB(150, 155, 160), { CastShadow = false })
			box(model, fx - 0.3, y0 + 2, z0 + d - 0.6, fx + 0.3, y0 + h, z0 + d + 0.4, M.Metal, Color3.fromRGB(150, 155, 160), { CastShadow = false })
			fx += 10
		end
		-- lobby
		box(model, cx - 10, y0, z0 - 6, cx + 10, y0 + 0.6, z0, M.Marble, Color3.fromRGB(220, 220, 215))
		box(model, cx - 12, y0 + 9, z0 - 7, cx + 12, y0 + 10, z0, M.Metal, Color3.fromRGB(60, 62, 66))
	else
		box(model, x0, y0 + 2, z0, x0 + w, y0 + h, z0 + d, st.mat, st.color)
		local spacing = if st.win == "big" then 12 else 10
		local ww = if st.win == "big" then 8 elseif st.win == "strip" then 7 else 4.6
		local wh = if st.win == "big" then 8 elseif st.win == "strip" then 2.5 else 6
		local yOff = if st.win == "strip" then 9 else 5.5
		local floors = if st.win == "strip" then 1 else b.floors
		for f = 0, floors - 1 do
			local y = y0 + 2 + f * FLOOR + yOff
			-- ledge per floor
			if st.win == "small" and f > 0 then
				box(model, x0 - 0.5, y - yOff - 0.4, z0 - 0.5, x0 + w + 0.5, y - yOff + 0.4, z0 + d + 0.5, M.Concrete, Color3.fromRGB(190, 185, 175), { CastShadow = false })
			end
			-- front/back
			local n = math.floor(w / spacing)
			local start = x0 + (w - (n - 1) * spacing) / 2
			for k = 0, n - 1 do
				local x = start + k * spacing
				window(model, CFrame.new(x, y, z0 - 0.1), ww, wh)
				window(model, CFrame.new(x, y, z0 + d + 0.1), ww, wh)
			end
			n = math.floor(d / spacing)
			start = z0 + (d - (n - 1) * spacing) / 2
			for k = 0, n - 1 do
				local z = start + k * spacing
				window(model, CFrame.new(x0 - 0.1, y, z) * CFrame.Angles(0, math.rad(90), 0), ww, wh)
				window(model, CFrame.new(x0 + w + 0.1, y, z) * CFrame.Angles(0, math.rad(90), 0), ww, wh)
			end
		end
		-- door
		box(model, cx - 3, y0, z0 - 0.3, cx + 3, y0 + 8, z0 + 0.2, M.Wood, Color3.fromRGB(70, 46, 30))
		if st.win == "strip" then
			box(model, cx - 14, y0, z0 - 0.3, cx + 14, y0 + 16, z0 + 0.2, M.DiamondPlate, Color3.fromRGB(120, 124, 128))
		end
	end
	-- roof parapet + rooftop units
	local top = y0 + h
	local pc = Color3.fromRGB(120, 118, 112)
	box(model, x0 - 0.3, top, z0 - 0.3, x0 + w + 0.3, top + 2.5, z0 + 0.7, M.Concrete, pc)
	box(model, x0 - 0.3, top, z0 + d - 0.7, x0 + w + 0.3, top + 2.5, z0 + d + 0.3, M.Concrete, pc)
	box(model, x0 - 0.3, top, z0 + 0.7, x0 + 0.7, top + 2.5, z0 + d - 0.7, M.Concrete, pc)
	box(model, x0 + w - 0.7, top, z0 + 0.7, x0 + w + 0.3, top + 2.5, z0 + d - 0.7, M.Concrete, pc)
	box(model, x0 + 0.7, top - 0.2, z0 + 0.7, x0 + w - 0.7, top + 0.2, z0 + d - 0.7, M.Asphalt, Color3.fromRGB(60, 60, 62))
	local r = Random.new(math.floor(x0 * 13 + z0 * 7))
	for _ = 1, r:NextInteger(1, 3) do
		local uw, ud = r:NextNumber(5, 10), r:NextNumber(5, 9)
		local ux, uz = x0 + 3 + r:NextNumber() * math.max(0.1, w - uw - 6), z0 + 3 + r:NextNumber() * math.max(0.1, d - ud - 6)
		box(model, ux, top, uz, ux + uw, top + r:NextNumber(3, 6), uz + ud, M.Metal, Color3.fromRGB(150, 152, 150))
	end
	model.Parent = parent
	return model
end

local function lamp(parent, x, z, face: Vector3)
	local m = Instance.new("Model")
	m.Name = "Lamp"
	local base = CFrame.lookAt(Vector3.new(x, CURB, z), Vector3.new(x, CURB, z) + face)
	cyl(m, 0.7, 2, base * CFrame.new(0, 1, 0), M.Metal, Color3.fromRGB(35, 37, 40))
	cyl(m, 0.35, 24, base * CFrame.new(0, 12, 0), M.Metal, Color3.fromRGB(35, 37, 40))
	P(m, Vector3.new(0.5, 0.5, 7), base * CFrame.new(0, 23.7, -3.3), M.Metal, Color3.fromRGB(35, 37, 40))
	P(m, Vector3.new(2.4, 0.6, 3.4), base * CFrame.new(0, 23.6, -7.2), M.Metal, Color3.fromRGB(35, 37, 40))
	local bulb = P(m, Vector3.new(2, 0.2, 2.8), base * CFrame.new(0, 23.2, -7.2), M.SmoothPlastic, Color3.fromRGB(255, 236, 200), { CastShadow = false })
	bulb:AddTag("LC_LampBulb")
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Bottom
	light.Angle = 120
	light.Range = 48
	light.Brightness = 3
	light.Color = Color3.fromRGB(255, 205, 150)
	light.Shadows = false
	light.Enabled = false
	light.Parent = bulb
	m.Parent = parent
end

local function tree(parent, x, z, s, r: Random)
	local m = Instance.new("Model")
	m.Name = "Tree"
	local trunkH = 14 * s
	cyl(m, 0.9 * s, trunkH, CFrame.new(x, CURB + trunkH / 2, z), M.Wood, Color3.fromRGB(78, 60, 44))
	local leafColor = Color3.fromHSV(0.24 + r:NextNumber() * 0.06, 0.55, 0.38 + r:NextNumber() * 0.12)
	for _ = 1, 5 do
		local rad = (5 + r:NextNumber() * 4) * s
		local off = Vector3.new(r:NextNumber(-4, 4) * s, trunkH + r:NextNumber(-1, 5) * s, r:NextNumber(-4, 4) * s)
		P(m, Vector3.one * rad * 2, CFrame.new(Vector3.new(x, CURB, z) + off), M.LeafyGrass, leafColor, { Shape = Enum.PartType.Ball, CastShadow = true })
	end
	m.Parent = parent
end

function CityBuilder.Car(parent, cf: CFrame, color: Color3)
	local m = Instance.new("Model")
	m.Name = "Car"
	P(m, Vector3.new(7, 2.6, 15.5), cf * CFrame.new(0, 2.4, 0), M.SmoothPlastic, color, { Reflectance = 0.18 })
	P(m, Vector3.new(6.4, 2.6, 8), cf * CFrame.new(0, 4.9, 0.8), M.Glass, Color3.fromRGB(20, 26, 32), { Reflectance = 0.3 })
	P(m, Vector3.new(6.5, 0.4, 7), cf * CFrame.new(0, 6.3, 0.9), M.SmoothPlastic, color, { Reflectance = 0.18 })
	for _, o in { { 3.3, 5 }, { -3.3, 5 }, { 3.3, -5 }, { -3.3, -5 } } do
		P(m, Vector3.new(1.2, 3, 3), cf * CFrame.new(o[1], 1.5, o[2]) * CFrame.Angles(0, 0, 0), RUBBER, Color3.fromRGB(20, 20, 20), { Shape = Enum.PartType.Cylinder })
		P(m, Vector3.new(1.3, 1.8, 1.8), cf * CFrame.new(o[1], 1.5, o[2]), M.Metal, Color3.fromRGB(190, 192, 196), { Shape = Enum.PartType.Cylinder })
	end
	local hl = P(m, Vector3.new(5.6, 0.6, 0.2), cf * CFrame.new(0, 3, -7.8), M.Neon, Color3.fromRGB(255, 244, 220), { CastShadow = false })
	hl:AddTag("LC_Headlight")
	P(m, Vector3.new(5.6, 0.6, 0.2), cf * CFrame.new(0, 3.2, 7.8), M.Neon, Color3.fromRGB(200, 20, 20), { CastShadow = false })
	m.Parent = parent
	return m
end

function CityBuilder.Kiosk(parent, pos: Vector3, face: Vector3, sign: string, color: Color3)
	local m = Instance.new("Model")
	m.Name = "Kiosk_" .. sign
	local base = CFrame.lookAt(pos, pos + face)
	-- counter at local -z (front), NPC stands behind it
	P(m, Vector3.new(14, 3.6, 3), base * CFrame.new(0, 1.8, -3), M.Wood, Color3.fromRGB(120, 82, 52))
	P(m, Vector3.new(14.6, 0.3, 3.6), base * CFrame.new(0, 3.75, -3), M.Marble, Color3.fromRGB(60, 60, 64))
	P(m, Vector3.new(14, 11, 0.6), base * CFrame.new(0, 5.5, 4), M.Wood, Color3.fromRGB(100, 70, 46))
	for _, x in { -6.8, 6.8 } do
		P(m, Vector3.new(0.5, 11, 0.5), base * CFrame.new(x, 5.5, -4.2), M.Metal, Color3.fromRGB(40, 40, 44))
	end
	local awn = P(m, Vector3.new(15.5, 0.3, 10), base * CFrame.new(0, 11.4, -0.4) * CFrame.Angles(math.rad(-12), 0, 0), M.Fabric, color)
	awn.CastShadow = true
	local signPart = P(m, Vector3.new(13, 2.6, 0.4), base * CFrame.new(0, 13.4, -4.6), M.SmoothPlastic, Color3.fromRGB(20, 20, 22))
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(520, 104)
	sg.LightInfluence = 0
	sg.Brightness = 1.6
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Text = sign
	tl.TextColor3 = Color3.fromRGB(255, 224, 138)
	tl.Font = Enum.Font.GothamBlack
	tl.TextScaled = true
	tl.Parent = sg
	sg.Parent = signPart
	-- SurfaceGui Front face = -Z of the part, which already looks out of the kiosk
	m.Parent = parent
	return m
end

function CityBuilder.Bench(parent, cf: CFrame)
	local m = Instance.new("Model")
	m.Name = "Bench"
	for k = 0, 3 do
		P(m, Vector3.new(7, 0.25, 0.5), cf * CFrame.new(0, 1.7, -0.9 + k * 0.6), M.Wood, Color3.fromRGB(130, 90, 58))
	end
	P(m, Vector3.new(7, 1.4, 0.25), cf * CFrame.new(0, 2.8, 1.1), M.Wood, Color3.fromRGB(130, 90, 58))
	for _, x in { -3, 3 } do
		P(m, Vector3.new(0.3, 1.7, 2.6), cf * CFrame.new(x, 0.85, 0), M.Metal, Color3.fromRGB(30, 30, 32))
	end
	m.Parent = parent
	return m
end

function CityBuilder.Build(plan)
	local old = workspace:FindFirstChild("LootCityMap")
	if old then old:Destroy() end
	local root = Instance.new("Folder")
	root.Name = "LootCityMap"
	local f = function(name)
		local x = Instance.new("Folder")
		x.Name = name
		x.Parent = root
		return x
	end
	local fGround, fBuild, fProps, fLamps, fBarriers = f("Ground"), f("Buildings"), f("Props"), f("Lamps"), f("Barriers")
	local r = Random.new(42)

	-- terrain around the city
	local terrain = workspace.Terrain
	terrain:Clear()
	terrain:FillBlock(CFrame.new(0, -6, 0), Vector3.new(3600, 12, 3600), M.Grass)
	for k = 1, 24 do
		local a = k / 24 * math.pi * 2
		local dd = 1250 + r:NextNumber() * 300
		terrain:FillBall(Vector3.new(math.cos(a) * dd, -60, math.sin(a) * dd), 220 + r:NextNumber() * 160, M.Grass)
	end
	-- asphalt base under the whole city
	P(fGround, Vector3.new(HALF * 2 + ROAD + 40, 2, HALF * 2 + ROAD + 40), CFrame.new(0, -1, 0), M.Asphalt, Color3.fromRGB(58, 58, 60)):AddTag("LC_Road")
	-- lots
	for _, lot in plan.lots do
		local bx0, bz0, bx1, bz1 = lot.x0 - SIDE, lot.z0 - SIDE, lot.x1 + SIDE, lot.z1 + SIDE
		box(fGround, bx0, 0, bz0, bx1, CURB, bz1, M.Pavement, Color3.fromRGB(150, 148, 142)):AddTag("LC_Sidewalk")
		box(fGround, bx0 - 0.3, 0, bz0 - 0.3, bx1 + 0.3, CURB - 0.05, bz1 + 0.3, M.Concrete, Color3.fromRGB(175, 172, 165))
		local gm = (M :: any)[lot.ground]
		local gc = ({ Ground = Color3.fromRGB(110, 92, 70), Pavement = Color3.fromRGB(165, 160, 152), Concrete = Color3.fromRGB(130, 130, 128), Grass = Color3.fromRGB(78, 110, 52) })[lot.ground]
		box(fGround, lot.x0, CURB, lot.z0, lot.x1, CURB + 0.05, lot.z1, gm, gc)
	end
	-- road markings
	local mark = Color3.fromRGB(220, 200, 90)
	for k = 0, N do
		local c = roadLine(k)
		for s = 0, N - 1 do
			local a, b = roadLine(s) + ROAD / 2 + 6, roadLine(s + 1) - ROAD / 2 - 6
			local t = a
			while t < b - 8 do
				if k ~= N / 2 then
					box(fGround, c - 0.25, 0, t, c + 0.25, 0.04, t + 8, M.SmoothPlastic, mark, { CastShadow = false, CanCollide = false })
					box(fGround, t, 0, c - 0.25, t + 8, 0.04, c + 0.25, M.SmoothPlastic, mark, { CastShadow = false, CanCollide = false })
				end
				t += 16
			end
		end
		for kk = 0, N do
			local x, z = roadLine(k), roadLine(kk)
			for q = -4, 4 do
				local o = q * 3.8
				box(fGround, x + o - 0.9, 0, z + ROAD / 2 - 6, x + o + 0.9, 0.04, z + ROAD / 2 - 1, M.SmoothPlastic, Color3.fromRGB(225, 225, 220), { CastShadow = false, CanCollide = false })
				box(fGround, x + o - 0.9, 0, z - ROAD / 2 + 1, x + o + 0.9, 0.04, z - ROAD / 2 + 6, M.SmoothPlastic, Color3.fromRGB(225, 225, 220), { CastShadow = false, CanCollide = false })
				box(fGround, x + ROAD / 2 - 6, 0, z + o - 0.9, x + ROAD / 2 - 1, 0.04, z + o + 0.9, M.SmoothPlastic, Color3.fromRGB(225, 225, 220), { CastShadow = false, CanCollide = false })
				box(fGround, x - ROAD / 2 + 1, 0, z + o - 0.9, x - ROAD / 2 + 6, 0.04, z + o + 0.9, M.SmoothPlastic, Color3.fromRGB(225, 225, 220), { CastShadow = false, CanCollide = false })
			end
		end
	end
	-- buildings
	for _, b in plan.buildings do
		CityBuilder.Building(fBuild, b)
	end
	-- garages
	for _, g in plan.garages do
		local x0, z0, n = g[1], g[2], g[3]
		for k = 0, n - 1 do
			local gx = x0 + k * 10
			box(fBuild, gx, CURB, z0, gx + 9.8, CURB + 9, z0 + 18, M.CorrodedMetal, Color3.fromRGB(120 + r:NextInteger(-20, 20), 110, 100))
			box(fBuild, gx + 1, CURB, z0 + 17.9, gx + 8.8, CURB + 7.5, z0 + 18.2, M.DiamondPlate, Color3.fromRGB(90, 96, 100))
		end
	end
	-- containers
	local ccol = { Color3.fromRGB(181, 68, 44), Color3.fromRGB(43, 93, 140), Color3.fromRGB(45, 107, 59), Color3.fromRGB(199, 146, 46), Color3.fromRGB(107, 111, 115), Color3.fromRGB(140, 43, 43) }
	for _, c in plan.containers do
		for s = 0, c[3] - 1 do
			P(fProps, Vector3.new(8.6, 9, 20), CFrame.new(c[1], CURB + 4.5 + s * 9, c[2]) * CFrame.Angles(0, math.rad(r:NextNumber(-2, 2)), 0), M.CorrodedMetal, ccol[((c[4] + s) % 6) + 1])
		end
	end
	-- dumpsters
	for _, dpos in plan.dumpsters do
		local cf = CFrame.new(dpos[1] + 3, CURB, dpos[2] + 2)
		P(fProps, Vector3.new(7, 4.2, 4.2), cf * CFrame.new(0, 2.1, 0), M.Metal, Color3.fromRGB(44, 90, 52))
		P(fProps, Vector3.new(7.2, 0.3, 4.6), cf * CFrame.new(0, 4.4, 0) * CFrame.Angles(math.rad(-6), 0, 0), M.Plastic, Color3.fromRGB(25, 25, 25))
	end
	-- pools & hedges
	for _, pl in plan.pools do
		box(fProps, pl[1] - 1.5, CURB, pl[2] - 1.5, pl[1] + pl[3] + 1.5, CURB + 1, pl[2] + pl[4] + 1.5, M.Marble, Color3.fromRGB(230, 228, 222))
		local w = box(fProps, pl[1], CURB + 1, pl[2], pl[1] + pl[3], CURB + 1.05, pl[2] + pl[4], M.Glass, Color3.fromRGB(40, 150, 190), { Reflectance = 0.3, Transparency = 0.1, CanCollide = false })
		w:AddTag("LC_Water")
	end
	for _, hg in plan.hedges do
		box(fProps, hg[1], CURB, hg[2], hg[1] + hg[3], CURB + 5, hg[2] + hg[4], M.LeafyGrass, Color3.fromRGB(52, 82, 38))
	end
	-- fountains
	for _, fp in plan.fountains do
		cyl(fProps, 13, 2, CFrame.new(fp + Vector3.new(0, 1, 0)), M.Marble, Color3.fromRGB(215, 212, 205))
		cyl(fProps, 12, 0.2, CFrame.new(fp + Vector3.new(0, 2.05, 0)), M.Glass, Color3.fromRGB(40, 130, 170), { Reflectance = 0.3, Transparency = 0.15 })
		cyl(fProps, 1.6, 8, CFrame.new(fp + Vector3.new(0, 4, 0)), M.Marble, Color3.fromRGB(215, 212, 205))
		local bowl = cyl(fProps, 5, 1.2, CFrame.new(fp + Vector3.new(0, 8.4, 0)), M.Marble, Color3.fromRGB(215, 212, 205))
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
		pe.Size = NumberSequence.new(0.6, 1.4)
		pe.Lifetime = NumberRange.new(1, 1.4)
		pe.Rate = 80
		pe.Speed = NumberRange.new(10, 14)
		pe.SpreadAngle = Vector2.new(12, 12)
		pe.Acceleration = Vector3.new(0, -30, 0)
		pe.EmissionDirection = Enum.NormalId.Right -- cylinder X axis points up after rotation
		pe.Parent = bowl
		for _, o in { -18, 18 } do
			CityBuilder.Bench(fProps, CFrame.lookAt(fp + Vector3.new(o, 0, 0), fp))
		end
	end
	-- lamps
	for _, l in plan.lamps do
		lamp(fLamps, l[1], l[2], l[3])
	end
	-- trees
	for _, t in plan.trees do
		tree(fProps, t[1], t[2], t[3], r)
	end
	-- parked cars
	local palette = { Color3.fromRGB(242, 242, 242), Color3.fromRGB(17, 17, 17), Color3.fromRGB(138, 143, 150), Color3.fromRGB(90, 13, 13), Color3.fromRGB(14, 42, 85), Color3.fromRGB(200, 200, 200), Color3.fromRGB(176, 24, 24), Color3.fromRGB(30, 77, 43) }
	local fCars = f("ParkedCars")
	for _, c in plan.cars do
		local pos = Vector3.new(c[1], 0, c[2])
		CityBuilder.Car(fCars, CFrame.lookAt(pos, pos + c[3]), palette[r:NextInteger(1, #palette)])
	end
	-- district barriers on the two boundary roads (x = 0 and z = 0)
	local function barrierLine(along: string, from: number, to: number, a: number, b: number)
		local m = Instance.new("Model")
		m.Name = "Barrier"
		m:SetAttribute("A", a)
		m:SetAttribute("B", b)
		local t = from
		while t < to do
			local cf = if along == "z" then CFrame.new(0, 0, t + 5) else CFrame.new(t + 5, 0, 0) * CFrame.Angles(0, math.rad(90), 0)
			P(m, Vector3.new(2.2, 3.4, 9.8), cf * CFrame.new(0, 1.7, 0), M.Concrete, Color3.fromRGB(230, 226, 218))
			P(m, Vector3.new(2.3, 0.6, 9.9), cf * CFrame.new(0, 3.6, 0), M.SmoothPlastic, Color3.fromRGB(205, 40, 30))
			t += 10
		end
		-- tall invisible wall so it cannot be jumped
		local len = to - from
		local wall = if along == "z" then box(m, -1, 0, from, 1, 60, to, M.ForceField, Color3.fromRGB(255, 60, 60)) else box(m, from, 0, -1, to, 60, 1, M.ForceField, Color3.fromRGB(255, 60, 60))
		wall.Transparency = 0.85
		wall.CastShadow = false
		wall.Name = "Wall"
		local _ = len
		m.Parent = fBarriers
	end
	barrierLine("z", 0, HALF + 30, 1, 2)
	barrierLine("z", -HALF - 30, 0, 3, 4)
	barrierLine("x", -HALF - 30, 0, 1, 3)
	barrierLine("x", 0, HALF + 30, 2, 4)
	-- world border
	for _, s in { { HALF + 34, 0, 2, HALF * 2 + 80 }, { -HALF - 34, 0, 2, HALF * 2 + 80 }, { 0, HALF + 34, HALF * 2 + 80, 2 }, { 0, -HALF - 34, HALF * 2 + 80, 2 } } do
		P(root, Vector3.new(s[3], 120, s[4]), CFrame.new(s[1], 60, s[2]), M.SmoothPlastic, Color3.new(1, 1, 1), { Transparency = 1, CastShadow = false })
	end
	-- distant skyline beyond the border
	local sk = f("Skyline")
	for k = 1, 60 do
		local a = k / 60 * math.pi * 2 + r:NextNumber() * 0.05
		local dd = HALF + 120 + r:NextNumber() * 260
		local hgt = 40 + r:NextNumber() * (if math.cos(a) > 0 then 260 else 90)
		local w = 50 + r:NextNumber() * 50
		local p = P(sk, Vector3.new(w, hgt, w), CFrame.new(math.cos(a) * dd, hgt / 2, math.sin(a) * dd), if r:NextNumber() < 0.5 then M.Glass else M.Concrete, Color3.fromRGB(80 + r:NextInteger(0, 60), 90 + r:NextInteger(0, 50), 100 + r:NextInteger(0, 50)), { Reflectance = 0.15, CanCollide = false })
		p:AddTag("LC_TowerCore")
	end
	-- spawn location
	local sp = Instance.new("SpawnLocation")
	sp.Anchored = true
	sp.Size = Vector3.new(12, 0.2, 12)
	sp.CFrame = CFrame.new(plan.spawnPoint + Vector3.new(0, 0.1, 0))
	sp.Material = M.Pavement
	sp.Color = Color3.fromRGB(165, 160, 152)
	sp.Duration = 0
	sp.Neutral = true
	sp.Parent = root
	root.Parent = workspace
	return root
end

return CityBuilder
]========])
	script("ModuleScript", "ItemFactory", server, [========[
--!nonstrict
-- PROTOTYPE - NOT FOR PRODUCTION
-- Builds the 3D look of loot items (pickup models with a rarity glow beam).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("LootCityShared"):WaitForChild("Config"))
local CityBuilder = require(script.Parent:WaitForChild("CityBuilder"))

local M = Enum.Material
local P, cyl = CityBuilder.P, CityBuilder.cyl
local ItemFactory = {}

local function mat(name: string): Enum.Material
	local ok, v = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	return if ok and v then v else Enum.Material.Fabric
end

local GOLD, SILVER = Color3.fromRGB(255, 196, 90), Color3.fromRGB(225, 228, 235)

local function metalFor(def)
	if def.mat == "silver" then return SILVER end
	return GOLD
end

-- returns a Model whose PrimaryPart sits on the ground at cf
function ItemFactory.Make(def, cf: CFrame)
	local m = Instance.new("Model")
	m.Name = "Loot_" .. def.id
	local base = P(m, Vector3.new(2.2, 0.2, 2.2), cf * CFrame.new(0, 0.1, 0), M.SmoothPlastic, Color3.new(1, 1, 1), { Transparency = 1, CanCollide = false, CastShadow = false })
	m.PrimaryPart = base
	local o = cf * CFrame.Angles(0, math.random() * 6.28, 0)
	local s = def.shape
	local function part(size, off, material, color, props)
		local t = props or {}
		t.CanCollide = false
		return P(m, size, o * off, material, color, t)
	end
	if s == "bottle" then
		part(Vector3.new(2.2, 0.8, 0.8), CFrame.new(0, 0.4, 0), M.Glass, Color3.fromRGB(47, 107, 58), { Shape = Enum.PartType.Cylinder, Transparency = 0.35, Reflectance = 0.2 })
		part(Vector3.new(0.8, 0.35, 0.35), CFrame.new(1.4, 0.4, 0), M.Glass, Color3.fromRGB(47, 107, 58), { Shape = Enum.PartType.Cylinder, Transparency = 0.35 })
	elseif s == "can" then
		part(Vector3.new(1.1, 0.7, 0.7), CFrame.new(0, 0.35, 0), M.Metal, Color3.fromRGB(200, 40, 40), { Shape = Enum.PartType.Cylinder })
	elseif s == "box" then
		part(Vector3.new(3, 2.2, 2.4), CFrame.new(0, 1.1, 0), CityBuilder.CARDBOARD, Color3.fromRGB(164, 122, 76))
		part(Vector3.new(1.5, 0.1, 2.4), CFrame.new(0.9, 2.4, 0) * CFrame.Angles(0, 0, -0.5), CityBuilder.CARDBOARD, Color3.fromRGB(164, 122, 76))
	elseif s == "coil" then
		for k = 0, 2 do
			part(Vector3.new(0.3, 1.8 - k * 0.2, 1.8 - k * 0.2), CFrame.new(0, 0.2 + k * 0.3, 0) * CFrame.Angles(0, 0, math.rad(90)), M.Metal, Color3.fromRGB(208, 122, 74), { Shape = Enum.PartType.Cylinder })
		end
	elseif s == "phone" or s == "console" then
		part(Vector3.new(0.6, 0.12, 1.2), CFrame.new(0, 0.06, 0), M.SmoothPlastic, Color3.fromRGB(20, 20, 22))
		part(Vector3.new(0.5, 0.02, 0.9), CFrame.new(0, 0.13, 0), M.Glass, Color3.fromRGB(30, 60, 90), { Reflectance = 0.4 })
	elseif s == "bag" then
		part(Vector3.new(2.6, 2.2, 2.4), CFrame.new(0, 1.1, 0), M.Plastic, Color3.fromRGB(20, 20, 22), { Shape = Enum.PartType.Ball })
	elseif s == "tire" then
		part(Vector3.new(1.2, 3.2, 3.2), CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), CityBuilder.RUBBER, Color3.fromRGB(22, 22, 22), { Shape = Enum.PartType.Cylinder })
	elseif s == "headphones" then
		part(Vector3.new(0.4, 0.8, 0.8), CFrame.new(-0.6, 0.4, 0), M.SmoothPlastic, Color3.fromRGB(20, 20, 22), { Shape = Enum.PartType.Cylinder })
		part(Vector3.new(0.4, 0.8, 0.8), CFrame.new(0.6, 0.4, 0), M.SmoothPlastic, Color3.fromRGB(20, 20, 22), { Shape = Enum.PartType.Cylinder })
		part(Vector3.new(1.4, 0.15, 0.25), CFrame.new(0, 0.85, 0), M.SmoothPlastic, Color3.fromRGB(20, 20, 22))
	elseif s == "toolbox" then
		part(Vector3.new(3, 1.3, 1.3), CFrame.new(0, 0.65, 0), M.SmoothPlastic, Color3.fromRGB(176, 28, 28))
		part(Vector3.new(1.2, 0.2, 0.2), CFrame.new(0, 1.45, 0), M.Metal, Color3.fromRGB(40, 40, 40))
	elseif s == "wallet" then
		part(Vector3.new(0.9, 0.2, 0.7), CFrame.new(0, 0.1, 0), mat("Leather"), Color3.fromRGB(74, 42, 24))
	elseif s == "radio" or s == "camera" then
		part(Vector3.new(1.6, 1, 0.5), CFrame.new(0, 0.5, 0), if s == "camera" then M.SmoothPlastic else mat("Leather"), Color3.fromRGB(40, 32, 28))
		part(Vector3.new(0.3, 0.6, 0.6), CFrame.new(0, 0.5, -0.35) * CFrame.Angles(0, math.rad(90), 0), M.Metal, Color3.fromRGB(200, 200, 205), { Shape = Enum.PartType.Cylinder })
	elseif s == "spoon" then
		part(Vector3.new(1.2, 0.06, 0.15), CFrame.new(0, 0.05, 0), M.Metal, SILVER)
		part(Vector3.new(0.45, 0.12, 0.35), CFrame.new(0.75, 0.06, 0), M.Metal, SILVER, { Shape = Enum.PartType.Ball })
	elseif s == "laptop" then
		part(Vector3.new(2.6, 0.15, 1.8), CFrame.new(0, 0.08, 0), M.Metal, Color3.fromRGB(190, 194, 200))
		part(Vector3.new(2.6, 1.8, 0.1), CFrame.new(0, 0.95, 0.9) * CFrame.Angles(math.rad(-15), 0, 0), M.Metal, Color3.fromRGB(190, 194, 200))
	elseif s == "gpu" then
		part(Vector3.new(2.2, 0.35, 0.9), CFrame.new(0, 0.18, 0), M.SmoothPlastic, Color3.fromRGB(25, 25, 28))
		part(Vector3.new(0.1, 0.7, 0.7), CFrame.new(-0.5, 0.38, 0) * CFrame.Angles(0, 0, math.rad(90)), M.Metal, Color3.fromRGB(60, 60, 64), { Shape = Enum.PartType.Cylinder })
		part(Vector3.new(0.1, 0.7, 0.7), CFrame.new(0.5, 0.38, 0) * CFrame.Angles(0, 0, math.rad(90)), M.Metal, Color3.fromRGB(60, 60, 64), { Shape = Enum.PartType.Cylinder })
	elseif s == "cash" then
		for k = 0, 2 do
			part(Vector3.new(1.3, 0.15, 0.6), CFrame.new(0, 0.08 + k * 0.15, 0) * CFrame.Angles(0, k * 0.25, 0), M.Fabric, Color3.fromRGB(143, 176, 138))
		end
	elseif s == "bar" then
		part(Vector3.new(1.4, 0.45, 0.65), CFrame.new(0, 0.23, 0), M.Metal, metalFor(def), { Reflectance = 0.25 })
	elseif s == "watch" or s == "ring" then
		part(Vector3.new(0.15, 0.7, 0.7), CFrame.new(0, 0.08, 0) * CFrame.Angles(0, 0, math.rad(90)), M.Metal, GOLD, { Shape = Enum.PartType.Cylinder, Reflectance = 0.3 })
		if s == "ring" then
			part(Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 0.3, 0), M.Glass, Color3.fromRGB(208, 16, 42), { Reflectance = 0.4 })
		end
	elseif s == "case" then
		part(Vector3.new(3, 0.9, 2.2), CFrame.new(0, 0.45, 0), M.Metal, Color3.fromRGB(200, 204, 210))
		part(Vector3.new(0.9, 0.2, 0.2), CFrame.new(0, 1, 0), M.Metal, Color3.fromRGB(30, 30, 30))
	elseif s == "gem" then
		local c = if def.mat == "emerald" then Color3.fromRGB(24, 192, 96) else Color3.fromRGB(220, 240, 255)
		part(Vector3.new(0.7, 0.9, 0.7), CFrame.new(0, 0.5, 0) * CFrame.Angles(math.rad(45), 0, math.rad(45)), M.Glass, c, { Reflectance = 0.5, Transparency = 0.2 })
	elseif s == "egg" then
		part(Vector3.new(1, 1.3, 1), CFrame.new(0, 0.65, 0), M.Metal, GOLD, { Shape = Enum.PartType.Ball, Reflectance = 0.3 })
		part(Vector3.new(0.1, 1.05, 1.05), CFrame.new(0, 0.65, 0) * CFrame.Angles(0, 0, math.rad(90)), M.Glass, Color3.fromRGB(208, 16, 42), { Shape = Enum.PartType.Cylinder })
	elseif s == "coin" then
		part(Vector3.new(0.08, 0.5, 0.5), CFrame.new(0, 0.04, 0) * CFrame.Angles(0, 0, math.rad(90)), M.Metal, metalFor(def), { Shape = Enum.PartType.Cylinder, Reflectance = 0.3 })
		part(Vector3.new(0.08, 0.5, 0.5), CFrame.new(0.35, 0.04, 0.15) * CFrame.Angles(0, 0, math.rad(90)), M.Metal, metalFor(def), { Shape = Enum.PartType.Cylinder, Reflectance = 0.3 })
	elseif s == "record" then
		part(Vector3.new(0.05, 2, 2), CFrame.new(0, 0.03, 0) * CFrame.Angles(0, 0, math.rad(90)), M.SmoothPlastic, Color3.fromRGB(15, 15, 15), { Shape = Enum.PartType.Cylinder })
		part(Vector3.new(0.06, 0.7, 0.7), CFrame.new(0, 0.04, 0) * CFrame.Angles(0, 0, math.rad(90)), M.SmoothPlastic, Color3.fromRGB(176, 28, 28), { Shape = Enum.PartType.Cylinder })
	elseif s == "rotary" then
		part(Vector3.new(1.6, 0.9, 1.4), CFrame.new(0, 0.45, 0), M.SmoothPlastic, Color3.fromRGB(18, 18, 18))
		part(Vector3.new(1.8, 0.35, 0.4), CFrame.new(0, 1.05, 0), M.SmoothPlastic, Color3.fromRGB(18, 18, 18))
	elseif s == "necklace" then
		for k = 0, 11 do
			local a = k / 12 * math.pi * 2
			part(Vector3.new(0.18, 0.18, 0.18), CFrame.new(math.cos(a) * 0.6, 0.09, math.sin(a) * 0.75), M.SmoothPlastic, Color3.fromRGB(246, 239, 230), { Shape = Enum.PartType.Ball, Reflectance = 0.2 })
		end
	elseif s == "frame" then
		part(Vector3.new(3.4, 2.6, 0.25), CFrame.new(0, 1.2, 0) * CFrame.Angles(math.rad(-15), 0, 0), M.Metal, GOLD)
		part(Vector3.new(3, 2.2, 0.1), CFrame.new(0, 1.2, -0.12) * CFrame.Angles(math.rad(-15), 0, 0), M.Fabric, Color3.fromRGB(150, 110, 70))
	elseif s == "statue" then
		part(Vector3.new(1, 0.3, 1), CFrame.new(0, 0.15, 0), M.Marble, Color3.fromRGB(230, 228, 220))
		part(Vector3.new(0.6, 1.5, 0.5), CFrame.new(0, 1.05, 0), M.Metal, Color3.fromRGB(168, 104, 58))
		part(Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 2.05, 0), M.Metal, Color3.fromRGB(168, 104, 58), { Shape = Enum.PartType.Ball })
	elseif s == "vase" then
		part(Vector3.new(1.4, 2, 1.4), CFrame.new(0, 1, 0), M.Glass, Color3.fromRGB(242, 244, 248), { Shape = Enum.PartType.Ball, Reflectance = 0.15 })
		part(Vector3.new(0.6, 0.5, 0.5), CFrame.new(0, 2.1, 0) * CFrame.Angles(0, 0, math.rad(90)), M.Glass, Color3.fromRGB(31, 79, 160), { Shape = Enum.PartType.Cylinder })
	elseif s == "chest" then
		part(Vector3.new(1.4, 0.9, 1), CFrame.new(0, 0.45, 0), M.Wood, Color3.fromRGB(110, 70, 40))
		part(Vector3.new(1.45, 0.15, 1.05), CFrame.new(0, 0.8, 0), M.Metal, GOLD)
	elseif s == "treasure" then
		part(Vector3.new(5, 3, 3.4), CFrame.new(0, 1.5, 0), M.Wood, Color3.fromRGB(110, 70, 40))
		part(Vector3.new(5.1, 0.8, 3.5), CFrame.new(0, 3.4, 0), M.Wood, Color3.fromRGB(96, 60, 34))
		part(Vector3.new(0.4, 4, 3.6), CFrame.new(-1.8, 1.9, 0), M.Metal, GOLD)
		part(Vector3.new(0.4, 4, 3.6), CFrame.new(1.8, 1.9, 0), M.Metal, GOLD)
	else
		part(Vector3.new(1, 1, 1), CFrame.new(0, 0.5, 0), M.Wood, Color3.fromRGB(150, 110, 70))
	end

	-- rarity glow: a thin vertical beam, a light, and sparkles for rare+
	local rar = Config.RARITY[def.r]
	local beam = P(m, Vector3.new(14, 0.35 + def.r * 0.1, 0.35 + def.r * 0.1), cf * CFrame.new(0, 7, 0) * CFrame.Angles(0, 0, math.rad(90)), M.Neon, rar.color, { Shape = Enum.PartType.Cylinder, Transparency = 0.55, CanCollide = false, CastShadow = false, CanQuery = false, CanTouch = false })
	beam.Name = "Beam"
	beam:AddTag("LC_Beam")
	if rar.light > 0 then
		local pl = Instance.new("PointLight")
		pl.Color = rar.color
		pl.Brightness = rar.light
		pl.Range = 10 + def.r * 2
		pl.Shadows = false
		pl.Parent = base
	end
	if def.r >= 3 then
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(rar.color)
		pe.LightEmission = 1
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
		pe.Lifetime = NumberRange.new(0.8, 1.4)
		pe.Rate = 4 + def.r * 3
		pe.Speed = NumberRange.new(1, 3)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Parent = base
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	return m
end

return ItemFactory
]========])
	script("ModuleScript", "HomeBuilder", server, [========[
--!nonstrict
-- PROTOTYPE - NOT FOR PRODUCTION
-- Player home plot: building stages (tent -> mansion) and decorations.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("LootCityShared"):WaitForChild("Config"))
local CityBuilder = require(script.Parent:WaitForChild("CityBuilder"))

local M = Enum.Material
local P, cyl = CityBuilder.P, CityBuilder.cyl
local CURB = Config.CURB
local HomeBuilder = {}

-- plot = {x0,z0,x1,z1,front}; local frame: origin at plot centre on the ground, -Z faces the street
local function frame(plot)
	local c = Vector3.new((plot.x0 + plot.x1) / 2, CURB, (plot.z0 + plot.z1) / 2)
	return CFrame.lookAt(c, c + Vector3.new(0, 0, plot.front))
end

local function wedge(parent, size, cf, material, color)
	local w = Instance.new("WedgePart")
	w.Anchored = true
	w.Size = size
	w.CFrame = cf
	w.Material = material
	w.Color = color
	w.Parent = parent
	return w
end

local function gable(parent, base: CFrame, cx, cz, w, d, y, h, color)
	wedge(parent, Vector3.new(w + 2, h, d / 2 + 1), base * CFrame.new(cx, y + h / 2, cz - d / 4 - 0.5), CityBuilder.ROOFTILES, color)
	wedge(parent, Vector3.new(w + 2, h, d / 2 + 1), base * CFrame.new(cx, y + h / 2, cz + d / 4 + 0.5) * CFrame.Angles(0, math.rad(180), 0), CityBuilder.ROOFTILES, color)
end

local function windows(parent, base, cx, cz, w, d, y, n, ww, wh)
	for k = 0, n - 1 do
		local x = cx - w / 2 + (k + 0.5) * w / n
		P(parent, Vector3.new(ww, wh, 0.4), base * CFrame.new(x, y, cz - d / 2 - 0.1), M.Glass, Color3.fromRGB(30, 40, 48), { Reflectance = 0.25 }):AddTag("LC_Window")
		P(parent, Vector3.new(ww, wh, 0.4), base * CFrame.new(x, y, cz + d / 2 + 0.1), M.Glass, Color3.fromRGB(30, 40, 48), { Reflectance = 0.25 }):AddTag("LC_Window")
	end
end

local function door(parent, base, x, y, z, w)
	P(parent, Vector3.new(w, 8, 0.5), base * CFrame.new(x, y + 4, z), M.Wood, Color3.fromRGB(90, 56, 34))
	local lampPart = P(parent, Vector3.new(0.8, 0.8, 0.8), base * CFrame.new(x + w / 2 + 1.5, y + 8.5, z - 0.5), M.Neon, Color3.fromRGB(255, 220, 160), { Shape = Enum.PartType.Ball })
	local l = Instance.new("PointLight")
	l.Range = 18
	l.Brightness = 1.5
	l.Color = Color3.fromRGB(255, 200, 140)
	l.Parent = lampPart
end

function HomeBuilder.SetStage(plotModel: Model, plot, stage: number)
	local old = plotModel:FindFirstChild("House")
	if old then old:Destroy() end
	local g = Instance.new("Model")
	g.Name = "House"
	local base = frame(plot)
	local white = Color3.fromRGB(236, 232, 224)
	if stage == 2 then
		local orange = Color3.fromRGB(208, 106, 28)
		wedge(g, Vector3.new(12, 8, 6), base * CFrame.new(0, 4, 4 - 3), M.Fabric, orange)
		wedge(g, Vector3.new(12, 8, 6), base * CFrame.new(0, 4, 4 + 3) * CFrame.Angles(0, math.rad(180), 0), M.Fabric, orange)
		local pit = cyl(g, 2, 0.8, base * CFrame.new(10, 0.4, -6), M.Slate, Color3.fromRGB(80, 80, 80))
		local fire = Instance.new("Fire")
		fire.Size = 4
		fire.Heat = 6
		fire.Parent = pit
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 140, 60)
		l.Range = 20
		l.Brightness = 2
		l.Parent = pit
	elseif stage == 3 then
		P(g, Vector3.new(24, 9, 9), base * CFrame.new(0, 6, 4), M.Metal, Color3.fromRGB(80, 110, 130))
		P(g, Vector3.new(24.4, 0.5, 9.4), base * CFrame.new(0, 10.6, 4), M.Metal, Color3.fromRGB(60, 64, 68))
		for _, x in { -7, 0, 7 } do
			P(g, Vector3.new(4, 3, 0.3), base * CFrame.new(x, 7, -0.6), M.Glass, Color3.fromRGB(30, 40, 48), { Reflectance = 0.25 }):AddTag("LC_Window")
		end
		for _, x in { -8, 8 } do
			for _, z in { 0, 8 } do
				P(g, Vector3.new(1.4, 3, 3), base * CFrame.new(x, 1.5, z), CityBuilder.RUBBER, Color3.fromRGB(22, 22, 22), { Shape = Enum.PartType.Cylinder })
			end
		end
	elseif stage == 4 then
		local w, d, h = 28, 22, 12
		P(g, Vector3.new(w, h, d), base * CFrame.new(0, h / 2, 6), M.Brick, Color3.fromRGB(150, 74, 54))
		gable(g, base, 0, 6, w, d, h, 7, Color3.fromRGB(150, 62, 45))
		windows(g, base, 0, 6, w, d, 6, 3, 4, 5)
		door(g, base, 6, 0, 6 - d / 2 - 0.3, 4.5)
		P(g, Vector3.new(3, 7, 3), base * CFrame.new(-8, h + 4, 10), M.Brick, Color3.fromRGB(120, 60, 46))
	elseif stage == 5 then
		local w, d, h = 36, 26, 22
		P(g, Vector3.new(w, h, d), base * CFrame.new(0, h / 2, 6), CityBuilder.PLASTER, Color3.fromRGB(214, 196, 160))
		gable(g, base, 0, 6, w, d, h, 9, Color3.fromRGB(140, 58, 42))
		windows(g, base, 0, 6, w, d, 6, 4, 5, 6)
		windows(g, base, 0, 6, w, d, 17, 4, 5, 6)
		P(g, Vector3.new(16, 0.8, 7), base * CFrame.new(0, 0.4, 6 - d / 2 - 3.5), M.WoodPlanks, Color3.fromRGB(140, 100, 66))
		P(g, Vector3.new(17, 0.8, 7.5), base * CFrame.new(0, 10, 6 - d / 2 - 3.5), M.WoodPlanks, Color3.fromRGB(110, 76, 50))
		for _, x in { -7.5, 7.5 } do
			cyl(g, 0.5, 9.2, base * CFrame.new(x, 5.2, 6 - d / 2 - 6.5), M.Marble, white)
		end
		door(g, base, 0, 0.8, 6 - d / 2 - 0.3, 5)
	elseif stage == 6 then
		local w, d, h = 34, 28, 34
		P(g, Vector3.new(w, h, d), base * CFrame.new(0, h / 2, 8), CityBuilder.PLASTER, white)
		for _, s in { -1, 1 } do
			P(g, Vector3.new(9, 22, 22), base * CFrame.new(s * (w / 2 + 4.5), 11, 8), CityBuilder.PLASTER, white)
			P(g, Vector3.new(9.6, 1, 22.6), base * CFrame.new(s * (w / 2 + 4.5), 22.5, 8), M.Marble, Color3.fromRGB(200, 198, 192))
		end
		P(g, Vector3.new(w + 1.4, 1.4, d + 1.4), base * CFrame.new(0, h + 0.7, 8), M.Marble, Color3.fromRGB(200, 198, 192))
		for f = 0, 2 do
			windows(g, base, 0, 8, w, d, 6 + f * 11, 5, 4.4, 7)
		end
		-- portico
		P(g, Vector3.new(26, 1.5, 9), base * CFrame.new(0, 0.75, 8 - d / 2 - 4.5), M.Marble, Color3.fromRGB(230, 228, 220))
		P(g, Vector3.new(27, 2, 10), base * CFrame.new(0, 21, 8 - d / 2 - 4.5), M.Marble, Color3.fromRGB(230, 228, 220))
		for k = 0, 5 do
			cyl(g, 1, 19, base * CFrame.new(-11 + k * 4.4, 11, 8 - d / 2 - 8), M.Marble, white)
		end
		door(g, base, 0, 1.5, 8 - d / 2 - 0.3, 6)
	end
	g.Parent = plotModel
end

function HomeBuilder.AddDecor(plotModel: Model, plot, id: string)
	local folder = plotModel:FindFirstChild("Decor") or (function()
		local f = Instance.new("Folder")
		f.Name = "Decor"
		f.Parent = plotModel
		return f
	end)()
	if folder:FindFirstChild(id) then return end
	local g = Instance.new("Model")
	g.Name = id
	local base = frame(plot)
	local hw = (plot.x1 - plot.x0) / 2 - 1
	local wood = Color3.fromRGB(140, 100, 66)
	if id == "fence" then
		local function run(ax, az, bx, bz, gap)
			local len = math.sqrt((bx - ax) ^ 2 + (bz - az) ^ 2)
			local n = math.floor(len / 6)
			for k = 0, n do
				local t = k / n
				local x, z = ax + (bx - ax) * t, az + (bz - az) * t
				if not (gap and math.abs(x) < 6) then
					P(g, Vector3.new(0.6, 4.5, 0.6), base * CFrame.new(x, 2.25, z), M.Wood, wood)
				end
			end
			local cf = CFrame.lookAt(Vector3.new(ax, 0, az), Vector3.new(bx, 0, bz))
			for h = 0, 2 do
				if gap then
					P(g, Vector3.new(0.3, 0.6, len / 2 - 6), base * CFrame.new(ax, 0, az) * (cf - cf.Position) * CFrame.new(0, 1.3 + h * 1.2, -(len / 4 - 3)), M.Wood, wood)
					P(g, Vector3.new(0.3, 0.6, len / 2 - 6), base * CFrame.new(ax, 0, az) * (cf - cf.Position) * CFrame.new(0, 1.3 + h * 1.2, -(len * 3 / 4 + 3)), M.Wood, wood)
				else
					P(g, Vector3.new(0.3, 0.6, len), base * CFrame.new(ax, 0, az) * (cf - cf.Position) * CFrame.new(0, 1.3 + h * 1.2, -len / 2), M.Wood, wood)
				end
			end
		end
		run(-hw, -hw, hw, -hw, true)
		run(-hw, hw, hw, hw, false)
		run(-hw, -hw, -hw, hw, false)
		run(hw, -hw, hw, hw, false)
	elseif id == "lamps" then
		P(g, Vector3.new(8, 0.15, hw - 6), base * CFrame.new(0, 0.08, -hw / 2 - 3), M.Pavement, Color3.fromRGB(180, 176, 168), { CanCollide = false })
		for _, p in { { -5, -hw + 2 }, { 5, -hw + 2 }, { -5, -10 }, { 5, -10 } } do
			cyl(g, 0.2, 5, base * CFrame.new(p[1], 2.5, p[2]), M.Metal, Color3.fromRGB(30, 30, 32))
			local b = P(g, Vector3.new(1, 1, 1), base * CFrame.new(p[1], 5.4, p[2]), M.Neon, Color3.fromRGB(255, 226, 170), { Shape = Enum.PartType.Ball })
			local l = Instance.new("PointLight")
			l.Range = 14
			l.Brightness = 1.2
			l.Color = Color3.fromRGB(255, 205, 150)
			l.Parent = b
		end
	elseif id == "garden" then
		for _, p in { { -hw + 4, hw - 4 }, { hw - 4, hw - 4 }, { -hw + 4, -hw + 10 }, { hw - 4, -hw + 10 } } do
			cyl(g, 0.7, 10, base * CFrame.new(p[1], 5, p[2]), M.Wood, Color3.fromRGB(78, 60, 44))
			for k = 1, 4 do
				P(g, Vector3.one * (6 + k), base * CFrame.new(p[1] + math.sin(k) * 2, 11 + k * 0.8, p[2] + math.cos(k) * 2), M.LeafyGrass, Color3.fromRGB(70, 110, 50), { Shape = Enum.PartType.Ball })
			end
		end
		local fc = { Color3.fromRGB(232, 58, 90), Color3.fromRGB(242, 194, 48), Color3.fromRGB(255, 255, 255), Color3.fromRGB(178, 74, 216) }
		for k = 0, 23 do
			local s = if k % 2 == 0 then -1 else 1
			P(g, Vector3.new(0.7, 0.7, 0.7), base * CFrame.new(s * (6 + (k % 3)), 0.4, -hw + 3 + math.floor(k / 2) * 1.6), M.SmoothPlastic, fc[k % 4 + 1], { Shape = Enum.PartType.Ball, CanCollide = false })
		end
	elseif id == "bench" then
		local c = base * CFrame.new(hw - 9, 0, -hw + 10)
		for _, p in { { -5, -5 }, { 5, -5 }, { -5, 5 }, { 5, 5 } } do
			P(g, Vector3.new(0.6, 9, 0.6), c * CFrame.new(p[1], 4.5, p[2]), M.Wood, wood)
		end
		wedge(g, Vector3.new(13, 3, 6.5), c * CFrame.new(0, 10.5, -3.25), CityBuilder.ROOFTILES, Color3.fromRGB(140, 58, 42))
		wedge(g, Vector3.new(13, 3, 6.5), c * CFrame.new(0, 10.5, 3.25) * CFrame.Angles(0, math.rad(180), 0), CityBuilder.ROOFTILES, Color3.fromRGB(140, 58, 42))
		CityBuilder.Bench(g, c)
	elseif id == "garage" then
		local c = base * CFrame.new(-hw + 8, 0, -4)
		P(g, Vector3.new(14, 10, 20), c * CFrame.new(0, 5, 0), CityBuilder.PLASTER, Color3.fromRGB(190, 190, 185))
		P(g, Vector3.new(15, 0.8, 21), c * CFrame.new(0, 10.4, 0), M.Metal, Color3.fromRGB(70, 72, 76))
		P(g, Vector3.new(11, 8, 0.4), c * CFrame.new(0, 4, -10.1), M.DiamondPlate, Color3.fromRGB(140, 144, 148))
	elseif id == "pool" then
		local c = base * CFrame.new(10, 0, hw - 9)
		P(g, Vector3.new(26, 0.8, 14), c * CFrame.new(0, 0.4, 0), M.Marble, Color3.fromRGB(232, 230, 224))
		P(g, Vector3.new(22, 0.1, 10), c * CFrame.new(0, 0.85, 0), M.Glass, Color3.fromRGB(40, 150, 190), { Reflectance = 0.3, Transparency = 0.1, CanCollide = false })
	elseif id == "fountain" then
		local c = base * CFrame.new(0, 0, -hw + 12)
		cyl(g, 6, 1.6, c * CFrame.new(0, 0.8, 0), M.Marble, Color3.fromRGB(225, 222, 215))
		cyl(g, 5.4, 0.1, c * CFrame.new(0, 1.65, 0), M.Glass, Color3.fromRGB(40, 130, 170), { Reflectance = 0.3, Transparency = 0.15 })
		local col = cyl(g, 0.8, 6, c * CFrame.new(0, 3, 0), M.Marble, Color3.fromRGB(225, 222, 215))
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
		pe.Transparency = NumberSequence.new(0.4, 1)
		pe.Size = NumberSequence.new(0.4, 1)
		pe.Lifetime = NumberRange.new(0.8, 1.2)
		pe.Rate = 50
		pe.Speed = NumberRange.new(8, 10)
		pe.SpreadAngle = Vector2.new(15, 15)
		pe.Acceleration = Vector3.new(0, -30, 0)
		pe.EmissionDirection = Enum.NormalId.Right
		pe.Parent = col
	elseif id == "statue" then
		local c = base * CFrame.new(hw - 7, 0, 8)
		local gold = Color3.fromRGB(255, 196, 90)
		P(g, Vector3.new(6, 4, 6), c * CFrame.new(0, 2, 0), M.Marble, Color3.fromRGB(230, 228, 220))
		P(g, Vector3.new(2.4, 5, 1.6), c * CFrame.new(0, 6.5, 0), M.Metal, gold, { Reflectance = 0.3 })
		P(g, Vector3.new(2, 2, 2), c * CFrame.new(0, 10, 0), M.Metal, gold, { Shape = Enum.PartType.Ball, Reflectance = 0.3 })
		P(g, Vector3.new(0.8, 4, 0.8), c * CFrame.new(1.8, 9.5, 0) * CFrame.Angles(0, 0, math.rad(-35)), M.Metal, gold, { Reflectance = 0.3 })
	end
	g.Parent = folder
end

function HomeBuilder.Sign(plotModel: Model, plot, text: string)
	local old = plotModel:FindFirstChild("Sign")
	if old then old:Destroy() end
	local base = frame(plot)
	local hw = (plot.x1 - plot.x0) / 2
	local m = Instance.new("Model")
	m.Name = "Sign"
	P(m, Vector3.new(0.5, 7, 0.5), base * CFrame.new(12, 3.5, -hw + 1), M.Wood, Color3.fromRGB(110, 76, 50))
	local board = P(m, Vector3.new(10, 3.4, 0.4), base * CFrame.new(12, 6.4, -hw + 0.8), M.Wood, Color3.fromRGB(30, 60, 36))
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(400, 136)
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.TextColor3 = Color3.fromRGB(220, 255, 220)
	tl.Font = Enum.Font.GothamBold
	tl.TextScaled = true
	tl.Text = text
	tl.Parent = sg
	sg.Parent = board
	m.Parent = plotModel
end

return HomeBuilder
]========])
	script("Script", "Server", server, [========[
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
]========])
	script("LocalScript", "LootCityClient", SPS, [========[
--!nonstrict
-- PROTOTYPE - NOT FOR PRODUCTION
-- Loot City client: HUD, phone, NPC shops, minimap, night lights, rain, traffic, sprint, vehicles.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("LootCityShared")
local Config = require(Shared:WaitForChild("Config"))
local ActionRF = Shared:WaitForChild("Action")
local PushRE = Shared:WaitForChild("Push")
local ITEM, RARITY, DISTRICTS = Config.ITEM_BY_ID, Config.RARITY, Config.DISTRICTS

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

local S = nil -- latest server state
local function fmt(n)
	n = math.floor(n or 0)
	local s = tostring(math.abs(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^ ", "")
	return (if n < 0 then "-$" else "$") .. out
end
local function has(list, v)
	return list ~= nil and table.find(list, v) ~= nil
end

-- ============ UI helpers ============
local FONT = Enum.Font.Gotham
local FONT_B = Enum.Font.GothamBold
local GLASS = Color3.fromRGB(14, 18, 24)
local ACC = Color3.fromRGB(255, 181, 46)
local GOOD = Color3.fromRGB(94, 227, 122)
local BAD = Color3.fromRGB(255, 90, 90)
local DIM = Color3.fromRGB(154, 166, 178)

local function new(class, props, children)
	local o = Instance.new(class)
	for k, v in props or {} do
		if k ~= "Parent" then (o :: any)[k] = v end
	end
	for _, c in children or {} do
		c.Parent = o
	end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end
local function corner(r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 12) })
end
local function stroke(c, t)
	return new("UIStroke", { Color = c or Color3.fromRGB(255, 255, 255), Transparency = t or 0.85, Thickness = 1 })
end
local function pad(p)
	return new("UIPadding", { PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p), PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p) })
end
local function label(props)
	local t = {
		BackgroundTransparency = 1, Font = FONT, TextColor3 = Color3.fromRGB(238, 242, 246), TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 20), RichText = true,
	}
	for k, v in props do t[k] = v end
	return new("TextLabel", t)
end
local function button(text, primary, onClick, props)
	local b = new("TextButton", {
		Text = text, Font = FONT_B, TextSize = 15, AutoButtonColor = true,
		TextColor3 = if primary then Color3.fromRGB(27, 18, 6) else Color3.fromRGB(238, 242, 246),
		BackgroundColor3 = if primary then ACC else Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = if primary then 0 else 0.9,
		Size = UDim2.new(0, 120, 0, 36), AutomaticSize = Enum.AutomaticSize.X,
	}, { corner(10), new("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }) })
	if props then
		for k, v in props do (b :: any)[k] = v end
	end
	if onClick then b.MouseButton1Click:Connect(onClick) end
	return b
end

local gui = new("ScreenGui", { Name = "LootCityUI", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })

-- ============ HUD ============
local tl = new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 18, 0, 60), Size = UDim2.new(0, 320, 0, 300), Parent = gui },
	{ new("UIListLayout", { Padding = UDim.new(0, 8) }) })
local function pill(h)
	return new("Frame", { BackgroundColor3 = GLASS, BackgroundTransparency = 0.35, Size = UDim2.new(0, 0, 0, h), AutomaticSize = Enum.AutomaticSize.X, Parent = tl }, { corner(12), stroke(), pad(10) })
end
local moneyPill = pill(58)
local moneyL = label({ Text = "$0", Font = FONT_B, TextSize = 30, TextColor3 = Color3.fromRGB(255, 224, 138), Size = UDim2.new(0, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.X, Parent = moneyPill })
local incomeL = label({ Text = "", TextSize = 13, TextColor3 = GOOD, Position = UDim2.new(0, 0, 0, 30), Size = UDim2.new(0, 0, 0, 16), AutomaticSize = Enum.AutomaticSize.X, Parent = moneyPill })
local bagPill = pill(40)
local bagL = label({ Text = "🎒 0/6", Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Parent = bagPill })
local distPill = pill(40)
local distL = label({ Text = "📍 Окраина", Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Parent = distPill })
local fxFrame = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 320, 0, 80), Parent = tl }, { new("UIListLayout", { Padding = UDim.new(0, 4) }) })

-- minimap
local MAPSIZE = 220
local mapHolder = new("CanvasGroup", { BackgroundColor3 = Color3.fromRGB(10, 12, 16), BackgroundTransparency = 0.25, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 60), Size = UDim2.fromOffset(MAPSIZE, MAPSIZE), Parent = gui },
	{ new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
new("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.6, Thickness = 2, Parent = mapHolder })
local mapWorld = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0), Parent = mapHolder })
local clockL = new("TextLabel", { BackgroundColor3 = GLASS, BackgroundTransparency = 0.35, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 60 + MAPSIZE + 8), Size = UDim2.fromOffset(MAPSIZE, 34), Font = FONT_B, TextSize = 15, TextColor3 = Color3.new(1, 1, 1), Text = "", Parent = gui }, { corner(10), stroke() })

-- static minimap content (blocks/district tints) built once into a big frame we move around
local MAPSCALE = 0.35 -- px per stud
local HALF = Config.HALF
local function m2p(x, z)
	return UDim2.fromOffset((x + HALF + 60) * MAPSCALE, (z + HALF + 60) * MAPSCALE)
end
local districtTiles = {}
local function buildStaticMap(parent, scale)
	local function at(x, z)
		return UDim2.fromOffset((x + HALF + 60) * scale, (z + HALF + 60) * scale)
	end
	new("Frame", { BackgroundColor3 = Color3.fromRGB(32, 34, 38), BorderSizePixel = 0, Position = at(-HALF - 30, -HALF - 30), Size = UDim2.fromOffset((HALF * 2 + 60) * scale, (HALF * 2 + 60) * scale), Parent = parent })
	local tiles = {}
	for d = 1, 4 do
		local x0 = if d % 2 == 1 then -HALF else 0
		local z0 = if d >= 3 then -HALF else 0
		tiles[d] = new("Frame", { BackgroundColor3 = DISTRICTS[d].color, BackgroundTransparency = 0.8, BorderSizePixel = 0, Position = at(x0, z0), Size = UDim2.fromOffset(HALF * scale, HALF * scale), Parent = parent })
	end
	for i = 0, Config.N - 1 do
		for j = 0, Config.N - 1 do
			local x0 = Config.roadLine(i) + Config.ROAD / 2
			local z0 = Config.roadLine(j) + Config.ROAD / 2
			new("Frame", { BackgroundColor3 = Color3.fromRGB(120, 124, 130), BackgroundTransparency = 0.55, BorderSizePixel = 0, Position = at(x0, z0), Size = UDim2.fromOffset((Config.CELL - Config.ROAD) * scale, (Config.CELL - Config.ROAD) * scale), Parent = parent })
		end
	end
	return tiles
end
districtTiles = buildStaticMap(mapWorld, MAPSCALE)
local npcIcons = {}
local function refreshNpcIcons(parent, scale, store)
	for _, c in store do c:Destroy() end
	table.clear(store)
	local folder = workspace:FindFirstChild("LootCityNPC")
	if not folder then return end
	for _, m in folder:GetChildren() do
		if m:IsA("Model") and m:GetAttribute("NPC") then
			local p = m:GetPivot().Position
			table.insert(store, new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Text = m:GetAttribute("Icon"), TextSize = 16, Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset((p.X + HALF + 60) * scale, (p.Z + HALF + 60) * scale), ZIndex = 3, Parent = parent }))
		end
	end
end
local homeIcon = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Text = "🏠", TextSize = 18, Size = UDim2.fromOffset(22, 22), ZIndex = 3, Visible = false, Parent = mapWorld })
local dotPool = {}
local arrow = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(26, 26), Text = "▲", TextSize = 22, Font = FONT_B, TextColor3 = Color3.new(1, 1, 1), ZIndex = 5, Parent = mapHolder })
new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(20, 16), Text = "С", Font = FONT_B, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), ZIndex = 5, Parent = mapHolder })

-- prompt hint, stamina, toasts, banner
local stamBar = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -28), Size = UDim2.fromOffset(240, 6), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.85, Parent = gui }, { corner(4) })
local stamFill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(94, 227, 192), Parent = stamBar }, { corner(4) })
local toasts = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -18, 1, -18), Size = UDim2.fromOffset(420, 300), Parent = gui },
	{ new("UIListLayout", { Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right }) })
local banner = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.fromOffset(560, 74), BackgroundColor3 = Color3.fromRGB(40, 20, 0), BackgroundTransparency = 0.2, Visible = false, Parent = gui }, { corner(14), new("UIStroke", { Color = ACC, Transparency = 0.4 }) })
local bannerT = label({ Text = "", Font = FONT_B, TextSize = 22, TextColor3 = Color3.fromRGB(255, 210, 122), TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 0, 26), Parent = banner })
local bannerS = label({ Text = "", TextSize = 14, TextColor3 = Color3.fromRGB(240, 220, 192), TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(10, 40), Size = UDim2.new(1, -20, 0, 26), TextWrapped = true, Parent = banner })

local function toast(text, color)
	local c = Color3.fromRGB(255, 181, 46)
	if typeof(color) == "string" then
		pcall(function()
			c = Color3.fromHex(color)
		end)
	end
	local f = new("Frame", { BackgroundColor3 = GLASS, BackgroundTransparency = 0.25, Size = UDim2.fromOffset(0, 36), AutomaticSize = Enum.AutomaticSize.X, Parent = toasts }, {
		corner(10), stroke(),
		new("Frame", { BackgroundColor3 = c, Size = UDim2.new(0, 4, 1, 0), BorderSizePixel = 0 }),
		label({ Text = text, TextSize = 14, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X }),
		new("UIPadding", { PaddingRight = UDim.new(0, 26) }),
	})
	local kids = toasts:GetChildren()
	local n = 0
	for _, k in kids do
		if k:IsA("Frame") then n += 1 end
	end
	if n > 5 then
		for _, k in kids do
			if k:IsA("Frame") then k:Destroy() break end
		end
	end
	task.delay(5.5, function()
		if f.Parent then f:Destroy() end
	end)
end
local bannerToken = 0
local function showBanner(t, s)
	bannerT.Text, bannerS.Text = t, s
	banner.Visible = true
	bannerToken += 1
	local my = bannerToken
	task.delay(7, function()
		if my == bannerToken then banner.Visible = false end
	end)
end

-- mobile/desktop buttons
local btnBar = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 18, 1, -18), Size = UDim2.fromOffset(400, 44), Parent = gui },
	{ new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }) })

-- ============ sounds ============
local function sfx(id, pitch)
	local map = {
		pickup = "rbxasset://sounds/electronicpingshort.wav", cash = "rbxasset://sounds/button.wav",
		error = "rbxasset://sounds/uuhhh.mp3", event = "rbxasset://sounds/swoosh.wav", legend = "rbxasset://sounds/electronicpingshort.wav",
	}
	local s = Instance.new("Sound")
	s.SoundId = map[id] or map.cash
	s.Volume = if id == "error" then 0.3 else 0.6
	s.PlaybackSpeed = pitch or 1
	s.Parent = SoundService
	s:Play()
	s.Ended:Connect(function()
		s:Destroy()
	end)
end

-- ============ modal (phone + NPC) ============
local modal = new("Frame", { Visible = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = gui })
local card = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.62, 0, 0.8, 0), BackgroundColor3 = GLASS, BackgroundTransparency = 0.08, ZIndex = 21, Parent = modal },
	{ corner(18), stroke(), new("UISizeConstraint", { MaxSize = Vector2.new(940, 760), MinSize = Vector2.new(520, 380) }) })
local head = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 78), ZIndex = 22, Parent = card }, { pad(16) })
local headIcon = label({ Text = "📱", TextSize = 36, Size = UDim2.fromOffset(50, 46), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 22, Parent = head })
local headTitle = label({ Text = "", Font = FONT_B, TextSize = 22, Position = UDim2.fromOffset(62, 0), Size = UDim2.new(1, -300, 0, 26), ZIndex = 22, Parent = head })
local headSub = label({ Text = "", TextSize = 13, TextColor3 = DIM, Position = UDim2.fromOffset(62, 28), Size = UDim2.new(1, -300, 0, 18), ZIndex = 22, Parent = head })
local headMoney = label({ Text = "", Font = FONT_B, TextSize = 20, TextColor3 = Color3.fromRGB(255, 224, 138), TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -60, 0, 0), Size = UDim2.fromOffset(200, 24), ZIndex = 22, Parent = head })
local headBag = label({ Text = "", TextSize = 13, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -60, 0, 26), Size = UDim2.fromOffset(200, 18), ZIndex = 22, Parent = head })
local closeBtn = button("✕", false, nil, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(44, 40), AutomaticSize = Enum.AutomaticSize.None, ZIndex = 22, Parent = head })
local tabsBar = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 80), Size = UDim2.new(1, -32, 0, 38), ZIndex = 22, Parent = card },
	{ new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }) })
local body = new("ScrollingFrame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 126), Size = UDim2.new(1, -32, 1, -142), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, BorderSizePixel = 0, ZIndex = 22, Parent = card },
	{ new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }), new("UIPadding", { PaddingRight = UDim.new(0, 10) }) })

local Modal = { open = false, kind = nil, npc = nil, tab = nil, greet = "" }
local renderModal -- forward

local function clearBody()
	for _, c in body:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
	end
end
local order = 0
local function add(o)
	order += 1
	o.LayoutOrder = order
	o.ZIndex = 23
	for _, d in o:GetDescendants() do
		if d:IsA("GuiObject") then d.ZIndex = 24 end
	end
	o.Parent = body
	return o
end
local function say(text)
	return add(new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.95, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, {
		corner(10), pad(12), new("UIStroke", { Color = ACC, Transparency = 0.6 }),
		label({ Text = text, TextWrapped = true, TextSize = 15, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }),
	}))
end
local function muted(text)
	return add(label({ Text = text, TextColor3 = DIM, TextSize = 13, TextWrapped = true, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }))
end
-- row: title, desc, right side {price text, buttons...}
local function row(title, desc, priceText, buttons, dotColor)
	local f = new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.96, Size = UDim2.new(1, 0, 0, 58) }, { corner(10) })
	local x = 14
	if dotColor then
		new("Frame", { BackgroundColor3 = dotColor, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(10, 10), Parent = f }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		x = 30
	end
	label({ Text = title, Font = FONT_B, TextSize = 16, Position = UDim2.fromOffset(x, 9), Size = UDim2.new(0.6, -x, 0, 20), TextTruncate = Enum.TextTruncate.AtEnd, Parent = f })
	label({ Text = desc or "", TextSize = 12, TextColor3 = DIM, Position = UDim2.fromOffset(x, 31), Size = UDim2.new(0.62, -x, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, Parent = f })
	local right = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.4, 0, 0, 38), Parent = f },
		{ new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8) }) })
	if priceText then
		label({ Text = priceText, Font = FONT_B, TextSize = 16, TextColor3 = Color3.fromRGB(255, 224, 138), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Parent = right })
	end
	for _, b in buttons or {} do
		b.Parent = right
	end
	return add(f)
end

local busy = false
local function act(name, args)
	if busy then return end
	busy = true
	task.spawn(function()
		local ok, res = pcall(function()
			return ActionRF:InvokeServer(name, args)
		end)
		busy = false
		if not ok or not res then sfx("error") end
	end)
end

local function setTabs(list)
	for _, c in tabsBar:GetChildren() do
		if c:IsA("TextButton") then c:Destroy() end
	end
	if #list <= 1 then return end
	for _, t in list do
		local b = button(t[2], Modal.tab == t[1], function()
			Modal.tab = t[1]
			if t[1] == "quest" and Modal.npc then act("quest", { npc = Modal.npc }) end
			renderModal()
		end, { ZIndex = 23 })
		b.Parent = tabsBar
	end
end

local NPC_BY_ID = {}
for _, n in Config.NPCS do NPC_BY_ID[n.id] = n end
local SELLERS = { pawn = true, antiq = true, scrap = true, shadow = true, jeweler = true }
local QUESTERS = { quest1 = true, quest2 = true, scrap = true, quest4 = true }

local function npcTabs(id)
	local t = {}
	if SELLERS[id] then table.insert(t, { "sell", "Продать" }) end
	if id == "gear" then table.insert(t, { "upg", "Улучшения" }) end
	if id == "garage" then table.insert(t, { "veh", "Транспорт" }) end
	if id == "broker" then table.insert(t, { "biz", "Бизнес" }) end
	if id == "mayor" then table.insert(t, { "perm", "Пропуска" }) end
	if id == "foreman" then table.insert(t, { "build", "Строительство" }); table.insert(t, { "decor", "Благоустройство" }) end
	if id == "antiq" then table.insert(t, { "maps", "Карты кладов" }) end
	if id == "shadow" then table.insert(t, { "black", "Особый товар" }) end
	if QUESTERS[id] then table.insert(t, { "quest", "Задание" }) end
	return t
end

local function pips(l, max)
	local s = ""
	for k = 1, max do
		s ..= if k <= l then "■" else "□"
	end
	return s
end

local function renderNPC()
	local def = NPC_BY_ID[Modal.npc]
	headIcon.Text, headTitle.Text, headSub.Text = def.icon, def.name, def.role
	setTabs(npcTabs(def.id))
	say("«" .. Modal.greet .. "»")
	local tab = Modal.tab
	if tab == "sell" then
		if #S.inv == 0 then muted("Рюкзак пуст. Возвращайтесь с добычей!") return end
		local total = 0
		for i, it in S.inv do
			local d = ITEM[it.id]
			if not (d.col and not has(S.col[d.col], d.id)) then total += S.prices[i][def.id] end
		end
		local top = add(new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40) }))
		label({ Text = ("Множитель торговли ×%.2f"):format(S.trade), TextColor3 = DIM, TextSize = 14, Size = UDim2.new(0.5, 0, 1, 0), Parent = top })
		button("Продать всё (кроме коллекционных) за " .. fmt(total), true, function()
			act("sellall", { npc = def.id })
		end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Parent = top })
		for i, it in S.inv do
			local d = ITEM[it.id]
			local mm = S.market[d.cat] or 1
			local trend = if mm > 1.05 then (" <font color='#5ee37a'>▲%d%%</font>"):format(math.floor((mm - 1) * 100)) elseif mm < 0.95 then (" <font color='#ff5a5a'>▼%d%%</font>"):format(math.floor((1 - mm) * 100)) else ""
			local need = d.col and not has(S.col[d.col], d.id)
			row(d.name, RARITY[d.r].name .. " · " .. Config.CATEGORIES[d.cat] .. trend .. (if need then " · <font color='#b26bff'>нужен для коллекции</font>" else ""), fmt(S.prices[i][def.id]),
				{ button("Продать", false, function() act("sell", { npc = def.id, i = i }) end) }, RARITY[d.r].color)
		end
	elseif tab == "upg" then
		for _, u in Config.UPGRADES do
			local l = S.upg[u.id] or 0
			local c = Config.upgradeCost(u, l)
			if l >= u.max then
				row(u.name .. "  " .. pips(l, u.max), u.desc, "Максимум", {})
			else
				row(u.name .. "  " .. pips(l, u.max), u.desc, fmt(c), { button("Купить", S.money >= c, function() act("upg", { id = u.id }) end) })
			end
		end
	elseif tab == "veh" then
		for _, v in Config.VEHICLES do
			if has(S.vehicles, v.id) then
				row(v.name, v.desc .. (" Скорость ×%.1f"):format(v.speed), nil, { button(if S.vehicle == v.id then "Слезть" else "Ехать", false, function()
					act("ride", { id = if S.vehicle == v.id then nil else v.id })
				end) })
			else
				row(v.name, v.desc .. (" Скорость ×%.1f"):format(v.speed), fmt(v.cost), { button("Купить", S.money >= v.cost, function() act("veh", { id = v.id }) end) })
			end
		end
		muted("Клавиша V — сесть на лучший транспорт или слезть.")
	elseif tab == "biz" then
		muted(("Доход сейчас: %s/мин (бонус престижа дома +%d%%). Оффлайн бизнес работает вполсилы, до 2 часов."):format(fmt(S.ppm), S.prestige))
		for _, b in Config.BUSINESSES do
			local own = S.biz[b.id] or 0
			local c = Config.businessCost(b, own)
			if own >= b.max then
				row(("%s ×%d/%d"):format(b.name, own, b.max), "+" .. fmt(b.income) .. "/мин за каждый", "Максимум", {})
			else
				row(("%s ×%d/%d"):format(b.name, own, b.max), "+" .. fmt(b.income) .. "/мин за каждый", fmt(c), { button("Купить", S.money >= c, function() act("biz", { id = b.id }) end) })
			end
		end
	elseif tab == "perm" then
		for d, dist in DISTRICTS do
			if S.unlocked[d] then
				row(dist.name, dist.desc, "Открыт", {})
			else
				row(dist.name, dist.desc .. (" Ценность находок ×%.1f"):format(dist.lootMult), fmt(dist.cost), { button("Купить пропуск", S.money >= dist.cost, function() act("perm", { d = d }) end) })
			end
		end
	elseif tab == "build" then
		for i, h in Config.HOME_STAGES do
			if i > 1 then
				if S.home >= i then
					row(h.name, "Престиж +" .. h.prestige, "Построено", {})
				elseif S.home == i - 1 then
					row(h.name, "Престиж +" .. h.prestige, fmt(h.cost), { button("Построить", S.money >= h.cost, function() act("build", { stage = i }) end) })
				else
					row(h.name, "Сначала предыдущий этап", fmt(h.cost), {})
				end
			end
		end
	elseif tab == "decor" then
		for _, d in Config.DECOR do
			if has(S.decor, d.id) then
				row(d.name, "Престиж +" .. d.prestige, "Есть", {})
			elseif S.home < d.needStage then
				row(d.name, "Нужно: " .. Config.HOME_STAGES[d.needStage].name, fmt(d.cost), {})
			else
				row(d.name, "Престиж +" .. d.prestige, fmt(d.cost), { button("Купить", S.money >= d.cost, function() act("decor", { id = d.id }) end) })
			end
		end
	elseif tab == "maps" then
		local c = 1500 + S.day * 100
		row("Карта клада", "Сундук с тремя ценными находками в открытом районе", fmt(c), { button("Купить", S.money >= c, function() act("map", {}) end) })
	elseif tab == "black" then
		row("Счастливый билет", "3 минуты сильно повышенной удачи", fmt(2500), { button("Купить", S.money >= 2500, function() act("ticket", {}) end) })
	elseif tab == "quest" then
		local q = S.quests[def.id]
		if not q or not q.text then
			muted("Получаем задание…")
			return
		end
		say("📜 " .. q.text .. "\nПрогресс: " .. q.prog .. "\nНаграда: " .. fmt(q.reward) .. " + репутация")
		local bar = add(new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40) }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }) }))
		button("Сдать задание", q.ready, function() act("qdone", { npc = def.id }) end).Parent = bar
		button("Другое задание", false, function() act("quest", { npc = def.id, skip = true }) end).Parent = bar
		muted(("Репутация: %d (уровень %d, +%d%% к ценам продажи)"):format(S.rep, S.repLevel, S.repLevel * 2))
	end
end

local bigMap = nil
local function renderPhone()
	headIcon.Text, headTitle.Text, headSub.Text = "📱", "Телефон", ("День %d · Репутация %d"):format(S.day, S.rep)
	setTabs({ { "inv", "🎒 Рюкзак" }, { "col", "🏆 Коллекции" }, { "quests", "📜 Задания" }, { "market", "📊 Рынок" }, { "map", "🗺️ Карта" }, { "stats", "📈 Статистика" } })
	local tab = Modal.tab
	if tab == "inv" then
		local top = add(new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40) }))
		label({ Text = ("Занято %d из %d мест"):format(S.used, S.slots), TextColor3 = DIM, TextSize = 14, Size = UDim2.new(0.5, 0, 1, 0), Parent = top })
		button("🚕 Такси к участку ($50)", false, function() act("taxi", {}) end, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Parent = top })
		if #S.inv == 0 then muted("Рюкзак пуст.") end
		for i, it in S.inv do
			local d = ITEM[it.id]
			local need = d.col and not has(S.col[d.col], d.id)
			local btns = {}
			if need then table.insert(btns, button("В коллекцию", true, function() act("collect", { i = i }) end)) end
			table.insert(btns, button("Выбросить", false, function() act("drop", { i = i }) end))
			row(d.name, ("%s · %s · %d мест · ~%s"):format(RARITY[d.r].name, Config.CATEGORIES[d.cat], d.slots, fmt(it.value)), nil, btns, RARITY[d.r].color)
		end
	elseif tab == "col" then
		for _, c in Config.COLLECTIONS do
			local have = S.col[c.id] or {}
			local items = {}
			for _, it in Config.ITEMS do
				if it.col == c.id then table.insert(items, it) end
			end
			local done = has(S.colDone, c.id)
			local lines = {}
			for _, it in items do
				table.insert(lines, if has(have, it.id) then "<font color='#5ee37a'>✓ " .. it.name .. "</font>" else ("<font color='#%s'>○ %s</font>"):format(RARITY[it.r].color:ToHex(), it.name))
			end
			say(("%s <b>%s</b>  %d/%d\nБонус: %s · награда %s\n%s"):format(if done then "✅" else "🏆", c.name, #have, #items, c.bonusText, fmt(c.reward), table.concat(lines, "   ")))
		end
		muted("Коллекционные предметы кладутся в коллекцию из вкладки «Рюкзак».")
	elseif tab == "quests" then
		for id, q in S.quests do
			local n = NPC_BY_ID[id]
			local locked = not S.unlocked[q.d]
			local desc = if locked then "Район закрыт" elseif q.text then q.text .. " — " .. q.prog .. (if q.ready then " · ГОТОВО!" else "") else "Зайдите за новым заданием"
			row(n.icon .. " " .. n.name .. " · " .. DISTRICTS[q.d].name, desc, if q.reward then fmt(q.reward) else nil, {})
		end
	elseif tab == "market" then
		muted("Цены меняются каждый игровой день. Продавайте, когда категория в плюсе.")
		for _, c in Config.CATEGORY_ORDER do
			local m = S.market[c] or 1
			local col = if m > 1.05 then "#5ee37a" elseif m < 0.95 then "#ff5a5a" else "#eef2f6"
			row(Config.CATEGORIES[c], "", ("<font color='%s'>×%.2f</font>"):format(col, m), {})
		end
		say("💰 Михалыч (Окраина) — базовая цена\n🏺 Вера (Центр) — +10%, редкие и выше +30%\n🔩 Толик (Промзона) — металл и хлам +50%\n🌙 Тень (Промзона, ночью) — всё +40%\n💎 Изабелла (Холмы) — драгоценности, антиквариат, искусство +60%")
	elseif tab == "map" then
		local holder = add(new("Frame", { BackgroundColor3 = Color3.fromRGB(11, 14, 18), Size = UDim2.new(1, 0, 0, 520), ClipsDescendants = true }, { corner(12) }))
		local scale = 500 / (HALF * 2 + 120)
		local inner = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(500, 500), Parent = holder })
		local tiles = buildStaticMap(inner, scale)
		for d = 1, 4 do
			tiles[d].BackgroundTransparency = if S.unlocked[d] then 0.75 else 0.92
			local c = tiles[d].AbsoluteSize
			local _ = c
			label({ Text = DISTRICTS[d].name .. (if S.unlocked[d] then "" else " 🔒"), Font = FONT_B, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 0.2), Position = UDim2.fromScale(0, 0.4), TextColor3 = if S.unlocked[d] then DISTRICTS[d].color else BAD, ZIndex = 25, Parent = tiles[d] })
		end
		local store = {}
		refreshNpcIcons(inner, scale, store)
		if S.plot then
			label({ Text = "🏠", TextSize = 18, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(22, 22), TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset((S.plot.x + HALF + 60) * scale, (S.plot.z + HALF + 60) * scale), ZIndex = 25, Parent = inner })
		end
		for _, m in (workspace:FindFirstChild("LootCityLoot") or Instance.new("Folder")):GetChildren() do
			if m:GetAttribute("Special") and m.PrimaryPart then
				local p = m.PrimaryPart.Position
				new("Frame", { BackgroundColor3 = RARITY[m:GetAttribute("Rarity") or 1].color, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), Position = UDim2.fromOffset((p.X + HALF + 60) * scale, (p.Z + HALF + 60) * scale), ZIndex = 25, Parent = inner }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }), new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2 }) })
			end
		end
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			label({ Text = "▲", Font = FONT_B, TextSize = 18, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(20, 20), TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset((hrp.Position.X + HALF + 60) * scale, (hrp.Position.Z + HALF + 60) * scale), Rotation = -math.deg(math.atan2(-hrp.CFrame.LookVector.X, -hrp.CFrame.LookVector.Z)), ZIndex = 26, Parent = inner })
		end
		bigMap = holder
		for _, d in holder:GetDescendants() do
			if d:IsA("GuiObject") and d.ZIndex < 24 then d.ZIndex = 24 end
		end
	elseif tab == "stats" then
		local king = S.home == 6 and #S.colDone == #Config.COLLECTIONS and S.unlocked[1] and S.unlocked[2] and S.unlocked[3] and S.unlocked[4]
		say(if king then "👑 Вы — Король Loot City! Все районы, все коллекции и особняк." else "Цель: открыть все районы, собрать все коллекции и построить особняк — стать Королём города.")
		local nUn = 0
		for d = 1, 4 do
			if S.unlocked[d] then nUn += 1 end
		end
		for _, r in {
			{ "Всего заработано", fmt(S.earned) }, { "Найдено предметов", S.stats.found }, { "Продано предметов", S.stats.sold },
			{ "Самая дорогая сделка", fmt(S.stats.best) }, { "Легендарных находок", S.stats.legend }, { "Дом", Config.HOME_STAGES[S.home].name },
			{ "Престиж", S.prestige }, { "Пассивный доход", fmt(S.ppm) .. "/мин" }, { "Открыто районов", nUn .. "/4" }, { "Коллекций собрано", #S.colDone .. "/" .. #Config.COLLECTIONS },
		} do
			row(r[1], "", tostring(r[2]), {})
		end
	end
end

renderModal = function()
	if not Modal.open or not S then return end
	clearBody()
	order = 0
	bigMap = nil
	headMoney.Text = fmt(S.money)
	headBag.Text = ("🎒 %d/%d"):format(S.used, S.slots)
	if Modal.kind == "npc" then renderNPC() else renderPhone() end
end

local function openModal(kind, npc, greet, tab)
	Modal.open, Modal.kind, Modal.npc, Modal.greet = true, kind, npc, greet or ""
	if kind == "npc" then
		local tabs = npcTabs(npc)
		Modal.tab = tabs[1][1]
		if Modal.tab == "quest" then act("quest", { npc = npc }) end
	else
		Modal.tab = tab or "inv"
	end
	modal.Visible = true
	renderModal()
end
local function closeModal()
	Modal.open = false
	modal.Visible = false
end
closeBtn.MouseButton1Click:Connect(closeModal)

button("📱 Телефон [Tab]", false, function()
	if Modal.open then closeModal() else openModal("phone") end
end, { BackgroundColor3 = GLASS, BackgroundTransparency = 0.3, Parent = btnBar })
button("🛵 Транспорт [V]", false, function()
	if not S then return end
	if S.vehicle then act("ride", { id = nil }) return end
	for k = #Config.VEHICLES, 1, -1 do
		local v = Config.VEHICLES[k]
		if has(S.vehicles, v.id) then act("ride", { id = v.id }) return end
	end
	toast("У вас пока нет транспорта. Загляните к механику Гоше.", "#9aa6b2")
end, { BackgroundColor3 = GLASS, BackgroundTransparency = 0.3, Parent = btnBar })

-- ============ server pushes ============
PushRE.OnClientEvent:Connect(function(msg)
	if msg.type == "state" then
		S = msg.state
		if Modal.open and Modal.tab ~= "map" then renderModal() end
	elseif msg.type == "toast" then
		toast(msg.text, msg.color)
	elseif msg.type == "banner" then
		showBanner(msg.title, msg.sub)
	elseif msg.type == "npc" then
		openModal("npc", msg.id, msg.greet)
	elseif msg.type == "sfx" then
		sfx(msg.id, if msg.id == "pickup" then 0.8 + (msg.r or 1) * 0.15 elseif msg.id == "legend" then 1.6 else 1)
	end
end)

-- ============ input: sprint, vehicle, phone ============
local stamina = 1
local sprinting = false
UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.Tab then
		if Modal.open then closeModal() else openModal("phone") end
		return
	end
	if processed then return end
	if input.KeyCode == Enum.KeyCode.M then
		if Modal.open and Modal.tab == "map" then closeModal() else openModal("phone", nil, nil, "map") end
	elseif input.KeyCode == Enum.KeyCode.V then
		if not S then return end
		if S.vehicle then act("ride", { id = nil }) return end
		for k = #Config.VEHICLES, 1, -1 do
			local v = Config.VEHICLES[k]
			if has(S.vehicles, v.id) then act("ride", { id = v.id }) return end
		end
		toast("У вас пока нет транспорта. Загляните к механику Гоше.", "#9aa6b2")
	elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		sprinting = true
	elseif input.KeyCode == Enum.KeyCode.Escape and Modal.open then
		closeModal()
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		sprinting = false
	end
end)

-- ============ environment: night lights, rain, wet roads ============
local warm = { Color3.fromRGB(255, 205, 140), Color3.fromRGB(255, 225, 170), Color3.fromRGB(230, 236, 255), Color3.fromRGB(255, 190, 120) }
local nightState = nil
-- deterministic "is this window lit" from its position, so it works for windows added later too
local function litIndex(p: BasePart): number?
	local v = p.Position
	local h = math.abs(math.floor(v.X * 7.13 + v.Y * 3.71 + v.Z * 5.37)) % 100
	return if h < 42 then (h % 4) + 1 else nil
end
local function setNight(night)
	if nightState == night then return end
	nightState = night
	for _, w in CollectionService:GetTagged("LC_Window") do
		local li = litIndex(w)
		if li then
			w.Material = if night then Enum.Material.Neon else Enum.Material.Glass
			w.Color = if night then warm[li] else Color3.fromRGB(30, 40, 48)
			w.Transparency = if night then 0.25 else 0
		end
	end
	for _, c in CollectionService:GetTagged("LC_TowerCore") do
		if c.Name ~= "Skyline" then
			c.Material = if night then Enum.Material.Neon else Enum.Material.SmoothPlastic
			c.Color = if night then Color3.fromRGB(120, 100, 70) else Color3.fromRGB(26, 28, 32)
		end
	end
	for _, b in CollectionService:GetTagged("LC_LampBulb") do
		b.Material = if night then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
	for _, h in CollectionService:GetTagged("LC_Headlight") do
		h.Material = if night then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
end

local lampLights = {}
local function scanLamps()
	table.clear(lampLights)
	for _, b in CollectionService:GetTagged("LC_LampBulb") do
		local l = b:FindFirstChildOfClass("SpotLight")
		if l then table.insert(lampLights, { light = l, pos = b.Position }) end
	end
end
scanLamps()

-- rain: emitter on an invisible part that follows the camera
local rainPart = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Transparency = 1, Size = Vector3.new(160, 1, 160), Parent = workspace })
local rain = new("ParticleEmitter", {
	Enabled = false, Rate = 1400, Lifetime = NumberRange.new(0.9, 1.1), Speed = NumberRange.new(110, 130),
	EmissionDirection = Enum.NormalId.Bottom, Size = NumberSequence.new(0.08), LightEmission = 0.2,
	Transparency = NumberSequence.new(0.35), Color = ColorSequence.new(Color3.fromRGB(190, 205, 220)),
	Orientation = Enum.ParticleOrientation.FacingCameraWorldUp, Squash = NumberSequence.new(12), Parent = rainPart,
})
local rainSound = new("Sound", { SoundId = "rbxasset://sounds/action_falling.mp3", Volume = 0, Looped = true, Parent = SoundService })
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
local baseHaze = atmosphere and atmosphere.Haze or 1
local baseDensity = atmosphere and atmosphere.Density or 0.3
local roads = CollectionService:GetTagged("LC_Road")
local sidewalks = CollectionService:GetTagged("LC_Sidewalk")
local wet = 0
local function applyWet(w)
	for _, r in roads do
		r.Reflectance = 0.22 * w
		r.Color = Color3.fromRGB(58, 58, 60):Lerp(Color3.fromRGB(32, 34, 38), w)
	end
	for _, s in sidewalks do
		s.Reflectance = 0.08 * w
	end
end

-- ============ local traffic (client-side only, purely visual) ============
local traffic = {}
local trafficFolder = new("Folder", { Name = "LC_Traffic", Parent = workspace })
local function makeCar(color)
	local m = Instance.new("Model")
	local function p(size, cf, material, c, props)
		local x = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Size = size, CFrame = cf, Material = material, Color = c })
		for k, v in props or {} do (x :: any)[k] = v end
		x.Parent = m
		return x
	end
	local root = p(Vector3.new(7, 2.6, 15.5), CFrame.new(0, 2.4, 0), Enum.Material.SmoothPlastic, color, { Reflectance = 0.18 })
	p(Vector3.new(6.4, 2.6, 8), CFrame.new(0, 4.9, 0.8), Enum.Material.Glass, Color3.fromRGB(20, 26, 32), { Reflectance = 0.3 })
	p(Vector3.new(6.5, 0.4, 7), CFrame.new(0, 6.3, 0.9), Enum.Material.SmoothPlastic, color, { Reflectance = 0.18 })
	for _, o in { { 3.3, 5 }, { -3.3, 5 }, { 3.3, -5 }, { -3.3, -5 } } do
		p(Vector3.new(1.2, 3, 3), CFrame.new(o[1], 1.5, o[2]), Enum.Material.Fabric, Color3.fromRGB(20, 20, 20), { Shape = Enum.PartType.Cylinder })
	end
	local hl = p(Vector3.new(5.6, 0.6, 0.2), CFrame.new(0, 3, -7.8), Enum.Material.Neon, Color3.fromRGB(255, 244, 220))
	local sl = new("SpotLight", { Face = Enum.NormalId.Front, Range = 40, Brightness = 2, Angle = 70, Enabled = false, Parent = hl })
	p(Vector3.new(5.6, 0.6, 0.2), CFrame.new(0, 3.2, 7.8), Enum.Material.Neon, Color3.fromRGB(200, 20, 20))
	m.PrimaryPart = root
	m.Parent = trafficFolder
	return m, sl
end
do
	local palette = { Color3.fromRGB(242, 242, 242), Color3.fromRGB(17, 17, 17), Color3.fromRGB(138, 143, 150), Color3.fromRGB(14, 42, 85), Color3.fromRGB(176, 24, 24), Color3.fromRGB(200, 200, 200) }
	local tr = Random.new(99)
	for k = 1, 16 do
		local q = (k % 4) + 1
		local sx = if q == 1 or q == 3 then -1 else 1
		local sz = if q >= 3 then -1 else 1
		local horiz = tr:NextNumber() < 0.5
		local lines = if (if horiz then sz else sx) < 0 then { 0, 1, 2 } else { 4, 5, 6 }
		local model, light = makeCar(palette[tr:NextInteger(1, #palette)])
		local c = { m = model, light = light, sx = sx, sz = sz, horiz = horiz, line = lines[tr:NextInteger(1, 3)], dir = if tr:NextNumber() < 0.5 then 1 else -1, speed = 40 + tr:NextNumber() * 20, cur = 0, pos = 0 }
		local s = if horiz then sx else sz
		c.pos = if s < 0 then -HALF + tr:NextNumber() * (HALF - 40) else 40 + tr:NextNumber() * (HALF - 40)
		table.insert(traffic, c)
	end
end
local function trafficRange(c)
	local s = if c.horiz then c.sx else c.sz
	return if s < 0 then -HALF - 10 else 30, if s < 0 then -30 else HALF + 10
end
local CELL = Config.CELL
local function updateTraffic(dt, ppos)
	for _, c in traffic do
		local base = Config.roadLine(c.line)
		local lane = 7 * c.dir
		local x = if c.horiz then c.pos else base - lane
		local z = if c.horiz then base + lane else c.pos
		local ax = if c.horiz then x + c.dir * 18 else x
		local az = if c.horiz then z else z + c.dir * 18
		local dp = if ppos then (Vector3.new(ax, ppos.Y, az) - ppos).Magnitude else 999
		local target = if dp < 14 then 0 else c.speed
		c.cur += (target - c.cur) * math.min(1, dt * (if target < c.cur then 5 else 0.8))
		local prev = c.pos
		c.pos += c.dir * c.cur * dt
		local lo, hi = trafficRange(c)
		if c.pos > hi then c.pos = hi; c.dir = -1 end
		if c.pos < lo then c.pos = lo; c.dir = 1 end
		local k0 = math.floor((prev + HALF) / CELL)
		local k1 = math.floor((c.pos + HALF) / CELL)
		if k0 ~= k1 then
			local kk = if c.dir > 0 then k1 else k0
			local other = if c.horiz then c.sx else c.sz
			local valid = kk >= 0 and kk <= Config.N and kk ~= Config.N / 2 and (if other < 0 then kk < Config.N / 2 else kk > Config.N / 2)
			if valid and math.random() < 0.4 then
				local oldBase = Config.roadLine(c.line)
				c.horiz = not c.horiz
				c.line = kk
				c.pos = oldBase
				c.dir = if math.random() < 0.5 then 1 else -1
				local lo2, hi2 = trafficRange(c)
				if c.pos + c.dir * 40 > hi2 then c.dir = -1 end
				if c.pos + c.dir * 40 < lo2 then c.dir = 1 end
			end
		end
		base = Config.roadLine(c.line)
		lane = 7 * c.dir
		x = if c.horiz then c.pos else base - lane
		z = if c.horiz then base + lane else c.pos
		local dirv = if c.horiz then Vector3.new(c.dir, 0, 0) else Vector3.new(0, 0, c.dir)
		local p = Vector3.new(x, 0, z)
		c.m:PivotTo(CFrame.lookAt(p, p + dirv))
	end
end

-- ============ barriers (local collision for unlocked districts) ============
local function updateBarriers()
	if not S then return end
	local map = workspace:FindFirstChild("LootCityMap")
	local folder = map and map:FindFirstChild("Barriers")
	if not folder then return end
	for _, b in folder:GetChildren() do
		local open = S.unlocked[b:GetAttribute("A")] and S.unlocked[b:GetAttribute("B")]
		for _, p in b:GetChildren() do
			if p:IsA("BasePart") then
				p.CanCollide = not open
				p.LocalTransparencyModifier = if open then 1 else 0
			end
		end
	end
end

-- ============ main loop ============
local acc, slowAcc = 0, 0
local lastDistrict = 0
RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	local ch = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local ppos = hrp and hrp.Position

	-- speed / stamina / FOV
	if hum and S then
		local veh = nil
		for _, v in Config.VEHICLES do
			if v.id == S.vehicle then veh = v end
		end
		local moving = hum.MoveDirection.Magnitude > 0.1
		local sp = sprinting and moving and stamina > 0.02 and not veh
		if sp then
			stamina = math.max(0, stamina - dt / S.stamina)
		else
			stamina = math.min(1, stamina + dt * 0.18)
		end
		local ws = 16 * S.speed * (if veh then veh.speed else 1) * (if sp then 1.6 else 1)
		if veh and sprinting then ws *= 1.25 end
		hum.WalkSpeed = ws
		hum.JumpPower = if veh then 0 else 50
		hum.UseJumpPower = true
		local speedNow = hrp.AssemblyLinearVelocity.Magnitude
		cam.FieldOfView += ((70 + math.clamp((speedNow - 20) * 0.25, 0, 20)) - cam.FieldOfView) * math.min(1, dt * 3)
		stamFill.Size = UDim2.fromScale(stamina, 1)
		stamBar.Visible = stamina < 0.99
	end

	updateTraffic(dt, ppos)

	acc += dt
	if acc < 0.1 then return end
	acc = 0
	if not S then return end

	-- HUD
	moneyL.Text = fmt(S.money)
	incomeL.Text = if S.ppm > 0 then ("+%s/мин"):format(fmt(S.ppm)) else ""
	bagL.Text = ("🎒 %d/%d"):format(S.used, S.slots)
	local t = Lighting.ClockTime
	local night = t < 6.3 or t > 19.2
	local d = if ppos then Config.districtOf(ppos.X, ppos.Z) else 1
	distL.Text = "📍 " .. DISTRICTS[d].name
	distL.TextColor3 = DISTRICTS[d].color
	if d ~= lastDistrict and lastDistrict ~= 0 and not S.unlocked[d] then
		toast(("🔒 Район «%s» закрыт. Пропуск — в мэрии (%s)."):format(DISTRICTS[d].name, fmt(DISTRICTS[d].cost)), "#ff5a5a")
	end
	lastDistrict = d
	local raining = workspace:GetAttribute("LC_Rain") == true
	clockL.Text = ("%s День %d · %02d:%02d"):format(if raining then "🌧️" elseif night then "🌙" else "☀️", S.day, math.floor(t), math.floor((t % 1) * 60))
	for _, c in fxFrame:GetChildren() do
		if c:IsA("TextLabel") then c:Destroy() end
	end
	for _, e in S.effects do
		new("TextLabel", { BackgroundColor3 = ACC, BackgroundTransparency = 0.82, Text = ("  %s · %dс  "):format(e.name, e.t), Font = FONT_B, TextSize = 12, TextColor3 = Color3.new(1, 1, 1), Size = UDim2.fromOffset(0, 22), AutomaticSize = Enum.AutomaticSize.X, Parent = fxFrame }, { corner(8) })
	end

	-- minimap
	if ppos then
		local look = hrp.CFrame.LookVector
		arrow.Rotation = -math.deg(math.atan2(-look.X, -look.Z))
		mapWorld.Position = UDim2.fromOffset(MAPSIZE / 2 - (ppos.X + HALF + 60) * MAPSCALE, MAPSIZE / 2 - (ppos.Z + HALF + 60) * MAPSCALE)
		for dd = 1, 4 do
			districtTiles[dd].BackgroundTransparency = if S.unlocked[dd] then 0.8 else 0.9
			districtTiles[dd].BackgroundColor3 = if S.unlocked[dd] then DISTRICTS[dd].color else BAD
		end
		if S.plot then
			homeIcon.Visible = true
			homeIcon.Position = m2p(S.plot.x, S.plot.z)
		end
		-- loot dots + beams visibility
		local lootF = workspace:FindFirstChild("LootCityLoot")
		local n = 0
		if lootF then
			for _, m in lootF:GetChildren() do
				local pp = m.PrimaryPart
				if pp then
					local dist = (pp.Position - ppos).Magnitude
					local special = m:GetAttribute("Special")
					local beam = m:FindFirstChild("Beam")
					if beam then beam.LocalTransparencyModifier = if dist < S.detect or special then 0 else 1 end
					if dist < S.detect or special then
						n += 1
						local dot = dotPool[n]
						if not dot then
							dot = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = 4, Parent = mapWorld }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
							dotPool[n] = dot
						end
						dot.Visible = true
						dot.BackgroundColor3 = RARITY[m:GetAttribute("Rarity") or 1].color
						dot.Size = if special then UDim2.fromOffset(10, 10) else UDim2.fromOffset(6, 6)
						dot.Position = m2p(pp.Position.X, pp.Position.Z)
					end
				end
			end
		end
		for k = n + 1, #dotPool do
			dotPool[k].Visible = false
		end
	end

	slowAcc += 0.1
	if slowAcc >= 1 then
		slowAcc = 0
		if #lampLights == 0 then
			scanLamps()
			roads = CollectionService:GetTagged("LC_Road")
			sidewalks = CollectionService:GetTagged("LC_Sidewalk")
			nightState = nil
		end
		setNight(night)
		updateBarriers()
		if #npcIcons == 0 or math.random() < 0.1 then refreshNpcIcons(mapWorld, MAPSCALE, npcIcons) end
		-- street lights near the player, only at night
		if ppos then
			for _, l in lampLights do
				l.light.Enabled = night and (l.pos - ppos).Magnitude < 320
			end
		end
		for _, c in traffic do
			c.light.Enabled = night and ppos ~= nil and (c.m:GetPivot().Position - ppos).Magnitude < 250
		end
		-- rain
		rain.Enabled = raining
		rainSound.Volume = if raining then 0.35 else 0
		if raining and not rainSound.IsPlaying then rainSound:Play() end
		local target = if raining then 1 else 0
		wet += (target - wet) * (if raining then 0.08 else 0.02)
		applyWet(wet)
		if atmosphere then
			atmosphere.Haze = baseHaze + wet * 2
			atmosphere.Density = baseDensity + wet * 0.15
		end
	end
	if raining and cam then
		rainPart.CFrame = CFrame.new(cam.CFrame.Position + Vector3.new(0, 60, 0))
	end
end)

local _ = TweenService
print("[LootCity] client ready")
]========])

	-- ===== realistic lighting =====
	print("[LootCity] настройка освещения…")
	for _, c in Lighting:GetChildren() do
		if c:IsA("PostEffect") or c:IsA("Sky") or c:IsA("Atmosphere") or c:IsA("Clouds") then c:Destroy() end
	end
	pcall(function() Lighting.Technology = Enum.Technology.Future end)
	Lighting.Brightness = 3
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.15
	Lighting.Ambient = Color3.fromRGB(38, 40, 46)
	Lighting.OutdoorAmbient = Color3.fromRGB(112, 118, 128)
	Lighting.ExposureCompensation = 0.1
	Lighting.GeographicLatitude = 38
	Lighting.ClockTime = 9
	local function make(class, props)
		local o = Instance.new(class)
		for k, v in props do o[k] = v end
		o.Parent = Lighting
		return o
	end
	make("Atmosphere", { Density = 0.3, Offset = 0.22, Color = Color3.fromRGB(199, 211, 224), Decay = Color3.fromRGB(104, 112, 124), Glare = 0.4, Haze = 1.4 })
	make("Sky", { SunAngularSize = 12, MoonAngularSize = 9, StarCount = 3000, CelestialBodiesShown = true })
	make("BloomEffect", { Intensity = 0.55, Size = 28, Threshold = 1.35 })
	make("ColorCorrectionEffect", { Brightness = 0.02, Contrast = 0.14, Saturation = 0.08, TintColor = Color3.fromRGB(255, 250, 244) })
	make("SunRaysEffect", { Intensity = 0.05, Spread = 0.7 })
	make("DepthOfFieldEffect", { FarIntensity = 0.1, FocusDistance = 60, InFocusRadius = 160, NearIntensity = 0 })
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.55
	clouds.Density = 0.6
	clouds.Parent = workspace.Terrain
	pcall(function() workspace.StreamingEnabled = false end)

	-- ===== build the city right in the editor so it is saved with the place =====
	print("[LootCity] строим город (это займёт несколько секунд)…")
	local CB = require(cityBuilder)
	CB.Build(CB.Plan())
	pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("Loot City installed") end)
end)
if ok then
	print("✅ Loot City установлен! Нажмите Play (F5). Чтобы сохранения работали в опубликованной игре — Game Settings → Security → Enable Studio Access to API Services.")
else
	warn("❌ Ошибка установки Loot City: " .. tostring(err))
end
