--[[
	Effects — всё красивое, что считается на компьютере игрока:
	парящие осколки, вращающийся луч Маяка, северное сияние,
	кружащая вдали Тень, покачивание духов, вспышки и конфетти.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LastLighthouse"):WaitForChild("Config"))
local Sound = require(script.Parent:WaitForChild("Sound"))

local player = Players.LocalPlayer
local Effects = {}

local world = workspace:WaitForChild("LastLighthouseWorld")
local shardBase = setmetatable({}, { __mode = "k" })
local shadowActive = false
local lighting = {}

local function tween(inst, time, props, style, direction)
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function getRoot()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

------------------------------------------------------------------------
-- Осколки: парят и вращаются
------------------------------------------------------------------------
local function trackShard(part)
	if part:IsA("BasePart") then
		shardBase[part] = { position = part.Position, phase = math.random() * math.pi * 2 }
	end
end

local function animateShards(t)
	local folder = world:FindFirstChild("ActiveShards")
	if not folder then
		return
	end
	for _, part in ipairs(folder:GetChildren()) do
		local base = shardBase[part]
		if not base and part:IsA("BasePart") then
			trackShard(part)
			base = shardBase[part]
		end
		if base then
			local y = math.sin(t * 2 + base.phase) * 0.45
			part.CFrame = CFrame.new(base.position + Vector3.new(0, y, 0)) * CFrame.Angles(t * 0.9 + base.phase, t * 1.4, math.rad(45))
		end
	end
end

------------------------------------------------------------------------
-- Маяк: вращающийся луч
------------------------------------------------------------------------
local beamPivot, beamPivotBase
local beams = {}

local function setupLighthouse()
	local lighthouse = world:FindFirstChild("Lighthouse")
	if not lighthouse then
		return
	end
	beamPivot = lighthouse:FindFirstChild("BeamPivot", true)
	if beamPivot then
		beamPivotBase = beamPivot.CFrame
		for _, child in ipairs(beamPivot:GetDescendants()) do
			if child:IsA("Beam") then
				table.insert(beams, { beam = child, width = child.Width1 })
			end
		end
	end
	local function applyLevel()
		local level = lighthouse:GetAttribute("Level") or 1
		local k = 0.6 + level * 0.12
		for _, b in ipairs(beams) do
			b.beam.Width1 = b.width * k
		end
	end
	lighthouse:GetAttributeChangedSignal("Level"):Connect(applyLevel)
	applyLevel()
end

local function animateLighthouse(t)
	if beamPivot and beamPivotBase then
		local speed = shadowActive and 0.25 or 0.55
		beamPivot.CFrame = beamPivotBase * CFrame.Angles(0, t * speed, 0)
	end
end

------------------------------------------------------------------------
-- Северное сияние
------------------------------------------------------------------------
local aurora = {}
local function setupAurora()
	local sky = world:FindFirstChild("Sky")
	if not sky then
		return
	end
	for _, b in ipairs(sky:GetDescendants()) do
		if b:IsA("Beam") then
			table.insert(aurora, { beam = b, c0 = b.CurveSize0, c1 = b.CurveSize1, phase = math.random() * 10 })
		end
	end
end

local function animateAurora(t)
	for _, a in ipairs(aurora) do
		a.beam.CurveSize0 = a.c0 + math.sin(t * 0.25 + a.phase) * 40
		a.beam.CurveSize1 = a.c1 + math.cos(t * 0.2 + a.phase) * 40
	end
end

------------------------------------------------------------------------
-- Тень, кружащая вдали
------------------------------------------------------------------------
local wisp, wispRadius = nil, 300
local function animateWisp(t, dt)
	if not wisp then
		wisp = world:FindFirstChild("ShadowWisp")
		if not wisp then
			return
		end
	end
	local targetRadius = shadowActive and 110 or 300
	wispRadius = wispRadius + (targetRadius - wispRadius) * math.min(1, dt * 0.5)
	local angle = t * 0.05
	local height = 40 + math.sin(t * 0.3) * 12
	local position = Vector3.new(math.cos(angle) * wispRadius, height, math.sin(angle) * wispRadius)
	wisp:PivotTo(CFrame.lookAt(position, Vector3.new(0, 30, 0)))
end

------------------------------------------------------------------------
-- Духи: лёгкое покачивание
------------------------------------------------------------------------
local function animatePets(t)
	local root = getRoot()
	if not root then
		return
	end
	for i = 1, 3 do
		local slot = root:FindFirstChild("PetSlot" .. i)
		if slot then
			local base = slot:GetAttribute("BasePosition")
			if base then
				slot.Position = base + Vector3.new(0, math.sin(t * 3 + i * 1.7) * 0.4, 0)
			end
		end
	end
end

------------------------------------------------------------------------
-- Одноразовые эффекты
------------------------------------------------------------------------
local function burst(position, color, count, size)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Position = position
	part.Parent = workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, size or 0.5),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new(0, 1)
	emitter.Lifetime = NumberRange.new(0.5, 1.1)
	emitter.Speed = NumberRange.new(6, 14)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = 4
	emitter.Rate = 0
	emitter.Parent = part
	emitter:Emit(count or 20)
	task.delay(1.5, function()
		part:Destroy()
	end)
end
Effects.Burst = burst

local function floatingText(position, text, color)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Position = position
	part.Parent = workspace
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(120, 40)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	tween(part, 1, { Position = position + Vector3.new(0, 4, 0) })
	task.delay(0.5, function()
		tween(label, 0.5, { TextTransparency = 1, TextStrokeTransparency = 1 })
	end)
	task.delay(1.1, function()
		part:Destroy()
	end)
end
Effects.FloatingText = floatingText

function Effects.Pickup(position, amount)
	Sound.Play("Pickup")
	burst(position, Color3.fromRGB(255, 230, 140), 12, 0.35)
	-- маленький огонёк летит к игроку
	local root = getRoot()
	if root then
		local orb = Instance.new("Part")
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(0.5, 0.5, 0.5)
		orb.Material = Enum.Material.Neon
		orb.Color = Color3.fromRGB(255, 230, 140)
		orb.Anchored = true
		orb.CanCollide = false
		orb.CanQuery = false
		orb.CanTouch = false
		orb.Position = position
		orb.Parent = workspace
		local start = os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local alpha = math.min(1, (os.clock() - start) / 0.35)
			local r = getRoot()
			if not r or alpha >= 1 then
				conn:Disconnect()
				orb:Destroy()
				return
			end
			orb.Position = position:Lerp(r.Position, alpha * alpha)
		end)
	end
	floatingText(position + Vector3.new(0, 1.5, 0), "+" .. amount .. " ✦", Color3.fromRGB(255, 220, 110))
end

function Effects.Celebrate(color)
	local root = getRoot()
	if not root then
		return
	end
	local colors = { Color3.fromRGB(255, 211, 107), Color3.fromRGB(255, 122, 217), Color3.fromRGB(107, 228, 255), Color3.fromRGB(110, 240, 160) }
	for i, c in ipairs(colors) do
		task.delay(i * 0.08, function()
			burst(root.Position + Vector3.new(0, 2, 0), color or c, 25, 0.6)
		end)
	end
end

function Effects.Ring(position, color)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.2
	ring.Size = Vector3.new(0.2, 2, 2)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	tween(ring, 0.6, { Size = Vector3.new(0.2, 22, 22), Transparency = 1 })
	task.delay(0.7, function()
		ring:Destroy()
	end)
end

function Effects.ScreenFlash(color, strength)
	local cc = lighting.color
	if not cc then
		return
	end
	local base = lighting.colorBase
	cc.Brightness = base.Brightness + (strength or 0.3)
	cc.TintColor = color or Color3.new(1, 1, 1)
	tween(cc, 0.8, { Brightness = shadowActive and -0.05 or base.Brightness, TintColor = shadowActive and Color3.fromRGB(190, 160, 230) or base.TintColor })
end

------------------------------------------------------------------------
-- Атмосфера при нашествии Тени
------------------------------------------------------------------------
local function applyShadowMood(active)
	if active == shadowActive then
		return
	end
	shadowActive = active
	local cc, atmo = lighting.color, lighting.atmosphere
	if cc then
		if active then
			tween(cc, 3, { TintColor = Color3.fromRGB(190, 160, 230), Saturation = -0.15, Brightness = -0.05 })
		else
			tween(cc, 3, { TintColor = lighting.colorBase.TintColor, Saturation = lighting.colorBase.Saturation, Brightness = lighting.colorBase.Brightness })
		end
	end
	if atmo then
		if active then
			tween(atmo, 3, { Density = math.min(0.75, lighting.atmoBase.Density + 0.25), Color = Color3.fromRGB(60, 30, 90) })
		else
			tween(atmo, 3, { Density = lighting.atmoBase.Density, Color = lighting.atmoBase.Color })
		end
	end
	if active then
		Sound.Play("Shadow")
	end
end

function Effects.SetWorldState(ws)
	applyShadowMood(ws.shadow and ws.shadow.active == true)
end

------------------------------------------------------------------------
function Effects.Init()
	local cc = Lighting:FindFirstChild("LL_Color")
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if cc then
		lighting.color = cc
		lighting.colorBase = { TintColor = cc.TintColor, Saturation = cc.Saturation, Brightness = cc.Brightness }
	end
	if atmo then
		lighting.atmosphere = atmo
		lighting.atmoBase = { Density = atmo.Density, Color = atmo.Color }
	end

	setupLighthouse()
	setupAurora()

	RunService.RenderStepped:Connect(function(dt)
		local t = os.clock()
		animateShards(t)
		animateLighthouse(t)
		animateAurora(t)
		animateWisp(t, dt)
		animatePets(t)
	end)

	Sound.StartMusic()
end

return Effects
