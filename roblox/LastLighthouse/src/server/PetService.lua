--[[
	PetService — духи-питомцы, которые летают за игроком.

	Модели духов собираются из простых деталей прямо в коде (ничего
	не нужно скачивать). Дух следует за игроком через AlignPosition,
	а физику духа считает компьютер самого игрока — так он летает плавно.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("LastLighthouse"):WaitForChild("Config"))
local DataService = require(script.Parent:WaitForChild("DataService"))

local PetService = {}

local world = workspace:WaitForChild("LastLighthouseWorld")
local petsFolder = world:FindFirstChild("Pets")
if not petsFolder then
	petsFolder = Instance.new("Folder")
	petsFolder.Name = "Pets"
	petsFolder.Parent = world
end

local SLOT_OFFSETS = {
	Vector3.new(2.8, 1.6, 2.2),
	Vector3.new(-2.8, 1.6, 2.2),
	Vector3.new(0, 3.2, 3.4),
}

local EYE_COLOR = Color3.fromRGB(25, 20, 45)

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		p[k] = v
	end
	return p
end

local function attach(model, root, p, offset)
	p.CFrame = root.CFrame * offset
	p.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = p
	weld.Parent = p
	return p
end

local function addGlow(root, color, size)
	local attachment = Instance.new("Attachment")
	attachment.Name = "Glow"
	attachment.Parent = root

	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 8 + size * 2
	light.Brightness = 1.6
	light.Parent = attachment

	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Color = ColorSequence.new(color)
	particles.LightEmission = 1
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25 * size),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Transparency = NumberSequence.new(0.2, 1)
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Rate = 8
	particles.Speed = NumberRange.new(0.2, 0.8)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = attachment
end

local function addEyes(model, root, s, forward, height, spread)
	for _, side in ipairs({ -1, 1 }) do
		attach(model, root, part({
			Name = "Eye",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.22, 0.22, 0.22) * s,
			Color = EYE_COLOR,
		}), CFrame.new(side * spread * s, height * s, -forward * s))
		attach(model, root, part({
			Name = "EyeShine",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.08, 0.08, 0.08) * s,
			Color = Color3.new(1, 1, 1),
			Material = Enum.Material.Neon,
		}), CFrame.new(side * spread * s + 0.04 * s, (height + 0.05) * s, -(forward + 0.1) * s))
	end
end

local builders = {}

builders.orb = function(model, root, def, s)
	attach(model, root, part({
		Name = "Core",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.55, 0.55, 0.55) * s,
		Color = def.glow,
		Material = Enum.Material.Neon,
	}), CFrame.new(0, -0.05 * s, 0.1 * s))
	addEyes(model, root, s, 0.45, 0.1, 0.17)
	for _, side in ipairs({ -1, 1 }) do
		attach(model, root, part({
			Name = "Wing",
			Size = Vector3.new(0.7, 0.05, 0.4) * s,
			Color = Color3.fromRGB(230, 245, 255),
			Material = Enum.Material.Glass,
			Transparency = 0.45,
		}), CFrame.new(side * 0.5 * s, 0.3 * s, 0.1 * s) * CFrame.Angles(0, 0, side * math.rad(25)))
	end
end

builders.jelly = function(model, root, def, s)
	addEyes(model, root, s, 0.45, 0.0, 0.18)
	for i = 0, 5 do
		local angle = i / 6 * math.pi * 2
		attach(model, root, part({
			Name = "Tentacle",
			Size = Vector3.new(0.09, 0.8, 0.09) * s,
			Color = def.glow,
			Material = Enum.Material.Neon,
			Transparency = 0.2,
		}), CFrame.new(math.cos(angle) * 0.25 * s, -0.65 * s, math.sin(angle) * 0.25 * s))
	end
	attach(model, root, part({
		Name = "Cap",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1.05, 1.05, 1.05) * s,
		Color = def.color,
		Material = Enum.Material.Glass,
		Transparency = 0.55,
	}), CFrame.new(0, 0.12 * s, 0))
end

builders.fox = function(model, root, def, s)
	addEyes(model, root, s, 0.45, 0.12, 0.17)
	attach(model, root, part({
		Name = "Snout",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.3, 0.3, 0.3) * s,
		Color = Color3.fromRGB(255, 235, 215),
	}), CFrame.new(0, -0.12 * s, -0.42 * s))
	for _, side in ipairs({ -1, 1 }) do
		local ear = Instance.new("WedgePart")
		ear.Anchored = false
		ear.CanCollide = false
		ear.CanTouch = false
		ear.CanQuery = false
		ear.Massless = true
		ear.CastShadow = false
		ear.Size = Vector3.new(0.1, 0.45, 0.3) * s
		ear.Color = def.color
		ear.Material = Enum.Material.SmoothPlastic
		attach(model, root, ear, CFrame.new(side * 0.25 * s, 0.5 * s, 0) * CFrame.Angles(0, math.rad(90), side * math.rad(-12)))
	end
	attach(model, root, part({
		Name = "Tail",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(0.5, 0.5, 0.5) * s,
		Color = def.glow,
		Material = Enum.Material.Neon,
	}), CFrame.new(0, 0.1 * s, 0.6 * s))
end

builders.phoenix = function(model, root, def, s)
	addEyes(model, root, s, 0.45, 0.12, 0.16)
	attach(model, root, part({
		Name = "Beak",
		Size = Vector3.new(0.15, 0.12, 0.25) * s,
		Color = Color3.fromRGB(255, 210, 90),
	}), CFrame.new(0, -0.02 * s, -0.55 * s))
	for _, side in ipairs({ -1, 1 }) do
		attach(model, root, part({
			Name = "Wing",
			Size = Vector3.new(1.3, 0.06, 0.6) * s,
			Color = def.glow,
			Material = Enum.Material.Neon,
			Transparency = 0.1,
		}), CFrame.new(side * 0.85 * s, 0.25 * s, 0.1 * s) * CFrame.Angles(0, side * math.rad(-15), side * math.rad(20)))
	end
	for i = -1, 1 do
		attach(model, root, part({
			Name = "Tail",
			Size = Vector3.new(0.12, 0.06, 1.1) * s,
			Color = i == 0 and def.color or def.glow,
			Material = Enum.Material.Neon,
		}), CFrame.new(i * 0.18 * s, 0, 0.85 * s) * CFrame.Angles(0, i * math.rad(18), 0))
	end
	attach(model, root, part({
		Name = "Crest",
		Size = Vector3.new(0.06, 0.35, 0.25) * s,
		Color = def.glow,
		Material = Enum.Material.Neon,
	}), CFrame.new(0, 0.55 * s, -0.1 * s) * CFrame.Angles(math.rad(-20), 0, 0))
end

local function buildPet(def)
	local model = Instance.new("Model")
	model.Name = def.id
	local s = def.size
	local root = part({
		Name = "Root",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(1, 1, 1) * s,
		Color = def.color,
		Massless = false,
	})
	root.Parent = model
	model.PrimaryPart = root

	local builder = builders[def.style] or builders.orb
	builder(model, root, def, s)
	addGlow(root, def.glow, s)

	local tag = Instance.new("BillboardGui")
	tag.Name = "PetTag"
	tag.Size = UDim2.fromOffset(140, 22)
	tag.StudsOffset = Vector3.new(0, 1.1 * s, 0)
	tag.MaxDistance = 40
	tag.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.Text = def.name
	label.TextColor3 = def.rarityColor
	label.TextStrokeTransparency = 0.4
	label.Parent = tag
	tag.Parent = root

	return model, root
end

local function clearPets(player)
	local folder = petsFolder:FindFirstChild(tostring(player.UserId))
	if folder then
		folder:Destroy()
	end
end

function PetService.Refresh(player)
	clearPets(player)
	local data = DataService.Get(player)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not data or not hrp then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = tostring(player.UserId)
	folder.Parent = petsFolder

	for index, petId in ipairs(data.equipped) do
		local def = Config.PetById[petId]
		local offset = SLOT_OFFSETS[index]
		if def and offset then
			local slotName = "PetSlot" .. index
			local slot = hrp:FindFirstChild(slotName)
			if not slot then
				slot = Instance.new("Attachment")
				slot.Name = slotName
				slot.Parent = hrp
			end
			slot.Position = offset
			slot:SetAttribute("BasePosition", offset)

			local model, root = buildPet(def)
			model:PivotTo(hrp.CFrame * CFrame.new(offset))

			local attachment = Instance.new("Attachment")
			attachment.Name = "Follow"
			attachment.Parent = root

			local alignPosition = Instance.new("AlignPosition")
			alignPosition.Attachment0 = attachment
			alignPosition.Attachment1 = slot
			alignPosition.Responsiveness = 18
			alignPosition.MaxForce = 100000
			alignPosition.MaxVelocity = 200
			alignPosition.Parent = root

			local alignOrientation = Instance.new("AlignOrientation")
			alignOrientation.Attachment0 = attachment
			alignOrientation.Attachment1 = slot
			alignOrientation.Responsiveness = 12
			alignOrientation.MaxTorque = 100000
			alignOrientation.Parent = root

			model.Parent = folder
			pcall(function()
				root:SetNetworkOwner(player)
			end)
		end
	end
end

function PetService.Start()
	Players.PlayerRemoving:Connect(clearPets)
end

return PetService
