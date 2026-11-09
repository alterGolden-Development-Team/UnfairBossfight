local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
local Effects = require(BossSystem.Combat.EffectService)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local api = {}
local skills = setmetatable({}, { __mode = "k" })
local deaths = setmetatable({}, { __mode = "k" })
local GOLD = Color3.fromRGB(255, 214, 43)
local LIGHT = Color3.fromRGB(255, 248, 180)
local function part(cast, name, frame, size, color, alpha)
	local p = Effects.AcquirePart()
	p.Name = name
	p.CFrame = frame
	p.Size = size
	p.Color = color
	p.Transparency = alpha
	p.Parent = Runtime.Effects
	cast:Add(p)
	return p
end
local function sparks(parent, color, rate)
	local p = Instance.new("ParticleEmitter")
	p.Name = "CharacterLightParticles"
	p.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	p.Color = ColorSequence.new(color, LIGHT)
	p.LightEmission = 1
	p.Rate = rate or 0
	p.Lifetime = NumberRange.new(0.35, 0.8)
	p.Speed = NumberRange.new(2, 6)
	p.SpreadAngle = Vector2.new(180, 180)
	p.Drag = 2
	p.Acceleration = Vector3.new(0, 5, 0)
	p.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.3, 0.4),
		NumberSequenceKeypoint.new(1, 0),
	})
	p.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	p.Parent = parent
	return p
end
function api.CancelSkill(character, key)
	local record = skills[character]
	local cast = record and record[key]
	if cast then
		cast:Dispose()
	end
end
function api.Skill(character, key, duration)
	local root = character:FindFirstChild("HumanoidRootPart")
	local h = character:FindFirstChildOfClass("Humanoid")
	if not root or not h or h.Health <= 0 then
		return
	end
	api.CancelSkill(character, key)
	local record = skills[character] or {}
	skills[character] = record
	local color = key == "Dash" and Color3.fromRGB(103, 198, 255)
		or GOLD
	local cast = Effects.NewCast(nil, "PlayerSkill" .. key, duration * 4 + 3)
	record[key] = cast
	local untilAt = Time.ActionNow(character) + duration
	local anchor = part(cast, "PlayerSkillAura", root.CFrame, Vector3.one * 0.1, color, 1)
	local p = sparks(anchor, color, key == "Dash" and 0 or 9)
	p:Emit(key == "Dash" and 12 or 24)
	local points = {}
	for i = 1, 4 do
		local a = Instance.new("Attachment")
		a.Parent = anchor
		points[i] = a
	end
	for i = 1, 2 do
		local beam = Instance.new("Beam")
		beam.Name = "SkillEnergyRibbon"
		beam.Attachment0 = points[i * 2 - 1]
		beam.Attachment1 = points[i * 2]
		beam.Color = ColorSequence.new(color, LIGHT)
		beam.Width0 = 0.12
		beam.Width1 = 0.07
		beam.Transparency = NumberSequence.new(0.35)
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.CurveSize0 = 2
		beam.CurveSize1 = -2
		beam.Segments = 6
		beam.Parent = anchor
	end
	local glow = Instance.new("Highlight")
	glow.Name = "PlayerSkillGlow"
	glow.Adornee = character
	glow.FillColor = color
	glow.OutlineColor = color
	glow.FillTransparency = 0.9
	glow.OutlineTransparency = 0.65
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.Parent = anchor
	cast.OnDispose = function()
		if record[key] == cast then
			record[key] = nil
		end
		if not next(record) then
			skills[character] = nil
		end
	end
	cast:Step(function()
		if
			not character.Parent
			or not root.Parent
			or h.Health <= 0
			or Time.ActionNow(character) >= untilAt
		then
			cast:Dispose()
			return false
		end
		anchor.CFrame = root.CFrame
		local t = Time.ActionNow(character)
		for i, a in ipairs(points) do
			local angle = t * 2 + i * math.pi * 0.5
			a.Position = Vector3.new(math.cos(angle) * 2.3, math.sin(angle * 2) * 0.55 - 0.3, math.sin(angle) * 2.3)
		end
		return true
	end)
	return cast
end
function api.ShieldBreak(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	 
	local cast = Effects.NewCast(nil, "BossShieldBreakVisual", 1.5)
	local anchor = part(cast, "ShatteredShieldLight", root.CFrame, Vector3.one * 0.1, GOLD, 1)
	sparks(anchor, GOLD):Emit(55)
	local glow = Instance.new("Highlight")
	glow.Adornee = character
	glow.FillColor = GOLD
	glow.OutlineColor = LIGHT
	glow.FillTransparency = 0.35
	glow.OutlineTransparency = 0.05
	glow.Parent = anchor
	local shards = {}
	for i = 1, 8 do
		local angle = i * math.pi * 0.25
		shards[i] =
			{ Part = part(cast, "ShieldBreakShard", root.CFrame, Vector3.new(0.35, 2.2, 1), GOLD, 0.1), Angle = angle }
	end
	local began = cast:Now()
	cast:Step(function(_, now)
		if not character.Parent or not root.Parent then
			cast:Dispose()
			return false
		end
		local t = math.clamp((now - began) / 1.5, 0, 1)
		anchor.CFrame = root.CFrame
		glow.FillTransparency = 0.35 + 0.65 * t
		glow.OutlineTransparency = 0.05 + 0.95 * t
		for i, entry in ipairs(shards) do
			local offset = Vector3.new(
				math.cos(entry.Angle) * (2 + 8 * t),
				math.sin(i * 2) * 2 + t * 3,
				math.sin(entry.Angle) * (2 + 8 * t)
			)
			entry.Part.CFrame = CFrame.new(root.Position + offset) * CFrame.Angles(t * 3, entry.Angle, t * 2)
			entry.Part.Transparency = 0.1 + 0.9 * t
		end
		return true
	end)
end
function api.Arrival(character, onRevealed)
	local root = character:FindFirstChild("HumanoidRootPart")
	local h = character:FindFirstChildOfClass("Humanoid")
	if not root or not h then
		return
	end
	local cast = Effects.NewCast(nil, "BossEntranceReveal", 1.25)
	local originals = {}
	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") or object:IsA("Decal") or object:IsA("Texture") then
			originals[object] = object.Transparency
			object.Transparency = 1
		end
	end
	local beam = part(
		cast,
		"BossEntranceGoldenLine",
		CFrame.new(root.Position + Vector3.new(0, 55, 0)),
		Vector3.new(0.1, 120, 0.1),
		LIGHT,
		0.1
	)
	local anchor = part(cast, "BossEntranceLight", root.CFrame, Vector3.one * 0.1, GOLD, 1)
	sparks(anchor, GOLD):Emit(50)
	local began = cast:Now()
	local revealed = false
	local function reveal()
		for object, alpha in pairs(originals) do
			if object.Parent then
				object.Transparency = alpha
			end
		end
		if not revealed and character.Parent and h.Health > 0 and not character:GetAttribute("EncounterEnded") then
			revealed = true
			if onRevealed then
				onRevealed()
			end
		end
	end
	cast.OnDispose = reveal
	cast:Step(function(_, now)
		if not character.Parent or h.Health <= 0 then
			cast:Dispose()
			return false
		end
		local elapsed = now - began
		local width = elapsed < 0.3 and 14 * math.sin(math.clamp(elapsed / 0.3, 0, 1) * math.pi * 0.5)
			or 14 * (1 - math.clamp((elapsed - 0.3) / 0.7, 0, 1))
		beam.Size = Vector3.new(math.max(0.1, width), 120, math.max(0.1, width * 0.55))
		beam.Transparency = 0.1 + 0.9 * math.clamp((elapsed - 0.4) / 0.7, 0, 1)
		local fade = math.clamp((elapsed - 0.35) / 0.55, 0, 1)
		for object, alpha in pairs(originals) do
			if object.Parent then
				object.Transparency = 1 - (1 - alpha) * fade
			end
		end
		if elapsed >= 0.9 and not revealed then
			reveal()
		end
		return true
	end)
	return cast
end
function api.Death(character)
	if deaths[character] or not character.Parent then
		return
	end
	local h = character:FindFirstChildOfClass("Humanoid")
	if not h or h.Health > 0 then
		return
	end
	h.BreakJointsOnDeath = false
	h.RequiresNeck = false
	deaths[character] = true
	character:SetAttribute("TimeStopExempt", true)
	local record = skills[character]
	if record then
		local selected = {}
		for _, cast in pairs(record) do
			table.insert(selected, cast)
		end
		for _, cast in ipairs(selected) do
			cast:Dispose()
		end
	end
	local cast = Effects.NewCast(nil, "R6DeathIntoLight", 3.7)
	cast.TimeStopExempt = true
	local bodies, visuals = {}, {}
	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") then
			object.Anchored = false
			if object.Parent == character and object.Name ~= "HumanoidRootPart" then
				object.CanCollide = true
				object.CollisionGroup = "Default"
				bodies[#bodies + 1] = object
			else
				object.CanCollide = false
			end
			visuals[object] = object.Transparency
		elseif object:IsA("Decal") or object:IsA("Texture") then
			visuals[object] = object.Transparency
		end
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	for _, joint in ipairs(character:GetDescendants()) do
		if
			joint:IsA("Motor6D")
			and joint.Part0
			and joint.Part1
			and joint.Part0.Parent == character
			and joint.Part1.Parent == character
		then
			 
			if joint.Part0 == root or joint.Part1 == root then
				joint.Enabled = true
				continue
			end
			 
			 
			local a = Instance.new("Attachment")
			a.Name = "DeathRagdollJoint"
			a.CFrame = joint.C0 * joint.Transform
			a.Parent = joint.Part0
			local b = Instance.new("Attachment")
			b.Name = "DeathRagdollJoint"
			b.CFrame = joint.C1
			b.Parent = joint.Part1
			local socket = Instance.new("BallSocketConstraint")
			socket.Name = "DeathRagdollSocket"
			socket.Attachment0 = a
			socket.Attachment1 = b
			socket.LimitsEnabled = true
			socket.UpperAngle = joint.Name == "Neck" and 30 or 65
			socket.TwistLimitsEnabled = true
			socket.TwistLowerAngle = -35
			socket.TwistUpperAngle = 35
			socket.Parent = joint.Part0
			joint.Enabled = false
		end
	end
	for index, first in ipairs(bodies) do
		for other = index + 1, #bodies do
			local noCollision = Instance.new("NoCollisionConstraint")
			noCollision.Name = "DeathRagdollNoSelfCollision"
			noCollision.Part0 = first
			noCollision.Part1 = bodies[other]
			noCollision.Parent = first
		end
	end
	for _, body in ipairs(bodies) do
		pcall(function()
			body:SetNetworkOwner(nil)
		end)
	end
	h.PlatformStand = true
	h.AutoRotate = false
	local animate = character:FindFirstChild("Animate")
	if animate and animate:IsA("LocalScript") then
		animate.Disabled = true
	end
	local animator = h:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0.05)
		end
	end
	local began = cast:Now()
	local emitting = false
	cast:Step(function(_, now)
		if not character.Parent then
			cast:Dispose()
			return false
		end
		local elapsed = now - began
		if elapsed < 1 then
			return true
		end
		if not emitting then
			emitting = true
			for _, body in ipairs(bodies) do
				local p = sparks(body, LIGHT, 16)
				cast:Add(p)
				p:Emit(12)
			end
		end
		local alpha = math.clamp((elapsed - 1) / 1.5, 0, 1)
		for object, original in pairs(visuals) do
			if object.Parent then
				object.Transparency = original + (1 - original) * alpha
			end
		end
		if elapsed >= 2.5 then
			for object in pairs(cast.objects) do
				if object:IsA("ParticleEmitter") then
					object.Enabled = false
				end
			end
		end
		return true
	end)
	return cast
end

 
 
function api.BossDeath(character, onFinished)
	if deaths[character] or not character.Parent then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local h = character:FindFirstChildOfClass("Humanoid")
	if not root or not h or h.Health > 0 then
		return
	end
	deaths[character] = true
	local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
	local dialogue = Config.BossDefeatDialogue
	local count = 0
	for _ in utf8.graphemes(dialogue) do
		count += 1
	end
	local kneel = Config.BossDefeatKneelDuration
	local dustAt = kneel + count * Config.DialogueCharacterInterval + Config.BossDefeatDialogueHold
	local fade = Config.BossDefeatFadeDuration
	local cast = Effects.NewCast(nil, "BossKneelFarewell", dustAt + fade + 1.1)
	cast.TimeStopExempt = true
	character:SetAttribute("TimeStopExempt", true)
	h.BreakJointsOnDeath = false
	h.RequiresNeck = false
	h.AutoRotate = false
	h.PlatformStand = true
	root.Anchored = true
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	local animate = character:FindFirstChild("Animate")
	if animate and (animate:IsA("Script") or animate:IsA("LocalScript")) then
		animate.Disabled = true
	end
	local animator = h:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:Stop(0.1)
		end
	end
	local frame = root.CFrame
	local lowered = frame - Vector3.new(0, 1.8, 0)
	local pose = {
		["Right Hip"] = { -82, 0, 0 },
		["Left Hip"] = { -76, 0, 0 },
		RootJoint = { 16, 0, 0 },
		["Right Shoulder"] = { 24, -8, -10 },
		["Left Shoulder"] = { 24, 8, 10 },
		Neck = { -14, 0, 0 },
	}
	local joints, visuals, bodies = {}, {}, {}
	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") then
			object.CanCollide = false
			object.CanTouch = false
			visuals[object] = object.Transparency
			if object.Parent == character and object.Name ~= "HumanoidRootPart" then
				bodies[#bodies + 1] = object
			end
		elseif object:IsA("Decal") or object:IsA("Texture") then
			visuals[object] = object.Transparency
		elseif object:IsA("Motor6D") and pose[object.Name] then
			local base = object:GetAttribute("BossBaseC0") or object.C0
			local angles = pose[object.Name]
			joints[#joints + 1] = {
				Motor = object,
				From = object.C0,
				To = CFrame.new(base.Position)
					* CFrame.Angles(math.rad(angles[1]), math.rad(angles[2]), math.rad(angles[3]))
					* base.Rotation,
			}
			object.Transform = CFrame.identity
		elseif object:IsA("ParticleEmitter") then
			object.Enabled = false
		elseif object:IsA("Beam") or object:IsA("Trail") then
			object.Enabled = false
		end
	end
	local dust = part(cast, "BossFarewellDust", frame, Vector3.one * 0.1, GOLD, 1)
	dust:SetAttribute("TimeStopExempt", true)
	local p = sparks(dust, GOLD, 0)
	p.Lifetime = NumberRange.new(0.6, 1.05)
	p.Speed = NumberRange.new(3, 9)
	p.Acceleration = Vector3.new(0, 7, 0)
	local began = cast:Now()
	local emission = 0
	cast:Schedule(kneel, function()
		if character.Parent then
			require(BossSystem.Players.PlayerEncounter).Say(dialogue, nil, { Duration = dustAt - kneel + 0.1 })
		end
	end)
	cast:Step(function(dt, now)
		if not character.Parent or not root.Parent then
			cast:Dispose()
			return false
		end
		local elapsed = now - began
		local t = math.clamp(elapsed / kneel, 0, 1)
		local blend = t * t * (3 - 2 * t)
		root.CFrame = frame:Lerp(lowered, blend)
		for _, joint in ipairs(joints) do
			if joint.Motor.Parent then
				joint.Motor.C0 = joint.From:Lerp(joint.To, blend)
			end
		end
		if elapsed >= dustAt then
			local alpha = math.clamp((elapsed - dustAt) / fade, 0, 1)
			for object, original in pairs(visuals) do
				if object.Parent then
					object.Transparency = original + (1 - original) * alpha
				end
			end
			emission += dt
			if elapsed < dustAt + fade and emission >= 0.1 then
				emission = 0
				 
				 
				for _, body in ipairs(bodies) do
					if body.Parent then
						dust.CFrame = body.CFrame
						p:Emit(5)
					end
				end
			end
		end
		return true
	end)
	cast:Schedule(dustAt + fade + 0.95, function()
		if not character.Parent then
			cast:Dispose()
			return
		end
		if onFinished then
			onFinished()
		end
		cast:Dispose()
		character:Destroy()
	end)
	return cast
end
return api
