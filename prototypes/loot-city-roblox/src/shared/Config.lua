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
