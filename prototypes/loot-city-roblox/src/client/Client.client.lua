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
		ws *= (player:GetAttribute("LC_AdminSpeed") or 1)
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
