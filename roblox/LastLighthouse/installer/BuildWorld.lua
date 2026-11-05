--[[
	BuildWorld — строит весь мир «Последнего Маяка» прямо в Studio.
	Вызывается установщиком. Создаёт: освещение и небо, северное сияние,
	Облачное море, парящие острова, Маяк, Старого Орина, записки,
	осколки света, мост и паркур на Рушащемся острове.
]]

local Lighting = game:GetService("Lighting")
local terrain = workspace.Terrain

local B = {} -- помощники (в таблице, чтобы не упереться в лимит локальных переменных)

B.rng = Random.new(20261105)

B.palette = {
	white = Color3.fromRGB(236, 234, 246),
	red = Color3.fromRGB(196, 52, 78),
	darkRed = Color3.fromRGB(130, 30, 60),
	metal = Color3.fromRGB(62, 56, 84),
	gold = Color3.fromRGB(255, 205, 100),
	warm = Color3.fromRGB(255, 196, 120),
	wood = Color3.fromRGB(96, 64, 52),
	stone = Color3.fromRGB(92, 86, 116),
	cyan = Color3.fromRGB(110, 230, 255),
	pink = Color3.fromRGB(255, 125, 215),
	violet = Color3.fromRGB(160, 120, 255),
	green = Color3.fromRGB(110, 240, 160),
	leaves = {
		Color3.fromRGB(255, 150, 205),
		Color3.fromRGB(175, 135, 255),
		Color3.fromRGB(95, 205, 185),
		Color3.fromRGB(255, 190, 150),
	},
}

function B.part(parent, props)
	local p = Instance.new(props.ClassName or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		if k ~= "ClassName" then
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

-- Вертикальный цилиндр (в Roblox ось цилиндра — X, поэтому поворачиваем).
function B.cyl(parent, name, position, height, diameter, color, material, extra)
	local props = {
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(height, diameter, diameter),
		CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	}
	if extra then
		for k, v in pairs(extra) do
			props[k] = v
		end
	end
	return B.part(parent, props)
end

function B.ball(parent, name, position, diameter, color, material, extra)
	local props = {
		Name = name,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(diameter, diameter, diameter),
		Position = position,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	}
	if extra then
		for k, v in pairs(extra) do
			props[k] = v
		end
	end
	return B.part(parent, props)
end

function B.light(parent, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range or 12
	l.Brightness = brightness or 1
	l.Shadows = false
	l.Parent = parent
	return l
end

function B.sparkles(parent, color, rate, size)
	local a = Instance.new("Attachment")
	a.Parent = parent
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(color)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size or 0.3), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new(0.1, 1)
	e.Lifetime = NumberRange.new(0.8, 1.6)
	e.Rate = rate or 4
	e.Speed = NumberRange.new(0.5, 1.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Parent = a
	return e
end

function B.billboard(parent, text, color, offsetY, width, maxDistance)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(width or 200, 34)
	gui.StudsOffset = Vector3.new(0, offsetY or 3, 0)
	gui.MaxDistance = maxDistance or 60
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.Parent = gui
	gui.Parent = parent
	return gui
end

function B.folder(parent, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

------------------------------------------------------------------------
-- 0. Чистим старое
------------------------------------------------------------------------
for _, name in ipairs({ "LastLighthouseWorld", "Baseplate" }) do
	local old = workspace:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end
for _, child in ipairs(workspace:GetChildren()) do
	if child:IsA("SpawnLocation") then
		child:Destroy()
	end
end
terrain:Clear()
for _, child in ipairs(terrain:GetChildren()) do
	if child:IsA("Clouds") then
		child:Destroy()
	end
end

local world = B.folder(workspace, "LastLighthouseWorld")
local hubFolder = B.folder(world, "Hub")
local decor = B.folder(world, "Decor")
local shardSpawns = B.folder(world, "ShardSpawns")
local notes = B.folder(world, "Notes")

------------------------------------------------------------------------
-- 1. Свет, небо, атмосфера
------------------------------------------------------------------------
for _, child in ipairs(Lighting:GetChildren()) do
	if child:IsA("Sky") or child:IsA("Atmosphere") or child:IsA("PostEffect") then
		child:Destroy()
	end
end
pcall(function()
	Lighting.Technology = Enum.Technology.Future
end)
Lighting.ClockTime = 23
Lighting.GeographicLatitude = 30
Lighting.Brightness = 2.4
Lighting.Ambient = Color3.fromRGB(48, 40, 92)
Lighting.OutdoorAmbient = Color3.fromRGB(100, 86, 170)
Lighting.ColorShift_Top = Color3.fromRGB(120, 100, 210)
Lighting.ColorShift_Bottom = Color3.fromRGB(40, 20, 80)
Lighting.EnvironmentDiffuseScale = 0.6
Lighting.EnvironmentSpecularScale = 0.8
Lighting.ExposureCompensation = 0.35
Lighting.GlobalShadows = true

do
	local sky = Instance.new("Sky")
	sky.StarCount = 3000
	sky.MoonAngularSize = 16
	sky.CelestialBodiesShown = true
	sky.Parent = Lighting

	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.32
	atmo.Offset = 0.25
	atmo.Color = Color3.fromRGB(112, 92, 196)
	atmo.Decay = Color3.fromRGB(60, 40, 120)
	atmo.Glare = 0.4
	atmo.Haze = 1.6
	atmo.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "LL_Bloom"
	bloom.Intensity = 0.85
	bloom.Size = 30
	bloom.Threshold = 0.92
	bloom.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "LL_Color"
	cc.Brightness = 0.02
	cc.Contrast = 0.12
	cc.Saturation = 0.15
	cc.TintColor = Color3.fromRGB(238, 232, 255)
	cc.Parent = Lighting

	local clouds = Instance.new("Clouds")
	clouds.Cover = 0.5
	clouds.Density = 0.45
	clouds.Color = Color3.fromRGB(185, 165, 235)
	clouds.Parent = terrain
end

------------------------------------------------------------------------
-- 2. Облачное море и материалы ландшафта
------------------------------------------------------------------------
terrain.WaterColor = Color3.fromRGB(140, 110, 225)
terrain.WaterTransparency = 0.35
terrain.WaterReflectance = 1
terrain.WaterWaveSize = 0.35
terrain.WaterWaveSpeed = 6
pcall(function()
	terrain.Decoration = true
end)
terrain:SetMaterialColor(Enum.Material.Grass, Color3.fromRGB(78, 160, 132))
terrain:SetMaterialColor(Enum.Material.Ground, Color3.fromRGB(92, 70, 82))
terrain:SetMaterialColor(Enum.Material.Rock, Color3.fromRGB(96, 86, 128))
terrain:SetMaterialColor(Enum.Material.Slate, Color3.fromRGB(70, 62, 100))
terrain:SetMaterialColor(Enum.Material.Cobblestone, Color3.fromRGB(150, 140, 175))
terrain:FillBlock(CFrame.new(0, -62, 0), Vector3.new(2048, 16, 2048), Enum.Material.Water)

do
	local cloudFolder = B.folder(decor, "CloudSea")
	local colors = { Color3.fromRGB(245, 240, 255), Color3.fromRGB(220, 205, 255), Color3.fromRGB(255, 220, 240) }
	for i = 1, 34 do
		local angle = B.rng:NextNumber(0, math.pi * 2)
		local dist = B.rng:NextNumber(140, 720)
		local center = Vector3.new(math.cos(angle) * dist, -52, math.sin(angle) * dist)
		for j = 1, B.rng:NextInteger(3, 5) do
			local d = B.rng:NextNumber(18, 46)
			B.ball(cloudFolder, "Cloud", center + Vector3.new(B.rng:NextNumber(-30, 30), B.rng:NextNumber(-2, 8), B.rng:NextNumber(-30, 30)), d,
				colors[B.rng:NextInteger(1, #colors)], Enum.Material.SmoothPlastic,
				{ CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Transparency = 0.08 })
		end
	end
end

------------------------------------------------------------------------
-- 3. Северное сияние и светлячки
------------------------------------------------------------------------
do
	local skyFolder = B.folder(world, "Sky")
	local anchor = B.part(skyFolder, {
		Name = "AuroraAnchor",
		Size = Vector3.new(1, 1, 1),
		Position = Vector3.new(0, 0, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	local ribbons = {
		{ a = Vector3.new(-650, 230, -420), b = Vector3.new(650, 260, -480), c1 = Color3.fromRGB(90, 255, 170), c2 = Color3.fromRGB(110, 200, 255), c3 = Color3.fromRGB(220, 120, 255) },
		{ a = Vector3.new(-600, 290, -560), b = Vector3.new(600, 300, -520), c1 = Color3.fromRGB(120, 210, 255), c2 = Color3.fromRGB(255, 120, 220), c3 = Color3.fromRGB(110, 255, 190) },
		{ a = Vector3.new(-520, 250, 480), b = Vector3.new(560, 270, 430), c1 = Color3.fromRGB(255, 130, 220), c2 = Color3.fromRGB(110, 255, 180), c3 = Color3.fromRGB(120, 200, 255) },
		{ a = Vector3.new(500, 260, -500), b = Vector3.new(520, 280, 520), c1 = Color3.fromRGB(110, 255, 180), c2 = Color3.fromRGB(160, 140, 255), c3 = Color3.fromRGB(255, 160, 210) },
	}
	for i, r in ipairs(ribbons) do
		local a0 = Instance.new("Attachment")
		a0.Name = "AuroraA" .. i
		a0.Position = r.a
		a0.Parent = anchor
		local a1 = Instance.new("Attachment")
		a1.Name = "AuroraB" .. i
		a1.Position = r.b
		a1.Parent = anchor
		local beam = Instance.new("Beam")
		beam.Name = "Aurora" .. i
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, r.c1),
			ColorSequenceKeypoint.new(0.5, r.c2),
			ColorSequenceKeypoint.new(1, r.c3),
		})
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.15, 0.6),
			NumberSequenceKeypoint.new(0.5, 0.45),
			NumberSequenceKeypoint.new(0.85, 0.62),
			NumberSequenceKeypoint.new(1, 1),
		})
		beam.Width0 = 150
		beam.Width1 = 120
		beam.CurveSize0 = 160 * (i % 2 == 0 and 1 or -1)
		beam.CurveSize1 = -140 * (i % 2 == 0 and 1 or -1)
		beam.Segments = 48
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.FaceCamera = true
		pcall(function()
			beam.Brightness = 2.5
		end)
		beam.Parent = anchor
	end

	-- светлячки над островом
	local fireflies = B.part(skyFolder, {
		Name = "Fireflies",
		Size = Vector3.new(170, 24, 170),
		Position = Vector3.new(0, 12, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Shape = Enum.ParticleEmitterShape.Box
	e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	e.Color = ColorSequence.new(Color3.fromRGB(255, 240, 150), Color3.fromRGB(170, 255, 200))
	e.LightEmission = 1
	e.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.2, 0.35),
		NumberSequenceKeypoint.new(0.8, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})
	e.Lifetime = NumberRange.new(6, 10)
	e.Rate = 22
	e.Speed = NumberRange.new(0.3, 1)
	e.SpreadAngle = Vector2.new(180, 180)
	e.RotSpeed = NumberRange.new(-30, 30)
	e.Parent = fireflies
end

------------------------------------------------------------------------
-- 4. Парящие острова (ландшафт)
------------------------------------------------------------------------
function B.island(center, radius)
	terrain:FillCylinder(CFrame.new(center - Vector3.new(0, 2, 0)), 4, radius, Enum.Material.Grass)
	terrain:FillCylinder(CFrame.new(center - Vector3.new(0, 6, 0)), 4, radius * 0.97, Enum.Material.Ground)
	local layers = 7
	local depthStep = math.max(4, radius * 0.16)
	for i = 1, layers do
		local f = i / (layers + 1)
		local r = radius * (1 - f) * 0.95
		local y = center.Y - 8 - i * depthStep
		terrain:FillCylinder(CFrame.new(center.X, y, center.Z), depthStep + 2, r, i % 2 == 0 and Enum.Material.Rock or Enum.Material.Slate)
		local below = center.Y - y
		for _ = 1, 3 do
			local a = B.rng:NextNumber(0, math.pi * 2)
			local br = math.min(r * 0.35, below - 6)
			if br > 2 then
				terrain:FillBall(Vector3.new(center.X + math.cos(a) * r * 0.75, y, center.Z + math.sin(a) * r * 0.75), br, Enum.Material.Rock)
			end
		end
	end
	-- висящие кристаллы под островом
	for _ = 1, math.floor(radius / 6) do
		local a = B.rng:NextNumber(0, math.pi * 2)
		local d = B.rng:NextNumber(0, radius * 0.45)
		local length = B.rng:NextNumber(4, 10)
		local y = center.Y - 10 - (1 - d / radius) * radius * 0.9
		local crystal = B.part(decor, {
			Name = "HangingCrystal",
			Size = Vector3.new(1.2, length, 1.2),
			CFrame = CFrame.new(center.X + math.cos(a) * d, y - length / 2, center.Z + math.sin(a) * d) * CFrame.Angles(0, a, math.rad(B.rng:NextNumber(-10, 10))),
			Color = B.rng:NextNumber() > 0.5 and B.palette.cyan or B.palette.pink,
			Material = Enum.Material.Neon,
			CanCollide = false,
			CastShadow = false,
		})
		crystal.Transparency = 0.1
	end
end

function B.tree(position, scale)
	scale = scale or 1
	local model = Instance.new("Model")
	model.Name = "GlowTree"
	local h = B.rng:NextNumber(6, 9) * scale
	B.cyl(model, "Trunk", position + Vector3.new(0, h / 2, 0), h, 1.5 * scale, B.palette.wood, Enum.Material.Wood)
	local color = B.palette.leaves[B.rng:NextInteger(1, #B.palette.leaves)]
	for i = 1, 3 do
		local offset = Vector3.new(B.rng:NextNumber(-2, 2), h + B.rng:NextNumber(-0.5, 2.5), B.rng:NextNumber(-2, 2)) * scale
		B.ball(model, "Leaves", position + offset, B.rng:NextNumber(6, 8.5) * scale, color)
	end
	for _ = 1, 4 do
		local offset = Vector3.new(B.rng:NextNumber(-3.2, 3.2), h + B.rng:NextNumber(-1.5, 1), B.rng:NextNumber(-3.2, 3.2)) * scale
		B.ball(model, "GlowFruit", position + offset, 0.7 * scale, B.palette.gold, Enum.Material.Neon, { CanCollide = false })
	end
	model.Parent = decor
	return model
end

function B.crystalCluster(position, color)
	local model = Instance.new("Model")
	model.Name = "CrystalCluster"
	for i = 1, B.rng:NextInteger(3, 5) do
		local h = B.rng:NextNumber(2.5, 6)
		B.part(model, {
			Name = "Crystal",
			Size = Vector3.new(1.2, h, 1.2),
			CFrame = CFrame.new(position + Vector3.new(B.rng:NextNumber(-1.5, 1.5), h / 2 - 0.5, B.rng:NextNumber(-1.5, 1.5)))
				* CFrame.Angles(math.rad(B.rng:NextNumber(-25, 25)), B.rng:NextNumber(0, 6.28), math.rad(B.rng:NextNumber(-25, 25))),
			Color = color,
			Material = Enum.Material.Neon,
			CastShadow = false,
		})
	end
	B.light(model:GetChildren()[1], color, 14, 1.2)
	model.Parent = decor
end

function B.mushroom(position, scale)
	local model = Instance.new("Model")
	model.Name = "GlowMushroom"
	scale = scale or 1
	B.cyl(model, "Stem", position + Vector3.new(0, 1 * scale, 0), 2 * scale, 0.7 * scale, Color3.fromRGB(240, 230, 220))
	local cap = B.ball(model, "Cap", position + Vector3.new(0, 2.2 * scale, 0), 2.2 * scale, B.palette.pink, Enum.Material.Neon)
	cap.Size = Vector3.new(2.2, 2.2, 2.2) * scale
	B.light(cap, B.palette.pink, 10, 1)
	model.Parent = decor
end

function B.lanternPost(position)
	local model = Instance.new("Model")
	model.Name = "LanternPost"
	B.part(model, { Name = "Post", Size = Vector3.new(0.5, 6, 0.5), Position = position + Vector3.new(0, 3, 0), Color = B.palette.metal, Material = Enum.Material.Metal })
	B.part(model, { Name = "Cap", Size = Vector3.new(1.6, 0.3, 1.6), Position = position + Vector3.new(0, 7.1, 0), Color = B.palette.metal, Material = Enum.Material.Metal })
	local lamp = B.part(model, { Name = "Lamp", Size = Vector3.new(1, 1.2, 1), Position = position + Vector3.new(0, 6.3, 0), Color = B.palette.warm, Material = Enum.Material.Neon, CastShadow = false })
	B.light(lamp, B.palette.warm, 16, 1.2)
	model.Parent = decor
end

function B.shardSpawn(position, value)
	local p = B.part(shardSpawns, {
		Name = "ShardSpawn",
		Size = Vector3.new(1, 1, 1),
		Position = position,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	if value then
		p:SetAttribute("Value", value)
	end
	return p
end

function B.note(position, index, facing)
	local cf = CFrame.lookAt(position, Vector3.new(facing.X, position.Y, facing.Z))
	B.part(notes, { Name = "NoteStand", Size = Vector3.new(1, 2.6, 1), CFrame = cf * CFrame.new(0, 1.3, 0), Color = B.palette.wood, Material = Enum.Material.Wood })
	local paper = B.part(notes, {
		Name = "Note" .. index,
		Size = Vector3.new(2, 0.15, 1.5),
		CFrame = cf * CFrame.new(0, 2.75, 0) * CFrame.Angles(math.rad(25), 0, 0),
		Color = Color3.fromRGB(245, 225, 175),
		CanCollide = false,
	})
	paper:SetAttribute("NoteIndex", index)
	B.light(paper, Color3.fromRGB(255, 225, 160), 9, 1)
	B.sparkles(paper, Color3.fromRGB(255, 230, 170), 3, 0.25)
	B.billboard(paper, "📜", Color3.new(1, 1, 1), 2.2, 40, 70)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Прочитать"
	prompt.ObjectText = "Записка"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = paper
end

-- Каменный «мостик» из парящих ступенек между двумя точками.
function B.stoneBridge(from, to, color)
	local delta = to - from
	local flat = Vector3.new(delta.X, 0, delta.Z)
	local steps = math.max(math.ceil(flat.Magnitude / 10), math.ceil(math.abs(delta.Y) / 3.5))
	for i = 1, steps - 1 do
		local p = from + delta * (i / steps)
		B.part(decor, {
			Name = "SkyStone",
			Size = Vector3.new(6, 1.5, 6),
			CFrame = CFrame.new(p - Vector3.new(0, 0.75, 0)) * CFrame.Angles(0, B.rng:NextNumber(0, 6.28), 0),
			Color = color or B.palette.stone,
			Material = Enum.Material.Slate,
		})
		local glow = B.part(decor, {
			Name = "SkyStoneGlow",
			Size = Vector3.new(4, 0.3, 4),
			Position = p - Vector3.new(0, 1.7, 0),
			Color = B.palette.cyan,
			Material = Enum.Material.Neon,
			CanCollide = false,
			CastShadow = false,
		})
		glow.Transparency = 0.3
		if i % 2 == 0 then
			B.shardSpawn(p + Vector3.new(0, 2.5, 0))
		end
	end
end

------------------------------------------------------------------------
-- 5. Главный остров
------------------------------------------------------------------------
local HUB_RADIUS = 80
B.island(Vector3.new(0, 0, 0), HUB_RADIUS)
-- небольшие холмики
for _ = 1, 10 do
	local a = B.rng:NextNumber(0, math.pi * 2)
	local d = B.rng:NextNumber(45, 70)
	terrain:FillBall(Vector3.new(math.cos(a) * d, -3, math.sin(a) * d), B.rng:NextNumber(5, 8), Enum.Material.Grass)
end
-- дорожка от места появления к Маяку
terrain:FillBlock(CFrame.new(0, -1.5, 8), Vector3.new(8, 3, 46), Enum.Material.Cobblestone)
-- дорожка к мосту на восток
terrain:FillBlock(CFrame.new(40, -1.5, 0), Vector3.new(80, 3, 8), Enum.Material.Cobblestone)

local LIGHTHOUSE_POS = Vector3.new(0, 0, -30)
local SPAWN_POS = Vector3.new(0, 0, 45)

do -- место появления
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = SPAWN_POS + Vector3.new(0, 0.5, 0)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Parent = hubFolder
	local disc = B.cyl(hubFolder, "SpawnDisc", SPAWN_POS + Vector3.new(0, 0.15, 0), 0.3, 12, B.palette.cyan, Enum.Material.Neon, { CanCollide = false, CastShadow = false })
	disc.Transparency = 0.35
	B.cyl(hubFolder, "SpawnBase", SPAWN_POS + Vector3.new(0, 0.05, 0), 0.4, 14, B.palette.stone, Enum.Material.Slate)
	B.sparkles(disc, B.palette.cyan, 8, 0.4)
end

for i = 0, 3 do -- фонари вдоль дорожки
	local z = 36 - i * 12
	B.lanternPost(Vector3.new(-6, 0, z))
	B.lanternPost(Vector3.new(6, 0, z))
end
for i = 1, 3 do
	B.lanternPost(Vector3.new(18 + i * 16, 0, 6))
end

------------------------------------------------------------------------
-- 6. Маяк
------------------------------------------------------------------------
do
	local L = LIGHTHOUSE_POS
	local lh = Instance.new("Model")
	lh.Name = "Lighthouse"
	local plinth = B.cyl(lh, "Plinth", L + Vector3.new(0, 1.5, 0), 3, 26, B.palette.stone, Enum.Material.Slate)
	lh.PrimaryPart = plinth
	for i = 1, 3 do -- ступени
		B.part(lh, { Name = "Step", Size = Vector3.new(9, i, 2.2), Position = L + Vector3.new(0, i / 2, 13 + (4 - i) * 2 - 1), Color = B.palette.stone, Material = Enum.Material.Slate })
	end
	for i = 0, 5 do -- башня в полоску
		local d = 14 - i * 0.8
		B.cyl(lh, "Tower" .. i, L + Vector3.new(0, 6 + i * 6, 0), 6, d, i % 2 == 0 and B.palette.white or B.palette.red)
	end
	for _, y in ipairs({ 12, 22, 32 }) do -- окошки
		local d = 14 - math.floor((y - 3) / 6) * 0.8
		for _, side in ipairs({ 1, -1 }) do
			local w = B.part(lh, { Name = "Window", Size = Vector3.new(1.4, 2.2, 0.5), Position = L + Vector3.new(0, y, side * (d / 2 + 0.1)), Color = B.palette.warm, Material = Enum.Material.Neon, CastShadow = false })
			if side == 1 then
				B.light(w, B.palette.warm, 8, 0.6)
			end
		end
	end
	B.part(lh, { Name = "Door", Size = Vector3.new(3.4, 5.2, 0.6), Position = L + Vector3.new(0, 5.6, 6.85), Color = B.palette.wood, Material = Enum.Material.Wood })
	B.part(lh, { Name = "DoorGlow", Size = Vector3.new(4.2, 0.5, 0.7), Position = L + Vector3.new(0, 8.5, 6.9), Color = B.palette.gold, Material = Enum.Material.Neon, CastShadow = false })

	B.cyl(lh, "Balcony", L + Vector3.new(0, 39.5, 0), 1, 16.5, B.palette.metal, Enum.Material.Metal)
	local posts = 16
	for i = 0, posts - 1 do
		local a = i / posts * math.pi * 2
		local r = 7.8
		B.part(lh, { Name = "RailPost", Size = Vector3.new(0.3, 2.2, 0.3), Position = L + Vector3.new(math.cos(a) * r, 41, math.sin(a) * r), Color = B.palette.metal, Material = Enum.Material.Metal })
		local a2 = (i + 0.5) / posts * math.pi * 2
		local seg = 2 * math.pi * r / posts
		B.part(lh, {
			Name = "Rail",
			Size = Vector3.new(seg + 0.2, 0.25, 0.25),
			CFrame = CFrame.new(L + Vector3.new(math.cos(a2) * r, 42.1, math.sin(a2) * r)) * CFrame.Angles(0, -a2 - math.pi / 2, 0),
			Color = B.palette.gold,
			Material = Enum.Material.Metal,
		})
	end
	local glass = B.cyl(lh, "LanternGlass", L + Vector3.new(0, 43.5, 0), 7, 9, Color3.fromRGB(255, 240, 210), Enum.Material.Glass)
	glass.Transparency = 0.6
	for i = 0, 5 do
		local a = i / 6 * math.pi * 2
		B.part(lh, { Name = "Frame", Size = Vector3.new(0.4, 7, 0.4), Position = L + Vector3.new(math.cos(a) * 4.4, 43.5, math.sin(a) * 4.4), Color = B.palette.metal, Material = Enum.Material.Metal })
	end
	local lantern = B.ball(lh, "Lantern", L + Vector3.new(0, 43.5, 0), 3.6, B.palette.gold, Enum.Material.Neon, { CanCollide = false, CastShadow = false })
	B.light(lantern, Color3.fromRGB(255, 215, 140), 32, 2)
	B.sparkles(lantern, B.palette.gold, 10, 0.6)

	local roof = { { 47.5, 1, 11 }, { 48.6, 1.2, 8.6 }, { 49.8, 1.2, 6 }, { 50.9, 1, 3.6 } }
	for _, r in ipairs(roof) do
		B.cyl(lh, "Roof", L + Vector3.new(0, r[1], 0), r[2], r[3], B.palette.darkRed)
	end
	B.part(lh, { Name = "Spire", Size = Vector3.new(0.4, 4, 0.4), Position = L + Vector3.new(0, 53.4, 0), Color = B.palette.metal, Material = Enum.Material.Metal })
	local tip = B.ball(lh, "SpireTip", L + Vector3.new(0, 55.6, 0), 1, B.palette.red, Enum.Material.Neon, { CastShadow = false })
	B.light(tip, B.palette.red, 10, 1)

	-- вращающийся луч (крутится на клиенте, см. Effects)
	local pivot = B.part(lh, {
		Name = "BeamPivot",
		Size = Vector3.new(1, 1, 1),
		Position = L + Vector3.new(0, 43.5, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
	local origin = Instance.new("Attachment")
	origin.Name = "Origin"
	origin.Parent = pivot
	for _, dir in ipairs({ 1, -1 }) do
		local finish = Instance.new("Attachment")
		finish.Name = dir == 1 and "EndA" or "EndB"
		finish.Position = Vector3.new(0, -10, 200 * dir)
		finish.Parent = pivot
		local layers = { { w0 = 2.5, w1 = 34, t0 = 0.35 }, { w0 = 5, w1 = 70, t0 = 0.8 } }
		for li, layer in ipairs(layers) do
			local beam = Instance.new("Beam")
			beam.Name = "LightBeam" .. li
			beam.Attachment0 = origin
			beam.Attachment1 = finish
			beam.Color = ColorSequence.new(Color3.fromRGB(255, 235, 170), Color3.fromRGB(255, 200, 140))
			beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, layer.t0), NumberSequenceKeypoint.new(1, 1) })
			beam.Width0 = layer.w0
			beam.Width1 = layer.w1
			beam.LightEmission = 1
			beam.LightInfluence = 0
			beam.FaceCamera = true
			beam.Segments = 1
			beam.Parent = pivot
		end
	end

	-- площадка для вклада света
	local pad = B.cyl(lh, "DepositPad", L + Vector3.new(0, 3.1, 10.2), 0.3, 6, B.palette.gold, Enum.Material.Neon, { CanCollide = false, CastShadow = false })
	pad.Transparency = 0.2
	local rise = B.sparkles(pad, B.palette.gold, 14, 0.45)
	rise.EmissionDirection = Enum.NormalId.Right -- ось цилиндра смотрит вверх
	rise.SpreadAngle = Vector2.new(15, 15)
	rise.Speed = NumberRange.new(3, 6)
	B.billboard(pad, "🔥 Отдать свет Маяку", B.palette.gold, 3.5, 260, 50)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Отдать свет"
	prompt.ObjectText = "Маяк"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad

	lh.Parent = world
end

------------------------------------------------------------------------
-- 7. Старый Орин
------------------------------------------------------------------------
do
	local pos = Vector3.new(16, 0, -6)
	local cf = CFrame.lookAt(pos, Vector3.new(SPAWN_POS.X, pos.Y, SPAWN_POS.Z))
	local orin = Instance.new("Model")
	orin.Name = "Orin"
	local function at(x, y, z)
		return (cf * CFrame.new(x, y, z)).Position
	end
	local robe = B.part(orin, {
		Name = "Robe",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(4, 2.8, 2.8),
		CFrame = cf * CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(52, 62, 150),
	})
	orin.PrimaryPart = robe
	B.part(orin, {
		Name = "Belt",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.35, 2.9, 2.9),
		CFrame = cf * CFrame.new(0, 2.7, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = B.palette.gold,
		Material = Enum.Material.Metal,
	})
	B.ball(orin, "Body", at(0, 4, 0), 2.5, Color3.fromRGB(60, 72, 170))
	local head = B.ball(orin, "Head", at(0, 5.45, 0), 1.9, Color3.fromRGB(242, 204, 176))
	head.CFrame = cf * CFrame.new(0, 5.45, 0)
	B.ball(orin, "Beard", at(0, 4.85, -0.55), 1.5, Color3.fromRGB(245, 245, 250))
	B.ball(orin, "BeardTip", at(0, 4.2, -0.75), 1, Color3.fromRGB(245, 245, 250))
	B.ball(orin, "Nose", at(0, 5.4, -0.95), 0.4, Color3.fromRGB(240, 170, 160))
	for _, side in ipairs({ -1, 1 }) do
		B.ball(orin, "Eye", at(side * 0.35, 5.65, -0.82), 0.26, Color3.fromRGB(25, 20, 45))
		B.part(orin, { Name = "Brow", Size = Vector3.new(0.5, 0.14, 0.14), CFrame = cf * CFrame.new(side * 0.38, 5.95, -0.8), Color = Color3.fromRGB(245, 245, 250) })
	end
	B.part(orin, {
		Name = "HatBrim",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.25, 3.2, 3.2),
		CFrame = cf * CFrame.new(0, 6.25, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(70, 40, 110),
	})
	B.part(orin, {
		Name = "HatTop",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.6, 1.7, 1.7),
		CFrame = cf * CFrame.new(0, 7.1, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(70, 40, 110),
	})
	B.ball(orin, "HatStar", at(0, 7.1, -0.85), 0.5, B.palette.gold, Enum.Material.Neon)
	B.part(orin, { Name = "Staff", Size = Vector3.new(0.3, 6.4, 0.3), CFrame = cf * CFrame.new(1.7, 3.2, -0.4), Color = B.palette.wood, Material = Enum.Material.Wood })
	local staffLamp = B.ball(orin, "StaffLantern", at(1.7, 6.6, -0.4), 0.9, B.palette.gold, Enum.Material.Neon, { CastShadow = false })
	B.light(staffLamp, B.palette.warm, 14, 1.4)
	B.sparkles(staffLamp, B.palette.gold, 5, 0.3)
	local tag = B.billboard(head, "Старый Орин", B.palette.gold, 3.2, 200, 60)
	local sub = tag.TextLabel:Clone()
	sub.Text = "Смотритель Маяка"
	sub.TextColor3 = Color3.fromRGB(200, 190, 255)
	sub.Size = UDim2.fromScale(1, 0.6)
	sub.Position = UDim2.fromScale(0, 1)
	sub.Parent = tag
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Поговорить"
	prompt.ObjectText = "Старый Орин"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = head
	orin.Parent = world
end

------------------------------------------------------------------------
-- 8. Украшения главного острова, осколки, первая записка
------------------------------------------------------------------------
function B.isFree(p)
	if (p - LIGHTHOUSE_POS).Magnitude < 20 then
		return false
	end
	if math.abs(p.X) < 9 and p.Z > -20 and p.Z < 52 then
		return false
	end
	if p.X > 10 and math.abs(p.Z) < 9 then
		return false
	end
	if (p - Vector3.new(16, 0, -6)).Magnitude < 7 then
		return false
	end
	return true
end

-- Высота земли (ландшафта) под точкой.
function B.ground(p)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { terrain }
	local ok, result = pcall(function()
		return workspace:Raycast(p + Vector3.new(0, 40, 0), Vector3.new(0, -80, 0), params)
	end)
	if ok and result then
		return Vector3.new(p.X, result.Position.Y, p.Z)
	end
	return p
end

function B.randomSpot(minR, maxR, center)
	center = center or Vector3.new()
	for _ = 1, 40 do
		local a = B.rng:NextNumber(0, math.pi * 2)
		local d = B.rng:NextNumber(minR, maxR)
		local p = center + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		if center.Magnitude > 1 or B.isFree(p) then
			return B.ground(p)
		end
	end
	return B.ground(center + Vector3.new(minR, 0, 0))
end

for _ = 1, 16 do
	B.tree(B.randomSpot(30, 72), B.rng:NextNumber(0.9, 1.3))
end
for i = 1, 8 do
	B.crystalCluster(B.randomSpot(25, 74), i % 2 == 0 and B.palette.cyan or B.palette.violet)
end
for _ = 1, 10 do
	B.mushroom(B.randomSpot(20, 70), B.rng:NextNumber(0.8, 1.5))
end
for _ = 1, 26 do
	B.shardSpawn(B.randomSpot(14, 74) + Vector3.new(0, 2.5, 0))
end
B.note(Vector3.new(-14, 0, -12), 1, SPAWN_POS)

------------------------------------------------------------------------
-- 9. Соседние острова (записки 2–4)
------------------------------------------------------------------------
do
	local islands = {
		{ center = Vector3.new(-140, 16, -60), radius = 26, from = Vector3.new(-76, 0, -22), note = 2 },
		{ center = Vector3.new(-70, 28, 150), radius = 22, from = Vector3.new(-30, 0, 72), note = 3 },
		{ center = Vector3.new(90, 24, -150), radius = 24, from = Vector3.new(38, 0, -68), note = 4 },
	}
	for _, info in ipairs(islands) do
		B.island(info.center, info.radius)
		local toCenter = (info.center - info.from)
		local flat = Vector3.new(toCenter.X, 0, toCenter.Z).Unit
		local edge = info.center - flat * (info.radius - 3)
		B.stoneBridge(info.from, Vector3.new(edge.X, info.center.Y, edge.Z))
		for _ = 1, 3 do
			B.tree(B.randomSpot(6, info.radius - 6, info.center), B.rng:NextNumber(0.8, 1.1))
		end
		B.crystalCluster(B.randomSpot(4, info.radius - 5, info.center), B.palette.pink)
		B.mushroom(B.randomSpot(4, info.radius - 5, info.center), 1.2)
		for _ = 1, 6 do
			B.shardSpawn(B.randomSpot(3, info.radius - 4, info.center) + Vector3.new(0, 2.5, 0))
		end
		B.note(info.center + Vector3.new(0, 0, 0), info.note, Vector3.new(0, 0, 0))
	end
	-- парящие камни-декорации вокруг
	for _ = 1, 14 do
		local a = B.rng:NextNumber(0, math.pi * 2)
		local d = B.rng:NextNumber(110, 260)
		local c = Vector3.new(math.cos(a) * d, B.rng:NextNumber(-10, 60), math.sin(a) * d)
		terrain:FillBall(c, B.rng:NextNumber(3, 7), Enum.Material.Rock)
	end
end

------------------------------------------------------------------------
-- 10. Мост и паркур «Рушащийся остров»
------------------------------------------------------------------------
do
	-- деревянный мост от главного острова
	for i = 0, 11 do
		local x = 74 + i * 2.1
		B.part(decor, { Name = "Plank", Size = Vector3.new(1.9, 0.5, 7), Position = Vector3.new(x, -0.25, 0), Color = Color3.fromRGB(120, 84, 66), Material = Enum.Material.WoodPlanks })
	end
	for _, z in ipairs({ -3.8, 3.8 }) do
		B.part(decor, { Name = "Rope", Size = Vector3.new(25, 0.25, 0.25), Position = Vector3.new(85.5, 2.5, z), Color = B.palette.gold, Material = Enum.Material.Neon, CastShadow = false })
		for _, x in ipairs({ 74, 97 }) do
			B.part(decor, { Name = "BridgePost", Size = Vector3.new(0.6, 3.5, 0.6), Position = Vector3.new(x, 1.5, z), Color = B.palette.wood, Material = Enum.Material.Wood })
		end
	end
	local sign = B.part(decor, { Name = "Sign", Size = Vector3.new(0.4, 3, 8), Position = Vector3.new(70, 4.5, 6), Color = B.palette.wood, Material = Enum.Material.Wood })
	B.billboard(sign, "⚠️ Рушащийся остров →", Color3.fromRGB(255, 180, 140), 3, 280, 80)

	local obby = B.folder(world, "Obby")
	local folders = {
		S = B.folder(obby, "Static"),
		F = B.folder(obby, "FallingPlatforms"),
		B = B.folder(obby, "BlinkPlatforms"),
		J = B.folder(obby, "JumpPads"),
		C = B.folder(obby, "Checkpoints"),
	}
	local colors = {
		S = { body = Color3.fromRGB(120, 100, 210), rim = B.palette.cyan },
		F = { body = Color3.fromRGB(230, 150, 120), rim = Color3.fromRGB(255, 120, 90) },
		C = { body = Color3.fromRGB(80, 70, 140), rim = B.palette.green },
	}

	local function platform(kind, top, size, phase)
		local thickness = 1.4
		local center = top - Vector3.new(0, thickness / 2, 0)
		if kind == "B" then
			local p = B.part(folders.B, {
				Name = "Blink",
				Size = Vector3.new(size, thickness, size),
				Position = center,
				Color = phase == 0 and B.palette.cyan or B.palette.pink,
				Material = Enum.Material.Neon,
				CastShadow = false,
			})
			p:SetAttribute("Phase", phase)
			return p
		end
		local folder = kind == "F" and folders.F or folders.S
		local sx, sz = size, size
		if type(size) == "table" then
			sx, sz = size[1], size[2]
		end
		local c = colors[kind] or colors.S
		local p = B.part(folder, {
			Name = kind == "F" and "Falling" or "Platform",
			Size = Vector3.new(sx, thickness, sz),
			Position = center,
			Color = c.body,
			Material = kind == "F" and Enum.Material.Slate or Enum.Material.SmoothPlastic,
		})
		local rim = B.part(kind == "F" and p or folders.S, {
			Name = "Rim",
			Size = Vector3.new(sx + 0.5, 0.35, sz + 0.5),
			Position = center - Vector3.new(0, thickness / 2 + 0.05, 0),
			Color = c.rim,
			Material = Enum.Material.Neon,
			CanCollide = false,
			CastShadow = false,
		})
		return p
	end

	local cpIndex = 0
	local function checkpoint(top)
		platform("C", top, 14)
		cpIndex = cpIndex + 1
		local cp = B.cyl(folders.C, "Checkpoint" .. cpIndex, top + Vector3.new(0, 0.2, 0), 0.4, 7, B.palette.green, Enum.Material.Neon, { CastShadow = false })
		cp.Transparency = 0.2
		cp:SetAttribute("Index", cpIndex)
		B.part(folders.S, { Name = "FlagPole", Size = Vector3.new(0.3, 7, 0.3), Position = top + Vector3.new(5, 3.5, 5), Color = B.palette.metal, Material = Enum.Material.Metal })
		local flag = B.part(folders.S, { Name = "Flag", Size = Vector3.new(0.1, 1.8, 2.8), Position = top + Vector3.new(5, 6, 3.5), Color = B.palette.green, Material = Enum.Material.Neon, CanCollide = false })
		B.billboard(flag, "Чекпоинт " .. cpIndex, B.palette.green, 2, 160, 60)
	end

	local cursor = Vector3.new(104, 0, 0)
	checkpoint(cursor)
	local path = {
		-- разминка
		{ 12, 1, 0, "S", 8 }, { 12, 1, 4, "S", 7 }, { 12, 1, -4, "S", 7 }, { 12, 0, 0, "S", 8 },
		-- падающие платформы
		{ 12, 0, 3, "F", 7 }, { 12, 1, -3, "F", 7 }, { 12, 0, 3, "F", 7 }, { 12, 1, -3, "F", 7 }, { 12, 0, 0, "F", 7 },
		{ 14, 0, 0, "CP" },
		-- мигающие платформы с островками отдыха
		{ 12, 0, 0, "B0", 7 }, { 11, 0, 0, "S", 6 }, { 11, 1, 0, "B1", 7 }, { 11, 0, 0, "S", 6 }, { 11, 1, 0, "B0", 7 }, { 11, 0, 0, "S", 6 },
		{ 13, 0, 0, "CP" },
		-- батут
		{ 13, 0, 0, "J", 9 }, { 16, 14, 0, "S", 10 }, { 12, 1, 0, "S", 7 },
		-- узкие балки зигзагом
		{ 13, 0, 3.5, "S", { 12, 3 } }, { 13, 0, -7, "S", { 12, 3 } }, { 13, 0, 7, "S", { 12, 3 } }, { 13, 0, -3.5, "S", { 12, 3 } },
		{ 14, 0, 0, "CP" },
		-- финальное испытание
		{ 12, 1, 0, "F", 6 }, { 11, 0, 3, "B1", 6 }, { 11, 0, 0, "S", 5 }, { 11, 1, -3, "F", 6 }, { 11, 0, 0, "B0", 6 }, { 11, 0, 0, "S", 5 }, { 11, 1, 0, "F", 6 },
		-- лестница к вершине
		{ 12, 3, 0, "S", 7 }, { 11, 3, 4, "S", 7 }, { 11, 3, -4, "S", 7 }, { 11, 3, 0, "S", 7 },
	}
	for i, step in ipairs(path) do
		cursor = cursor + Vector3.new(step[1], step[2], step[3])
		local kind = step[4]
		if kind == "CP" then
			checkpoint(cursor)
		elseif kind == "J" then
			platform("S", cursor, step[5])
			local pad = B.cyl(folders.J, "JumpPad", cursor + Vector3.new(0, 0.25, 0), 0.5, 5.5, B.palette.green, Enum.Material.Neon, { CastShadow = false })
			B.sparkles(pad, B.palette.green, 10, 0.4)
			B.billboard(pad, "⬆ БАТУТ", B.palette.green, 2.5, 140, 50)
		elseif kind == "B0" or kind == "B1" then
			platform("B", cursor, step[5], kind == "B0" and 0 or 1)
		else
			platform(kind, cursor, step[5])
		end
		if i % 3 == 0 and kind ~= "CP" then
			B.shardSpawn(cursor + Vector3.new(0, 3, 0), 12)
		end
	end

	-- вершина: остров с Осколком Звезды
	local summit = cursor + Vector3.new(30, 0, 0)
	B.island(summit, 24)
	terrain:FillBlock(CFrame.new(cursor + Vector3.new(14, -1.5, 0)), Vector3.new(16, 3, 8), Enum.Material.Cobblestone)
	local finish = B.cyl(obby, "Finish", summit + Vector3.new(0, 0.25, 0), 0.5, 10, B.palette.gold, Enum.Material.Neon, { CastShadow = false })
	finish.Transparency = 0.15
	B.sparkles(finish, B.palette.gold, 16, 0.5)
	local star = B.part(obby, {
		Name = "StarShard",
		Size = Vector3.new(4, 4, 4),
		CFrame = CFrame.new(summit + Vector3.new(0, 9, 0)) * CFrame.Angles(math.rad(45), math.rad(30), math.rad(45)),
		Color = B.palette.pink,
		Material = Enum.Material.Neon,
		CanCollide = false,
		CastShadow = false,
	})
	B.light(star, B.palette.pink, 30, 2)
	B.sparkles(star, B.palette.pink, 20, 0.8)
	B.billboard(star, "✦ ОСКОЛОК ЗВЕЗДЫ ✦", B.palette.pink, 5, 300, 200)
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2
		B.crystalCluster(summit + Vector3.new(math.cos(a) * 15, 0, math.sin(a) * 15), i % 2 == 0 and B.palette.pink or B.palette.cyan)
	end
	B.note(summit + Vector3.new(-8, 0, 8), 5, summit)

	-- портал домой
	local portal = B.cyl(obby, "ReturnPortal", summit + Vector3.new(10, 4, -10), 0.6, 7, B.palette.violet, Enum.Material.Neon, { CanCollide = false, CastShadow = false })
	portal.CFrame = CFrame.new(summit + Vector3.new(10, 4, -10)) * CFrame.Angles(0, math.rad(45), 0)
	portal.Transparency = 0.25
	portal:SetAttribute("Teleport", "Hub")
	B.sparkles(portal, B.palette.violet, 20, 0.6)
	B.billboard(portal, "🏠 Домой", B.palette.violet, 5, 160, 60)
end

------------------------------------------------------------------------
-- 11. Тень, кружащая вдали
------------------------------------------------------------------------
do
	local wisp = Instance.new("Model")
	wisp.Name = "ShadowWisp"
	local core = B.ball(wisp, "Core", Vector3.new(0, 40, -300), 18, Color3.fromRGB(12, 6, 24), Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	wisp.PrimaryPart = core
	for i = 1, 7 do
		local offset = Vector3.new(B.rng:NextNumber(-10, 10), B.rng:NextNumber(-6, 8), B.rng:NextNumber(-4, 10))
		B.ball(wisp, "Smoke", core.Position + offset, B.rng:NextNumber(7, 12), Color3.fromRGB(20, 10, 36), Enum.Material.SmoothPlastic, { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	end
	for _, side in ipairs({ -1, 1 }) do
		local eye = B.ball(wisp, "Eye", core.Position + Vector3.new(side * 3.2, 2, -8.2), 2.2, Color3.fromRGB(190, 120, 255), Enum.Material.Neon, { CanCollide = false, CanQuery = false, CanTouch = false })
		B.light(eye, Color3.fromRGB(170, 100, 255), 20, 2)
	end
	local a = Instance.new("Attachment")
	a.Parent = core
	local smoke = Instance.new("ParticleEmitter")
	smoke.Color = ColorSequence.new(Color3.fromRGB(30, 10, 50), Color3.fromRGB(5, 0, 10))
	smoke.LightEmission = 0
	smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 14) })
	smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	smoke.Lifetime = NumberRange.new(2.5, 4)
	smoke.Rate = 18
	smoke.Speed = NumberRange.new(2, 5)
	smoke.SpreadAngle = Vector2.new(180, 180)
	smoke.Parent = a
	wisp.Parent = world
end

B.folder(world, "ActiveShards")
B.folder(world, "Pets")

pcall(function()
	workspace.StreamingEnabled = false
end)
