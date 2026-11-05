--[[
	UI — весь интерфейс игры, собранный из кода.

	HUD (свет, ранг, Маяк, события), магазин (улучшения / духи / донат),
	окно вклада в Маяк, диалоги с эффектом печатной машинки,
	всплывающие уведомления и большие баннеры.
	Автоматически масштабируется под телефон, планшет и ПК.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LastLighthouse"):WaitForChild("Config"))
local Sound = require(script.Parent:WaitForChild("Sound"))

local player = Players.LocalPlayer
local UI = {}

------------------------------------------------------------------------
-- Палитра
------------------------------------------------------------------------
local C = {
	Night = Color3.fromRGB(14, 12, 38),
	Panel = Color3.fromRGB(30, 25, 70),
	Panel2 = Color3.fromRGB(48, 38, 104),
	Gold = Color3.fromRGB(255, 211, 107),
	Gold2 = Color3.fromRGB(255, 160, 70),
	Cyan = Color3.fromRGB(107, 228, 255),
	Pink = Color3.fromRGB(255, 122, 217),
	Violet = Color3.fromRGB(150, 110, 255),
	Green = Color3.fromRGB(110, 240, 160),
	Red = Color3.fromRGB(255, 95, 120),
	Text = Color3.fromRGB(244, 240, 255),
	Muted = Color3.fromRGB(175, 168, 220),
	Shadow = Color3.fromRGB(40, 10, 60),
}
UI.Colors = C

local KIND_COLORS = {
	info = C.Cyan,
	warn = C.Red,
	purchase = C.Gold,
	boost = C.Gold2,
	level = C.Gold,
	rank = C.Green,
	deposit = C.Gold,
	upgrade = C.Cyan,
	pet = C.Pink,
	story = Color3.fromRGB(235, 210, 160),
	shadow = C.Violet,
	victory = C.Green,
}

------------------------------------------------------------------------
-- Помощники
------------------------------------------------------------------------
local function new(className, props, children)
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for k, v in pairs(props) do
			if k == "Parent" then
				parent = v
			else
				inst[k] = v
			end
		end
	end
	if children then
		for _, child in ipairs(children) do
			child.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 14) })
end

local function stroke(color, thickness, transparency)
	return new("UIStroke", {
		Color = color,
		Thickness = thickness or 2,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function textStroke(color, thickness)
	return new("UIStroke", { Color = color or C.Night, Thickness = thickness or 1.5, Transparency = 0.2 })
end

local function gradient(c1, c2, rotation)
	return new("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rotation or 90 })
end

local function padding(px)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	})
end

local function label(props)
	local defaults = {
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextColor3 = C.Text,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
	}
	for k, v in pairs(props) do
		defaults[k] = v
	end
	return new("TextLabel", defaults)
end

local function tween(inst, time, props, style, direction)
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function formatNumber(n)
	n = math.floor(n or 0)
	if n >= 1000000 then
		return string.format("%.2fM", n / 1000000)
	elseif n >= 10000 then
		return string.format("%.1fK", n / 1000)
	end
	local s = tostring(n)
	local formatted = s:reverse():gsub("(%d%d%d)", "%1 "):reverse()
	return (formatted:gsub("^ ", ""))
end
UI.FormatNumber = formatNumber

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

-- Кнопка с градиентом и «пружинкой» при наведении/нажатии.
local function button(props)
	local c1 = props.Color1 or C.Gold
	local c2 = props.Color2 or C.Gold2
	local btn = new("TextButton", {
		Name = props.Name or "Button",
		Size = props.Size or UDim2.fromOffset(140, 44),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Font = Enum.Font.FredokaOne,
		Text = props.Text or "",
		TextSize = props.TextSize or 20,
		TextColor3 = props.TextColor or C.Night,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	}, {
		corner(props.Radius or 12),
		gradient(c1, c2, 90),
		stroke(Color3.new(1, 1, 1), 1.5, 0.6),
	})
	local scale = new("UIScale", { Parent = btn })
	btn.MouseEnter:Connect(function()
		tween(scale, 0.12, { Scale = 1.06 })
	end)
	btn.MouseLeave:Connect(function()
		tween(scale, 0.12, { Scale = 1 })
	end)
	btn.MouseButton1Down:Connect(function()
		tween(scale, 0.06, { Scale = 0.94 })
	end)
	btn.MouseButton1Up:Connect(function()
		tween(scale, 0.15, { Scale = 1.04 }, Enum.EasingStyle.Back)
	end)
	btn.Activated:Connect(function()
		Sound.Play("Click")
	end)
	return btn
end

local function setButtonColors(btn, c1, c2)
	local g = btn:FindFirstChildOfClass("UIGradient")
	if g then
		g.Color = ColorSequence.new(c1, c2)
	end
end

local function progressBar(parent, props)
	local back = new("Frame", {
		Name = props.Name or "Bar",
		Size = props.Size,
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		BackgroundColor3 = Color3.fromRGB(10, 8, 28),
		BackgroundTransparency = 0.2,
		Parent = parent,
	}, { corner(8) })
	local fill = new("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = back,
	}, { corner(8), gradient(props.Color1 or C.Cyan, props.Color2 or C.Pink, 0) })
	local text = label({
		Name = "Label",
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = props.TextSize or 13,
		ZIndex = 3,
		Parent = back,
	}, nil)
	textStroke(C.Night, 1.2).Parent = text
	return back, fill, text
end

local function setProgress(fill, ratio)
	ratio = math.clamp(ratio or 0, 0, 1)
	tween(fill, 0.35, { Size = UDim2.fromScale(ratio, 1) })
end

------------------------------------------------------------------------
-- Состояние
------------------------------------------------------------------------
local ps = nil -- состояние игрока с сервера
local ws = nil -- состояние мира
local send = function() end
local gui, scaleObj
local hud = {}
local shop = {}
local deposit = {}
local dialogue = {}
local toastHolder
local bannerHolder
local displayedLight = 0
local lightTweenValue

------------------------------------------------------------------------
-- HUD
------------------------------------------------------------------------
local function buildHud()
	-- Свет
	local lightPill = new("Frame", {
		Name = "LightPill",
		Size = UDim2.fromOffset(250, 62),
		Position = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = gui,
	}, { corner(18), gradient(C.Panel2, C.Night, 90), stroke(C.Gold, 2, 0.15) })
	local star = label({
		Name = "Star",
		Text = "✦",
		Size = UDim2.fromOffset(54, 62),
		TextSize = 40,
		TextColor3 = C.Gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = lightPill,
	})
	new("UIGradient", { Color = ColorSequence.new(C.Gold, C.Pink), Rotation = 45, Parent = star })
	hud.lightLabel = label({
		Name = "Amount",
		Text = "0",
		Position = UDim2.fromOffset(54, 4),
		Size = UDim2.new(1, -62, 0, 36),
		TextSize = 32,
		Parent = lightPill,
	})
	textStroke(C.Night, 2).Parent = hud.lightLabel
	hud.multLabel = label({
		Name = "Mult",
		Text = "звёздный свет · x1.00",
		Position = UDim2.fromOffset(56, 38),
		Size = UDim2.new(1, -62, 0, 18),
		TextSize = 14,
		TextColor3 = C.Cyan,
		Font = Enum.Font.GothamBold,
		Parent = lightPill,
	})
	hud.lightPill = lightPill
	hud.lightScale = new("UIScale", { Parent = lightPill })

	-- Ранг
	local rankPanel = new("Frame", {
		Name = "RankPanel",
		Size = UDim2.fromOffset(250, 52),
		Position = UDim2.fromOffset(16, 86),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = gui,
	}, { corner(14), gradient(C.Panel, C.Night, 90), stroke(C.Cyan, 1.5, 0.5) })
	hud.rankLabel = label({
		Name = "Rank",
		Text = "Новичок",
		Position = UDim2.fromOffset(12, 4),
		Size = UDim2.new(1, -24, 0, 22),
		TextSize = 18,
		TextColor3 = C.Green,
		Parent = rankPanel,
	})
	local _, xpFill, xpText = progressBar(rankPanel, {
		Size = UDim2.new(1, -24, 0, 16),
		Position = UDim2.fromOffset(12, 28),
		Color1 = C.Green,
		Color2 = C.Cyan,
		TextSize = 12,
	})
	hud.xpFill = xpFill
	hud.xpText = xpText

	-- Маяк (сверху по центру)
	local lighthouse = new("Frame", {
		Name = "Lighthouse",
		Size = UDim2.fromOffset(380, 58),
		Position = UDim2.new(0.5, 0, 0, 12),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = gui,
	}, { corner(16), gradient(C.Panel2, C.Night, 90), stroke(C.Gold, 1.5, 0.4) })
	hud.lighthouseLabel = label({
		Text = "🗼 МАЯК · уровень 1",
		Position = UDim2.fromOffset(0, 4),
		Size = UDim2.new(1, 0, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 19,
		TextColor3 = C.Gold,
		Parent = lighthouse,
	})
	textStroke(C.Night, 1.5).Parent = hud.lighthouseLabel
	local _, lhFill, lhText = progressBar(lighthouse, {
		Size = UDim2.new(1, -28, 0, 18),
		Position = UDim2.fromOffset(14, 32),
		Color1 = C.Gold,
		Color2 = Color3.fromRGB(255, 250, 220),
	})
	hud.lhFill = lhFill
	hud.lhText = lhText

	-- Бусты (под Маяком)
	hud.boostRow = new("Frame", {
		Name = "Boosts",
		Size = UDim2.fromOffset(420, 30),
		Position = UDim2.new(0.5, 0, 0, 76),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 8),
		}),
	})
	local function chip(name, c1, c2)
		local f = new("Frame", {
			Name = name,
			Size = UDim2.fromOffset(200, 28),
			BackgroundColor3 = Color3.new(1, 1, 1),
			Visible = false,
			Parent = hud.boostRow,
		}, { corner(14), gradient(c1, c2, 0) })
		local l = label({
			Size = UDim2.fromScale(1, 1),
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = 14,
			TextColor3 = C.Night,
			Parent = f,
		})
		return f, l
	end
	hud.globalChip, hud.globalChipText = chip("Global", C.Gold, C.Gold2)
	hud.victoryChip, hud.victoryChipText = chip("Victory", C.Green, C.Cyan)

	-- Событие Тени
	local shadow = new("Frame", {
		Name = "ShadowEvent",
		Size = UDim2.fromOffset(440, 74),
		Position = UDim2.new(0.5, 0, 0, 112),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Visible = false,
		Parent = gui,
	}, { corner(16), gradient(Color3.fromRGB(70, 20, 110), Color3.fromRGB(15, 5, 25), 90), stroke(C.Violet, 2, 0) })
	hud.shadowTitle = label({
		Text = "🌑 ТЕНЬ НАСТУПАЕТ!",
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, 0, 0, 26),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextSize = 22,
		TextColor3 = Color3.fromRGB(230, 200, 255),
		Parent = shadow,
	})
	textStroke(Color3.new(0, 0, 0), 2).Parent = hud.shadowTitle
	local _, shFill, shText = progressBar(shadow, {
		Size = UDim2.new(1, -28, 0, 22),
		Position = UDim2.fromOffset(14, 40),
		Color1 = C.Violet,
		Color2 = C.Gold,
		TextSize = 14,
	})
	hud.shadowFill = shFill
	hud.shadowText = shText
	hud.shadow = shadow
	hud.shadowStroke = shadow:FindFirstChildOfClass("UIStroke")

	-- Боковые кнопки
	local side = new("Frame", {
		Name = "SideButtons",
		Size = UDim2.fromOffset(84, 330),
		Position = UDim2.new(0, 16, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local function sideButton(order, icon, text, c1, c2, onClick)
		local b = button({
			Name = text,
			Size = UDim2.fromOffset(78, 74),
			Color1 = c1,
			Color2 = c2,
			Text = "",
			Radius = 18,
			LayoutOrder = order,
			Parent = side,
		})
		label({
			Text = icon,
			Size = UDim2.new(1, 0, 0, 44),
			Position = UDim2.fromOffset(0, 4),
			TextSize = 32,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = b,
		})
		local t = label({
			Text = text,
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.fromOffset(0, 48),
			TextSize = 14,
			TextColor3 = C.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = b,
		})
		textStroke(C.Night, 1.5).Parent = t
		b.Activated:Connect(onClick)
		return b
	end
	sideButton(1, "🛒", "Магазин", C.Cyan, Color3.fromRGB(60, 120, 255), function()
		UI.OpenShop("Upgrades")
	end)
	sideButton(2, "✨", "Духи", C.Pink, C.Violet, function()
		UI.OpenShop("Pets")
	end)
	local donate = sideButton(3, "💎", "Донат", C.Gold, C.Gold2, function()
		UI.OpenShop("Donate")
	end)
	-- кнопка доната мягко «дышит», чтобы её замечали
	task.spawn(function()
		local s = donate:FindFirstChildOfClass("UIScale")
		while donate.Parent do
			if s and s.Scale == 1 then
				tween(s, 0.6, { Scale = 1.05 }, Enum.EasingStyle.Sine)
				task.wait(0.6)
				tween(s, 0.6, { Scale = 1 }, Enum.EasingStyle.Sine)
			end
			task.wait(1.6)
		end
	end)
	sideButton(4, "🏠", "Домой", C.Panel2, C.Night, function()
		send("ReturnToHub")
	end)
end

------------------------------------------------------------------------
-- Окна (общая рамка)
------------------------------------------------------------------------
local openWindow = nil

local function makeWindow(name, size, title, accent)
	local overlay = new("TextButton", {
		Name = name .. "Overlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Visible = false,
		ZIndex = 20,
		Parent = gui,
	})
	local window = new("Frame", {
		Name = name,
		Size = size,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 21,
		Parent = overlay,
	}, { corner(22), gradient(C.Panel2, C.Night, 90), stroke(accent or C.Gold, 2.5, 0.1) })
	local winScale = new("UIScale", { Parent = window })
	local titleLabel = label({
		Name = "Title",
		Text = title,
		Size = UDim2.new(1, -80, 0, 44),
		Position = UDim2.fromOffset(22, 10),
		TextSize = 30,
		TextColor3 = accent or C.Gold,
		ZIndex = 22,
		Parent = window,
	})
	textStroke(C.Night, 2).Parent = titleLabel
	local close = button({
		Name = "Close",
		Text = "✕",
		Size = UDim2.fromOffset(44, 44),
		Position = UDim2.new(1, -14, 0, 12),
		AnchorPoint = Vector2.new(1, 0),
		Color1 = C.Red,
		Color2 = Color3.fromRGB(190, 50, 90),
		TextColor = C.Text,
		Parent = window,
	})
	close.ZIndex = 22

	local obj = { overlay = overlay, window = window, scale = winScale, title = titleLabel }
	local function hide()
		UI.CloseWindow(obj)
	end
	close.Activated:Connect(hide)
	overlay.Activated:Connect(hide)
	-- клики по самому окну не закрывают его
	new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		ZIndex = 21,
		Parent = window,
	})
	return obj
end

function UI.OpenWindow(obj)
	if openWindow and openWindow ~= obj then
		UI.CloseWindow(openWindow, true)
	end
	openWindow = obj
	obj.overlay.Visible = true
	obj.overlay.BackgroundTransparency = 1
	obj.scale.Scale = 0.75
	tween(obj.overlay, 0.2, { BackgroundTransparency = 0.45 })
	tween(obj.scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
end

function UI.CloseWindow(obj, instant)
	if openWindow == obj then
		openWindow = nil
	end
	if instant then
		obj.overlay.Visible = false
		return
	end
	tween(obj.overlay, 0.15, { BackgroundTransparency = 1 })
	local t = tween(obj.scale, 0.15, { Scale = 0.8 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	t.Completed:Connect(function()
		if openWindow ~= obj then
			obj.overlay.Visible = false
		end
	end)
end

------------------------------------------------------------------------
-- Магазин
------------------------------------------------------------------------
local function card(parent, order, accent)
	return new("Frame", {
		Size = UDim2.new(1, -8, 0, 96),
		BackgroundColor3 = Color3.new(1, 1, 1),
		LayoutOrder = order,
		ZIndex = 23,
		Parent = parent,
	}, { corner(16), gradient(C.Panel, Color3.fromRGB(22, 18, 52), 0), stroke(accent, 1.5, 0.45) })
end

local function cardIcon(parent, icon, color)
	local holder = new("Frame", {
		Size = UDim2.fromOffset(72, 72),
		Position = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 24,
		Parent = parent,
	}, { corner(36), gradient(color, C.Night, 135) })
	label({
		Text = icon,
		Size = UDim2.fromScale(1, 1),
		TextSize = 38,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 25,
		Parent = holder,
	})
end

local function cardText(parent, title, titleColor, subtitle, extra)
	local t = label({
		Text = title,
		Position = UDim2.fromOffset(98, 10),
		Size = UDim2.new(1, -270, 0, 26),
		TextSize = 21,
		TextColor3 = titleColor or C.Text,
		ZIndex = 24,
		Parent = parent,
	})
	textStroke(C.Night, 1.5).Parent = t
	label({
		Text = subtitle,
		Position = UDim2.fromOffset(98, 36),
		Size = UDim2.new(1, -270, 0, 34),
		TextSize = 14,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextColor3 = C.Muted,
		Font = Enum.Font.GothamMedium,
		ZIndex = 24,
		Parent = parent,
	})
	if extra then
		label({
			Text = extra,
			Position = UDim2.fromOffset(98, 70),
			Size = UDim2.new(1, -270, 0, 18),
			TextSize = 13,
			TextColor3 = C.Cyan,
			Font = Enum.Font.GothamBold,
			ZIndex = 24,
			Parent = parent,
		})
	end
end

local function cardButton(parent, text, c1, c2, textColor, onClick)
	local b = button({
		Text = text,
		Size = UDim2.fromOffset(150, 48),
		Position = UDim2.new(1, -14, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		Color1 = c1,
		Color2 = c2,
		TextColor = textColor or C.Night,
		TextSize = 18,
		Parent = parent,
	})
	b.ZIndex = 25
	b.Activated:Connect(onClick)
	return b
end

local function clearList(list)
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function renderUpgrades(list)
	for order, id in ipairs(Config.UpgradeOrder) do
		local def = Config.Upgrades[id]
		local level = ps and ps.upgrades[id] or 0
		local maxed = level >= def.maxLevel
		local cost = Config.GetUpgradeCost(id, level)
		local c = card(list, order, C.Cyan)
		cardIcon(c, def.icon, C.Cyan)
		local effect
		if id == "Radius" then
			effect = "Сейчас: радиус " .. string.format("%.1f", ps and ps.radius or Config.Light.BasePickupRadius)
		else
			effect = "Сейчас: скорость " .. string.format("%.1f", 16 + level * def.perLevel)
		end
		cardText(c, def.name .. "  ·  " .. level .. "/" .. def.maxLevel, C.Text, def.description, effect)
		if maxed then
			cardButton(c, "МАКС ✓", C.Green, C.Cyan, C.Night, function() end)
		else
			local canAfford = ps and ps.light >= cost
			local b = cardButton(c, formatNumber(cost) .. " ✦", C.Gold, C.Gold2, C.Night, function()
				send("BuyUpgrade", id)
			end)
			if not canAfford then
				setButtonColors(b, Color3.fromRGB(110, 100, 150), Color3.fromRGB(70, 60, 110))
				b.TextColor3 = C.Text
			end
		end
	end
end

local function isEquipped(petId)
	if not ps then
		return false
	end
	for _, id in ipairs(ps.equipped) do
		if id == petId then
			return true
		end
	end
	return false
end

local function renderPets(list)
	local equippedCount = ps and #ps.equipped or 0
	local slots = ps and ps.slots or Config.BaseEquipSlots
	local info = label({
		Text = "Призвано духов: " .. equippedCount .. " / " .. slots .. (slots < Config.PassEquipSlots and "   ·   хочешь больше? загляни в Донат" or ""),
		Size = UDim2.new(1, -8, 0, 24),
		TextSize = 15,
		TextColor3 = C.Muted,
		Font = Enum.Font.GothamBold,
		LayoutOrder = 0,
		ZIndex = 24,
		Parent = list,
	})
	info.TextXAlignment = Enum.TextXAlignment.Center
	for _, pet in ipairs(Config.Pets) do
		local owned = ps and ps.pets[pet.id]
		local c = card(list, pet.order, pet.rarityColor)
		cardIcon(c, pet.style == "phoenix" and "🌈" or (pet.style == "fox" and "🦊" or (pet.style == "jelly" and "🌙" or "🌟")), pet.glow)
		cardText(c, pet.name, pet.rarityColor, pet.rarity .. " · " .. pet.description,
			"+" .. math.floor(pet.lightBonus * 100) .. "% света  ·  +" .. pet.radiusBonus .. " радиус")
		if owned then
			if isEquipped(pet.id) then
				cardButton(c, "Убрать", C.Panel2, C.Night, C.Text, function()
					send("EquipPet", pet.id)
				end)
			else
				cardButton(c, "Призвать", C.Green, C.Cyan, C.Night, function()
					send("EquipPet", pet.id)
				end)
			end
		elseif pet.currency == "Robux" then
			local product = Config.Products[pet.productKey]
			cardButton(c, "💎 " .. (product and product.priceText or "R$"), C.Gold, C.Pink, C.Night, function()
				send("PromptProduct", pet.productKey)
			end)
		else
			local b = cardButton(c, formatNumber(pet.price) .. " ✦", C.Gold, C.Gold2, C.Night, function()
				send("BuyPet", pet.id)
			end)
			if not ps or ps.light < pet.price then
				setButtonColors(b, Color3.fromRGB(110, 100, 150), Color3.fromRGB(70, 60, 110))
				b.TextColor3 = C.Text
			end
		end
	end
end

local function renderDonate(list)
	local header1 = label({
		Text = "👑 Навсегда (геймпассы)",
		Size = UDim2.new(1, -8, 0, 28),
		TextSize = 20,
		TextColor3 = C.Gold,
		LayoutOrder = 0,
		ZIndex = 24,
		Parent = list,
	})
	textStroke(C.Night, 1.5).Parent = header1
	for order, key in ipairs(Config.PassOrder) do
		local def = Config.Passes[key]
		local owned = ps and ps.passes[key]
		local c = card(list, order, C.Gold)
		cardIcon(c, def.icon, C.Gold)
		cardText(c, def.name, C.Gold, def.description)
		if owned then
			cardButton(c, "Куплено ✓", C.Green, C.Cyan, C.Night, function() end)
		else
			cardButton(c, def.priceText, C.Gold, C.Gold2, C.Night, function()
				send("PromptPass", key)
			end)
		end
	end
	local header2 = label({
		Text = "✦ Свет и бусты",
		Size = UDim2.new(1, -8, 0, 28),
		TextSize = 20,
		TextColor3 = C.Cyan,
		LayoutOrder = 10,
		ZIndex = 24,
		Parent = list,
	})
	textStroke(C.Night, 1.5).Parent = header2
	for order, key in ipairs(Config.ProductOrder) do
		local def = Config.Products[key]
		local c = card(list, 10 + order, def.pet and C.Pink or C.Cyan)
		cardIcon(c, def.icon, def.pet and C.Pink or C.Cyan)
		cardText(c, def.name, C.Text, def.description)
		local ownedPet = def.pet and ps and ps.pets[def.pet]
		if ownedPet then
			cardButton(c, "Уже твой ✓", C.Green, C.Cyan, C.Night, function() end)
		else
			cardButton(c, def.priceText, C.Gold, C.Pink, C.Night, function()
				send("PromptProduct", key)
			end)
		end
	end
	local footer = label({
		Text = "Покупки поддерживают разработчика и помогают Маяку гореть ✦",
		Size = UDim2.new(1, -8, 0, 24),
		TextSize = 13,
		TextColor3 = C.Muted,
		Font = Enum.Font.GothamMedium,
		LayoutOrder = 100,
		ZIndex = 24,
		Parent = list,
	})
	footer.TextXAlignment = Enum.TextXAlignment.Center
end

local TABS = {
	{ id = "Upgrades", text = "🛒 Улучшения", render = renderUpgrades, accent = C.Cyan },
	{ id = "Pets", text = "✨ Духи", render = renderPets, accent = C.Pink },
	{ id = "Donate", text = "💎 Донат", render = renderDonate, accent = C.Gold },
}

local function buildShop()
	local obj = makeWindow("Shop", UDim2.fromOffset(680, 470), "Магазин Смотрителя", C.Gold)
	shop.obj = obj
	shop.tab = "Upgrades"
	shop.tabButtons = {}

	local tabsRow = new("Frame", {
		Size = UDim2.new(1, -44, 0, 44),
		Position = UDim2.fromOffset(22, 62),
		BackgroundTransparency = 1,
		ZIndex = 22,
		Parent = obj.window,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 10),
		}),
	})
	for _, tab in ipairs(TABS) do
		local b = button({
			Text = tab.text,
			Size = UDim2.fromOffset(200, 42),
			Color1 = C.Panel2,
			Color2 = C.Panel,
			TextColor = C.Text,
			TextSize = 18,
			Parent = tabsRow,
		})
		b.ZIndex = 23
		b.Activated:Connect(function()
			UI.OpenShop(tab.id)
		end)
		shop.tabButtons[tab.id] = b
	end

	shop.list = new("ScrollingFrame", {
		Size = UDim2.new(1, -36, 1, -128),
		Position = UDim2.fromOffset(22, 116),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.Gold,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 23,
		Parent = obj.window,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 4) }),
	})
end

local function renderShop()
	if not shop.obj or openWindow ~= shop.obj then
		return
	end
	local scroll = shop.list.CanvasPosition
	clearList(shop.list)
	for _, tab in ipairs(TABS) do
		local b = shop.tabButtons[tab.id]
		if tab.id == shop.tab then
			setButtonColors(b, tab.accent, C.Panel2)
			b.TextColor3 = C.Night
			shop.obj.title.TextColor3 = tab.accent
			tab.render(shop.list)
		else
			setButtonColors(b, C.Panel2, C.Panel)
			b.TextColor3 = C.Text
		end
	end
	shop.list.CanvasPosition = scroll
end

function UI.OpenShop(tabId)
	local changed = shop.tab ~= tabId
	shop.tab = tabId or shop.tab
	if openWindow ~= shop.obj then
		UI.OpenWindow(shop.obj)
		shop.list.CanvasPosition = Vector2.zero
	elseif changed then
		shop.list.CanvasPosition = Vector2.zero
	end
	renderShop()
end

------------------------------------------------------------------------
-- Окно вклада в Маяк
------------------------------------------------------------------------
local function buildDeposit()
	local obj = makeWindow("Deposit", UDim2.fromOffset(460, 280), "🗼 Отдать свет Маяку", C.Gold)
	deposit.obj = obj
	deposit.info = label({
		Text = "",
		Position = UDim2.fromOffset(24, 62),
		Size = UDim2.new(1, -48, 0, 70),
		TextSize = 16,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.GothamMedium,
		TextColor3 = C.Muted,
		RichText = true,
		ZIndex = 23,
		Parent = obj.window,
	})
	local row = new("Frame", {
		Size = UDim2.new(1, -48, 0, 60),
		Position = UDim2.new(0, 24, 1, -84),
		BackgroundTransparency = 1,
		ZIndex = 22,
		Parent = obj.window,
	}, {
		new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 12),
		}),
	})
	local options = { { 0.25, "25%" }, { 0.5, "50%" }, { 1, "ВСЁ 🔥" } }
	for i, option in ipairs(options) do
		local b = button({
			Text = option[2],
			Size = UDim2.fromOffset(124, 56),
			Color1 = i == 3 and C.Gold or C.Cyan,
			Color2 = i == 3 and C.Gold2 or Color3.fromRGB(60, 120, 255),
			TextSize = 22,
			LayoutOrder = i,
			Parent = row,
		})
		b.ZIndex = 23
		b.Activated:Connect(function()
			send("Deposit", option[1])
			UI.CloseWindow(obj)
		end)
	end
end

local function renderDeposit()
	if not deposit.info or not ps then
		return
	end
	deposit.info.Text = "У тебя <font color=\"#FFD36B\"><b>" .. formatNumber(ps.light) .. " ✦</b></font>. "
		.. "Сколько света отдать огню? Ты получишь столько же <b>опыта Смотрителя</b> — каждый новый ранг навсегда даёт <font color=\"#6EF0A0\"><b>+" .. math.floor(Config.RankBonus * 100) .. "% света</b></font>."
end

function UI.OpenDeposit()
	renderDeposit()
	UI.OpenWindow(deposit.obj)
end

------------------------------------------------------------------------
-- Диалоги
------------------------------------------------------------------------
local DIALOGUE_STYLES = {
	default = { c1 = C.Panel2, c2 = C.Night, accent = C.Gold, name = C.Gold },
	note = { c1 = Color3.fromRGB(95, 70, 45), c2 = Color3.fromRGB(45, 30, 20), accent = Color3.fromRGB(235, 205, 150), name = Color3.fromRGB(255, 225, 170) },
	shadow = { c1 = Color3.fromRGB(60, 15, 90), c2 = Color3.fromRGB(10, 0, 20), accent = C.Violet, name = Color3.fromRGB(220, 180, 255) },
}

local function buildDialogue()
	local box = new("TextButton", {
		Name = "Dialogue",
		Size = UDim2.fromOffset(760, 170),
		Position = UDim2.new(0.5, 0, 1, -24),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		Visible = false,
		ZIndex = 40,
		Parent = gui,
	}, { corner(22) })
	dialogue.gradient = gradient(C.Panel2, C.Night, 90)
	dialogue.gradient.Parent = box
	dialogue.stroke = stroke(C.Gold, 2.5, 0.1)
	dialogue.stroke.Parent = box
	dialogue.scale = new("UIScale", { Parent = box })

	local nameTag = new("Frame", {
		Size = UDim2.fromOffset(320, 40),
		Position = UDim2.fromOffset(26, -20),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 41,
		Parent = box,
	}, { corner(14), gradient(C.Gold, C.Gold2, 0) })
	dialogue.nameTagGradient = nameTag:FindFirstChildOfClass("UIGradient")
	dialogue.name = label({
		Size = UDim2.new(1, -24, 1, 0),
		Position = UDim2.fromOffset(12, 0),
		TextSize = 20,
		TextColor3 = C.Night,
		ZIndex = 42,
		Parent = nameTag,
	})
	dialogue.text = label({
		Size = UDim2.new(1, -52, 1, -64),
		Position = UDim2.fromOffset(26, 30),
		TextSize = 20,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Font = Enum.Font.GothamMedium,
		ZIndex = 41,
		Parent = box,
	})
	dialogue.hint = label({
		Text = "Нажми, чтобы продолжить ▶",
		Size = UDim2.new(1, -40, 0, 22),
		Position = UDim2.new(0, 20, 1, -30),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = C.Muted,
		Font = Enum.Font.GothamBold,
		ZIndex = 41,
		Parent = box,
	})
	dialogue.box = box
	dialogue.queue = {}
	dialogue.running = false
	dialogue.advance = Instance.new("BindableEvent")
	box.Activated:Connect(function()
		dialogue.advance:Fire()
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if dialogue.box.Visible and (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.E) then
			dialogue.advance:Fire()
		end
	end)
end

local function playDialogue(entry)
	local style = DIALOGUE_STYLES[entry.style or "default"] or DIALOGUE_STYLES.default
	dialogue.gradient.Color = ColorSequence.new(style.c1, style.c2)
	dialogue.stroke.Color = style.accent
	dialogue.nameTagGradient.Color = ColorSequence.new(style.name, style.accent)
	dialogue.name.Text = entry.speaker or ""
	local box = dialogue.box
	box.Visible = true
	dialogue.scale.Scale = 0.85
	tween(dialogue.scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)

	for index, line in ipairs(entry.lines or {}) do
		dialogue.text.Text = line
		dialogue.text.MaxVisibleGraphemes = 0
		dialogue.hint.Text = index < #entry.lines and "Нажми, чтобы продолжить ▶" or "Нажми, чтобы закрыть ✓"
		local skipped = false
		local conn = dialogue.advance.Event:Connect(function()
			skipped = true
		end)
		local length = utf8.len(line) or #line
		local shown = 0
		while shown < length and not skipped do
			shown = shown + 1
			dialogue.text.MaxVisibleGraphemes = shown
			task.wait(0.022)
		end
		conn:Disconnect()
		dialogue.text.MaxVisibleGraphemes = -1
		dialogue.advance.Event:Wait()
	end
	local t = tween(dialogue.scale, 0.15, { Scale = 0.85 })
	t.Completed:Wait()
	box.Visible = false
end

-- Показывает диалог (в очереди). Если передан done (BindableEvent) — сработает по окончании.
function UI.ShowDialogue(entry, done)
	table.insert(dialogue.queue, { entry = entry, done = done })
	if dialogue.running then
		return
	end
	dialogue.running = true
	task.spawn(function()
		while #dialogue.queue > 0 do
			local item = table.remove(dialogue.queue, 1)
			playDialogue(item.entry)
			if item.done then
				item.done:Fire()
			end
		end
		dialogue.running = false
	end)
end

function UI.ShowDialogueAsync(entry)
	local done = Instance.new("BindableEvent")
	UI.ShowDialogue(entry, done)
	done.Event:Wait()
	done:Destroy()
end

------------------------------------------------------------------------
-- Уведомления и баннеры
------------------------------------------------------------------------
local function buildToasts()
	toastHolder = new("Frame", {
		Name = "Toasts",
		Size = UDim2.fromOffset(340, 400),
		Position = UDim2.new(1, -16, 0, 16),
		AnchorPoint = Vector2.new(1, 0),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = gui,
	}, {
		new("UIListLayout", {
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	bannerHolder = new("Frame", {
		Name = "Banner",
		Size = UDim2.fromOffset(700, 140),
		Position = UDim2.fromScale(0.5, 0.32),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ZIndex = 60,
		Parent = gui,
	})
end

local toastCount = 0
function UI.Notify(text, kind)
	if not toastHolder then
		return
	end
	toastCount = toastCount + 1
	local color = KIND_COLORS[kind] or C.Cyan
	local toast = new("Frame", {
		Size = UDim2.fromOffset(340, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(1, 1, 1),
		LayoutOrder = toastCount,
		ZIndex = 50,
		Parent = toastHolder,
	}, { corner(14), gradient(C.Panel2, C.Night, 90), stroke(color, 2, 0.1), padding(10) })
	local stripe = new("Frame", {
		Size = UDim2.new(0, 5, 1, 0),
		BackgroundColor3 = color,
		ZIndex = 51,
		Parent = toast,
	}, { corner(3) })
	stripe.Position = UDim2.fromOffset(-4, 0)
	local l = label({
		Text = text,
		Size = UDim2.new(1, -8, 0, 0),
		Position = UDim2.fromOffset(8, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextSize = 16,
		TextWrapped = true,
		Font = Enum.Font.GothamBold,
		ZIndex = 51,
		Parent = toast,
	})
	l.TextColor3 = C.Text
	local s = new("UIScale", { Scale = 0.6, Parent = toast })
	tween(s, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(4.5, function()
		local t = tween(s, 0.25, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		t.Completed:Wait()
		toast:Destroy()
	end)
	-- не больше 5 уведомлений сразу
	local toasts = {}
	for _, child in ipairs(toastHolder:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(toasts, child)
		end
	end
	if #toasts > 5 then
		table.sort(toasts, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		toasts[1]:Destroy()
	end
end

function UI.Banner(title, subtitle, color)
	if not bannerHolder then
		return
	end
	bannerHolder:ClearAllChildren()
	local s = new("UIScale", { Scale = 0.3, Parent = bannerHolder })
	local t = label({
		Text = title,
		Size = UDim2.new(1, 0, 0, 80),
		TextSize = 64,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.new(1, 1, 1),
		ZIndex = 60,
		Parent = bannerHolder,
	})
	new("UIGradient", { Color = ColorSequence.new(color or C.Gold, C.Pink), Rotation = 90, Parent = t })
	textStroke(C.Night, 3).Parent = t
	local st = label({
		Text = subtitle or "",
		Size = UDim2.new(1, 0, 0, 36),
		Position = UDim2.fromOffset(0, 80),
		TextSize = 26,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = C.Text,
		ZIndex = 60,
		Parent = bannerHolder,
	})
	textStroke(C.Night, 2).Parent = st
	tween(s, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
	task.delay(2.6, function()
		if s.Parent then
			local out = tween(s, 0.3, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			out.Completed:Wait()
			if s.Parent then
				bannerHolder:ClearAllChildren()
			end
		end
	end)
end

function UI.BumpLight()
	if not hud.lightScale then
		return
	end
	hud.lightScale.Scale = 1.08
	tween(hud.lightScale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
end

function UI.SetHudVisible(visible)
	for _, name in ipairs({ "LightPill", "RankPanel", "Lighthouse", "Boosts", "SideButtons", "Toasts" }) do
		local f = gui:FindFirstChild(name)
		if f then
			f.Visible = visible
		end
	end
	if hud.shadow then
		hud.shadow.Visible = visible and ws ~= nil and ws.shadow.active
	end
end

------------------------------------------------------------------------
-- Обновление от сервера
------------------------------------------------------------------------
local function renderHud()
	if not ps then
		return
	end
	-- плавный счётчик света
	if lightTweenValue then
		tween(lightTweenValue, 0.5, { Value = ps.light })
	end
	hud.multLabel.Text = "звёздный свет · x" .. string.format("%.2f", ps.multiplier)
	hud.rankLabel.Text = "⭐ " .. ps.rankName
	local rank = Config.Ranks[ps.rankIndex]
	if rank then
		hud.rankLabel.TextColor3 = rank.color
	end
	if ps.nextRankXp then
		local ratio = (ps.keeperXp - ps.rankXp) / math.max(1, ps.nextRankXp - ps.rankXp)
		setProgress(hud.xpFill, ratio)
		hud.xpText.Text = formatNumber(ps.keeperXp) .. " / " .. formatNumber(ps.nextRankXp) .. " опыта"
	else
		setProgress(hud.xpFill, 1)
		hud.xpText.Text = "Максимальный ранг!"
	end
end

local function renderWorld()
	if not ws then
		return
	end
	hud.lighthouseLabel.Text = "🗼 МАЯК · уровень " .. ws.level .. (ws.level > 1 and ("  (+" .. math.floor((ws.level - 1) * Config.Lighthouse.BonusPerLevel * 100 + 0.5) .. "% всем)") or "")
	if ws.nextThreshold then
		local ratio = (ws.lighthouseTotal - ws.prevThreshold) / math.max(1, ws.nextThreshold - ws.prevThreshold)
		setProgress(hud.lhFill, ratio)
		hud.lhText.Text = formatNumber(ws.lighthouseTotal) .. " / " .. formatNumber(ws.nextThreshold) .. " ✦ до следующего уровня"
	else
		setProgress(hud.lhFill, 1)
		hud.lhText.Text = "Маяк сияет в полную силу!"
	end
	local shadow = ws.shadow
	local hudVisible = gui:FindFirstChild("LightPill") and gui.LightPill.Visible
	hud.shadow.Visible = shadow.active and hudVisible
	if shadow.active then
		setProgress(hud.shadowFill, shadow.progress / math.max(1, shadow.goal))
	end
end

function UI.SetPlayerState(state)
	ps = state
	renderHud()
	renderShop()
	if openWindow == deposit.obj then
		renderDeposit()
	end
end

function UI.SetWorldState(state)
	ws = state
	renderWorld()
end

function UI.GetPlayerState()
	return ps
end

-- таймеры (обновляются 4 раза в секунду)
local function timerLoop()
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc = acc + dt
		if acc < 0.25 or not ws then
			return
		end
		acc = 0
		local now = workspace:GetServerTimeNow()
		local g = ws.globalBoostUntil - now
		hud.globalChip.Visible = g > 0
		if g > 0 then
			hud.globalChipText.Text = "🔥 x2 свет от " .. ws.globalBoostBy .. " · " .. formatTime(g)
		end
		local v = ws.shadowBoostUntil - now
		hud.victoryChip.Visible = v > 0
		if v > 0 then
			hud.victoryChipText.Text = "☀️ Победа над Тенью · " .. formatTime(v)
		end
		if ws.shadow.active then
			hud.shadowText.Text = formatNumber(ws.shadow.progress) .. " / " .. formatNumber(ws.shadow.goal) .. " ✦   ·   осталось " .. formatTime(ws.shadow.endsAt - now)
			hud.shadowStroke.Transparency = 0.5 + math.sin(os.clock() * 6) * 0.5
		end
	end)
end

------------------------------------------------------------------------
function UI.Init(options)
	send = options.send
	local playerGui = player:WaitForChild("PlayerGui")
	gui = new("ScreenGui", {
		Name = "LastLighthouseUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = false,
		Parent = playerGui,
	})
	UI.Gui = gui
	scaleObj = new("UIScale", { Parent = gui })
	local function rescale()
		local camera = workspace.CurrentCamera
		if not camera then
			return
		end
		local vp = camera.ViewportSize
		scaleObj.Scale = math.clamp(math.min(vp.X / 1150, vp.Y / 680), 0.5, 1.15)
	end
	rescale()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

	buildHud()
	buildShop()
	buildDeposit()
	buildDialogue()
	buildToasts()
	timerLoop()

	lightTweenValue = Instance.new("NumberValue")
	lightTweenValue.Changed:Connect(function(value)
		local shown = math.floor(value + 0.5)
		if shown ~= displayedLight then
			displayedLight = shown
			hud.lightLabel.Text = formatNumber(shown)
		end
	end)
end

return UI
