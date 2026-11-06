--!nonstrict
-- PROTOTYPE - NOT FOR PRODUCTION
-- Developer menu UI. Lives in ServerScriptService and is cloned by the server ONLY into an
-- admin's PlayerGui, so other players never receive this code. Every command is re-checked on the server.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("LootCityShared")
local Config = require(Shared:WaitForChild("Config"))
local AdminRF = Shared:WaitForChild("Admin")
local gui = script.Parent

local FONT, FONT_B = Enum.Font.Gotham, Enum.Font.GothamBold
local BG = Color3.fromRGB(16, 19, 26)
local ACC = Color3.fromRGB(255, 120, 60)
local DIM = Color3.fromRGB(150, 160, 172)

local function new(class, props, children)
	local o = Instance.new(class)
	for k, v in props or {} do
		if k ~= "Parent" then (o :: any)[k] = v end
	end
	for _, c in children or {} do c.Parent = o end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end
local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r or 8) }) end
local function label(text, props)
	local l = new("TextLabel", { BackgroundTransparency = 1, Text = text, Font = FONT, TextSize = 14, TextColor3 = Color3.fromRGB(235, 238, 242), TextXAlignment = Enum.TextXAlignment.Left, RichText = true, Size = UDim2.new(1, 0, 0, 20) })
	for k, v in props or {} do (l :: any)[k] = v end
	return l
end
local function btn(text, color, onClick, w)
	local b = new("TextButton", { Text = text, Font = FONT_B, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), AutoButtonColor = true,
		BackgroundColor3 = color or Color3.fromRGB(52, 58, 70), Size = UDim2.fromOffset(w or 0, 30), AutomaticSize = if w then Enum.AutomaticSize.None else Enum.AutomaticSize.X },
		{ corner(7), new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
	if onClick then b.MouseButton1Click:Connect(onClick) end
	return b
end
local function box(placeholder, w, text)
	return new("TextBox", { PlaceholderText = placeholder, Text = text or "", Font = FONT, TextSize = 13, TextColor3 = Color3.new(1, 1, 1), PlaceholderColor3 = DIM,
		BackgroundColor3 = Color3.fromRGB(30, 34, 44), Size = UDim2.fromOffset(w or 140, 30), ClearTextOnFocus = false }, { corner(7) })
end
local function hrow(children)
	return new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.Y },
		{ new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), Wraps = true, VerticalAlignment = Enum.VerticalAlignment.Center }), table.unpack(children) })
end

-- ===== window =====
local win = new("Frame", { Visible = false, BackgroundColor3 = BG, BackgroundTransparency = 0.04, Position = UDim2.new(0, 18, 0.5, -330), Size = UDim2.fromOffset(600, 660), Active = true, Parent = gui },
	{ corner(14), new("UIStroke", { Color = ACC, Transparency = 0.4, Thickness = 1.5 }) })
local title = label("🛠 <b>Меню разработчика</b>", { TextSize = 18, Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -80, 0, 26), Parent = win })
local closeB = btn("✕", Color3.fromRGB(70, 40, 40), nil, 36)
closeB.Position = UDim2.new(1, -48, 0, 10)
closeB.Parent = win
local targetL = label("", { TextSize = 13, TextColor3 = DIM, Position = UDim2.fromOffset(16, 38), Size = UDim2.new(1, -200, 0, 20), Parent = win })
local prevB = btn("◀", nil, nil, 34)
prevB.Position = UDim2.new(1, -170, 0, 36)
prevB.Parent = win
local selfB = btn("Я", ACC, nil, 50)
selfB.Position = UDim2.new(1, -130, 0, 36)
selfB.Parent = win
local nextB = btn("▶", nil, nil, 34)
nextB.Position = UDim2.new(1, -74, 0, 36)
nextB.Parent = win
local tabsF = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 74), Size = UDim2.new(1, -24, 0, 30), Parent = win },
	{ new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }) })
local body = new("ScrollingFrame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 112), Size = UDim2.new(1, -28, 1, -150), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5, BorderSizePixel = 0, Parent = win },
	{ new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }), new("UIPadding", { PaddingRight = UDim.new(0, 8) }) })
local status = label("", { TextSize = 12, TextColor3 = DIM, Position = UDim2.new(0, 16, 1, -30), Size = UDim2.new(1, -32, 0, 20), Parent = win })

-- drag by the title
do
	local dragging, start, startPos
	title.Active = true
	title.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging, start, startPos = true, i.Position, win.Position end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - start
			win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end

local toggleB = btn("🛠 Админ [F2]", ACC, nil)
toggleB.AnchorPoint = Vector2.new(0.5, 0)
toggleB.Position = UDim2.new(0.5, 0, 0, 8)
toggleB.Parent = gui

-- ===== state =====
local Info = nil
local tab = "players"
local targetId = player.UserId
local order = 0
local render -- forward

local function setStatus(t, ok)
	status.Text = (if ok == false then "<font color='#ff6a6a'>✗ </font>" else "<font color='#5ee37a'>✓ </font>") .. t
end
local function call(name, args, okText)
	task.spawn(function()
		local ok, res = pcall(function()
			return AdminRF:InvokeServer(name, args or {})
		end)
		if ok and res then
			setStatus(okText or name, true)
		else
			setStatus((okText or name) .. " — не выполнено", false)
		end
		task.wait(0.2)
		local ok2, info = pcall(function()
			return AdminRF:InvokeServer("info", {})
		end)
		if ok2 and info then
			Info = info
			render()
		end
	end)
end
local function targetArgs(extra)
	local t = { target = targetId }
	for k, v in extra or {} do t[k] = v end
	return t
end
local function targetName()
	if Info then
		for _, p in Info.players do
			if p.id == targetId then return p.name end
		end
	end
	return player.Name
end

local function add(o)
	order += 1
	o.LayoutOrder = order
	o.Parent = body
	return o
end
local function section(text)
	add(label("<b>" .. text .. "</b>", { TextSize = 15, TextColor3 = ACC, Size = UDim2.new(1, 0, 0, 24) }))
end
local function clear()
	for _, c in body:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
	end
	order = 0
end

local TABS = { { "players", "Игроки" }, { "give", "Выдать" }, { "progress", "Прогресс" }, { "world", "Мир" }, { "me", "Я" }, { "bans", "Баны" }, { "log", "Журнал" } }
local function drawTabs()
	for _, c in tabsF:GetChildren() do
		if c:IsA("TextButton") then c:Destroy() end
	end
	for _, t in TABS do
		local b = btn(t[2], if tab == t[1] then ACC else nil, function()
			tab = t[1]
			render()
		end)
		b.Parent = tabsF
	end
end

-- ===== self tools (client-side) =====
local Self = { fly = false, noclip = false, speed = 1 }
local flyLV, flyAtt
local function setFly(on)
	Self.fly = on
	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if flyLV then flyLV:Destroy() flyLV = nil end
	if flyAtt then flyAtt:Destroy() flyAtt = nil end
	if hum then hum.PlatformStand = on end
	if on and hrp then
		flyAtt = new("Attachment", { Parent = hrp })
		flyLV = new("LinearVelocity", { Attachment0 = flyAtt, MaxForce = math.huge, VectorVelocity = Vector3.zero, RelativeTo = Enum.ActuatorRelativeTo.World, Parent = hrp })
	end
end
RunService.Stepped:Connect(function()
	local ch = player.Character
	if not ch then return end
	if Self.noclip then
		for _, p in ch:GetDescendants() do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end
	if Self.fly and flyLV then
		local cam = workspace.CurrentCamera
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
		flyLV.VectorVelocity = if dir.Magnitude > 0 then dir.Unit * 90 * Self.speed else Vector3.zero
	end
end)
player.CharacterAdded:Connect(function()
	Self.fly = false
	flyLV, flyAtt = nil, nil
end)

-- ===== tabs =====
local reasonBox = nil
local function drawPlayers()
	section("Игроки на сервере (" .. #Info.players .. ")")
	reasonBox = box("Причина кика/бана", 260)
	add(hrow({ label("Причина:", { Size = UDim2.fromOffset(70, 30) }), reasonBox }))
	for _, p in Info.players do
		local f = add(new("Frame", { BackgroundColor3 = Color3.fromRGB(28, 32, 42), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, { corner(8), new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }), new("UIListLayout", { Padding = UDim.new(0, 6) }) }))
		label(("<b>%s</b> (@%s, id %d)%s%s"):format(p.display, p.name, p.id, if p.admin then " <font color='#ff7a3c'>[админ]</font>" else "", if p.id == targetId then " <font color='#5ee37a'>◀ цель</font>" else ""), { Parent = f })
		label(("💰 $%d · 🏠 %s · районов %d/4 · 🎒 %d · реп %d · 📍 %s"):format(p.money, Config.HOME_STAGES[p.home].name, p.districts, p.items, p.rep, p.where), { TextSize = 12, TextColor3 = DIM, Parent = f })
		local r = hrow({
			btn("Цель", ACC, function() targetId = p.id; render() end),
			btn("ТП к нему", nil, function() call("tpTo", { target = p.id }, "телепорт к " .. p.name) end),
			btn("Притянуть", nil, function() call("bring", { target = p.id }, "притянул " .. p.name) end),
			btn("К его дому", nil, function() call("tpHome", { target = p.id }, "у дома " .. p.name) end),
		})
		r.Parent = f
		if p.id ~= player.UserId then
			local r2 = hrow({
				btn("Кик", Color3.fromRGB(150, 100, 30), function() call("kick", { target = p.id, reason = reasonBox.Text }, "кик " .. p.name) end),
				btn("Бан навсегда", Color3.fromRGB(170, 40, 40), function() call("ban", { target = p.id, reason = reasonBox.Text }, "бан " .. p.name) end),
			})
			r2.Parent = f
		end
	end
end

local countBox = nil
local function drawGive()
	section("Деньги → " .. targetName())
	local amt = box("Сумма", 140, "10000")
	add(hrow({
		amt,
		btn("Добавить", Color3.fromRGB(40, 120, 60), function() call("money", targetArgs({ amount = tonumber(amt.Text) or 0 }), "деньги +" .. amt.Text) end),
		btn("Установить", nil, function() call("money", targetArgs({ amount = tonumber(amt.Text) or 0, set = true }), "баланс = " .. amt.Text) end),
		btn("Забрать", Color3.fromRGB(150, 60, 40), function() call("money", targetArgs({ amount = -(tonumber(amt.Text) or 0) }), "деньги -" .. amt.Text) end),
	}))
	add(hrow({
		btn("+$1 000", nil, function() call("money", targetArgs({ amount = 1000 }), "+$1 000") end),
		btn("+$10 000", nil, function() call("money", targetArgs({ amount = 10000 }), "+$10 000") end),
		btn("+$100 000", nil, function() call("money", targetArgs({ amount = 100000 }), "+$100 000") end),
		btn("+$1 000 000", nil, function() call("money", targetArgs({ amount = 1000000 }), "+$1 000 000") end),
	}))
	section("Предметы → " .. targetName())
	countBox = box("Кол-во", 70, "1")
	add(hrow({ label("Количество:", { Size = UDim2.fromOffset(90, 30) }), countBox, btn("Очистить рюкзак", Color3.fromRGB(150, 60, 40), function() call("clearInv", targetArgs(), "рюкзак очищен") end) }))
	for _, it in Config.ITEMS do
		local r = Config.RARITY[it.r]
		add(hrow({
			label(("<font color='#%s'>●</font> %s <font color='#8a94a0'>· %s · $%d%s</font>"):format(r.color:ToHex(), it.name, r.name, it.v, if it.col then " · коллекция" else ""), { Size = UDim2.new(1, -230, 0, 30) }),
			btn("В рюкзак", nil, function() call("item", targetArgs({ id = it.id, count = tonumber(countBox.Text) or 1 }), "выдан " .. it.name) end),
			btn("На землю", nil, function() call("loot", { op = "spawn", id = it.id }, "на земле: " .. it.name) end),
		}))
	end
end

local function drawProgress()
	section("Быстро → " .. targetName())
	add(hrow({
		btn("Все улучшения MAX", ACC, function() call("upgrade", targetArgs({ all = true }), "улучшения MAX") end),
		btn("Все районы", nil, function() call("unlockAll", targetArgs({ what = "districts" }), "районы открыты") end),
		btn("Весь транспорт", nil, function() call("unlockAll", targetArgs({ what = "vehicles" }), "транспорт выдан") end),
		btn("Весь декор", nil, function() call("unlockAll", targetArgs({ what = "decor" }), "декор выдан") end),
		btn("Все коллекции", nil, function() call("unlockAll", targetArgs({ what = "collections" }), "коллекции собраны") end),
		btn("Бизнес MAX", nil, function() call("unlockAll", targetArgs({ what = "business" }), "бизнес MAX") end),
	}))
	section("Уровни улучшений")
	for _, u in Config.UPGRADES do
		local lv = box("0-" .. u.max, 60, "")
		add(hrow({
			label(u.name .. " <font color='#8a94a0'>(макс " .. u.max .. ")</font>", { Size = UDim2.new(1, -260, 0, 30) }),
			lv,
			btn("Установить", nil, function() call("upgrade", targetArgs({ id = u.id, lvl = tonumber(lv.Text) or 0 }), u.name .. " = " .. lv.Text) end),
			btn("MAX", ACC, function() call("upgrade", targetArgs({ id = u.id, lvl = u.max }), u.name .. " MAX") end),
		}))
	end
	section("Районы")
	for d, dist in Config.DISTRICTS do
		add(hrow({
			label(dist.name, { Size = UDim2.new(1, -200, 0, 30) }),
			btn("Открыть", Color3.fromRGB(40, 120, 60), function() call("district", targetArgs({ d = d, on = true }), dist.name .. " открыт") end),
			btn("Закрыть", Color3.fromRGB(150, 60, 40), function() call("district", targetArgs({ d = d, on = false }), dist.name .. " закрыт") end),
		}))
	end
	section("Дом")
	local homeBtns = {}
	for i, h in Config.HOME_STAGES do
		table.insert(homeBtns, btn(h.name, nil, function() call("home", targetArgs({ stage = i }), "дом: " .. h.name) end))
	end
	add(hrow(homeBtns))
	section("Прочее")
	add(hrow({
		btn("Репутация +10", nil, function() call("rep", targetArgs({ amount = 10 }), "репутация +10") end),
		btn("Репутация −10", nil, function() call("rep", targetArgs({ amount = -10 }), "репутация −10") end),
	}))
	local confirm = false
	local resetB
	resetB = btn("Сбросить прогресс игрока", Color3.fromRGB(170, 40, 40), function()
		if not confirm then
			confirm = true
			resetB.Text = "Точно сбросить? Нажмите ещё раз"
			return
		end
		call("reset", targetArgs(), "прогресс сброшен")
	end)
	add(hrow({ resetB }))
end

local function drawWorld()
	section("Сервер")
	local h = math.floor(Info.time * 24)
	add(label(("День %d · %02d:%02d · лута на карте %d · лимит на район %d · следующее событие через %dс"):format(Info.day, h, math.floor((Info.time * 24 - h) * 60), Info.loot, Info.cap, Info.eventIn), { TextColor3 = DIM, TextWrapped = true, Size = UDim2.new(1, 0, 0, 36) }))
	add(label("Активно: " .. (if #Info.effects > 0 then table.concat(Info.effects, ", ") else "нет"), { TextColor3 = DIM }))
	section("Время суток")
	add(hrow({
		btn("🌅 06:00", nil, function() call("time", { t = 0.25 }, "06:00") end),
		btn("☀️ 09:00", nil, function() call("time", { t = 0.375 }, "09:00") end),
		btn("🌞 12:00", nil, function() call("time", { t = 0.5 }, "12:00") end),
		btn("🌇 18:30", nil, function() call("time", { t = 0.77 }, "18:30") end),
		btn("🌙 23:00", nil, function() call("time", { t = 0.96 }, "23:00") end),
		btn("Следующий день", nil, function() call("nextDay", {}, "новый день") end),
	}))
	section("События (в вашем районе)")
	add(hrow({
		btn("🚚 Грузовик", nil, function() call("event", { name = "truck" }, "грузовик") end),
		btn("💸 Ажиотаж", nil, function() call("event", { name = "sale" }, "ажиотаж") end),
		btn("🌧️ Ливень", nil, function() call("event", { name = "rain" }, "ливень") end),
		btn("📦 Курьер", nil, function() call("event", { name = "courier" }, "курьер") end),
		btn("✨ Лихорадка", nil, function() call("event", { name = "gold" }, "лихорадка") end),
		btn("🗺️ Клад", nil, function() call("event", { name = "treasure" }, "клад") end),
		btn("Остановить всё", Color3.fromRGB(150, 60, 40), function() call("stopEffects", {}, "события остановлены") end),
	}))
	section("Лут")
	local cap = box("лимит", 70, tostring(Info.cap))
	add(hrow({
		label("Лимит предметов на район:", { Size = UDim2.fromOffset(190, 30) }), cap,
		btn("Применить", nil, function() call("loot", { op = "cap", n = tonumber(cap.Text) or 40 }, "лимит " .. cap.Text) end),
		btn("Пересоздать весь лут", nil, function() call("loot", { op = "clear" }, "лут пересоздан") end),
	}))
	section("Объявление всем игрокам")
	local ann = box("Текст объявления", 380)
	add(hrow({ ann, btn("📢 Отправить", ACC, function() call("announce", { text = ann.Text }, "объявление отправлено") end) }))
	section("Сохранения")
	add(hrow({ btn("💾 Сохранить всех игроков", nil, function() call("saveAll", {}, "сохранено") end) }))
end

local function drawMe()
	section("Перемещение")
	add(hrow({
		btn(if Self.fly then "✈️ Полёт: ВКЛ" else "✈️ Полёт: выкл", if Self.fly then ACC else nil, function() setFly(not Self.fly); render() end),
		btn(if Self.noclip then "👻 Сквозь стены: ВКЛ" else "👻 Сквозь стены: выкл", if Self.noclip then ACC else nil, function() Self.noclip = not Self.noclip; render() end),
	}))
	add(label("Полёт: WASD + Space (вверх) / Ctrl (вниз), направление — по камере.", { TextSize = 12, TextColor3 = DIM }))
	local sp = {}
	for _, m in { 1, 2, 3, 5, 10 } do
		table.insert(sp, btn("×" .. m, if Self.speed == m then ACC else nil, function()
			Self.speed = m
			player:SetAttribute("LC_AdminSpeed", m)
			render()
		end))
	end
	add(hrow({ label("Скорость:", { Size = UDim2.fromOffset(80, 30) }), table.unpack(sp) }))
	section("Телепорт")
	local H = Config.HALF / 2
	add(hrow({
		btn("🏪 Рынок", nil, function() call("tpPos", { x = Config.roadLine(2) + Config.CELL / 2, z = Config.roadLine(3) + Config.CELL / 2 - 20 }, "рынок") end),
		btn("🏠 Мой дом", nil, function() call("tpHome", {}, "дом") end),
		btn("Окраина", nil, function() call("tpPos", { x = -H, z = H }, "Окраина") end),
		btn("Центр", nil, function() call("tpPos", { x = H, z = H }, "Центр") end),
		btn("Промзона", nil, function() call("tpPos", { x = -H, z = -H }, "Промзона") end),
		btn("Холмы", nil, function() call("tpPos", { x = H, z = -H }, "Холмы") end),
	}))
	local xb, zb = box("X", 80), box("Z", 80)
	add(hrow({ label("Координаты:", { Size = UDim2.fromOffset(90, 30) }), xb, zb, btn("ТП", nil, function() call("tpPos", { x = tonumber(xb.Text), z = tonumber(zb.Text) }, "ТП") end) }))
	add(label("Совет: телепорт в закрытый район вернёт вас обратно — сначала откройте районы во вкладке «Прогресс».", { TextSize = 12, TextColor3 = DIM, TextWrapped = true, Size = UDim2.new(1, 0, 0, 34) }))
end

local function drawBans()
	section("Забанить по UserId (даже если игрок не в сети)")
	local idb, rb = box("UserId", 130), box("Причина", 220)
	add(hrow({ idb, rb, btn("Бан", Color3.fromRGB(170, 40, 40), function() call("ban", { target = tonumber(idb.Text), reason = rb.Text, name = idb.Text }, "бан " .. idb.Text) end) }))
	section("Список банов (" .. #Info.bans .. ")")
	if #Info.bans == 0 then add(label("Никто не забанен.", { TextColor3 = DIM })) end
	for _, b in Info.bans do
		add(hrow({
			label(("<b>%s</b> (id %s) — %s <font color='#8a94a0'>· забанил %s</font>"):format(tostring(b.name), b.id, tostring(b.reason), tostring(b.by)), { Size = UDim2.new(1, -110, 0, 30), TextTruncate = Enum.TextTruncate.AtEnd }),
			btn("Разбанить", Color3.fromRGB(40, 120, 60), function() call("unban", { id = b.id }, "разбан " .. b.id) end),
		}))
	end
end

local function drawLog()
	section("Журнал действий администраторов (сессия сервера)")
	if #Info.log == 0 then add(label("Пока пусто.", { TextColor3 = DIM })) end
	for _, e in Info.log do
		add(label(("<font color='#8a94a0'>%s · %s</font>  %s"):format(e.t, e.who, e.text), { TextSize = 13, TextWrapped = true, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }))
	end
end

render = function()
	if not win.Visible then return end
	drawTabs()
	targetL.Text = "Цель команд: <b>" .. targetName() .. "</b>" .. (if targetId == player.UserId then " (вы)" else "")
	clear()
	if not Info then
		add(label("Загрузка…", { TextColor3 = DIM }))
		return
	end
	if tab == "players" then drawPlayers()
	elseif tab == "give" then drawGive()
	elseif tab == "progress" then drawProgress()
	elseif tab == "world" then drawWorld()
	elseif tab == "me" then drawMe()
	elseif tab == "bans" then drawBans()
	else drawLog() end
end

local function refresh()
	local ok, info = pcall(function()
		return AdminRF:InvokeServer("info", {})
	end)
	if ok and info then
		Info = info
		-- drop a target that left
		local found = false
		for _, p in Info.players do
			if p.id == targetId then found = true end
		end
		if not found then targetId = player.UserId end
	end
end
local function cycle(dir)
	if not Info or #Info.players == 0 then return end
	local idx = 1
	for i, p in Info.players do
		if p.id == targetId then idx = i end
	end
	idx = ((idx - 1 + dir) % #Info.players) + 1
	targetId = Info.players[idx].id
	render()
end
prevB.MouseButton1Click:Connect(function() cycle(-1) end)
nextB.MouseButton1Click:Connect(function() cycle(1) end)
selfB.MouseButton1Click:Connect(function() targetId = player.UserId; render() end)

local function toggle()
	win.Visible = not win.Visible
	if win.Visible then
		task.spawn(function()
			refresh()
			render()
		end)
	end
end
toggleB.MouseButton1Click:Connect(toggle)
closeB.MouseButton1Click:Connect(toggle)
UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.F2 and not processed then toggle() end
end)

-- light auto-refresh of the info line while the window is open (does not rebuild text boxes being typed in)
task.spawn(function()
	while true do
		task.wait(3)
		if win.Visible and (tab == "players" or tab == "log" or tab == "bans") and not UserInputService:GetFocusedTextBox() then
			refresh()
			render()
		end
	end
end)
print("[LootCity] developer menu ready (F2)")
