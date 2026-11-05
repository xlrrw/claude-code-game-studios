#!/usr/bin/env python3
"""Собирает установщик для Command Bar Roblox Studio из файлов src/ и installer/.

Запуск:  python3 roblox/LastLighthouse/tools/build_installer.py
Результат: roblox/LastLighthouse/LastLighthouse_Installer.txt

Соглашения имён (как у Rojo):
  *.server.lua -> Script, *.client.lua -> LocalScript, *.lua -> ModuleScript
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "LastLighthouse_Installer.txt"

# (папка в src, путь в игре)
TARGETS = [
    ("shared", "ReplicatedStorage"),
    ("server", "ServerScriptService"),
    ("client", "StarterPlayer.StarterPlayerScripts"),
]
PRESERVE = {"MonetizationIds"}  # не перезаписывать при повторной установке
FILE_ORDER = {"Config": 0, "MonetizationIds": 1}


def long_string(text: str) -> str:
    level = 1
    while f"]{'=' * level}]" in text or f"[{'=' * level}[" in text:
        level += 1
    eq = "=" * level
    return f"[{eq}[\n{text}]{eq}]"


def class_and_name(path: Path):
    name = path.name
    if name.endswith(".server.lua"):
        return "Script", name[: -len(".server.lua")]
    if name.endswith(".client.lua"):
        return "LocalScript", name[: -len(".client.lua")]
    return "ModuleScript", name[: -len(".lua")]


def collect(targets):
    version = "?"
    entries = []
    for folder, service in targets:
        files = sorted((ROOT / "src" / folder).glob("*.lua"),
                       key=lambda p: (FILE_ORDER.get(class_and_name(p)[1], 5), p.name))
        for path in files:
            cls, name = class_and_name(path)
            source = path.read_text(encoding="utf-8")
            if name == "Config":
                for line in source.splitlines():
                    if line.startswith("Config.Version"):
                        version = line.split('"')[1]
            entries.append(
                "\t{ service = %r, name = %r, class = %r, preserve = %s, source = %s },"
                % (service, name, cls, "true" if name in PRESERVE else "false", long_string(source))
            )

    return version, entries


def make(targets, with_world, out, part_title):
    version, entries = collect(TARGETS)
    _, entries = collect(targets)
    services = [service for _, service in targets]
    services_lua = ", ".join('"%s"' % s for s in services)
    build_world = (ROOT / "installer" / "BuildWorld.lua").read_text(encoding="utf-8") if with_world else ""
    world_block = ("""
-- строим мир
local function BuildWorld()
""" + build_world + """
end
BuildWorld()
print("[Маяк] Мир построен: острова, Маяк, паркур, северное сияние")
""") if with_world else ""

    done_hint = ("Теперь вставь следующую часть." if part_title and not with_world
                 else "Нажми Play, чтобы сыграть в «Последний Маяк». Сохрани место: File → Save to Roblox")
    installer = f'''--[[
	================================================================
	  ПОСЛЕДНИЙ МАЯК  v{version}  — УСТАНОВЩИК ДЛЯ COMMAND BAR{part_title}
	================================================================
	1. Открой Roblox Studio → New → Baseplate (новое пустое место).
	2. Вкладка View → включи «Command Bar» (и «Output», чтобы видеть сообщения).
	3. Выдели ВЕСЬ этот текст (Ctrl+A), скопируй (Ctrl+C),
	   вставь в Command Bar (Ctrl+V) и нажми Enter.
	4. Подожди 10–30 секунд. В Output появится «✦ УСТАНОВКА ЗАВЕРШЕНА».
	5. Нажми Play — и играй!

	ВНИМАНИЕ: установщик пересоздаёт ландшафт и мир «LastLighthouseWorld».
	Запускай его в НОВОМ месте (или там, где уже стоит «Последний Маяк»).
	Твои ID доната в MonetizationIds при повторной установке сохраняются.
	Собрано автоматически из папки roblox/LastLighthouse/src.
]]

local okInstall, installError = pcall(function()

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local recording = nil
pcall(function()
	recording = ChangeHistoryService:TryBeginRecording("Install Last Lighthouse")
end)

local FILES = {{
{chr(10).join(entries)}
}}

local function resolve(path)
	local node = game
	for part in string.gmatch(path, "[^%.]+") do
		if node == game then
			node = game:GetService(part)
		else
			node = node:FindFirstChild(part) or node:WaitForChild(part, 5)
		end
	end
	return node
end

-- сохраняем ID доната из прошлой установки
local preserved = {{}}
for _, file in ipairs(FILES) do
	if file.preserve then
		local root = resolve(file.service)
		local old = root:FindFirstChild("LastLighthouse") and root.LastLighthouse:FindFirstChild(file.name)
		if old and old:IsA("LuaSourceContainer") then
			preserved[file.name] = old.Source
		end
	end
end

-- удаляем старые папки игры
for _, servicePath in ipairs({{ {services_lua} }}) do
	local root = resolve(servicePath)
	local old = root:FindFirstChild("LastLighthouse")
	if old then
		old:Destroy()
	end
end

-- создаём скрипты
local created = 0
for _, file in ipairs(FILES) do
	local root = resolve(file.service)
	local folder = root:FindFirstChild("LastLighthouse")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "LastLighthouse"
		folder.Parent = root
	end
	local script = Instance.new(file.class)
	script.Name = file.name
	script.Source = preserved[file.name] or file.source
	script.Parent = folder
	created = created + 1
end
print("[Маяк] Скриптов создано: " .. created)

{world_block}
if recording then
	pcall(function()
		ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
	end)
end

end)

if okInstall then
	print("✦✦✦ УСТАНОВКА{part_title} ЗАВЕРШЕНА! {done_hint} ✦✦✦")
	print("Подсказки: включи Lighting → Technology = Future для лучшей графики; донат настраивается в ReplicatedStorage → LastLighthouse → MonetizationIds")
else
	warn("[Маяк] Ошибка установки: " .. tostring(installError))
end
'''
    out.write_text(installer, encoding="utf-8")
    print(f"OK: {out.name} ({len(installer.encode('utf-8')) // 1024} KB, {len(entries)} скриптов)")


def main():
    make(TARGETS, True, OUT, "")
    parts = ROOT / "installer_parts"
    parts.mkdir(exist_ok=True)
    make(TARGETS[:2], False, parts / "Part1_Server.txt", " (ЧАСТЬ 1 из 3)")
    make(TARGETS[2:], False, parts / "Part2_Client.txt", " (ЧАСТЬ 2 из 3)")
    make([], True, parts / "Part3_World.txt", " (ЧАСТЬ 3 из 3)")


if __name__ == "__main__":
    main()
