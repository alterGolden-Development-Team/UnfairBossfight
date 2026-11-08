local Visuals = {}
function Visuals.profile(ctx)
	local function profile(x, width)
		local curve = math.sqrt(math.max(0, 1 - (x / (width * 0.5)) ^ 2))
		return -16 * curve, 0.35 + 4 * curve ^ 0.7
	end
	return profile
end
function Visuals.disc(ctx)
	local core = ctx.core
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local function disc(position, startDiameter, endDiameter, duration, color, startAlpha)
		local d = core.Part(
			"IntimidatingShockDisc",
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
			"IntimidatingFlash",
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
function Visuals.addTrail(ctx)
	local bright = ctx.bright
	local gold = ctx.gold
	local function addTrail(host, height, lifetime, startAlpha)
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, height * 0.5, 0)
		a0.Parent = host
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -height * 0.5, 0)
		a1.Parent = host
		local trail = Instance.new("Trail")
		trail.Name = "CrescentWake"
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Lifetime = lifetime
		trail.MinLength = 0.1
		trail.Color = ColorSequence.new(bright, gold)
		trail.LightEmission = 1
		trail.FaceCamera = true
		trail.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, startAlpha or 0.4), NumberSequenceKeypoint.new(1, 1) })
		trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.15) })
		trail.Parent = host
		return trail
	end
	return addTrail
end
function Visuals.CreateFlameTrail(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local Status = ctx.Status
	local Placement = ctx.Placement
	local core = ctx.core
	local Config = ctx.Config
	local gold = ctx.gold
	local Audio = ctx.Audio
	local bright = ctx.bright
	local deepGold = ctx.deepGold
	local rng = ctx.rng
	local function CreateFlameTrail(width)
		local cast = Effects.NewCast(actor, "IntimidatingGoldenFlames", math.huge)
		local strips, members = {}, {}
		local scan = 0
		local humStarted = false
		local added = 0
		local trail = { Cast = cast, Stopped = false }
		cast.OnDispose = function()
			Status.RemoveZoneBurn(cast)
			table.clear(members)
			table.clear(strips)
		end
		function trail:Add(frame)
			if self.Stopped or cast.closed then
				return
			end
			local center = Placement.GroundPoint(frame.Position + frame.LookVector * 8, { Clamp = false })
			if not center then
				return
			end
			local direction = Vector3.new(frame.LookVector.X, 0, frame.LookVector.Z)
			if direction.Magnitude < 0.01 then
				return
			end
			local flat = CFrame.lookAt(center + Vector3.new(0, 0.12, 0), center + Vector3.new(0, 0.12, 0) + direction)
			local body = cast:Add(
				core.Part(
					"GoldenMagicalFlamePath",
					flat,
					Vector3.new(width, 0.18, Config.GoldenFlameSegmentLength + 1),
					gold,
					1
				)
			)
			body.Material = Enum.Material.Neon
			if not humStarted then
				humStarted = true
				Audio.Loop(cast, actor, "CrescentFlame", flat.Position)
			end
			added += 1
			local emitters = {}
			local function track(emitter)
				table.insert(emitters, { Emitter = emitter, Rate = emitter.Rate })
			end
			 
			local sparks = Instance.new("ParticleEmitter")
			sparks.Name = "GoldenFlameTongues"
			sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sparks.Color = ColorSequence.new(bright, gold)
			sparks.LightEmission = 1
			sparks.EmissionDirection = Enum.NormalId.Top
			sparks.SpreadAngle = Vector2.new(10, 10)
			sparks.Lifetime = NumberRange.new(0.5, 1)
			sparks.Speed = NumberRange.new(4, 8)
			sparks.Rate = 28
			sparks.Acceleration = Vector3.new(0, 4, 0)
			sparks.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1.5),
				NumberSequenceKeypoint.new(0.4, 2.5),
				NumberSequenceKeypoint.new(1, 0),
			})
			sparks.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.15),
				NumberSequenceKeypoint.new(0.7, 0.35),
				NumberSequenceKeypoint.new(1, 1),
			})
			sparks.Parent = body
			track(sparks)
			 
			local fire = Instance.new("ParticleEmitter")
			fire.Name = "GoldenFlameCore"
			fire.Texture = "rbxasset://textures/particles/fire_main.dds"
			fire.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, bright),
				ColorSequenceKeypoint.new(0.4, gold),
				ColorSequenceKeypoint.new(1, deepGold),
			})
			fire.LightEmission = 1
			fire.EmissionDirection = Enum.NormalId.Top
			fire.SpreadAngle = Vector2.new(8, 8)
			fire.Lifetime = NumberRange.new(0.6, 1.1)
			fire.Speed = NumberRange.new(2, 5)
			fire.Rate = 24
			fire.Acceleration = Vector3.new(0, 6, 0)
			fire.Rotation = NumberRange.new(0, 360)
			fire.RotSpeed = NumberRange.new(-50, 50)
			fire.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 2.5),
				NumberSequenceKeypoint.new(0.35, 4.5),
				NumberSequenceKeypoint.new(1, 0),
			})
			fire.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(0.6, 0.5),
				NumberSequenceKeypoint.new(1, 1),
			})
			fire.Parent = body
			track(fire)
			 
			local embers = Instance.new("ParticleEmitter")
			embers.Name = "GoldenFlameEmbers"
			embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			embers.Color = ColorSequence.new(bright, deepGold)
			embers.LightEmission = 1
			embers.EmissionDirection = Enum.NormalId.Top
			embers.SpreadAngle = Vector2.new(25, 25)
			embers.Lifetime = NumberRange.new(1, 2)
			embers.Speed = NumberRange.new(8, 14)
			embers.Rate = 10
			embers.Acceleration = Vector3.new(0, 6, 0)
			embers.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
			embers.Parent = body
			track(embers)
			 
			local light
			if added % 3 == 1 then
				light = Instance.new("PointLight")
				light.Color = gold
				light.Range = 16
				light.Brightness = 0
				light.Parent = body
			end
			sparks:Emit(14)
			fire:Emit(8)
			table.insert(strips, {
				Body = body,
				Frame = flat,
				Expires = cast:Now() + Config.GoldenFlameLifetime,
				Born = cast:Now(),
				Seed = rng:NextNumber(0, 6.28),
				Light = light,
				Emitters = emitters,
			})
		end
		function trail:Stop()
			self.Stopped = true
		end
		cast:Step(function(dt, now)
			for index = #strips, 1, -1 do
				local strip = strips[index]
				if now >= strip.Expires then
					Effects.Release(strip.Body)
					table.remove(strips, index)
				else
					local fadeOut = math.clamp((now - strip.Expires + 1.2) / 1.2, 0, 1)
					local fadeIn = math.clamp((now - strip.Born) / 0.35, 0, 1)
					local flicker = 0.04 * math.sin(now * 11 + strip.Seed)
					strip.Body.Transparency =
						math.clamp(math.max(0.65 + 0.35 * (1 - fadeIn), 0.65 + 0.35 * fadeOut) + flicker, 0, 1)
					local life = 1 - fadeOut
					for _, item in ipairs(strip.Emitters) do
						item.Emitter.Rate = item.Rate * life
					end
					if strip.Light then
						strip.Light.Brightness = (1.1 + 0.4 * math.sin(now * 9 + strip.Seed)) * life * fadeIn
					end
				end
			end
			scan += dt
			if scan >= 0.1 then
				scan = 0
				local current = {}
				for _, character in ipairs(core.Characters()) do
					if core.Alive(character) then
						local position = character.HumanoidRootPart.Position
						for _, strip in ipairs(strips) do
							local point = strip.Frame:PointToObjectSpace(position)
							if
								math.abs(point.X) <= width / 2 + 1
								and math.abs(point.Z) <= (Config.GoldenFlameSegmentLength + 1) / 2 + 1
								and point.Y >= -2
								and point.Y <= 7
							then
								current[character] = true
								break
							end
						end
					end
				end
				for character in pairs(current) do
					if not members[character] then
						Status.SetZoneBurn(character, cast, true, actor)
					end
				end
				for character in pairs(members) do
					if not current[character] then
						Status.SetZoneBurn(character, cast, false)
					end
				end
				members = current
			end
			if trail.Stopped and #strips == 0 then
				cast:Dispose()
				return false
			end
			return true
		end)
		return trail
	end
	return CreateFlameTrail
end
function Visuals.CreateWave(ctx)
	local core = ctx.core
	local b = ctx.b
	local gold = ctx.gold
	local bright = ctx.bright
	local Tween = ctx.Tween
	local profile = ctx.profile
	local deepGold = ctx.deepGold
	local addTrail = ctx.addTrail
	local Time = ctx.Time
	local actor = ctx.actor
	local function CreateWave(frame)
		local model = Instance.new("Model")
		model.Name = "IntimidatingGoldenSlash"
		model.Parent = core.Effects
		model.WorldPivot = frame
		local width = b:GetAttribute("IntimidatingSlashWidth") or 56
		local depth = 3
		local lifetime = b:GetAttribute("IntimidatingSlashLifetime") or 30
		local anchor = core.Part("IntimidatingSlashAnchor", frame, Vector3.new(0.1, 0.1, 0.1), gold, 1)
		anchor.Parent = model
		local light = Instance.new("PointLight")
		light.Color = gold
		light.Brightness = 2
		light.Range = 25
		light.Parent = anchor
		local sparks = Instance.new("ParticleEmitter")
		sparks.Name = "SlowGoldenSlashEmbers"
		sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparks.Color = ColorSequence.new(bright, gold)
		sparks.LightEmission = 1
		sparks.Lifetime = NumberRange.new(0.3, 0.8)
		sparks.Speed = NumberRange.new(2, 5)
		sparks.SpreadAngle = Vector2.new(90, 90)
		sparks.Rate = 35
		sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0) })
		sparks.Parent = anchor
		sparks:Emit(40)
		local segments = 20
		local pulses = {}
		 
		local lightPulse = Tween:Create(
			light,
			TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Brightness = 3.5 }
		)
		lightPulse:Play()
		table.insert(pulses, lightPulse)
		for index = 0, segments - 1 do
			local a = -math.pi * 0.5 + index * math.pi / segments
			local z = a + math.pi / segments
			local p0 = Vector3.new(math.sin(a) * width * 0.5, 0, -16 * math.cos(a))
			local p1 = Vector3.new(math.sin(z) * width * 0.5, 0, -16 * math.cos(z))
			local mid = (p0 + p1) * 0.5
			local _, thickness = profile(mid.X, width)
			local cf = frame * CFrame.lookAt(mid, p1)
			local length = (p1 - p0).Magnitude + 0.12
			 
			local glow = core.Part(
				"IntimidatingCrescentGlow",
				cf,
				Vector3.new(thickness * 2.2, depth + 2.5, length + 0.2),
				deepGold,
				0.8
			)
			glow.Material = Enum.Material.Neon
			glow.Parent = model
			local glowPulse = Tween:Create(
				glow,
				TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Transparency = 0.92 }
			)
			glowPulse:Play()
			table.insert(pulses, glowPulse)
			local piece = core.Part("IntimidatingCrescentRibbon", cf, Vector3.new(thickness, depth, length), gold, 0.12)
			piece.Material = Enum.Material.Neon
			piece.Parent = model
			local pulse = Tween:Create(
				piece,
				TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Transparency = 0.3 }
			)
			pulse:Play()
			table.insert(pulses, pulse)
			local edge = core.Part(
				"IntimidatingCrescentEdge",
				cf * CFrame.new(thickness * 0.4, 0, 0),
				Vector3.new(0.18, depth + 0.15, length + 0.1),
				bright,
				0.02
			)
			edge.Material = Enum.Material.Neon
			edge.Parent = model
			 
			if index % 4 == 0 then
				addTrail(piece, depth, 1.2, 0.45)
			end
			 
			if index % 3 == 1 then
				local drift = Instance.new("ParticleEmitter")
				drift.Name = "CrescentDrift"
				drift.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				drift.Color = ColorSequence.new(bright, gold)
				drift.LightEmission = 1
				drift.EmissionDirection = Enum.NormalId.Top
				drift.SpreadAngle = Vector2.new(35, 35)
				drift.Lifetime = NumberRange.new(0.6, 1.3)
				drift.Speed = NumberRange.new(1.5, 4)
				drift.Rate = 6
				drift.Acceleration = Vector3.new(0, 3, 0)
				drift.Size =
					NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
				drift.Parent = piece
			end
		end
		 
		for _, side in ipairs({ -1, 1 }) do
			local tip = core.Part(
				"CrescentTipFlare",
				frame * CFrame.new(side * width * 0.5, 0, 0),
				Vector3.new(3.2, 3.2, 3.2),
				bright,
				0.1
			)
			tip.Shape = Enum.PartType.Ball
			tip.Material = Enum.Material.Neon
			tip.Parent = model
			local tipPulse = Tween:Create(
				tip,
				TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ Transparency = 0.5, Size = Vector3.new(4.4, 4.4, 4.4) }
			)
			tipPulse:Play()
			table.insert(pulses, tipPulse)
			addTrail(tip, 3.2, 1.6, 0.2)
			local tipSparks = Instance.new("ParticleEmitter")
			tipSparks.Name = "CrescentTipSparks"
			tipSparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			tipSparks.Color = ColorSequence.new(bright, gold)
			tipSparks.LightEmission = 1
			tipSparks.SpreadAngle = Vector2.new(180, 180)
			tipSparks.Lifetime = NumberRange.new(0.4, 0.9)
			tipSparks.Speed = NumberRange.new(3, 8)
			tipSparks.Rate = 50
			tipSparks.Size =
				NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
			tipSparks.Parent = tip
			local tipLight = Instance.new("PointLight")
			tipLight.Color = gold
			tipLight.Brightness = 2
			tipLight.Range = 14
			tipLight.Parent = tip
		end
		model:SetAttribute("Lifetime", lifetime)
		model:SetAttribute("ExpiresAt", workspace:GetServerTimeNow() + lifetime)
		model:SetAttribute("Shape", "Open crescent")
		core.KeepFor(model, lifetime + 0.5, pulses)
		return {
			model = model,
			frame = frame,
			width = width,
			depth = depth,
			nextTick = {},
			createdAt = Time.EncounterNow(actor),
			lifetime = lifetime,
			traveled = 0,
			pulses = pulses,
		}
	end
	return CreateWave
end
function Visuals.startChargeVfx(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local gold = ctx.gold
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local core = ctx.core
	local rng = ctx.rng
	local bright = ctx.bright
	local disc = ctx.disc
	local function startChargeVfx(blade, chargeTime)
		local cast = Effects.NewCast(actor, "IntimidatingChargeVfx", chargeTime + 1)
		local light = Instance.new("PointLight")
		light.Color = gold
		light.Brightness = 0
		light.Range = 8
		light.Parent = blade
		Tween:Create(
			light,
			TweenInfo.new(chargeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Brightness = 5, Range = 24 }
		):Play()
		Debris:AddItem(light, chargeTime + 0.6)
		local elapsed, streakTimer, ringTimer = 0, 0, 0
		cast:Step(function(dt)
			if not core.Root.Parent or not blade.Parent then
				return false
			end
			elapsed += dt
			local progress = math.clamp(elapsed / chargeTime, 0, 1)
			streakTimer += dt
			if streakTimer >= 0.06 then
				streakTimer = 0
				local center = blade.Position
				for _ = 1, 1 + math.floor(progress * 3) do
					local dir = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-0.4, 1), rng:NextNumber(-1, 1))
					dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.yAxis
					local radius = rng:NextNumber(9, 15) * (1 - progress * 0.35)
					core.MotionLine(
						"IntimidatingChargeStreak",
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
				disc(core.Root.Position - Vector3.new(0, 2.7, 0), 24 - 6 * progress, 2, 0.4, gold, 0.6)
			end
			return true
		end)
		return cast
	end
	return startChargeVfx
end
return table.freeze(Visuals)
