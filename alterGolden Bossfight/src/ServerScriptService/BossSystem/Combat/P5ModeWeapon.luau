--[[
 P5ModeWeapon - the weapon the boss carries during a Phase 5 mode (P5ModeService equips it on entering a mode,
 drops it on leaving). His own sword is put away meanwhile. The weapon is welded in his hand along the line his
 sword's blade takes, so every pose holds it the same way:
   Space   Star Saber   - an obsidian blade with a violet edge and a star at the tip
   Natural Aurora Glaive - a long dark shaft with a mint-and-blue crescent blade and an aurora trail
   Time    Clock Hand   - a giant gold minute hand with a gear guard and a counterweight
 The attack it is swung with lives in Attacks/P5/Weapon/P5ModeWeapon.
]]
local BossSystem = script:FindFirstAncestor("BossSystem")
local Weapons = require(BossSystem.Boss.WeaponController)
local api = {}
local held = setmetatable({}, { __mode = "k" })

local VIOLET = Color3.fromRGB(174, 114, 255)
local DEEP = Color3.fromRGB(46, 18, 84)
local MINT = Color3.fromRGB(115, 255, 205)
local BLUE = Color3.fromRGB(98, 195, 255)
local GOLD = Color3.fromRGB(255, 200, 70)
local SHINE = Color3.fromRGB(255, 246, 214)
local IRON = Color3.fromRGB(38, 44, 54)
local NEON, METAL, FOIL = Enum.Material.Neon, Enum.Material.Metal, Enum.Material.Foil

 -- the hand and the grip frame in hand space whose -Z runs along the sword blade
local function gripFrame(actor)
	local hand = actor:FindFirstChild("RightHand") or actor:FindFirstChild("Right Arm")
	if not hand then return nil end
	local sword = Weapons.Get(actor)
	local grip = actor:FindFirstChild("RightGrip", true) or actor:FindFirstChild("BossSwordGrip", true)
	local handle = sword and sword:FindFirstChild("Handle")
	local blade = sword and sword:FindFirstChild("Blade")
	if grip and grip:IsA("JointInstance") and grip.Part0 == hand and handle and blade and blade:IsA("BasePart") then
		local inHand = grip.C0 * grip.C1:Inverse()
		local along = handle.CFrame:VectorToObjectSpace(blade.Position - handle.Position)
		if along.Magnitude > 0.05 then
			return hand, inHand * CFrame.lookAt(Vector3.zero, along.Unit)
		end
	end
	return hand, CFrame.new(0, -hand.Size.Y * 0.5, 0) * CFrame.Angles(-math.pi / 2, 0, 0)
end

local function part(folder, root, name, size, cf, color, material, alpha, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or NEON
	p.Transparency = alpha or 0
	if shape then p.Shape = shape end
	p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow, p.Massless, p.Anchored = false, false, false, false, true, false
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.CFrame = root.CFrame * cf
	local w = Instance.new("Weld")
	w.Part0, w.Part1, w.C0 = root, p, cf
	w.Parent = p
	p.Parent = folder
	return p
end

local function sparkles(parent, color, rate)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(SHINE, color)
	e.LightEmission, e.LightInfluence = 1, 0
	e.Size = NumberSequence.new(0.25, 0)
	e.Lifetime = NumberRange.new(0.4, 0.8)
	e.Speed = NumberRange.new(0.5, 2)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = rate
	e.Shape = Enum.ParticleEmitterShape.Box
	e.Parent = parent
	return e
end

local BUILD = {}
function BUILD.Space(folder, root)
	part(folder, root, "SaberGuard", Vector3.new(1.5, 0.22, 0.32), CFrame.new(0, 0, -0.55), DEEP, METAL)
	part(folder, root, "SaberGem", Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, 0, -0.55), VIOLET, NEON, 0, Enum.PartType.Ball)
	part(folder, root, "SaberGrip", Vector3.new(0.28, 0.28, 1.1), CFrame.new(0, 0, 0.1), DEEP, METAL)
	local core = part(folder, root, "SaberBlade", Vector3.new(0.14, 0.5, 5.4), CFrame.new(0, 0, -3.4), Color3.fromRGB(22, 10, 40), NEON)
	part(folder, root, "SaberEdge", Vector3.new(0.1, 0.72, 5.6), CFrame.new(0, 0, -3.45), VIOLET, NEON, 0.45)
	local tip = part(folder, root, "SaberStar", Vector3.new(0.7, 0.7, 0.7), CFrame.new(0, 0, -6.3), SHINE, NEON, 0, Enum.PartType.Ball)
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = VIOLET, 10, 2, false
	light.Parent = tip
	sparkles(core, VIOLET, 18)
end
function BUILD.Natural(folder, root)
	part(folder, root, "GlaiveShaft", Vector3.new(0.24, 0.24, 7.2), CFrame.new(0, 0, -1.8), IRON, METAL)
	part(folder, root, "GlaiveBand", Vector3.new(0.34, 0.34, 0.3), CFrame.new(0, 0, -5.2), MINT, NEON)
	local blade = part(folder, root, "GlaiveBlade", Vector3.new(0.14, 1.5, 2.8), CFrame.new(0, 0.55, -6.6) * CFrame.Angles(math.rad(-18), 0, 0), MINT, NEON, 0.05)
	part(folder, root, "GlaiveGlow", Vector3.new(0.1, 2, 3.2), CFrame.new(0, 0.6, -6.6) * CFrame.Angles(math.rad(-18), 0, 0), BLUE, NEON, 0.5)
	part(folder, root, "GlaiveSpike", Vector3.new(0.14, 0.5, 1.4), CFrame.new(0, -0.35, -6.1) * CFrame.Angles(math.rad(25), 0, 0), BLUE, NEON)
	local a0 = Instance.new("Attachment") a0.Position = Vector3.new(0, 0.7, 0.9) a0.Parent = blade
	local a1 = Instance.new("Attachment") a1.Position = Vector3.new(0, -0.6, -1) a1.Parent = blade
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.Color = ColorSequence.new(MINT, BLUE)
	trail.Transparency = NumberSequence.new(0.35, 1)
	trail.Lifetime, trail.LightEmission, trail.LightInfluence, trail.FaceCamera = 0.3, 1, 0, false
	trail.Parent = blade
	sparkles(blade, MINT, 14)
end
function BUILD.Time(folder, root)
	part(folder, root, "ClockWeight", Vector3.new(0.75, 0.75, 0.75), CFrame.new(0, 0, 0.75), GOLD, FOIL, 0, Enum.PartType.Ball)
	part(folder, root, "ClockGear", Vector3.new(0.25, 1.5, 1.5), CFrame.new(0, 0, -0.45) * CFrame.Angles(0, math.pi / 2, 0), GOLD, FOIL, 0, Enum.PartType.Cylinder)
	part(folder, root, "ClockHub", Vector3.new(0.3, 0.55, 0.55), CFrame.new(0, 0, -0.45) * CFrame.Angles(0, math.pi / 2, 0), SHINE, NEON, 0, Enum.PartType.Cylinder)
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		part(folder, root, "ClockTooth", Vector3.new(0.22, 0.28, 0.28), CFrame.new(0, math.cos(a) * 0.82, -0.45 + math.sin(a) * 0.82), GOLD, FOIL)
	end
	local hand = part(folder, root, "ClockBlade", Vector3.new(0.16, 0.42, 5.6), CFrame.new(0, 0, -3.5), GOLD, FOIL)
	part(folder, root, "ClockLine", Vector3.new(0.18, 0.1, 5.4), CFrame.new(0, 0, -3.5), SHINE, NEON)
	for _, s in ipairs({ -1, 1 }) do
		part(folder, root, "ClockTip", Vector3.new(0.16, 0.5, 1.3), CFrame.new(0, s * 0.3, -6.5) * CFrame.Angles(s * math.rad(28), 0, 0), GOLD, FOIL)
	end
	sparkles(hand, GOLD, 12)
end

function api.Equip(actor, mode)
	api.Unequip(actor)
	local build = BUILD[mode]
	local hand, frame = gripFrame(actor)
	if not build or not hand then return false end
	local folder = Instance.new("Folder")
	folder.Name = "P5ModeWeapon"
	local root = Instance.new("Part")
	root.Name = "WeaponGrip"
	root.Size = Vector3.one * 0.2
	root.Transparency = 1
	root.CanCollide, root.CanQuery, root.CanTouch, root.Massless, root.Anchored = false, false, false, true, false
	root.CFrame = hand.CFrame * frame
	local w = Instance.new("Weld")
	w.Part0, w.Part1, w.C0 = hand, root, frame
	w.Parent = root
	root.Parent = folder
	build(folder, root)
	held[actor] = { Folder = folder, Unarmed = actor:GetAttribute("UnarmedCombat") == true }
	Weapons.SetUnarmed(actor, true)  -- his own sword goes away while the mode weapon is out
	folder.Parent = actor
	actor:SetAttribute("P5Weapon", mode)
	return true
end

function api.Unequip(actor)
	local record = held[actor]
	held[actor] = nil
	local folder = actor:FindFirstChild("P5ModeWeapon")
	if folder then folder:Destroy() end
	if record and actor.Parent then
		Weapons.SetUnarmed(actor, record.Unarmed)
	end
	actor:SetAttribute("P5Weapon", nil)
end

return api
