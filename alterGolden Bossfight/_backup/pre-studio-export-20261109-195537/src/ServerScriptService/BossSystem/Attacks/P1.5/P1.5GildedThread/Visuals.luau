local Visuals = {}
function Visuals.part(ctx)
	local Effects = ctx.Effects
	local Runtime = ctx.Runtime
	local function part(name, size, color, transparency)
		local value = Effects.AcquirePart()
		value.Name = name
		value.Size = size
		value.Color = color
		value.Material = Enum.Material.Neon
		value.Transparency = transparency
		value.Anchored = true
		value.CanCollide = false
		value.CanQuery = false
		value.CanTouch = false
		value.CastShadow = false
		value.Parent = Runtime.Effects
		return value
	end
	return part
end
function Visuals.emitter(ctx)
	local PARTICLE_TEXTURE = ctx.PARTICLE_TEXTURE
	local function emitter(parent, props)
		local value = Instance.new("ParticleEmitter")
		value.Enabled = false
		value.Rate = 0
		value.LightEmission = 1
		value.LightInfluence = 0
		if PARTICLE_TEXTURE ~= "" then
			value.Texture = PARTICLE_TEXTURE
		end
		for key, v in pairs(props) do
			value[key] = v
		end
		value.Parent = parent
		return value
	end
	return emitter
end
function Visuals.buildHeadFx(ctx)
	local GOLD = ctx.GOLD
	local emitter = ctx.emitter
	local FADE_OUT = ctx.FADE_OUT
	local HEAT = ctx.HEAT
	local BRIGHT = ctx.BRIGHT
	local AMBER = ctx.AMBER
	local function buildHeadFx(host)
		local att = Instance.new("Attachment")
		att.Name = "GildedThreadHeadFx"
		att.Parent = host
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Brightness = 1.8
		light.Range = 16
		light.Shadows = false
		light.Parent = att
		 
		local aura = emitter(att, {
			Name = "Aura",
			Enabled = true,
			Rate = 3,
			Lifetime = NumberRange.new(0.55),
			Speed = NumberRange.new(0),
			LockedToPart = true,
			Size = NumberSequence.new(4, 8.5),
			Transparency = NumberSequence.new(0.6, 1),
			Color = ColorSequence.new(GOLD),
			Rotation = NumberRange.new(0, 360),
		})
		 
		local glitter = emitter(att, {
			Name = "Glitter",
			Enabled = true,
			Rate = 40,
			Lifetime = NumberRange.new(0.9, 1.9),
			Speed = NumberRange.new(0.4, 3),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 2,
			Size = NumberSequence.new(0.5, 0),
			Transparency = FADE_OUT,
			Color = HEAT,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-90, 90),
		})
		 
		local embers = emitter(att, {
			Name = "Embers",
			Enabled = true,
			Rate = 24,
			Lifetime = NumberRange.new(0.35, 0.75),
			Speed = NumberRange.new(9, 20),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, -24, 0),
			Size = NumberSequence.new(0.34, 0),
			Transparency = NumberSequence.new(0, 1),
			Color = ColorSequence.new(BRIGHT, AMBER),
		})
		local emitters = { aura, glitter, embers }
		local stopped = false
		local fx = {}
		function fx.SetVisible(on)
			if stopped then
				return
			end
			for _, e in ipairs(emitters) do
				e.Enabled = on
			end
			light.Enabled = on
		end
		function fx.Stop(immediate)
			if stopped then
				return
			end
			stopped = true
			for _, e in ipairs(emitters) do
				e.Enabled = false
			end
			light:Destroy()
			aura:Destroy()
			if immediate then
				att:Destroy()
			else
				 
				task.delay(2.2, function()
					att:Destroy()
				end)
			end
		end
		return fx
	end
	return buildHeadFx
end
function Visuals.createSlot(ctx)
	local RIBBON_TEXTURE = ctx.RIBBON_TEXTURE
	local function createSlot(anchor)
		local a, b = Instance.new("Attachment"), Instance.new("Attachment")
		a.Name = "ThreadStart"
		b.Name = "ThreadEnd"
		a.Parent = anchor
		b.Parent = anchor
		local function ribbon(name)
			local beam = Instance.new("Beam")
			beam.Name = name
			beam.Attachment0 = a
			beam.Attachment1 = b
			beam.LightEmission = 1
			beam.LightInfluence = 0
			beam.FaceCamera = true
			beam.Segments = 1
			beam.Enabled = false
			beam.Parent = anchor
			return beam
		end
		local glow = ribbon("GildedThreadGlow")
		if RIBBON_TEXTURE ~= "" then
			glow.Texture = RIBBON_TEXTURE
			glow.TextureMode = Enum.TextureMode.Wrap
			glow.TextureLength = 4
			glow.TextureSpeed = 1.5
		end
		local beam = ribbon("GildedThreadRibbon")
		return { a = a, b = b, beam = beam, glow = glow, expiresAt = 0, active = false, stage = 1 }
	end
	return createSlot
end
function Visuals.styleSlot(ctx)
	local WHITE_HOT = ctx.WHITE_HOT
	local BRIGHT = ctx.BRIGHT
	local CORE_WIDTH = ctx.CORE_WIDTH
	local GLOW_WIDTH = ctx.GLOW_WIDTH
	local GOLD = ctx.GOLD
	local AMBER = ctx.AMBER
	local EMBER = ctx.EMBER
	local function styleSlot(slot, stage, f)
		local coreColor, glowColor, coreAlpha, glowAlpha, coreWidth, glowWidth
		if stage == 0 then
			coreColor, glowColor = WHITE_HOT, BRIGHT
			coreAlpha, glowAlpha = 0, 0.5
			coreWidth, glowWidth = CORE_WIDTH * 1.25, GLOW_WIDTH * 1.1
		elseif stage == 1 then
			coreColor, glowColor = BRIGHT, GOLD
			coreAlpha, glowAlpha = 0.08, 0.72
			coreWidth, glowWidth = CORE_WIDTH, GLOW_WIDTH
		else
			f = math.clamp(f or 0, 0, 1)
			local cool = 1 - f
			coreColor, glowColor = BRIGHT:Lerp(AMBER, cool), GOLD:Lerp(EMBER, cool)
			coreAlpha, glowAlpha = 0.08 + 0.92 * cool, 0.72 + 0.28 * cool
			coreWidth, glowWidth = CORE_WIDTH * f, GLOW_WIDTH * f
		end
		slot.beam.Color = ColorSequence.new(coreColor)
		slot.beam.Transparency = NumberSequence.new(coreAlpha)
		slot.beam.Width0 = coreWidth
		slot.beam.Width1 = coreWidth
		slot.glow.Color = ColorSequence.new(glowColor)
		slot.glow.Transparency = NumberSequence.new(glowAlpha)
		slot.glow.Width0 = glowWidth
		slot.glow.Width1 = glowWidth
	end
	return styleSlot
end
function Visuals.playCharge(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local CHARGE_TIME = ctx.CHARGE_TIME
	local part = ctx.part
	local WHITE_HOT = ctx.WHITE_HOT
	local GOLD = ctx.GOLD
	local emitter = ctx.emitter
	local HEAT = ctx.HEAT
	local core = ctx.core
	local function playCharge(character)
		local cast = Effects.NewCast(actor, "P1.5GildedThread", CHARGE_TIME + 0.3)
		local orb = part("GildedThreadChargeOrb", Vector3.one * 0.4, WHITE_HOT, 0.05)
		orb.Shape = Enum.PartType.Ball
		cast:Add(orb)
		local shells = {}
		for index = 1, 2 do
			local shell = part("GildedThreadChargeShell", Vector3.one * 11, GOLD, 1)
			shell.Shape = Enum.PartType.Ball
			cast:Add(shell)
			shells[index] = shell
		end
		local light = Instance.new("PointLight")
		light.Color = GOLD
		light.Range = 16
		light.Brightness = 0.5
		light.Shadows = false
		light.Parent = orb
		 
		local gather = emitter(shells[1], {
			Name = "Gather",
			Enabled = true,
			Rate = 110,
			Lifetime = NumberRange.new(0.28, 0.4),
			Speed = NumberRange.new(11, 15),
			Shape = Enum.ParticleEmitterShape.Sphere,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
			ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
			Size = NumberSequence.new(0.5, 0),
			Transparency = NumberSequence.new(0, 0.8),
			Color = HEAT,
			Rotation = NumberRange.new(0, 360),
		})
		 
		local function center()
			local root = core.Root
			local forward = root.CFrame.LookVector
			local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				local delta = targetRoot.Position - root.Position
				local flat = Vector3.new(delta.X, 0, delta.Z)
				if flat.Magnitude > 0.01 then
					forward = flat.Unit
				end
			end
			return root.Position + Vector3.new(0, 0.3, 0) + forward * 4
		end
		local function place(alpha)
			local frame = CFrame.new(center())
			orb.Size = Vector3.one * (0.4 + 2.4 * alpha * alpha)
			orb.CFrame = frame
			light.Brightness = 0.5 + 2 * alpha
			for index, shell in ipairs(shells) do
				local phase = (alpha * 1.6 + (index - 1) * 0.5) % 1
				shell.Size = Vector3.one * (11 - 8 * phase * phase)
				shell.Transparency = 1 - 0.22 * math.sin(phase * math.pi)
				shell.CFrame = frame
			end
		end
		place(0)
		local elapsed = 0
		cast.OnDispose = function()
			gather:Destroy()
			light:Destroy()
		end
		cast:Step(function(dt)
			elapsed += dt
			local root = core.Root
			if elapsed >= CHARGE_TIME or not (root and root.Parent) then
				cast:Dispose()
				return false
			end
			place(elapsed / CHARGE_TIME)
			return true
		end)
	end
	return playCharge
end
function Visuals.createImpact(ctx)
	local anchor = ctx.anchor
	local emitter = ctx.emitter
	local WHITE_HOT = ctx.WHITE_HOT
	local AMBER = ctx.AMBER
	local BRIGHT = ctx.BRIGHT
	local GOLD = ctx.GOLD
	local function createImpact()
		local att = Instance.new("Attachment")
		att.Name = "ThreadImpact"
		att.Parent = anchor
		local sparks = emitter(att, {
			Name = "Sparks",
			Rate = 260,
			Lifetime = NumberRange.new(0.3, 0.65),
			Speed = NumberRange.new(14, 30),
			SpreadAngle = Vector2.new(55, 55),
			EmissionDirection = Enum.NormalId.Front,
			Acceleration = Vector3.new(0, -45, 0),
			Drag = 1.5,
			Size = NumberSequence.new(0.45, 0),
			Transparency = NumberSequence.new(0, 1),
			Color = ColorSequence.new(WHITE_HOT, AMBER),
		})
		local flash = emitter(att, {
			Name = "Flash",
			Rate = 24,
			Lifetime = NumberRange.new(0.18, 0.24),
			Speed = NumberRange.new(0),
			Size = NumberSequence.new(2.5, 9),
			Transparency = NumberSequence.new(0.1, 1),
			Color = ColorSequence.new(BRIGHT, GOLD),
			Rotation = NumberRange.new(0, 360),
		})
		return { att = att, sparks = sparks, flash = flash, offAt = nil }
	end
	return createImpact
end
return table.freeze(Visuals)
