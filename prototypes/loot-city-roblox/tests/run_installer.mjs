// PROTOTYPE - NOT FOR PRODUCTION
// Runs dist/LootCity_Installer.lua inside the mock (as the Command Bar would), then starts the installed server.
import fs from 'fs';
import { execFileSync } from 'child_process';
const installer = fs.readFileSync('dist/LootCity_Installer.lua', 'utf8');
const test = `
local SP = game:GetService("StarterPlayer")
local sps = Instance.new("StarterPlayerScripts"); sps.Name = "StarterPlayerScripts"; sps.Parent = SP
local bp = Instance.new("Part"); bp.Name = "Baseplate"; bp.Parent = workspace
local cache = {}
function require(inst)
	if cache[inst] then return cache[inst] end
	local fn = assert(loadstring(inst.Source, inst.Name))
	setfenv(fn, setmetatable({ script = inst }, { __index = getfenv(1) }))
	cache[inst] = fn()
	return cache[inst]
end
local INSTALLER = ${JSON.stringify(installer)}
local fn = assert(loadstring(INSTALLER, "installer"))
setfenv(fn, getfenv(1))
fn()
assert(workspace:FindFirstChild("LootCityMap"), "map not built")
assert(not workspace:FindFirstChild("Baseplate"), "baseplate not removed")
assert(game:GetService("ReplicatedStorage").LootCityShared.Config, "config missing")
assert(sps:FindFirstChild("LootCityClient"), "client missing")
print("installed parts", STATS.parts)
-- start the installed server script like Play would
local server = game:GetService("ServerScriptService").LootCityServer.Server
local sfn = assert(loadstring(server.Source, "Server"))
setfenv(sfn, setmetatable({ script = server }, { __index = getfenv(1) }))
sfn()
local plr = MockAddPlayer(7)
for _, f in DELAYED do task.spawn(f) end
for _ = 1, 50 do game:GetService("RunService").Heartbeat:Fire(0.1) end
print("loot after play", #workspace.LootCityLoot:GetChildren(), "npcs", #workspace.LootCityNPC:GetChildren())
print("INSTALLER TEST OK")
`;
fs.mkdirSync('tests/.out', { recursive: true });
fs.writeFileSync('tests/.out/installer_bundle.luau', fs.readFileSync('tests/mock_roblox.luau', 'utf8') + '\n' + test);
process.stdout.write(execFileSync(process.argv[2], ['tests/.out/installer_bundle.luau'], { encoding: 'utf8' }));
