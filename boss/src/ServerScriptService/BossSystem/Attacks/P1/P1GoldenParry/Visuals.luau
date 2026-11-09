local Visuals = {}
function Visuals.disc(ctx)
	local core = ctx.core
	local Effects = ctx.Effects
	local Debris = ctx.Debris
	local function disc(position, startDiameter, endDiameter, duration, color, startAlpha)
		local d = core.Part(
			"GoldenParryDisc",
			CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2),
			Vector3.new(0.2, startDiameter, startDiameter),
			color,
			startAlpha or 0.4
		)
		d.Shape = Enum.PartType.Cylinder
		d.Material = Enum.Material.Neon
		Effects:Create(
			d,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.2, endDiameter, endDiameter), Transparency = 1 }
		):Play()
		Debris:AddItem(d, duration + 0.05)
	end
	return disc
end
function Visuals.glowBall(ctx)
	local core = ctx.core
	local BRIGHT = ctx.BRIGHT
	local Effects = ctx.Effects
	local Debris = ctx.Debris
	local function glowBall(position, size, duration, color)
		local f =
			core.Part("GoldenParryGlowBall", CFrame.new(position), Vector3.one * size * 0.25, color or BRIGHT, 0.1)
		f.Shape = Enum.PartType.Ball
		f.Material = Enum.Material.Neon
		Effects:Create(
			f,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.one * size, Transparency = 1 }
		):Play()
		Debris:AddItem(f, duration + 0.05)
	end
	return glowBall
end
function Visuals.sparkBurst(ctx)
	local core = ctx.core
	local GOLD = ctx.GOLD
	local BRIGHT = ctx.BRIGHT
	local Debris = ctx.Debris
	local function sparkBurst(position, count, minSpeed, maxSpeed)
		local anchor = core.Part("GoldenParrySparkBurst", CFrame.new(position), Vector3.new(1, 0.2, 1), GOLD, 1)
		local e = Instance.new("ParticleEmitter")
		e.Name = "GoldenParrySparks"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(BRIGHT, GOLD)
		e.LightEmission = 1
		e.Rate = 0
		e.SpreadAngle = Vector2.new(180, 180)
		e.Lifetime = NumberRange.new(0.3, 0.7)
		e.Speed = NumberRange.new(minSpeed, maxSpeed)
		e.Drag = 4
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
		e.Parent = anchor
		e:Emit(count)
		Debris:AddItem(anchor, 1)
	end
	return sparkBurst
end
function Visuals.radial(ctx)
	local rng = ctx.rng
	local core = ctx.core
	local GOLD = ctx.GOLD
	local BRIGHT = ctx.BRIGHT
	local function radial(center, axisA, axisB, count, inner, outer, width, fade)
		for i = 1, count do
			local angle = i / count * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
			local d = axisA * math.cos(angle) + axisB * math.sin(angle)
			core.MotionLine(
				"GoldenParryRay",
				center + d * inner,
				center + d * outer * rng:NextNumber(0.7, 1.1),
				width,
				i % 2 == 0 and GOLD or BRIGHT,
				fade
			)
		end
	end
	return radial
end
function Visuals.slashLine(ctx)
	local core = ctx.core
	local DEEP = ctx.DEEP
	local GOLD = ctx.GOLD
	local BRIGHT = ctx.BRIGHT
	local function slashLine(from, to, scale)
		core.MotionLine("GoldenParrySlashGlow", from, to, 3.2 * scale, DEEP, 0.35)
		core.MotionLine("GoldenParrySlash", from, to, 1.4 * scale, GOLD, 0.4)
		core.MotionLine("GoldenParrySlashCore", from, to, 0.4 * scale, BRIGHT, 0.4)
	end
	return slashLine
end
function Visuals.slashVfx(ctx)
	local root = ctx.root
	local slashLine = ctx.slashLine
	local glowBall = ctx.glowBall
	local BRIGHT = ctx.BRIGHT
	local sparkBurst = ctx.sparkBurst
	local victimFloor = ctx.victimFloor
	local disc = ctx.disc
	local GOLD = ctx.GOLD
	local radial = ctx.radial
	local core = ctx.core
	local Effects = ctx.Effects
	local Debris = ctx.Debris
	local function slashVfx(index, center)
		local right = root.CFrame.RightVector
		local up = Vector3.yAxis
		local mid = center + Vector3.new(0, 0.5, 0)
		if index == 1 then
			slashLine(mid - right * 5 + up * 4.5, mid + right * 5 - up * 3, 1)
		elseif index == 2 then
			slashLine(mid + right * 5 + up * 4.5, mid - right * 5 - up * 3, 1)
		else
			slashLine(mid + up * 8, mid - up * 5, 1.3)
			slashLine(mid - right * 7, mid + right * 7, 1.1)
		end
		local finisher = index == 3
		glowBall(mid, finisher and 12 or 7, 0.22, BRIGHT)
		sparkBurst(mid, finisher and 28 or 14, 8, finisher and 28 or 20)
		if finisher then
			local floor = victimFloor()
			disc(floor, 4, 40, 0.5, GOLD, 0.3)
			disc(floor, 2, 24, 0.35, BRIGHT, 0.2)
			radial(floor + Vector3.new(0, 0.2, 0), Vector3.xAxis, Vector3.zAxis, 20, 3, 24, 0.25, 0.35)
			local pillar = core.Part(
				"GoldenParryPillar",
				CFrame.new(center + Vector3.new(0, 10, 0)),
				Vector3.new(3, 24, 3),
				BRIGHT,
				0.2
			)
			pillar.Material = Enum.Material.Neon
			Effects:Create(
				pillar,
				TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					CFrame = CFrame.new(center + Vector3.new(0, 18, 0)),
					Size = Vector3.new(1, 40, 1),
					Transparency = 1,
				}
			):Play()
			Debris:AddItem(pillar, 0.4)
			core.ScreenEffect("Shake", { Origin = center, Radius = 80, Duration = 0.35, Intensity = 0.5 })
		end
	end
	return slashVfx
end
return table.freeze(Visuals)
