 
local Visuals = {}
function Visuals.blastPlumes(ctx)
	local random = ctx.random
	local part = ctx.part
	local GOLD = ctx.GOLD
	local Effects = ctx.Effects
	local function blastPlumes(cast, position, radius, damageHeight, final)
		local innerCount, outerCount = final and 6 or 4, final and 12 or 8
		local lifetime = final and 1.1 or 0.78
		local offset = random:NextNumber(0, math.pi * 2)
		for index = 1, innerCount + outerCount do
			local outer = index > innerCount
			local ringIndex = outer and index - innerCount or index
			local ringCount = outer and outerCount or innerCount
			local angle = offset + (ringIndex - 1) * math.pi * 2 / ringCount + (outer and 0.18 or 0)
			local distance = radius * (outer and 0.72 or 0.32)
			local width = radius * (outer and 0.56 or 0.44)
			local height = damageHeight * random:NextNumber(outer and 0.68 or 0.5, outer and 1 or 0.8)
			local plumePoint = position
				+ Vector3.new(math.cos(angle) * distance, height * 0.32, math.sin(angle) * distance)
			local plume = part(
				cast,
				"RoyalBowImpactBlastPlume",
				CFrame.new(plumePoint),
				Vector3.new(width, height, width),
				index % 2 == 0 and GOLD or Color3.fromRGB(255, 192, 24),
				outer and 0.48 or 0.53
			)
			plume.Shape = Enum.PartType.Ball
			plume:SetAttribute("RoyalBowOuterBlast", outer)
			plume:SetAttribute("RoyalBowDamageRadius", radius)
			plume:SetAttribute("RoyalBowBlastDistance", distance)
			plume:SetAttribute("RoyalBowBlastRadius", width * 0.5)
			Effects:Create(plume, TweenInfo.new(lifetime - 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CFrame = CFrame.new(plumePoint + Vector3.new(0, height * 0.05, 0)),
				Size = Vector3.new(width, height * 1.1, width),
				Transparency = 1,
			}):Play()
			local sparks = Instance.new("ParticleEmitter")
			sparks.Name = "RoyalBowOuterBlastSparks"
			sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			sparks.Color = ColorSequence.new(GOLD, Color3.fromRGB(255, 162, 18))
			sparks.Rate = 0
			sparks.Lifetime = NumberRange.new(0.22, 0.65)
			sparks.Speed = NumberRange.new(final and 16 or 12, final and 28 or 22)
			sparks.Acceleration = Vector3.new(0, -12, 0)
			sparks.SpreadAngle = Vector2.new(140, 140)
			sparks.LightEmission = 0.22
			sparks.LightInfluence = 0.28
			sparks.Transparency =
				NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
			sparks.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, final and 1.1 or 0.7),
				NumberSequenceKeypoint.new(1, 0),
			})
			sparks.Parent = plume
			sparks:Emit(final and 8 or 5)
			Effects.ReleaseAfter(plume, lifetime)
		end
		return innerCount + outerCount
	end
	return blastPlumes
end
function Visuals.aftermath(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local part = ctx.part
	local GOLD = ctx.GOLD
	local disc = ctx.disc
	local UPRIGHT = ctx.UPRIGHT
	local ring = ctx.ring
	local BRIGHT = ctx.BRIGHT
	local api = ctx.api
	local dustEmitter = ctx.dustEmitter
	local sparkEmitter = ctx.sparkEmitter
	local GRAVITY = ctx.GRAVITY
	local crackField = ctx.crackField
	local random = ctx.random
	local STONE = ctx.STONE
	local screenGrade = ctx.screenGrade
	local Time = ctx.Time
	local setAlpha = ctx.setAlpha
	local growStrands = ctx.growStrands
	local function aftermath(position, radius, damageHeight, final)
		local life = final and 4.2 or 3
		local cast = Effects.NewCast(actor, final and "RoyalBowFinalAftermath" or "RoyalBowAftermath", life + 0.3)
		local base = Vector3.new(position.X, position.Y + 0.12, position.Z)
		local anchor = part(cast, "RoyalBowAftermathAnchor", CFrame.new(base), Vector3.one * 0.1, GOLD, 1)
	
		local segments = math.clamp(math.floor(radius * 1.5), 48, 96)
		local edgeBeams = ring(anchor, radius, segments, final and 3 or 2, BRIGHT, 0, false, 0.4)
		local glowBeams = ring(anchor, radius, segments, final and 9 or 6, GOLD, 0.5, false, 0.4)
		local zoneBeams = final and ring(anchor, api.ExecutionRadius, 40, 3, BRIGHT, 0, false, 0.5) or nil
	
		local pillarHeight = final and 520 or 220
		local pillarWidth = radius * (final and 0.3 or 0.28)
		local pillar = disc(
			cast,
			"RoyalBowPillar",
			CFrame.new(base + Vector3.new(0, pillarHeight * 0.5, 0)) * UPRIGHT,
			Vector3.new(pillarHeight, pillarWidth, pillarWidth),
			GOLD,
			0.4
		)
		local pillarCore = disc(
			cast,
			"RoyalBowPillarCore",
			pillar.CFrame,
			Vector3.new(pillarHeight, pillarWidth * 0.45, pillarWidth * 0.45),
			BRIGHT,
			0.1
		)
	
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Range = 60
		light.Brightness = 6
		light.Shadows = false
		light.Parent = anchor
	
		local burst = sparkEmitter(anchor, 0, radius * 0.05)
		burst.Speed = NumberRange.new(radius * 1.2, radius * 2.6)
		burst.SpreadAngle = Vector2.new(60, 60)
		burst.Acceleration = Vector3.new(0, -GRAVITY * 0.5, 0)
		burst.Lifetime = NumberRange.new(0.7, 1.4)
		burst:Emit(final and 70 or 36)
	
		local field = part(
			cast,
			"RoyalBowEmberField",
			CFrame.new(base + Vector3.new(0, 2, 0)),
			Vector3.new(radius * 1.4, 3, radius * 1.4),
			GOLD,
			1
		)
		local embers = sparkEmitter(field, radius * 0.9, 0.6)
		embers.Speed = NumberRange.new(1, 4)
		embers.Acceleration = Vector3.new(0, 8, 0)
		embers.Lifetime = NumberRange.new(1.2, 2.4)
		embers.SpreadAngle = Vector2.new(30, 30)
	
		local strands, crackBeams = crackField(anchor, final and 18 or 10, radius * 0.95, radius * 0.04)
	
		local pieces = {}
	
		 
		if final then
			screenGrade(
				{
					Brightness = 0.35,
					Contrast = 0.15,
					Saturation = 0.1,
					Tint = BRIGHT,
					Bloom = 1.8,
					Blur = 16,
					Rays = 0.45,
				},
				0.04,
				0.1,
				1.2
			)
		else
			screenGrade({ Brightness = 0.1, Bloom = 0.6, Tint = BRIGHT, Blur = 3 }, 0.03, 0.03, 0.35)
		end
	
		local began = Time.EncounterNow(actor)
		local grown, shownRing, shownFade = false, -1, -1
		cast:Step(function()
			if not cast:Alive() then
				return false
			end
			local elapsed = Time.EncounterNow(actor) - began
			local t = math.clamp(elapsed / life, 0, 1)
			local quick = math.clamp(elapsed / (final and 0.9 or 0.6), 0, 1)
	
			local level = math.floor(quick ^ 1.5 * 24) / 24
			if level ~= shownRing then
				shownRing = level
				setAlpha(edgeBeams, level)
				setAlpha(glowBeams, 0.5 + 0.5 * level)
				if zoneBeams then
					setAlpha(zoneBeams, level)
				end
			end
			local width = math.max(pillarWidth * (1 - quick), 0.05)
			pillar.Size = Vector3.new(pillarHeight, width, width)
			pillar.Transparency = 0.4 + 0.6 * quick
			pillarCore.Size = Vector3.new(pillarHeight, width * 0.45, width * 0.45)
			pillarCore.Transparency = 0.1 + 0.9 * quick
			light.Brightness = 6 * (1 - quick)
	
			if not grown then
				local grow = math.clamp(elapsed / 0.35, 0, 1)
				growStrands(strands, 1 - (1 - grow) ^ 3)
				grown = grow >= 1
			end
			local fadeLevel = math.floor(t ^ 2 * 20) / 20
			if fadeLevel ~= shownFade then
				shownFade = fadeLevel
				setAlpha(crackBeams, 0.1 + 0.9 * fadeLevel)
			end
	
			if embers.Enabled and elapsed > life * 0.7 then
				embers.Enabled = false
			end
			for _, piece in ipairs(pieces) do
				local e = math.min(elapsed, piece.Flight)
				local v = piece.Velocity
				local height = v.Y * e - 0.5 * GRAVITY * e * e
				local spot = base + Vector3.new(v.X * e, math.max(height, 0) + piece.Size * 0.5, v.Z * e)
				piece.Part.CFrame = CFrame.new(spot)
					* CFrame.Angles(piece.Spin.X * e, piece.Spin.Y * e, piece.Spin.Z * e)
				piece.Part.Transparency = t > 0.7 and (t - 0.7) / 0.3 or 0
			end
	
			if t >= 1 then
				cast:Dispose()
				return false
			end
			return true
		end)
	end
	return aftermath
end
return table.freeze(Visuals)
