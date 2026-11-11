local BossSystem = script:FindFirstAncestor("BossSystem")
local Effects = require(BossSystem.Combat.EffectService)
local GOLD = Color3.fromRGB(255, 194, 44)
local WHITE = Color3.fromRGB(255, 250, 222)
local AMBER = Color3.fromRGB(239, 119, 24)
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local key = NumberSequenceKeypoint.new
local api = {}

function api.Explode(core, cast, point, radius)
	local random = Random.new()
	local center = point + Vector3.new(0, radius * 0.35, 0)
	local scale = radius / 30
	local function part(name, cf, size, color, transparency, lifetime)
		local object = cast:Add(core.Part(name, cf, size, color, transparency))
		Effects.ReleaseAfter(object, lifetime)
		return object
	end
	local function tween(object, seconds, properties)
		Effects:Create(object, TweenInfo.new(seconds, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), properties)
			:Play()
	end
	local function shell(name, color, diameter, alpha, duration)
		local ball = part(name, CFrame.new(center), Vector3.one * 3, color, alpha, duration + 0.1)
		ball.Shape = Enum.PartType.Ball
		tween(ball, duration, { Size = Vector3.one * diameter, Transparency = 1 })
		return ball
	end
	local function shockRing(frame, reach, color, duration, width)
		local segments = 32
		for i = 1, segments do
			local angle = i * math.pi * 2 / segments
			local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local tangent = Vector3.new(-direction.Z, 0, direction.X)
			local function pose(distance)
				local position = direction * distance
				return frame * CFrame.lookAt(position, position + tangent)
			end
			local segment =
				part("ProjectileShockRing", pose(3), Vector3.new(width, width, 0.65), color, 0.12, duration + 0.1)
			tween(
				segment,
				duration,
				{
					CFrame = pose(reach),
					Size = Vector3.new(width * 0.22, width * 0.22, reach * math.pi * 2 / segments * 1.06),
					Transparency = 1,
				}
			)
		end
	end

	shell("ProjectileBlastCore", WHITE, radius * 0.85, 0.04, 0.24)
	local blast = shell("ProjectileMirrorImpact", GOLD, radius * 2, 0.68, 0.55)
	blast:SetAttribute("ImpactRadius", radius)
	shockRing(CFrame.new(point + Vector3.new(0, 0.7, 0)), radius * 1.4, GOLD, 0.7, 0.85 * scale)
	cast:Schedule(0.1, function()
		shockRing(CFrame.new(center) * CFrame.Angles(math.rad(32), 0, 0), radius * 1.15, WHITE, 0.6, 0.5 * scale)
	end)

	for i = 1, 20 do
		local angle = i * math.pi * 2 / 20 + random:NextNumber(-0.08, 0.08)
		local direction = Vector3.new(math.cos(angle), random:NextNumber(0.2, 1.2), math.sin(angle)).Unit
		local length = random:NextNumber(3, 7) * scale
		local shard = part(
			"ProjectileMirrorShard",
			CFrame.lookAt(center + direction * 2, center + direction * 3),
			Vector3.new(0.4, 1.2, length) * scale,
			i % 3 == 0 and WHITE or GOLD,
			0.08,
			1.15
		)
		local a, b = Instance.new("Attachment"), Instance.new("Attachment")
		a.Position, b.Position = Vector3.new(-0.3, 0, 0), Vector3.new(0.3, 0, 0)
		a.Parent, b.Parent = shard, shard
		local trail = Instance.new("Trail")
		trail.Attachment0, trail.Attachment1 = a, b
		trail.Color = ColorSequence.new(WHITE, AMBER)
		trail.Lifetime, trail.LightEmission = 0.2, 1
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.WidthScale = NumberSequence.new(1, 0)
		trail.Parent = shard
		local destination = center + direction * radius * random:NextNumber(0.9, 1.6)
		tween(
			shard,
			random:NextNumber(0.7, 1),
			{
				CFrame = CFrame.lookAt(destination, destination + direction) * CFrame.Angles(0.5, 0.7, angle),
				Size = Vector3.new(0.04, 0.12, length * 0.3),
				Transparency = 1,
			}
		)
	end

	local anchor = part("ProjectileImpactEmitter", CFrame.new(center), Vector3.one * 0.5, GOLD, 1, 2.4)
	local light = Instance.new("PointLight")
	light.Color, light.Brightness, light.Range = GOLD, 8, math.min(radius * 2.5, 60)
	light.Parent = anchor
	tween(light, 0.65, { Brightness = 0, Range = 0 })
	local function emitter(name, texture, lifetime, speed, colors, sizes)
		local particles = Instance.new("ParticleEmitter")
		particles.Name, particles.Texture = name, texture
		particles.Rate, particles.SpreadAngle = 0, Vector2.new(180, 180)
		particles.Lifetime, particles.Speed = lifetime, speed
		particles.Color, particles.Size = colors, sizes
		particles.LightEmission, particles.Drag = 0.8, 3
		particles.Transparency = NumberSequence.new({ key(0, 0), key(0.65, 0.25), key(1, 1) })
		particles.Parent = anchor
		return particles
	end
	local sparks = emitter(
		"ImpactGoldenBurst",
		SPARKLE,
		NumberRange.new(0.3, 0.9),
		NumberRange.new(35, 75),
		ColorSequence.new(WHITE, GOLD),
		NumberSequence.new(1.2 * scale, 0)
	)
	sparks.Acceleration = Vector3.new(0, -22, 0)
	sparks:Emit(56)
	local embers = emitter(
		"ImpactEmbers",
		SPARKLE,
		NumberRange.new(1, 2),
		NumberRange.new(8, 24),
		ColorSequence.new(GOLD, AMBER),
		NumberSequence.new(0.65 * scale, 0)
	)
	embers.Acceleration = Vector3.new(0, 9, 0)
	embers:Emit(28)
	local dust = emitter(
		"ImpactSmoke",
		SMOKE,
		NumberRange.new(0.7, 1.5),
		NumberRange.new(12, 32),
		ColorSequence.new(Color3.fromRGB(129, 94, 47), Color3.fromRGB(62, 48, 32)),
		NumberSequence.new({ key(0, 2 * scale), key(0.5, 7 * scale), key(1, 10 * scale) })
	)
	dust.LightEmission = 0
	dust.SpreadAngle = Vector2.new(80, 80)
	dust.Transparency = NumberSequence.new({ key(0, 0.8), key(0.3, 0.65), key(1, 1) })
	dust:Emit(14)
end

return api

