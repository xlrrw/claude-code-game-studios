-- PROTOTYPE - NOT FOR PRODUCTION
-- Drives the server script through a full play session against the mock API.
local SRC = ...
local mods = {}
local function loadModule(inst, path)
	local fn = assert(loadstring(SRC[path], path))
	setfenv(fn, setmetatable({ script = inst }, { __index = getfenv(1) }))
	return fn()
end
function require(inst)
	local path = inst._props.__path
	if not mods[path] then mods[path] = loadModule(inst, path) end
	return mods[path]
end
local RS = game:GetService("ReplicatedStorage")
local shared = Instance.new("Folder"); shared.Name = "LootCityShared"; shared.Parent = RS
local cfg = Instance.new("ModuleScript"); cfg.Name = "Config"; cfg.__path = "Config"; cfg.Parent = shared
local srv = Instance.new("Folder"); srv.Name = "LootCityServer"; srv.Parent = game:GetService("ServerScriptService")
for _, n in { "CityBuilder", "ItemFactory", "HomeBuilder" } do
	local m = Instance.new("ModuleScript"); m.Name = n; m.__path = n; m.Parent = srv
end
local serverScript = Instance.new("Script"); serverScript.Name = "Server"; serverScript.Parent = srv
loadModule(serverScript, "Server")
local Config = require(cfg)
local Action = shared.Action
local Heartbeat = game:GetService("RunService").Heartbeat

local plr = MockAddPlayer(101)
for _, f in DELAYED do task.spawn(f) end
local function lastState()
	for i = #PUSHED, 1, -1 do
		local p = PUSHED[i]
		if p.msg.type == "state" and p.plr == plr then return p.msg.state end
	end
end
local hrp = plr.Character.HumanoidRootPart
local npcF = workspace.LootCityNPC
local function goTo(id)
	for _, m in npcF:GetChildren() do
		if m:GetAttribute("NPC") == id then hrp.CFrame = m:GetPivot() + Vector3.new(0, 0, 0); return m end
	end
	error("npc not found " .. id)
end
local function call(name, args)
	local r = Action.OnServerInvoke(plr, name, args)
	return r
end
-- tick a little
for _ = 1, 10 do Heartbeat:Fire(0.1) end
local loot = workspace.LootCityLoot:GetChildren()
print("loot spawned", #loot)
assert(#loot >= 100, "too little loot")
-- pick up 6 items in district 1
local picked = 0
for _, m in loot do
	local prompt = m.PrimaryPart:FindFirstChildOfClass("ProximityPrompt")
	local p = m.PrimaryPart.Position
	if Config.districtOf(p.X, p.Z) == 1 and picked < 10 then
		prompt.Triggered:Fire(plr); picked += 1
	end
end
local s = lastState()
print("after pickup: used", s.used, "/", s.slots, "inv", #s.inv)
assert(#s.inv > 0, "nothing picked")
-- talk to pawn & sell all
goTo("pawn")
assert(call("sellall", { npc = "pawn" }), "sellall failed")
s = lastState(); print("money after sell", s.money)
-- give money and buy everything
-- (test hook: reach into the data via a sell of a fake item isn't possible; mutate through repeated quests instead)
local DataRef
for k, v in getfenv(0) do end
-- direct: walk the state table through upvalue-free path: the server exposes nothing, so emulate rich player by many sells
for i = 1, 300 do
	for _, m in workspace.LootCityLoot:GetChildren() do
		local p = m.PrimaryPart.Position
		if Config.districtOf(p.X, p.Z) == 1 then m.PrimaryPart:FindFirstChildOfClass("ProximityPrompt").Triggered:Fire(plr) end
	end
	-- like a player: put collection pieces into the collection first
	local st = lastState()
	for idx = #st.inv, 1, -1 do
		local def = Config.ITEM_BY_ID[st.inv[idx].id]
		if def.col and not table.find(st.col[def.col] or {}, def.id) then call("collect", { i = idx }); st = lastState() end
	end
	goTo("pawn"); call("sellall", { npc = "pawn" })
	for _ = 1, 40 do Heartbeat:Fire(0.1) end
	if i % 50 == 0 then
		local c, sp = 0, 0
		for _, m in workspace.LootCityLoot:GetChildren() do
			local pp = m.PrimaryPart.Position
			if Config.districtOf(pp.X, pp.Z) == 1 then c += 1 end
			if m:GetAttribute("Special") then sp += 1 end
		end
		print("iter", i, "d1 loot", c, "special", sp, "total", #workspace.LootCityLoot:GetChildren(), "used", lastState().used, "money", lastState().money)
	end
	if lastState().money > 25000 then break end
end
s = lastState(); print("money after grinding", s.money, "found", s.stats.found)
goTo("gear"); print("upg backpack", call("upg", { id = "backpack" }))
goTo("garage"); print("buy scooter", call("veh", { id = "scooter" })); print("ride off", call("ride", {})); print("ride on", call("ride", { id = "scooter" }))
goTo("broker"); print("biz vending", call("biz", { id = "vending" }))
goTo("foreman"); print("build tent", call("build", { stage = 2 })); print("decor fence", call("decor", { id = "fence" }))
goTo("mayor"); print("perm center", call("perm", { d = 2 }))
goTo("quest1"); print("quest get", call("quest", { npc = "quest1" })); print("quest skip", call("quest", { npc = "quest1", skip = true }))
s = lastState(); print("quest text", s.quests.quest1.text, s.quests.quest1.prog)
print("qdone (may be not ready)", call("qdone", { npc = "quest1" }))
print("taxi", call("taxi", {}))
-- drop & collect
s = lastState()
if #s.inv > 0 then print("drop", call("drop", { i = 1 })) end
-- far from npc must fail
hrp.CFrame = CFrame.new(-400, 3, 400)
assert(call("upg", { id = "shoes" }) == false, "remote purchase should fail")
assert(call("nonsense", {}) == false)
-- events: run lots of time
for _ = 1, 6000 do Heartbeat:Fire(0.1) end
local kinds = {}
for _, p in PUSHED do if p.msg.type == "banner" then kinds[p.msg.title] = true end end
local n = 0 for k in kinds do n += 1 end
print("distinct banners seen", n)
s = lastState()
print("final: money", s.money, "day", s.day, "ppm", s.ppm, "home", s.home, "vehicle", s.vehicle, "unlocked2", s.unlocked[2])
assert(s.home == 2 and s.vehicle == "scooter" and s.unlocked[2])
game:GetService("Players").PlayerRemoving:Fire(plr)
print("SERVER TEST OK")
