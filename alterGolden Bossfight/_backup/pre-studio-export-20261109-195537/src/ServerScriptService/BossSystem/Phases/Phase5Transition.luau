 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Effects = require(BossSystem.Combat.EffectService)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Locomotion = require(BossSystem.Boss.BossLocomotion)
local Audio = require(BossSystem.Presentation.CombatAudio)
local Golden = require(BossSystem.Attacks.Shared.P4GoldenFX)
local FX = Golden.FX

local GOLD = Color3.fromRGB(255, 196, 40)
local BRIGHT = Color3.fromRGB(255, 236, 160)
local WHITE = Color3.fromRGB(255, 252, 236)
local EMBER = Color3.fromRGB(255, 150, 40)
local OBSIDIAN = Color3.fromRGB(20, 16, 24)
local VOID = Color3.fromRGB(40, 20, 60)
local METAL = Color3.fromRGB(255, 200, 90)
local ROCK = Color3.fromRGB(46, 40, 36)
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local UP = Vector3.yAxis
local rng = Random.new()

local POSES = {
	Bow = { Waist = { 28, 0, 0 }, Neck = { 32, 0, 0 }, RightHip = { 80, 0, 0 }, RightKnee = { 95, 0, 0 }, LeftHip = { -15, 0, 0 },
		LeftKnee = { 100, 0, 0 }, RightShoulder = { 8, 0, 6 }, RightElbow = { 20, 0, 0 }, LeftShoulder = { 8, 0, -6 }, LeftElbow = { 20, 0, 0 } },
	Rise = { Waist = { -5, 0, 0 }, Neck = { 6, 0, 0 }, RightHip = { 10, 0, 0 }, RightKnee = { 25, 0, 0 }, LeftHip = { -5, 0, 0 },
		LeftKnee = { 35, 0, 0 }, RightShoulder = { 15, 0, 45 }, RightElbow = { 30, 0, 0 }, LeftShoulder = { 15, 0, -45 }, LeftElbow = { 30, 0, 0 },
		RightWrist = { -25, 0, 0 }, LeftWrist = { -25, 0, 0 } },
	Clench = { Waist = { 18, 0, 0 }, Neck = { 22, 0, 0 }, RightHip = { 35, 0, 0 }, RightKnee = { 65, 0, 0 }, LeftHip = { 25, 0, 0 },
		LeftKnee = { 75, 0, 0 }, RightShoulder = { 80, 0, -40 }, RightElbow = { 105, 0, 0 }, LeftShoulder = { 80, 0, 40 }, LeftElbow = { 105, 0, 0 } },
	Scream = { Waist = { -22, 0, 0 }, Neck = { -40, 0, 0 }, RightHip = { -10, 0, 0 }, RightKnee = { 15, 0, 0 }, LeftHip = { -10, 0, 0 },
		LeftKnee = { 15, 0, 0 }, RightShoulder = { 40, 0, 110 }, RightElbow = { 5, 0, 0 }, LeftShoulder = { 40, 0, -110 }, LeftElbow = { 5, 0, 0 },
		RightWrist = { -30, 0, 0 }, LeftWrist = { -30, 0, 0 } },
	Ascendant = { Waist = { -4, 0, 0 }, Neck = { -4, 0, 0 }, RightHip = { 8, 0, 0 }, RightKnee = { 12, 0, 0 }, LeftHip = { -6, 0, 0 },
		LeftKnee = { 20, 0, 0 }, RightShoulder = { 75, 0, 15 }, RightElbow = { 5, 0, 0 }, RightWrist = { -30, 0, 0 },
		LeftShoulder = { 5, 0, -20 }, LeftElbow = { 15, 0, 0 } },
}

local api = { Poses = POSES }

local function screen(data)
	local remote = game.ReplicatedStorage:FindFirstChild("BossCombatEffects")
	if not remote then return end
	for _, player in ipairs(Players:GetPlayers()) do
		remote:FireClient(player, "Phase5Transform", data)
	end
end
local function shake(origin, intensity, duration)
	local remote = game.ReplicatedStorage:FindFirstChild("BossCombatEffects")
	if not remote then return end
	for _, player in ipairs(Players:GetPlayers()) do
		remote:FireClient(player, "Shake", { Origin = origin, Radius = 500, Duration = duration, Intensity = intensity })
	end
end
local function smooth(t) return t * t * (3 - 2 * t) end
local function flat(a) return Vector3.new(math.cos(a), 0, math.sin(a)) end

 
 
local function blade(make, rot, length, width, thickness)
	local list = {}
	for k = 0, 1 do
		local turn = rot * CFrame.Angles(0, 0, k * math.pi)
		local size = Vector3.new(thickness, width / 2, length)
		local p = make(size)
		p.Shape = Enum.PartType.Wedge
		table.insert(list, { Part = p, Rot = turn.Rotation, Offset = (turn * CFrame.new(0, width / 4, -length / 2)).Position, Size = size })
	end
	return list
end

 
 
 
local forms = setmetatable({}, { __mode = "k" })
local animator

local function formPart(folder, name, size, color, alpha, material)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Color, p.Transparency = name, size, color, alpha or 0
	p.Material = material or Enum.Material.Neon
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow, p.Massless = false, false, false, false, false, true
	p.Parent = folder
	return p
end
local function weld(part0, part1, c0)
	local w = Instance.new("Weld")
	w.Part0, w.Part1, w.C0 = part0, part1, c0 or CFrame.identity
	w.Parent = part1
	return w
end
local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture, e.LightEmission, e.LightInfluence = SPARK, 1, 0
	for k, v in pairs(props) do e[k] = v end
	e.Parent = parent
	return e
end

local function startAnimator()
	if animator then return end
	animator = Run.Heartbeat:Connect(function()
		local now = os.clock()
		local any = false
		for actor, form in pairs(forms) do
			if not actor.Parent or not form.Folder.Parent then
				forms[actor] = nil
				continue
			end
			any = true
			local t = now - form.Born
			if form.Halo then form.Halo.C0 = form.HaloBase * CFrame.Angles(0, 0, t * 0.7) end
			if form.Orbit then form.Orbit.C0 = CFrame.new(0, -0.4 + math.sin(t * 1.3) * 0.25, 0) * CFrame.Angles(0, t * 1.1, 0) end
			 -- a slow idle beat; BeatWings lifts them high and beats them hard for a while (the Butterfly)
			local beating = form.BeatUntil and now < form.BeatUntil
			local flap = beating and math.sin(t * 16) or math.sin(t * 2.1)
			local amp, lift = beating and 30 or 8, beating and 20 or 0
			if form.WingL then form.WingL.C0 = form.WingLBase * CFrame.Angles(0, math.rad(-amp * flap), math.rad(4 * flap - lift)) end
			if form.WingR then form.WingR.C0 = form.WingRBase * CFrame.Angles(0, math.rad(amp * flap), math.rad(-4 * flap + lift)) end
		end
		if not any then
			animator:Disconnect()
			animator = nil
		end
	end)
end

function api.BeatWings(actor, seconds)
	local form = forms[actor]
	if form then form.BeatUntil = os.clock() + seconds end
end

function api.HasForm(actor)
	return actor:FindFirstChild("Phase5Form") ~= nil
end

function api.ApplyForm(actor)
	if not actor or not actor.Parent or actor:FindFirstChild("Phase5Form") then return false end
	local head, torso, root = actor:FindFirstChild("Head"), actor:FindFirstChild("UpperTorso"), actor:FindFirstChild("HumanoidRootPart")
	if not head or not torso or not root then return false end
	local folder = Instance.new("Folder")
	folder.Name = "Phase5Form"
	actor:SetAttribute("Phase5Form", true)

	 
	for _, item in ipairs(actor:GetChildren()) do
		if item:IsA("Shirt") then
			item:SetAttribute("Phase5Template", item.ShirtTemplate)
			item.ShirtTemplate = ""
		elseif item:IsA("Pants") then
			item:SetAttribute("Phase5Template", item.PantsTemplate)
			item.PantsTemplate = ""
		end
	end
	local dark = { "UpperTorso", "LowerTorso", "LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg", "LeftFoot", "RightFoot" }
	local metal = { "Head", "LeftUpperArm", "LeftLowerArm", "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand" }
	for _, name in ipairs(dark) do
		local p = actor:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			p.Color, p.Material, p.Reflectance = OBSIDIAN, Enum.Material.SmoothPlastic, 0.12
		end
	end
	for _, name in ipairs(metal) do
		local p = actor:FindFirstChild(name)
		if p and p:IsA("BasePart") then
			p.Color, p.Material, p.Reflectance = METAL, Enum.Material.Foil, 0
		end
	end
	local face = head:FindFirstChildOfClass("Decal")
	if face then face.Transparency = 1 end

	 
	for _, name in ipairs(dark) do
		local p = actor:FindFirstChild(name)
		if p and p:IsA("BasePart") and not name:find("Foot") then
			local count = name:find("Torso") and 5 or 3
			for i = 1, count do
				local side = i % 2 == 0 and 1 or -1
				local length = rng:NextNumber(0.35, 0.9) * math.min(p.Size.X, p.Size.Y) * 1.3
				local seam = formPart(folder, "Phase5Seam", Vector3.new(0.07, 0.07, length), BRIGHT, 0)
				local x = rng:NextNumber(-0.35, 0.35) * p.Size.X
				local y = rng:NextNumber(-0.38, 0.38) * p.Size.Y
				weld(p, seam, CFrame.new(x, y, side * (p.Size.Z / 2 + 0.02)) * CFrame.Angles(0, 0, rng:NextNumber(0, math.pi)) * CFrame.Angles(0, math.pi / 2, 0))
			end
		end
	end

	 
	for _, x in ipairs({ -0.2, 0.2 }) do
		local eye = formPart(folder, "Phase5Eye", Vector3.new(0.2, 0.09, 0.05), WHITE, 0)
		weld(head, eye, CFrame.new(x, 0.12, -head.Size.Z / 2 - 0.12))
	end
	local eyeLight = Instance.new("PointLight")
	eyeLight.Color, eyeLight.Range, eyeLight.Brightness, eyeLight.Shadows = BRIGHT, 7, 2, false
	eyeLight.Parent = head

	 
	local haloCenter = formPart(folder, "Phase5HaloCenter", Vector3.one * 0.2, GOLD, 1)
	local haloBase = CFrame.new(0, 0.55, 0.95)
	local haloWeld = weld(head, haloCenter, haloBase)
	for i = 1, 20 do
		local a = (i - 1) / 20 * math.pi * 2
		local seg = formPart(folder, "Phase5HaloRing", Vector3.new(0.12, 0.5, 0.12), i % 2 == 0 and BRIGHT or GOLD, 0)
		weld(haloCenter, seg, CFrame.new(math.cos(a) * 1.55, math.sin(a) * 1.55, 0) * CFrame.Angles(0, 0, a))
	end
	for i = 1, 8 do
		local a = (i - 1) / 8 * math.pi * 2
		 
		local dir = Vector3.new(math.cos(a), math.sin(a), 0)
		local frame = CFrame.lookAt(Vector3.zero, dir, Vector3.new(-dir.Y, dir.X, 0))
		for _, w in ipairs(blade(function(size) return formPart(folder, "Phase5HaloRay", size, i % 2 == 0 and WHITE or GOLD, 0.05) end,
			frame, i % 2 == 0 and 1.3 or 0.8, 0.32, 0.06)) do
			weld(haloCenter, w.Part, CFrame.new(dir * 1.7) * CFrame.new(w.Offset) * w.Rot)
		end
	end

	 
	local function wing(side)
		local rootPart = formPart(folder, side > 0 and "Phase5WingR" or "Phase5WingL", Vector3.one * 0.2, GOLD, 1)
		local base = CFrame.new(side * 0.45, 0.45, torso.Size.Z / 2 + 0.25) * CFrame.Angles(0, math.rad(side * 18), 0)
		local w = weld(torso, rootPart, base)
		local lengths = { 3.4, 4.6, 5.6, 5, 3.8 }
		for i, length in ipairs(lengths) do
			local spread = math.rad(-25 + (i - 1) * 24)  
			local dir = Vector3.new(side * math.cos(spread), math.sin(spread) + 0.15, 0.35).Unit
			local frame = CFrame.lookAt(Vector3.zero, dir, Vector3.new(-dir.Y, dir.X, 0).Unit)
			for _, b in ipairs(blade(function(size)
				return formPart(folder, "Phase5Feather", size, i % 2 == 0 and WHITE or BRIGHT, 0.12)
			end, frame, length, 0.7, 0.07)) do
				weld(rootPart, b.Part, CFrame.new(b.Offset) * b.Rot)
			end
		end
		return w, base
	end
	local wingR, wingRBase = wing(1)
	local wingL, wingLBase = wing(-1)

	 
	for _, name in ipairs({ "LeftLowerArm", "RightLowerArm", "LeftLowerLeg", "RightLowerLeg" }) do
		local p = actor:FindFirstChild(name)
		if p then
			for k = -1, 1, 2 do
				local band = formPart(folder, "Phase5Band", Vector3.new(0.12, p.Size.X * 1.18, p.Size.Z * 1.18), GOLD, 0)
				band.Shape = Enum.PartType.Cylinder
				weld(p, band, CFrame.new(0, k * p.Size.Y * 0.28, 0) * CFrame.Angles(0, 0, math.pi / 2))
			end
		end
	end

	 
	local orbitCenter = formPart(folder, "Phase5Orbit", Vector3.one * 0.2, GOLD, 1)
	local orbitWeld = weld(root, orbitCenter, CFrame.identity)
	for i = 1, 3 do
		local a = (i - 1) / 3 * math.pi * 2
		local center = Vector3.new(math.cos(a) * 3.4, (i - 2) * 0.5, math.sin(a) * 3.4)
		for _, dir in ipairs({ UP, -UP }) do
			for _, b in ipairs(blade(function(size) return formPart(folder, "Phase5Shard", size, i == 2 and WHITE or GOLD, 0) end,
				CFrame.lookAt(Vector3.zero, dir, Vector3.xAxis), 0.9, 0.55, 0.3)) do
				weld(orbitCenter, b.Part, CFrame.new(center) * CFrame.new(b.Offset) * b.Rot)
			end
		end
		local glow = formPart(folder, "Phase5ShardGlow", Vector3.one * 0.9, GOLD, 0.6)
		glow.Shape = Enum.PartType.Ball
		weld(orbitCenter, glow, CFrame.new(center))
	end

	 
	local aura = Instance.new("Attachment")
	aura.Name = "Phase5Aura"
	aura.Parent = torso
	emitter(aura, { Color = ColorSequence.new(WHITE, GOLD), Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.35),
		NumberSequenceKeypoint.new(1, 0) }), Transparency = NumberSequence.new(0.1, 1), Lifetime = NumberRange.new(1, 1.8), Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(50, 50), Acceleration = Vector3.new(0, 6, 0), Rate = 16, EmissionDirection = Enum.NormalId.Top,
		Shape = Enum.ParticleEmitterShape.Box })
	emitter(aura, { Color = ColorSequence.new(WHITE, BRIGHT), Size = NumberSequence.new(0.3, 0), Transparency = NumberSequence.new(0, 1),
		Lifetime = NumberRange.new(0.1, 0.22), Speed = NumberRange.new(8, 18), SpreadAngle = Vector2.new(180, 180), Rate = 6 })
	emitter(aura, { Texture = SMOKE, LightEmission = 0, Color = ColorSequence.new(VOID, OBSIDIAN), Size = NumberSequence.new(1.5, 4),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.75), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(1.2, 2), Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(180, 180), Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-40, 40), Acceleration = Vector3.new(0, 2, 0), Rate = 5 })
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = GOLD, 16, 1.6, false
	light.Parent = aura
	local outline = Instance.new("Highlight")
	outline.Name = "Phase5Outline"
	outline.FillColor, outline.FillTransparency = GOLD, 0.92
	outline.OutlineColor, outline.OutlineTransparency = BRIGHT, 0.25
	outline.DepthMode = Enum.HighlightDepthMode.Occluded
	outline.Adornee = actor
	outline.Parent = folder

	folder.Parent = actor
	forms[actor] = {
		Folder = folder, Born = os.clock(),
		Halo = haloWeld, HaloBase = haloBase, Orbit = orbitWeld,
		WingL = wingL, WingLBase = wingLBase, WingR = wingR, WingRBase = wingRBase,
	}
	orbitWeld.C0 = CFrame.identity
	startAnimator()
	return true
end

function api.RemoveForm(actor)
	local folder = actor and actor:FindFirstChild("Phase5Form")
	if folder then folder:Destroy() end
	forms[actor] = nil
end

 
 
 
function api.Play(actor, cast, timeline)
	local root = actor:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local core = require(BossSystem.Combat.AttackRegistry).For(actor, "P1CombatCore")
	local ctx = Golden.Context(core)
	local charge, burst, reveal = timeline.Charge, timeline.Burst, timeline.Reveal
	local frame = timeline.Frame or root.CFrame
	local token = timeline.Token
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { actor, Runtime.Effects }
	local hit = workspace:Raycast(frame.Position, Vector3.new(0, -40, 0), params)
	local floor = hit and hit.Position or frame.Position - Vector3.new(0, 3, 0)
	local floorY = floor.Y
	local function send(stage, data)
		data = data or {}
		data.Stage, data.Owner, data.Token = stage, actor, token
		screen(data)
	end
	local function temp(name, cf, size, color, alpha, shape)
		local p = FX.Temp(ctx, cast, name, cf, size, color, alpha)
		if shape then p.Shape = shape end
		return p
	end
	local function pose(name, blend)
		if timeline.Animated then return end
		pcall(Locomotion.Pose, actor, POSES[name], blend)
	end

	 
	local animationId = Config.Phase5TransformAnimationId
	local authored = actor:FindFirstChild("Phase5Transform", true)
	if authored and authored:IsA("Animation") then animationId = authored.AnimationId end
	if type(animationId) == "string" and animationId ~= "" then
		local humanoid = actor:FindFirstChildOfClass("Humanoid")
		local anim = humanoid and (humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid))
		if anim then
			local animation = Instance.new("Animation")
			animation.AnimationId = animationId
			local ok, track = pcall(anim.LoadAnimation, anim, animation)
			if ok and track then
				timeline.Animated = true
				track.Priority = Enum.AnimationPriority.Action4
				track:Play(0.2)
				task.defer(function()
					local length = track.Length > 0 and track.Length or (charge + burst)
					track:AdjustSpeed(length / (charge + burst))
				end)
				cast:Schedule(charge + burst + reveal, function() track:Stop(0.4) end)
				local previous = cast.OnDispose
				cast.OnDispose = function(...)
					pcall(function() track:Stop(0.3) end)
					if previous then return previous(...) end
				end
			end
		end
	end

	 
	local born = cast:Now()
	local kneelDepth, lift = 1.5, 7
	cast:Step(function(_, now)
		if not root.Parent then return false end
		local t = now - born
		local y
		if t < 0.8 then
			y = -kneelDepth * smooth(t / 0.8)
		elseif t < charge then
			local k = smooth(math.clamp((t - 1.4) / math.max(0.5, charge - 1.8), 0, 1))
			y = -kneelDepth + (kneelDepth + lift) * k
		elseif t < charge + burst then
			y = lift + (t > charge + burst * 0.48 and 0.8 or 0)
		else
			local k = smooth(math.clamp((t - charge - burst - 0.6) / math.max(0.5, reveal - 1.2), 0, 1))
			y = (lift + 0.8) * (1 - k)
		end
		local tremble = 0
		if t > 1 and t < charge + burst * 0.48 then
			tremble = math.clamp((t - 1) / charge, 0, 1) * 0.12
		end
		local jitter = Vector3.new(rng:NextNumber(-1, 1), 0, rng:NextNumber(-1, 1)) * tremble
		root.CFrame = frame + Vector3.new(0, y, 0) + jitter
		root.AssemblyLinearVelocity = Vector3.zero
		return t < charge + burst + reveal + 1
	end)

	 
	send("Begin", { Center = floor, Frame = frame, Charge = charge, Burst = burst, Reveal = reveal, Title = timeline.Title })
	pose("Bow", 0.5)
	Audio.Emit(actor, "EntranceReveal", root)

	 
	local rings = {}
	for i, spec in ipairs({ { 10, BRIGHT, 0.45 }, { 18, GOLD, 0.55 }, { 27, GOLD, 0.7 } }) do
		local anchor, set = Golden.BeamRing(ctx, cast, "Phase5Sigil", floor + UP * (0.15 + i * 0.02), 1, spec[2], spec[3], 56)
		rings[i] = { Anchor = anchor, Set = set, Radius = spec[1], Width = spec[3] }
	end
	local spokes = {}
	for i = 1, 12 do
		spokes[i] = temp("Phase5Spoke", CFrame.new(floor), Vector3.new(0.18, 0.06, 0.1), i % 3 == 0 and WHITE or GOLD, 0.1)
	end
	 
	local cracks = {}
	for i = 1, 10 do
		local a = (i - 1) / 10 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local points = { floor + UP * 0.08 }
		local reach = rng:NextNumber(18, 30)
		for k = 1, 4 do
			local p = floor + flat(a + rng:NextNumber(-0.35, 0.35)) * reach * k / 4
			points[k + 1] = Vector3.new(p.X, floorY + 0.08, p.Z)
		end
		local segments = {}
		for k = 1, 4 do
			segments[k] = temp("Phase5Crack", CFrame.new(points[k]), Vector3.new(0.3, 0.05, 0.05), BRIGHT, 0)
		end
		cracks[i] = { Points = points, Segments = segments, Delay = rng:NextNumber(0, 0.4) }
	end
	 
	local rocks = {}
	for i = 1, 18 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(7, 22)
		local size = rng:NextNumber(0.8, 2.4)
		local rock = temp("Phase5Rock", CFrame.new(floor + flat(a) * r - UP * size), Vector3.new(size, size * rng:NextNumber(0.6, 1), size * rng:NextNumber(0.7, 1.2)), ROCK, 0)
		rock.Material = Enum.Material.Slate
		rocks[i] = { Part = rock, Angle = a, Radius = r, Height = rng:NextNumber(2, 14), Spin = CFrame.Angles(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1)),
			Start = rng:NextNumber(0.3, charge * 0.5), Rate = rng:NextNumber(0.15, 0.35), Velocity = nil }
	end
	 
	local gather = temp("Phase5Gather", CFrame.new(frame.Position), Vector3.one * 30, GOLD, 1)
	local inward = FX.Emitter(gather, {
		Color = FX.Grad(WHITE, BRIGHT, GOLD), Size = FX.Seq(0.9, 0.3), Transparency = FX.Seq(1, 0.1, 0),
		Lifetime = NumberRange.new(0.8), Speed = NumberRange.new(-34), Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface, Rotation = NumberRange.new(0, 360), Rate = 0,
	})
	 
	local pillarHeight = 420
	local pillar = temp("Phase5Pillar", CFrame.new(frame.Position + UP * pillarHeight / 2) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(pillarHeight, 0.2, 0.2), BRIGHT, 0.6, Enum.PartType.Cylinder)
	local pillarGlow = temp("Phase5PillarGlow", pillar.CFrame, Vector3.new(pillarHeight, 0.6, 0.6), GOLD, 0.85, Enum.PartType.Cylinder)
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = GOLD, 60, 0, false
	light.Parent = gather
	local highlight = Instance.new("Highlight")
	highlight.Name = "Phase5Charge"
	highlight.FillColor, highlight.OutlineColor = GOLD, WHITE
	highlight.FillTransparency, highlight.OutlineTransparency = 1, 1
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Adornee = actor
	highlight.Parent = actor
	cast:Add(highlight)

	local shattered = false
	local lastStep = born
	cast:Step(function(_, now)
		local t = now - born
		local dt = math.clamp(now - lastStep, 0, 0.1)
		lastStep = now
		local k = math.clamp(t / charge, 0, 1)
		 
		for i, ring in ipairs(rings) do
			local grow = smooth(math.clamp(k * 3 - (i - 1) * 0.4, 0, 1))
			if not shattered then
				ring.Set(math.max(0.5, ring.Radius * grow), 0.15 + 0.15 * math.sin(t * 6 + i), ring.Width * (1 + k))
			end
			ring.Anchor.CFrame = CFrame.new(floor + UP * (0.15 + i * 0.02)) * CFrame.Angles(0, t * (i % 2 == 0 and -0.4 or 0.3), 0)
		end
		if not shattered then
			for i, spoke in ipairs(spokes) do
				local a = (i - 1) / 12 * math.pi * 2 + t * 0.3
				local reach = 27 * smooth(math.clamp(k * 2.2 - 0.2, 0, 1))
				local from = floor + flat(a) * 10 + UP * 0.12
				local to = floor + flat(a) * math.max(10.05, reach) + UP * 0.12
				spoke.CFrame = CFrame.lookAt((from + to) / 2, to)
				spoke.Size = Vector3.new(0.18, 0.06, math.max(0.05, (to - from).Magnitude))
			end
			for _, crack in ipairs(cracks) do
				local c = math.clamp((k - crack.Delay * 0.5) * 1.6, 0, 1) * 4
				for s = 1, 4 do
					local seg = crack.Segments[s]
					local part = math.clamp(c - (s - 1), 0, 1)
					local a, b = crack.Points[s], crack.Points[s + 1]
					local tip = a:Lerp(b, part)
					if part > 0.01 then
						seg.CFrame = CFrame.lookAt((a + tip) / 2, tip + (b - a).Unit * 0.01)
						seg.Size = Vector3.new(0.3 - 0.05 * s, 0.05, (tip - a).Magnitude)
						seg.Transparency = 0.05
					else
						seg.Transparency = 1
					end
				end
			end
			 
			for _, rock in ipairs(rocks) do
				local lt = t - rock.Start
				if lt > 0 then
					local up = math.min(rock.Height, lt * (2 + 6 * k))
					rock.Angle += dt * rock.Rate * (1 + 2 * k)
					local p = floor + flat(rock.Angle) * rock.Radius + UP * up
					rock.Part.CFrame = CFrame.new(p) * rock.Spin * CFrame.Angles(lt * 0.6, lt * 0.4, 0)
				end
			end
			inward.Rate = 30 + 220 * k
			light.Brightness = 1 + 6 * k
			highlight.FillTransparency = 1 - 0.55 * k
			highlight.OutlineTransparency = 1 - 0.9 * k
			local w = 0.2 + 2.4 * k ^ 2
			pillar.Size = Vector3.new(pillarHeight, w, w)
			pillarGlow.Size = Vector3.new(pillarHeight, w * 3, w * 3)
		end
		return t < charge + burst + reveal
	end)

	 
	do
		local at, interval, n = 0.9, 1.25, 0
		while at < charge - 0.2 do
			n += 1
			local strength = math.clamp(at / charge, 0.2, 1)
			cast:Schedule(at, function()
				FX.Shockwave(ctx, cast, CFrame.new(floor + UP * 0.2), 4, 30 + 30 * strength, 0.5, GOLD, 0.25, 0.6 + strength)
				FX.Ring(ctx, cast, CFrame.new(frame.Position) * CFrame.Angles(math.pi / 2, 0, 0), 2, 12 + 10 * strength, 0.35, BRIGHT, 0.2, 0.5, 1)
				send("Beat", { Strength = strength })
				shake(frame.Position, 0.25 + 0.5 * strength, 0.25)
				Audio.Emit(actor, "CataclysmStomp", root)
			end)
			at += interval
			interval = math.max(0.32, interval * 0.8)
		end
	end
	 
	do
		local at = 1.2
		while at < charge + burst * 0.45 do
			cast:Schedule(at, function()
				local a = rng:NextNumber(0, math.pi * 2)
				local spot = floor + flat(a) * rng:NextNumber(6, 26) + UP * 0.2
				FX.ForkedBolt(ctx, cast, spot + UP * 90 + flat(a) * 10, spot, BRIGHT, WHITE, 0.45, 0.25, 3)
				FX.Sparks(ctx, cast, spot, GOLD, WHITE, 10, 8, 26, 0.5)
				FX.Light(ctx, cast, spot + UP * 3, WHITE, 6, 30, 0.2)
			end)
			at += math.max(0.08, 0.6 * (1 - at / (charge + burst)))
		end
	end
	cast:Schedule(charge * 0.35, function() pose("Rise", 0.8) end)
	cast:Schedule(charge * 0.78, function() pose("Clench", 0.5) end)

	 
	local cocoon, cocoonCore, gyros
	cast:Schedule(charge, function()
		pose("Scream", 0.12)
		send("Burst", { Duration = burst })
		Audio.Emit(actor, "RoyalFinalCharge", root)
		shake(frame.Position, 1, burst * 0.5)
		local center = frame.Position + UP * lift
		cocoon = temp("Phase5Cocoon", CFrame.new(center), Vector3.one * 3, GOLD, 0.6, Enum.PartType.Ball)
		cocoonCore = temp("Phase5CocoonCore", CFrame.new(center), Vector3.one * 2, WHITE, 0.3, Enum.PartType.Ball)
		FX.Tween(cocoon, burst * 0.45, { Size = Vector3.one * 13, Transparency = 0.12 })
		FX.Tween(cocoonCore, burst * 0.45, { Size = Vector3.one * 10.5, Transparency = 0 })
		gyros = {}
		for i = 1, 3 do
			local anchor, set = Golden.BeamRing(ctx, cast, "Phase5Gyro", center, 8 + i, i == 2 and WHITE or GOLD, 0.2, 48)
			gyros[i] = { Anchor = anchor, Set = set, Axis = CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), rng:NextNumber(0, 3)) }
		end
		local start = cast:Now()
		cast:Step(function(_, now)
			if shattered then return false end
			local t = now - start
			for i, g in ipairs(gyros) do
				g.Anchor.CFrame = CFrame.new(center) * g.Axis * CFrame.Angles(t * (5 + i * 2), t * 3, 0)
				g.Set(8 + i - t * 3, 0.1, 0.9)
			end
			local w = 2.6 + 12 * math.clamp(t / (burst * 0.4), 0, 1)
			pillar.Size = Vector3.new(pillarHeight, w, w)
			pillar.Transparency = 0.1
			pillarGlow.Size = Vector3.new(pillarHeight, w * 2.2, w * 2.2)
			pillarGlow.Transparency = 0.6
			inward.Rate = 400
			 
			for _, rock in ipairs(rocks) do
				local p = rock.Part.Position
				rock.Part.CFrame = CFrame.new(p:Lerp(center, math.clamp(t * 0.9, 0, 0.5) * 0.08)) * rock.Spin
			end
			return true
		end)
	end)
	 
	cast:Schedule(charge + burst * 0.4, function()
		api.ApplyForm(actor)
		if highlight.Parent then highlight.FillTransparency, highlight.OutlineTransparency = 0.2, 0 end
	end)

	 
	cast:Schedule(charge + burst * 0.48, function()
		shattered = true
		local center = frame.Position + UP * lift
		pose("Ascendant", 0.08)
		send("Shatter", {})
		Audio.Emit(actor, "CataclysmSlam", root)
		Audio.Emit(actor, "RoyalFinalImpact", root)
		shake(frame.Position, 1.8, 1.1)
		if timeline.OnReveal then task.spawn(timeline.OnReveal) end
		 
		for _, p in ipairs({ cocoon, cocoonCore }) do if p then FX.Release(cast, p) end end
		for _, g in ipairs(gyros or {}) do FX.Release(cast, g.Anchor) end
		local shards = {}
		for i = 1, 30 do
			local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.4, 1), rng:NextNumber(-1, 1)).Unit
			local size = Vector3.new(rng:NextNumber(0.15, 0.4), rng:NextNumber(0.8, 2.6), rng:NextNumber(1, 3))
			local s = temp("Phase5Shard", CFrame.new(center + dir * 4), size, i % 3 == 0 and WHITE or GOLD, 0, Enum.PartType.Wedge)
			shards[i] = { Part = s, Velocity = dir * rng:NextNumber(40, 90), Spin = Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(-8, 8), rng:NextNumber(-8, 8)) }
			FX.Tween(s, 1.3, { Transparency = 1, Size = size * 0.3 })
		end
		local start = cast:Now()
		local last = start
		cast:Step(function(_, now)
			local dt = math.clamp(now - last, 0, 0.1)
			last = now
			for _, s in ipairs(shards) do
				if s.Part.Parent then
					s.Velocity = s.Velocity * math.exp(-2.2 * dt) - UP * 30 * dt
					s.Part.CFrame = (s.Part.CFrame + s.Velocity * dt) * CFrame.Angles(s.Spin.X * dt, s.Spin.Y * dt, s.Spin.Z * dt)
				end
			end
			for _, rock in ipairs(rocks) do
				if rock.Part.Parent then
					if not rock.Velocity then
						local away = rock.Part.Position - center
						away = away.Magnitude > 0.1 and away.Unit or flat(rock.Angle)
						rock.Velocity = (away + UP * 0.4).Unit * rng:NextNumber(60, 110)
						FX.Tween(rock.Part, 1.2, { Transparency = 1 })
					end
					rock.Velocity = rock.Velocity * math.exp(-1.4 * dt) - UP * 40 * dt
					rock.Part.CFrame = (rock.Part.CFrame + rock.Velocity * dt) * CFrame.Angles(dt * 4, dt * 3, 0)
				end
			end
			if now - start > 1.4 then
				for _, s in ipairs(shards) do FX.Release(cast, s.Part) end
				for _, rock in ipairs(rocks) do FX.Release(cast, rock.Part) end
				return false
			end
			return true
		end)
		 
		FX.Flash(ctx, cast, center, WHITE, 90, 0.6, 0)
		FX.Flash(ctx, cast, center, GOLD, 150, 1, 0.35)
		FX.Shockwave(ctx, cast, CFrame.new(floor + UP * 0.25), 6, 150, 1.1, GOLD, 0.1, 3)
		FX.Shockwave(ctx, cast, CFrame.new(floor + UP * 0.3), 4, 95, 0.8, WHITE, 0.05, 2)
		FX.Shockwave(ctx, cast, CFrame.new(floor + UP * 0.35), 2, 50, 0.55, BRIGHT, 0, 1.4)
		FX.Ring(ctx, cast, CFrame.new(center), 4, 110, 0.9, BRIGHT, 0, 3, 1)
		FX.Ring(ctx, cast, CFrame.new(center) * CFrame.Angles(math.pi / 2, 0, 0), 4, 140, 1, GOLD, 0, 3.4, 1)
		FX.Ring(ctx, cast, CFrame.new(center) * CFrame.Angles(0.6, 0.8, 0), 3, 80, 0.7, WHITE, 0, 2, 1)
		FX.Streaks(ctx, cast, center, nil, GOLD, WHITE, 90, 180, 90, 190, 6)
		FX.Sparks(ctx, cast, center, GOLD, WHITE, 140, 30, 110, 1.4)
		FX.Light(ctx, cast, center, WHITE, 16, 320, 1.4)
		pcall(FX.Smoke, ctx, cast, floor + UP, ROCK, 10, 24, 50, 6)
		 
		for _, ring in ipairs(rings) do ring.Set(ring.Radius * 1.4, 0, ring.Width * 3) end
		cast:Schedule(0.12, function() for _, ring in ipairs(rings) do FX.Release(cast, ring.Anchor) end end)
		for _, spoke in ipairs(spokes) do spoke.Color = WHITE FX.Tween(spoke, 0.7, { Transparency = 1 }) end
		for _, crack in ipairs(cracks) do
			for _, seg in ipairs(crack.Segments) do seg.Color = WHITE FX.Tween(seg, 1.4, { Transparency = 1 }) end
		end
		inward.Enabled = false
		FX.Tween(pillar, 0.5, { Size = Vector3.new(pillarHeight, 0.05, 0.05), Transparency = 1 })
		FX.Tween(pillarGlow, 0.5, { Size = Vector3.new(pillarHeight, 0.1, 0.1), Transparency = 1 })
		FX.Tween(light, 1.2, { Brightness = 0 })
		if highlight.Parent then FX.Tween(highlight, 1.2, { FillTransparency = 1, OutlineTransparency = 1 }) end
	end)

	 
	cast:Schedule(charge + burst + 0.6 + math.max(0.5, reveal - 1.2), function()
		send("Land", {})
		FX.Shockwave(ctx, cast, CFrame.new(floor + UP * 0.2), 2, 26, 0.5, GOLD, 0.2, 0.8)
		pcall(FX.Smoke, ctx, cast, floor + UP * 0.5, ROCK, 5, 10, 20, 2)
		Audio.Emit(actor, "CataclysmStomp", root)
		shake(frame.Position, 0.5, 0.3)
	end)
end

return api
