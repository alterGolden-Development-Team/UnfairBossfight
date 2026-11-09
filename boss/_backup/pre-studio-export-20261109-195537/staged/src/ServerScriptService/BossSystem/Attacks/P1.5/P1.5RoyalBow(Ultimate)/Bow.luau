 
local Visuals = {}
function Visuals.buildBow(ctx)
	local part = ctx.part
	local GOLD = ctx.GOLD
	local beam = ctx.beam
	local Effects = ctx.Effects
	local actor = ctx.actor
	local Time = ctx.Time
	local easeOut = ctx.easeOut
	local function buildBow(cast, root)
		local bow = part(cast, "RoyalBowAnchor", root.CFrame * CFrame.new(0, 3, -7), Vector3.one * 0.1, GOLD, 1)
		local upperArc = beam(bow, "RoyalBowUpperArc", Vector3.new(0, 0, 0), Vector3.new(0, 24, 0), 1.5, 13)
		local lowerArc = beam(bow, "RoyalBowLowerArc", Vector3.new(0, -24, 0), Vector3.new(0, 0, 0), 1.5, 13)
		local upperString = beam(bow, "RoyalBowUpperString", Vector3.new(0, 24, 0), Vector3.new(0, 0, 8), 0.25)
		local lowerString = beam(bow, "RoyalBowLowerString", Vector3.new(0, 0, 8), Vector3.new(0, -24, 0), 0.25)
		local function glowArc(name, from, finish)
			local strand = beam(bow, name, from, finish, 5, 13)
			strand.Color = ColorSequence.new(GOLD)
			strand.Transparency = NumberSequence.new(0.8)
			return strand
		end
		local upperGlow = glowArc("RoyalBowUpperArcGlow", Vector3.new(0, 0, 0), Vector3.new(0, 24, 0))
		local lowerGlow = glowArc("RoyalBowLowerArcGlow", Vector3.new(0, -24, 0), Vector3.new(0, 0, 0))
	
		 
		local reveal = {}
		for _, strand in ipairs({ upperArc, lowerArc, upperString, lowerString, upperGlow, lowerGlow }) do
			for _, attachment in ipairs({ strand.Attachment0, strand.Attachment1 }) do
				reveal[#reveal + 1] = { Attachment = attachment, Rest = attachment.Position }
				attachment.Position = Vector3.zero
			end
		end
		local revealCast = Effects.NewCast(actor, "RoyalBowReveal", 1)
		local revealBegan = Time.EncounterNow(actor)
		revealCast:Step(function()
			if not revealCast:Alive() then
				return false
			end
			local t = math.clamp((Time.EncounterNow(actor) - revealBegan) / 0.45, 0, 1)
			local grown = easeOut(t)
			for _, item in ipairs(reveal) do
				item.Attachment.Position = item.Rest * grown
			end
			if t >= 1 then
				revealCast:Dispose()
				return false
			end
			return true
		end)
	
		 
		local nockA, nockB = upperString.Attachment1, lowerString.Attachment0
		local restZ, drawn, shownDraw, twangToken = 8, 0, -1, 0
		local function setNock(z)
			nockA.Position = Vector3.new(0, 0, z)
			nockB.Position = Vector3.new(0, 0, z)
		end
		local control = {}
		function control.Draw(amount)
			twangToken += 1  
			local level = math.floor(math.clamp(amount, 0, 1) * 40)
			if level == shownDraw then
				return
			end
			shownDraw = level
			drawn = level / 40
			setNock(restZ + 7 * drawn ^ 1.4)
		end
		function control.Release()
			twangToken += 1
			local token = twangToken
			local startZ = restZ + 7 * drawn ^ 1.4
			shownDraw = -1
			local twang = Effects.NewCast(actor, "RoyalBowTwang", 0.7)
			local began = Time.EncounterNow(actor)
			twang:Step(function()
				if not twang:Alive() or token ~= twangToken then
					twang:Dispose()
					return false
				end
				local t = Time.EncounterNow(actor) - began
				if t >= 0.45 then
					setNock(restZ)
					twang:Dispose()
					return false
				end
				setNock(restZ + (startZ - restZ) * math.exp(-11 * t) * math.cos(t * 46))
				return true
			end)
		end
		return bow, control
	end
	return buildBow
end
function Visuals.windup(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local part = ctx.part
	local GOLD = ctx.GOLD
	local link = ctx.link
	local BRIGHT = ctx.BRIGHT
	local ball = ctx.ball
	local sparkEmitter = ctx.sparkEmitter
	local converge = ctx.converge
	local ring = ctx.ring
	local Time = ctx.Time
	local setAlpha = ctx.setAlpha
	local function windup(origin, position, direction, warning, final)
		local cast = Effects.NewCast(actor, final and "RoyalBowFinalWindup" or "RoyalBowArrowWindup", warning + 0.4)
		local frame = CFrame.lookAt(origin, origin + direction)
		local anchor = part(cast, "RoyalBowWindupAnchor", frame, Vector3.one * 0.1, GOLD, 1)
		local aimFrom, aimTo = Instance.new("Attachment"), Instance.new("Attachment")
		aimFrom.Parent, aimTo.Parent = anchor, anchor
		aimFrom.WorldPosition, aimTo.WorldPosition = origin, position + Vector3.new(0, 0.4, 0)
		local aim = link(anchor, aimFrom, aimTo, final and 0.7 or 0.4, BRIGHT, 1)
		aim.Name = "RoyalBowAimLine"
	
		local orb = ball(cast, "RoyalBowChargeOrb", CFrame.new(origin), Vector3.one * 0.5, BRIGHT, 0.1)
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Range = 50
		light.Brightness = 1
		light.Shadows = false
		light.Parent = orb
		local inward = sparkEmitter(orb, final and 90 or 45, final and 1.4 or 0.9)
		if converge(inward) then
			inward.SpreadAngle = Vector2.new(0, 0)
			inward.Speed = NumberRange.new(12, 18)
			inward.Lifetime = final and NumberRange.new(0.4, 0.5) or NumberRange.new(0.18, 0.26)
		end
	
		local ringAnchor = part(cast, "RoyalBowChargeRings", frame, Vector3.one * 0.1, GOLD, 1)
		local ringBeams = {}
		for layer = 1, 3 do
			local radius = (final and 13 or 7.5) * (1 - (layer - 1) * 0.25)
			local beams =
				ring(ringAnchor, radius, 28, final and 0.9 or 0.6, BRIGHT, 1, true, -layer * (final and 6 or 4), true)
			for _, strand in ipairs(beams) do
				ringBeams[#ringBeams + 1] = strand
			end
		end
	
		local began, shown = Time.EncounterNow(actor), -1
		cast:Step(function()
			if not cast:Alive() then
				return false
			end
			local elapsed = Time.EncounterNow(actor) - began
			local progress = math.clamp(elapsed / warning, 0, 1)
			orb.Size = Vector3.one * ((final and 15 or 7) * progress ^ 1.5 + 0.5)
			light.Brightness = 1 + 4 * progress
			ringAnchor.CFrame = frame * CFrame.Angles(0, 0, elapsed * (final and 6 or 4))
			local quantized = math.floor(progress * 20) / 20
			if quantized ~= shown then
				shown = quantized
				setAlpha({ aim }, 0.9 - 0.55 * quantized)
				setAlpha(ringBeams, 1 - 0.8 * quantized)
			end
			return true
		end)
		return cast
	end
	return windup
end
function Visuals.releaseBurst(ctx)
	local expandingRing = ctx.expandingRing
	local sparkBurst = ctx.sparkBurst
	local core = ctx.core
	local function releaseBurst(origin, direction, final)
		expandingRing(
			CFrame.lookAt(origin, origin + direction),
			true,
			2,
			final and 20 or 11,
			0.35,
			final and 2.4 or 1.5
		)
		sparkBurst(origin, final and 50 or 24, final and 1.6 or 1, final and 40 or 26)
		core.ScreenEffect("Shake", {
			Origin = origin,
			Radius = final and 250 or 120,
			Duration = final and 0.4 or 0.18,
			Intensity = final and 0.4 or 0.2,
		})
	end
	return releaseBurst
end
function Visuals.telegraph(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local part = ctx.part
	local GOLD = ctx.GOLD
	local ring = ctx.ring
	local disc = ctx.disc
	local UPRIGHT = ctx.UPRIGHT
	local api = ctx.api
	local BRIGHT = ctx.BRIGHT
	local link = ctx.link
	local point = ctx.point
	local Time = ctx.Time
	local resizeRing = ctx.resizeRing
	local easeOut = ctx.easeOut
	local setAlpha = ctx.setAlpha
	local function telegraph(position, radius, final, duration)
		local cast = Effects.NewCast(actor, final and "RoyalBowFinalTelegraph" or "RoyalBowTelegraph", duration + 0.4)
		local base = Vector3.new(position.X, position.Y + 0.15, position.Z)
		local anchor = part(cast, "RoyalBowTelegraphAnchor", CFrame.new(base), Vector3.one * 0.1, GOLD, 1)
		ring(anchor, radius, math.clamp(math.floor(radius * 1.5), 48, 96), final and 1.8 or 1.2, GOLD, 0.1, false, 0)
		local fill =
			disc(cast, "RoyalBowTelegraphFill", CFrame.new(base) * UPRIGHT, Vector3.new(0.2, 0.2, 0.2), GOLD, 0.7)
		local zone
		if final then
			ring(anchor, api.ExecutionRadius, 32, 1.4, BRIGHT, 0, false, 0.05)
			zone = disc(
				cast,
				"RoyalBowExecutionZone",
				CFrame.new(base) * UPRIGHT,
				Vector3.new(0.12, api.ExecutionRadius * 2, api.ExecutionRadius * 2),
				Color3.fromRGB(255, 110, 40),
				0.55
			)
		end
	
		 
		local spinner = part(cast, "RoyalBowTelegraphSpinner", CFrame.new(base), Vector3.one * 0.1, GOLD, 1)
		ring(spinner, radius * 0.72, final and 40 or 28, final and 1.1 or 0.7, BRIGHT, 0.35, false, 0.1, true)
		ring(spinner, radius * 0.5, final and 28 or 20, 0.6, GOLD, 0.5, false, 0.1, true)
		 
		local ticks = final and 16 or 10
		for tick = 1, ticks do
			local angle = (tick - 1) * math.pi * 2 / ticks
			local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
			link(
				anchor,
				point(anchor, direction * radius * 0.94 + Vector3.new(0, 0.1, 0)),
				point(anchor, direction * radius * 1.08 + Vector3.new(0, 0.1, 0)),
				final and 1.2 or 0.8,
				BRIGHT,
				0.1
			)
		end
		 
		local closeBeams, closePoints = ring(
			anchor,
			radius * 1.6,
			math.clamp(math.floor(radius * 1.2), 40, 72),
			final and 1.3 or 0.9,
			BRIGHT,
			0.6,
			false,
			0.1
		)
		 
		local curtainTops, curtainBeams, curtainScale
		if final then
			curtainTops, curtainBeams, curtainScale = {}, {}, {}
			for index = 1, 40 do
				local angle = (index - 1) * math.pi * 2 / 40
				local x, z = math.cos(angle) * radius, math.sin(angle) * radius
				local bottom, top = point(anchor, Vector3.new(x, 0.3, z)), point(anchor, Vector3.new(x, 0.3, z))
				curtainTops[index] = top
				curtainScale[index] = 0.55 + 0.45 * math.abs(math.sin(index * 1.7))
				curtainBeams[index] = link(anchor, bottom, top, 0.45, BRIGHT, 0.6)
			end
		end
	
		local began, shownClose, shownCurtain = Time.EncounterNow(actor), -1, -1
		cast:Step(function()
			if not cast:Alive() then
				return false
			end
			local elapsed = Time.EncounterNow(actor) - began
			local progress = math.clamp(elapsed / duration, 0, 1)
			local size = math.max(radius * 2 * progress, 0.2)
			fill.Size = Vector3.new(0.2, size, size)
			if zone then
				zone.Transparency = 0.5 + 0.2 * math.sin(elapsed * 10)
			end
			spinner.CFrame = CFrame.new(base) * CFrame.Angles(0, elapsed * (final and 1.4 or 2) * (1 + progress), 0)
			local closeStep = math.floor(progress * 24)
			if closeStep ~= shownClose then
				shownClose = closeStep
				resizeRing(closePoints, radius * (1.6 - 0.6 * easeOut(closeStep / 24)), false, 0.1)
				setAlpha(closeBeams, 0.6 - 0.6 * closeStep / 24)
			end
			if curtainTops then
				local level = math.floor(progress * 20)
				if level ~= shownCurtain then
					shownCurtain = level
					local rise = easeOut(level / 20)
					for index, top in ipairs(curtainTops) do
						top.Position =
							Vector3.new(top.Position.X, 0.3 + 34 * curtainScale[index] * rise, top.Position.Z)
					end
					setAlpha(curtainBeams, 0.6 - 0.4 * level / 20)
				end
			end
			return true
		end)
		return cast
	end
	return telegraph
end
return table.freeze(Visuals)
