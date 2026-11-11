local Observer = require(script:FindFirstAncestor("BossSystem").Players.PlayerObserver)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Run = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Effects = require(BossSystem.Combat.EffectService)
local Registry = require(BossSystem.Combat.AttackRegistry)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Status = require(BossSystem.Combat.StatusEffectService)
local Encounter = require(BossSystem.Players.PlayerEncounter)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Weapon = require(BossSystem.Boss.WeaponController)
local Locomotion = require(BossSystem.Boss.BossLocomotion)
local Story = require(BossSystem.Encounter.EncounterStory)
local Audio = require(BossSystem.Presentation.CombatAudio)
local api = {}
local running = setmetatable({}, { __mode = "k" })
local visuals = setmetatable({}, { __mode = "k" })
local weaponStates = setmetatable({}, { __mode = "k" })
local gold = Color3.fromRGB(255, 205, 28)
local white = Color3.fromRGB(255, 251, 186)
local ember = Color3.fromRGB(255, 140, 20)
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"

local RECALL = Config.Phase3WaveRecallDuration or 15
local RETURN_SCALE = 0.6
local TURN_HOLD = Config.Phase3WaveTurnHold or 0.3

local function alive(character)
	if Observer.IsCharacter(character) then
		return false
	end
	local h = character and character:FindFirstChildOfClass("Humanoid")
	return character and character.Parent and h and h.Health > 0 and character:FindFirstChild("HumanoidRootPart")
end
local function stamp(actor, name)
	actor:SetAttribute(name, workspace:GetServerTimeNow())
end
local function part(cast, name, frame, size, color, alpha, parent)
	local p = Effects.AcquirePart()
	p.Name = name
	p.CFrame = frame
	p.Size = size
	p.Color = color or gold
	p.Transparency = alpha or 0
	p:SetAttribute("TimeStopExempt", true)
	p.Parent = parent or Runtime.Effects
	if cast then
		cast:Add(p)
	end
	return p
end
local function release(cast, object)
	if not object then
		return
	end
	cast.objects[object] = nil
	for _, child in ipairs(object:GetChildren()) do
		if child:GetAttribute("Phase3Dressing") then
			child:Destroy()
		end
	end
	Effects.Release(object)
end
local function dress(record, instance)
	instance:SetAttribute("Phase3Dressing", true)
	table.insert(record.Dressings, instance)
	return instance
end
local function stage(record, name)
	record.Stage = name
	record.Actor:SetAttribute("Phase3Stage", name)
	record.Actor:SetAttribute("AttackState", "Phase 3: " .. name)
end
local function pose(record, angles, duration)
	record.PoseToken = Locomotion.Pose(record.Actor, angles, duration, true)
end
local function valid(record)
	local actor = record.Actor
	return not record.Cast.closed
		and alive(actor)
		and not actor:GetAttribute("EncounterEnded")
		and actor:GetAttribute("PhaseGeneration") == record.Generation
		and actor:GetAttribute("Phase3IntroActive") == true
end
local function waitFor(record, seconds, step)
	local began = record.Cast:Now()
	while valid(record) do
		local elapsed = record.Cast:Now() - began
		if step then
			step(math.clamp(elapsed / math.max(0.001, seconds), 0, 1))
		end
		if elapsed >= seconds then
			return true
		end
		Run.Heartbeat:Wait()
	end
	return false
end

local function groundAt(position)
	local floor = Placement.GroundPoint(position, { Clamp = true, Margin = 6 })
	return (floor or (position - Vector3.new(0, 2.5, 0))) + Vector3.new(0, 0.25, 0)
end
local function ring(record, position, from, to, duration, color, alpha)
	local disc = part(
		record.Cast,
		"Phase3ShockRing",
		CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(0.2, from, from),
		color or gold,
		alpha or 0.45
	)
	disc.Shape = Enum.PartType.Cylinder
	disc.Material = Enum.Material.Neon
	Effects:Create(disc, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.2, to, to),
		Transparency = 1,
	}):Play()
	record.Cast:Schedule(duration + 0.05, function()
		release(record.Cast, disc)
	end)
	return disc
end
local function pillar(record, position, height, width, duration, color)
	local body = part(
		record.Cast,
		"Phase3LightColumn",
		CFrame.new(position + Vector3.new(0, height * 0.5, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Vector3.new(height, width, width),
		color or gold,
		0.55
	)
	body.Shape = Enum.PartType.Cylinder
	body.Material = Enum.Material.Neon
	Effects:Create(body, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(height * 1.15, width * 0.15, width * 0.15),
		Transparency = 1,
	}):Play()
	record.Cast:Schedule(duration + 0.05, function()
		release(record.Cast, body)
	end)
	return body
end
local function flash(record, parent, brightness, range, duration)
	local light = Instance.new("PointLight")
	light.Name = "Phase3Flash"
	light.Color = gold
	light.Brightness = brightness
	light.Range = range
	light.Parent = parent
	record.Cast:Add(light)
	TweenService
		:Create(light, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 })
		:Play()
	record.Cast:Schedule(duration + 0.05, function()
		release(record.Cast, light)
	end)
end
local function sparkBurst(record, parent, count, minSpeed, maxSpeed, lift)
	local anchor = Instance.new("Attachment")
	anchor.Name = "Phase3SparkBurst"
	anchor.Parent = parent
	record.Cast:Add(anchor)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Phase3Sparks"
	emitter.Texture = SPARKLE
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, white),
		ColorSequenceKeypoint.new(0.5, gold),
		ColorSequenceKeypoint.new(1, ember),
	})
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Lifetime = NumberRange.new(0.5, 1.2)
	emitter.Speed = NumberRange.new(minSpeed, maxSpeed)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, lift and 12 or -14, 0)
	emitter.Drag = 1.2
	emitter.Rate = 0
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(0.25, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter:SetAttribute("TimeStopExempt", true)
	emitter.Parent = anchor
	emitter:Emit(count)
	record.Cast:Schedule(1.4, function()
		release(record.Cast, anchor)
	end)
end

local function roar(record, bounds)
	stage(record, "Roar")
	pose(record, { RightShoulder = { -30, 0, 72 }, LeftShoulder = { -30, 0, -72 }, Waist = { -18, 0, 0 } }, 0.2)
	if not waitFor(record, 0.3) then
		return false
	end
	local origin = record.Core.Root.Position
	stamp(record.Actor, "Phase3RoarAt")
	Audio.Emit(record.Actor, "Roar", record.Core.Root)
	record.Core.ScreenEffect(
		"Shake",
		{ Origin = origin, Radius = math.max(bounds.Width, bounds.Depth) * 1.5, Duration = 1.3, Intensity = 2.8 }
	)
	local glow = Instance.new("Highlight")
	glow.Name = "TransformationRoarEnergy"
	glow.Adornee = record.Actor
	glow.FillColor = gold
	glow.FillTransparency = 0.6
	glow.OutlineColor = gold
	glow.OutlineTransparency = 0.1
	glow.Parent = record.Actor
	record.Cast:Add(glow)
	TweenService:Create(
		glow,
		TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FillTransparency = 1, OutlineTransparency = 0.8 }
	):Play()
	local anchor = Instance.new("Attachment")
	anchor.Name = "TransformationRoarSparks"
	anchor.Parent = record.Core.Root
	record.Cast:Add(anchor)
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "GoldenRoarBurst"
	sparks.Texture = SPARKLE
	sparks.Color = ColorSequence.new(gold, Color3.fromRGB(255, 227, 74))
	sparks.LightEmission = 1
	sparks.Lifetime = NumberRange.new(0.45, 1.1)
	sparks.Speed = NumberRange.new(14, 32)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Rate = 0
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.2, 0.65),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks:SetAttribute("TimeStopExempt", true)
	sparks.Parent = anchor
	sparks:Emit(55)
	local rising = Instance.new("ParticleEmitter")
	rising.Name = "GoldenRoarEmbers"
	rising.Texture = SPARKLE
	rising.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, white),
		ColorSequenceKeypoint.new(1, ember),
	})
	rising.LightEmission = 1
	rising.LightInfluence = 0
	rising.Lifetime = NumberRange.new(0.9, 1.6)
	rising.Speed = NumberRange.new(4, 12)
	rising.SpreadAngle = Vector2.new(40, 40)
	rising.Acceleration = Vector3.new(0, 16, 0)
	rising.Rate = 0
	rising.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.3, 0.7),
		NumberSequenceKeypoint.new(1, 0),
	})
	rising:SetAttribute("TimeStopExempt", true)
	rising.Parent = anchor
	rising:Emit(40)
	for index = 1, 3 do
		local delay = 0.02 + (index - 1) * 0.12
		record.Cast:Schedule(delay, function()
			ring(record, origin - Vector3.new(0, 2.4 - index * 0.4, 0), 5, 90 + index * 40, 1.2, gold, 0.45)
		end)
	end
	ring(record, origin - Vector3.new(0, 2.2, 0), 4, 60, 0.7, white, 0.25)
	pillar(record, origin - Vector3.new(0, 2.6, 0), 60, 8, 1.1)
	flash(record, record.Core.Root, 6, 40, 0.9)
	record.Cast:Schedule(1.25, function()
		release(record.Cast, glow)
		release(record.Cast, anchor)
	end)
	return waitFor(record, 1.3)
end

local function cross(a, b)
	return a.X * b.Z - a.Z * b.X
end
local function segmentDistance(point, a, b)
	local delta = b - a
	local squared = delta:Dot(delta)
	local alpha = squared > 1e-8 and math.clamp((point - a):Dot(delta) / squared, 0, 1) or 0
	return (point - a - delta * alpha).Magnitude
end
local function sweptSegmentContains(point, segment, first, last, padding)
	local a, b = segment.Start * first, segment.Finish * first
	local c, d = segment.Finish * last, segment.Start * last
	local s1, s2, s3, s4 =
		cross(b - a, point - a), cross(c - b, point - b), cross(d - c, point - c), cross(a - d, point - d)
	local inside = (s1 >= 0 and s2 >= 0 and s3 >= 0 and s4 >= 0) or (s1 <= 0 and s2 <= 0 and s3 <= 0 and s4 <= 0)
	return inside and math.abs(last - first) > 1e-5
		or segmentDistance(point, a, b) <= padding
		or segmentDistance(point, b, c) <= padding
		or segmentDistance(point, c, d) <= padding
		or segmentDistance(point, d, a) <= padding
end
function api.WaveContains(point, wave, previousRadius)
	if not wave or not wave.Active then
		return false
	end
	local p = wave.Frame:PointToObjectSpace(point)
	if math.abs(p.X) > wave.HalfX or math.abs(p.Z) > wave.HalfZ or p.Y < -0.5 or p.Y >= (wave.Height or 6) + 3 then
		return false
	end
	local center = wave.Center or Vector3.zero
	p = Vector3.new(p.X - center.X, 0, p.Z - center.Z)
	local previous = previousRadius or wave.Radius
	local first, last = math.min(previous, wave.Radius), math.max(previous, wave.Radius)
	local distance = p.Magnitude
	if distance < first * 0.70 - wave.Width * 0.5 - 1.25 or distance > last * 1.08 + wave.Width * 0.5 + 1.25 then
		return false
	end
	for _, segment in ipairs(wave.Segments) do
		if sweptSegmentContains(p, segment, first, last, wave.Width * 0.5 + 1.25) then
			return true
		end
	end
	return false
end

local function snapshotWeapon(record)
	local sword = Weapon.Get(record.Actor)
	local handle = sword and sword:FindFirstChild("Handle")
	if not sword or not handle or not handle:IsA("BasePart") then
		return nil
	end
	local data = { Sword = sword, Handle = handle, Parts = {}, Controls = {} }
	for _, object in ipairs(sword:GetDescendants()) do
		if object:IsA("BasePart") then
			local state =
				{ Part = object, Transparency = object.Transparency, Color = object.Color, Material = object.Material }
			if object:IsA("MeshPart") then
				state.TextureID = object.TextureID
			end
			local mesh = object:FindFirstChildOfClass("SpecialMesh")
			if mesh then
				state.Mesh = mesh
				state.TextureId = mesh.TextureId
				state.VertexColor = mesh.VertexColor
			end
			table.insert(data.Parts, state)
		elseif object:IsA("Trail") or object:IsA("ParticleEmitter") then
			table.insert(data.Controls, { Object = object, Enabled = object.Enabled })
		end
	end
	record.Weapon = data
	return data
end
local function restoreWeapon(record)
	for _, tween in ipairs(record.WeaponTweens or {}) do
		tween:Cancel()
	end
	for _, state in ipairs(record.Weapon and record.Weapon.Parts or {}) do
		local p = state.Part
		if p.Parent then
			p.Transparency = state.Transparency
			p.Color = state.Color
			p.Material = state.Material
			if state.TextureID then
				p.TextureID = state.TextureID
			end
			if state.Mesh and state.Mesh.Parent then
				state.Mesh.TextureId = state.TextureId
				state.Mesh.VertexColor = state.VertexColor
			end
		end
	end
	for _, state in ipairs(record.Weapon and record.Weapon.Controls or {}) do
		if state.Object.Parent then
			state.Object.Enabled = state.Enabled
		end
	end
	Weapon.SetUnarmed(record.Actor, false)
end
local function discardWeapon(record)
	local data = snapshotWeapon(record)
	if not data then
		return true
	end
	stage(record, "Discard sword")
	pose(record, { RightShoulder = { 20, 0, 105 }, Waist = { 0, -20, 0 } }, 0.25)
	if not waitFor(record, 0.25) then
		return false
	end
	local thrown = Instance.new("Model")
	thrown.Name = "Phase3DiscardedSword"
	thrown.Parent = Runtime.Effects
	record.Cast:Add(thrown)
	local pieces = {}
	local origin = data.Handle.CFrame
	for _, state in ipairs(data.Parts) do
		local source = state.Part
		local p =
			part(nil, "Discarded" .. source.Name, source.CFrame, source.Size, source.Color, source.Transparency, thrown)
		p.Material = source.Material
		local mesh = source:FindFirstChildOfClass("SpecialMesh")
		if mesh then
			mesh:Clone().Parent = p
		end
		if source:IsA("Part") then
			p.Shape = source.Shape
		end
		table.insert(pieces, { Part = p, Offset = origin:ToObjectSpace(source.CFrame) })
	end
	local trail
	if pieces[1] then
		trail = Instance.new("ParticleEmitter")
		trail.Name = "DiscardedSwordTrail"
		trail.Texture = SPARKLE
		trail.Color = ColorSequence.new(white, gold)
		trail.LightEmission = 1
		trail.LightInfluence = 0
		trail.Lifetime = NumberRange.new(0.35, 0.8)
		trail.Speed = NumberRange.new(0, 3)
		trail.SpreadAngle = Vector2.new(180, 180)
		trail.Rate = 55
		trail.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.55),
			NumberSequenceKeypoint.new(1, 0),
		})
		trail:SetAttribute("TimeStopExempt", true)
		trail.Parent = pieces[1].Part
	end
	for _, state in ipairs(data.Controls) do
		state.Object.Enabled = false
	end
	Weapon.SetUnarmed(record.Actor, true)
	for _, state in ipairs(data.Parts) do
		local p = state.Part
		p.Transparency = state.Transparency
		p.Material = Enum.Material.Neon
		p.Color = p.Name == "Handle" and gold or white
		if p:IsA("MeshPart") then
			p.TextureID = ""
		end
		if state.Mesh then
			state.Mesh.TextureId = ""
			state.Mesh.VertexColor = Vector3.new(1, 0.88, 0.32)
		end
	end
	stamp(record.Actor, "Phase3SwordDiscardedAt")
	local start = record.Cast:Now()
	local endPosition = origin.Position + record.MotionFrame.RightVector * 25 + record.MotionFrame.LookVector * 8
	local floor = Placement.GroundPoint(endPosition, { Clamp = true, Margin = 6 })
	endPosition = floor and floor + Vector3.new(0, 0.6, 0) or endPosition
	local landed = false
	record.Cast:Step(function(_, now)
		if not thrown.Parent then
			return false
		end
		local age = now - start
		local progress = math.min(age / 1.1, 1)
		local position = origin.Position:Lerp(endPosition, progress)
			+ Vector3.new(0, math.sin(progress * math.pi) * 17, 0)
		local frame = CFrame.new(position) * origin.Rotation * CFrame.Angles(0, 0, progress * math.pi * 2.7)
		for _, piece in ipairs(pieces) do
			piece.Part.CFrame = frame * piece.Offset
			if age > 3 then
				piece.Part.Transparency = math.clamp((age - 3) / 0.8, 0, 1)
			end
		end
		if progress >= 1 and not landed then
			landed = true
			if trail then
				trail.Enabled = false
			end
			ring(record, endPosition - Vector3.new(0, 0.35, 0), 3, 30, 0.55, white, 0.4)
			if pieces[1] then
				sparkBurst(record, pieces[1].Part, 26, 8, 22, false)
			end
		end
		if age >= 3.8 then
			if trail then
				trail:Destroy()
			end
			release(record.Cast, thrown)
			return false
		end
		return true
	end)
	return waitFor(record, 0.65)
end

local function attached(model, name, body, offset, size, color, alpha)
	local p = part(nil, name, body.CFrame * offset, size, color, alpha, model)
	p.Anchored = false
	p.Massless = true
	local weld = Instance.new("WeldConstraint")
	weld.Name = "Phase3Attachment"
	weld.Part0 = body
	weld.Part1 = p
	weld.Parent = p
	return p
end
local function shoulderEndpoint(actor, armName, jointName)
	local arm = actor:FindFirstChild(armName)
	if arm and arm:IsA("BasePart") then
		return arm
	end
	for _, joint in ipairs(actor:GetDescendants()) do
		if joint:IsA("Motor6D") and (joint.Name == jointName or joint.Name == armName:gsub(" Arm", " Shoulder")) then
			local endpoint = joint.Part1
			if endpoint and endpoint:IsDescendantOf(actor) then
				return endpoint
			end
		end
	end
end
local function transform(record)
	stage(record, "Transformation")
	Audio.Emit(record.Actor, "Phase3Transform", record.Core.Root)
	local torso = record.Actor:FindFirstChild("Torso") or record.Actor:FindFirstChild("UpperTorso") or record.Core.Root
	local arms = {
		shoulderEndpoint(record.Actor, "Right Arm", "RightShoulder"),
		shoulderEndpoint(record.Actor, "Left Arm", "LeftShoulder"),
	}
	local aura = Instance.new("Model")
	aura.Name = "Phase3GoldenRegalia"
	aura:SetAttribute("BossFormVisual", true)
	aura.Parent = record.Actor
	record.Cast:Add(aura)
	record.Aura = aura
	for _, arm in pairs(arms) do
		if arm then
			local emitterPart =
				attached(aura, "GoldenArmFlame", arm, CFrame.new(0, -0.2, 0), Vector3.new(0.8, 1.2, 0.8), white, 1)
			local emitter = Instance.new("ParticleEmitter")
			emitter.Name = "GoldenMagicFlame"
			emitter.Texture = SPARKLE
			emitter.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, white),
				ColorSequenceKeypoint.new(0.45, gold),
				ColorSequenceKeypoint.new(1, ember),
			})
			emitter.LightEmission = 1
			emitter.LightInfluence = 0
			emitter.Lifetime = NumberRange.new(0.35, 0.8)
			emitter.Rate = 36
			emitter.Speed = NumberRange.new(1, 3)
			emitter.Acceleration = Vector3.new(0, 8, 0)
			emitter.SpreadAngle = Vector2.new(35, 35)
			emitter.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.4),
				NumberSequenceKeypoint.new(0.35, 1.15),
				NumberSequenceKeypoint.new(1, 0),
			})
			emitter.Transparency =
				NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
			emitter:SetAttribute("TimeStopExempt", true)
			emitter.Parent = emitterPart
			local light = Instance.new("PointLight")
			light.Color = gold
			light.Range = 8
			light.Brightness = 1.5
			light.Parent = emitterPart
		end
	end
	local embersPart = attached(aura, "GoldenTorsoEmbers", torso, CFrame.new(), Vector3.new(2, 2.4, 1.2), white, 1)
	local drift = Instance.new("ParticleEmitter")
	drift.Name = "GoldenTorsoEmbers"
	drift.Texture = SPARKLE
	drift.Color = ColorSequence.new(white, gold)
	drift.LightEmission = 1
	drift.LightInfluence = 0
	drift.Lifetime = NumberRange.new(0.9, 1.7)
	drift.Rate = 14
	drift.Speed = NumberRange.new(0.5, 2)
	drift.Acceleration = Vector3.new(0, 6, 0)
	drift.SpreadAngle = Vector2.new(25, 25)
	drift.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.3, 0.55),
		NumberSequenceKeypoint.new(1, 0),
	})
	drift.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	drift:SetAttribute("TimeStopExempt", true)
	drift.Parent = embersPart
	stamp(record.Actor, "Phase3TransformationStartedAt")
	pose(record, { RightShoulder = { 0, 0, 45 }, LeftShoulder = { 0, 0, -45 }, Waist = { -5, 0, 0 } }, 0.6)
	local rootPosition = record.Core.Root.Position
	local ground = groundAt(rootPosition)
	ring(record, ground, 4, 70, 1.1, gold, 0.5)
	pillar(record, ground, 70, 9, 1.4)
	flash(record, record.Core.Root, 5, 36, 1.2)
	record.Cast:Schedule(0.7, function()
		ring(record, ground, 4, 110, 0.9, white, 0.4)
	end)
	if not waitFor(record, 1.5) then
		return false
	end
	ring(record, ground, 6, 150, 0.8, white, 0.35)
	pillar(record, ground, 90, 12, 0.9, white)
	sparkBurst(record, record.Core.Root, 60, 18, 40, true)
	flash(record, record.Core.Root, 8, 48, 0.8)
	record.Core.ScreenEffect("Shake", { Origin = rootPosition, Radius = 120, Duration = 0.6, Intensity = 1.6 })
	Weapon.SetUnarmed(record.Actor, true)
	pose(record, { RightShoulder = { -20, 0, 20 }, LeftShoulder = { -20, 0, -20 } }, 0.25)
	stamp(record.Actor, "Phase3UnarmedFormAt")
	return waitFor(record, 0.25)
end

local function jumpCenter(record, bounds)
	stage(record, "Center jump")
	local current = record.MotionFrame
	local desired = CFrame.new(bounds.Frame.Position) * current.Rotation
	local center = Placement.Validate(record.Actor, desired, { Margin = 8 })
	if not center then
		return false
	end
	local peak = CFrame.new(center.Position + Vector3.new(0, Config.Phase3JumpHeight, 0)) * current.Rotation
	ring(record, groundAt(current.Position), 4, 34, 0.5, white, 0.5)
	flash(record, record.Core.Root, 3, 24, 0.4)
	pose(record, {
		RightShoulder = { -125, 0, 25 },
		LeftShoulder = { -30, 0, -25 },
		RightHip = { -35, 0, 0 },
		LeftHip = {
			-20,
			0,
			0,
		},
	}, 0.25)
	if
		not waitFor(record, Config.Phase3JumpAscent, function(t)
			local eased = 1 - (1 - t) ^ 3
			record.MotionFrame = current:Lerp(peak, eased)
		end)
	then
		return false
	end
	pose(record, { RightShoulder = { 70, 0, 20 }, LeftShoulder = { 20, 0, -20 }, Waist = { 25, 0, 0 } }, 0.12)
	if
		not waitFor(record, Config.Phase3JumpDescent, function(t)
			record.MotionFrame = peak:Lerp(center, t * t)
		end)
	then
		return false
	end
	record.MotionFrame = center
	record.Core.Root.CFrame = center
	stage(record, "Center impact")
	stamp(record.Actor, "Phase3CenterImpactAt")
	record.Core.ScreenEffect(
		"Shake",
		{ Origin = center.Position, Radius = math.max(bounds.Width, bounds.Depth), Duration = 0.65, Intensity = 2.1 }
	)
	local ground = groundAt(center.Position)
	ring(record, ground, 5, 100, 0.65, gold, 0.45)
	ring(record, ground, 3, 55, 0.45, white, 0.3)
	record.Cast:Schedule(0.12, function()
		ring(record, ground, 3, 80, 0.55, gold, 0.5)
	end)
	pillar(record, ground, 40, 10, 0.7)
	sparkBurst(record, record.Core.Root, 45, 14, 34, false)
	flash(record, record.Core.Root, 7, 44, 0.6)
	return waitFor(record, 0.3)
end

local function previewWave(record, wave)
	local pieces = {}
	local center = wave.Center or Vector3.zero
	for _, segment in ipairs(wave.Segments) do
		local a = wave.Frame:PointToWorldSpace(segment.Start * 15 + center + Vector3.new(0, 0.15, 0))
		local b = wave.Frame:PointToWorldSpace(segment.Finish * 15 + center + Vector3.new(0, 0.15, 0))
		local warning = part(
			record.Cast,
			"Phase3WaveTelegraph",
			CFrame.lookAt((a + b) * 0.5, b),
			Vector3.new(0.65, 0.12, (b - a).Magnitude),
			Color3.fromRGB(196, 145, 48),
			0.85
		)
		warning.Material = Enum.Material.Neon
		Effects:Create(
			warning,
			TweenInfo.new(Config.Phase3WaveWarning, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Transparency = 0.3 }
		):Play()
		table.insert(pieces, warning)
	end
	for _, opening in ipairs(wave.Openings) do
		local direction = Vector3.new(math.cos(opening.Angle), 0, math.sin(opening.Angle))
		for index = 1, 3 do
			local at = wave.Frame:PointToWorldSpace(direction * (12 + index * 10) + center + Vector3.new(0, 0.12, 0))
			local mark = part(
				record.Cast,
				"Phase3WaveSafeOpening",
				CFrame.lookAt(at, at + wave.Frame:VectorToWorldSpace(direction)),
				Vector3.new(1.25, 0.09, 4),
				Color3.fromRGB(115, 186, 148),
				0.38
			)
			mark.Material = Enum.Material.Neon
			table.insert(pieces, mark)
		end
	end
	return pieces
end

local function releaseWaveParts(record, wave)
	for _, data in ipairs(wave.Parts) do
		release(record.Cast, data.Part)
		release(record.Cast, data.Rim)
		release(record.Cast, data.Glow)
	end
	table.clear(wave.Parts)
end
local function pulse(record, gravity)
	local glow = gravity.Pulse
	if not glow or not glow.Parent then
		return
	end
	gravity.PulseToken = (gravity.PulseToken or 0) + 1
	local token = gravity.PulseToken
	glow.FillTransparency = 0.45
	glow.OutlineTransparency = 0
	record.Cast:Schedule(0.18, function()
		if gravity.PulseToken == token and glow.Parent then
			glow.FillTransparency = 1
			glow.OutlineTransparency = 1
		end
	end)
end
local function absorb(record, wave)
	local gravity = record.Gravity
	local at = wave.Frame:PointToWorldSpace((wave.Center or Vector3.zero) + Vector3.new(0, 0.3, 0))
	ring(record, at, 28, 4, 0.45, white, 0.25)
	stamp(record.Actor, "Phase3WaveReturnedAt")
	Audio.Emit(record.Actor, "Phase2WaveRelease", record.Core.Root, { VolumeScale = 0.35 })
	flash(record, record.Core.Root, 2.5, 18, 0.35)
	if gravity then
		if gravity.Burst and gravity.Burst.Parent then
			gravity.Burst:Emit(18)
		end
		pulse(record, gravity)
	end
	record.Actor:SetAttribute("Phase3WavesReturned", (record.Actor:GetAttribute("Phase3WavesReturned") or 0) + 1)
end
local function turnFlare(record, gravity, wave)
	for _, data in ipairs(wave.Parts) do
		data.Part.Color = Color3.fromRGB(226, 198, 118)
		data.Rim.Color = white
		data.Rim.Transparency = 0.1
		if data.Embers and data.Embers.Parent then
			data.Embers:Emit(14)
		end
	end
	stamp(record.Actor, "Phase3WaveTurnedAt")
	Audio.Emit(record.Actor, "Phase2WaveWarning", record.Core.Root, { VolumeScale = 0.4 })
	if not gravity.Recall then
		gravity.Recall = true
		stamp(record.Actor, "Phase3RecallStartedAt")
		record.Actor:SetAttribute("Phase3RecallActive", true)
		if gravity.Pull then
			gravity.Pull.Rate = 85
		end
		pose(record, { RightShoulder = { -75, 0, 30 }, LeftShoulder = { -75, 0, -30 }, Waist = { 12, 0, 0 } }, 0.25)
		flash(record, record.Core.Root, 4, 30, 0.6)
		ring(record, groundAt(record.Core.Root.Position), 90, 6, 1.0, white, 0.55)
	end
end

local function beginWave(record, gravity, index)
	if not valid(record) or not gravity.Active then
		return
	end
	local sides = record.Random:NextInteger(Config.Phase3WaveSidesMin, Config.Phase3WaveSidesMax)
	local spacing = math.pi * 2 / sides
	local angle = (gravity.FirstGap + (index - 1) * 2.3999632297) % (math.pi * 2)
	local rotation = angle - spacing * 0.5
	local wave = {
		Frame = gravity.Frame,
		Center = gravity.Center,
		HalfX = gravity.HalfX,
		HalfZ = gravity.HalfZ,
		Width = Config.Phase3WaveWidth,
		Height = Config.Phase3WaveHeight,
		Radius = 5,
		Previous = 5,
		Active = false,
		Warning = true,
		Mode = "Out",
		Parts = {},
		Segments = {},
		Hit = {},
		Index = index,
		Openings = { { Angle = angle, Width = spacing } },
		Sides = sides,
	}
	local omitted = { [1] = true }
	if index % 3 == 0 then
		local opposite = math.floor(sides * 0.5) + 1
		omitted[opposite] = true
		table.insert(wave.Openings, { Angle = (angle + (opposite - 1) * spacing) % (math.pi * 2), Width = spacing })
	end
	local vertices = {}
	for vertex = 1, sides do
		local a = rotation + (vertex - 1) * spacing
		local scale = record.Random:NextNumber(0.93, 1.07)
		vertices[vertex] = Vector3.new(math.cos(a) * scale, 0, math.sin(a) * scale)
	end
	for side = 1, sides do
		if not omitted[side] then
			local a, b = vertices[side], vertices[side % sides + 1]
			local inset = Config.Phase3WaveSegmentInset
			table.insert(wave.Segments, { Start = a:Lerp(b, inset), Finish = a:Lerp(b, 1 - inset) })
		end
	end
	table.insert(gravity.Waves, wave)
	record.Actor:SetAttribute("Phase3WaveGapAngle", angle)
	record.Actor:SetAttribute("Phase3WaveWarningIndex", index)
	stamp(record.Actor, "Phase3WaveWarningAt")
	Audio.Emit(record.Actor, "Phase2WaveWarning", record.Core.Root, { VolumeScale = 0.5 })
	local cue = Instance.new("Highlight")
	cue.Name = "Phase3WaveHandCue"
	cue.Adornee = record.Actor:FindFirstChild("Right Arm") or record.Actor
	cue.FillColor = gold
	cue.OutlineColor = gold
	cue.FillTransparency = 0.65
	cue.OutlineTransparency = 0.1
	cue.DepthMode = Enum.HighlightDepthMode.Occluded
	cue.Parent = record.Actor
	record.Cast:Add(cue)
	local previews = previewWave(record, wave)
	record.Cast:Schedule(Config.Phase3WaveWarning, function()
		release(record.Cast, cue)
		for _, preview in ipairs(previews) do
			release(record.Cast, preview)
		end
		if not valid(record) or not gravity.Active then
			return
		end
		wave.Warning = false
		wave.Active = true
		wave.ReleaseAt = record.Cast:Now()
		record.Actor:SetAttribute("Phase3WavesReleased", index)
		stamp(record.Actor, "Phase3WaveReleasedAt")
		Audio.Emit(record.Actor, "Phase2WaveRelease", record.Core.Root, { VolumeScale = 0.6 })
		for _, segment in ipairs(wave.Segments) do
			local body = part(
				record.Cast,
				"Phase3SegmentedPolygonWave",
				CFrame.identity,
				Vector3.new(wave.Width, wave.Height, 1),
				Color3.fromRGB(196, 141, 37),
				0.64
			)
			body.Material = Enum.Material.SmoothPlastic
			local rim = part(
				record.Cast,
				"Phase3WaveLeadingEdge",
				CFrame.identity,
				Vector3.one,
				Color3.fromRGB(240, 196, 66),
				0.25
			)
			rim.Material = Enum.Material.Neon
			local glow = part(
				record.Cast,
				"Phase3WaveGroundGlow",
				CFrame.identity,
				Vector3.one,
				Color3.fromRGB(255, 214, 92),
				0.72
			)
			glow.Material = Enum.Material.Neon
			local embers = dress(record, Instance.new("ParticleEmitter"))
			embers.Name = "WaveEdgeEmbers"
			embers.Texture = SPARKLE
			embers.Color = ColorSequence.new(white, gold)
			embers.LightEmission = 1
			embers.LightInfluence = 0
			embers.Lifetime = NumberRange.new(0.3, 0.7)
			embers.Rate = 30
			embers.Speed = NumberRange.new(2, 7)
			embers.Acceleration = Vector3.new(0, 6, 0)
			embers.SpreadAngle = Vector2.new(25, 25)
			embers.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 0),
			})
			embers:SetAttribute("TimeStopExempt", true)
			embers.Parent = rim
			table.insert(wave.Parts, { Segment = segment, Part = body, Rim = rim, Glow = glow, Embers = embers })
		end
		local limit = math.sqrt(gravity.HalfX ^ 2 + gravity.HalfZ ^ 2) + wave.Width
		local outer = 5 + limit
		local travel = limit / Config.Phase3WaveSpeed
		local returnTravel = limit / (Config.Phase3WaveReturnSpeed or Config.Phase3WaveSpeed * RETURN_SCALE)
		local returnDamage = Config.Phase3WaveReturnDamage or Config.Phase3WaveDamage
		wave.TravelDuration = travel
		wave.ReturnDuration = returnTravel
		record.Cast:Step(function(_, now)
			if not gravity.Active or not valid(record) then
				return false
			end
			local previous = wave.Radius
			if wave.Mode == "Out" then
				local progress = math.min((now - wave.ReleaseAt) / travel, 1)
				wave.Radius = 5 + limit * progress
				if progress >= 1 then
					wave.Mode = "Turn"
					wave.ModeAt = now
					table.clear(wave.Hit)
					turnFlare(record, gravity, wave)
				end
			elseif wave.Mode == "Turn" then
				wave.Radius = outer
				if now - wave.ModeAt >= TURN_HOLD then
					wave.Mode = "Return"
					wave.ModeAt = now
				end
			else
				local progress = math.min((now - wave.ModeAt) / returnTravel, 1)
				wave.Radius = outer - limit * progress
				if progress >= 1 then
					wave.Active = false
					wave.Finished = true
					absorb(record, wave)
					releaseWaveParts(record, wave)
					table.clear(wave.Hit)
					return false
				end
			end
			wave.Previous = previous
			local center = wave.Center or Vector3.zero
			for _, data in ipairs(wave.Parts) do
				local a, b = data.Segment.Start * wave.Radius + center, data.Segment.Finish * wave.Radius + center
				local start = wave.Frame:PointToWorldSpace(a + Vector3.new(0, wave.Height * 0.5, 0))
				local finish = wave.Frame:PointToWorldSpace(b + Vector3.new(0, wave.Height * 0.5, 0))
				local length = (finish - start).Magnitude
				data.Part.CFrame = CFrame.lookAt((start + finish) * 0.5, finish)
				data.Part.Size = Vector3.new(wave.Width, wave.Height, length)
				data.Rim.CFrame = data.Part.CFrame * CFrame.new(0, wave.Height * 0.5 - 0.15, 0)
				data.Rim.Size = Vector3.new(math.min(0.65, wave.Width), 0.28, length)
				local groundStart = wave.Frame:PointToWorldSpace(a + Vector3.new(0, 0.12, 0))
				local groundFinish = wave.Frame:PointToWorldSpace(b + Vector3.new(0, 0.12, 0))
				data.Glow.CFrame = CFrame.lookAt((groundStart + groundFinish) * 0.5, groundFinish)
				data.Glow.Size = Vector3.new(wave.Width * 2.4, 0.1, length)
			end
			if wave.Mode ~= "Turn" then
				local damage = wave.Mode == "Return" and returnDamage or Config.Phase3WaveDamage
				for _, character in ipairs(Runtime.Characters()) do
					if
						alive(character)
						and not wave.Hit[character]
						and api.WaveContains(character.HumanoidRootPart.Position, wave, previous)
					then
						wave.Hit[character] = true
						local amount = Encounter.Damage(character, damage, record.Actor)
						if amount > 0 then
							record.Actor:SetAttribute(
								"Phase3WaveHits",
								(record.Actor:GetAttribute("Phase3WaveHits") or 0) + 1
							)
						end
					end
				end
			end
			return true
		end)
	end)
end

local function releaseField(record)
	local gravity = record.Gravity
	if not gravity then
		return
	end
	gravity.Active = false
	for character, data in pairs(gravity.Players) do
		Status.RemoveZoneSlow(character, record.Cast)
		Status.SetJumpDisabled(character, record.Cast, false)
	end
	table.clear(gravity.Players)
	for _, wave in ipairs(gravity.Waves) do
		wave.Active = false
		wave.Warning = false
		releaseWaveParts(record, wave)
		table.clear(wave.Hit)
	end
	Status.RemoveZoneSlow(record.Cast)
	if record.Actor.Parent and running[record.Actor] == record then
		record.Actor:SetAttribute("Phase3GravityActive", false)
		record.Actor:SetAttribute("Phase3RecallActive", false)
	end
end
local function gravityField(record, bounds)
	stage(record, "Gravity")
	local total = Config.Phase3GravityDuration + RECALL
	local gravity = {
		Frame = bounds.Frame,
		HalfX = bounds.HalfX - 4,
		HalfZ = bounds.HalfZ - 4,
		Center = bounds.Frame:PointToObjectSpace(record.MotionFrame.Position) * Vector3.new(1, 0, 1),
		Players = {},
		Waves = {},
		Active = true,
		Recall = false,
		FirstGap = record.Random:NextNumber(0, math.pi * 2),
	}
	record.Gravity = gravity
	record.Actor:SetAttribute("Phase3GravityActive", true)
	record.Actor:SetAttribute("Phase3RecallActive", false)
	stamp(record.Actor, "Phase3GravityStartedAt")
	record.Actor:SetAttribute("Phase3GravityEndsAt", workspace:GetServerTimeNow() + total)
	local floor =
		part(record.Cast, "Phase3GlobalGravityMote", bounds.Frame * CFrame.new(0, 0.3, 0), Vector3.one, gold, 0.65)
	local strips = {}
	local function strip(offset, size)
		local s = part(
			record.Cast,
			"Phase3GravityBoundary",
			bounds.Frame * CFrame.new(offset.X, 0.2, offset.Z),
			size,
			gold,
			0.55
		)
		s.Material = Enum.Material.Neon
		table.insert(strips, s)
	end
	strip(Vector3.new(gravity.HalfX, 0, 0), Vector3.new(0.6, 0.12, gravity.HalfZ * 2))
	strip(Vector3.new(-gravity.HalfX, 0, 0), Vector3.new(0.6, 0.12, gravity.HalfZ * 2))
	strip(Vector3.new(0, 0, gravity.HalfZ), Vector3.new(gravity.HalfX * 2, 0.12, 0.6))
	strip(Vector3.new(0, 0, -gravity.HalfZ), Vector3.new(gravity.HalfX * 2, 0.12, 0.6))
	local vortex = part(
		record.Cast,
		"Phase3GravityVortex",
		CFrame.new(record.MotionFrame.Position),
		Vector3.new(56, 56, 56),
		gold,
		1
	)
	local pull = dress(record, Instance.new("ParticleEmitter"))
	pull.Name = "GravityPull"
	pull.Texture = SPARKLE
	pull.Shape = Enum.ParticleEmitterShape.Sphere
	pull.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	pull.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
	pull.Color = ColorSequence.new(white, gold)
	pull.LightEmission = 1
	pull.LightInfluence = 0
	pull.Lifetime = NumberRange.new(1.8, 2.0)
	pull.Speed = NumberRange.new(14, 15.5)
	pull.Rate = 35
	pull.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.15, 0.7),
		NumberSequenceKeypoint.new(1, 0),
	})
	pull:SetAttribute("TimeStopExempt", true)
	pull.Parent = vortex
	gravity.Pull = pull
	local anchor = Instance.new("Attachment")
	anchor.Name = "Phase3RecallAnchor"
	anchor.Parent = record.Core.Root
	record.Cast:Add(anchor)
	local burst = Instance.new("ParticleEmitter")
	burst.Name = "RecallAbsorbBurst"
	burst.Texture = SPARKLE
	burst.Color = ColorSequence.new(white, gold)
	burst.LightEmission = 1
	burst.LightInfluence = 0
	burst.Lifetime = NumberRange.new(0.4, 0.9)
	burst.Speed = NumberRange.new(8, 18)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Rate = 0
	burst.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	burst:SetAttribute("TimeStopExempt", true)
	burst.Parent = anchor
	gravity.Burst = burst
	local pulseGlow = Instance.new("Highlight")
	pulseGlow.Name = "Phase3RecallPulse"
	pulseGlow.Adornee = record.Actor
	pulseGlow.FillColor = white
	pulseGlow.OutlineColor = gold
	pulseGlow.FillTransparency = 1
	pulseGlow.OutlineTransparency = 1
	pulseGlow.Parent = record.Actor
	record.Cast:Add(pulseGlow)
	gravity.Pulse = pulseGlow
	pose(record, { RightShoulder = { -150, 0, 20 }, LeftShoulder = { -150, 0, -20 }, Waist = { -8, 0, 0 } }, 0.3)
	local scan = 0
	record.Cast:Step(function(dt, now)
		if not gravity.Active then
			return false
		end
		local breathe = 0.58 + 0.1 * math.sin(now * 4)
		for _, s in ipairs(strips) do
			s.Transparency = breathe
		end
		scan += dt
		if scan >= 0.08 then
			scan = 0
			local present = {}
			for _, character in ipairs(Runtime.Characters()) do
				if alive(character) and Placement.Contains(character.HumanoidRootPart.Position, 4) then
					present[character] = true
					local data = gravity.Players[character]
					local root = character.HumanoidRootPart
					if not data or data.Root ~= root then
						data = { Root = root }
						gravity.Players[character] = data
						Status.SetZoneSlow(character, record.Cast, Config.Phase3GravitySlow)
						Status.SetJumpDisabled(character, record.Cast, true)
					end
				end
			end
			for character, data in pairs(gravity.Players) do
				if not present[character] then
					Status.RemoveZoneSlow(character, record.Cast)
					Status.SetJumpDisabled(character, record.Cast, false)
					gravity.Players[character] = nil
				end
			end
		end
		return true
	end)
	for index = 1, Config.Phase3WaveCount do
		local at = 0.15 + (index - 1) * Config.Phase3WaveBarrageDuration / Config.Phase3WaveCount
		record.Cast:Schedule(at, function()
			beginWave(record, gravity, index)
		end)
	end
	local started = record.Cast:Now()
	while valid(record) do
		local elapsed = record.Cast:Now() - started
		if elapsed >= total then
			local live = false
			for _, wave in ipairs(gravity.Waves) do
				if wave.Warning or wave.Active then
					live = true
					break
				end
			end
			if not live or elapsed >= total + 6 then
				break
			end
		end
		Run.Heartbeat:Wait()
	end
	if not valid(record) then
		return false
	end
	releaseField(record)
	stamp(record.Actor, "Phase3GravityFinishedAt")
	Effects:Create(floor, TweenInfo.new(0.3), { Transparency = 1 }):Play()
	for _, s in ipairs(strips) do
		Effects:Create(s, TweenInfo.new(0.4), { Transparency = 1 }):Play()
	end
	pull.Rate = 0
	release(record.Cast, pulseGlow)
	record.Cast:Schedule(0.35, function()
		release(record.Cast, floor)
		release(record.Cast, anchor)
	end)
	record.Cast:Schedule(0.45, function()
		for _, s in ipairs(strips) do
			release(record.Cast, s)
		end
	end)
	record.Cast:Schedule(2.3, function()
		release(record.Cast, vortex)
	end)
	return true
end

function api.Active(actor)
	return running[actor]
end
function api.ClearVisual(actor)
	local model = visuals[actor]
	visuals[actor] = nil
	if model then
		Effects.Release(model)
	end
	local weapon = weaponStates[actor]
	weaponStates[actor] = nil
	if weapon then
		restoreWeapon(weapon)
	end
end
function api.Cancel(actor, reason)
	local record = running[actor]
	if not record then
		return false
	end
	record.CancelReason = reason or "Phase 3 interrupted"
	record.Cast:Dispose()
	return true
end
function api.Begin(actor, target)
	if running[actor] then
		return running[actor]
	end
	if
		not alive(actor)
		or actor:GetAttribute("EncounterEnded")
		or actor:GetAttribute("Phase3Triggered")
		or ((actor:GetAttribute("Phase") or 1) ~= 2 and (actor:GetAttribute("Phase") or 1) ~= 2.5)
		or (actor:GetAttribute("Shield") or 1) > 0
		or actor:GetAttribute("IsGoldenClone")
		or actor:GetAttribute("IsClone")
	then
		return false
	end
	local bounds = Placement.GetBounds()
	if not bounds then
		return false
	end
	local core = Registry.For(actor, "P1CombatCore")
	actor:SetAttribute("Phase3Triggered", true)
	actor:SetAttribute("Phase3IntroActive", true)
	actor:SetAttribute("Phase2ShieldBreakSequenceActive", true)
	Audio.StopMusic(actor, "Phase2ShieldBreak")
	Audio.Emit(actor, "ShieldShatter", core.Root)
	actor:SetAttribute("Invulnerable", true)
	actor:SetAttribute("PhaseTransitionInProgress", true)
	actor:SetAttribute("AIEnabled", false)
	actor:SetAttribute("ParryActive", false)
	actor:SetAttribute("AttackInProgress", true)
	actor:SetAttribute("UnstoppableDisabled", true)
	actor:SetAttribute("PhaseGeneration", (actor:GetAttribute("PhaseGeneration") or 0) + 1)
	actor:SetAttribute("MovementRevision", (actor:GetAttribute("MovementRevision") or 0) + 1)
	require(BossSystem.Combat.PassiveController).Stop(actor)
	require(BossSystem.Mechanics.Clones.CloneController).CancelAll(actor, "Phase 3 transformation")
	require(BossSystem.Combat.CataclysmQTEService).CancelForActor(actor, "Phase 3 transformation")
	Time.ClearOwner(actor)
	Effects.CancelOwner(actor, "Phase 3 transformation")
	api.ClearVisual(actor)
	local cast = Effects.NewCast(
		actor,
		"Phase3Transformation",
		Config.Phase3PauseDuration
			+ Config.Phase3GravityDuration
			+ RECALL
			+ 6
			+ Story.Duration(Story.Phase3Before)
			+ Story.Duration(Story.Phase3After)
			+ 16
	)
	cast.TimeStopExempt = true
	local record = {
		Actor = actor,
		Core = core,
		Cast = cast,
		Generation = actor:GetAttribute("PhaseGeneration"),
		Target = target,
		MotionFrame = Placement.Validate(actor, core.Root.CFrame) or core.Root.CFrame,
		Completed = false,
		Random = Random.new(),
		RootAnchored = core.Root.Anchored,
		Dressings = {},
	}
	running[actor] = record
	function record:Cancel(reason)
		return api.Cancel(actor, reason)
	end
	function record:IsActive()
		return valid(self)
	end
	stamp(actor, "Phase3IntroStartedAt")
	record.Sequence = (actor:GetAttribute("Phase3IntroSequence") or 0) + 1
	actor:SetAttribute("Phase3IntroSequence", record.Sequence)
	actor:SetAttribute("Phase3WavesReleased", 0)
	actor:SetAttribute("Phase3WavesReturned", 0)
	actor:SetAttribute("Phase3RecallActive", false)
	actor:SetAttribute("Phase3GridsReleased", 0)
	core.Root.CFrame = record.MotionFrame
	core.Root.AssemblyLinearVelocity = Vector3.zero
	Time.SetAnchored(core.Root, true)
	pose(record, { RightShoulder = { 15, 0, 0 }, RightElbow = { 60, 0, 0 }, LeftShoulder = { 0, 0, 0 } }, 0.25)
	cast:Step(function()
		if not valid(record) then
			cast:Dispose()
			return false
		end
		core.Root.CFrame = record.MotionFrame
		core.Root.AssemblyLinearVelocity = Vector3.zero
		return true
	end)
	cast.OnDispose = function()
		local sameRecord = actor.Parent
			and running[actor] == record
			and actor:GetAttribute("Phase3IntroSequence") == record.Sequence
		local owns = sameRecord and actor:GetAttribute("PhaseGeneration") == record.Generation
		if running[actor] == record then
			running[actor] = nil
		end
		if sameRecord then
			actor:SetAttribute("Phase3IntroActive", false)
			actor:SetAttribute("Phase2ShieldBreakSequenceActive", false)
			actor:SetAttribute("Phase3GravityActive", false)
			actor:SetAttribute("Phase3RecallActive", false)
			if not record.Completed and (actor:GetAttribute("Phase") or 1) < 3 then
				actor:SetAttribute("Phase3Triggered", false)
			end
		end
		if owns then
			actor:SetAttribute("Phase3IntroActive", false)
			actor:SetAttribute("AttackInProgress", false)
			actor:SetAttribute("PhaseTransitionInProgress", false)
			actor:SetAttribute("Invulnerable", false)
			actor:SetAttribute("ExecutionLocked", false)
			actor:SetAttribute("ShieldBreakInProgress", false)
			actor:SetAttribute("UnstoppableDisabled", false)
			if not record.Completed then
				actor:SetAttribute("Phase3CancelReason", record.CancelReason or cast.CancelReason or "Interrupted")
				actor:SetAttribute("Phase3Triggered", false)
				stage(record, "Cancelled")
			end
			if alive(actor) and not actor:GetAttribute("EncounterEnded") then
				actor:SetAttribute("AIEnabled", true)
				actor:SetAttribute("NextAttackAt", workspace:GetServerTimeNow() + 0.35)
			end
		end
		local fieldOk, fieldError = xpcall(function()
			releaseField(record)
		end, debug.traceback)
		if not fieldOk then
			warn("Phase3 field cleanup: " .. tostring(fieldError))
		end
		for _, item in ipairs(record.Dressings) do
			pcall(item.Destroy, item)
		end
		table.clear(record.Dressings)
		local poseOk, poseError = pcall(Locomotion.ReleasePose, actor, record.PoseToken, 0.2)
		if not poseOk then
			warn("Phase3 pose cleanup: " .. tostring(poseError))
		end
		if sameRecord and core.Root.Parent then
			Time.SetAnchored(core.Root, record.RootAnchored)
			core.Root.AssemblyLinearVelocity = Vector3.zero
			core.Root.AssemblyAngularVelocity = Vector3.zero
			if owns then
				local safe = Placement.Validate(actor, record.MotionFrame)
					or Placement.Validate(actor, core.Root.CFrame)
				if safe then
					core.Root.CFrame = safe
				end
			end
		end
		if owns and not record.Completed then
			local weaponOk, weaponError = xpcall(function()
				restoreWeapon(record)
			end, debug.traceback)
			if not weaponOk then
				warn("Phase3 weapon cleanup: " .. tostring(weaponError))
			end
		end
		if owns and alive(actor) and not actor:GetAttribute("EncounterEnded") then
			require(BossSystem.Combat.PassiveController).Start(actor, core.Melee.GetTarget)
			require(BossSystem.Mechanics.Reality.RealityController).Start(actor)
		end
	end
	task.spawn(function()
		local ok, err = xpcall(function()
			stage(record, "Pause")
			if not waitFor(record, Config.Phase3PauseDuration) then
				return
			end
			stamp(actor, "Phase3PauseEndedAt")
			stage(record, "Shield break")
			local options = {
				Valid = function()
					return valid(record)
				end,
				Wait = function(seconds)
					return waitFor(record, seconds)
				end,
				Hold = Config.Phase3DialogueHold,
				Prefix = "Phase3",
			}
			if
				not roar(record, bounds)
				or not jumpCenter(record, bounds)
				or not gravityField(record, bounds)
				or not discardWeapon(record)
				or not transform(record)
			then
				return
			end
			stage(record, "Final dialogue")
			if not Story.Play(actor, Story.Phase3After, options) then
				return
			end
			Weapon.SetUnarmed(actor, true)
			actor:SetAttribute("IdentityRevealed", true)
			actor:SetAttribute("PhaseTitleOverride", "alterGolden, Illusionist")
			core.Humanoid.DisplayName = "alterGolden, Illusionist"
			actor:SetAttribute("Phase", 3)
			core.Humanoid.MaxHealth = Config.Phase3MaxHealth
			core.Humanoid.Health = Config.Phase3MaxHealth
			actor:SetAttribute("MaxShield", Config.Phase3ShieldMaxHealth)
			actor:SetAttribute("Shield", Config.Phase3ShieldMaxHealth)
			actor:SetAttribute("ShieldBroken", false)
			actor:SetAttribute("Defense", 0)
			actor:SetAttribute("UnstoppableDisabled", false)
			local glow = actor:FindFirstChild("ShieldGlow")
			if glow then
				glow.Enabled = true
			end
			record.Completed = true
			weaponStates[actor] = record
			if record.Aura then
				cast.objects[record.Aura] = nil
				visuals[actor] = record.Aura
			end
			actor:SetAttribute("Phase3IntroActive", false)
			actor:SetAttribute("PhaseTransitionInProgress", false)
			actor:SetAttribute("Phase2ShieldBreakSequenceActive", false)
			actor:SetAttribute("Invulnerable", false)
			actor:SetAttribute("AIEnabled", true)
			actor:SetAttribute("AttackInProgress", false)
			actor:SetAttribute("NextAttackAt", workspace:GetServerTimeNow() + 0.35)
			stamp(actor, "Phase3StartedAt")
			stamp(actor, "Phase3IntroCompletedAt")
			Audio.Phase(actor, 3)
			stage(record, "Complete")
			core.Melee.Pose("Idle", 0.2)
			actor:SetAttribute("AttackState", "Idle")
			cast:Dispose()
			require(BossSystem.Combat.PassiveController).Start(actor, core.Melee.GetTarget)
		end, debug.traceback)
		if not ok then
			warn("Phase3Transformation: " .. tostring(err))
			record.CancelReason = "Cinematic error"
		end
		if not record.Completed and not cast.closed then
			cast:Dispose()
		end
	end)
	return record
end
return api
