--[[
 EnragedGate - the Gate of Wrath behind the lobby statues. Hold its prompt to start the encounter straight in Phase 5
 against an enraged boss: workspace EncounterEnraged is set, then the PolyStar's own start runs (ArenaController
 .Activate), so the picked difficulty, lives and scaling all apply as usual. While EncounterEnraged is set,
 DifficultyConfig reads every profile through an enraged copy (more damage, faster cooldowns, shorter telegraphs,
 denser attacks, a sturdier boss, final phase 5), Development/InstantPhaseOverride skips to Phase 5 and marks the boss
 Enraged (BossClient.Presentation.P5ModeAuraClient draws the red aura). The gate closes during a fight and the flag
 clears when the encounter ends.
]]
local B = script:FindFirstAncestor("BossSystem")
local Arena = require(B.Encounter.ArenaController)
local api = {}
local CRIMSON = Color3.fromRGB(220, 30, 60)
local GOLD = Color3.fromRGB(255, 196, 64)
local STONE = Color3.fromRGB(38, 30, 34)
local SPOT = CFrame.lookAt(Vector3.new(-404, 0, 0), Vector3.new(0, 0, 0))  -- behind the class and difficulty statues
local LINE = "You skipped every lesson. Then you get all of me - nothing held back."
local prompt
local started = false

local function part(parent, name, size, cf, color, material, alpha)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Material = material or Enum.Material.Slate
	p.Transparency = alpha or 0
	p.Anchored, p.CanCollide, p.CanTouch, p.CastShadow = true, true, false, true
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function build()
	local arena = workspace:FindFirstChild("GoldenGrasslandArena") or workspace
	local old = arena:FindFirstChild("EnragedGate")
	if old then old:Destroy() end
	local model = Instance.new("Model")
	model.Name = "EnragedGate"
	local ray = workspace:Raycast(SPOT.Position + Vector3.new(0, 60, 0), Vector3.new(0, -120, 0))
	local base = SPOT + Vector3.new(0, ray and ray.Position.Y or 0, 0)
	part(model, "Step", Vector3.new(16, 1, 10), base * CFrame.new(0, 0.5, 0), STONE)
	part(model, "Step2", Vector3.new(13, 1, 7), base * CFrame.new(0, 1.5, 0.5), STONE)
	for _, x in ipairs({ -6, 6 }) do
		part(model, "Pillar", Vector3.new(3, 20, 3), base * CFrame.new(x, 12, 1), STONE)
		part(model, "Trim", Vector3.new(3.3, 0.5, 3.3), base * CFrame.new(x, 2.5, 1), GOLD, Enum.Material.Neon)
		part(model, "Trim", Vector3.new(3.3, 0.5, 3.3), base * CFrame.new(x, 21.5, 1), GOLD, Enum.Material.Neon)
		part(model, "Vein", Vector3.new(0.3, 17, 3.1), base * CFrame.new(x + (x < 0 and 1.4 or -1.4), 12, 1), CRIMSON, Enum.Material.Neon)
		local horn = part(model, "Horn", Vector3.new(1.6, 6, 3), base * CFrame.new(x * 1.15, 25, 1) * CFrame.Angles(0, 0, x < 0 and 0.45 or -0.45), STONE)
		horn.Shape = Enum.PartType.Block
		local tip = Instance.new("WedgePart")
		tip.Name, tip.Size, tip.Color, tip.Material = "HornTip", Vector3.new(3, 3, 1.6), GOLD, Enum.Material.Neon
		tip.Anchored, tip.CanCollide = true, false
		tip.CFrame = horn.CFrame * CFrame.new(0, 4.5, 0) * CFrame.Angles(0, math.pi / 2, 0)
		tip.Parent = model
	end
	local arch = part(model, "Arch", Vector3.new(17, 3, 3.6), base * CFrame.new(0, 23.5, 1), STONE)
	part(model, "ArchTrim", Vector3.new(17.4, 0.5, 3.8), base * CFrame.new(0, 21.9, 1), GOLD, Enum.Material.Neon)
	local portal = part(model, "Portal", Vector3.new(9, 19, 0.3), base * CFrame.new(0, 11.5, 1), CRIMSON, Enum.Material.Neon, 0.35)
	portal.CanCollide = false
	local inner = part(model, "PortalCore", Vector3.new(6, 15, 0.2), base * CFrame.new(0, 11, 1), Color3.fromRGB(20, 0, 8), Enum.Material.Neon, 0.15)
	inner.CanCollide = false
	local swirl = Instance.new("ParticleEmitter")
	swirl.Texture = "rbxasset://textures/particles/fire_main.dds"
	swirl.Color = ColorSequence.new(Color3.fromRGB(255, 80, 60), GOLD)
	swirl.LightEmission, swirl.Rate, swirl.Lifetime = 1, 25, NumberRange.new(0.8, 1.4)
	swirl.Speed = NumberRange.new(1, 3)
	swirl.Size = NumberSequence.new(3, 0)
	swirl.Transparency = NumberSequence.new(0.3, 1)
	swirl.Acceleration = Vector3.new(0, 4, 0)
	swirl.Parent = portal
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness = CRIMSON, 24, 3
	light.Parent = portal
	local sign = Instance.new("SurfaceGui")
	sign.Face, sign.LightInfluence, sign.Brightness = Enum.NormalId.Front, 0, 1.5
	sign.CanvasSize = Vector2.new(680, 120)
	local text = Instance.new("TextLabel")
	text.Size, text.BackgroundTransparency = UDim2.fromScale(1, 1), 1
	text.Text, text.Font, text.TextScaled = "GATE OF WRATH", Enum.Font.Garamond, true
	text.TextColor3, text.TextStrokeColor3, text.TextStrokeTransparency = Color3.fromRGB(255, 120, 110), Color3.fromRGB(40, 0, 6), 0
	text.Parent = sign
	sign.Parent = arch
	prompt = Instance.new("ProximityPrompt")
	prompt.Name = "EnterEnraged"
	prompt.ActionText = "Enter the Enraged Trial"
	prompt.ObjectText = "Gate of Wrath - Phase 5, enraged"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 2
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Enabled = workspace:GetAttribute("EncounterStarted") ~= true
	prompt.Parent = portal
	model.Parent = arena
	return prompt
end

local function enter(player)
	if workspace:GetAttribute("EncounterStarted") == true then
		return
	end
	workspace:SetAttribute("EncounterEnraged", true)
	if not Arena.Activate(player) then
		workspace:SetAttribute("EncounterEnraged", nil)
		return
	end
	task.spawn(function()
		for _ = 1, 100 do
			if workspace:GetAttribute("BossEncounterReady") == true then break end
			task.wait(0.2)
		end
		if workspace:GetAttribute("EncounterEnraged") == true then
			pcall(require(B.Players.PlayerEncounter).Say, LINE, nil, { Duration = 3.5 })
		end
	end)
end

function api.Start()
	if started then return end
	started = true
	build().Triggered:Connect(enter)
	workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(function()
		local on = workspace:GetAttribute("EncounterStarted") == true
		if prompt then prompt.Enabled = not on end
		if not on then workspace:SetAttribute("EncounterEnraged", nil) end
	end)
end

return api
