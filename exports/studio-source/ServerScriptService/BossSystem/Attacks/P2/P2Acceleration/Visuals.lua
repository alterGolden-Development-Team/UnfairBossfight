local Style = require(script.Parent.Style)
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local VFX = Style.VFX
local Visuals = {}

local function out(t)
	return TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

local function key(t, v)
	return NumberSequenceKeypoint.new(t, v)
end

function Visuals.new(ctx)
	local actor = ctx.actor
	local core = ctx.core
	local Effects = ctx.Effects
	local GOLD, BRIGHT = Style.GOLD, Style.BRIGHT
	local DEEP = Style.DEEP

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
		local position = hit and (hit.Position + Vector3.new(0, 0.15, 0)) or (root.Position - Vector3.new(0, 3, 0))
		return CFrame.new(position)
	end

	local function ring(cast, groundCF, color, startDiameter, endDiameter, life, thickness)
		local disc = fxPart(
			cast,
			"AccelerationRing",
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

	local function windupVfx(root)
		local cast = Effects.NewCast(actor, "AccelerationWindup", 0.5)
		for index = 1, 16 do
			local angle = (index / 16) * math.pi * 2 + math.random() * 0.4
			local radius = 7 + math.random() * 3
			local height = (math.random() - 0.5) * 6
			local start = root.CFrame * CFrame.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
			local mote = fxPart(
				cast,
				"AccelerationMote",
				start,
				Vector3.one * 0.4,
				index % 2 == 0 and GOLD or BRIGHT,
				0,
				Enum.PartType.Ball
			)
			Effects:Create(mote, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				CFrame = root.CFrame,
				Size = Vector3.one * 0.05,
				Transparency = 1,
			}):Play()
		end
	end

	local function activationVfx(root, model)
		local cast = Effects.NewCast(actor, "AccelerationActivation", 1.1)
		local ground = groundCFrame(root, model)

		local flash = fxPart(cast, "AccelerationFlash", root.CFrame, Vector3.one * 4, BRIGHT, 0, Enum.PartType.Ball)
		Effects:Create(flash, out(0.3), { Size = Vector3.one * 13, Transparency = 1 }):Play()
		local shell = fxPart(cast, "AccelerationShell", root.CFrame, Vector3.one * 3, GOLD, 0.35, Enum.PartType.Ball)
		Effects:Create(shell, out(0.6), { Size = Vector3.one * 24, Transparency = 1 }):Play()

		ring(cast, ground, BRIGHT, 3, 26, 0.5, 0.3)
		task.delay(0.1, function()
			pcall(ring, cast, ground, GOLD, 3, 38, 0.7, 0.3)
		end)
		task.delay(0.2, function()
			pcall(ring, cast, ground, DEEP, 3, 50, 0.85, 0.3)
		end)

		local pillar = fxPart(
			cast,
			"AccelerationPillar",
			CFrame.new(ground.Position + Vector3.new(0, 10, 0)) * CFrame.Angles(0, 0, math.pi / 2),
			Vector3.new(20, 5, 5),
			BRIGHT,
			0.2,
			Enum.PartType.Cylinder
		)
		Effects:Create(pillar, out(0.55), { Size = Vector3.new(34, 0.2, 0.2), Transparency = 1 }):Play()

		for index = 1, 8 do
			local angle = (index / 8) * math.pi * 2
			local x, z = math.cos(angle) * 3.5, math.sin(angle) * 3.5
			local ray = fxPart(
				cast,
				"AccelerationGoldenStreak",
				ground * CFrame.new(x, 2.5, z),
				Vector3.new(0.18, 5, 0.18),
				index % 2 == 0 and GOLD or BRIGHT,
				0.05
			)
			Effects:Create(ray, out(0.6), {
				CFrame = ground * CFrame.new(x, 8, z),
				Size = Vector3.new(0.03, 15, 0.03),
				Transparency = 1,
			}):Play()
		end

		for index = 1, 12 do
			local angle = (index / 12) * math.pi * 2
			local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local from = ground.Position + dir * 2 + Vector3.new(0, 0.25, 0)
			local to = ground.Position + dir * 12 + Vector3.new(0, 0.25, 0)
			local streak = fxPart(
				cast,
				"AccelerationGroundStreak",
				CFrame.lookAt(from, from + dir),
				Vector3.new(0.35, 0.12, 1.5),
				index % 2 == 0 and GOLD or BRIGHT,
				0.05
			)
			Effects:Create(streak, out(0.45), {
				CFrame = CFrame.lookAt(to, to + dir),
				Size = Vector3.new(0.05, 0.05, 9),
				Transparency = 1,
			}):Play()
		end

		local burst = newEmitter(root, {
			Name = "AccelerationBurst",
			Enabled = false,
			Color = ColorSequence.new(BRIGHT, GOLD),
			Size = NumberSequence.new({ key(0, 1.2), key(1, 0) }),
			Transparency = NumberSequence.new({ key(0, 0), key(0.7, 0.2), key(1, 1) }),
			Lifetime = NumberRange.new(0.5, 0.9),
			Speed = NumberRange.new(25, 55),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 5,
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-180, 180),
		})
		burst:Emit(60)
		Debris:AddItem(burst, 1.5)

		playSound(root, VFX.ActivationSoundId, 1.2, 1)
	end

	local function startAura(root, duration)
		local sparks = newEmitter(root, {
			Name = "AccelerationAuraSparks",
			Rate = 45,
			Color = ColorSequence.new(BRIGHT, GOLD),
			Size = NumberSequence.new({ key(0, 0.7), key(1, 0) }),
			Transparency = NumberSequence.new({ key(0, 0.1), key(1, 1) }),
			Lifetime = NumberRange.new(0.5, 0.9),
			Speed = NumberRange.new(3, 8),
			SpreadAngle = Vector2.new(35, 35),
			Acceleration = Vector3.new(0, 10, 0),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-90, 90),
		})
		local embers = newEmitter(root, {
			Name = "AccelerationAuraEmbers",
			Rate = 18,
			Color = ColorSequence.new(GOLD, DEEP),
			Size = NumberSequence.new({ key(0, 1.4), key(1, 0) }),
			Transparency = NumberSequence.new({ key(0, 0.5), key(1, 1) }),
			Lifetime = NumberRange.new(0.6, 1.1),
			Speed = NumberRange.new(0, 2),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 4, 0),
		})

		local top = Instance.new("Attachment")
		top.Name = "AccelerationTrailTop"
		top.Position = Vector3.new(0, 2, 0)
		top.Parent = root
		local bottom = Instance.new("Attachment")
		bottom.Name = "AccelerationTrailBottom"
		bottom.Position = Vector3.new(0, -2, 0)
		bottom.Parent = root
		local trail = Instance.new("Trail")
		trail.Name = "AccelerationTrail"
		trail.Attachment0 = top
		trail.Attachment1 = bottom
		trail.Lifetime = 0.4
		trail.MinLength = 0.05
		trail.LightEmission = 1
		trail.LightInfluence = 0
		trail.FaceCamera = true
		trail.Color = ColorSequence.new(BRIGHT, DEEP)
		trail.Transparency = NumberSequence.new({ key(0, 0.1), key(1, 1) })
		trail.WidthScale = NumberSequence.new({ key(0, 1), key(1, 0) })
		trail.Parent = root

		local light = Instance.new("PointLight")
		light.Name = "AccelerationGlow"
		light.Color = GOLD
		light.Brightness = 8
		light.Range = 22
		light.Parent = root
		TweenService:Create(light, out(0.7), { Brightness = 1.5, Range = 14 }):Play()

		task.delay(duration, function()
			sparks.Enabled = false
			embers.Enabled = false
			trail.Enabled = false
			if light.Parent then
				TweenService:Create(light, out(0.5), { Brightness = 0 }):Play()
			end
		end)
		for _, instance in ipairs({ sparks, embers, trail, top, bottom, light }) do
			Debris:AddItem(instance, duration + 1.5)
		end
	end

	local function afterimage(model)
		local count = 0
		for _, part in ipairs(model:GetDescendants()) do
			if count >= VFX.MaxGhostParts then
				break
			end
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 0.9 then
				local ok, ghost = pcall(function()
					return part:Clone()
				end)
				if ok and ghost then
					count += 1
					for _, child in ipairs(ghost:GetChildren()) do
						if not child:IsA("DataModelMesh") then
							child:Destroy()
						end
					end
					ghost.Name = "AccelerationGhost"
					ghost.Anchored = true
					ghost.CanCollide = false
					ghost.CanQuery = false
					ghost.CanTouch = false
					ghost.CastShadow = false
					ghost.Material = Enum.Material.Neon
					ghost.Color = GOLD
					ghost.Transparency = 0.4
					if ghost:IsA("MeshPart") then
						ghost.TextureID = ""
					end
					ghost.CFrame = part.CFrame
					ghost.Parent = workspace
					TweenService:Create(ghost, out(VFX.AfterimageLife), { Transparency = 1 }):Play()
					Debris:AddItem(ghost, VFX.AfterimageLife + 0.1)
				end
			end
		end
	end

	local function runLoop(root, model, duration)
		task.spawn(function()
			local finish = os.clock() + duration
			local nextPulse = os.clock() + VFX.PulseInterval
			while os.clock() < finish and root.Parent do
				local now = os.clock()
				if VFX.Afterimages and model and model.Parent and root.AssemblyLinearVelocity.Magnitude > 6 then
					afterimage(model)
				end
				if now >= nextPulse then
					nextPulse = now + VFX.PulseInterval
					local cast = Effects.NewCast(actor, "AccelerationPulse", 0.8)
					ring(cast, groundCFrame(root, model), GOLD, 4, 22, 0.6, 0.25)
				end
				task.wait(VFX.AfterimageInterval)
			end
		end)
	end

	return {
		Windup = windupVfx,
		Activate = activationVfx,
		StartAura = startAura,
		RunLoop = runLoop,
	}
end

return table.freeze(Visuals)
