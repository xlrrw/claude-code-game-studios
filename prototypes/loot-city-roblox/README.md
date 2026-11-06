# Loot City: Город возможностей — Roblox

**Status:** in-progress (playable build, not yet run inside real Roblox Studio)

## Hypothesis
Same as `prototypes/loot-city`: the single-player find-sell-upgrade-expand loop in a
city stays engaging without other players. This version runs on Roblox.

## Install (Command Bar)
1. Roblox Studio → New → **Baseplate**.
2. View → **Command Bar**.
3. Paste all of `dist/LootCity_Installer.lua` → Enter. Wait for "✅ Loot City установлен!" in Output.
4. Play (F5). For saves in a published game: Game Settings → Security → Enable Studio Access to API Services.

Alternative for developers: `rojo serve` with `default.project.json` (the map is then built by the server at runtime).

## What's inside
- `src/shared/Config.lua` — items, rarities, districts, upgrades, vehicles, home, businesses, NPCs, map layout.
- `src/server/CityBuilder.lua` — deterministic city plan + builder (Future lighting, real materials).
- `src/server/ItemFactory.lua`, `HomeBuilder.lua` — loot models, home stages and decor.
- `src/server/Server.server.lua` — DataStore saves, economy, loot, NPC shops, quests, events, plots, vehicles.
- `src/client/Client.client.lua` — HUD, minimap, phone, shop UI, night lights, rain, traffic, sprint.
- `tools/build_installer.mjs` — packs everything into `dist/LootCity_Installer.lua`.

## Tests
A minimal Roblox API mock (`tests/mock_roblox.luau`) lets the Luau CLI run:
`node tests/run.mjs <luau> tests/run_builders.luau`, `... tests/run_server.luau`, `node tests/run_installer.mjs <luau>`.
Static analysis: `luau-lsp analyze --definitions=<roblox globalTypes> --sourcemap=sourcemap.json src/...`.

## Findings
- Builders, server session (pickup → sell → buy → build → permits → quests → events) and the installer pass in the mock.
- The client UI is only statically analysed — first real check is inside Studio.
- City ≈ 11.2k parts, 336 street lights (enabled only near the player at night).
