--[[
	Sound — звуки и музыка. ID задаются в Config.Sounds (0 = тишина).
]]

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LastLighthouse"):WaitForChild("Config"))

local Sound = {}
local cache = {}

local function getSound(name)
	local id = Config.Sounds[name]
	if type(id) ~= "number" or id <= 0 then
		return nil
	end
	local s = cache[name]
	if not s then
		s = Instance.new("Sound")
		s.Name = "LL_" .. name
		s.SoundId = "rbxassetid://" .. id
		s.Volume = 0.6
		s.Parent = SoundService
		cache[name] = s
	end
	return s
end

function Sound.Play(name)
	local s = getSound(name)
	if s then
		SoundService:PlayLocalSound(s)
	end
end

function Sound.StartMusic()
	local s = getSound("Music")
	if s then
		s.Looped = true
		s.Volume = 0.3
		s:Play()
	end
end

return Sound
