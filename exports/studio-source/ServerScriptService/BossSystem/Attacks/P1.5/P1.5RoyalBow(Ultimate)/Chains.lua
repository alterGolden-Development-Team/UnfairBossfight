 
local Visuals = {}
function Visuals.chainSigil(ctx)
	local CHAIN_TINT = ctx.CHAIN_TINT
	local GOLD = ctx.GOLD
	local Effects = ctx.Effects
	local actor = ctx.actor
	local part = ctx.part
	local setAlpha = ctx.setAlpha
	local ring = ctx.ring
	local BRIGHT = ctx.BRIGHT
	local point = ctx.point
	local link = ctx.link
	local HOT = ctx.HOT
	local WHITE = ctx.WHITE
	local disc = ctx.disc
	local UPRIGHT = ctx.UPRIGHT
	local sparkEmitter = ctx.sparkEmitter
	local expandingRing = ctx.expandingRing
	local random = ctx.random
	local Time = ctx.Time
	local resizeRing = ctx.resizeRing
	local easeOut = ctx.easeOut
	local recolor = ctx.recolor
	local sparkBurst = ctx.sparkBurst
	local function chainSigil(record, settings)
		local final, radius, mode = settings.Final, settings.Radius, settings.Mode
		local tracking, life = settings.TrackingTime, settings.Life
		local crowded = settings.Count > 4  
		local mark = CHAIN_TINT[mode] or GOLD
		local cast = Effects.NewCast(actor, final and "RoyalBowFinalChainSigil" or "RoyalBowChainSigil", life + 1.2)
		local function groundOf()
			local at = record.Position or settings.Position
			return Vector3.new(at.X, at.Y + 0.2, at.Z)
		end
		local lastAt = groundOf()
		local anchor = part(cast, "RoyalBowChainAnchor", CFrame.new(lastAt), Vector3.one * 0.1, GOLD, 1)
	
		local groups, dirty = {}, true
		local function group(beams, alpha)
			local item = { Beams = beams, Alpha = alpha }
			groups[#groups + 1] = item
			return item
		end
		local function paint(item, visibility)
			setAlpha(item.Beams, 1 - (1 - item.Alpha) * visibility)
		end
	
		local edgeBeams =
			ring(anchor, radius * 1.15, crowded and 24 or 40, final and 1.1 or 0.8, mark, 1, false, 0, true)
		local edge = group(edgeBeams, 0.1)
		local closeBeams, closePoints = ring(anchor, radius * 3.4, crowded and 20 or 32, 0.5, BRIGHT, 1, false, 0.05)
		local closing = group(closeBeams, 0.25)
	
		local runePoints, runeBeams = {}, {}
		for index = 1, 6 do
			local angle = (index - 1) * math.pi / 3
			runePoints[index] =
				point(anchor, Vector3.new(math.cos(angle) * radius * 0.85, 0.05, math.sin(angle) * radius * 0.85))
		end
		for index = 1, 6 do
			runeBeams[index] = link(anchor, runePoints[index], runePoints[(index + 1) % 6 + 1], 0.35, mark, 1)
		end
		local rune = group(runeBeams, 0.2)
	
		local crossBeams = {}
		if mode == "Direct" then  
			for arm = 0, 3 do
				local angle = arm * math.pi * 0.5
				local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
				crossBeams[#crossBeams + 1] = link(
					anchor,
					point(anchor, direction * radius * 0.3 + Vector3.new(0, 0.05, 0)),
					point(anchor, direction * radius * 1.6 + Vector3.new(0, 0.05, 0)),
					0.5,
					HOT,
					1
				)
			end
		end
		local cross = group(crossBeams, 0.1)
	
		 
		local linkCount = crowded and 6 or 9
		local links, linkBeams = {}, {}
		for index = 1, linkCount do
			local rest = 0.6 + (index - 1) * 3.4
			local sway = index % 2 == 0 and 0.3 or -0.3
			local bottom = point(anchor, Vector3.new(sway, rest, 0))
			local top = point(anchor, Vector3.new(sway, rest + 2.4, 0))
			local strand = link(anchor, bottom, top, index % 2 == 0 and 0.5 or 0.8, BRIGHT, 1)
			strand.Color = ColorSequence.new(WHITE, mark)
			links[index] = { Top = top, Bottom = bottom, Rest = rest, Sway = sway }
			linkBeams[index] = strand
		end
		local chain = group(linkBeams, final and 0.2 or 0.35)
	
		local pillarHeight = final and 70 or 46
		local pillarWidth = math.max(radius * 0.3, 0.8)
		local pillar = disc(
			cast,
			"RoyalBowChainPillar",
			CFrame.new(lastAt) * UPRIGHT,
			Vector3.new(0.5, pillarWidth, pillarWidth),
			mark,
			1
		)
		local glitter = sparkEmitter(pillar, crowded and 14 or 24, 0.6)
		glitter.Speed = NumberRange.new(0.5, 2)
		glitter.Acceleration = Vector3.new(0, 4, 0)
		glitter.Color = ColorSequence.new(BRIGHT, mark)
		local rise = sparkEmitter(anchor, crowded and 8 or 14, 0.7)
		rise.EmissionDirection = Enum.NormalId.Top
		rise.Speed = NumberRange.new(4, 12)
		rise.SpreadAngle = Vector2.new(18, 18)
		rise.Acceleration = Vector3.new(0, 6, 0)
		rise.Lifetime = NumberRange.new(0.8, 1.4)
		rise.Color = ColorSequence.new(BRIGHT, mark)
		local light = Instance.new("PointLight")
		light.Color = mark
		light.Range = 18
		light.Brightness = 0
		light.Shadows = false
		light.Parent = anchor
	
		expandingRing(CFrame.new(lastAt), false, 1, radius * 2.6, 0.4, final and 1.4 or 1, 20)  
	
		local elapsed, spin = 0, random:NextNumber(0, math.pi * 2)
		local locked, fadeStart = false, nil
		local shownVisibility, shownClose, shownPulse, dropped, lastHeight = -1, -1, -1, false, -1
		cast:Step(function(dt)
			if not cast:Alive() then
				return false
			end
			local delta = Time.EncounterDelta(actor, dt)
			elapsed += delta
			spin += delta * (locked and 4.5 or 1.4)
			if not fadeStart and (elapsed >= life or (record.Cast and record.Cast.closed)) then
				fadeStart = elapsed
			end
			local fade = fadeStart and math.clamp((elapsed - fadeStart) / 0.35, 0, 1) or 0
			if fade >= 1 then
				cast:Dispose()
				return false
			end
			local visibility = math.min(math.clamp(elapsed / 0.25, 0, 1), 1 - fade)
	
			local at = groundOf()
			local moved = (at - lastAt).Magnitude > 0.02
			if moved then
				lastAt = at
			end
			anchor.CFrame = CFrame.new(lastAt) * CFrame.Angles(0, spin, 0)
	
			 
			if not locked then
				local progress = math.clamp(elapsed / math.max(tracking, 0.05), 0, 1)
				local closeStep = math.floor(progress * 30)
				if closeStep ~= shownClose then
					shownClose = closeStep
					resizeRing(closePoints, radius * (3.4 - 2.2 * easeOut(closeStep / 30)), false, 0.05)
				end
			end
	
			 
			if not locked and elapsed >= tracking then
				locked, dirty = true, true
				resizeRing(closePoints, radius, false, 0.05)
				recolor(closeBeams, WHITE)
				closing.Alpha = 0
				recolor(edgeBeams, HOT)
				edge.Alpha = 0.15
				recolor(runeBeams, HOT)
				rune.Alpha = 0.05
				cross.Alpha = 0
				chain.Alpha = 0
				for _, strand in ipairs(linkBeams) do
					strand.Color = ColorSequence.new(WHITE, HOT)
					strand.Width0, strand.Width1 = strand.Width0 * 1.45, strand.Width1 * 1.45
				end
				pillar.Color = HOT
				rise.Rate = rise.Rate * 3
				expandingRing(CFrame.new(lastAt), false, radius * 0.5, radius * 2.4, 0.25, final and 1.6 or 1.1, 20)
				sparkBurst(lastAt + Vector3.new(0, 1, 0), final and 12 or 8, 0.7, 16)
			end
	
			 
			if locked then
				local pulse = math.floor((math.sin(elapsed * 16) * 0.5 + 0.5) * 4)
				if pulse ~= shownPulse then
					shownPulse = pulse
					rune.Alpha = 0.05 + 0.12 * pulse
					edge.Alpha = 0.1 + 0.1 * pulse
					paint(rune, visibility)
					paint(edge, visibility)
				end
			end
	
			local quantized = math.floor(visibility * 12)
			if quantized ~= shownVisibility or dirty then
				shownVisibility, dirty = quantized, false
				for _, item in ipairs(groups) do
					paint(item, quantized / 12)
				end
				pillar.Transparency = 1 - (1 - (locked and 0.35 or 0.6)) * quantized / 12
				light.Brightness = (locked and 4 or 1.5) * quantized / 12
			end
	
			local height = math.max(pillarHeight * easeOut(math.clamp(elapsed / 0.3, 0, 1)) * (1 - fade), 0.5)
			if moved or math.abs(height - lastHeight) > 0.2 then
				lastHeight = height
				pillar.Size = Vector3.new(height, pillarWidth, pillarWidth)
				pillar.CFrame = CFrame.new(lastAt.X, lastAt.Y + height * 0.5, lastAt.Z) * UPRIGHT
			end
	
			 
			if not dropped then
				local settled = true
				for index, item in ipairs(links) do
					local land = math.clamp((elapsed - index * 0.025) / 0.3, 0, 1)
					if land < 1 then
						settled = false
					end
					local lift = 40 * (1 - easeOut(land))
					item.Bottom.Position = Vector3.new(item.Sway, item.Rest + lift, 0)
					item.Top.Position = Vector3.new(item.Sway, item.Rest + 2.4 + lift, 0)
				end
				dropped = settled
			end
			return true
		end)
	end
	return chainSigil
end
function Visuals.chainTethers(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local part = ctx.part
	local GOLD = ctx.GOLD
	local point = ctx.point
	local link = ctx.link
	local BRIGHT = ctx.BRIGHT
	local Time = ctx.Time
	local core = ctx.core
	local setAlpha = ctx.setAlpha
	local recolor = ctx.recolor
	local HOT = ctx.HOT
	local function chainTethers(records, target, fallback, life, lockAt)
		if #records == 0 then
			return
		end
		local cast = Effects.NewCast(actor, "RoyalBowChainTethers", life + 1)
		local hub = part(cast, "RoyalBowChainTetherAnchor", CFrame.new(fallback), Vector3.one * 0.1, GOLD, 1)
		local hubPoint = point(hub, Vector3.zero)
		local feet, beams = {}, {}
		for index = 1, #records do
			feet[index] = point(hub, Vector3.zero)
			beams[index] = link(hub, feet[index], hubPoint, 0.3, BRIGHT, 1)
			beams[index].Color = ColorSequence.new(BRIGHT, GOLD)
		end
		local lastFocus = fallback
		local elapsed, shown, locked = 0, -1, false
		cast:Step(function(dt)
			if not cast:Alive() then
				return false
			end
			elapsed += Time.EncounterDelta(actor, dt)
			local open = false
			for _, record in ipairs(records) do
				if not (record.Cast and record.Cast.closed) then
					open = true
					break
				end
			end
			if elapsed >= life + 0.3 or not open then
				cast:Dispose()
				return false
			end
			if target and target.Parent and core.Alive(target) then
				local root = target:FindFirstChild("HumanoidRootPart")
				if root then
					lastFocus = root.Position
				end
			end
			local first = records[1].Position
			local focus = Vector3.new(lastFocus.X, (first and first.Y or fallback.Y) + 0.4, lastFocus.Z)
			hub.CFrame = CFrame.new(focus)
			hubPoint.WorldPosition = focus
			for index, record in ipairs(records) do
				local at = record.Position
				if at then
					feet[index].WorldPosition = Vector3.new(at.X, at.Y + 0.4, at.Z)
				end
			end
			local visibility = math.min(math.clamp(elapsed / 0.3, 0, 1), math.clamp((life - elapsed) / 0.3, 0, 1))
			local level = elapsed < lockAt and elapsed / math.max(lockAt, 0.05) or 1
			local signature = math.floor(visibility * 10) * 100 + math.floor(level * 10)
			if signature ~= shown then
				shown = signature
				setAlpha(beams, 1 - (1 - (0.8 - 0.7 * level)) * visibility)
				if level >= 1 and not locked then
					locked = true
					recolor(beams, HOT)
					for _, strand in ipairs(beams) do
						strand.Width0, strand.Width1 = 0.6, 0.6
					end
				end
			end
			return true
		end)
	end
	return chainTethers
end
return table.freeze(Visuals)
