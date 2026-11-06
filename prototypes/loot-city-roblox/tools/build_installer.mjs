// PROTOTYPE - NOT FOR PRODUCTION
// Packs all Luau sources into one script for the Roblox Studio Command Bar: dist/LootCity_Installer.lua
import fs from 'fs';
const read = (p) => fs.readFileSync(p, 'utf8');
const SRC = {
  Config: read('src/shared/Config.lua'),
  CityBuilder: read('src/server/CityBuilder.lua'),
  ItemFactory: read('src/server/ItemFactory.lua'),
  HomeBuilder: read('src/server/HomeBuilder.lua'),
  Server: read('src/server/Server.server.lua'),
  Client: read('src/client/Client.client.lua'),
};
const EQ = '========';
for (const [k, s] of Object.entries(SRC)) {
  if (s.includes(']' + EQ + ']')) throw new Error('delimiter clash in ' + k);
}
const ls = (s) => `[${EQ}[\n${s}]${EQ}]`;
const out = `-- ================================================================
-- LOOT CITY: Город возможностей — установщик для Roblox Studio
-- 1) Откройте пустое место (шаблон Baseplate) в Roblox Studio
-- 2) Вкладка View -> Command Bar
-- 3) Вставьте ВЕСЬ этот текст в Command Bar и нажмите Enter
-- 4) Дождитесь сообщения "Loot City установлен" в Output и нажмите Play
-- Повторная установка безопасна: старая версия удаляется.
-- ================================================================
local ok, err = pcall(function()
	local RS = game:GetService("ReplicatedStorage")
	local SSS = game:GetService("ServerScriptService")
	local SP = game:GetService("StarterPlayer")
	local Lighting = game:GetService("Lighting")
	local SPS = SP:WaitForChild("StarterPlayerScripts")
	print("[LootCity] установка…")
	for _, o in { RS:FindFirstChild("LootCityShared"), SSS:FindFirstChild("LootCityServer"), SPS:FindFirstChild("LootCityClient"),
		workspace:FindFirstChild("LootCityMap"), workspace:FindFirstChild("LootCityLoot"), workspace:FindFirstChild("LootCityNPC"),
		workspace:FindFirstChild("LootCityPlots"), workspace:FindFirstChild("Baseplate"), workspace:FindFirstChild("SpawnLocation") } do
		if o then o:Destroy() end
	end
	local function script(class, name, parent, source)
		local s = Instance.new(class)
		s.Name = name
		s.Source = source
		s.Parent = parent
		return s
	end
	local shared = Instance.new("Folder")
	shared.Name = "LootCityShared"
	shared.Parent = RS
	script("ModuleScript", "Config", shared, ${ls(SRC.Config)})
	local server = Instance.new("Folder")
	server.Name = "LootCityServer"
	server.Parent = SSS
	local cityBuilder = script("ModuleScript", "CityBuilder", server, ${ls(SRC.CityBuilder)})
	script("ModuleScript", "ItemFactory", server, ${ls(SRC.ItemFactory)})
	script("ModuleScript", "HomeBuilder", server, ${ls(SRC.HomeBuilder)})
	script("Script", "Server", server, ${ls(SRC.Server)})
	script("LocalScript", "LootCityClient", SPS, ${ls(SRC.Client)})

	-- ===== realistic lighting =====
	print("[LootCity] настройка освещения…")
	for _, c in Lighting:GetChildren() do
		if c:IsA("PostEffect") or c:IsA("Sky") or c:IsA("Atmosphere") or c:IsA("Clouds") then c:Destroy() end
	end
	pcall(function() Lighting.Technology = Enum.Technology.Future end)
	Lighting.Brightness = 3
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.15
	Lighting.Ambient = Color3.fromRGB(38, 40, 46)
	Lighting.OutdoorAmbient = Color3.fromRGB(112, 118, 128)
	Lighting.ExposureCompensation = 0.1
	Lighting.GeographicLatitude = 38
	Lighting.ClockTime = 9
	local function make(class, props)
		local o = Instance.new(class)
		for k, v in props do o[k] = v end
		o.Parent = Lighting
		return o
	end
	make("Atmosphere", { Density = 0.3, Offset = 0.22, Color = Color3.fromRGB(199, 211, 224), Decay = Color3.fromRGB(104, 112, 124), Glare = 0.4, Haze = 1.4 })
	make("Sky", { SunAngularSize = 12, MoonAngularSize = 9, StarCount = 3000, CelestialBodiesShown = true })
	make("BloomEffect", { Intensity = 0.55, Size = 28, Threshold = 1.35 })
	make("ColorCorrectionEffect", { Brightness = 0.02, Contrast = 0.14, Saturation = 0.08, TintColor = Color3.fromRGB(255, 250, 244) })
	make("SunRaysEffect", { Intensity = 0.05, Spread = 0.7 })
	make("DepthOfFieldEffect", { FarIntensity = 0.1, FocusDistance = 60, InFocusRadius = 160, NearIntensity = 0 })
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Cover = 0.55
	clouds.Density = 0.6
	clouds.Parent = workspace.Terrain
	pcall(function() workspace.StreamingEnabled = false end)

	-- ===== build the city right in the editor so it is saved with the place =====
	print("[LootCity] строим город (это займёт несколько секунд)…")
	local CB = require(cityBuilder)
	CB.Build(CB.Plan())
	pcall(function() game:GetService("ChangeHistoryService"):SetWaypoint("Loot City installed") end)
end)
if ok then
	print("✅ Loot City установлен! Нажмите Play (F5). Чтобы сохранения работали в опубликованной игре — Game Settings → Security → Enable Studio Access to API Services.")
else
	warn("❌ Ошибка установки Loot City: " .. tostring(err))
end
`;
fs.mkdirSync('dist', { recursive: true });
fs.writeFileSync('dist/LootCity_Installer.lua', out);
console.log('dist/LootCity_Installer.lua', (out.length / 1024).toFixed(0), 'KB');
