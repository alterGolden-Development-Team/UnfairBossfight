--!nonstrict
--[[
 Azusa's body: the Roblox avatar of mymeo125 (R15), her Blender katana (ReplicatedStorage.AzusaFX.Katana) in her right hand,
 Roblox's default R15 animations, and a root that glides (anchored, moved by CFrame) so her moves are exact.
 She is Workspace."Azusa" (the class kits find her through BossKit: workspace attribute ClassBossName).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Azusa = {}
local USER = "mymeo125"
local PINK = Color3.fromRGB(255, 120, 180)
-- Her moves were generated for her R15 body (Roblox animation generator, 2026-11-11); each clip is ~6 s and is time-scaled to its
-- attack with Azusa.Play(name, seconds). Run is Roblox's default.
local ANIMS = {
	Idle = "rbxassetid://82909146103538", -- combat-ready stance, katana in hand
	Run = "rbxassetid://913376220",
	Iai = "rbxassetid://96855348977197", -- crouch, hand on the hilt, lightning quick-draw
	BigSlash = "rbxassetid://134809624119099", -- both hands high, a huge diagonal cut that launches a wave
	Plunge = "rbxassetid://107655810410345", -- leap and drive the blade into the floor
	Throw = "rbxassetid://123856879692519", -- a dancer's spinning sweep that throws a fan of blades
	DashCut = "rbxassetid://80377760935845", -- low, fast dash with a passing cut
	Summon = "rbxassetid://132464979477953", -- blade to the sky, spinning, gathering power
	Stagger = "rbxassetid://79939354090544", -- parried: stumbles back
	Point = "rbxassetid://129727993057905", -- points the blade at the floor, stamps: marks a target
	Kneel = "rbxassetid://120142044322082", -- beaten: one knee, a smile and a thumbs up
}

local model, humanoid, root, animator
local tracks = {}
local glide -- { from, to, startAt, duration }

local function description()
	local okId, userId = pcall(Players.GetUserIdFromNameAsync, Players, USER)
	if okId then
		local ok, d = pcall(Players.GetHumanoidDescriptionFromUserIdAsync, Players, userId)
		if ok then
			return d
		end
	end
	return Instance.new("HumanoidDescription")
end

function Azusa.Build(at)
	if model then
		model:Destroy()
	end
	local ok, m = pcall(Players.CreateHumanoidModelFromDescriptionAsync, Players, description(), Enum.HumanoidRigType.R15)
	if not ok then
		warn("[Azusa] could not build her: " .. tostring(m))
		return nil
	end
	model = m
	model.Name = "Azusa"
	humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayName = "Azusa"
	humanoid.NameDisplayDistance = 0
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	root = model:FindFirstChild("HumanoidRootPart")
	root.Anchored = true
	local animate = model:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanQuery = true
		end
	end
	-- her sword, in her right hand, blade up along the forearm when idle
	local fx = ReplicatedStorage:FindFirstChild("AzusaFX")
	local katana = fx and fx:FindFirstChild("Katana")
	local hand = model:FindFirstChild("RightHand")
	if katana and hand then
		local sword = katana:Clone()
		sword.Name = "Katana"
		local grip = hand.CFrame * CFrame.new(0, -0.15, 0) * CFrame.Angles(math.rad(-90), 0, 0)
		sword:PivotTo(grip)
		for _, p in sword:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored, p.Massless = false, true
				local weld = Instance.new("WeldConstraint")
				weld.Part0, weld.Part1 = hand, p
				weld.Parent = p
				if p.Name == "Glow" then
					p.Color = Color3.fromRGB(255, 220, 236)
				end
			end
		end
		sword.Parent = model
		-- a petal-pink trail off the edge, on while she attacks (Azusa.Trail)
		local edge = sword:FindFirstChild("Glow")
		if edge then
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			local half = edge.Size.Y > edge.Size.Z and edge.Size.Y or edge.Size.Z
			a0.Position = Vector3.new(0, edge.Size.Y > edge.Size.Z and -half / 2 or 0, edge.Size.Y > edge.Size.Z and 0 or -half / 2)
			a1.Position = -a0.Position
			a0.Parent, a1.Parent = edge, edge
			local trail = Instance.new("Trail")
			trail.Name = "BladeTrail"
			trail.Attachment0, trail.Attachment1 = a0, a1
			trail.Color = ColorSequence.new(Color3.new(1, 1, 1), PINK)
			trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(1, 1) })
			trail.Lifetime, trail.MinLength = 0.22, 0.05
			trail.LightEmission, trail.LightInfluence = 1, 0
			trail.FaceCamera = false
			trail.Enabled = false
			trail.Parent = edge
		end
	end
	-- the flash on her body when she winds up (TutorialClient flashes Highlights tagged AzusaFlash)
	local glow = Instance.new("Highlight")
	glow.Name = "Charge"
	glow.FillColor, glow.OutlineColor = PINK, Color3.new(1, 1, 1)
	glow.FillTransparency, glow.OutlineTransparency = 1, 1
	glow.DepthMode = Enum.HighlightDepthMode.Occluded
	glow.Parent = model
	-- petals that trail off her
	local trail = Instance.new("ParticleEmitter")
	trail.Name = "Petals"
	trail.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 180, 210))
	trail.Size = NumberSequence.new(0.35)
	trail.Lifetime = NumberRange.new(1.2, 2)
	trail.Rate = 6
	trail.Speed = NumberRange.new(1, 2)
	trail.SpreadAngle = Vector2.new(180, 180)
	trail.Parent = root
	local height = humanoid.HipHeight + root.Size.Y / 2
	model:SetAttribute("Height", height)
	model:PivotTo(at + Vector3.new(0, height, 0))
	model.Parent = workspace
	animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	tracks = {}
	for name, id in ANIMS do
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local okTrack, track = pcall(animator.LoadAnimation, animator, anim)
		if okTrack then
			tracks[name] = track
		end
	end
	if tracks.Idle then
		tracks.Idle.Looped = true
		tracks.Idle:Play()
	end
	if tracks.Run then
		tracks.Run.Looped = true
	end
	return model
end

function Azusa.Model()
	return model
end
function Azusa.Root()
	return root
end
function Azusa.Alive()
	return model ~= nil and model.Parent ~= nil and humanoid ~= nil and humanoid.Health > 0
end

-- Plays a move so that the whole clip takes `seconds` (default: its own length). Other moves stop.
function Azusa.Play(name, seconds)
	local t = tracks[name]
	if not t then
		return nil
	end
	for other, track in tracks do
		if other ~= name and other ~= "Idle" and other ~= "Run" and track.IsPlaying then
			track:Stop(0.12)
		end
	end
	t:Play(0.08)
	local length = t.Length > 0 and t.Length or 6
	t:AdjustSpeed(seconds and length / seconds or 1)
	return t
end
-- The blade trail on or off.
function Azusa.Trail(on)
	local trail = model and model:FindFirstChild("BladeTrail", true)
	if trail then
		trail.Enabled = on
	end
end

-- A pink ghost of her where she stands now, fading out (for dashes and blinks).
function Azusa.Afterimage(seconds)
	if not model then
		return
	end
	local ghost = Instance.new("Model")
	ghost.Name = "AzusaGhost"
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 and p.Name ~= "HumanoidRootPart" then
			local copy = p:Clone()
			copy:ClearAllChildren()
			copy.Anchored, copy.CanCollide, copy.CanQuery, copy.CanTouch, copy.CastShadow = true, false, false, false, false
			copy.Material = Enum.Material.ForceField
			copy.Color = PINK
			copy.Transparency = 0.15
			copy.Parent = ghost
			game:GetService("TweenService"):Create(copy, TweenInfo.new(seconds or 0.45), { Transparency = 1 }):Play()
		end
	end
	ghost.Parent = workspace:FindFirstChild("AzusaFXLive") or workspace
	game:GetService("Debris"):AddItem(ghost, (seconds or 0.45) + 0.1)
end

function Azusa.Stop(name)
	local t = tracks[name]
	if t then
		t:Stop(0.15)
	end
end

local function feet(pos)
	return Vector3.new(pos.X, (model:GetAttribute("Height") or 3) + (model:GetAttribute("FloorY") or 0), pos.Z)
end

-- Turn to face a point (stays on the floor).
function Azusa.Face(point)
	if not root then
		return
	end
	local here = root.Position
	local look = Vector3.new(point.X, here.Y, point.Z)
	if (look - here).Magnitude > 0.1 then
		model:PivotTo(CFrame.lookAt(here, look))
	end
end

-- Glide to a floor point over `seconds` (running animation), facing `faceAt` (or where she goes). Yields.
function Azusa.MoveTo(point, seconds, faceAt, noRun)
	if not root then
		return
	end
	local from = root.Position
	local to = feet(point)
	seconds = math.max(seconds or ((to - from).Magnitude / 34), 0.05)
	glide = { from = from, to = to, startAt = os.clock(), duration = seconds, face = faceAt }
	if not noRun and tracks.Run then
		tracks.Run:Play(0.15, 1, 1.4)
	end
	local token = glide
	while glide == token and os.clock() - token.startAt < token.duration and Azusa.Alive() do
		RunService.Heartbeat:Wait()
		local t = math.clamp((os.clock() - token.startAt) / token.duration, 0, 1)
		local pos = token.from:Lerp(token.to, 1 - (1 - t) ^ 2)
		local look = token.face or token.to
		local flat = Vector3.new(look.X, pos.Y, look.Z)
		model:PivotTo((flat - pos).Magnitude > 0.1 and CFrame.lookAt(pos, flat) or CFrame.new(pos) * (root.CFrame - root.Position))
	end
	if tracks.Run then
		tracks.Run:Stop(0.2)
	end
	if glide == token then
		glide = nil
	end
end

-- Appear somewhere else in a burst of petals.
function Azusa.Blink(point, faceAt)
	if not root then
		return
	end
	local burst = Instance.new("Part")
	burst.Anchored, burst.CanCollide, burst.CanQuery, burst.CanTouch, burst.Transparency = true, false, false, false, 1
	burst.Size, burst.Position = Vector3.new(1, 1, 1), root.Position
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	e.Color = ColorSequence.new(Color3.fromRGB(255, 160, 200), Color3.new(1, 1, 1))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.5, 0.9)
	e.Speed = NumberRange.new(12, 22)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Rate = 0
	e.Parent = burst
	burst.Parent = workspace
	e:Emit(40)
	game:GetService("Debris"):AddItem(burst, 1.5)
	local to = feet(point)
	model:PivotTo(CFrame.lookAt(to, Vector3.new((faceAt or point).X, to.Y, (faceAt or point).Z) + Vector3.new(0.001, 0, 0)))
	local burst2 = burst:Clone()
	burst2.Position = to
	burst2.Parent = workspace
	burst2:FindFirstChildOfClass("ParticleEmitter"):Emit(40)
	game:GetService("Debris"):AddItem(burst2, 1.5)
end

-- The wind-up flash on her body for `seconds` (TutorialClient flashes it, faster towards the end).
function Azusa.Charge(seconds, color)
	local glow = model and model:FindFirstChild("Charge")
	if not glow then
		return
	end
	local now = workspace:GetServerTimeNow()
	glow:SetAttribute("FlashColor", color or PINK)
	glow:SetAttribute("FlashFrom", now)
	glow:SetAttribute("FlashTo", now + seconds)
	game:GetService("CollectionService"):AddTag(glow, "AzusaFlash")
	task.delay(seconds + 0.15, function()
		if glow.Parent and glow:GetAttribute("FlashTo") <= workspace:GetServerTimeNow() then
			game:GetService("CollectionService"):RemoveTag(glow, "AzusaFlash")
			glow.FillTransparency, glow.OutlineTransparency = 1, 1
		end
	end)
end

return Azusa
