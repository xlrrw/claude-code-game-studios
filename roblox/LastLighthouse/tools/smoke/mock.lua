-- Minimal Roblox API mock for smoke-running the installer and game scripts.
unpack = unpack or table.unpack
function math.clamp(x, a, b) if x < a then return a elseif x > b then return b end return x end
math.sign = function(x) return x > 0 and 1 or (x < 0 and -1 or 0) end

local LOG = {}
function warn(...) local t = {} for i = 1, select("#", ...) do t[#t+1] = tostring(select(i, ...)) end print("WARN: " .. table.concat(t, " ")) LOG[#LOG+1] = table.concat(t, " ") end
WARNINGS = LOG

------------------------------------------------------------------ scheduler
local now = 0
local queue = {}   -- {time, co, args}
local deferred = {}
local function resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then error("coroutine error: " .. tostring(err) .. "\n" .. debug.traceback(co), 0) end
end
local function schedule(t, co, ...) queue[#queue+1] = { time = now + (t or 0), co = co, args = { ... } } end
task = {}
function task.spawn(fn, ...) local co = type(fn) == "thread" and fn or coroutine.create(fn) resume(co, ...) return co end
function task.defer(fn, ...) local co = coroutine.create(fn) deferred[#deferred+1] = { co = co, args = { ... } } return co end
function task.delay(t, fn, ...) local co = coroutine.create(fn) schedule(t, co, ...) return co end
function task.wait(t)
	local co = coroutine.running()
	if not co or not coroutine.isyieldable() then error("task.wait outside coroutine") end
	schedule(math.max(t or 0.03, 0.001), co)
	return coroutine.yield()
end
function task.cancel() end
os.clock = function() return now end
local realtime = os.time
os.time = function() return 1700000000 + math.floor(now) end
local heartbeats = {}
function RUN(seconds, dt)
	dt = dt or 1 / 30
	local target = now + seconds
	while now < target do
		while #deferred > 0 do local d = table.remove(deferred, 1) resume(d.co, unpack(d.args)) end
		now = now + dt
		for _, sig in ipairs(heartbeats) do sig:Fire(dt) end
		local due = {}
		local rest = {}
		for _, q in ipairs(queue) do if q.time <= now then due[#due+1] = q else rest[#rest+1] = q end end
		queue = rest
		table.sort(due, function(a, b) return a.time < b.time end)
		for _, q in ipairs(due) do if coroutine.status(q.co) == "suspended" then resume(q.co, unpack(q.args)) end end
		while #deferred > 0 do local d = table.remove(deferred, 1) resume(d.co, unpack(d.args)) end
	end
end

------------------------------------------------------------------ signals
local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({ fns = {} }, Signal) end
function Signal:Connect(fn) local c = { fn = fn, connected = true } self.fns[#self.fns+1] = c return { Disconnect = function() c.connected = false end, Connected = true } end
function Signal:Once(fn) local c c = self:Connect(function(...) c.Disconnect() fn(...) end) return c end
function Signal:Fire(...) for _, c in ipairs(self.fns) do if c.connected then task.spawn(c.fn, ...) end end end
function Signal:Wait()
	local co = coroutine.running()
	local conn conn = self:Connect(function(...) conn.Disconnect() resume(co, ...) end)
	return coroutine.yield()
end

------------------------------------------------------------------ datatypes
local V3 = {}
V3.__index = function(v, k)
	if k == "Magnitude" then return math.sqrt(v.X*v.X + v.Y*v.Y + v.Z*v.Z) end
	if k == "Unit" then local m = math.sqrt(v.X*v.X + v.Y*v.Y + v.Z*v.Z) return Vector3.new(v.X/m, v.Y/m, v.Z/m) end
	if k == "Lerp" then return function(a, b, t) return a + (b - a) * t end end
	if k == "Dot" then return function(a, b) return a.X*b.X + a.Y*b.Y + a.Z*b.Z end end
	error("Vector3 has no member " .. tostring(k), 2)
end
local function isV3(x) return getmetatable(x) == V3 end
V3.__add = function(a, b) assert(isV3(a) and isV3(b), "Vector3 + non-Vector3") return Vector3.new(a.X+b.X, a.Y+b.Y, a.Z+b.Z) end
V3.__sub = function(a, b) assert(isV3(a) and isV3(b), "Vector3 - non-Vector3") return Vector3.new(a.X-b.X, a.Y-b.Y, a.Z-b.Z) end
V3.__mul = function(a, b)
	if type(a) == "number" then a, b = b, a end
	if type(b) == "number" then return Vector3.new(a.X*b, a.Y*b, a.Z*b) end
	assert(isV3(b), "Vector3 * bad") return Vector3.new(a.X*b.X, a.Y*b.Y, a.Z*b.Z)
end
V3.__div = function(a, b) assert(type(b) == "number") return Vector3.new(a.X/b, a.Y/b, a.Z/b) end
V3.__unm = function(a) return Vector3.new(-a.X, -a.Y, -a.Z) end
V3.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
V3.__tostring = function(v) return string.format("(%.1f, %.1f, %.1f)", v.X, v.Y, v.Z) end
Vector3 = {}
function Vector3.new(x, y, z)
	x, y, z = x or 0, y or 0, z or 0
	assert(type(x) == "number" and type(y) == "number" and type(z) == "number", "Vector3.new expects numbers")
	return setmetatable({ X = x, Y = y, Z = z }, V3)
end
Vector3.zero = Vector3.new()
Vector3.one = Vector3.new(1, 1, 1)

-- CFrame: position p, rotation columns r (3x3 row-major m)
local CF = {}
local function mat_mul(a, b)
	local m = {}
	for i = 0, 2 do for j = 0, 2 do
		local s = 0 for k = 0, 2 do s = s + a[i*3+k+1] * b[k*3+j+1] end m[i*3+j+1] = s
	end end
	return m
end
local function mat_vec(m, v) return Vector3.new(m[1]*v.X+m[2]*v.Y+m[3]*v.Z, m[4]*v.X+m[5]*v.Y+m[6]*v.Z, m[7]*v.X+m[8]*v.Y+m[9]*v.Z) end
local function transpose(m) return { m[1], m[4], m[7], m[2], m[5], m[8], m[3], m[6], m[9] } end
local function mkcf(p, m) return setmetatable({ p = p, m = m }, CF) end
local function isCF(x) return getmetatable(x) == CF end
CF.__index = function(c, k)
	if k == "Position" or k == "p" then return rawget(c, "p") end
	if k == "LookVector" then local m = c.m return Vector3.new(-m[3], -m[6], -m[9]) end
	if k == "RightVector" then local m = c.m return Vector3.new(m[1], m[4], m[7]) end
	if k == "UpVector" then local m = c.m return Vector3.new(m[2], m[5], m[8]) end
	if k == "X" then return c.p.X end
	if k == "Y" then return c.p.Y end
	if k == "Z" then return c.p.Z end
	if k == "Inverse" then return function(s) local t = transpose(s.m) return mkcf(-mat_vec(t, s.p), t) end end
	if k == "ToObjectSpace" then return function(s, o) return s:Inverse() * o end end
	if k == "ToWorldSpace" then return function(s, o) return s * o end end
	if k == "PointToWorldSpace" then return function(s, v) return s * v end end
	if k == "Lerp" then return function(a, b, t) return mkcf(a.p + (b.p - a.p) * t, b.m) end end
	error("CFrame has no member " .. tostring(k), 2)
end
CF.__mul = function(a, b)
	assert(isCF(a), "CFrame * : left not CFrame")
	if isCF(b) then return mkcf(a.p + mat_vec(a.m, b.p), mat_mul(a.m, b.m)) end
	if isV3(b) then return a.p + mat_vec(a.m, b) end
	error("CFrame * bad operand " .. type(b))
end
CF.__add = function(a, b) assert(isCF(a) and isV3(b), "CFrame + needs Vector3") return mkcf(a.p + b, a.m) end
CF.__sub = function(a, b) assert(isCF(a) and isV3(b), "CFrame - needs Vector3") return mkcf(a.p - b, a.m) end
local I = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
CFrame = {}
function CFrame.new(x, y, z)
	if x == nil then return mkcf(Vector3.new(), I) end
	if isV3(x) then return mkcf(x, I) end
	return mkcf(Vector3.new(x, y, z), I)
end
function CFrame.Angles(rx, ry, rz)
	assert(type(rx) == "number" and type(ry) == "number" and type(rz) == "number", "CFrame.Angles expects numbers")
	local cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
	local X = { 1, 0, 0, 0, cx, -sx, 0, sx, cx }
	local Y = { cy, 0, sy, 0, 1, 0, -sy, 0, cy }
	local Z = { cz, -sz, 0, sz, cz, 0, 0, 0, 1 }
	return mkcf(Vector3.new(), mat_mul(mat_mul(X, Y), Z))
end
CFrame.fromEulerAnglesXYZ = CFrame.Angles
function CFrame.lookAt(pos, target)
	assert(isV3(pos) and isV3(target), "lookAt expects Vector3")
	local f = (target - pos)
	assert(f.Magnitude > 0, "lookAt zero direction (NaN in Roblox)")
	f = f.Unit
	local up = Vector3.new(0, 1, 0)
	local r = Vector3.new(f.Z * up.Y - f.Y * up.Z, f.X * up.Z - f.Z * up.X, f.Y * up.X - f.X * up.Y)
	if r.Magnitude < 1e-6 then r = Vector3.new(1, 0, 0) end
	r = r.Unit
	local u = Vector3.new(r.Y * f.Z - r.Z * f.Y, r.Z * f.X - r.X * f.Z, r.X * f.Y - r.Y * f.X)
	return mkcf(pos, { r.X, u.X, -f.X, r.Y, u.Y, -f.Y, r.Z, u.Z, -f.Z })
end

local function simpleType(name, fields)
	local mt = { __index = function(t, k) error(name .. " has no member " .. tostring(k), 2) end, __tostring = function() return name end }
	return function(...)
		local args = { ... }
		local t = { __type = name }
		for i, f in ipairs(fields) do t[f] = args[i] end
		return setmetatable(t, mt)
	end
end

local C3 = { __index = function(c, k)
	if k == "Lerp" then return function(a, b, t) return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t) end end
	error("Color3 has no member " .. tostring(k), 2)
end }
Color3 = {}
function Color3.new(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3) end
function Color3.fromRGB(r, g, b)
	assert(type(r) == "number" and type(g) == "number" and type(b) == "number", "fromRGB numbers")
	return Color3.new(r / 255, g / 255, b / 255)
end
local function isC3(x) return getmetatable(x) == C3 end

UDim = { new = simpleType("UDim", { "Scale", "Offset" }) }
UDim2 = {}
function UDim2.new(a, b, c, d) return { __type = "UDim2", X = UDim.new(a or 0, b or 0), Y = UDim.new(c or 0, d or 0) } end
function UDim2.fromOffset(x, y) assert(type(x) == "number" and type(y) == "number") return UDim2.new(0, x, 0, y) end
function UDim2.fromScale(x, y) assert(type(x) == "number" and type(y) == "number") return UDim2.new(x, 0, y, 0) end
Vector2 = { new = function(x, y) return { __type = "Vector2", X = x or 0, Y = y or 0 } end }
Vector2.zero = Vector2.new()
ColorSequenceKeypoint = { new = function(t, c) assert(type(t) == "number" and isC3(c), "CSK args") return { t = t, c = c } end }
ColorSequence = { new = function(a, b)
	if type(a) == "table" and not isC3(a) then return { __type = "ColorSequence", kps = a } end
	assert(isC3(a), "ColorSequence.new needs Color3") if b then assert(isC3(b)) end
	return { __type = "ColorSequence" }
end }
NumberSequenceKeypoint = { new = function(t, v) assert(type(t) == "number" and type(v) == "number", "NSK args") return { t = t, v = v } end }
NumberSequence = { new = function(a, b)
	if type(a) == "table" then
		assert(a[1].t == 0 and a[#a].t == 1, "NumberSequence must start at 0 and end at 1")
		return { __type = "NumberSequence" }
	end
	assert(type(a) == "number") return { __type = "NumberSequence" }
end }
NumberRange = { new = function(a, b) assert(type(a) == "number") return { __type = "NumberRange", Min = a, Max = b or a } end }
TweenInfo = { new = function(...) return { __type = "TweenInfo", args = { ... } } end }
RaycastParams = { new = function() return { __type = "RaycastParams" } end }
Random = { new = function(seed)
	local state = seed or 1
	local function nextf() state = (state * 1103515245 + 12345) % 2147483648 return state / 2147483648 end
	return {
		NextNumber = function(_, a, b) if a == nil then return nextf() end return a + (b - a) * nextf() end,
		NextInteger = function(_, a, b) assert(a <= b, "NextInteger range") return a + math.floor(nextf() * (b - a + 1)) end,
	}
end }
math.random = (function() local r = Random.new(3) return function(a, b) if a == nil then return r:NextNumber() end if b == nil then return r:NextInteger(1, a) end return r:NextInteger(a, b) end end)()

Enum = setmetatable({}, { __index = function(_, enumType)
	return setmetatable({}, { __index = function(_, item) return "Enum." .. enumType .. "." .. item end })
end })

------------------------------------------------------------------ instances
local EVENTS = {
	Touched = true, Triggered = true, OnServerEvent = true, OnClientEvent = true, PlayerAdded = true, PlayerRemoving = true,
	CharacterAdded = true, Heartbeat = true, RenderStepped = true, Changed = true, Event = true, Completed = true,
	Activated = true, MouseEnter = true, MouseLeave = true, MouseButton1Down = true, MouseButton1Up = true,
	InputBegan = true, JumpRequest = true, StateChanged = true, PromptGamePassPurchaseFinished = true, Died = true,
}
local Inst = {}
local ALL = {}
local function newInstance(className, name)
	local obj = { __class = className, __props = { Name = name or className }, __children = {}, __attrs = {}, __signals = {}, __propsig = {} }
	ALL[#ALL+1] = obj
	return setmetatable(obj, Inst)
end
local methods = {}
Inst.__index = function(obj, key)
	if key == "ClassName" then return obj.__class end
	local p = obj.__props[key]
	if p ~= nil then return p end
	if key == "Parent" then return nil end
	if EVENTS[key] then
		local s = obj.__signals[key]
		if not s then s = Signal.new() obj.__signals[key] = s if key == "Heartbeat" or key == "RenderStepped" then heartbeats[#heartbeats+1] = s end end
		return s
	end
	if methods[key] then return methods[key] end
	local ex = obj.__props.__extra
	if ex and ex[key] then return ex[key] end
	for _, c in ipairs(obj.__children) do if c.__props.Name == key then return c end end
	-- unknown property: Roblox has defaults; return nil for reads of unset properties
	if key:match("^[A-Z]") and not key:match("^[A-Z][a-z]*[A-Z]") then return nil end
	return nil
end
Inst.__newindex = function(obj, key, value)
	if key == "Parent" then
		local old = obj.__props.Parent
		if old then for i, c in ipairs(old.__children) do if c == obj then table.remove(old.__children, i) break end end end
		obj.__props.Parent = value
		if value then
			assert(getmetatable(value) == Inst, "Parent must be Instance")
			table.insert(value.__children, obj)
			local s = value.__signals.ChildAdded if s then s:Fire(obj) end
		end
		return
	end
	if key == "CFrame" then assert(getmetatable(value) == CF, "CFrame property needs CFrame (" .. obj.__class .. "." .. obj.__props.Name .. ")") obj.__props.Position = value.p end
	if key == "Position" and (obj.__class == "Part" or obj.__class == "WedgePart" or obj.__class == "SpawnLocation") then
		assert(isV3(value), "Position needs Vector3") local cf = obj.__props.CFrame obj.__props.CFrame = cf and mkcf(value, cf.m) or CFrame.new(value)
	end
	if key == "Size" and (obj.__class == "Part" or obj.__class == "WedgePart" or obj.__class == "SpawnLocation") then assert(isV3(value), "Size needs Vector3") end
	if (key == "Color" and (obj.__class == "Part" or obj.__class == "WedgePart" or obj.__class == "PointLight")) or key == "TextColor3" or key == "BackgroundColor3" then assert(isC3(value), key .. " needs Color3 on " .. obj.__class) end
	if key == "Color" and (obj.__class == "Beam" or obj.__class == "UIGradient" or obj.__class == "ParticleEmitter") then assert(type(value) == "table" and value.__type == "ColorSequence", "Color needs ColorSequence on " .. obj.__class) end
	if key == "Text" then assert(type(value) == "string", "Text must be string") end
	obj.__props[key] = value
	local ps = obj.__propsig[key] if ps then ps:Fire() end
	local cs = obj.__signals.Changed if cs and obj.__class:match("Value$") then cs:Fire(value) end
end
Inst.__tostring = function(o) return o.__props.Name end

function methods.FindFirstChild(obj, name, recursive)
	for _, c in ipairs(obj.__children) do if c.__props.Name == name then return c end end
	if recursive then for _, c in ipairs(obj.__children) do local r = methods.FindFirstChild(c, name, true) if r then return r end end end
	return nil
end
function methods.WaitForChild(obj, name, timeout)
	local c = methods.FindFirstChild(obj, name)
	if c then return c end
	local deadline = now + (timeout or 5)
	while now < deadline do
		if coroutine.isyieldable() then task.wait(0.05) else break end
		c = methods.FindFirstChild(obj, name)
		if c then return c end
	end
	if timeout then return nil end
	error("Infinite yield: WaitForChild('" .. name .. "') on " .. obj.__props.Name)
end
local ISA = {
	BasePart = { Part = 1, WedgePart = 1, SpawnLocation = 1, MeshPart = 1 },
	LuaSourceContainer = { Script = 1, LocalScript = 1, ModuleScript = 1 },
	GuiObject = { Frame = 1, TextLabel = 1, TextButton = 1, ScrollingFrame = 1, ImageLabel = 1 },
	PostEffect = { BloomEffect = 1, ColorCorrectionEffect = 1, SunRaysEffect = 1 },
	Model = { Model = 1 },
}
function methods.IsA(obj, cls) if obj.__class == cls then return true end local g = ISA[cls] return g ~= nil and g[obj.__class] ~= nil end
function methods.FindFirstChildOfClass(obj, cls) for _, c in ipairs(obj.__children) do if c.__class == cls then return c end end return nil end
function methods.FindFirstChildWhichIsA(obj, cls) for _, c in ipairs(obj.__children) do if methods.IsA(c, cls) then return c end end return nil end
function methods.FindFirstAncestorOfClass(obj, cls) local p = obj.__props.Parent while p do if p.__class == cls then return p end p = p.__props.Parent end return nil end
function methods.IsDescendantOf(obj, anc) local p = obj.__props.Parent while p do if p == anc then return true end p = p.__props.Parent end return false end
function methods.GetChildren(obj) local t = {} for i, c in ipairs(obj.__children) do t[i] = c end return t end
function methods.GetDescendants(obj) local t = {} local function rec(o) for _, c in ipairs(o.__children) do t[#t+1] = c rec(c) end end rec(obj) return t end
function methods.Destroy(obj) obj.Parent = nil obj.__destroyed = true end
function methods.ClearAllChildren(obj) for _, c in ipairs(methods.GetChildren(obj)) do methods.Destroy(c) end end
function methods.Clone(obj)
	local c = newInstance(obj.__class)
	for k, v in pairs(obj.__props) do if k ~= "Parent" then c.__props[k] = v end end
	for _, ch in ipairs(obj.__children) do local cc = methods.Clone(ch) cc.Parent = c end
	return c
end
function methods.SetAttribute(obj, k, v) assert(type(k) == "string") local t = type(v) assert(v == nil or t == "number" or t == "string" or t == "boolean" or isV3(v) or isC3(v), "bad attribute type " .. t) obj.__attrs[k] = v local s = obj.__propsig["@" .. k] if s then s:Fire() end end
function methods.GetAttribute(obj, k) return obj.__attrs[k] end
function methods.GetPropertyChangedSignal(obj, k) local s = obj.__propsig[k] if not s then s = Signal.new() obj.__propsig[k] = s end return s end
function methods.GetAttributeChangedSignal(obj, k) return methods.GetPropertyChangedSignal(obj, "@" .. k) end
function methods.GetPivot(obj)
	if obj.__class == "Model" then local pp = obj.__props.PrimaryPart if pp then return pp.CFrame end return CFrame.new() end
	return obj.__props.CFrame or CFrame.new()
end
function methods.PivotTo(obj, cf)
	assert(isCF(cf), "PivotTo needs CFrame")
	local old = methods.GetPivot(obj)
	local delta = cf * old:Inverse()
	local function move(o) if o.__props.CFrame then o.CFrame = delta * o.__props.CFrame end for _, c in ipairs(o.__children) do move(c) end end
	if obj.__class == "Model" then move(obj) else obj.CFrame = cf end
end
function methods.SetNetworkOwner(obj, p) assert(not obj.__props.Anchored, "SetNetworkOwner on anchored part") end
function methods.Emit() end
function methods.Play(obj) if obj.__class == "Tween" then local tw = obj task.delay(0.01, function() for k, v in pairs(tw.__goal) do tw.__target[k] = v end tw.Completed:Fire() end) end end
function methods.Cancel() end
function methods.Fire(obj, ...) if obj.__class == "BindableEvent" then obj.Event:Fire(...) end end
function methods.FireClient(obj, player, ...) assert(player and player.__class == "Player", "FireClient needs player") CLIENT_EVENTS[#CLIENT_EVENTS+1] = { remote = obj.__props.Name, player = player, args = { ... } } if player == LOCAL_PLAYER then obj.OnClientEvent:Fire(...) end end
function methods.FireAllClients(obj, ...) CLIENT_EVENTS[#CLIENT_EVENTS+1] = { remote = obj.__props.Name, all = true, args = { ... } } obj.OnClientEvent:Fire(...) end
function methods.FireServer(obj, ...) obj.OnServerEvent:Fire(LOCAL_PLAYER, ...) end
function methods.GetPlayers(obj) return methods.GetChildren(obj) end
function methods.GetPlayerFromCharacter(obj, ch) for _, p in ipairs(obj.__children) do if p.__props.Character == ch then return p end end return nil end
function methods.GetPlayerByUserId(obj, id) for _, p in ipairs(obj.__children) do if p.__props.UserId == id then return p end end return nil end
function methods.GetState() return "Enum.HumanoidStateType.Running" end
function methods.ChangeState() end
function methods.Disconnect() end
CLIENT_EVENTS = {}

Instance = { new = function(className, parent)
	assert(type(className) == "string", "Instance.new class")
	local o = newInstance(className)
	if className == "Attachment" then o.__props.Position = Vector3.new() end
	if className == "Beam" then o.__props.Width1 = 1 o.__props.CurveSize0 = 0 o.__props.CurveSize1 = 0 end
	if className == "Part" or className == "WedgePart" or className == "SpawnLocation" then o.__props.CFrame = CFrame.new() o.__props.Position = Vector3.new() o.__props.Size = Vector3.new(4, 1, 2) o.__props.Transparency = 0 o.__props.Color = Color3.new(0.6, 0.6, 0.6) o.__props.Anchored = false end
	if className == "UIScale" then o.__props.Scale = 1 end
	if className == "ScrollingFrame" then o.__props.CanvasPosition = Vector2.new() end
	if className == "NumberValue" then o.__props.Value = 0 end
	if className == "StringValue" then o.__props.Value = "" end
	if parent then o.Parent = parent end
	return o
end }

------------------------------------------------------------------ services
game = newInstance("DataModel", "Game")
local services = {}
local function service(name, class)
	local s = newInstance(class or name, name)
	s.Parent = game
	services[name] = s
	return s
end
workspace = service("Workspace")
workspace.__extra = {
	GetServerTimeNow = function() return 1700000000 + now end,
	Raycast = function() return nil end,
}
local terrain = newInstance("Terrain", "Terrain")
terrain.__extra = {}
for _, m in ipairs({ "FillBlock", "FillCylinder", "FillBall", "Clear", "SetMaterialColor" }) do terrain.__extra[m] = function(self, a, b, c, d)
	if m == "FillBlock" then assert(isCF(a) and isV3(b) and type(c) == "string", "FillBlock(CFrame, Vector3, Material)") end
	if m == "FillCylinder" then assert(isCF(a) and type(b) == "number" and type(c) == "number" and type(d) == "string", "FillCylinder(CFrame, h, r, Material)") assert(c > 0 and b > 0, "FillCylinder size") end
	if m == "FillBall" then assert(isV3(a) and type(b) == "number" and type(c) == "string", "FillBall(Vector3, r, Material)") assert(b > 0, "FillBall radius > 0") end
end end
terrain.Parent = workspace
local camera = newInstance("Camera", "Camera")
camera.__props.ViewportSize = Vector2.new(1280, 720)
camera.__props.CFrame = CFrame.new()
camera.Parent = workspace
workspace.__props.CurrentCamera = camera
service("Lighting")
service("ReplicatedStorage")
service("ServerScriptService")
service("ServerStorage")
local sp = service("StarterPlayer")
local sps = newInstance("StarterPlayerScripts", "StarterPlayerScripts") sps.Parent = sp
service("ChangeHistoryService").__props.TryBeginRecording = function() return "rec1" end
services.ChangeHistoryService.__props.FinishRecording = function() end
local Players = service("Players")
local rs = service("RunService")
rs.__props.IsStudio = function() return true end
rs.__props.IsServer = function() return true end
service("TweenService").__props.Create = function(_, target, info, goal)
	assert(getmetatable(target) == Inst, "Tween target must be Instance")
	for k, v in pairs(goal) do local _ = target[k] end
	local tw = newInstance("Tween") tw.__goal = goal tw.__target = target return tw
end
service("SoundService").__props.PlayLocalSound = function() end
service("UserInputService")
local mps = service("MarketplaceService")
mps.__props.UserOwnsGamePassAsync = function() return false end
mps.__props.PromptGamePassPurchase = function() PROMPTS = (PROMPTS or 0) + 1 end
mps.__props.PromptProductPurchase = function() PROMPTS = (PROMPTS or 0) + 1 end
local dss = service("DataStoreService")
DATASTORE = {}
dss.__props.GetDataStore = function(_, name)
	return {
		GetAsync = function(_, key) task.wait(0.1) return DATASTORE[key] end,
		UpdateAsync = function(_, key, fn) task.wait(0.1) DATASTORE[key] = fn(DATASTORE[key]) end,
	}
end
game.__props.GetService = function(_, name) local s = services[name] if not s then error("unknown service " .. name) end return s end
game.__props.BindToClose = function() end

------------------------------------------------------------------ script loading
local moduleCache = {}
local function runSource(scr)
	local env = setmetatable({ script = scr }, { __index = _G })
	local fn, err = load(scr.__props.Source, "=" .. scr.__props.Name, "t", env)
	if not fn then error("compile " .. scr.__props.Name .. ": " .. err) end
	return fn
end
function require(mod)
	assert(getmetatable(mod) == Inst and mod.__class == "ModuleScript", "require needs ModuleScript")
	if moduleCache[mod] == nil then
		local fn = runSource(mod)
		local r = fn()
		assert(r ~= nil, "module returned nil: " .. mod.__props.Name)
		moduleCache[mod] = r
	end
	return moduleCache[mod]
end
function RUN_SCRIPT(scr) task.spawn(runSource(scr)) end
function RESET_MODULES() moduleCache = {} end

function NEW_PLAYER(name, id)
	local p = newInstance("Player", name)
	p.__props.UserId = id
	p.__props.DisplayName = name
	p.__props.MembershipType = "Enum.MembershipType.None"
	local gui = newInstance("PlayerGui", "PlayerGui") gui.Parent = p
	return p
end
function SPAWN_CHARACTER(p, pos)
	local ch = newInstance("Model", p.__props.Name)
	local hrp = Instance.new("Part") hrp.Name = "HumanoidRootPart" hrp.CFrame = CFrame.new(pos) hrp.Parent = ch
	local head = Instance.new("Part") head.Name = "Head" head.CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0)) head.Parent = ch
	local hum = Instance.new("Humanoid") hum.Health = 100 hum.WalkSpeed = 16 hum.Parent = ch
	ch.__props.PrimaryPart = hrp
	ch.Parent = workspace
	p.Character = ch
	p.CharacterAdded:Fire(ch)
	return ch
end
SERVICES = services
ALL_INSTANCES = ALL
