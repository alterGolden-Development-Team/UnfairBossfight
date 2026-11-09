local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Effects = require(script:FindFirstAncestor("BossSystem").Combat.EffectService)

local WHITE = Color3.fromRGB(255, 255, 245)
local PALE = Color3.fromRGB(255, 239, 154)
local SOFT = Color3.fromRGB(255, 214, 90)
local GOLD = Color3.fromRGB(255, 190, 40)
local EMBER = Color3.fromRGB(255, 120, 40)

local FLAT = CFrame.Angles(0, 0, math.pi / 2)  
local CYLINDER, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball

local function info(time, style, dir)
	return TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
end

return function(core, owner)
	local api = {}
	local rng = Random.new()

	 
	 
	 
	local function part(cast, name, cf, size, color, transparency, shape)
		local p = cast:Add(core.Part(name, cf, size, color, transparency))
		p.Material = Enum.Material.Neon
		if shape then p.Shape = shape end
		return p
	end

	local function tween(p, time, goals, style, dir)
		Effects:Create(p, info(time, style, dir), goals):Play()
	end

	local function ball(cast, pos, from, to, time, color, startTransparency)
		local p = part(cast, "PlayerCloneBall", CFrame.new(pos), Vector3.one * from, color, startTransparency, BALL)
		tween(p, time, { Size = Vector3.one * to, Transparency = 1 })
		return p
	end

	 
	local function disc(cast, cf, thickness, from, to, time, color, startTransparency, style)
		local p = part(cast, "PlayerCloneDisc", cf, Vector3.new(thickness, from, from), color, startTransparency, CYLINDER)
		tween(p, time, { Size = Vector3.new(thickness, to, to), Transparency = 1 }, style)
		return p
	end

	local function flash(host, range, brightness, time)
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Range = range
		light.Brightness = brightness
		light.Shadows = false
		light.Parent = host
		TweenService:Create(light, info(time, Enum.EasingStyle.Quad), { Brightness = 0 }):Play()
	end

	local function sparks(cast, pos, count, speed, spread, direction, gravity)
		local host = part(cast, "PlayerCloneSparks", CFrame.new(pos), Vector3.one * 0.4, GOLD, 1)
		local e = Instance.new("ParticleEmitter")
		e.Enabled = false
		e.Rate = 0
		e.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, WHITE),
			ColorSequenceKeypoint.new(0.4, PALE),
			ColorSequenceKeypoint.new(1, GOLD),
		})
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.1), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.7, 0.15),
			NumberSequenceKeypoint.new(1, 1),
		})
		e.Lifetime = NumberRange.new(0.5, 0.9)
		e.Speed = speed
		e.SpreadAngle = Vector2.new(spread, spread)
		e.EmissionDirection = direction
		e.Acceleration = Vector3.new(0, gravity, 0)
		e.Drag = 2
		e.LightEmission = 1
		e.LightInfluence = 0
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-200, 200)
		e.Parent = host
		e:Emit(count)
	end

	 
	 
	 
	function api.Burst(position, radius, name)
		radius = radius or 8
		local cast = Effects.NewCast(owner, name or "PlayerCloneBurst", 1.3)
		local hot = ball(cast, position, 1, radius * 1.1, 0.3, WHITE, 0)  
		flash(hot, radius * 3, 6, 0.5)
		ball(cast, position, 1, radius * 2, 0.55, GOLD, 0.25)  
		disc(cast, CFrame.new(position) * FLAT, 0.4, 2, radius * 3, 0.6, PALE, 0.35)  
		sparks(cast, position, math.clamp(math.floor(radius * 3), 12, 60),
			NumberRange.new(radius * 1.5, radius * 3.5), 180, Enum.NormalId.Top, -30)
	end

	 
	 
	 
	function api.Charge(character, duration)
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return { Stop = function() end } end

		local cast = Effects.NewCast(owner, "PlayerCloneCharge", duration + 1)
		local origin = root.Position
		local stopped = false

		 
		local glow = Instance.new("Highlight")
		glow.Name = "PlayerCloneChargeGlow"
		glow.FillColor = GOLD
		glow.OutlineColor = WHITE
		glow.FillTransparency = 0.85
		glow.OutlineTransparency = 0.2
		glow.DepthMode = Enum.HighlightDepthMode.Occluded
		glow.Parent = character
		TweenService:Create(glow, info(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { FillTransparency = 0.15 }):Play()
		Debris:AddItem(glow, duration + 1)

		 
		local orb = part(cast, "PlayerCloneOrb", CFrame.new(origin), Vector3.one * 2, PALE, 0.65, BALL)
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Range = 26
		light.Brightness = 0
		light.Shadows = false
		light.Parent = orb
		TweenService:Create(light, info(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Brightness = 7 }):Play()

		 
		local platform = part(cast, "PlayerCloneChargeRing", CFrame.new(origin) * FLAT,
			Vector3.new(0.25, 18, 18), GOLD, 0.55, CYLINDER)

		 
		local pull = part(cast, "PlayerClonePull", CFrame.new(origin), Vector3.one * 18, GOLD, 1, BALL)
		local e = Instance.new("ParticleEmitter")
		e.Rate = 90
		e.Shape = Enum.ParticleEmitterShape.Sphere
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
		e.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
		e.Speed = NumberRange.new(14, 18)
		e.Lifetime = NumberRange.new(0.45, 0.5)
		e.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, PALE), ColorSequenceKeypoint.new(1, WHITE) })
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0.1) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		e.LightEmission = 1
		e.LightInfluence = 0
		e.Parent = pull

		local function stop()
			if stopped then return end
			stopped = true
			glow:Destroy()
			if not cast.closed then cast:Dispose() end
		end

		local started = cast:Now()
		local acc = 0
		cast:Step(function(dt)
			if stopped then return false end
			acc += dt
			if acc < 0.03 then return true end
			acc = 0
			if not root.Parent then stop(); return false end
			local t = cast:Now() - started
			local k = math.clamp(t / duration, 0, 1)
			local pos = root.Position
			local size = 2 + 8 * k * k
			orb.CFrame = CFrame.new(pos)
			orb.Size = Vector3.one * size
			orb.Transparency = 0.65 - 0.35 * k
			pull.CFrame = CFrame.new(pos)
			local ring = 18 - 13 * k
			platform.CFrame = CFrame.new(pos - Vector3.new(0, 2.7, 0)) * FLAT
			platform.Size = Vector3.new(0.25, ring, ring)
			platform.Transparency = 0.55 - 0.35 * k
			if k >= 1 then stop(); return false end
			return true
		end)

		return { Stop = stop }
	end

	 
	 
	 
	function api.SkyExplosion(position)
		api.Burst(position, 22, "PlayerCloneSkyExplosion")
		local cast = Effects.NewCast(owner, "PlayerCloneSkyRings", 1.4)
		local at = CFrame.new(position)
		disc(cast, at * FLAT, 0.5, 4, 70, 0.75, PALE, 0.3)  
		disc(cast, at, 0.5, 4, 56, 0.65, GOLD, 0.4)  
		disc(cast, at * CFrame.Angles(0, math.pi / 2, 0), 0.5, 4, 56, 0.65, GOLD, 0.4)  
		for _ = 1, 10 do  
			local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.9, 0.3), rng:NextNumber(-1, 1))
			if dir.Magnitude < 0.1 then dir = Vector3.yAxis end
			dir = dir.Unit
			local length = rng:NextNumber(26, 44)
			local ray = part(cast, "PlayerCloneRay", CFrame.lookAt(position, position + dir), Vector3.new(0.5, 0.5, 2), WHITE, 0.1)
			tween(ray, 0.5, {
				CFrame = CFrame.lookAt(position + dir * length * 0.5, position + dir * length),
				Size = Vector3.new(0.05, 0.05, length),
				Transparency = 1,
			})
		end
	end

	 
	 
	 
	function api.Telegraph(ground, time)
		local cast = Effects.NewCast(owner, "PlayerCloneTelegraph", time + 0.4)
		local outer = part(cast, "PlayerCloneMark", CFrame.new(ground + Vector3.new(0, 0.2, 0)) * FLAT,
			Vector3.new(0.15, 20, 20), SOFT, 0.8, CYLINDER)
		tween(outer, time, { Size = Vector3.new(0.15, 5, 5), Transparency = 0.25 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local inner = part(cast, "PlayerCloneMarkCore", CFrame.new(ground + Vector3.new(0, 0.3, 0)) * FLAT,
			Vector3.new(0.12, 2.5, 2.5), WHITE, 0.7, CYLINDER)
		tween(inner, time, { Transparency = 0.15 }, Enum.EasingStyle.Linear)
	end

	 
	 
	 
	function api.Arrival(ground)
		local cast = Effects.NewCast(owner, "PlayerCloneArrival", 1.2)
		disc(cast, CFrame.new(ground + Vector3.new(0, 0.3, 0)) * FLAT, 0.3, 3, 24, 0.5, PALE, 0.25)
		local pillar = part(cast, "PlayerClonePillar", CFrame.new(ground + Vector3.new(0, 22, 0)),
			Vector3.new(4, 44, 4), WHITE, 0.2)
		tween(pillar, 0.45, { Size = Vector3.new(0.4, 44, 0.4), Transparency = 1 }, Enum.EasingStyle.Quad)
		local hot = ball(cast, ground + Vector3.new(0, 3, 0), 2, 9, 0.3, WHITE, 0.1)
		flash(hot, 16, 5, 0.4)
		sparks(cast, ground + Vector3.new(0, 1, 0), 16, NumberRange.new(16, 30), 35, Enum.NormalId.Top, -55)
	end

	 
	 
	 
	 
	function api.Trail(root)
		local top = Instance.new("Attachment")
		top.Name = "PlayerCloneTrailTop"
		top.Position = Vector3.new(0, 1.6, 0)
		local bottom = Instance.new("Attachment")
		bottom.Name = "PlayerCloneTrailBottom"
		bottom.Position = Vector3.new(0, -1.6, 0)
		local trail = Instance.new("Trail")
		trail.Attachment0 = top
		trail.Attachment1 = bottom
		trail.Lifetime = 0.5
		trail.MinLength = 0.05
		trail.FaceCamera = true
		trail.LightEmission = 1
		trail.LightInfluence = 0
		trail.Color = ColorSequence.new(WHITE, GOLD)
		trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1) })
		trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
		top.Parent = root
		bottom.Parent = root
		trail.Parent = root
		local items = { top, bottom, trail }
		for _, item in ipairs(items) do Debris:AddItem(item, 5) end  
		return function()
			trail.Enabled = false
			for _, item in ipairs(items) do Debris:AddItem(item, 1) end
		end
	end

	 
	 
	 
	function api.Beam(a, b, time, width)
		local distance = (b - a).Magnitude
		if distance < 0.5 then return end
		time = time or 0.3
		width = width or 1
		local cast = Effects.NewCast(owner, "PlayerCloneBeam", time + 0.5)
		local p = part(cast, "PlayerCloneBeam", CFrame.lookAt(a, b) * CFrame.new(0, 0, -distance / 2),
			Vector3.new(width, width, distance), PALE, 0.1)
		tween(p, time, { Size = Vector3.new(0.05, 0.05, distance), Transparency = 1 }, Enum.EasingStyle.Quad)
	end

	function api.Swap(a, b)
		api.Burst(a, 5, "PlayerCloneSwap")
		api.Burst(b, 5, "PlayerCloneSwap")
		api.Beam(a, b, 0.35, 1.4)
	end

	function api.Dash(position)
		api.Burst(position, 3.5, "PlayerCloneDash")
	end

	 
	function api.Rush(model)
		local old = model:FindFirstChild("PlayerCopyRushGlow")
		if old then old:Destroy() end
		local h = Instance.new("Highlight")
		h.Name = "PlayerCopyRushGlow"
		h.FillColor = EMBER
		h.OutlineColor = WHITE
		h.FillTransparency = 0.15
		h.OutlineTransparency = 0
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = model
		TweenService:Create(h, TweenInfo.new(0.18, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ FillTransparency = 0.55 }):Play()
		Debris:AddItem(h, 3)
		api.Burst(model:GetPivot().Position, 4, "PlayerCloneRush")
	end

	function api.Calm(model)
		local h = model:FindFirstChild("PlayerCopyRushGlow")
		if h then h:Destroy() end
	end

	return api
end