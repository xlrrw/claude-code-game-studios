-- PROTOTYPE - NOT FOR PRODUCTION
-- Minimal Roblox API mock so the city/home/item builders can run in the plain Luau CLI.
local V = {}
V.__index = function(t, k)
	if k == "X" then return rawget(t, "x") elseif k == "Y" then return rawget(t, "y") elseif k == "Z" then return rawget(t, "z")
	elseif k == "Magnitude" then return math.sqrt(t.x * t.x + t.y * t.y + t.z * t.z)
	elseif k == "Unit" then local m = math.sqrt(t.x * t.x + t.y * t.y + t.z * t.z); return Vector3.new(t.x / m, t.y / m, t.z / m) end
	return nil
end
local function v3(x, y, z) return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, V) end
V.__add = function(a, b) return v3(a.x + b.x, a.y + b.y, a.z + b.z) end
V.__sub = function(a, b) return v3(a.x - b.x, a.y - b.y, a.z - b.z) end
V.__mul = function(a, b)
	if type(a) == "number" then return v3(b.x * a, b.y * a, b.z * a) end
	if type(b) == "number" then return v3(a.x * b, a.y * b, a.z * b) end
	return v3(a.x * b.x, a.y * b.y, a.z * b.z)
end
V.__div = function(a, b) return v3(a.x / b, a.y / b, a.z / b) end
V.__unm = function(a) return v3(-a.x, -a.y, -a.z) end
Vector3 = { new = v3, zero = v3(0, 0, 0), one = v3(1, 1, 1) }
Vector2 = { new = function(x, y) return { X = x, Y = y } end }

local CF = {}
local function cf(r, p) return setmetatable({ r = r, p = p }, CF) end
local function mulR(a, b)
	local r = {}
	for i = 0, 2 do for j = 0, 2 do
		local s = 0
		for k = 0, 2 do s += a[i * 3 + k + 1] * b[k * 3 + j + 1] end
		r[i * 3 + j + 1] = s
	end end
	return r
end
local function rv(r, v) return v3(r[1] * v.x + r[2] * v.y + r[3] * v.z, r[4] * v.x + r[5] * v.y + r[6] * v.z, r[7] * v.x + r[8] * v.y + r[9] * v.z) end
CF.__index = function(t, k)
	if k == "Position" then return t.p elseif k == "LookVector" then return rv(t.r, v3(0, 0, -1))
	elseif k == "X" then return t.p.x elseif k == "Y" then return t.p.y elseif k == "Z" then return t.p.z end
	return nil
end
CF.__mul = function(a, b)
	if getmetatable(b) == CF then return cf(mulR(a.r, b.r), a.p + rv(a.r, b.p)) end
	return a.p + rv(a.r, b)
end
CF.__add = function(a, v) return cf(a.r, a.p + v) end
CF.__sub = function(a, v) return cf(a.r, a.p - v) end
local I = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
CFrame = {
	new = function(x, y, z)
		if type(x) == "table" then return cf(I, x) end
		return cf(I, v3(x or 0, y or 0, z or 0))
	end,
	Angles = function(rx, ry, rz)
		local cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
		local X = { 1, 0, 0, 0, cx, -sx, 0, sx, cx }
		local Y = { cy, 0, sy, 0, 1, 0, -sy, 0, cy }
		local Z = { cz, -sz, 0, sz, cz, 0, 0, 0, 1 }
		return cf(mulR(mulR(X, Y), Z), v3())
	end,
	lookAt = function(at, target)
		local f = (target - at)
		local m = f.Magnitude
		assert(m > 1e-6, "lookAt with zero direction")
		f = f / m
		local up = v3(0, 1, 0)
		local rx = v3(f.z * up.y - f.y * up.z, f.x * up.z - f.z * up.x, f.y * up.x - f.x * up.y) -- f x up
		local rm = rx.Magnitude
		if rm < 1e-6 then rx = v3(1, 0, 0) else rx = rx / rm end
		local u = v3(rx.y * f.z - rx.z * f.y, rx.z * f.x - rx.x * f.z, rx.x * f.y - rx.y * f.x) -- rx x f
		return cf({ rx.x, u.x, -f.x, rx.y, u.y, -f.y, rx.z, u.z, -f.z }, at)
	end,
}

local C = {}
C.__index = C
function C:ToHex() return string.format("%02x%02x%02x", self.R * 255, self.G * 255, self.B * 255) end
function C:Lerp(o, t) return Color3.new(self.R + (o.R - self.R) * t, self.G + (o.G - self.G) * t, self.B + (o.B - self.B) * t) end
Color3 = {
	new = function(r, g, b) return setmetatable({ R = r, G = g, B = b }, C) end,
	fromRGB = function(r, g, b) assert(r and g and b, "fromRGB nil"); return setmetatable({ R = r / 255, G = g / 255, B = b / 255 }, C) end,
	fromHSV = function(h, s, v) return setmetatable({ R = v, G = v, B = v }, C) end,
	fromHex = function() return setmetatable({ R = 1, G = 1, B = 1 }, C) end,
}
local function seq(...) return { ... } end
ColorSequence = { new = seq }
NumberSequence = { new = seq }
NumberSequenceKeypoint = { new = seq }
NumberRange = { new = seq }
UDim2 = { new = seq, fromScale = seq, fromOffset = seq }
UDim = { new = seq }

local enumMeta = {}
enumMeta.__index = function(t, k)
	local path = rawget(t, "_p") .. "." .. k
	if path == "Enum.Material.NotAMaterial" then error("no such enum") end
	local v = setmetatable({ _p = path }, enumMeta)
	rawset(t, k, v)
	return v
end
Enum = setmetatable({ _p = "Enum" }, enumMeta)

STATS = { parts = 0, instances = 0, lights = 0, byClass = {} }
local Inst = {}
local BASEPARTS = { Part = true, WedgePart = true, SpawnLocation = true }
Inst.__index = function(t, k)
	local m = rawget(Inst, k)
	if m then return m end
	local props = rawget(t, "_props")
	if props[k] ~= nil then return props[k] end
	for _, c in rawget(t, "_children") do
		if c._props.Name == k then return c end
	end
	return nil
end
Inst.__newindex = function(t, k, v)
	if k == "Parent" then
		local old = t._props.Parent
		if old then
			for i, c in old._children do if c == t then table.remove(old._children, i) break end end
		end
		if v then table.insert(v._children, t) end
		t._props.Parent = v
		return
	end
	if BASEPARTS[t._props.ClassName] and k == "Size" then
		assert(v.x > 0 and v.y > 0 and v.z > 0, "non-positive part size " .. v.x .. "," .. v.y .. "," .. v.z)
	end
	t._props[k] = v
end
function Inst.new(class, parent)
	local o = setmetatable({ _props = { ClassName = class, Name = class }, _children = {}, _tags = {}, _attr = {} }, Inst)
	STATS.instances += 1
	STATS.byClass[class] = (STATS.byClass[class] or 0) + 1
	if BASEPARTS[class] then STATS.parts += 1 end
	if class == "SpotLight" or class == "PointLight" then STATS.lights += 1 end
	if parent then o.Parent = parent end
	return o
end
function Inst:IsA(c) return self._props.ClassName == c or (c == "BasePart" and BASEPARTS[self._props.ClassName]) or c == "Instance" end
function Inst:AddTag(t) self._tags[t] = true end
function Inst:FindFirstChild(n) for _, c in self._children do if c._props.Name == n then return c end end return nil end
function Inst:WaitForChild(n) local c = self:FindFirstChild(n); assert(c, "WaitForChild missing " .. n); return c end
function Inst:FindFirstChildOfClass(n) for _, c in self._children do if c._props.ClassName == n then return c end end return nil end
function Inst:GetChildren() return table.clone(self._children) end
function Inst:GetDescendants()
	local out = {}
	local function rec(o) for _, c in o._children do table.insert(out, c); rec(c) end end
	rec(self)
	return out
end
function Inst:Destroy() self.Parent = nil end
function Inst:ClearAllChildren() for _, c in table.clone(self._children) do c.Parent = nil end end
function Inst:SetAttribute(k, v) self._attr[k] = v end
function Inst:GetAttribute(k) return self._attr[k] end
function Inst:PivotTo(c) self._props.Pivot = c end
function Inst:GetPivot() return self._props.Pivot or CFrame.new() end
Instance = { new = Inst.new }

local Terrain = Inst.new("Terrain")
function Terrain:Clear() end
function Terrain:FillBlock() end
function Terrain:FillBall() end
rawset(Terrain, "Clear", Terrain.Clear)
workspace = Inst.new("Workspace")
Terrain.Name = "Terrain"
Terrain.Parent = workspace
local services = {}
game = { GetService = function(_, n)
	if n == "Workspace" then return workspace end
	services[n] = services[n] or Inst.new(n)
	return services[n]
end }
Random = { new = function(seed)
	local s = seed or 1
	local function nxt() s = (s * 1103515245 + 12345) % 2147483648; return s / 2147483648 end
	return {
		NextNumber = function(_, a, b) local r = nxt(); if a then return a + r * (b - a) end return r end,
		NextInteger = function(_, a, b) return a + math.floor(nxt() * (b - a + 1)) end,
	}
end }
typeof = function(x) return type(x) end
warn = print

-- ===== extra mocks for the server script =====
local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({ fns = {} }, Signal) end
function Signal:Connect(fn) table.insert(self.fns, fn); return { Disconnect = function() end } end
function Signal:Fire(...) for _, f in self.fns do f(...) end end
MockSignal = Signal
local oldIndex = Inst.__index
Inst.__index = function(t, k)
	if k == "Position" then
		local c = rawget(t, "_props").CFrame
		if c then return c.Position end
	end
	if k == "Triggered" or k == "PlayerAdded" or k == "PlayerRemoving" or k == "Heartbeat" or k == "CharacterAdded" or k == "OnClientEvent" or k == "Ended" then
		local props = rawget(t, "_props")
		props[k] = props[k] or Signal.new()
		return props[k]
	end
	return oldIndex(t, k)
end
PUSHED = {}
function Inst:FireClient(plr, msg) table.insert(PUSHED, { plr = plr, msg = msg }) end
function Inst:FireAllClients(msg) table.insert(PUSHED, { all = true, msg = msg }) end
local playersList = {}
local Players = game:GetService("Players")
rawget(Players, "_props").GetPlayers = function() return table.clone(playersList) end
rawget(Players, "_props").CreateHumanoidModelFromDescription = function() error("not in mock") end
MockAddPlayer = function(id)
	local plr = Inst.new("Player")
	plr.UserId = id; plr.DisplayName = "Tester" .. id; plr.Name = "Tester" .. id
	local ch = Inst.new("Model")
	local hrp = Inst.new("Part"); hrp.Name = "HumanoidRootPart"; hrp.CFrame = CFrame.new(0, 3, 0); hrp.Size = Vector3.new(2, 2, 1); hrp.Parent = ch
	Inst.new("Humanoid").Parent = ch
	plr.Character = ch
	local pg = Inst.new("PlayerGui"); pg.Name = "PlayerGui"; pg.Parent = plr
	table.insert(playersList, plr)
	Players.PlayerAdded:Fire(plr)
	return plr
end
local stores = {}
rawget(game:GetService("DataStoreService"), "_props").GetDataStore = function()
	return {
		GetAsync = function(_, k) return stores[k] end,
		SetAsync = function(_, k, v) stores[k] = v end,
	}
end
game.BindToClose = function() end
game.CreatorType = Enum.CreatorType.User
game.CreatorId = 101 -- the test owner
rawget(game:GetService("RunService"), "_props").IsStudio = function() return false end
function Inst:Clone()
	local c = Inst.new(self._props.ClassName)
	for k, v in self._props do if k ~= "Parent" then c._props[k] = v end end
	return c
end
function Inst:Kick(reason) self._props.Kicked = reason or true end
function Inst:GetRankInGroupAsync() return 0 end
DELAYED = {}
task = {
	spawn = function(fn, ...) local co = coroutine.create(fn); coroutine.resume(co, ...) end,
	delay = function(_, fn, ...) table.insert(DELAYED, fn) end,
	wait = function() coroutine.yield() end,
}
MockRemovePlayer = function(plr)
	local list = game:GetService("Players"):GetPlayers()
	local Pl = game:GetService("Players")
	local raw = rawget(Pl, "_props").GetPlayers
	rawget(Pl, "_props").GetPlayers = function()
		local out = {}
		for _, p in raw() do if p ~= plr then table.insert(out, p) end end
		return out
	end
	Pl.PlayerRemoving:Fire(plr)
	local _ = list
end
