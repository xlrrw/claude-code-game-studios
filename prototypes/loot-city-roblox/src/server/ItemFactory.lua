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
