local Visuals = {}
function Visuals.solid(ctx)
	local Effects = ctx.Effects
	local Runtime = ctx.Runtime
	local function solid(cast, name, shape, size, color, alpha)
		local p = Effects.AcquirePart()
		p.Name = name
		p.Shape = shape
		p.Material = Enum.Material.Neon
		p.Color = color
		p.Transparency = alpha
		p.Size = size
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Parent = Runtime.Effects
		cast:Add(p)
		return p
	end
	return solid
end
function Visuals.muzzlePoint(ctx)
	local actor = ctx.actor
	local core = ctx.core
	local function muzzlePoint()
		local hand = actor:FindFirstChild("Left Arm")
		return (hand and hand.Position or core.Root.Position + Vector3.new(0, 1, 0)) + core.Root.CFrame.LookVector * 2
	end
	return muzzlePoint
end
function Visuals.startCharge(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local CHARGE = ctx.CHARGE
	local solid = ctx.solid
	local WHITE = ctx.WHITE
	local GOLD = ctx.GOLD
	local Debris = ctx.Debris
	local muzzlePoint = ctx.muzzlePoint
	local core = ctx.core
	local TAU = ctx.TAU
	local ORANGE = ctx.ORANGE
	local function startCharge()
		local cast = Effects.NewCast(actor, "P5GoldenBulletsCharge", CHARGE + 3)
		local orb = solid(cast, "GoldenChargeOrb", Enum.PartType.Ball, Vector3.one * 0.4, WHITE, 0.05)
		local halo = solid(cast, "GoldenChargeHalo", Enum.PartType.Ball, Vector3.one, GOLD, 0.6)
		local ringA = solid(cast, "GoldenChargeRingA", Enum.PartType.Cylinder, Vector3.new(0.08, 6, 6), GOLD, 0.2)
		local ringB = solid(cast, "GoldenChargeRingB", Enum.PartType.Cylinder, Vector3.new(0.06, 4, 4), WHITE, 0.3)
		local orbiters = {}
		for i = 1, 4 do
			orbiters[i] = solid(
				cast,
				"GoldenChargeSpark",
				Enum.PartType.Ball,
				Vector3.one * 0.35,
				i % 2 == 0 and WHITE or GOLD,
				0.1
			)
		end
	
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Range = 10
		light.Brightness = 0
		light.Shadows = false
		light.Parent = orb
		 
		local sand = solid(cast, "GoldenChargeSand", Enum.PartType.Ball, Vector3.one * 5, GOLD, 1)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "GoldenConverge"
		emitter.Shape = Enum.ParticleEmitterShape.Sphere
		emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
		emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		emitter.Rate = 60
		emitter.Lifetime = NumberRange.new(0.25, 0.4)
		emitter.Speed = NumberRange.new(6, 9)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(0.3, 0.3),
			NumberSequenceKeypoint.new(1, 0),
		})
		emitter.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, GOLD),
			ColorSequenceKeypoint.new(0.6, WHITE),
			ColorSequenceKeypoint.new(1, WHITE),
		})
		emitter.LightEmission = 1
		emitter.RotSpeed = NumberRange.new(-200, 200)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.Parent = sand
		Debris:AddItem(emitter, CHARGE + 4)
	
		local allParts = { orb, halo, ringA, ringB, sand, table.unpack(orbiters) }
		local current = muzzlePoint()
		local function layout(progress, time)
			local origin = muzzlePoint()
			current = origin
			local look = core.Root.CFrame.LookVector
			local frame = CFrame.lookAt(origin, origin + look)
			local ease = 1 - (1 - progress) ^ 3
			local axis = frame * CFrame.Angles(0, math.pi / 2, 0)
			orb.Size = Vector3.one * (0.4 + 1.3 * ease)
			orb.CFrame = CFrame.new(origin)
			halo.Size = Vector3.one * (1 + 3.6 * ease)
			halo.CFrame = CFrame.new(origin)
			local dA = 1.6 + (1 - ease) * 6.4
			local dB = 1.1 + (1 - ease) * 4
			ringA.Size = Vector3.new(0.08, dA, dA)
			ringA.CFrame = axis * CFrame.new(0, 0, 0)
			ringB.Size = Vector3.new(0.06, dB, dB)
			ringB.CFrame = frame * CFrame.new(0, 0, -0.5) * CFrame.Angles(0, math.pi / 2, 0)
			local radius = 0.7 + (1 - ease) * 2.8
			for i, spark in ipairs(orbiters) do
				local a = time * (8 + ease * 10) + i * TAU / 4
				spark.CFrame =
					CFrame.new(frame:PointToWorldSpace(Vector3.new(math.cos(a) * radius, math.sin(a) * radius, 0)))
			end
			sand.CFrame = CFrame.new(origin)
			light.Brightness = 0.5 + ease * 2.5
		end
		layout(0, 0)
		local elapsed, accum, released = 0, 0, false
		cast:Step(function(dt)
			if released then
				return false
			end
			if not core.Active() then
				cast:Dispose()
				return false
			end
			elapsed += dt
			accum += dt
			if accum < 0.03 then
				return true
			end
			accum = 0
			layout(math.clamp(elapsed / CHARGE, 0, 1), elapsed)
			return true
		end)
	
		local handle = {}
		function handle.Release(flare)
			if released then
				return
			end
			released = true
			emitter.Enabled = false
			if flare then
				 
				orb.Color = Color3.new(1, 1, 1)
				Effects:Create(
					orb,
					TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Size = Vector3.one * 3.2, Transparency = 1 }
				):Play()
				Effects:Create(halo, TweenInfo.new(0.22), { Size = Vector3.one * 7, Transparency = 1 }):Play()
				light.Brightness = 5
				local ring =
					solid(cast, "GoldenChargeShock", Enum.PartType.Cylinder, Vector3.new(0.1, 2, 2), ORANGE, 0.1)
				local look = core.Root.CFrame.LookVector
				ring.CFrame = CFrame.lookAt(current, current + look) * CFrame.Angles(0, math.pi / 2, 0)
				Effects:Create(
					ring,
					TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Size = Vector3.new(0.1, 9, 9), Transparency = 1 }
				):Play()
				for _, p in ipairs({ ringA, ringB, table.unpack(orbiters) }) do
					Effects:Create(p, TweenInfo.new(0.15), { Transparency = 1 }):Play()
				end
			else
				for _, p in ipairs(allParts) do
					Effects:Create(p, TweenInfo.new(0.15), { Transparency = 1 }):Play()
				end
			end
			cast:Schedule(0.35, function()
				cast:Dispose()
			end)
		end
		return handle
	end
	return startCharge
end
return table.freeze(Visuals)
