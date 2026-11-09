local Visuals = {}
-- What the ground is made of at a point (terrain or a part): its colour and material, so the
-- chunks the boss tears up, the debris and the dust all match whatever floor the arena has.
local lookParams = RaycastParams.new()
lookParams.FilterType = Enum.RaycastFilterType.Include
function Visuals.groundLook(position)
	local arena = workspace:FindFirstChild("GoldenGrasslandArena")
	lookParams.FilterDescendantsInstances = { workspace.Terrain, arena and arena:FindFirstChild("Grassland"), arena and arena:FindFirstChild("ApproachFloor") }
	local hit = workspace:Raycast(position + Vector3.new(0, 12, 0), Vector3.new(0, -60, 0), lookParams)
	if not hit then
		return Color3.fromRGB(214, 190, 120), Enum.Material.SmoothPlastic
	end
	if hit.Instance == workspace.Terrain then
		return workspace.Terrain:GetMaterialColor(hit.Material), hit.Material
	end
	return hit.Instance.Color, hit.Instance.Material
end
function Visuals.makePart(ctx)
	local core = ctx.core
	local function makePart(cast, name, frame, size, color, transparency)
		local part = core.Part(name, frame, size, color, transparency)
		cast:Add(part)
		return part
	end
	return makePart
end
function Visuals.setupDisc(ctx)
	local function setupDisc(part, material)
		part.Shape = Enum.PartType.Cylinder
		part.Material = material or Enum.Material.Neon
		return part
	end
	return setupDisc
end
function Visuals.sparkEmitter(ctx)
	local whiteGold = ctx.whiteGold
	local gold = ctx.gold
	local function sparkEmitter(parent, rate, size)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.Color = ColorSequence.new(whiteGold, gold)
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
function Visuals.screenGrade(ctx)
	local effects = ctx.effects
	local actor = ctx.actor
	local Lighting = ctx.Lighting
	local Debris = ctx.Debris
	local Time = ctx.Time
	local function screenGrade(peak, fadeIn, hold, fadeOut)
		local total = fadeIn + (hold == math.huge and 60 or hold) + fadeOut
		local cast = effects.NewCast(actor, "CataclysmScreenGrade", total + 0.5)
		local color = Instance.new("ColorCorrectionEffect")
		color.Name = "CataclysmGrade"
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "CataclysmBloom"
		bloom.Size = peak.BloomSize or 36
		bloom.Threshold = peak.BloomThreshold or 0.95
		bloom.Intensity = 0
		color.Parent = Lighting
		bloom.Parent = Lighting
		Debris:AddItem(color, total + 2)
		Debris:AddItem(bloom, total + 2)
		local control, releaseAt = {}, nil
		local began, shown = Time.EncounterNow(actor), -1
		function control.Release()
			releaseAt = releaseAt or (Time.EncounterNow(actor) - began)
		end
		cast:Step(function()
			if not cast:Alive() then
				color:Destroy()
				bloom:Destroy()
				return false
			end
			local elapsed = Time.EncounterNow(actor) - began
			local outStart = releaseAt or (fadeIn + hold)
			local level = math.clamp(elapsed / fadeIn, 0, 1)
			if elapsed >= outStart then
				level = math.min(level, 1 - (elapsed - outStart) / fadeOut)
			end
			if elapsed >= outStart and level <= 0 then
				color:Destroy()
				bloom:Destroy()
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
			end
			return true
		end)
		return control
	end
	return screenGrade
end
function Visuals.telegraph(ctx)
	local effects = ctx.effects
	local actor = ctx.actor
	local groundAt = ctx.groundAt
	local UPRIGHT = ctx.UPRIGHT
	local setupDisc = ctx.setupDisc
	local makePart = ctx.makePart
	local gold = ctx.gold
	local whiteGold = ctx.whiteGold
	local Time = ctx.Time
	local function telegraph(center, radius, duration)
		local cast = effects.NewCast(actor, "CataclysmTelegraph", duration + 0.3)
		local frame = CFrame.new(center.X, groundAt(center) + 0.12, center.Z) * UPRIGHT
		setupDisc(makePart(cast, "CataclysmWarnOuter", frame, Vector3.new(0.1, radius * 2, radius * 2), gold, 0.72))
		local fill = setupDisc(makePart(cast, "CataclysmWarnFill", frame, Vector3.new(0.14, 0.2, 0.2), whiteGold, 0.3))
		local began = Time.EncounterNow(actor)
		cast:Step(function()
			if not cast:Alive() then
				return false
			end
			local t = math.clamp((Time.EncounterNow(actor) - began) / duration, 0, 1)
			local d = math.max(radius * 2 * t, 0.2)
			fill.Size = Vector3.new(0.14, d, d)
			if t >= 1 then
				cast:Dispose()
				return false
			end
			return true
		end)
	end
	return telegraph
end
function Visuals.impactBurst(ctx)
	local effects = ctx.effects
	local actor = ctx.actor
	local groundAt = ctx.groundAt
	local makePart = ctx.makePart
	local gold = ctx.gold
	local setupDisc = ctx.setupDisc
	local UPRIGHT = ctx.UPRIGHT
	local whiteGold = ctx.whiteGold
	local sparkEmitter = ctx.sparkEmitter
	local DEBRIS_GRAVITY = ctx.DEBRIS_GRAVITY
	local random = ctx.random
	local stone = ctx.stone
	local Time = ctx.Time
	local function impactBurst(center, scale, debrisCount, crackCount, simple)
		local life = 1.6
		local cast = effects.NewCast(actor, "CataclysmImpactBurst", life + 0.3)
		local base = Vector3.new(center.X, groundAt(center) + 0.1, center.Z)
		local anchor = makePart(cast, "CataclysmBurstAnchor", CFrame.new(base), Vector3.one * 0.1, gold, 1)
		local groundColor, groundMaterial = Visuals.groundLook(base)
	
		local flash, pillar, light, dome
		local pillarHeight = scale * 7
		if not simple then
			flash = setupDisc(
				makePart(
					cast,
					"CataclysmFlashDisc",
					CFrame.new(base + Vector3.new(0, 0.1, 0)) * UPRIGHT,
					Vector3.new(0.3, 1, 1),
					whiteGold,
					0.2
				)
			)
			dome = makePart(cast, "CataclysmBlastDome", CFrame.new(base), Vector3.one, whiteGold, 0.65)
			dome.Shape = Enum.PartType.Ball
			dome.Material = Enum.Material.Neon
			pillar = setupDisc(
				makePart(
					cast,
					"CataclysmPillar",
					CFrame.new(base + Vector3.new(0, pillarHeight * 0.5, 0)) * UPRIGHT,
					Vector3.new(pillarHeight, scale * 0.5, scale * 0.5),
					gold,
					0.45
				)
			)
			light = Instance.new("PointLight")
			light.Color = gold
			light.Range = math.min(scale * 4, 60)
			light.Brightness = 5
			light.Shadows = false
			light.Parent = anchor
		end
	
		local dust = Instance.new("ParticleEmitter")
		dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
		dust.Color = ColorSequence.new(groundColor:Lerp(Color3.new(1, 1, 1), 0.25), groundColor:Lerp(Color3.new(0, 0, 0), 0.2))
		dust.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
		dust.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, scale * 0.5),
			NumberSequenceKeypoint.new(1, math.min(scale * 1.6, 60)),
		})
		dust.Lifetime = NumberRange.new(0.7, 1.2)
		dust.Speed = NumberRange.new(scale * 0.8, scale * 2.2)
		dust.SpreadAngle = Vector2.new(85, 85)
		dust.Drag = 3
		dust.Rate = 200 + scale * 8
		dust.LightEmission = 0.2
		dust.Parent = anchor
	
		local sparks = sparkEmitter(anchor, 160, scale * 0.07)
		sparks.Speed = NumberRange.new(scale * 2, scale * 5)
		sparks.SpreadAngle = Vector2.new(50, 50)
		sparks.Acceleration = Vector3.new(0, -DEBRIS_GRAVITY * 0.6, 0)
		sparks.Lifetime = NumberRange.new(0.7, 1.3)
	
		local pieces = {}
		for index = 1, debrisCount do
			local size = scale * random:NextNumber(0.08, 0.2)
			local piece = makePart(
				cast,
				"CataclysmDebris",
				CFrame.new(base),
				Vector3.new(size, size * random:NextNumber(0.6, 1), size * random:NextNumber(0.8, 1.2)),
				groundColor:Lerp(Color3.new(0, 0, 0), random:NextNumber(0, 0.18)),
				0
			)
			piece.Material = groundMaterial
			local angle = random:NextNumber(0, math.pi * 2)
			local speed = scale * random:NextNumber(0.8, 2.2)
			pieces[index] = {
				Part = piece,
				Size = size,
				Velocity = Vector3.new(
					math.cos(angle) * speed,
					scale * random:NextNumber(1.2, 2.4),
					math.sin(angle) * speed
				),
				Spin = Vector3.new(random:NextNumber(-8, 8), random:NextNumber(-8, 8), random:NextNumber(-8, 8)),
			}
		end
	
		local strands, crackBeams = {}, {}
		local function strand(offsets, width)
			local attachments = {}
			for index = 1, #offsets do
				local attachment = Instance.new("Attachment")
				attachment.Parent = anchor
				attachments[index] = attachment
			end
			local segmentCount = #offsets - 1
			for index = 1, segmentCount do
				local beam = Instance.new("Beam")
				beam.Name = "CataclysmCrackLine"
				beam.Attachment0 = attachments[index]
				beam.Attachment1 = attachments[index + 1]
				beam.Width0 = math.max(width * (1 - 0.8 * (index - 1) / segmentCount), 0.25)
				beam.Width1 = math.max(width * (1 - 0.8 * index / segmentCount), 0.2)
				beam.FaceCamera = true
				beam.LightEmission = 1
				beam.Color = ColorSequence.new(whiteGold, gold)
				beam.Transparency = NumberSequence.new(0.1)
				beam.Segments = 1
				beam.Parent = anchor
				crackBeams[#crackBeams + 1] = beam
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
		local crackTotal = crackCount or 0
		for index = 1, crackTotal do
			local heading = (index - 1) * math.pi * 2 / crackTotal + random:NextNumber(-0.2, 0.2)
			local length = scale * random:NextNumber(2, 3.6)
			local width = scale * random:NextNumber(0.04, 0.08)
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
	
		local grown, shownFade = false, -1
		local began = Time.EncounterNow(actor)
		cast:Step(function()
			if not cast:Alive() then
				return false
			end
			local elapsed = Time.EncounterNow(actor) - began
			local t = math.clamp(elapsed / life, 0, 1)
			local quick = math.clamp(elapsed / 0.45, 0, 1)
	
			if flash then
				local d = math.max(scale * 2.6 * (1 - (1 - quick) ^ 3), 0.2)
				flash.Size = Vector3.new(0.3, d, d)
				flash.Transparency = 0.2 + 0.8 * quick
				dome.Size = Vector3.one * d * 1.2
				dome.Transparency = 0.65 + 0.35 * quick
				local w = math.max(scale * 0.5 * (1 - quick), 0.05)
				pillar.Size = Vector3.new(pillarHeight, w, w)
				pillar.Transparency = 0.45 + 0.55 * quick
				light.Brightness = 5 * (1 - quick)
			end
			if elapsed > 0.2 then
				if dust.Enabled then
					dust.Enabled = false
				end
				if sparks.Enabled then
					sparks.Enabled = false
				end
			end
	
			if not grown then
				local grow = math.clamp(elapsed / 0.35, 0, 1)
				local eased = 1 - (1 - grow) ^ 3
				for _, item in ipairs(strands) do
					for index, attachment in ipairs(item.Attachments) do
						local offset = item.Offsets[index]
						attachment.Position = Vector3.new(offset.X * eased, 0.15, offset.Z * eased)
					end
				end
				grown = grow >= 1
			end
			local fadeLevel = math.floor(t ^ 2 * 20) / 20
			if fadeLevel ~= shownFade then
				shownFade = fadeLevel
				local fade = NumberSequence.new(0.1 + 0.9 * fadeLevel)
				for _, beam in ipairs(crackBeams) do
					beam.Transparency = fade
				end
			end
	
			local floorY = base.Y
			for _, piece in ipairs(pieces) do
				local e = piece.Rest or elapsed
				local v = piece.Velocity
				local position = base + Vector3.new(v.X * e, v.Y * e - 0.5 * DEBRIS_GRAVITY * e * e, v.Z * e)
				position = Vector3.new(position.X, math.max(position.Y, floorY + piece.Size * 0.5), position.Z)
				if not piece.Rest and elapsed > 0.05 and position.Y <= floorY + piece.Size * 0.5 then
					piece.Rest = elapsed
				end
				piece.Part.CFrame = CFrame.new(position)
					* CFrame.Angles(piece.Spin.X * e, piece.Spin.Y * e, piece.Spin.Z * e)
				piece.Part.Transparency = t > 0.65 and (t - 0.65) / 0.35 or 0
			end
	
			if t >= 1 then
				cast:Dispose()
				return false
			end
			return true
		end)
	end
	return impactBurst
end
function Visuals.sigil(ctx)
	local effects = ctx.effects
	local actor = ctx.actor
	local groundAt = ctx.groundAt
	local makePart = ctx.makePart
	local gold = ctx.gold
	local setupDisc = ctx.setupDisc
	local UPRIGHT = ctx.UPRIGHT
	local whiteGold = ctx.whiteGold
	local Time = ctx.Time
	local function sigil(center, radius)
		local cast = effects.NewCast(actor, "CataclysmSigil", 45)
		local base = Vector3.new(center.X, groundAt(center) + 0.2, center.Z)
		local anchor = makePart(cast, "CataclysmSigilAnchor", CFrame.new(base), Vector3.one * 0.1, gold, 1)
		local glow = setupDisc(
			makePart(
				cast,
				"CataclysmSigilGlow",
				CFrame.new(base.X, base.Y - 0.1, base.Z) * UPRIGHT,
				Vector3.new(0.1, radius * 2, radius * 2),
				gold,
				1
			)
		)
		local beams = {}
	
		local function point(position)
			local attachment = Instance.new("Attachment")
			attachment.Position = position
			attachment.Parent = anchor
			return attachment
		end
		local function line(from, to, width, color)
			local beam = Instance.new("Beam")
			beam.Name = "CataclysmSigilLine"
			beam.Attachment0 = from
			beam.Attachment1 = to
			beam.Width0 = width
			beam.Width1 = width
			beam.FaceCamera = true
			beam.LightEmission = 1
			beam.Color = ColorSequence.new(color)
			beam.Transparency = NumberSequence.new(1)
			beam.Segments = 1
			beam.Parent = anchor
			beams[#beams + 1] = beam
		end
		local function ring(ringRadius, segments, width, color)
			local points = {}
			for index = 1, segments do
				local angle = (index - 1) * math.pi * 2 / segments
				points[index] = point(Vector3.new(math.cos(angle) * ringRadius, 0, math.sin(angle) * ringRadius))
			end
			for index = 1, segments do
				line(points[index], points[index % segments + 1], width, color)
			end
		end
	
		ring(radius, 56, 1.8, gold)
		ring(radius * 1.07, 56, 0.6, whiteGold)
		ring(radius * 0.62, 40, 1.2, whiteGold)
		local star = {}
		for index = 1, 6 do
			star[index] = point(Vector3.zero)
		end
		for _, pair in ipairs({ { 1, 3 }, { 3, 5 }, { 5, 1 }, { 2, 4 }, { 4, 6 }, { 6, 2 } }) do
			line(star[pair[1]], star[pair[2]], 1.3, gold)
		end
	
		local control, closedAt = {}, nil
		function control.Close()
			closedAt = closedAt or Time.EncounterNow(actor)
		end
		local began, shown = Time.EncounterNow(actor), -1
		cast:Step(function()
			if not cast:Alive() then
				return false
			end
			local now = Time.EncounterNow(actor)
			local level = math.clamp((now - began) / 0.7, 0, 1)
			if closedAt then
				level = math.min(level, 1 - (now - closedAt) / 0.6)
			end
			if closedAt and level <= 0 then
				cast:Dispose()
				return false
			end
			if level ~= shown then
				shown = level
				local visible = math.max(level, 0)
				local fade = NumberSequence.new(1 - 0.92 * visible)
				for _, beam in ipairs(beams) do
					beam.Transparency = fade
				end
				glow.Transparency = 1 - 0.14 * visible
			end
			local spin = (now - began) * 0.45
			for index, attachment in ipairs(star) do
				local angle = spin + (index - 1) * math.pi / 3
				attachment.Position = Vector3.new(math.cos(angle) * radius * 0.92, 0, math.sin(angle) * radius * 0.92)
			end
			return true
		end)
		return control
	end
	return sigil
end
function Visuals.chainVisual(ctx)
	local makePart = ctx.makePart
	local gold = ctx.gold
	local whiteGold = ctx.whiteGold
	local sparkEmitter = ctx.sparkEmitter
	local function chainVisual(cast)
		local anchor = makePart(cast, "CataclysmChainAnchor", CFrame.identity, Vector3.one * 0.1, gold, 1)
		local a, b = Instance.new("Attachment"), Instance.new("Attachment")
		a.Parent = anchor
		b.Parent = anchor
		local beam = Instance.new("Beam")
		beam.Name = "GildedChain"
		beam.Attachment0 = a
		beam.Attachment1 = b
		beam.Width0 = 0.38
		beam.Width1 = 0.38
		beam.Color = ColorSequence.new(gold, whiteGold)
		beam.Transparency = NumberSequence.new(0.08)
		beam.LightEmission = 1
		beam.FaceCamera = true
		beam.Segments = 6
		beam.CurveSize0 = 1.1
		beam.CurveSize1 = -1.1
		beam.Parent = anchor
		local edge = beam:Clone()
		edge.Name = "GildedChainCore"
		edge.Width0 = 0.09
		edge.Width1 = 0.09
		edge.Color = ColorSequence.new(whiteGold)
		edge.Parent = anchor
		local halo = beam:Clone()
		halo.Name = "GildedChainGlow"
		halo.Width0 = 1.4
		halo.Width1 = 1.4
		halo.Color = ColorSequence.new(gold)
		halo.Transparency = NumberSequence.new(0.78)
		halo.Parent = anchor
		sparkEmitter(a, 20, 0.6)
		sparkEmitter(b, 20, 0.6)
		local visual = { Anchor = anchor, First = a, Last = b }
		function visual:Connect(from, to)
			a.WorldPosition = from
			b.WorldPosition = to
		end
		return visual
	end
	return chainVisual
end
function Visuals.spawnChunk(ctx)
	local effects = ctx.effects
	local actor = ctx.actor
	local random = ctx.random
	local grass = ctx.grass
	local groundAt = ctx.groundAt
	local makePart = ctx.makePart
	local stone = ctx.stone
	local Audio = ctx.Audio
	local impactBurst = ctx.impactBurst
	local gold = ctx.gold
	local sparkEmitter = ctx.sparkEmitter
	local Time = ctx.Time
	local function spawnChunk(index, position, scale)
		local cast = effects.NewCast(actor, "CataclysmEarthChunk", 30)
		local size = Vector3.new(
			scale * random:NextNumber(0.85, 1.15),
			scale * random:NextNumber(0.65, 1),
			scale * random:NextNumber(0.85, 1.15)
		)
		if grass then
			local localPosition = grass.CFrame:PointToObjectSpace(position)
			local margin = size.Magnitude * 0.5 + 4
			position = grass.CFrame:PointToWorldSpace(
				Vector3.new(
					math.clamp(localPosition.X, -grass.Size.X * 0.5 + margin, grass.Size.X * 0.5 - margin),
					0,
					math.clamp(localPosition.Z, -grass.Size.Z * 0.5 + margin, grass.Size.Z * 0.5 - margin)
				)
			)
		end
		local y = groundAt(position)
		local bottom = Vector3.new(position.X, y - size.Magnitude * 0.5 - 1, position.Z)
		local top = Vector3.new(position.X, y + random:NextNumber(65, 105), position.Z)
		local rotation = CFrame.Angles(
			random:NextNumber(-0.65, 0.65),
			random:NextNumber(0, math.pi * 2),
			random:NextNumber(-0.65, 0.65)
		)
		 -- the chunk is torn out of whatever floor is there
		local groundColor, groundMaterial = Visuals.groundLook(Vector3.new(position.X, y, position.Z))
		local part = makePart(
			cast,
			"GildedEarthChunk",
			CFrame.new(bottom) * rotation,
			size,
			groundColor:Lerp(Color3.new(0, 0, 0), random:NextNumber(0, 0.15)),
			0
		)
		part.Material = groundMaterial
		Audio.Emit(actor, "EarthRise", position, { Scale = scale })
		impactBurst(Vector3.new(position.X, y, position.Z), scale * 0.6, 5, 3, true)
		local outline = Instance.new("SelectionBox")
		outline.Name = "GoldenEnergyOutline"
		outline.Adornee = part
		outline.LineThickness = 0.12
		outline.Color3 = gold
		outline.SurfaceTransparency = 1
		outline.Parent = part
		local glow = Instance.new("PointLight")
		glow.Color = gold
		glow.Range = math.min(scale * 1.6, 60)
		glow.Brightness = 1.5
		glow.Shadows = false
		glow.Parent = part
		sparkEmitter(part, 14 + scale * 0.5, scale * 0.07)
		local chunk = { Cast = cast, Part = part, Phase = "Rising", Launched = false, Done = false }
		local began = Time.EncounterNow(actor)
		cast:Step(function()
			if chunk.Phase == "Rising" then
				local t = math.clamp((Time.EncounterNow(actor) - began) / 0.7, 0, 1)
				part.CFrame = CFrame.new(bottom:Lerp(top, 1 - (1 - t) ^ 3)) * rotation
				if t == 1 then
					chunk.Phase = "Hovering"
				end
			elseif chunk.Phase == "Hovering" then
				part.CFrame = CFrame.new(
					top + Vector3.new(0, math.sin(Time.EncounterNow(actor) * 2.7 + index) * 0.3, 0)
				) * rotation
			end
			return not chunk.Done
		end)
		return chunk
	end
	return spawnChunk
end
return table.freeze(Visuals)
