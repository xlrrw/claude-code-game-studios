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
