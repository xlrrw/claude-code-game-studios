# Loot City: Город возможностей — prototype

**Status:** in-progress (playable build)

## Hypothesis
A single-player "find loot → sell → upgrade → expand" loop in a realistic-looking
3D city is engaging on its own, without other players: NPC traders, quests, random
city events, collections, home building and passive businesses carry the session.

## How to run
- Windows: run `release/LootCity-Setup.exe` (per-user install, no admin), then launch from the desktop shortcut.
- Any OS: open `dist/LootCity.html` in Chrome/Edge (single self-contained file).

## Build
```
npm install && node build.mjs                 # -> dist/LootCity.html
cp dist/LootCity.html electron/ && cd electron && npm install
npx electron-builder --win --x64 --dir        # -> release/win-unpacked
cd ../installer && makensis LootCity.nsi      # -> release/LootCity-Setup.exe
```

## Tech
Three.js r170 (WebGL2), all assets procedural: PBR textures generated on canvas
(albedo / roughness-metalness / normal / emissive), Preetham sky + PMREM reflections,
4K soft sun shadows, N8AO ambient occlusion, HDR bloom, SMAA, ACES tone mapping,
film grade. Day/night cycle (12 min), rain with wet reflective asphalt, traffic.

## Findings
- Loop and all systems run end to end (verified headlessly: pickup, sell, quests,
  permits, home stages 1–5 + all decor, vehicles, businesses, all 6 events).
- Not yet tested on real Windows hardware; FPS on a discrete GPU is unmeasured.
- "Mega-realistic" is limited by having no photo-scanned assets; next step for
  fidelity would be real PBR texture sets and modelled characters/cars.
