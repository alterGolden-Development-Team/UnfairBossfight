 
local Visuals = {}
function Visuals.sparkEmitter(ctx)
	local BRIGHT = ctx.BRIGHT
	local GOLD = ctx.GOLD
	local function sparkEmitter(parent, rate, size)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(BRIGHT, GOLD)
		emitter.LightEmission = 1
		emitter.Rate = rate
		emitter.Lifetime = NumberRange.new(0.5, 1)
		emitter.Speed = NumberRange.new(3, 9)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		emitter.Parent = parent
		return emitter
	end
	return sparkEmitter
end
function Visuals.dustEmitter(ctx)
	local function dustEmitter(parent, scale)
		local dust = Instance.new("ParticleEmitter")
		dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
		dust.Color = ColorSequence.new(Color3.fromRGB(196, 176, 120), Color3.fromRGB(120, 104, 70))
		dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
		dust.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, scale * 0.3),
			NumberSequenceKeypoint.new(1, math.min(scale * 1.1, 50)),
		})
		dust.Lifetime = NumberRange.new(0.8, 1.5)
		dust.Speed = NumberRange.new(scale * 0.5, scale * 1.4)
		dust.SpreadAngle = Vector2.new(85, 85)
		dust.Drag = 3
		dust.Rate = 0
		dust.LightEmission = 0.15
		dust.Parent = parent
		return dust
	end
	return dustEmitter
end
function Visuals.converge(ctx)
	local function converge(emitter)
		return (
			pcall(function()
				emitter.Shape = Enum.ParticleEmitterShape.Sphere
				emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
				emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
			end)
		)
	end
	return converge
end
function Visuals.screenGrade(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local Lighting = ctx.Lighting
	local Debris = ctx.Debris
	local Time = ctx.Time
	local function screenGrade(peak, fadeIn, hold, fadeOut)
		local total = fadeIn + (hold == math.huge and 60 or hold) + fadeOut
		local cast = Effects.NewCast(actor, "RoyalBowScreenGrade", total + 0.5)
		local color = Instance.new("ColorCorrectionEffect")
		color.Name = "RoyalBowGrade"
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "RoyalBowBloom"
		bloom.Size = peak.BloomSize or 36
		bloom.Threshold = peak.BloomThreshold or 0.95
		bloom.Intensity = 0
		color.Parent = Lighting
		bloom.Parent = Lighting
		Debris:AddItem(color, total + 2)
		Debris:AddItem(bloom, total + 2)
		local blur, rays
		if peak.Blur then
			blur = Instance.new("BlurEffect")
			blur.Name = "RoyalBowBlur"
			blur.Size = 0
			blur.Parent = Lighting
			Debris:AddItem(blur, total + 2)
		end
		if peak.Rays then
			rays = Instance.new("SunRaysEffect")
			rays.Name = "RoyalBowRays"
			rays.Intensity = 0
			rays.Spread = peak.RaySpread or 0.85
			rays.Parent = Lighting
			Debris:AddItem(rays, total + 2)
		end
		local function cleanup()
			color:Destroy()
			bloom:Destroy()
			if blur then
				blur:Destroy()
			end
			if rays then
				rays:Destroy()
			end
		end
		local control, releaseAt = {}, nil
		local began, shown = Time.EncounterNow(actor), -1
		function control.Release()
			releaseAt = releaseAt or (Time.EncounterNow(actor) - began)
		end
		cast:Step(function()
			if not cast:Alive() then
				cleanup()
				return false
			end
			local elapsed = Time.EncounterNow(actor) - began
			local outStart = releaseAt or (fadeIn + hold)
			local level = math.clamp(elapsed / fadeIn, 0, 1)
			if elapsed >= outStart then
				level = math.min(level, 1 - (elapsed - outStart) / fadeOut)
			end
			if elapsed >= outStart and level <= 0 then
				cleanup()
				cast:Dispose()
				return false
			end
			if level ~= shown then
				shown = level
				color.Brightness = (peak.Brightness or 0) * level
				color.Contrast = (peak.Contrast or 0) * level
				color.Saturation = (peak.Saturation or 0) * level
				color.TintColor = Color3.new(1, 1, 1):Lerp(peak.Tint or Color3.new(1, 1, 1), level)
				bloom.Intensity = (peak.Bloom or 0) * level
				if blur then
					blur.Size = peak.Blur * level
				end
				if rays then
					rays.Intensity = peak.Rays * level
				end
			end
			return true
		end)
		return control
	end
	return screenGrade
end
function Visuals.crackField(ctx)
	local point = ctx.point
	local link = ctx.link
	local BRIGHT = ctx.BRIGHT
	local GOLD = ctx.GOLD
	local random = ctx.random
	local function crackField(anchor, count, reach, width)
		local strands, beams = {}, {}
		local function strand(offsets, strandWidth)
			local attachments = {}
			for index = 1, #offsets do
				attachments[index] = point(anchor, Vector3.zero)
			end
			local segmentCount = #offsets - 1
			for index = 1, segmentCount do
				local line = link(
					anchor,
					attachments[index],
					attachments[index + 1],
					math.max(strandWidth * (1 - 0.8 * (index - 1) / segmentCount), 0.25),
					BRIGHT,
					0.1
				)
				line.Width1 = math.max(strandWidth * (1 - 0.8 * index / segmentCount), 0.2)
				line.Color = ColorSequence.new(BRIGHT, GOLD)
				beams[#beams + 1] = line
			end
			strands[#strands + 1] = { Offsets = offsets, Attachments = attachments }
		end
		local function walk(start, heading, length, segments)
			local offsets = { start }
			local curl = random:NextNumber(-0.12, 0.12)
			local stepLength = length / segments
			for _ = 1, segments do
				heading += curl + random:NextNumber(-0.28, 0.28)
				offsets[#offsets + 1] = offsets[#offsets]
					+ Vector3.new(math.cos(heading), 0, math.sin(heading))
						* stepLength
						* random:NextNumber(0.7, 1.3)
			end
			return offsets
		end
		for index = 1, count do
			local heading = (index - 1) * math.pi * 2 / count + random:NextNumber(-0.2, 0.2)
			local length = reach * random:NextNumber(0.55, 1)
			local offsets = walk(Vector3.zero, heading, length, 7)
			strand(offsets, width)
			for _, pick in ipairs({ 3, 5 }) do
				if random:NextNumber() < 0.6 then
					local side = random:NextNumber() < 0.5 and -1 or 1
					strand(
						walk(offsets[pick], heading + side * random:NextNumber(0.5, 1), length * 0.35, 3),
						width * 0.6
					)
				end
			end
		end
		local farthest = 0
		for _, item in ipairs(strands) do
			for _, offset in ipairs(item.Offsets) do
				farthest = math.max(farthest, offset.Magnitude)
			end
		end
		if farthest > reach then
			local factor = reach / farthest
			for _, item in ipairs(strands) do
				for index, offset in ipairs(item.Offsets) do
					item.Offsets[index] = offset * factor
				end
			end
		end
		return strands, beams
	end
	return crackField
end
function Visuals.growStrands(ctx)
	local function growStrands(strands, amount)
		for _, item in ipairs(strands) do
			for index, attachment in ipairs(item.Attachments) do
				local offset = item.Offsets[index]
				attachment.Position = Vector3.new(offset.X * amount, 0.15, offset.Z * amount)
			end
		end
	end
	return growStrands
end
function Visuals.expandingRing(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local part = ctx.part
	local GOLD = ctx.GOLD
	local ring = ctx.ring
	local BRIGHT = ctx.BRIGHT
	local Time = ctx.Time
	local resizeRing = ctx.resizeRing
	local setAlpha = ctx.setAlpha
	local function expandingRing(frame, vertical, from, to, duration, width, segmentCount)
		local cast = Effects.NewCast(actor, "RoyalBowShockRing", duration + 0.2)
		local anchor = part(cast, "RoyalBowShockAnchor", frame, Vector3.one * 0.1, GOLD, 1)
		local segments = segmentCount or 36
		local beams, points = ring(anchor, 1, segments, width, BRIGHT, 0.1, vertical, 0)
		local began, shown = Time.EncounterNow(actor), -1
		cast:Step(function()
			if not cast:Alive() then
				return false
			end
			local t = math.clamp((Time.EncounterNow(actor) - began) / duration, 0, 1)
			local radius = from + (to - from) * (1 - (1 - t) ^ 3)
			resizeRing(points, radius, vertical, vertical and 0 or 0.2)
			local level = math.floor(t * 12) / 12
			if level ~= shown then
				shown = level
				setAlpha(beams, 0.1 + 0.9 * level)
			end
			if t >= 1 then
				cast:Dispose()
				return false
			end
			return true
		end)
	end
	return expandingRing
end
function Visuals.sparkBurst(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local part = ctx.part
	local GOLD = ctx.GOLD
	local sparkEmitter = ctx.sparkEmitter
	local function sparkBurst(position, count, size, speed)
		local cast = Effects.NewCast(actor, "RoyalBowSparkBurst", 1.4)
		local anchor = part(cast, "RoyalBowSparkAnchor", CFrame.new(position), Vector3.one * 0.1, GOLD, 1)
		local emitter = sparkEmitter(anchor, 0, size)
		emitter.Speed = NumberRange.new(speed * 0.5, speed)
		emitter:Emit(count)
	end
	return sparkBurst
end
function Visuals.groundPuff(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local part = ctx.part
	local GOLD = ctx.GOLD
	local dustEmitter = ctx.dustEmitter
	local sparkEmitter = ctx.sparkEmitter
	local expandingRing = ctx.expandingRing
	local function groundPuff(position, scale)
		local cast = Effects.NewCast(actor, "RoyalBowGroundPuff", 2)
		local base = Vector3.new(position.X, position.Y + 0.15, position.Z)
		local anchor = part(cast, "RoyalBowPuffAnchor", CFrame.new(base), Vector3.one * 0.1, GOLD, 1)
		local emitter = sparkEmitter(anchor, 0, scale * 0.06)
		emitter.Speed = NumberRange.new(scale * 0.8, scale * 1.8)
		emitter.SpreadAngle = Vector2.new(70, 70)
		emitter:Emit(math.floor(scale * 1.2))
		expandingRing(CFrame.new(base), false, 2, scale * 1.6, 0.45, 1.2)
	end
	return groundPuff
end
function Visuals.lightColumn(ctx)
	local disc = ctx.disc
	local UPRIGHT = ctx.UPRIGHT
	local BRIGHT = ctx.BRIGHT
	local function lightColumn(cast, groundY, x, z, width)
		local column = disc(
			cast,
			"RoyalBowLightColumn",
			CFrame.new(x, groundY + 0.5, z) * UPRIGHT,
			Vector3.new(1, width, width),
			BRIGHT,
			0.5
		)
		local function update(topY)
			local height = math.max(topY - groundY, 1)
			column.Size = Vector3.new(height, width, width)
			column.CFrame = CFrame.new(x, groundY + height * 0.5, z) * UPRIGHT
		end
		return update, column
	end
	return lightColumn
end
function Visuals.fadeAway(ctx)
	local Effects = ctx.Effects
	local function fadeAway(piece, seconds)
		Effects:Create(piece, TweenInfo.new(seconds), { Transparency = 1 }):Play()
		Effects.ReleaseAfter(piece, seconds + 0.1)
	end
	return fadeAway
end
function Visuals.lightSpikes(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local random = ctx.random
	local disc = ctx.disc
	local UPRIGHT = ctx.UPRIGHT
	local BRIGHT = ctx.BRIGHT
	local GOLD = ctx.GOLD
	local Time = ctx.Time
	local easeOut = ctx.easeOut
	local function lightSpikes(position, radius, final)
		local cast = Effects.NewCast(actor, "RoyalBowImpactSpikes", (final and 0.9 or 0.6) + 0.4)
		local spikes = {}
		local offset = random:NextNumber(0, math.pi * 2)
		local count = final and 14 or 8
		for index = 1, count do
			local angle = offset + (index - 1) * math.pi * 2 / count
			local distance = radius * random:NextNumber(0.35, 0.95)
			local width = radius * (final and 0.07 or 0.06)
			local foot = Vector3.new(
				position.X + math.cos(angle) * distance,
				position.Y + 0.15,
				position.Z + math.sin(angle) * distance
			)
			local spike = disc(
				cast,
				"RoyalBowImpactSpike",
				CFrame.new(foot + Vector3.new(0, 1, 0)) * UPRIGHT,
				Vector3.new(2, width, width),
				index % 2 == 0 and BRIGHT or GOLD,
				0.15
			)
			spikes[index] = {
				Part = spike,
				Foot = foot,
				Width = width,
				Height = (final and 90 or 45) * random:NextNumber(0.6, 1),
				Life = (final and 0.7 or 0.45) * random:NextNumber(0.85, 1.15),
			}
		end
		local began = Time.EncounterNow(actor)
		cast:Step(function()
			if not cast:Alive() then
				return false
			end
			local elapsed = Time.EncounterNow(actor) - began
			local done = true
			for _, item in ipairs(spikes) do
				local t = math.clamp(elapsed / item.Life, 0, 1)
				if t < 1 then
					done = false
				end
				local height = math.max(item.Height * easeOut(math.min(t * 3, 1)), 1)
				local width = item.Width * (1 - 0.6 * t)
				item.Part.Size = Vector3.new(height, width, width)
				item.Part.CFrame = CFrame.new(item.Foot + Vector3.new(0, height * 0.5, 0)) * UPRIGHT
				item.Part.Transparency = 0.15 + 0.85 * t ^ 2
			end
			if done then
				cast:Dispose()
				return false
			end
			return true
		end)
	end
	return lightSpikes
end
return table.freeze(Visuals)
