// PROTOTYPE - NOT FOR PRODUCTION
// All gameplay data / tuning in one place.

export const RARITY = [
  { id: 0, name: 'Обычный', color: '#c9ced6', hex: 0xc9ced6, beam: 0.18 },
  { id: 1, name: 'Необычный', color: '#5ee37a', hex: 0x5ee37a, beam: 0.35 },
  { id: 2, name: 'Редкий', color: '#4aa8ff', hex: 0x4aa8ff, beam: 0.55 },
  { id: 3, name: 'Эпический', color: '#b26bff', hex: 0xb26bff, beam: 0.8 },
  { id: 4, name: 'Легендарный', color: '#ffb52e', hex: 0xffb52e, beam: 1.1 },
];

export const CATEGORIES = {
  junk: 'Хлам', metal: 'Металл', electronics: 'Электроника', jewelry: 'Драгоценности',
  antiques: 'Антиквариат', art: 'Искусство', cash: 'Наличные',
};

// shape: bottle, can, box, phone, laptop, toolbox, coin, bar, gem, frame, statue, vase, case, watch, ring,
//        camera, radio, record, console, necklace, bag, tire, chest, headphones, gpu
export const ITEMS = [
  // common
  { id: 'bottle', name: 'Пустая бутылка', r: 0, v: 4, cat: 'junk', shape: 'bottle', slots: 1 },
  { id: 'can', name: 'Алюминиевая банка', r: 0, v: 3, cat: 'metal', shape: 'can', slots: 1 },
  { id: 'cardboard', name: 'Коробка с барахлом', r: 0, v: 9, cat: 'junk', shape: 'box', slots: 2 },
  { id: 'scrap', name: 'Медный провод', r: 0, v: 14, cat: 'metal', shape: 'coil', slots: 1 },
  { id: 'oldphone', name: 'Разбитый телефон', r: 0, v: 12, cat: 'electronics', shape: 'phone', slots: 1 },
  { id: 'trashbag', name: 'Пакет со всячиной', r: 0, v: 7, cat: 'junk', shape: 'bag', slots: 2 },
  { id: 'tire', name: 'Старая покрышка', r: 0, v: 11, cat: 'junk', shape: 'tire', slots: 2 },
  // uncommon
  { id: 'headphones', name: 'Наушники', r: 1, v: 45, cat: 'electronics', shape: 'headphones', slots: 1 },
  { id: 'toolbox', name: 'Ящик с инструментами', r: 1, v: 70, cat: 'metal', shape: 'toolbox', slots: 2 },
  { id: 'wallet', name: 'Кожаный кошелёк', r: 1, v: 60, cat: 'cash', shape: 'wallet', slots: 1 },
  { id: 'radio', name: 'Транзисторный радиоприёмник', r: 1, v: 55, cat: 'electronics', shape: 'radio', slots: 1 },
  { id: 'silverspoon', name: 'Серебряная ложка', r: 1, v: 80, cat: 'metal', shape: 'spoon', slots: 1 },
  // rare
  { id: 'laptop', name: 'Ноутбук', r: 2, v: 260, cat: 'electronics', shape: 'laptop', slots: 2 },
  { id: 'gpu', name: 'Видеокарта', r: 2, v: 380, cat: 'electronics', shape: 'gpu', slots: 1 },
  { id: 'cashstack', name: 'Пачка купюр', r: 2, v: 300, cat: 'cash', shape: 'cash', slots: 1 },
  { id: 'silverbar', name: 'Серебряный слиток', r: 2, v: 420, cat: 'metal', shape: 'bar', slots: 1, mat: 'silver' },
  // epic
  { id: 'goldwatch', name: 'Золотые часы', r: 3, v: 1300, cat: 'jewelry', shape: 'watch', slots: 1, col: 'jewels' },
  { id: 'briefcase', name: 'Кейс с деньгами', r: 3, v: 1800, cat: 'cash', shape: 'case', slots: 2 },
  { id: 'goldbar', name: 'Золотой слиток', r: 3, v: 1600, cat: 'metal', shape: 'bar', slots: 1, mat: 'gold' },
  // legendary
  { id: 'diamond', name: 'Бриллиант «Звезда Севера»', r: 4, v: 9000, cat: 'jewelry', shape: 'gem', slots: 1, col: 'jewels', mat: 'diamond' },
  { id: 'faberge', name: 'Императорское яйцо', r: 4, v: 12000, cat: 'antiques', shape: 'egg', slots: 1 },

  // ---- collections ----
  // coins
  { id: 'c_ruble', name: 'Царский рубль', r: 2, v: 350, cat: 'antiques', shape: 'coin', slots: 1, col: 'coins', mat: 'silver' },
  { id: 'c_denar', name: 'Римский денарий', r: 2, v: 420, cat: 'antiques', shape: 'coin', slots: 1, col: 'coins', mat: 'silver' },
  { id: 'c_dublon', name: 'Испанский дублон', r: 3, v: 1100, cat: 'antiques', shape: 'coin', slots: 1, col: 'coins', mat: 'gold' },
  { id: 'c_dollar', name: 'Серебряный доллар 1804', r: 3, v: 1400, cat: 'antiques', shape: 'coin', slots: 1, col: 'coins', mat: 'silver' },
  { id: 'c_byzant', name: 'Византийский солид', r: 4, v: 4200, cat: 'antiques', shape: 'coin', slots: 1, col: 'coins', mat: 'gold' },
  // retro tech
  { id: 'r_camera', name: 'Плёночная камера', r: 1, v: 120, cat: 'electronics', shape: 'camera', slots: 1, col: 'retro' },
  { id: 'r_cassette', name: 'Кассетный плеер', r: 1, v: 95, cat: 'electronics', shape: 'radio', slots: 1, col: 'retro' },
  { id: 'r_vinyl', name: 'Редкая пластинка', r: 2, v: 280, cat: 'art', shape: 'record', slots: 1, col: 'retro' },
  { id: 'r_console', name: 'Карманная консоль', r: 2, v: 340, cat: 'electronics', shape: 'console', slots: 1, col: 'retro' },
  { id: 'r_phone', name: 'Дисковый телефон', r: 3, v: 900, cat: 'antiques', shape: 'rotary', slots: 2, col: 'retro' },
  // jewels
  { id: 'j_ring', name: 'Кольцо с рубином', r: 3, v: 1500, cat: 'jewelry', shape: 'ring', slots: 1, col: 'jewels' },
  { id: 'j_pearl', name: 'Жемчужное ожерелье', r: 3, v: 1900, cat: 'jewelry', shape: 'necklace', slots: 1, col: 'jewels' },
  { id: 'j_emerald', name: 'Изумруд', r: 4, v: 6000, cat: 'jewelry', shape: 'gem', slots: 1, col: 'jewels', mat: 'emerald' },
  // art
  { id: 'a_paint', name: 'Картина маслом', r: 3, v: 2200, cat: 'art', shape: 'frame', slots: 2, col: 'art' },
  { id: 'a_statue', name: 'Бронзовая статуэтка', r: 3, v: 1700, cat: 'art', shape: 'statue', slots: 2, col: 'art' },
  { id: 'a_vase', name: 'Фарфоровая ваза', r: 2, v: 600, cat: 'art', shape: 'vase', slots: 2, col: 'art' },
  { id: 'a_box', name: 'Антикварная шкатулка', r: 2, v: 520, cat: 'antiques', shape: 'chest', slots: 1, col: 'art' },
  { id: 'a_master', name: 'Утерянный шедевр', r: 4, v: 15000, cat: 'art', shape: 'frame', slots: 2, col: 'art' },
];
export const ITEM_BY_ID = Object.fromEntries(ITEMS.map((i) => [i.id, i]));

export const COLLECTIONS = [
  { id: 'coins', name: 'Старинные монеты', bonusText: '+10% к цене продажи всех предметов', reward: 5000 },
  { id: 'retro', name: 'Ретро-техника', bonusText: '+4 места в рюкзаке', reward: 3000 },
  { id: 'jewels', name: 'Драгоценности', bonusText: '+25% к шансу редкой добычи', reward: 15000 },
  { id: 'art', name: 'Искусство', bonusText: '×1.5 пассивный доход', reward: 25000 },
];

// Districts: quadrant layout. 0 = SW start
export const DISTRICTS = [
  { id: 0, name: 'Окраина', cost: 0, lootMult: 1.0, rarityBoost: 0, color: '#c98b4a', desc: 'Старые кирпичные дома, гаражи и пустыри.' },
  { id: 1, name: 'Центр', cost: 3000, lootMult: 1.6, rarityBoost: 0.6, color: '#4aa8ff', desc: 'Стеклянные небоскрёбы, офисы и магазины.' },
  { id: 2, name: 'Промзона', cost: 15000, lootMult: 2.4, rarityBoost: 1.2, color: '#9aa1a8', desc: 'Склады, контейнеры, металлолом. Ночью — чёрный рынок.' },
  { id: 3, name: 'Золотые холмы', cost: 75000, lootMult: 4.0, rarityBoost: 2.2, color: '#ffb52e', desc: 'Виллы, бассейны и элитные башни.' },
];

export const UPGRADES = [
  { id: 'backpack', name: 'Рюкзак побольше', desc: '+3 места в рюкзаке', base: 150, growth: 1.85, max: 10 },
  { id: 'shoes', name: 'Беговые кроссовки', desc: '+8% к скорости ходьбы', base: 120, growth: 1.7, max: 8 },
  { id: 'detector', name: 'Сканер добычи', desc: '+15 м к радиусу обнаружения', base: 250, growth: 1.9, max: 8 },
  { id: 'luck', name: 'Талисман удачи', desc: '+12% к шансу редких находок', base: 400, growth: 2.0, max: 10 },
  { id: 'stamina', name: 'Выносливость', desc: '+30% к запасу бега', base: 100, growth: 1.6, max: 6 },
  { id: 'trade', name: 'Навык торговли', desc: '+6% к цене продажи', base: 300, growth: 1.95, max: 10 },
];
export const upgradeCost = (u, lvl) => Math.round(u.base * Math.pow(u.growth, lvl));

export const VEHICLES = [
  { id: 'scooter', name: 'Самокат', cost: 600, speed: 1.6, desc: 'Тихий и шустрый.' },
  { id: 'bike', name: 'Велосипед', cost: 2200, speed: 2.1, desc: 'Классика городских улиц.' },
  { id: 'moto', name: 'Мотоцикл', cost: 14000, speed: 3.0, desc: 'Рёв мотора и ветер в лицо.' },
  { id: 'car', name: 'Спорткар', cost: 65000, speed: 4.3, desc: 'Быстрее всех в городе.' },
];

export const HOME_STAGES = [
  { name: 'Пустой участок', cost: 0, prestige: 0 },
  { name: 'Палатка', cost: 250, prestige: 1 },
  { name: 'Строительный вагончик', cost: 2500, prestige: 3 },
  { name: 'Кирпичный дом', cost: 16000, prestige: 8 },
  { name: 'Двухэтажный коттедж', cost: 70000, prestige: 20 },
  { name: 'Особняк', cost: 300000, prestige: 60 },
];

export const DECOR = [
  { id: 'fence', name: 'Деревянный забор', cost: 400, prestige: 1, needStage: 1 },
  { id: 'lamps', name: 'Садовые фонари', cost: 700, prestige: 1, needStage: 1 },
  { id: 'garden', name: 'Сад и деревья', cost: 1500, prestige: 2, needStage: 2 },
  { id: 'bench', name: 'Беседка со скамейкой', cost: 3000, prestige: 3, needStage: 2 },
  { id: 'garage', name: 'Гараж', cost: 9000, prestige: 5, needStage: 3 },
  { id: 'pool', name: 'Бассейн', cost: 30000, prestige: 10, needStage: 4 },
  { id: 'fountain', name: 'Фонтан', cost: 45000, prestige: 12, needStage: 4 },
  { id: 'statue', name: 'Золотая статуя', cost: 120000, prestige: 25, needStage: 5 },
];

export const BUSINESSES = [
  { id: 'vending', name: 'Автомат с газировкой', cost: 900, income: 12, max: 5 },
  { id: 'laundry', name: 'Прачечная', cost: 6000, income: 70, max: 5 },
  { id: 'carwash', name: 'Автомойка', cost: 24000, income: 260, max: 5 },
  { id: 'parking', name: 'Платная парковка', cost: 80000, income: 800, max: 5 },
  { id: 'market', name: 'Мини-маркет', cost: 220000, income: 2100, max: 5 },
  { id: 'tower', name: 'Бизнес-центр', cost: 900000, income: 8000, max: 3 },
];
// income is $ per in-game minute (= real minute)
export const businessCost = (b, owned) => Math.round(b.cost * Math.pow(1.45, owned));

export const DAY_LENGTH = 720; // seconds per full day

export const START = { money: 20, slots: 6 };
