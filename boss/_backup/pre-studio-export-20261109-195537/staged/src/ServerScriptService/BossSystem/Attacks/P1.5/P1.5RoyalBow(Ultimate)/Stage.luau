 
local Visuals = {}
function Visuals.summonSigil(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local part = ctx.part
	local GOLD = ctx.GOLD
	local ring = ctx.ring
	local BRIGHT = ctx.BRIGHT
	local link = ctx.link
	local point = ctx.point
	local sparkEmitter = ctx.sparkEmitter
	local Time = ctx.Time
	local setAlpha = ctx.setAlpha
	local function summonSigil(x, groundY, z)
		local cast = Effects.NewCast(actor, "RoyalBowSummonSigil", 40)
		local base = Vector3.new(x, groundY + 0.3, z)
		local outerAnchor = part(cast, "RoyalBowSigilAnchor", CFrame.new(base), Vector3.one * 0.1, GOLD, 1)
		local innerAnchor = part(cast, "RoyalBowSigilInner", CFrame.new(base), Vector3.one * 0.1, GOLD, 1)
		local beams = {}
		local function collect(list)
			for _, strand in ipairs(list) do
				beams[#beams + 1] = strand
			end
		end
		collect(ring(outerAnchor, 26, 64, 1.6, GOLD, 1, false, 0))
		collect(ring(outerAnchor, 23.5, 64, 0.5, BRIGHT, 1, false, 0))
		collect(ring(innerAnchor, 18, 48, 1, BRIGHT, 1, false, 0.05, true))
		collect(ring(innerAnchor, 9, 32, 0.8, GOLD, 1, false, 0.05))
		for spoke = 1, 12 do
			local angle = (spoke - 1) * math.pi / 6
			local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
			beams[#beams + 1] = link(
				outerAnchor,
				point(outerAnchor, direction * 18.5 + Vector3.new(0, 0.05, 0)),
				point(outerAnchor, direction * 23.5 + Vector3.new(0, 0.05, 0)),
				0.6,
				GOLD,
				1
			)
		end
		local star = {}
		for index = 1, 6 do
			local angle = (index - 1) * math.pi / 3
			star[index] = point(innerAnchor, Vector3.new(math.cos(angle) * 16, 0.1, math.sin(angle) * 16))
		end
		for index = 1, 6 do
			beams[#beams + 1] = link(innerAnchor, star[index], star[(index + 1) % 6 + 1], 0.8, BRIGHT, 1)
		end
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Range = 50
		light.Brightness = 0
		light.Shadows = false
		light.Parent = outerAnchor
		local field =
			part(cast, "RoyalBowSigilEmbers", CFrame.new(base + Vector3.new(0, 2, 0)), Vector3.new(44, 2, 44), GOLD, 1)
		local embers = sparkEmitter(field, 40, 0.7)
		embers.Speed = NumberRange.new(1, 4)
		embers.Acceleration = Vector3.new(0, 8, 0)
		embers.Lifetime = NumberRange.new(1.4, 2.6)
		embers.SpreadAngle = Vector2.new(25, 25)
	
		local control, closedAt = {}, nil
		function control.Close()
			if not closedAt then
				closedAt = Time.EncounterNow(actor)
				embers.Enabled = false
			end
		end
		local began, shown = Time.EncounterNow(actor), -1
		cast:Step(function()
			if not cast:Alive() then
				return false
			end
			local now = Time.EncounterNow(actor)
			local level = math.clamp((now - began) / 0.8, 0, 1)
			if closedAt then
				level = math.min(level, 1 - (now - closedAt) / 0.6)
			end
			if closedAt and level <= 0 then
				cast:Dispose()
				return false
			end
			local quantized = math.floor(math.max(level, 0) * 20) / 20
			if quantized ~= shown then
				shown = quantized
				setAlpha(beams, 1 - 0.85 * quantized)
				light.Brightness = 2.5 * quantized
			end
			local turn = now - began
			outerAnchor.CFrame = CFrame.new(base) * CFrame.Angles(0, turn * 0.25, 0)
			innerAnchor.CFrame = CFrame.new(base) * CFrame.Angles(0, -turn * 0.55, 0)
			return true
		end)
		return control
	end
	return summonSigil
end
function Visuals.skyMotes(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local part = ctx.part
	local GOLD = ctx.GOLD
	local sparkEmitter = ctx.sparkEmitter
	local function skyMotes(x, groundY, z)
		local cast = Effects.NewCast(actor, "RoyalBowSkyMotes", 40)
		local field =
			part(cast, "RoyalBowMoteField", CFrame.new(x, groundY + 110, z), Vector3.new(170, 2, 170), GOLD, 1)
		local motes = sparkEmitter(field, 70, 0.55)
		motes.EmissionDirection = Enum.NormalId.Bottom
		motes.SpreadAngle = Vector2.new(6, 6)
		motes.Speed = NumberRange.new(10, 18)
		motes.Lifetime = NumberRange.new(5, 7.5)
		local control = {}
		function control.Stop()
			motes.Enabled = false
			Effects.ReleaseAfter(field, 8)
		end
		return control
	end
	return skyMotes
end
function Visuals.halo(ctx)
	local core = ctx.core
	local Effects = ctx.Effects
	local actor = ctx.actor
	local part = ctx.part
	local GOLD = ctx.GOLD
	local ring = ctx.ring
	local BRIGHT = ctx.BRIGHT
	local link = ctx.link
	local point = ctx.point
	local Time = ctx.Time
	local setAlpha = ctx.setAlpha
	local function halo()
		local root = core.Root
		local cast = Effects.NewCast(actor, "RoyalBowHalo", 30)
		local anchor = part(cast, "RoyalBowHaloAnchor", root.CFrame, Vector3.one * 0.1, GOLD, 1)
		local beams = {}
		local function collect(list)
			for _, strand in ipairs(list) do
				beams[#beams + 1] = strand
			end
		end
		local outerBeams, outer = ring(anchor, 17, 48, 1.6, GOLD, 1, true, 0)
		local innerBeams, inner = ring(anchor, 12, 36, 1, BRIGHT, 1, true, 0)
		local rimBeams = ring(anchor, 18.6, 48, 0.5, BRIGHT, 1, true, 0)
		collect(outerBeams)
		collect(innerBeams)
		collect(rimBeams)
		for step = 0, 11 do
			beams[#beams + 1] = link(anchor, inner[step * 3 + 1], outer[step * 4 + 1], 0.9, GOLD, 1)
		end
		for step = 0, 23 do
			local angle = step / 24 * math.pi * 2
			local direction = Vector3.new(math.cos(angle), math.sin(angle), 0)
			local reach = step % 2 == 0 and 29 or 24
			beams[#beams + 1] =
				link(anchor, point(anchor, direction * 20), point(anchor, direction * reach), 0.7, BRIGHT, 1)
		end
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Range = 60
		light.Brightness = 0
		light.Shadows = false
		light.Parent = anchor
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
			local level = math.clamp((now - began) / 0.8, 0, 1)
			if closedAt then
				level = math.min(level, 1 - (now - closedAt) / 0.5)
			end
			if closedAt and level <= 0 then
				cast:Dispose()
				return false
			end
			local quantized = math.floor(math.max(level, 0) * 20) / 20
			if quantized ~= shown then
				shown = quantized
				setAlpha(beams, 1 - 0.9 * quantized)
				light.Brightness = 3 * quantized
			end
			if root.Parent then
				anchor.CFrame = root.CFrame * CFrame.new(0, 4, 9) * CFrame.Angles(0, 0, (now - began) * 0.35)
			end
			return true
		end)
		return control
	end
	return halo
end
return table.freeze(Visuals)
