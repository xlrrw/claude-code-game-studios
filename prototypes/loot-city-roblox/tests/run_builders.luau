-- PROTOTYPE - NOT FOR PRODUCTION
-- Runs Plan/Build, every home stage + decor and every loot item model against the mock API.
local function readFile(p)
	local f = assert(io and io.open and io.open(p, "r"), "io unavailable")
	local s = f:read("*a"); f:close(); return s
end
local SRC = ...
local mods = {}
local function loadModule(inst, path)
	local fn = assert(loadstring(SRC[path], path))
	local env = setmetatable({ script = inst }, { __index = getfenv(1) })
	setfenv(fn, env)
	return fn()
end
local origRequire = require
function require(inst)
	if type(inst) == "string" then return origRequire(inst) end
	local path = inst._props.__path
	if not mods[path] then mods[path] = loadModule(inst, path) end
	return mods[path]
end
local _ = readFile
local RS = game:GetService("ReplicatedStorage")
local shared = Instance.new("Folder"); shared.Name = "LootCityShared"; shared.Parent = RS
local cfg = Instance.new("ModuleScript"); cfg.Name = "Config"; cfg.__path = "Config"; cfg.Parent = shared
local SSS = game:GetService("ServerScriptService")
local srv = Instance.new("Folder"); srv.Name = "LootCityServer"; srv.Parent = SSS
for _, n in { "CityBuilder", "ItemFactory", "HomeBuilder" } do
	local m = Instance.new("ModuleScript"); m.Name = n; m.__path = n; m.Parent = srv
end
local Config = require(cfg)
local CB = require(srv.CityBuilder)
local plan = CB.Plan()
local function count(t) local n = 0 for _ in t do n += 1 end return n end
print("plan: buildings", #plan.buildings, "lamps", #plan.lamps, "trees", #plan.trees, "cars", #plan.cars, "plots", #plan.plots, "npcSpots", count(plan.npcSpots))
print("spawns per district", #plan.spawns[1], #plan.spawns[2], #plan.spawns[3], #plan.spawns[4])
for _, n in Config.NPCS do assert(plan.npcSpots[n.id], "missing NPC spot " .. n.id) end
assert(#plan.plots == 4, "expected 4 plots")
assert(plan.spawnPoint, "no spawn point")
-- every spawn must be inside its district
for d = 1, 4 do for _, p in plan.spawns[d] do assert(Config.districtOf(p.X, p.Z) == d, "spawn in wrong district") end end
CB.Build(plan)
print("after Build: parts", STATS.parts, "instances", STATS.instances, "lights", STATS.lights)
local HB = require(srv.HomeBuilder)
local plotM = Instance.new("Model"); plotM.Parent = workspace
for i = 2, 6 do HB.SetStage(plotM, plan.plots[1], i) end
for _, d in Config.DECOR do HB.AddDecor(plotM, plan.plots[1], d.id) end
HB.Sign(plotM, plan.plots[1], "Участок: test")
local IF = require(srv.ItemFactory)
for _, it in Config.ITEMS do
	local m = IF.Make(it, CFrame.new(0, 0.6, 0))
	assert(m.PrimaryPart, "no primary part for " .. it.id)
end
IF.Make({ id = "treasure", shape = "treasure", r = 5, name = "Сундук" }, CFrame.new())
for i, u in Config.UPGRADES do assert(Config.upgradeCost(u, 0) > 0) end
print("all builders OK; total parts", STATS.parts)
