local Visuals = {}
function Visuals.groundClock(ctx)
	local core = ctx.core
	local BRIGHT = ctx.BRIGHT
	local VFX = ctx.VFX
	local GOLD = ctx.GOLD
	local TAU = ctx.TAU
	local function groundClock(cast, ground)
		local origin = CFrame.new(ground + Vector3.new(0, 0.22, 0))
		local records = {}
		local function anchor(name)
			local value = cast:Add(core.Part(name, origin, Vector3.one * 0.1, BRIGHT, 1))
			value:SetAttribute("TimeStopExempt", true)
			return value
		end
		local base = anchor("GoldenHourArenaClock")
		local cogA = anchor("GoldenHourArenaCog")
		local cogB = anchor("GoldenHourArenaCounterCog")
		local hand = anchor("GoldenHourArenaHand")
	
		VFX.Circle(base, 48, 36, { Label = "ArenaRim", Width = 0.4, Color = GOLD, Alpha = 0.3, Collect = records })
		VFX.Circle(
			base,
			45,
			36,
			{ Label = "ArenaRimInner", Width = 0.18, Color = BRIGHT, Alpha = 0.5, Collect = records }
		)
		VFX.Circle(base, 20, 20, { Label = "ArenaCore", Width = 0.22, Color = GOLD, Alpha = 0.5, Collect = records })
		for index = 1, 12 do
			local angle = (index - 1) * TAU / 12
			local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local major = (index - 1) % 3 == 0
			VFX.Ribbon(
				base,
				{ direction * (major and 36 or 40.5), direction * 47 },
				false,
				{ Label = "ArenaHour", Width = major and 0.8 or 0.35, Color = BRIGHT, Alpha = 0.25, Collect = records }
			)
		end
		VFX.Cog(cogA, 32, 35.5, 12, { Label = "ArenaCogA", Width = 0.3, Color = GOLD, Alpha = 0.4, Collect = records })
		VFX.Cog(
			cogB,
			24,
			26.8,
			8,
			{ Label = "ArenaCogB", Width = 0.26, Color = BRIGHT, Alpha = 0.45, Offset = 0.2, Collect = records }
		)
		VFX.Ribbon(
			hand,
			{ Vector3.new(-7, 0, 0), Vector3.new(46, 0, 0) },
			false,
			{ Label = "ArenaHand", Width = 0.9, Color = BRIGHT, Alpha = 0.12, Collect = records }
		)
		VFX.Circle(
			hand,
			2.6,
			12,
			{ Label = "ArenaHandHub", Width = 0.35, Color = BRIGHT, Alpha = 0.2, Collect = records }
		)
	
		local sigil = { Records = records }
		function sigil.Update(sweep, spin)
			cogA.CFrame = origin * CFrame.Angles(0, spin * 0.5, 0)
			cogB.CFrame = origin * CFrame.Angles(0, -spin * 0.8, 0)
			hand.CFrame = origin * CFrame.Angles(0, -sweep, 0)
		end
		return sigil
	end
	return groundClock
end
function Visuals.part(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local frame = ctx.frame
	local rig = ctx.rig
	local function part(name, offset, size, color, alpha, material, dyn)
		local value = cast:Add(core.Part(name, frame * offset, size, color, 1))
		value.Material = material or Enum.Material.Metal
		value:SetAttribute("TimeStopExempt", true)
		table.insert(rig.pieces, { part = value, offset = offset, alpha = alpha or 0, dyn = dyn })
		return value
	end
	return part
end
function Visuals.disc(ctx)
	local part = ctx.part
	local FLAT = ctx.FLAT
	local function disc(name, offset, diameter, thickness, color, alpha, material, dyn)
		local value = part(
			name,
			offset * FLAT,
			Vector3.new(thickness, diameter, diameter),
			color,
			alpha,
			material,
			dyn and function()
				return dyn() * FLAT
			end
		)
		value.Shape = Enum.PartType.Cylinder
		return value
	end
	return disc
end
function Visuals.ringPulse(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local BRIGHT = ctx.BRIGHT
	local VFX = ctx.VFX
	local pulses = ctx.pulses
	local function ringPulse(ringFrame, radius, duration, width, alpha, color, sides)
		if cast.closed then
			return
		end
		local carrier = cast:Add(core.Part("GoldenHourRingPulse", ringFrame, Vector3.one * 0.1, BRIGHT, 1))
		carrier:SetAttribute("TimeStopExempt", true)
		local strands, attachments = VFX.Circle(
			carrier,
			1,
			sides or 36,
			{ Label = "RingPulse", Width = width, Color = color or BRIGHT, Alpha = alpha }
		)
		local directions = {}
		for index, attachment in ipairs(attachments) do
			directions[index] = attachment.Position
		end
		pulses[#pulses + 1] = {
			Carrier = carrier,
			Strands = strands,
			Attachments = attachments,
			Directions = directions,
			Start = os.clock(),
			Duration = duration,
			Radius = radius,
			Width = width,
			Alpha = alpha,
		}
	end
	return ringPulse
end
return table.freeze(Visuals)
