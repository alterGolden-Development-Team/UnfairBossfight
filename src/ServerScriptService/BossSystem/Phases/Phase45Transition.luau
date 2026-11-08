 
 
local BossSystem = script:FindFirstAncestor("BossSystem")
local Effects = require(BossSystem.Combat.EffectService)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Players = game:GetService("Players")

local CRIMSON = Color3.fromRGB(196, 18, 48)
local ROSE = Color3.fromRGB(255, 86, 120)
local BLUSH = Color3.fromRGB(255, 214, 226)
local GOLD = Color3.fromRGB(255, 205, 70)
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local api = {}

local function seq(...)
	local v = { ... }
	local k = {}
	for i, x in ipairs(v) do
		k[i] = NumberSequenceKeypoint.new((i - 1) / (#v - 1), x)
	end
	return NumberSequence.new(k)
end
local function grad(...)
	local v = { ... }
	local k = {}
	for i, x in ipairs(v) do
		k[i] = ColorSequenceKeypoint.new((i - 1) / (#v - 1), x)
	end
	return ColorSequence.new(k)
end

local function part(cast, name, frame, size, color, alpha, shape)
	local p = Effects.AcquirePart()
	p.Name, p.CFrame, p.Size, p.Color, p.Transparency = name, frame, size, color, alpha or 0
	if shape then
		p.Shape = shape
	end
	p:SetAttribute("TimeStopExempt", true)
	p.Parent = Runtime.Effects
	return cast:Add(p)
end
local function tween(object, time, goal, style)
	local t = Effects:Create(object, TweenInfo.new(time, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end
local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture, e.LightEmission, e.LightInfluence, e.Rate = SPARK, 1, 0, 0
	for k, v in pairs(props) do
		e[k] = v
	end
	e.Parent = parent
	return e
end
local function screen(kind, data)
	local remote = game.ReplicatedStorage:FindFirstChild("BossCombatEffects")
	if not remote then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		remote:FireClient(player, kind, data)
	end
end

function api.Play(actor, cast, duration)
	local root = actor:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local center = root.Position
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { actor, Runtime.Effects }
	local hit = workspace:Raycast(center, Vector3.new(0, -30, 0), params)
	local floor = hit and hit.Position + Vector3.new(0, 0.1, 0) or center - Vector3.new(0, 3, 0)
	local bloomAt = duration * 0.72

	 
	local sigilR = 16
	local edges = {}
	for i = 1, 10 do
		edges[i] = part(cast, "Phase45Sigil", CFrame.new(floor), Vector3.new(0.5, 0.08, 0.1), i <= 5 and CRIMSON or ROSE, 1)
	end
	local ring = part(cast, "Phase45SigilRing", CFrame.new(floor) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(0.06, sigilR * 2.3, sigilR * 2.3), CRIMSON, 1, Enum.PartType.Cylinder)
	tween(ring, 0.6, { Transparency = 0.55 })
	local born = cast:Now()
	local function corner(i, spin, r)
		local a = spin + (i - 1) / 5 * math.pi * 2 - math.pi / 2
		return floor + Vector3.new(math.cos(a) * r, 0.05, math.sin(a) * r)
	end

	 
	local gather = part(cast, "Phase45Gather", CFrame.new(center), Vector3.one * 26, CRIMSON, 1)
	local inward = emitter(gather, {
		Color = grad(BLUSH, ROSE, CRIMSON),
		Size = seq(0.9, 0.5),
		Transparency = seq(1, 0.1, 0),
		Lifetime = NumberRange.new(0.7),
		Speed = NumberRange.new(-28),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-260, 260),
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		Rate = 90,
	})
	local core = part(cast, "Phase45Core", CFrame.new(center), Vector3.one * 0.5, ROSE, 0.1, Enum.PartType.Ball)
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows = CRIMSON, 40, 0, false
	light.Parent = core

	cast:Step(function(_, now)
		local t = now - born
		local k = math.clamp(t / bloomAt, 0, 1)
		local spin = t * 0.6
		for i = 1, 5 do
			 
			local reveal = math.clamp(k * 5 - (i - 1), 0, 1)
			local a, b = corner(i, spin, sigilR), corner(i % 5 + 1, spin, sigilR)
			local tip = a:Lerp(b, reveal)
			local e = edges[i]
			if reveal > 0.01 then
				e.CFrame = CFrame.lookAt((a + tip) / 2, tip)
				e.Size = Vector3.new(0.55, 0.08, (tip - a).Magnitude)
				e.Transparency = 0.05
			end
			 
			local sa, sb = corner(i, -spin * 1.4, sigilR * 0.92), corner((i + 1) % 5 + 1, -spin * 1.4, sigilR * 0.92)
			local st = sa:Lerp(sb, math.clamp(k * 5 - (i - 1) - 0.5, 0, 1))
			local s = edges[i + 5]
			if (st - sa).Magnitude > 0.05 then
				s.CFrame = CFrame.lookAt((sa + st) / 2, st)
				s.Size = Vector3.new(0.3, 0.08, (st - sa).Magnitude)
				s.Transparency = 0.25
			end
		end
		local pulse = 1 + 0.12 * math.sin(t * 24)
		core.CFrame = CFrame.new(center)
		core.Size = Vector3.one * (0.5 + 5 * k ^ 1.5) * pulse
		light.Brightness = 1 + 5 * k
		inward.Rate = 60 + 160 * k
		return t < bloomAt
	end)

	 
	cast:Schedule(bloomAt, function()
		inward.Enabled = false
		tween(core, 0.18, { Size = Vector3.one * 22, Transparency = 1 })
		tween(light, 0.6, { Brightness = 0 })
		local flash = part(cast, "Phase45Flash", CFrame.new(center), Vector3.one * 4, BLUSH, 0, Enum.PartType.Ball)
		tween(flash, 0.25, { Size = Vector3.one * 34, Transparency = 1 })
		 
		for i = 1, 5 do
			local a = (i - 1) / 5 * math.pi * 2
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local base = CFrame.lookAt(center, center + dir) * CFrame.Angles(math.rad(70), 0, 0)
			local petal = part(cast, "Phase45Petal", base * CFrame.new(0, 0, -2), Vector3.new(3, 0.4, 5), ROSE, 0.1, Enum.PartType.Ball)
			local open = CFrame.lookAt(center, center + dir) * CFrame.Angles(math.rad(-8), 0, 0) * CFrame.new(0, 0, -11)
			tween(petal, 0.35, { CFrame = open, Size = Vector3.new(9, 0.6, 16) }, Enum.EasingStyle.Back)
			cast:Schedule(0.45, function()
				if petal.Parent then
					tween(petal, 0.5, { Transparency = 1, Size = Vector3.new(11, 0.2, 20) })
				end
			end)
		end
		 
		for i, spec in ipairs({ { 2, 90, 0.7, CRIMSON }, { 2, 60, 0.5, BLUSH }, { 1, 30, 0.35, GOLD } }) do
			local wave = part(cast, "Phase45Shockwave", CFrame.new(floor + Vector3.new(0, 0.1 * i, 0)) * CFrame.Angles(0, 0, math.pi / 2),
				Vector3.new(0.2, spec[1], spec[1]), spec[4], 0.15, Enum.PartType.Cylinder)
			tween(wave, spec[3], { Size = Vector3.new(0.05, spec[2], spec[2]), Transparency = 1 })
		end
		 
		local burst = part(cast, "Phase45Burst", CFrame.new(center), Vector3.one * 0.2, ROSE, 1)
		emitter(burst, {
			Color = grad(BLUSH, ROSE, CRIMSON),
			Size = seq(1.2, 0.8, 0),
			Transparency = seq(0, 0.2, 1),
			Lifetime = NumberRange.new(1, 1.8),
			Speed = NumberRange.new(30, 70),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, -6, 0),
			Drag = 2,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-300, 300),
		}):Emit(160)
		emitter(burst, {
			Texture = SMOKE,
			LightEmission = 0.3,
			Color = grad(ROSE, CRIMSON),
			Size = seq(6, 18),
			Transparency = seq(0.5, 1),
			Lifetime = NumberRange.new(0.8, 1.3),
			Speed = NumberRange.new(20, 40),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 3,
			Rotation = NumberRange.new(0, 360),
		}):Emit(18)
		for _, e in ipairs(edges) do
			tween(e, 0.8, { Transparency = 1 })
		end
		tween(ring, 0.8, { Transparency = 1, Size = Vector3.new(0.06, sigilR * 3, sigilR * 3) })
		screen("Shake", { Origin = center, Radius = 260, Duration = 0.8, Intensity = 1.1 })
		screen("ImpactTint", { Origin = center, Radius = 260, Color = CRIMSON, Intensity = 1, Duration = 0.6 })
	end)
end

return api
