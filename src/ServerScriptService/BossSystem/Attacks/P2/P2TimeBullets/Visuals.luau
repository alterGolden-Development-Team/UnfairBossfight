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
function Visuals.groundUnder(ctx)
	local core = ctx.core
	local function groundUnder(root)
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -60, 0), core.Params())
		return (hit and hit.Position or root.Position - Vector3.new(0, 3, 0)) + Vector3.new(0, 0.12, 0)
	end
	return groundUnder
end
function Visuals.startSigil(ctx)
	local core = ctx.core
	local groundUnder = ctx.groundUnder
	local Config = ctx.Config
	local Effects = ctx.Effects
	local actor = ctx.actor
	local solid = ctx.solid
	local TIME = ctx.TIME
	local GOLD = ctx.GOLD
	local WHITE = ctx.WHITE
	local Debris = ctx.Debris
	local TAU = ctx.TAU
	local function startSigil(chargeTime)
		local root = core.Root
		local origin = groundUnder(root)
		local radius = Config.TimeBulletSigilRadius or 11
		local cast = Effects.NewCast(actor, "P2TimeBulletsSigil", chargeTime + 1.6)
		local parts = {}
		local function add(p)
			table.insert(parts, p)
			return p
		end
		local outer = add(solid(cast, "TimeSigilOuter", Enum.PartType.Cylinder, Vector3.new(0.12, 1, 1), TIME, 0.25))
		local inner = add(solid(cast, "TimeSigilInner", Enum.PartType.Cylinder, Vector3.new(0.12, 1, 1), GOLD, 0.4))
		local ticks = {}
		for i = 1, 12 do
			local major = i % 3 == 0
			ticks[i] = add(
				solid(
					cast,
					"TimeSigilTick",
					Enum.PartType.Block,
					Vector3.new(major and 0.42 or 0.26, 0.12, major and 1.7 or 0.95),
					major and WHITE or TIME,
					0.15
				)
			)
		end
		local hourHand = add(solid(cast, "TimeSigilHour", Enum.PartType.Block, Vector3.new(0.45, 0.14, 1), GOLD, 0.1))
		local minuteHand =
			add(solid(cast, "TimeSigilMinute", Enum.PartType.Block, Vector3.new(0.3, 0.14, 1), WHITE, 0.1))
		 
		local motes = solid(cast, "TimeSigilMotes", Enum.PartType.Ball, Vector3.one * radius * 0.9, TIME, 1)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "TimeConverge"
		emitter.Shape = Enum.ParticleEmitterShape.Sphere
		emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
		emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		emitter.Rate = 70
		emitter.Lifetime = NumberRange.new(0.45, 0.7)
		emitter.Speed = NumberRange.new(7, 11)
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.3, 0.4),
			NumberSequenceKeypoint.new(1, 0),
		})
		emitter.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		emitter.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, GOLD),
			ColorSequenceKeypoint.new(0.5, TIME),
			ColorSequenceKeypoint.new(1, WHITE),
		})
		emitter.LightEmission = 1
		emitter.RotSpeed = NumberRange.new(-200, 200)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.Parent = motes
		Debris:AddItem(emitter, chargeTime + 2)
	
		local base = CFrame.new(origin)
		local flat = CFrame.Angles(0, 0, math.pi / 2)  
		local function layout(progress, time)
			local scale = math.max(0.05, progress)
			local spin = -time * 1.6
			outer.Size = Vector3.new(0.12, radius * 2 * scale, radius * 2 * scale)
			outer.CFrame = base * flat
			inner.Size = Vector3.new(0.12, radius * 1.35 * 2 * scale, radius * 1.35 * 2 * scale)
			inner.CFrame = base * flat
			for i, tick in ipairs(ticks) do
				local a = (i - 1) / 12 * TAU + spin
				tick.CFrame = base * CFrame.Angles(0, -a, 0) * CFrame.new(0, 0.04, -radius * 0.82 * scale)
			end
			local hourLength, minuteLength = radius * 0.5 * scale, radius * 0.8 * scale
			hourHand.Size = Vector3.new(0.45, 0.14, hourLength)
			hourHand.CFrame = base
				* CFrame.new(0, 0.08, 0)
				* CFrame.Angles(0, -time * 1.1, 0)
				* CFrame.new(0, 0, -hourLength / 2)
			minuteHand.Size = Vector3.new(0.3, 0.14, minuteLength)
			minuteHand.CFrame = base
				* CFrame.new(0, 0.1, 0)
				* CFrame.Angles(0, -time * 6.5, 0)
				* CFrame.new(0, 0, -minuteLength / 2)
			motes.CFrame = CFrame.new(root.Position)
		end
		layout(0.05, 0)
	
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
			local p = math.clamp(elapsed / chargeTime, 0, 1)
			layout(1 - (1 - p) ^ 3, elapsed)
			return true
		end)
	
		local handle = {}
		function handle.Release(flare)
			if released then
				return
			end
			released = true
			emitter.Enabled = false
			local fade = flare and 0.4 or 0.2
			if flare then
				local ring = solid(
					cast,
					"TimeSigilShock",
					Enum.PartType.Cylinder,
					Vector3.new(0.14, radius * 1.6, radius * 1.6),
					WHITE,
					0.1
				)
				ring.CFrame = base * flat
				Effects:Create(
					ring,
					TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Size = Vector3.new(0.14, radius * 3.6, radius * 3.6), Transparency = 1 }
				):Play()
				for _, p in ipairs(parts) do
					p.Color = WHITE
				end
			end
			for _, p in ipairs(parts) do
				Effects:Create(p, TweenInfo.new(fade), { Transparency = 1 }):Play()
			end
			cast:Schedule(fade + 0.1, function()
				cast:Dispose()
			end)
		end
		return handle
	end
	return startSigil
end
return table.freeze(Visuals)
