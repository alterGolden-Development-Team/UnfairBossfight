 
local Visuals = {}
function Visuals.fireworkBurst(ctx)
	local core = ctx.core
	local sparkle = ctx.sparkle
	local NSK = ctx.NSK
	local WHITE = ctx.WHITE
	local Effects = ctx.Effects
	local function fireworkBurst(position, colors, count, speed, life, size)
		local p = core.Part("EtherealFireworkBurst", CFrame.new(position), Vector3.one * 0.2, colors[1], 1)
		local main = sparkle(
			p,
			count * 10,
			NumberRange.new(life * 0.7, life),
			NumberRange.new(speed * 0.55, speed),
			size,
			ColorSequence.new(colors[1], colors[2])
		)
		main.SpreadAngle = Vector2.new(180, 180)
		main.Drag = 2.4
		main.Acceleration = Vector3.new(0, -16, 0)
		main.Transparency = NumberSequence.new({ NSK(0, 0), NSK(0.6, 0.1), NSK(1, 1) })
		local crackle = sparkle(
			p,
			count * 8,
			NumberRange.new(0.35, 0.6),
			NumberRange.new(speed * 0.2, speed * 0.45),
			size * 0.55,
			ColorSequence.new(WHITE, colors[2])
		)
		crackle.SpreadAngle = Vector2.new(180, 180)
		crackle.Drag = 3
		crackle.Acceleration = Vector3.new(0, -10, 0)
		crackle.Enabled = false
		task.delay(0.1, function()
			if main.Parent then
				main.Enabled = false
			end
		end)
		task.delay(life * 0.55, function()
			if not crackle.Parent then
				return
			end
			crackle.Enabled = true
			task.delay(0.1, function()
				if crackle.Parent then
					crackle.Enabled = false
				end
			end)
		end)
		Effects.ReleaseAfter(p, life * 0.55 + 1)
		return p
	end
	return fireworkBurst
end
function Visuals.fireworkShell(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local NSK = ctx.NSK
	local sparkle = ctx.sparkle
	local WHITE = ctx.WHITE
	local Effects = ctx.Effects
	local ring = ctx.ring
	local dome = ctx.dome
	local fireworkBurst = ctx.fireworkBurst
	local sfx = ctx.sfx
	local CUE = ctx.CUE
	local function fireworkShell(origin, apex, colors, delay, flight)
		task.delay(delay, function()
			if not cast:Alive() then
				return
			end
			local comet =
				core.Part("EtherealFireworkShell", CFrame.new(origin), Vector3.one * 0.9, colors[2], 0)
			comet.Shape = Enum.PartType.Ball
			comet.Material = Enum.Material.Neon
			comet.CastShadow = false
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.Position = Vector3.new(0, 0.45, 0)
			a1.Position = Vector3.new(0, -0.45, 0)
			a0.Parent = comet
			a1.Parent = comet
			local tr = Instance.new("Trail")
			tr.Attachment0 = a0
			tr.Attachment1 = a1
			tr.Lifetime = 0.3
			tr.LightEmission = 1
			tr.FaceCamera = true
			tr.Color = ColorSequence.new(colors[2], colors[1])
			tr.Transparency = NumberSequence.new({ NSK(0, 0), NSK(1, 1) })
			tr.WidthScale = NumberSequence.new({ NSK(0, 1.5), NSK(1, 0) })
			tr.Parent = comet
			sparkle(
				comet,
				40,
				NumberRange.new(0.25, 0.4),
				NumberRange.new(0, 2),
				1,
				ColorSequence.new(colors[1], WHITE)
			)
			Effects:Create(
				comet,
				TweenInfo.new(flight, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = CFrame.new(apex) }
			):Play()
			Effects.ReleaseAfter(comet, flight + 0.05)
			task.delay(flight, function()
				if not cast:Alive() then
					return
				end
				ring(apex, colors[1], 2, 24, 0.55, 0.3, true)
				dome(apex, colors[2], 1, 12, 0.3, true)
				fireworkBurst(apex, colors, 64, 36, 1.4, 1.7)
				sfx(CUE.Firework, apex, 0.6)
			end)
		end)
	end
	return fireworkShell
end
function Visuals.firework(ctx)
	local FIREWORK_COLORS = ctx.FIREWORK_COLORS
	local fireworkBurst = ctx.fireworkBurst
	local ring = ctx.ring
	local random = ctx.random
	local fireworkShell = ctx.fireworkShell
	local function firework(position, index)
		local base = FIREWORK_COLORS[index % #FIREWORK_COLORS + 1]
		fireworkBurst(position, base, 70, 42, 1.1, 1.8)  
		ring(position, base[1], 2, 20, 0.4, 0.3)
		for shell = 1, 3 do  
			local colors = FIREWORK_COLORS[(index + shell * 2) % #FIREWORK_COLORS + 1]
			local angle = random:NextNumber(0, math.pi * 2)
			local spread = random:NextNumber(0.35, 1)
			local direction = Vector3.new(
				math.cos(angle) * spread,
				random:NextNumber(0.9, 1.4),
				math.sin(angle) * spread
			).Unit
			fireworkShell(
				position,
				position + direction * random:NextNumber(12, 20),
				colors,
				(shell - 1) * 0.14,
				0.38
			)
		end
	end
	return firework
end
function Visuals.cardImpact(ctx)
	local WHITE = ctx.WHITE
	local GOLD = ctx.GOLD
	local cast = ctx.cast
	local core = ctx.core
	local Effects = ctx.Effects
	local burst = ctx.burst
	local Audio = ctx.Audio
	local actor = ctx.actor
	local firework = ctx.firework
	local function cardImpact(position, index)
		local tint = index % 2 == 0 and WHITE or GOLD
		local flash =
			cast:Add(core.Part("EtherealCardHitBurst", CFrame.new(position), Vector3.one * 1.2, tint, 0.45))
		flash.Shape = Enum.PartType.Ball
		Effects:Create(flash, TweenInfo.new(0.32), { Size = Vector3.one * 6, Transparency = 1 }):Play()
		burst(position, 18, ColorSequence.new(GOLD, WHITE), 16, 0.45, 0.7)
		Effects.ReleaseAfter(flash, 0.5)
		Audio.Emit(actor, "CardBurst", position, { VolumeScale = 0.65 })
		firework(position, index)
	end
	return cardImpact
end
return table.freeze(Visuals)
