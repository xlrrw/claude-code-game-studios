--[[
	StoryService — сюжет: вступление, записки первого Смотрителя и Старый Орин.

	• Записки — детали в LastLighthouseWorld.Notes с атрибутом NoteIndex (1..5).
	• Орин — модель LastLighthouseWorld.Orin, с ним можно поговорить.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LastLighthouse"):WaitForChild("Config"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local State = require(script.Parent:WaitForChild("ServerState"))

local StoryService = {}

local world = workspace:WaitForChild("LastLighthouseWorld")

local function ensurePrompt(parent, action, object)
	local prompt = parent:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = action
		prompt.ObjectText = object
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = parent
	end
	return prompt
end

local function countNotes(data)
	local n = 0
	for _ in pairs(data.notes) do
		n = n + 1
	end
	return n
end

local function readNote(player, index)
	local data = DataService.Get(player)
	local text = Config.Story.Notes[index]
	if not data or not text then
		return
	end
	local key = tostring(index)
	local firstTime = not data.notes[key]
	data.notes[key] = true

	State.Remotes.Dialogue:FireClient(player, {
		speaker = "Записка первого Смотрителя (" .. index .. "/" .. #Config.Story.Notes .. ")",
		lines = { text },
		style = "note",
	})

	if firstTime then
		State.AddLight(player, Config.Story.NoteReward.light)
		State.AddXp(player, Config.Story.NoteReward.xp)
		State.Notify(player, "📜 Новая записка! +" .. Config.Story.NoteReward.light .. " ✦", "story")
		if countNotes(data) >= #Config.Story.Notes then
			task.delay(1.5, function()
				if player.Parent then
					State.Remotes.Dialogue:FireClient(player, {
						speaker = "Тайна Тени",
						lines = { Config.Story.AllNotesMessage },
						style = "shadow",
					})
				end
			end)
		end
	end
	State.PushPlayer(player)
end

local function orinLines(player)
	local data = DataService.Get(player)
	if not data then
		return { "Подожди немного, путник..." }
	end
	local lines = {}
	local hasPet = next(data.pets) ~= nil
	local notes = countNotes(data)
	local rankIndex = State.GetRank(data.keeperXp)

	if State.World.shadow.active then
		table.insert(lines, "Чувствуешь холод? Тень совсем рядом! Скорее неси свет в Маяк — все вместе мы её прогоним!")
		return lines
	end
	if data.light < 30 and data.keeperXp < 50 then
		table.insert(lines, "Видишь сияющие осколки? Просто подойди к ним — свет сам потянется к тебе.")
		table.insert(lines, "Когда наберёшь света, подойди к дверям Маяка и отдай часть огню. За это ты получишь опыт Смотрителя.")
		return lines
	end
	if not hasPet then
		table.insert(lines, "В одиночку собирать свет тяжело. Загляни в меню «Духи» — Светлячок стоит совсем немного.")
	end
	if data.starShards < 1 then
		table.insert(lines, "За мостом на востоке начинается Рушащийся остров. Острова там уже падают... но на вершине спрятан Осколок Звезды.")
	end
	if notes < #Config.Story.Notes then
		table.insert(lines, "Ты нашёл " .. notes .. " из " .. #Config.Story.Notes .. " записок первого Смотрителя. Поищи на соседних островах и вдоль паркура.")
	else
		table.insert(lines, "Ты прочёл все записки... Значит, ты тоже понял. Тень когда-то была одним из нас. Но об этом — позже.")
	end
	if rankIndex < #Config.Ranks then
		table.insert(lines, "Каждый новый ранг Смотрителя навсегда делает твой свет сильнее. Не жалей огня для Маяка!")
	end
	if #lines == 0 then
		table.insert(lines, "Ты стал настоящим Смотрителем. Маяк горит ярче, пока ты рядом.")
	end
	return lines
end

function StoryService.IntroDone(player)
	local data = DataService.Get(player)
	if data and not data.introSeen then
		data.introSeen = true
		State.PushPlayer(player)
	end
end

function StoryService.Start()
	local notes = world:FindFirstChild("Notes")
	if notes then
		for _, note in ipairs(notes:GetDescendants()) do
			if note:IsA("BasePart") and note:GetAttribute("NoteIndex") then
				local index = note:GetAttribute("NoteIndex")
				local prompt = ensurePrompt(note, "Прочитать", "Записка")
				prompt.Triggered:Connect(function(player)
					readNote(player, index)
				end)
			end
		end
	end

	local orin = world:FindFirstChild("Orin")
	local talkPart = orin and (orin:FindFirstChild("Head") or orin.PrimaryPart)
	if talkPart then
		local prompt = ensurePrompt(talkPart, "Поговорить", "Старый Орин")
		prompt.Triggered:Connect(function(player)
			State.Remotes.Dialogue:FireClient(player, {
				speaker = "Старый Орин",
				lines = orinLines(player),
			})
		end)
	end
end

return StoryService
