local Visuals = {}
function Visuals.embers(ctx)
	local gold = ctx.gold
	local function embers(parent, rate)
		local e = Instance.new("ParticleEmitter")
		e.Name = "SplitGoldenEmbers"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(255, 255, 182), gold)
		e.LightEmission = 1
		e.Lifetime = NumberRange.new(0.35, 0.85)
		e.Speed = NumberRange.new(4, 9)
		e.Acceleration = Vector3.new(0, 2, 0)
		e.Drag = 3
		e.SpreadAngle = Vector2.new(35, 35)
		e.EmissionDirection = Enum.NormalId.Top
		e.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(0.3, 0.4),
			NumberSequenceKeypoint.new(1, 0),
		})
		e.Rate = rate
		e.Parent = parent
		return e
	end
	return embers
end
function Visuals.disc(ctx)
	local core = ctx.core
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local function disc(position, startDiameter, endDiameter, duration, color, startAlpha)
		local d = core.Part(
			"GoldenSplitShockDisc",
			CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2),
			Vector3.new(0.25, startDiameter, startDiameter),
			color,
			startAlpha or 0.4
		)
		d.Shape = Enum.PartType.Cylinder
		d.Material = Enum.Material.Neon
		Tween:Create(
			d,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.25, endDiameter, endDiameter), Transparency = 1 }
		):Play()
		Debris:AddItem(d, duration + 0.05)
	end
	return disc
end
function Visuals.flash(ctx)
	local core = ctx.core
	local bright = ctx.bright
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local function flash(position, size, duration, color)
		local f = core.Part(
			"GoldenSplitFlash",
			CFrame.new(position),
			Vector3.new(size * 0.25, size * 0.25, size * 0.25),
			color or bright,
			0.1
		)
		f.Shape = Enum.PartType.Ball
		f.Material = Enum.Material.Neon
		Tween:Create(
			f,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(size, size, size), Transparency = 1 }
		):Play()
		Debris:AddItem(f, duration + 0.05)
	end
	return flash
end
function Visuals.bolt(ctx)
	local rng = ctx.rng
	local core = ctx.core
	local bright = ctx.bright
	local gold = ctx.gold
	local function bolt(from, to, spread, width, segmentCount, fade)
		local dir = to - from
		local len = dir.Magnitude
		if len < 1 then
			return
		end
		local unit = dir / len
		local side = unit:Cross(Vector3.yAxis)
		side = side.Magnitude > 0.01 and side.Unit or Vector3.xAxis
		local up = side:Cross(unit)
		local segments = segmentCount or math.clamp(math.floor(len / 2.5), 2, 6)
		local prev = from
		for i = 1, segments do
			local point = from + dir * (i / segments)
			if i < segments then
				point += side * rng:NextNumber(-spread, spread) + up * rng:NextNumber(-spread, spread) * 0.4
			end
			core.MotionLine("GoldenSplitCrack", prev, point, width or 0.18, i % 2 == 0 and bright or gold, fade or 0.3)
			prev = point
		end
	end
	return bolt
end
function Visuals.fountain(ctx)
	local core = ctx.core
	local gold = ctx.gold
	local bright = ctx.bright
	local Debris = ctx.Debris
	local function fountain(position, count)
		local anchor = core.Part("GoldenSplitEmberBurst", CFrame.new(position), Vector3.new(1, 0.2, 1), gold, 1)
		local e = Instance.new("ParticleEmitter")
		e.Name = "GoldenSplitFountain"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(bright, gold)
		e.LightEmission = 1
		e.Rate = 0
		e.EmissionDirection = Enum.NormalId.Top
		e.SpreadAngle = Vector2.new(30, 30)
		e.Lifetime = NumberRange.new(0.6, 1.2)
		e.Speed = NumberRange.new(14, 28)
		e.Acceleration = Vector3.new(0, -28, 0)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0) })
		e.Parent = anchor
		e:Emit(count)
		Debris:AddItem(anchor, 1.5)
	end
	return fountain
end
function Visuals.TrailEffects(ctx)
	local core = ctx.core
	local Tween = ctx.Tween
	local gold = ctx.gold
	local embers = ctx.embers
	local bright = ctx.bright
	local deepGold = ctx.deepGold
	local Debris = ctx.Debris
	local function TrailEffects(lane, drop, lifetime)
		local model = Instance.new("Model")
		model.Name = "GoldenSplitLingeringEffects"
		model.Parent = core.Effects
		local pulses = {}
		local function pulse(part, info, properties)
			local tween = Tween:Create(part, info, properties)
			table.insert(pulses, tween)
			tween:Play()
		end
		local function piece(name, cf, size, color, alpha)
			local p = core.Part(name, cf, size, color, alpha)
			p.Material = Enum.Material.Neon
			p.Parent = model
			return p
		end
		local center = lane.frame * CFrame.new(0, -drop + 0.12, -lane.length * 0.5)
		local vein =
			piece("SplitPulsingCore", center, Vector3.new(0.65, 0.15, lane.length), Color3.fromRGB(255, 255, 150), 0.12)
		pulse(
			vein,
			TweenInfo.new(0.42, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Transparency = 0.7 }
		)
		for _, side in ipairs({ -1, 1 }) do
			local edge = piece(
				"SplitGlowingEdge",
				center * CFrame.new(side * (lane.width * 0.5 - 0.15), 0, 0),
				Vector3.new(0.25, 0.12, lane.length),
				gold,
				0.22
			)
			pulse(
				edge,
				TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Transparency = 0.75 }
			)
		end
		 
		for i = 1, 3 do
			local dash = piece(
				"SplitFlowPulse",
				center * CFrame.new(0, 0.08, lane.length * 0.5 - 3),
				Vector3.new(0.9, 0.14, 5),
				Color3.fromRGB(255, 255, 200),
				0.1
			)
			local duration = math.clamp(lane.length / 45, 0.8, 2.2) * (0.85 + i * 0.15)
			pulse(
				dash,
				TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false),
				{ CFrame = center * CFrame.new(0, 0.08, -lane.length * 0.5 + 3) }
			)
		end
		local count = math.clamp(math.ceil(lane.length / 40), 2, 8)
		for i = 1, count do
			local t = (i - 0.5) / count
			local cf = lane.frame * CFrame.new(math.sin(i * 2.1) * lane.width * 0.28, -drop + 0.25, -t * lane.length)
			local anchor = piece("SplitEmberVent", cf, Vector3.new(2, 0.15, 3), gold, 1)
			embers(anchor, 7):Emit(12)
			 
			local flame = Instance.new("ParticleEmitter")
			flame.Name = "SplitVentFlame"
			flame.Texture = "rbxasset://textures/particles/fire_main.dds"
			flame.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, bright),
				ColorSequenceKeypoint.new(0.5, gold),
				ColorSequenceKeypoint.new(1, deepGold),
			})
			flame.LightEmission = 1
			flame.EmissionDirection = Enum.NormalId.Top
			flame.SpreadAngle = Vector2.new(6, 6)
			flame.Lifetime = NumberRange.new(0.5, 0.9)
			flame.Speed = NumberRange.new(2, 5)
			flame.Rate = 8
			flame.Acceleration = Vector3.new(0, 5, 0)
			flame.Rotation = NumberRange.new(0, 360)
			flame.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1.2),
				NumberSequenceKeypoint.new(0.4, 2.6),
				NumberSequenceKeypoint.new(1, 0),
			})
			flame.Transparency =
				NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
			flame.Parent = anchor
			local fissure = piece(
				"SplitJaggedVein",
				cf * CFrame.Angles(0, math.rad(35 * math.sin(i)), 0),
				Vector3.new(0.16, 0.12, 6),
				Color3.fromRGB(255, 249, 115),
				0.3
			)
			pulse(
				fissure,
				TweenInfo.new(0.5 + 0.07 * i, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Transparency = 0.8 }
			)
			if i % 3 == 1 then
				local light = Instance.new("PointLight")
				light.Color = gold
				light.Brightness = 0.6
				light.Range = 10
				light.Parent = anchor
			end
		end
		for i = 1, 3 do
			local ripple =
				core.Part("SplitImpactPressure", center, Vector3.new(lane.width, 0.08, lane.length), gold, 0.6)
			ripple.Material = Enum.Material.Neon
			Tween:Create(
				ripple,
				TweenInfo.new(0.25 + i * 0.1),
				{ Size = Vector3.new(lane.width * (1 + i * 0.35), 0.08, lane.length), Transparency = 1 }
			):Play()
			Debris:AddItem(ripple, 0.3 + i * 0.1)
		end
		core.KeepFor(model, lifetime + 1.1, pulses)
		return model, pulses
	end
	return TrailEffects
end
function Visuals.Warning(ctx)
	local h = ctx.h
	local root = ctx.root
	local core = ctx.core
	local gold = ctx.gold
	local Tween = ctx.Tween
	local function Warning(lane, groundY)
		local drop = groundY and lane.frame.Position.Y - groundY - 0.12 or h.HipHeight + root.Size.Y * 0.5 - 0.12
		local band = core.Part(
			"GoldenSplitWarningBand",
			lane.frame * CFrame.new(0, -drop, -lane.length * 0.5),
			Vector3.new(lane.width, 0.1, lane.length),
			gold,
			0.85
		)
		band.Material = Enum.Material.Neon
		local line = core.Part(
			"GoldenSplitWarningLine",
			band.CFrame + Vector3.new(0, 0.08, 0),
			Vector3.new(0.55, 0.16, lane.length),
			gold,
			0.05
		)
		line.Material = Enum.Material.Neon
		Tween:Create(
			line,
			TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Transparency = 0.55 }
		):Play()
		return band, line
	end
	return Warning
end
function Visuals.startChargeVfx(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local root = ctx.root
	local h = ctx.h
	local core = ctx.core
	local gold = ctx.gold
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local embers = ctx.embers
	local rng = ctx.rng
	local bright = ctx.bright
	local disc = ctx.disc
	local function startChargeVfx(blade, chargeTime)
		local cast = Effects.NewCast(actor, "GoldenSplitChargeVfx", chargeTime + 1)
		local feet = root.Position - Vector3.new(0, h.HipHeight + root.Size.Y * 0.5 - 0.15, 0)
		local hub = cast:Add(
			core.Part(
				"GoldenSplitHub",
				CFrame.new(feet) * CFrame.Angles(0, 0, math.pi / 2),
				Vector3.new(0.2, 7, 7),
				gold,
				0.5
			)
		)
		hub.Shape = Enum.PartType.Cylinder
		hub.Material = Enum.Material.Neon
		Tween:Create(
			hub,
			TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Transparency = 0.85, Size = Vector3.new(0.2, 10, 10) }
		):Play()
		local light = Instance.new("PointLight")
		light.Color = gold
		light.Brightness = 0
		light.Range = 8
		light.Parent = blade
		Tween:Create(
			light,
			TweenInfo.new(chargeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Brightness = 5, Range = 26 }
		):Play()
		Debris:AddItem(light, chargeTime + 0.6)
		local glow = embers(blade, 30)
		glow.SpreadAngle = Vector2.new(180, 180)
		glow.Speed = NumberRange.new(2, 6)
		Debris:AddItem(glow, chargeTime + 0.2)
		local elapsed, streakTimer, ringTimer = 0, 0, 0
		cast:Step(function(dt)
			if not root.Parent or not blade.Parent then
				return false
			end
			elapsed += dt
			local progress = math.clamp(elapsed / chargeTime, 0, 1)
			streakTimer += dt
			if streakTimer >= 0.06 then
				streakTimer = 0
				local center = blade.Position
				for _ = 1, 1 + math.floor(progress * 3) do
					local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.3, 1), rng:NextNumber(-1, 1))
					dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.yAxis
					local radius = rng:NextNumber(9, 16) * (1 - progress * 0.35)
					core.MotionLine(
						"GoldenSplitChargeStreak",
						center + dir * radius,
						center + dir * radius * 0.25,
						0.1 + progress * 0.1,
						rng:NextNumber() > 0.5 and gold or bright,
						0.18
					)
				end
			end
			ringTimer += dt
			if ringTimer >= 0.35 - 0.15 * progress then
				ringTimer = 0
				disc(feet, 26 - 6 * progress, 3, 0.4, gold, 0.6)
			end
			return true
		end)
		return cast
	end
	return startChargeVfx
end
return table.freeze(Visuals)
