local Visuals = {}
function Visuals.newPart(ctx)
	local Effects = ctx.Effects
	local effects = ctx.effects
	local function newPart(name, cf, size, color, transparency)
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
		p.Parent = effects
		return p
	end
	return newPart
end
function Visuals.vfxPart(ctx)
	local newPart = ctx.newPart
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local function vfxPart(name, cf, size, color, transparency, lifetime)
		local p = newPart(name, cf, size, color, transparency)
		Tween:Create(p, TweenInfo.new(lifetime, Enum.EasingStyle.Quad), { Transparency = 1 }):Play()
		Debris:AddItem(p, lifetime + 0.06)
		return p
	end
	return vfxPart
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
function Visuals.taper(ctx)
	local function taper(p)
		return math.sin(math.pi * math.clamp(p, 0, 1)) ^ 0.7
	end
	return taper
end
function Visuals.sparkBurstAt(ctx)
	local vfxPart = ctx.vfxPart
	local GOLD = ctx.GOLD
	local makeSparks = ctx.makeSparks
	local function sparkBurstAt(position, count)
		local anchor = vfxPart("SlashSparkBurst", CFrame.new(position), Vector3.new(0.1, 0.1, 0.1), GOLD, 1, 0.4)
		local emitter = makeSparks(anchor, 0)
		emitter.Speed = NumberRange.new(10, 26)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Lifetime = NumberRange.new(0.25, 0.55)
		emitter:Emit(count)
	end
	return sparkBurstAt
end
function Visuals.dustPuffAt(ctx)
	local vfxPart = ctx.vfxPart
	local GOLD = ctx.GOLD
	local function dustPuffAt(position, size, count)
		local anchor = vfxPart("SlashDust", CFrame.new(position), Vector3.new(0.1, 0.1, 0.1), GOLD, 1, 1.1)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "GoldenSlashDust"
		emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
		emitter.Color = ColorSequence.new(Color3.fromRGB(214, 196, 152))
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(0.5, 0.9)
		emitter.Speed = NumberRange.new(8, 18)
		emitter.SpreadAngle = Vector2.new(80, 80)
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Acceleration = Vector3.new(0, -6, 0)
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-70, 70)
		emitter.Size =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.4), NumberSequenceKeypoint.new(1, size) })
		emitter.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
		emitter.Parent = anchor
		emitter:Emit(count)
	end
	return dustPuffAt
end
function Visuals.flashBall(ctx)
	local vfxPart = ctx.vfxPart
	local WHITE = ctx.WHITE
	local Tween = ctx.Tween
	local function flashBall(position, scale, duration, color)
		local ball =
			vfxPart("SlashFlash", CFrame.new(position), Vector3.one * scale * 0.3, color or WHITE, 0.1, duration)
		ball.Shape = Enum.PartType.Ball
		Tween:Create(
			ball,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.one * scale }
		):Play()
	end
	return flashBall
end
function Visuals.HitFx(ctx)
	local flashBall = ctx.flashBall
	local WHITE = ctx.WHITE
	local AMBER = ctx.AMBER
	local rng = ctx.rng
	local vfxPart = ctx.vfxPart
	local Tween = ctx.Tween
	local sparkBurstAt = ctx.sparkBurstAt
	local function HitFx(position)
		flashBall(position, 9, 0.2, WHITE)
		flashBall(position, 5, 0.12, AMBER)
		for _ = 1, 3 do
			local orientation =
				CFrame.Angles(rng:NextNumber(0, math.pi), rng:NextNumber(0, math.pi), rng:NextNumber(0, math.pi))
			local bar =
				vfxPart("SlashMark", CFrame.new(position) * orientation, Vector3.new(0.4, 0.4, 3), WHITE, 0, 0.18)
			Tween:Create(
				bar,
				TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = Vector3.new(0.06, 0.06, 11) }
			):Play()
		end
		sparkBurstAt(position, 20)
	end
	return HitFx
end
function Visuals.Crescent(ctx)
	local b = ctx.b
	local Debris = ctx.Debris
	local taper = ctx.taper
	local newPart = ctx.newPart
	local GOLD = ctx.GOLD
	local AMBER = ctx.AMBER
	local WHITE = ctx.WHITE
	local params = ctx.params
	local dustPuffAt = ctx.dustPuffAt
	local TweenService = ctx.TweenService
	local flashBall = ctx.flashBall
	local makeSparks = ctx.makeSparks
	local vfxPart = ctx.vfxPart
	local Run = ctx.Run
	local function Crescent(frame, index)
		local finisher = index == 3
		local radius = b:GetAttribute("SlashRadius") or 22
		local sweepDeg = 2 * (b:GetAttribute("SlashHalfAngle") or 135)
		local plane = frame * CFrame.Angles(0, 0, math.rad(({ 28, -28, 0 })[index]))
		local reverse = index == 2  
		local LIFE = 0.95
		local items = {}
		local longest = 0
		local function angleAt(t)
			return math.rad(-sweepDeg / 2 + sweepDeg * t)
		end
		local function progress(t)
			return reverse and 1 - t or t
		end
		local function delayAt(t, extra)
			return progress(t) * 0.07 + (extra or 0)
		end
		local function trackPart(piece, delay, hold, fade, alpha)
			table.insert(items, { Part = piece, Delay = delay, Hold = hold, Fade = fade, Alpha = alpha })
			longest = math.max(longest, delay + hold + fade)
			Debris:AddItem(piece, LIFE)
		end
	
		 
		local bodySegments = 24
		for i = 0, bodySegments - 1 do
			local t = (i + 0.5) / bodySegments
			local angle = angleAt(t)
			local width = 0.12 + 3.6 * taper(t)
			local r = radius - width / 2
			local cf = plane * CFrame.new(math.sin(angle) * r, 0, -math.cos(angle) * r) * CFrame.Angles(0, -angle, 0)
			local length = radius * math.rad(sweepDeg / bodySegments) + 0.055
			local piece = newPart("GoldenCrescent", cf, Vector3.new(length, 0.12, width), GOLD, 1)
			trackPart(piece, delayAt(t), 0.1, 0.3, 0.1)
		end
	
		 
		local anchor = newPart("SlashRibbonAnchor", plane, Vector3.new(0.1, 0.1, 0.1), GOLD, 1)
		Debris:AddItem(anchor, LIFE)
		local function ribbon(name, r, lift, segs, peak, color, alpha, emission, extra, hold, fade)
			local points = {}
			for i = 0, segs do
				local a = angleAt(i / segs)
				local attachment = Instance.new("Attachment")
				attachment.Position = Vector3.new(math.sin(a) * r, lift and lift(i / segs) or 0, -math.cos(a) * r)
				attachment.Parent = anchor
				points[i + 1] = attachment
			end
			for i = 1, segs do
				local t0, t1 = (i - 1) / segs, i / segs
				local beam = Instance.new("Beam")
				beam.Name = name
				beam.Attachment0 = points[i]
				beam.Attachment1 = points[i + 1]
				beam.Width0 = 0
				beam.Width1 = 0
				beam.FaceCamera = true
				beam.Segments = 1
				beam.LightEmission = emission
				beam.Color = ColorSequence.new(color)
				beam.Transparency = NumberSequence.new(alpha)
				beam.Parent = anchor
				local delay = delayAt((t0 + t1) * 0.5, extra)
				table.insert(items, {
					Beam = beam,
					Delay = delay,
					Hold = hold,
					Fade = fade,
					W0 = math.max(0.08, peak * taper(t0)),
					W1 = math.max(0.08, peak * taper(t1)),
				})
				longest = math.max(longest, delay + hold + fade)
			end
		end
		ribbon("SlashGlow", radius, nil, 16, 5.5, AMBER, 0.55, 0.8, 0, 0.12, 0.4)
		ribbon("SlashCore", radius, nil, 16, 1.1, WHITE, 0.02, 1, 0, 0.1, 0.3)
		 
		ribbon("SlashDome", radius * 0.97, function(t)
			return 0.6 + math.sin(math.pi * t) * 4
		end, 16, 2.4, GOLD, 0.25, 0.6, 0.01, 0.1, 0.32)
		 
		ribbon("SlashEcho", radius * 0.8, function(t)
			return 0.3 + math.sin(math.pi * t) * 1.6
		end, 10, 1.6, GOLD, 0.45, 0.8, 0.025, 0.06, 0.28)
		ribbon("SlashEcho", radius * 0.62, function(t)
			return 0.2 + math.sin(math.pi * t) * 1
		end, 10, 1.1, AMBER, 0.6, 0.8, 0.045, 0.05, 0.25)
		if finisher then
			ribbon("SlashFinisherGlow", radius * 1.12, function(t)
				return 1.2 + math.sin(math.pi * t) * 3
			end, 16, 8, AMBER, 0.78, 0.8, 0.01, 0.15, 0.45)
		end
	
		 
		local ray = workspace:Raycast(frame.Position, Vector3.new(0, -30, 0), params())
		local floor = ray and ray.Position.Y or frame.Position.Y - 3
		local flatFrame = CFrame.new(frame.Position.X, floor + 0.12, frame.Position.Z) * frame.Rotation
		local scarSegments = 16
		for i = 0, scarSegments - 1 do
			local t = (i + 0.5) / scarSegments
			local a = angleAt(t)
			local r = radius * 0.92
			local cf = flatFrame * CFrame.new(math.sin(a) * r, 0, -math.cos(a) * r) * CFrame.Angles(0, -a, 0)
			local length = r * math.rad(sweepDeg / scarSegments) + 0.1
			local piece = newPart("SlashScar", cf, Vector3.new(length, 0.08, 0.9 * taper(t) + 0.15), AMBER, 1)
			trackPart(piece, delayAt(t, 0.02), 0.15, 0.45, 0.3)
		end
		for _, t in ipairs({ 0.15, 0.5, 0.85 }) do
			local a = angleAt(t)
			local at =
				flatFrame:PointToWorldSpace(Vector3.new(math.sin(a) * radius * 0.9, 0.3, -math.cos(a) * radius * 0.9))
			dustPuffAt(at, 5, 6)
		end
		local function shockDisc(from, to, duration, color, alpha)
			local disc = newPart(
				"SlashShockwave",
				CFrame.new(frame.Position.X, floor + 0.15, frame.Position.Z) * CFrame.Angles(0, 0, math.pi * 0.5),
				Vector3.new(0.1, from, from),
				color,
				alpha
			)
			disc.Shape = Enum.PartType.Cylinder
			TweenService:Create(
				disc,
				TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = Vector3.new(0.1, to, to), Transparency = 1 }
			):Play()
			Debris:AddItem(disc, duration + 0.1)
		end
		shockDisc(6, radius * 1.5, 0.25, AMBER, 0.4)
		flashBall(frame.Position + Vector3.new(0, 1.5, 0), 9, 0.16, AMBER)
		if finisher then
			task.delay(0.08, function()
				shockDisc(8, radius * 2.1, 0.35, WHITE, 0.5)
			end)
			local column = newPart(
				"SlashColumn",
				CFrame.new(frame.Position.X, floor + 14, frame.Position.Z) * CFrame.Angles(0, 0, math.pi * 0.5),
				Vector3.new(28, 9, 9),
				AMBER,
				0.4
			)
			column.Shape = Enum.PartType.Cylinder
			TweenService:Create(
				column,
				TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = Vector3.new(46, 1.5, 1.5), Transparency = 1 }
			):Play()
			Debris:AddItem(column, 0.45)
		end
	
		 
		local function tipCFrame(a)
			return plane * CFrame.Angles(0, -a, 0) * CFrame.new(0, 0, -radius * 0.95)
		end
		local flare = newPart("SlashFlare", tipCFrame(angleAt(progress(0))), Vector3.one * 3.4, WHITE, 0.05)
		flare.Shape = Enum.PartType.Ball
		local flareLight = Instance.new("PointLight")
		flareLight.Color = GOLD
		flareLight.Range = 26
		flareLight.Brightness = 3
		flareLight.Shadows = false
		flareLight.Parent = flare
		local f0, f1 = Instance.new("Attachment"), Instance.new("Attachment")
		f0.Position = Vector3.new(0, 1.5, 0)
		f1.Position = Vector3.new(0, -1.5, 0)
		f0.Parent = flare
		f1.Parent = flare
		local flareTrail = Instance.new("Trail")
		flareTrail.Name = "SlashFlareTrail"
		flareTrail.Attachment0 = f0
		flareTrail.Attachment1 = f1
		flareTrail.Lifetime = 0.18
		flareTrail.LightEmission = 1
		flareTrail.FaceCamera = false
		flareTrail.MinLength = 0.05
		flareTrail.Color = ColorSequence.new(WHITE, GOLD)
		flareTrail.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1) })
		flareTrail.Parent = flare
		local river = makeSparks(flare, 650)
		river.Speed = NumberRange.new(3, 12)
		river.SpreadAngle = Vector2.new(180, 180)
		river.Lifetime = NumberRange.new(0.2, 0.5)
		river.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
		Debris:AddItem(flare, 0.7)
		local front = vfxPart(
			"SlashSparkBurst",
			frame * CFrame.new(0, 0, -6),
			Vector3.new(0.1, 0.1, 0.1),
			Color3.fromRGB(255, 210, 25),
			1,
			0.35
		)
		makeSparks(front, 0):Emit(30)
	
		 
		task.spawn(function()
			local began = os.clock()
			local sweeping = true
			while true do
				local t = os.clock() - began
				if sweeping then
					local a = math.clamp(t / 0.07, 0, 1)
					if flare.Parent then
						flare.CFrame = tipCFrame(angleAt(progress(a)))
					end
					if a >= 1 then
						sweeping = false
						river.Enabled = false
						flareLight.Enabled = false
						if flare.Parent then
							TweenService
								:Create(flare, TweenInfo.new(0.15), { Transparency = 1, Size = Vector3.one * 0.5 })
								:Play()
						end
					end
				end
				for _, item in ipairs(items) do
					local reveal = math.clamp((t - item.Delay) / 0.035, 0, 1)
					local fade = math.clamp((t - item.Delay - item.Hold) / item.Fade, 0, 1)
					local amount = reveal * (1 - fade * fade)
					if item.Part then
						if item.Part.Parent then
							item.Part.Transparency = 1 - (1 - item.Alpha) * amount
						end
					elseif item.Beam.Parent then
						item.Beam.Width0 = item.W0 * amount
						item.Beam.Width1 = item.W1 * amount
					end
				end
				if t >= longest and not sweeping then
					break
				end
				Run.Heartbeat:Wait()
			end
		end)
	end
	return Crescent
end
return table.freeze(Visuals)
