 
local TweenService = game:GetService("TweenService")
local Style = require(script.Parent.Style)
local DARK = Style.DARK
local GOLD = Style.GOLD
local PALE = Style.PALE
local WHITE = Style.WHITE
local SPARKLE = Style.SPARKLE
local NEON_SOFTEN = Style.NEON_SOFTEN
local PULSE_SLOW = Style.PULSE_SLOW
local kp = NumberSequenceKeypoint.new
local STEEL = Color3.fromRGB(52, 46, 74)
return function(context)
	local timeScale = context.TimeScale
	local part, cylinder = context.Visuals.Part, context.Visuals.Cylinder
	local function pulse(object, property, from, to, seconds, phase)
		if property == "Transparency" then
			from += (1 - from) * NEON_SOFTEN
			to += (1 - to) * NEON_SOFTEN
		end
		object[property] = from
		local tween = TweenService:Create(
			object,
			TweenInfo.new(seconds * PULSE_SLOW, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ [property] = to }
		)
		object.Destroying:Connect(function()
			tween:Cancel()
		end)
		task.delay(phase or 0, function()
			if object.Parent then
				tween:Play()
			end
		end)
		return tween
	end
	 
	local CUP_H, CUP_Y0, CUP_R0, CUP_R1, CUP_BANDS = 12.5, 0.3, 6.2, 4.1, 32
	local CUP_YELLOW = Color3.fromRGB(245, 199, 35)
	local CUP_YELLOW_LIGHT = Color3.fromRGB(255, 231, 102)
	local CUP_YELLOW_DARK = Color3.fromRGB(185, 137, 17)
	 
	local function cupRadius(h)
		return CUP_R0 + (CUP_R1 - CUP_R0) * h
	end

	local function makeCup(roundFolder, index, cf)
		local m = Instance.new("Model")
		m.Name = "GoldenCup" .. index  
		m.Parent = roundFolder
		local pivot = part(m, "CupPivot", Vector3.one, CFrame.identity, CUP_YELLOW, nil, 1)
		m.PrimaryPart = pivot
		local plastic = Enum.Material.SmoothPlastic
		local topY = CUP_Y0 + CUP_H
		local step = CUP_H / CUP_BANDS

		 
		for band = 1, CUP_BANDS do
			local h = (band - 0.5) / CUP_BANDS
			cylinder(
				m,
				"Shell",
				cupRadius(h) * 2,
				step * 1.08,
				CFrame.new(0, CUP_Y0 + (band - 0.5) * step, 0),
				CUP_YELLOW,
				plastic
			)
		end

		 
		cylinder(m, "Mouth", CUP_R0 * 2 - 0.4, 0.1, CFrame.new(0, CUP_Y0 - 0.03, 0), DARK, plastic)

		 
		cylinder(m, "RolledLip", CUP_R0 * 2 + 0.9, 0.5, CFrame.new(0, CUP_Y0 + 0.25, 0), CUP_YELLOW_LIGHT, plastic)
		cylinder(m, "RolledLipTop", CUP_R0 * 2 + 0.4, 0.3, CFrame.new(0, CUP_Y0 + 0.62, 0), CUP_YELLOW_LIGHT, plastic)

		 
		for _, h in ipairs({ 0.34, 0.46, 0.58 }) do
			cylinder(m, "Ridge", cupRadius(h) * 2 + 0.7, 0.3, CFrame.new(0, CUP_Y0 + h * CUP_H, 0), CUP_YELLOW, plastic)
		end

		 
		cylinder(m, "BaseRing", CUP_R1 * 2 + 0.6, 0.4, CFrame.new(0, topY - 0.05, 0), CUP_YELLOW_LIGHT, plastic)
		cylinder(m, "BaseInset", CUP_R1 * 2 - 1.0, 0.12, CFrame.new(0, topY + 0.2, 0), CUP_YELLOW_DARK, plastic)

		 
		local side = Vector3.new(0.35, 0, 1).Unit
		local g0 = side * (cupRadius(0.12) + 0.08) + Vector3.new(0, CUP_Y0 + 0.12 * CUP_H, 0)
		local g1 = side * (cupRadius(0.86) + 0.08) + Vector3.new(0, CUP_Y0 + 0.86 * CUP_H, 0)
		local gMid = (g0 + g1) / 2
		part(
			m,
			"Gloss",
			Vector3.new(0.6, 0.06, (g1 - g0).Magnitude),
			CFrame.lookAt(gMid, gMid + (g1 - g0).Unit, side),
			WHITE,
			plastic,
			0.6
		)

		 
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 1, 0)
		a0.Parent = pivot
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, topY, 0)
		a1.Parent = pivot
		local trail = Instance.new("Trail")
		trail.Attachment0, trail.Attachment1 = a0, a1
		trail.Lifetime, trail.MinLength = 0.5, 0.05
		trail.LightEmission, trail.FaceCamera = 0.6, true
		trail.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, WHITE),
			ColorSequenceKeypoint.new(0.4, PALE),
			ColorSequenceKeypoint.new(1, GOLD),
		})
		trail.Transparency = NumberSequence.new({ kp(0, 0.3), kp(1, 1) })
		trail.Enabled = false
		trail.Parent = pivot

		m:PivotTo(cf)
		return { Model = m, Frame = cf, Slot = index, Trail = trail }
	end

	 
	 
	local function spotlight(roundFolder, cup)
		local base = cup.Frame * CFrame.new(0, 43, 0)
		local fixture = Instance.new("Model")
		fixture.Name = "GameshowSpotlight"
		fixture.Parent = roundFolder
		local lamp = part(fixture, "Lamp", Vector3.new(4.2, 0.5, 4.2), base, DARK, Enum.Material.Metal)
		fixture.PrimaryPart = lamp
		cylinder(fixture, "Housing", 3.8, 3.2, base * CFrame.new(0, 1.85, 0), STEEL, Enum.Material.Metal)
		cylinder(fixture, "RearCap", 4.3, 0.5, base * CFrame.new(0, 3.6, 0), DARK, Enum.Material.Metal)
		local lens = cylinder(
			fixture,
			"Lens",
			3.4,
			0.12,
			base * CFrame.new(0, -0.32, 0),
			WHITE,
			Enum.Material.Neon,
			0.05
		)
		pulse(lens, "Transparency", 0, 0.35, 0.8)
		for i = 0, 3 do
			part(
				fixture,
				"BarnDoor",
				Vector3.new(4.2, 0.12, 1.5),
				base
					* CFrame.Angles(0, i * math.pi / 2, 0)
					* CFrame.new(0, -0.3, 2.4)
					* CFrame.Angles(0.5, 0, 0),
				STEEL
			)
		end
		for _, x in ipairs({ -2.5, 2.5 }) do
			part(fixture, "Yoke", Vector3.new(0.4, 3.4, 0.4), base * CFrame.new(x, 1.6, 0), STEEL)
		end
		part(fixture, "YokeBar", Vector3.new(5.4, 0.4, 0.4), base * CFrame.new(0, 3.4, 0), STEEL)
		cylinder(fixture, "Stem", 1.0, 5, base * CFrame.new(0, 5.9, 0), STEEL, Enum.Material.Metal)

		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Bottom
		light.Angle = 29
		light.Range = 60
		light.Brightness = 6
		light.Color = WHITE
		light.Shadows = true
		light.Parent = lamp

		local dust = Instance.new("ParticleEmitter")
		dust.Name = "BeamDust"
		dust.Texture = SPARKLE
		dust.Color = ColorSequence.new(WHITE)
		dust.LightEmission = 1
		dust.EmissionDirection = Enum.NormalId.Bottom
		dust.Rate = 5
		dust.Lifetime = NumberRange.new(1.5, 2.5)
		dust.Speed = NumberRange.new(4, 9)
		dust.SpreadAngle = Vector2.new(14, 14)
		dust.Size = NumberSequence.new({ kp(0, 0.5), kp(1, 0) })
		dust.Transparency = NumberSequence.new({ kp(0, 0.3), kp(1, 1) })
		dust.Parent = lamp

		local top = Instance.new("Attachment")
		top.Position = Vector3.new(0, -0.35, 0)
		top.Parent = lamp
		local bottom = Instance.new("Attachment")
		bottom.Position = Vector3.new(0, 0.3, 0)
		bottom.Parent = cup.Model.PrimaryPart
		local function shaft(name, w0, w1, transparency, color)
			local b = Instance.new("Beam")
			b.Name = name
			b.Attachment0, b.Attachment1 = top, bottom
			b.Width0, b.Width1 = w0, w1
			b.FaceCamera, b.LightEmission = true, 1
			b.Color = ColorSequence.new(color)
			b.Transparency = NumberSequence.new(transparency)
			b.Parent = lamp
			return b
		end
		local beam = shaft("GameshowLightShaft", 1.2, 17, 0.93, PALE)
		shaft("GameshowLightCore", 0.5, 7, 0.9, WHITE)
		pulse(beam, "Width1", 15, 19, 1.4)

		 
		local pool = Instance.new("Model")
		pool.Name = "SpotPoolModel"
		pool.Parent = roundFolder
		local poolCF = cup.Frame * CFrame.new(0, 0.06, 0)
		local outer = cylinder(pool, "SpotPool", 23, 0.05, poolCF, PALE, Enum.Material.Neon, 0.9)
		pool.PrimaryPart = outer
		cylinder(
			pool,
			"SpotPoolMid",
			16,
			0.05,
			poolCF * CFrame.new(0, 0.02, 0),
			PALE,
			Enum.Material.Neon,
			0.8
		)
		local core = cylinder(
			pool,
			"SpotPoolCore",
			9,
			0.05,
			poolCF * CFrame.new(0, 0.04, 0),
			WHITE,
			Enum.Material.Neon,
			0.62
		)
		pulse(core, "Transparency", 0.5, 0.78, 1.2)

		return { Lamp = fixture, Light = light, Beam = beam, Pool = pool }
	end
	 
	local function ghost(roundFolder, cf, color)
		local m = Instance.new("Model")
		m.Name = "CupAfterImage"
		m.Parent = roundFolder
		local info = TweenInfo.new(0.45 * timeScale)
		for n = 1, 4 do
			local h = (n - 0.5) / 4
			local p = cylinder(
				m,
				"Echo",
				cupRadius(h) * 2,
				CUP_H / 4 * 1.1,
				cf * CFrame.new(0, CUP_Y0 + (n - 0.5) * CUP_H / 4, 0),
				color,
				Enum.Material.Neon,
				0.72
			)
			TweenService:Create(p, info, { Transparency = 1 }):Play()
		end
		task.delay(0.5 * timeScale, function()
			m:Destroy()
		end)
	end
	return { Cup = makeCup, Spotlight = spotlight, Ghost = ghost }
end
