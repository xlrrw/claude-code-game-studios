local function step(name, fn)
	local ok, err = pcall(fn)
	print((ok and "PASS " or "FAIL ") .. name .. (ok and "" or (": " .. tostring(err))))
	if not ok then FAILED = true end
end

local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

step("installer runs", function()
	local fn = assert(load(INSTALLER, "=Installer", "t"))
	local co = task.spawn(fn)
	RUN(1)
	assert(coroutine.status(co) == "dead", "installer still running")
	for _, w in ipairs(WARNINGS) do if w:find("Ошибка установки") then error(w) end end
end)

local world = workspace:FindFirstChild("LastLighthouseWorld")
step("world built", function()
	assert(world, "no world")
	for _, n in ipairs({ "Lighthouse", "Orin", "ShardSpawns", "Notes", "Obby", "Sky", "ShadowWisp", "ActiveShards", "Pets" }) do
		assert(world:FindFirstChild(n), "missing " .. n)
	end
	local spawns = #world.ShardSpawns:GetChildren()
	local notes = 0
	for _, d in ipairs(world.Notes:GetDescendants()) do if d:GetAttribute("NoteIndex") then notes = notes + 1 end end
	print("  shard spawns:", spawns, "notes:", notes, "checkpoints:", #world.Obby.Checkpoints:GetChildren(),
		"falling:", #world.Obby.FallingPlatforms:GetChildren(), "blink:", #world.Obby.BlinkPlatforms:GetChildren(), "instances:", #ALL_INSTANCES)
	assert(notes == 5, "need 5 notes")
	assert(world.Lighthouse:FindFirstChild("DepositPad", true), "no pad")
	assert(world.Lighthouse:FindFirstChild("BeamPivot", true), "no pivot")
end)

step("scripts installed", function()
	assert(RS.LastLighthouse.Config and RS.LastLighthouse.MonetizationIds)
	assert(SSS.LastLighthouse.Main.ClassName == "Script")
	assert(game:GetService("StarterPlayer").StarterPlayerScripts.LastLighthouse.ClientMain.ClassName == "LocalScript")
end)

-- server start
step("server starts", function()
	RUN_SCRIPT(SSS.LastLighthouse.Main)
	RUN(1)
	assert(#world.ActiveShards:GetChildren() > 0, "no shards spawned")
end)

local Config = require(RS.LastLighthouse.Config)
local DataService = require(SSS.LastLighthouse.DataService)
local State = require(SSS.LastLighthouse.ServerState)

LOCAL_PLAYER = NEW_PLAYER("Tester", 101)
Players.__props.LocalPlayer = LOCAL_PLAYER
local p = LOCAL_PLAYER
step("player joins", function()
	p.Parent = Players
	Players.PlayerAdded:Fire(p)
	SPAWN_CHARACTER(p, Vector3.new(0, 3, 45))
	RUN(2)
	assert(DataService.Get(p), "no data")
	assert(p:FindFirstChild("leaderstats"), "no leaderstats")
	assert(p.Character.Head:FindFirstChild("KeeperTag"), "no overhead")
end)

step("client starts", function()
	local folder = game:GetService("StarterPlayer").StarterPlayerScripts.LastLighthouse
	RUN_SCRIPT(folder.ClientMain)
	RUN(3)
	assert(p.PlayerGui:FindFirstChild("LastLighthouseUI"), "no UI")
end)

local function clickDialogue(times)
	for _ = 1, times do
		local d = p.PlayerGui.LastLighthouseUI:FindFirstChild("Dialogue")
		d.Activated:Fire()
		RUN(0.2)
	end
end

step("intro plays and finishes", function()
	RUN(16)
	clickDialogue(20)
	RUN(3)
	assert(DataService.Get(p).introSeen == true, "intro not marked seen")
	assert(workspace.CurrentCamera.CameraType == "Enum.CameraType.Custom", "camera not restored")
end)

local Remotes = RS.LastLighthouse.Remotes
local function act(name, arg) Remotes.Action:FireServer(name, arg) RUN(0.3) end
local data = DataService.Get(p)

step("collect shards", function()
	local shard = world.ActiveShards:GetChildren()[1]
	p.Character.HumanoidRootPart.CFrame = CFrame.new(shard.Position)
	RUN(0.5)
	assert(data.light > 0, "no light collected")
	print("  light after pickup:", data.light)
end)

step("shop: cannot afford, then buy upgrade + pet", function()
	data.light = 0
	act("BuyUpgrade", "Radius")
	assert(data.upgrades.Radius == 0)
	data.light = 100000
	act("BuyUpgrade", "Radius") act("BuyUpgrade", "Speed")
	assert(data.upgrades.Radius == 1 and data.upgrades.Speed == 1, "upgrade failed")
	assert(p.Character.Humanoid.WalkSpeed > 16, "speed not applied")
	act("BuyPet", "Firefly")
	assert(data.pets.Firefly and data.equipped[1] == "Firefly", "pet buy failed")
	assert(#world.Pets[tostring(p.UserId)]:GetChildren() == 1, "pet model missing")
	act("BuyPet", "Fox")
	act("EquipPet", "Fox")
	assert(data.equipped[1] == "Fox" and #data.equipped == 1, "swap failed")
	act("BuyPet", "Phoenix") -- robux pet must not be buyable with light
	assert(not data.pets.Phoenix)
	print("  multiplier:", State.GetMultiplier(p), "radius:", State.GetRadius(p))
end)

step("open shop tabs (client render)", function()
	local UI = require(game:GetService("StarterPlayer").StarterPlayerScripts.LastLighthouse.UI)
	UI.OpenShop("Upgrades") RUN(0.2) UI.OpenShop("Pets") RUN(0.2) UI.OpenShop("Donate") RUN(0.2)
	UI.OpenDeposit() RUN(0.5)
end)

step("deposit to lighthouse + rank up", function()
	data.light = 2000
	act("Deposit", 0.5)
	assert(data.light == 1000, "deposit amount wrong " .. data.light)
	assert(data.keeperXp >= 1000, "xp missing")
	assert(State.World.lighthouseTotal == 1000 and State.World.level == 2, "lighthouse level " .. State.World.level)
	act("Deposit", 0.3) -- invalid fraction ignored
	assert(data.light == 1000)
end)

step("monetization: prompts with id 0 just notify", function()
	act("PromptPass", "VIP")
	act("PromptProduct", "LightSmall")
	assert(not PROMPTS, "should not prompt without ids")
end)

step("ProcessReceipt grants once", function()
	local idsModule = RS.LastLighthouse.MonetizationIds
	idsModule.Source = idsModule.Source:gsub("LightSmall = 0", "LightSmall = 555"):gsub("PhoenixSpirit = 0", "PhoenixSpirit = 777")
	RESET_MODULES()
	local Mon = require(SSS.LastLighthouse.MonetizationService)
	Mon.Start()
	local MPS = game:GetService("MarketplaceService")
	local before = data.light
	local DS2 = require(SSS.LastLighthouse.DataService)
	-- new module instances have separate profiles; load the player into them
	task.spawn(function() DS2.Load(p) end)
	RUN(1)
	local d2 = DS2.Get(p)
	local b2 = d2.light
	local r1, r2
	task.spawn(function() r1 = MPS.ProcessReceipt({ PlayerId = 101, ProductId = 555, PurchaseId = "abc" }) end)
	RUN(1)
	task.spawn(function() r2 = MPS.ProcessReceipt({ PlayerId = 101, ProductId = 555, PurchaseId = "abc" }) end)
	RUN(1)
	assert(r1 == "Enum.ProductPurchaseDecision.PurchaseGranted" and r2 == r1, tostring(r1) .. " " .. tostring(r2))
	assert(d2.light == b2 + 500, "granted " .. (d2.light - b2))
	local r3
	task.spawn(function() r3 = MPS.ProcessReceipt({ PlayerId = 101, ProductId = 777, PurchaseId = "def" }) end)
	RUN(1)
	assert(d2.pets.Phoenix, "phoenix not granted")
	local r4
	task.spawn(function() r4 = MPS.ProcessReceipt({ PlayerId = 999, ProductId = 555, PurchaseId = "x" }) end)
	RUN(1)
	assert(r4 == "Enum.ProductPurchaseDecision.NotProcessedYet")
end)

step("notes and orin", function()
	local note = world.Notes:FindFirstChild("Note1")
	note:FindFirstChildOfClass("ProximityPrompt").Triggered:Fire(p)
	RUN(0.5)
	assert(data.notes["1"], "note not saved")
	clickDialogue(3)
	world.Orin.Head:FindFirstChildOfClass("ProximityPrompt").Triggered:Fire(p)
	RUN(0.5)
	clickDialogue(6)
end)

step("obby: checkpoint, falling platform, void, finish", function()
	local cp = world.Obby.Checkpoints:FindFirstChild("Checkpoint2")
	cp.Touched:Fire(p.Character.HumanoidRootPart)
	local fall = world.Obby.FallingPlatforms:GetChildren()[1]
	fall.Touched:Fire(p.Character.HumanoidRootPart)
	RUN(5)
	p.Character.HumanoidRootPart.CFrame = CFrame.new(0, -100, 0)
	RUN(0.5)
	local y = p.Character.HumanoidRootPart.Position
	print("  respawned at", tostring(y))
	assert((y - cp.Position).Magnitude < 10, "not returned to checkpoint")
	local before = data.light
	world.Obby.Finish.Touched:Fire(p.Character.HumanoidRootPart)
	RUN(1)
	assert(data.light > before and data.starShards == 1, "finish reward")
	clickDialogue(2)
	RUN(4)
end)

step("shadow event cycle", function()
	RUN(250, 0.25)
	assert(State.World.shadow.active, "shadow did not start")
	data.light = 100000
	act("Deposit", 1)
	RUN(2, 0.25)
	assert(not State.World.shadow.active, "shadow should end on goal")
	assert(State.World.shadowBoostUntil > 0, "no boost")
end)

step("player leaves, data saved", function()
	p.Parent = nil
	Players.PlayerRemoving:Fire(p)
	RUN(2)
end)

print("warnings:", #WARNINGS)
for _, w in ipairs(WARNINGS) do print("  - " .. w) end
print(FAILED and "SOME TESTS FAILED" or "ALL SMOKE TESTS PASSED")
