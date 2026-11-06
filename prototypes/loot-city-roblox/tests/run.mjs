// PROTOTYPE - NOT FOR PRODUCTION
// Feeds module sources to the Luau CLI test (the CLI has no file I/O for loadstring sources).
import fs from 'fs';
import { execFileSync } from 'child_process';
const luau = process.argv[2];
const files = { Server: 'src/server/Server.server.lua', Config: 'src/shared/Config.lua', CityBuilder: 'src/server/CityBuilder.lua', ItemFactory: 'src/server/ItemFactory.lua', HomeBuilder: 'src/server/HomeBuilder.lua' };
let prelude = 'local SRC = {}\n';
for (const [k, p] of Object.entries(files)) {
  const s = fs.readFileSync(p, 'utf8');
  prelude += `SRC[${JSON.stringify(k)}] = ${JSON.stringify(s)}\n`;
}
const runner = fs.readFileSync('' + (process.argv[3] || 'tests/run_builders.luau') + '', 'utf8').replace('local SRC = ...', '');
const script = fs.readFileSync('tests/mock_roblox.luau', 'utf8') + '\n' + prelude + '\n' + runner;
fs.mkdirSync('tests/.out', { recursive: true });
fs.writeFileSync('tests/.out/bundle.luau', script);
console.log(execFileSync(luau, ['tests/.out/bundle.luau'], { encoding: 'utf8' }));
