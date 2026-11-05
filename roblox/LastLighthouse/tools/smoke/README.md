# Дымовой тест «Последнего Маяка»

Запускает установщик и все скрипты игры в имитации Roblox API (Lua-VM fengari в Node.js),
без Roblox Studio. Ловит ошибки выполнения: опечатки, nil, неверные аргументы CFrame/Vector3,
сломанный донат (двойная выдача), паркур, событие Тени, сохранение.

Это НЕ замена запуску в Studio — внешний вид, физика и UI-раскладка проверяются только там.

```bash
cd roblox/LastLighthouse/tools/smoke
npm install fengari@0.1.4
python3 ../build_installer.py
node sim.js ../../LastLighthouse_Installer.txt
```

Ожидаемый итог: `ALL SMOKE TESTS PASSED`, `warnings: 0`.
