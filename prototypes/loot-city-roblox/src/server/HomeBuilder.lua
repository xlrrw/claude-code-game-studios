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
