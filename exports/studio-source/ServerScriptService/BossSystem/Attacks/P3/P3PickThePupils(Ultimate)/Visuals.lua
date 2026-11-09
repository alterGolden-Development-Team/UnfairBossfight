 
local TweenService = game:GetService("TweenService")
local Style = require(script.Parent.Style)
local GOLD = Style.GOLD
local WHITE = Style.WHITE
local NEON_SOFTEN = Style.NEON_SOFTEN
local SPARKLE = Style.SPARKLE
local CONFETTI = Style.CONFETTI
local kp = NumberSequenceKeypoint.new
return function(context)
	local folder, cast = context.Folder, context.Cast
	local timeScale, valid, cue = context.TimeScale, context.Valid, context.Cue
	local function part(parent, name, size, cf, color, material, transparency, shape)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame = name, size, cf
		p.Color, p.Material = color or GOLD, material or Enum.Material.Metal
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		transparency = transparency or 0
		if p.Material == Enum.Material.Neon and transparency > 0 and transparency < 1 then
			transparency += (1 - transparency) * NEON_SOFTEN
		end
		p.Transparency = transparency
		if shape then
			p.Shape = shape
		end
		p.Parent = parent
		return p
	end
	local function cylinder(parent, name, diameter, height, cf, color, material, alpha)
		return part(
			parent,
			name,
			Vector3.new(height, diameter, diameter),
			cf * CFrame.Angles(0, 0, math.pi / 2),
			color,
			material,
			alpha,
			Enum.PartType.Cylinder
		)
	end
	local function label(parent, text, color, height)
		local gui = Instance.new("BillboardGui")
		gui.Size, gui.StudsOffset = UDim2.fromOffset(160, 55), Vector3.new(0, height or 2.5, 0)
		gui.AlwaysOnTop, gui.MaxDistance = false, 230
		gui.Parent = parent
		local t = Instance.new("TextLabel")
		t.Size, t.BackgroundTransparency = UDim2.fromScale(1, 1), 1
		t.Font, t.Text, t.TextSize = Enum.Font.GothamBold, text, 28
		t.TextColor3, t.TextStrokeTransparency = color or WHITE, 0.4
		t.Parent = gui
		return t
	end

	 
	local function burst(at, color, scale)
		scale = scale or 1
		local host = part(folder, "RevealSparkles", Vector3.one, CFrame.new(at), color, nil, 1)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = SPARKLE
		emitter.Color, emitter.LightEmission = ColorSequence.new(color, WHITE), 1
		emitter.Rate, emitter.Lifetime, emitter.Speed =
			180 * scale, NumberRange.new(0.5, 1.1), NumberRange.new(12 * scale, 30 * scale)
		emitter.SpreadAngle, emitter.Size = Vector2.new(180, 180), NumberSequence.new({ kp(0, 1), kp(1, 0) })
		emitter.Parent = host
		task.delay(0.18, function()
			if emitter.Parent then
				emitter.Enabled = false
			end
		end)
		task.delay(1.5, function()
			host:Destroy()
		end)
	end
	local function ring(cf, diameter, color, seconds, thickness, startDiameter)
		thickness = thickness or 0.3
		local p =
			cylinder(folder, "Shockwave", startDiameter or 2, thickness, cf, color, Enum.Material.Neon, 0.1)
		TweenService:Create(
			p,
			TweenInfo.new(seconds * timeScale, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(thickness, diameter, diameter), Transparency = 1 }
		):Play()
		task.delay(seconds * timeScale + 0.1, function()
			p:Destroy()
		end)
	end
	local function pillar(at, color, height, seconds)
		local p = cylinder(
			folder,
			"LightPillar",
			8,
			height,
			CFrame.new(at + Vector3.new(0, height / 2, 0)),
			color,
			Enum.Material.Neon,
			0.55
		)
		TweenService:Create(
			p,
			TweenInfo.new(seconds * timeScale, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(height, 0.5, 0.5), Transparency = 1 }
		):Play()
		task.delay(seconds * timeScale + 0.1, function()
			p:Destroy()
		end)
	end
	local function fireworks(at)
		for index = 1, 5 do
			cast:Schedule((index - 1) * 0.18, function()
				if not valid() then return end
				local color = CONFETTI[index % #CONFETTI + 1]
				local origin = at + Vector3.new((index - 3) * 4, 2, 0)
				local apex = origin + Vector3.new((index - 3) * 5, 28 + index % 2 * 10, -4)
				local rocket = part(folder, "CupVictoryFirework", Vector3.one * 0.7, CFrame.new(origin), color, Enum.Material.Neon, 0, Enum.PartType.Ball)
				local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
				a0.Position, a1.Position = Vector3.new(0, 0.3, 0), Vector3.new(0, -0.3, 0)
				a0.Parent, a1.Parent = rocket, rocket
				local trail = Instance.new("Trail")
				trail.Attachment0, trail.Attachment1 = a0, a1
				trail.Color, trail.Lifetime, trail.LightEmission = ColorSequence.new(color, WHITE), 0.35, 1
				trail.Parent = rocket
				TweenService:Create(rocket, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = apex }):Play()
				cast:Schedule(0.6, function()
					if not valid() then return end
					rocket.Transparency = 1
					local emitter = Instance.new("ParticleEmitter")
					emitter.Texture, emitter.Rate = SPARKLE, 0
					emitter.Color, emitter.LightEmission = ColorSequence.new(color, WHITE), 1
					emitter.Lifetime, emitter.Speed = NumberRange.new(0.8, 1.4), NumberRange.new(18, 38)
					emitter.SpreadAngle, emitter.Drag = Vector2.new(180, 180), 2
					emitter.Acceleration = Vector3.new(0, -18, 0)
					emitter.Size = NumberSequence.new({ kp(0, 1.2), kp(1, 0) })
					emitter.Parent = rocket
					emitter:Emit(70)
					cue("CardBurst", apex, 0.6)
					task.delay(1.6, function() rocket:Destroy() end)
				end)
			end)
		end
	end

	local function confetti(at, count, spread, speed)
		local host = part(folder, "Confetti", Vector3.one, CFrame.new(at), WHITE, nil, 1)
		for _, color in ipairs(CONFETTI) do
			local e = Instance.new("ParticleEmitter")
			e.Texture = SPARKLE
			e.Color = ColorSequence.new(color)
			e.LightEmission = 0.6
			e.Enabled = false
			e.Lifetime = NumberRange.new(1.6, 3)
			e.Speed = NumberRange.new(speed * 0.5, speed)
			e.SpreadAngle = Vector2.new(spread, spread)
			e.Acceleration = Vector3.new(0, -45, 0)
			e.Rotation, e.RotSpeed = NumberRange.new(0, 360), NumberRange.new(-360, 360)
			e.Size = NumberSequence.new({ kp(0, 0.9), kp(0.8, 0.9), kp(1, 0) })
			e.Parent = host
			e:Emit(math.floor(count / #CONFETTI))
		end
		task.delay(3.4, function()
			host:Destroy()
		end)
	end

	return { Part = part, Cylinder = cylinder, Label = label, Burst = burst,
		Ring = ring, Pillar = pillar, Fireworks = fireworks, Confetti = confetti }
end
