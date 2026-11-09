local Visuals = {}
function Visuals.part(ctx)
	local Effects = ctx.Effects
	local function part(parent, name, cf, size, color, transparency)
		local p = Effects.AcquirePart()
		p.CastShadow = false
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Material = Enum.Material.Neon
		p.Shape = Enum.PartType.Block
		p.Color = color
		p.Transparency = transparency
		p.Size = size
		p.CFrame = cf
		p.Parent = parent
		return p
	end
	return part
end
function Visuals.makeSparks(ctx)
	local function makeSparks(parent, rate)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "GoldenSlashSparks"
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 190), Color3.fromRGB(255, 208, 25))
		emitter.LightEmission = 1
		emitter.Lifetime = NumberRange.new(0.12, 0.3)
		emitter.Speed = NumberRange.new(6, 16)
		emitter.SpreadAngle = Vector2.new(100, 100)
		emitter.Acceleration = Vector3.new(0, -12, 0)
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.28), NumberSequenceKeypoint.new(1, 0) })
		emitter.Rate = rate
		emitter.Enabled = rate > 0
		emitter.Parent = parent
		return emitter
	end
	return makeSparks
end
function Visuals.key(ctx)
	local function key(time, value)
		return NumberSequenceKeypoint.new(time, value)
	end
	return key
end
function Visuals.taper(ctx)
	local function taper(p)
		return math.sin(math.pi * math.clamp(p, 0, 1)) ^ 0.65
	end
	return taper
end
function Visuals.burstSparks(ctx)
	local part = ctx.part
	local effects = ctx.effects
	local GOLD = ctx.GOLD
	local makeSparks = ctx.makeSparks
	local key = ctx.key
	local Debris = ctx.Debris
	local function burstSparks(position, count, speedMin, speedMax)
		local anchor = part(effects, "SlashSparkBurst", CFrame.new(position), Vector3.one * 0.2, GOLD, 1)
		local emitter = makeSparks(anchor, 0)
		emitter.Speed = NumberRange.new(speedMin or 14, speedMax or 32)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Lifetime = NumberRange.new(0.25, 0.55)
		emitter.Size = NumberSequence.new({ key(0, 0.55), key(1, 0) })
		emitter:Emit(count)
		Debris:AddItem(anchor, 0.8)
	end
	return burstSparks
end
function Visuals.flashBall(ctx)
	local part = ctx.part
	local effects = ctx.effects
	local WHITE = ctx.WHITE
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local function flashBall(position, scale, duration, color)
		local ball = part(effects, "SlashFlash", CFrame.new(position), Vector3.one * scale * 0.3, color or WHITE, 0.1)
		ball.Shape = Enum.PartType.Ball
		Tween:Create(
			ball,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.one * scale, Transparency = 1 }
		):Play()
		Debris:AddItem(ball, duration + 0.05)
	end
	return flashBall
end
function Visuals.streakBar(ctx)
	local part = ctx.part
	local effects = ctx.effects
	local WHITE = ctx.WHITE
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local function streakBar(cf, fromSize, toSize, duration, color)
		local bar = part(effects, "SlashStreak", cf, fromSize, color or WHITE, 0)
		Tween:Create(
			bar,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = toSize, Transparency = 1 }
		):Play()
		Debris:AddItem(bar, duration + 0.05)
	end
	return streakBar
end
function Visuals.HitFx(ctx)
	local flashBall = ctx.flashBall
	local WHITE = ctx.WHITE
	local rng = ctx.rng
	local streakBar = ctx.streakBar
	local burstSparks = ctx.burstSparks
	local function HitFx(position)
		flashBall(position, 7, 0.18, WHITE)
		for _ = 1, 2 do
			local orientation =
				CFrame.Angles(rng:NextNumber(0, math.pi), rng:NextNumber(0, math.pi), rng:NextNumber(0, math.pi))
			streakBar(
				CFrame.new(position) * orientation,
				Vector3.new(0.35, 0.35, 3),
				Vector3.new(0.06, 0.06, 9),
				0.16,
				WHITE
			)
		end
		burstSparks(position, 14, 14, 30)
	end
	return HitFx
end
function Visuals.LaunchFx(ctx)
	local flashBall = ctx.flashBall
	local AMBER = ctx.AMBER
	local part = ctx.part
	local effects = ctx.effects
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local burstSparks = ctx.burstSparks
	local function LaunchFx(frame)
		local position = frame.Position
		flashBall(position, 6, 0.15, AMBER)
		local ring = part(
			effects,
			"SlashLaunchRing",
			CFrame.lookAt(position, position + frame.LookVector) * CFrame.Angles(0, math.pi / 2, 0),
			Vector3.new(0.12, 2, 2),
			AMBER,
			0.35
		)
		ring.Shape = Enum.PartType.Cylinder
		Tween:Create(
			ring,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.12, 13, 13), Transparency = 1 }
		):Play()
		Debris:AddItem(ring, 0.25)
		burstSparks(position, 8, 10, 22)
	end
	return LaunchFx
end
function Visuals.EndFx(ctx)
	local flashBall = ctx.flashBall
	local WHITE = ctx.WHITE
	local burstSparks = ctx.burstSparks
	local function EndFx(wave)
		local position = wave.frame.Position
		flashBall(position, 8, 0.2, WHITE)
		burstSparks(position, 18, 14, 34)
	end
	return EndFx
end
function Visuals.CreateWave(ctx)
	local effects = ctx.effects
	local b = ctx.b
	local part = ctx.part
	local GOLD = ctx.GOLD
	local makeSparks = ctx.makeSparks
	local WHITE = ctx.WHITE
	local AMBER = ctx.AMBER
	local key = ctx.key
	local taper = ctx.taper
	local function CreateWave(frame, index)
		local model = Instance.new("Model")
		model.Name = index == 1 and "RangedSlashForwardDiagonal" or "RangedSlashBackDiagonal"
		model.Parent = effects
		local width = b:GetAttribute("RangedSlashWidth") or 24
		local plane = frame * CFrame.Angles(0, 0, math.rad(index == 1 and 45 or -45))
		model.WorldPivot = plane
		 
		local segments = 12
		local function arcLocal(t)
			local s = math.sin(math.pi * t)
			return Vector3.new((t - 0.5) * width, 0.4 * s, 2.6 * (1 - s) ^ 1.1)
		end
		 
		local anchor = part(model, "RangedSlashSparkTrail", plane, Vector3.new(width * 0.7, 0.4, 0.3), GOLD, 1)
		local sparks = makeSparks(anchor, 45)
		sparks.EmissionDirection = Enum.NormalId.Back
		sparks:Emit(16)
		 
		local wind = Instance.new("ParticleEmitter")
		wind.Name = "GoldenSlashWind"
		wind.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		wind.Color = ColorSequence.new(WHITE, AMBER)
		wind.LightEmission = 0.9
		wind.Rate = 40
		wind.Lifetime = NumberRange.new(0.15, 0.28)
		wind.Speed = NumberRange.new(6, 14)
		wind.EmissionDirection = Enum.NormalId.Back
		wind.SpreadAngle = Vector2.new(8, 8)
		wind.Orientation = Enum.ParticleOrientation.VelocityParallel
		wind.Size = NumberSequence.new({ key(0, 2), key(1, 0) })
		wind.Transparency = NumberSequence.new({ key(0, 0.2), key(1, 1) })
		wind.Parent = anchor
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Range = 16
		light.Brightness = 1.5
		light.Shadows = false
		light.Parent = anchor
	
		 
		local function makePoints(offset)
			local list = {}
			for i = 0, segments do
				local t = i / segments
				local a = Instance.new("Attachment")
				a.Position = arcLocal(t) + (offset and offset(t) or Vector3.zero)
				a.Parent = anchor
				list[i + 1] = a
			end
			return list
		end
		local function ribbon(list, name, w, color, alpha, emission)
			for i = 1, segments do
				local beam = Instance.new("Beam")
				beam.Name = name
				beam.Attachment0 = list[i]
				beam.Attachment1 = list[i + 1]
				beam.Width0 = math.max(0.08, w * taper((i - 1) / segments))
				beam.Width1 = math.max(0.08, w * taper(i / segments))
				beam.FaceCamera = true
				beam.Segments = 1
				beam.LightEmission = emission
				beam.Color = ColorSequence.new(color)
				beam.Transparency = NumberSequence.new(alpha)
				beam.Parent = anchor
			end
		end
		local center = makePoints()
		ribbon(center, "SlashGlow", 6, AMBER, 0.6, 0.8)
		ribbon(center, "SlashCore", 0.7, WHITE, 0.03, 1)
		ribbon(
			makePoints(function(t)
				return Vector3.new(0, 0.42 * (0.12 + 2.3 * taper(t)), 0)
			end),
			"SlashEdge",
			0.3,
			WHITE,
			0.05,
			1
		)
		 
		local ghost = Instance.new("Trail")
		ghost.Name = "SlashGhost"
		ghost.Attachment0 = center[1]
		ghost.Attachment1 = center[segments + 1]
		ghost.Lifetime = 0.22
		ghost.LightEmission = 0.85
		ghost.FaceCamera = false
		ghost.MinLength = 0.1
		ghost.Color = ColorSequence.new(AMBER, GOLD)
		ghost.Transparency = NumberSequence.new({ key(0, 0.4), key(1, 1) })
		ghost.Parent = anchor
	
		 
		for i = 0, segments - 1 do
			local p0, p1 = arcLocal(i / segments), arcLocal((i + 1) / segments)
			local mid = (p0 + p1) * 0.5
			local dir = p1 - p0
			local thickness = 0.12 + 2.3 * taper((i + 0.5) / segments)
			part(
				model,
				"GoldenSlash",
				plane * CFrame.lookAt(mid, mid + dir),
				Vector3.new(0.24, thickness, dir.Magnitude + 0.08),
				GOLD,
				0.06
			)
		end
		return {
			model = model,
			frame = plane,
			width = width,
			hit = {},
			traveled = 0,
			range = b:GetAttribute("RangedSlashRange") or 220,
			index = index,
			damage = b:GetAttribute("RangedSlashDamage") or 5,
		}
	end
	return CreateWave
end
function Visuals.SummonLightSword(ctx)
	local b = ctx.b
	local Debris = ctx.Debris
	local function SummonLightSword(lifetime)
		local tool = b["Basic Sword"]
		local hand = b:FindFirstChild("LeftHand") or b:FindFirstChild("Left Arm")
		if not hand then
			return
		end
		local native = b:FindFirstChild("RightGrip", true)
		local mount = native and native.C0 or CFrame.new(0, -0.3, 0)
		local frame = hand.CFrame * mount * tool.Grip:Inverse()
		local model = Instance.new("Model")
		model.Name = "GoldenLightSword"
		model.Parent = b
		local handle
		for _, original in ipairs(tool:GetChildren()) do
			if original:IsA("BasePart") then
				local p = Instance.new("Part")
				p.CastShadow = false
				p.Name = original.Name
				p.Size = original.Size
				p.Material = Enum.Material.Neon
				p.Color = Color3.fromRGB(255, 235, 85)
				p.Transparency = 0.12
				p.CanCollide = false
				p.CanTouch = false
				p.CanQuery = false
				p.Massless = true
				if original:IsA("Part") then
					p.Shape = original.Shape
				end
				p.CFrame = frame * tool.Handle.CFrame:ToObjectSpace(original.CFrame)
				p.Parent = model
				if p.Name == "Handle" then
					handle = p
				end
			end
		end
		if handle then
			for _, p in ipairs(model:GetChildren()) do
				if p:IsA("BasePart") and p ~= handle then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = handle
					weld.Part1 = p
					weld.Parent = p
				end
			end
			local grip = Instance.new("Motor6D")
			grip.Name = "LeftLightSwordGrip"
			grip.Part0 = hand
			grip.Part1 = handle
			grip.C0 = mount
			grip.C1 = tool.Grip
			grip.Parent = handle
		end
		Debris:AddItem(model, lifetime or 1.8)
		b:SetAttribute("LightSwordSummons", (b:GetAttribute("LightSwordSummons") or 0) + 1)
		return model
	end
	return SummonLightSword
end
return table.freeze(Visuals)
