local Style = require(script.Parent.Style)
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local VFX = Style.VFX
local Visuals = {}

local function out(t)
	return TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

local function inn(t)
	return TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

local function key(t, v)
	return NumberSequenceKeypoint.new(t, v)
end

function Visuals.new(ctx)
	local actor = ctx.actor
	local core = ctx.core
	local Effects = ctx.Effects
	local CYAN, GOLD = Style.CYAN, Style.GOLD
	local WHITE = Style.WHITE

	local function fxPart(cast, name, cf, size, color, transparency, shape)
		local part = cast:Add(core.Part(name, cf, size, color, transparency))
		part.Material = Enum.Material.Neon
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		if shape then
			part.Shape = shape
		end
		return part
	end

	local function newEmitter(parent, props)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		emitter.LightEmission = 1
		emitter.LightInfluence = 0
		emitter.Orientation = Enum.ParticleOrientation.FacingCamera
		for name, value in pairs(props) do
			emitter[name] = value
		end
		emitter.Parent = parent
		return emitter
	end

	local function groundCFrame(root, model)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = model and { model } or {}
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -30, 0), params)
		local position = hit and (hit.Position + Vector3.new(0, 0.15, 0)) or (root.Position - Vector3.new(0, 2.5, 0))
		return CFrame.new(position)
	end

	local function ring(cast, groundCF, color, startDiameter, endDiameter, life, thickness)
		local disc = fxPart(
			cast,
			"DecelerationRing",
			groundCF * CFrame.Angles(0, 0, math.pi / 2),
			Vector3.new(thickness, startDiameter, startDiameter),
			color,
			0.1,
			Enum.PartType.Cylinder
		)
		Effects:Create(disc, out(life), {
			Size = Vector3.new(thickness * 0.25, endDiameter, endDiameter),
			Transparency = 1,
		}):Play()
	end

	local function playSound(parent, soundId, volume, speed)
		if soundId == "" then
			return
		end
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = volume
		sound.PlaybackSpeed = speed
		sound.RollOffMaxDistance = 140
		sound.Parent = parent
		sound:Play()
		Debris:AddItem(sound, 4)
	end

	local function sigilVfx(cast, root)
		local at = root.CFrame * CFrame.new(0, 2, -3.5)
		local dial = at * CFrame.Angles(0, math.pi / 2, 0)

		local sigil = fxPart(cast, "DecelerationSigil", at, Vector3.one * 1, CYAN, 0.35, Enum.PartType.Ball)
		Effects:Create(sigil, inn(0.5), { Size = Vector3.one * 4.5, Transparency = 0.1 }):Play()

		local goldDial =
			fxPart(cast, "DecelerationDialGold", dial, Vector3.new(0.1, 1, 1), GOLD, 0.45, Enum.PartType.Cylinder)
		Effects:Create(goldDial, out(0.5), { Size = Vector3.new(0.1, 7, 7) }):Play()
		local cyanDial =
			fxPart(cast, "DecelerationDialCyan", dial, Vector3.new(0.1, 10, 10), CYAN, 0.5, Enum.PartType.Cylinder)
		Effects:Create(cyanDial, inn(0.5), { Size = Vector3.new(0.1, 3, 3) }):Play()

		for index = 1, 12 do
			local angle = (index / 12) * math.pi * 2 + math.random() * 0.4
			local radius = 6 + math.random() * 3
			local height = (math.random() - 0.5) * 5
			local mote = fxPart(
				cast,
				"DecelerationMote",
				at * CFrame.new(math.cos(angle) * radius, height, math.sin(angle) * radius),
				Vector3.one * 0.35,
				index % 2 == 0 and CYAN or WHITE,
				0,
				Enum.PartType.Ball
			)
			Effects:Create(mote, inn(0.45), { CFrame = at, Size = Vector3.one * 0.05, Transparency = 1 }):Play()
		end

		return { sigil = sigil, goldDial = goldDial, cyanDial = cyanDial }
	end

	local function warningVfx(cast, groundCF, markerPart, sigil)
		local bars = {}
		local count = 24
		for index = 1, count do
			local angle = (index / count) * math.pi * 2
			local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local pos = groundCF.Position + dir * 6.4 + Vector3.new(0, 0.1, 0)
			local long = index % 2 == 0
			local bar = fxPart(
				cast,
				"DecelerationTick",
				CFrame.lookAt(pos, pos + dir),
				Vector3.new(0.22, 0.1, long and 1.8 or 1),
				CYAN,
				0.45
			)
			bars[index] = { part = bar, dir = dir }
			task.delay(((index - 1) / count) * 0.42, function()
				if bar.Parent then
					bar.Color = GOLD
					bar.Transparency = 0
				end
			end)
		end

		local closing = fxPart(
			cast,
			"DecelerationClosing",
			groundCF * CFrame.new(0, 0.06, 0) * CFrame.Angles(0, 0, math.pi / 2),
			Vector3.new(0.1, 12, 12),
			WHITE,
			0.55,
			Enum.PartType.Cylinder
		)
		Effects:Create(closing, inn(0.5), { Size = Vector3.new(0.1, 2, 2), Transparency = 0.1 }):Play()

		local beam
		if sigil then
			local a0 = Instance.new("Attachment")
			a0.Name = "DecelerationBeamStart"
			a0.Parent = sigil
			local a1 = Instance.new("Attachment")
			a1.Name = "DecelerationBeamEnd"
			a1.Parent = markerPart
			beam = Instance.new("Beam")
			beam.Name = "DecelerationBeam"
			beam.Attachment0 = a0
			beam.Attachment1 = a1
			beam.Color = ColorSequence.new(CYAN, WHITE)
			beam.LightEmission = 1
			beam.LightInfluence = 0
			beam.FaceCamera = true
			beam.Width0 = 0.15
			beam.Width1 = 0.5
			beam.Segments = 12
			beam.CurveSize0 = math.random() < 0.5 and 3 or -3
			beam.CurveSize1 = -beam.CurveSize0
			beam.Transparency = NumberSequence.new(0.3)
			beam.Parent = sigil
		end

		return { bars = bars, closing = closing, beam = beam, ground = groundCF }
	end

	local function bossImpactVfx(root, model, sigilParts)
		if sigilParts then
			Effects:Create(sigilParts.sigil, out(0.25), { Size = Vector3.one * 14, Transparency = 1 }):Play()
			Effects:Create(sigilParts.goldDial, out(0.3), { Size = Vector3.new(0.05, 20, 20), Transparency = 1 }):Play()
			Effects:Create(sigilParts.cyanDial, out(0.3), { Size = Vector3.new(0.05, 14, 14), Transparency = 1 }):Play()
		end

		local cast = Effects.NewCast(actor, "DecelerationImpact", 1.1)
		local ground = groundCFrame(root, model)
		ring(cast, ground, WHITE, 3, 30, 0.45, 0.3)
		task.delay(0.08, function()
			pcall(ring, cast, ground, CYAN, 3, 46, 0.7, 0.3)
		end)
		task.delay(0.16, function()
			pcall(ring, cast, ground, GOLD, 3, 60, 0.85, 0.3)
		end)

		local burst = newEmitter(root, {
			Name = "DecelerationBurst",
			Enabled = false,
			Color = ColorSequence.new(WHITE, CYAN),
			Size = NumberSequence.new({ key(0, 1.2), key(1, 0) }),
			Transparency = NumberSequence.new({ key(0, 0), key(0.7, 0.2), key(1, 1) }),
			Lifetime = NumberRange.new(0.5, 0.9),
			Speed = NumberRange.new(20, 45),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 5,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-180, 180),
		})
		burst:Emit(45)
		Debris:AddItem(burst, 1.5)

		playSound(root, VFX.PulseSoundId, 1.2, 0.9)
		return cast
	end

	local function releaseWarning(mark)
		if mark.beam then
			TweenService:Create(mark.beam, out(0.15), { Width0 = 0, Width1 = 0 }):Play()
		end
		if mark.closing then
			Effects:Create(mark.closing, out(0.2), { Transparency = 1 }):Play()
		end
		for _, entry in ipairs(mark.bars) do
			local to = mark.ground.Position + entry.dir * 13 + Vector3.new(0, 0.1, 0)
			Effects:Create(entry.part, out(0.22), {
				CFrame = CFrame.lookAt(to, to + entry.dir),
				Transparency = 1,
			}):Play()
		end
	end

	local function targetImpactVfx(cast, hrp, groundCF)
		local bubble = fxPart(cast, "DecelerationBubble", hrp.CFrame, Vector3.one * 4, CYAN, 0.5, Enum.PartType.Ball)
		Effects:Create(bubble, out(0.45), { Size = Vector3.one * 17, Transparency = 1 }):Play()
		local flash = fxPart(cast, "DecelerationFlash", hrp.CFrame, Vector3.one * 2, WHITE, 0.1, Enum.PartType.Ball)
		Effects:Create(flash, out(0.25), { Size = Vector3.one * 8, Transparency = 1 }):Play()

		ring(cast, groundCF, GOLD, 3, 18, 0.5, 0.2)

		local sparks = newEmitter(hrp, {
			Name = "DecelerationHitSparks",
			Enabled = false,
			Color = ColorSequence.new(WHITE, CYAN),
			Size = NumberSequence.new({ key(0, 0.9), key(1, 0) }),
			Transparency = NumberSequence.new({ key(0, 0), key(1, 1) }),
			Lifetime = NumberRange.new(0.5, 1),
			Speed = NumberRange.new(8, 18),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 3,
			Rotation = NumberRange.new(0, 360),
		})
		sparks:Emit(30)
		Debris:AddItem(sparks, 1.5)
	end

	local function stopDebuffVfx(motes, highlight)
		if motes then
			motes.Enabled = false
			Debris:AddItem(motes, 2.6)
		end
		if highlight then
			TweenService:Create(highlight, out(0.6), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
			Debris:AddItem(highlight, 0.8)
		end
	end

	local function startDebuffVfx(target, hrp, duration)
		local oldMotes = hrp:FindFirstChild("DecelerationMotes")
		if oldMotes then
			oldMotes:Destroy()
		end
		local oldHighlight = target:FindFirstChild("DecelerationHighlight")
		if oldHighlight then
			oldHighlight:Destroy()
		end

		local motes
		if VFX.MoteAura then
			motes = newEmitter(hrp, {
				Name = "DecelerationMotes",
				Rate = 12,
				Color = ColorSequence.new(CYAN, GOLD),
				Size = NumberSequence.new({ key(0, 0), key(0.3, 0.9), key(1, 0) }),
				Transparency = NumberSequence.new({ key(0, 1), key(0.25, 0.25), key(1, 1) }),
				Lifetime = NumberRange.new(1.5, 2.5),
				Speed = NumberRange.new(0, 1),
				SpreadAngle = Vector2.new(180, 180),
				Acceleration = Vector3.new(0, -1.5, 0),
				Drag = 2,
				Rotation = NumberRange.new(0, 360),
				RotSpeed = NumberRange.new(-20, 20),
			})
		end

		local highlight
		if VFX.TargetHighlight then
			highlight = Instance.new("Highlight")
			highlight.Name = "DecelerationHighlight"
			highlight.Adornee = target
			highlight.FillColor = CYAN
			highlight.FillTransparency = 0.88
			highlight.OutlineColor = GOLD
			highlight.OutlineTransparency = 0.45
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			highlight.Parent = target
		end

		task.spawn(function()
			local started = os.clock()
			local finish = started + duration
			while os.clock() < finish do
				task.wait(0.25)
				if not target.Parent or not core.Alive(target) then
					break
				end
				if os.clock() - started > 0.75 then
					local untilTime = target:GetAttribute("DecelerationUntil")
					if untilTime and untilTime <= workspace:GetServerTimeNow() then
						break
					end
				end
			end
			stopDebuffVfx(motes, highlight)
		end)
	end

	local function createWarning(cast, target, hrp, sigilParts)
		local ground = groundCFrame(hrp, target)
		local marker = cast:Add(core.Part(
			"DecelerationTemporalWarning",
			ground * CFrame.Angles(0, 0, math.pi * 0.5),
			Vector3.new(0.1, 12, 12), CYAN, 0.6
		))
		marker.Shape = Enum.PartType.Cylinder
		local mark = warningVfx(cast, ground, marker, sigilParts and sigilParts.sigil or nil)
		mark.marker = marker
		return mark
	end

	local function releaseTargetWarning(mark)
		if not mark then
			return
		end
		mark.marker.Color = GOLD
		Effects:Create(mark.marker, TweenInfo.new(0.25), {
			Size = Vector3.new(0.08, 24, 24), Transparency = 1,
		}):Play()
		releaseWarning(mark)
	end

	return {
		GroundCFrame = groundCFrame,
		Sigil = sigilVfx,
		CreateWarning = createWarning,
		BossImpact = bossImpactVfx,
		ReleaseWarning = releaseTargetWarning,
		TargetImpact = targetImpactVfx,
		StartDebuff = startDebuffVfx,
	}
end

return table.freeze(Visuals)
