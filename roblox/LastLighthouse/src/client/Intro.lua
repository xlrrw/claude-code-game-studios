--[[
	Intro — вступительная катсцена при первом входе:
	пролёт камеры над Облачным морем к Маяку, название игры,
	затем Старый Орин рассказывает историю.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LastLighthouse"):WaitForChild("Config"))

local player = Players.LocalPlayer
local Intro = {}

local function tween(inst, time, props, style, direction)
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Sine, direction or Enum.EasingDirection.InOut), props)
	t:Play()
	return t
end

local function makeOverlay()
	local gui = Instance.new("ScreenGui")
	gui.Name = "LastLighthouseIntro"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")

	local function bar(top)
		local f = Instance.new("Frame")
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.BorderSizePixel = 0
		f.Size = UDim2.new(1, 0, 0, 0)
		f.AnchorPoint = Vector2.new(0, top and 0 or 1)
		f.Position = UDim2.fromScale(0, top and 0 or 1)
		f.Parent = gui
		return f
	end
	local topBar, bottomBar = bar(true), bar(false)

	local fade = Instance.new("Frame")
	fade.BackgroundColor3 = Color3.fromRGB(8, 6, 20)
	fade.BorderSizePixel = 0
	fade.Size = UDim2.fromScale(1, 1)
	fade.BackgroundTransparency = 0
	fade.ZIndex = 5
	fade.Parent = gui

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.Position = UDim2.fromScale(0.5, 0.42)
	title.Size = UDim2.fromScale(0.9, 0.16)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.Text = Config.Story.Title
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextTransparency = 1
	title.ZIndex = 6
	title.Parent = gui
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(Color3.fromRGB(255, 225, 130), Color3.fromRGB(255, 130, 220))
	g.Rotation = 90
	g.Parent = title
	local st = Instance.new("UIStroke")
	st.Thickness = 3
	st.Color = Color3.fromRGB(20, 10, 40)
	st.Transparency = 1
	st.Parent = title

	local subtitle = Instance.new("TextLabel")
	subtitle.BackgroundTransparency = 1
	subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
	subtitle.Position = UDim2.fromScale(0.5, 0.53)
	subtitle.Size = UDim2.fromScale(0.8, 0.05)
	subtitle.Font = Enum.Font.GothamBold
	subtitle.TextScaled = true
	subtitle.Text = Config.Story.Subtitle
	subtitle.TextColor3 = Color3.fromRGB(200, 190, 255)
	subtitle.TextTransparency = 1
	subtitle.ZIndex = 6
	subtitle.Parent = gui

	local skip = Instance.new("TextButton")
	skip.AnchorPoint = Vector2.new(1, 1)
	skip.Position = UDim2.new(1, -20, 1, -20)
	skip.Size = UDim2.fromOffset(170, 40)
	skip.BackgroundColor3 = Color3.fromRGB(40, 30, 90)
	skip.BackgroundTransparency = 0.2
	skip.Font = Enum.Font.FredokaOne
	skip.TextSize = 18
	skip.TextColor3 = Color3.new(1, 1, 1)
	skip.Text = "Пропустить ▶▶"
	skip.ZIndex = 10
	skip.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = skip

	return {
		gui = gui,
		topBar = topBar,
		bottomBar = bottomBar,
		fade = fade,
		title = title,
		titleStroke = st,
		subtitle = subtitle,
		skip = skip,
	}
end

function Intro.Play(UI)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local world = workspace:WaitForChild("LastLighthouseWorld")
	local lighthouse = world:WaitForChild("Lighthouse", 10)
	local camera = workspace.CurrentCamera
	if not lighthouse then
		return
	end

	local lantern = lighthouse:FindFirstChild("Lantern", true)
	local target = lantern and lantern.Position or lighthouse:GetPivot().Position
	local orin = world:FindFirstChild("Orin")
	local orinHead = orin and orin:FindFirstChild("Head")

	UI.SetHudVisible(false)
	local o = makeOverlay()
	local skipped = false
	o.skip.Activated:Connect(function()
		skipped = true
	end)

	local function waitOrSkip(seconds)
		local deadline = os.clock() + seconds
		while os.clock() < deadline and not skipped do
			task.wait()
		end
	end

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(target + Vector3.new(260, -40, 260), target)

	tween(o.topBar, 1, { Size = UDim2.new(1, 0, 0.11, 0) })
	tween(o.bottomBar, 1, { Size = UDim2.new(1, 0, 0.11, 0) })
	tween(o.fade, 2, { BackgroundTransparency = 1 })

	-- Кадр 1: подъём из Облачного моря
	local shot1 = tween(camera, 7, { CFrame = CFrame.lookAt(target + Vector3.new(110, 25, 140), target) })
	task.delay(1.2, function()
		if skipped then
			return
		end
		tween(o.title, 1.5, { TextTransparency = 0 })
		tween(o.titleStroke, 1.5, { Transparency = 0 })
		tween(o.subtitle, 1.5, { TextTransparency = 0 }).Completed:Wait()
		task.wait(2.5)
		if skipped then
			return
		end
		tween(o.title, 1, { TextTransparency = 1 })
		tween(o.titleStroke, 1, { Transparency = 1 })
		tween(o.subtitle, 1, { TextTransparency = 1 })
	end)
	waitOrSkip(7)
	shot1:Cancel()

	-- Кадр 2: облёт вокруг Маяка
	if not skipped then
		local shot2 = tween(camera, 6, { CFrame = CFrame.lookAt(target + Vector3.new(-70, 10, 60), target + Vector3.new(0, -10, 0)) })
		waitOrSkip(6)
		shot2:Cancel()
	end

	o.title.TextTransparency = 1
	o.titleStroke.Transparency = 1
	o.subtitle.TextTransparency = 1
	o.skip.Visible = false

	-- Кадр 3: Старый Орин
	if orinHead then
		local look = orinHead.CFrame
		local from = look * CFrame.new(-3, 1, -9)
		tween(camera, skipped and 0.6 or 2, { CFrame = CFrame.lookAt(from.Position, look.Position) })
		task.wait(skipped and 0.6 or 2)
	end
	UI.ShowDialogueAsync({ speaker = Config.Story.IntroSpeaker, lines = Config.Story.IntroLines })

	-- Возвращаем управление
	tween(o.topBar, 0.8, { Size = UDim2.new(1, 0, 0, 0) })
	tween(o.bottomBar, 0.8, { Size = UDim2.new(1, 0, 0, 0) })
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid
	UI.SetHudVisible(true)
	UI.Banner("Глава I", "Тень над облаками")
	task.delay(1, function()
		o.gui:Destroy()
	end)
	UI.Notify("Подсказка: подходи к сияющим осколкам — свет сам притянется к тебе ✦", "info")
end

return Intro
