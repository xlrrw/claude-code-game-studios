const fs = require('fs');
const { lua, lauxlib, lualib, to_luastring } = require('fengari');
const L = lauxlib.luaL_newstate();
lualib.luaL_openlibs(L);
lua.lua_pushstring(L, to_luastring(fs.readFileSync(process.argv[2], 'utf8')));
lua.lua_setglobal(L, to_luastring('INSTALLER'));
for (const f of [__dirname + '/mock.lua', __dirname + '/run.lua']) {
  if (lauxlib.luaL_dostring(L, to_luastring(fs.readFileSync(f, 'utf8'))) !== 0) {
    console.log('LUA ERROR in', f, lua.lua_tojsstring(L, -1)); process.exit(1);
  }
}
