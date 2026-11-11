--[==[ BACKUP of ServerScriptService.BossSystem.Combat.ProjectileService (ModuleScript) ]==]
return nil
--[==[
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
local Effects = require(BossSystem.Combat.EffectService)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Registry = require(BossSystem.Combat.AttackRegistry)
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local TimeEffects = require(BossSystem.Mechanics.Time.TimeEffectController)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Metadata = require(BossSystem.Combat.AbilityMetadata)
local Audio = require(BossSystem.Presentation.CombatAudio)
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local StarterPlayer = game:GetService("StarterPlayer")
local api = {}
local counts = setmetatable({}, { __mode = "k" })
local knownPlayers = setmetatable({}, { __mode = "k" })
local random = Random.new()
local motions = {}
local GOLD = Color3.fromRGB(255, 213, 36)
local WHITE = Color3.fromRGB(255, 253, 188)
-- time bullets are yellow (P2 and P5): the clock, trail, sparks and glow all read from these
local TIME = Color3.fromRGB(255, 224, 70)
local CORE = Color3.fromRGB(255, 246, 180)
local DEEP = Color3.fromRGB(184, 120, 12)
local FROZEN = Color3.fromRGB(214, 190, 110)
local FACE = Color3.fromRGB(6, 18, 30)
local ORANGE = Color3.fromRGB(255, 140, 24)
local AMBER = Color3.fromRGB(176, 78, 10)
local BULLET_GOLD = Color3.fromRGB(255, 228, 130)
local NO_TARGETS = {}
local TIME_SIZE = 1.15
local VISUAL_TAG = "TimeBulletVisual"
local starterScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
local animationClient = starterScripts and starterScripts:FindFirstChild("TimeBulletClient", true)
local CLIENT_ANIM = Config.TimeBulletClientAnimation ~= false
	and animationClient ~= nil
	and animationClient:IsA("LocalScript")
	and animationClient.Enabled
local STATE_OF = { Materializing = "Summon", Flying = "Flying", Dormant = "Frozen", Cue = "Cue" }
local function ownerOf(actor)
	local ref = actor:FindFirstChild("EncounterOwner")
	return ref and ref:IsA("ObjectValue") and ref.Value or actor
end
local function motionCall(handle, name, ...)
	local callback = handle.Options[name]
	if type(callback) ~= "function" then
		return false, nil
	end
	local ok, result = xpcall(callback, debug.traceback, ...)
	if not ok then
		warn("Projectile motion " .. name .. ": " .. tostring(result))
	end
	return ok, result
end
local function restoreMotion(handle)
	if not handle.Hidden then
		return
	end
	 
	 
	handle.Hidden = false
	motionCall(handle, "Hide", false)
end
function api.RegisterMotion(actor, options)
	local skill = options.Skill or actor:GetAttribute("CurrentAttackFile")
	local definition = skill and Metadata.Get(skill)
	local handle = {
		Owner = ownerOf(actor),
		Options = options,
		Closed = false,
		Hidden = false,
		CanMissingFrame = definition and definition.CanMissingFrame == true,
	}
	function handle:IsHidden()
		return self.Hidden
	end
	function handle:Dispose()
		if self.Closed then
			return
		end
		self.Closed = true
		motions[self] = nil
		restoreMotion(self)
	end
	motions[handle] = true
	return handle
end
 
 
function api.SafeReappearance(position, direction, radius, params)
	local requested = position
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health > 0 and math.abs(root.Position.Y - requested.Y) < 6 then
			local delta = requested - root.Position
			if delta.Magnitude < radius then
				local away = delta.Magnitude > 0.01 and delta.Unit or -direction
				local move = away * (radius - delta.Magnitude + 0.2)
				local wall = workspace:Spherecast(requested, 0.5, move, params)
				if not wall then
					requested += move
				else
					requested -= direction * radius
				end
			end
		end
	end
	return requested
end
function api.SkipAhead(actor, seconds, hiddenDuration)
	seconds = math.clamp(tonumber(seconds) or Config.MissingFrameSkipSeconds, 0, 3)
	hiddenDuration = math.clamp(tonumber(hiddenDuration) or 0.14, 0.05, 0.3)
	local owner = ownerOf(actor)
	local selected = {}
	for handle in pairs(motions) do
		local options = handle.Options
		if handle.Closed or options.Cast.closed then
			handle:Dispose()
		elseif
			handle.Owner == owner
			and handle.CanMissingFrame
			and not handle.Hidden
			and #selected < (Config.MissingFrameMaxThreats or 96)
		then
			local ok, moving = motionCall(handle, "Moving")
			if not ok then
				handle:Dispose()
			elseif moving then
				handle.Hidden = true
				local hidden = motionCall(handle, "Hide", true)
				if hidden then
					table.insert(selected, handle)
				else
					handle:Dispose()
				end
			end
		end
	end
	if #selected == 0 then
		return 0
	end
	 
	 
	owner:SetAttribute(
		"MissingFrameDamageGraceUntil",
		math.max(
			owner:GetAttribute("MissingFrameDamageGraceUntil") or 0,
			workspace:GetServerTimeNow() + hiddenDuration + (Config.MissingFrameDamageGrace or 0.22)
		)
	)
	local cast = Effects.NewCast(owner, "MissingFrameProjectileSkip", hiddenDuration + 0.4)
	local finished = false
	cast.OnDispose = function()
		for _, handle in ipairs(selected) do
			restoreMotion(handle)
		end
	end
	cast:Schedule(hiddenDuration, function()
		if finished then
			return
		end
		finished = true
		for _, handle in ipairs(selected) do
			if not handle.Closed and not handle.Options.Cast.closed then
				local ok, moving = motionCall(handle, "Moving")
				if not ok then
					handle:Dispose()
				elseif moving then
					local advanced, result = motionCall(handle, "Advance", seconds)
					if not advanced or result == false then
						handle:Dispose()
					elseif handle.Options.Settle then
						motionCall(handle, "Settle")
					end
				end
			end
			restoreMotion(handle)
		end
		cast:Dispose()
	end)
	return #selected
end
local function activeTarget(character)
	local h = character and character:FindFirstChildOfClass("Humanoid")
	local player = character and (Players:GetPlayerFromCharacter(character) or knownPlayers[character])
	if player then
		knownPlayers[character] = player
	end
	return character
		and character.Parent
		and h
		and h.Health > 0
		and character:FindFirstChild("HumanoidRootPart")
		and (
			not player
			or player.Parent == Players
				and player.Character == character
				and not player:GetAttribute("PermanentlyDefeated")
				and not player:GetAttribute("ViewAsServer")
		)
end
local function counter(owner)
	local value = counts[owner]
	if not value then
		value = { Golden = 0, Time = 0 }
		counts[owner] = value
	end
	return value
end
function api.Capacity(actor, kind)
	local cap = kind == "Time" and Config.MaxActiveTimeBullets or Config.MaxActiveGoldenBullets
	return math.max(0, cap - counter(ownerOf(actor))[kind])
end
local function part(cast, name, size, color, alpha, position)
	local p = Effects.AcquirePart()
	p.Name = name
	p.Size = size
	p.Color = color
	p.Transparency = alpha
	p.Shape = Enum.PartType.Ball
	p.CFrame = CFrame.new(position)
	p.Parent = Runtime.Effects
	cast:Add(p)
	return p
end
 
local function trail(body, color)
	local a = Instance.new("Attachment")
	a.Position = Vector3.new(0, 0.25, 0)
	a.Parent = body
	local b = Instance.new("Attachment")
	b.Position = Vector3.new(0, -0.25, 0)
	b.Parent = body
	local t = Instance.new("Trail")
	t.Name = "BulletEnergyTrail"
	t.Attachment0 = a
	t.Attachment1 = b
	t.Color = ColorSequence.new(WHITE, color)
	t.LightEmission = 1
	t.FaceCamera = true
	t.Lifetime = 0.14
	t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
	t.MinLength = 0.1
	t.Parent = body
	return t
end

 
local sparkTemplate = Instance.new("ParticleEmitter")
sparkTemplate.Name = "TimeSparks"
sparkTemplate.Enabled = false
sparkTemplate.Rate = 0
sparkTemplate.Lifetime = NumberRange.new(0.35, 0.75)
sparkTemplate.Speed = NumberRange.new(8, 22)
sparkTemplate.SpreadAngle = Vector2.new(180, 180)
sparkTemplate.Drag = 5
sparkTemplate.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0) })
sparkTemplate.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
sparkTemplate.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, WHITE),
	ColorSequenceKeypoint.new(0.4, TIME),
	ColorSequenceKeypoint.new(1, DEEP),
})
sparkTemplate.LightEmission = 1
sparkTemplate.RotSpeed = NumberRange.new(-240, 240)
local goldSparkTemplate = sparkTemplate:Clone()
goldSparkTemplate.Name = "GoldSparks"
goldSparkTemplate.Acceleration = Vector3.new(0, -16, 0)
goldSparkTemplate.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, WHITE),
	ColorSequenceKeypoint.new(0.35, GOLD),
	ColorSequenceKeypoint.new(1, ORANGE),
})

local clockTemplate
local function circle(name, parent, size, color, alpha)
	local f = Instance.new("Frame")
	f.Name = name
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.fromScale(size, size)
	f.BackgroundColor3 = color
	f.BackgroundTransparency = alpha
	f.BorderSizePixel = 0
	f.Parent = parent
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(1, 0)
	round.Parent = f
	return f
end
local function handFrame(parent, name, width, length, color)
	 
	local holder = Instance.new("Frame")
	holder.Name = name
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.Parent = parent
	local line = Instance.new("Frame")
	line.Name = "Blade"
	line.AnchorPoint = Vector2.new(0.5, 1)
	line.Position = UDim2.fromScale(0.5, 0.5)
	line.Size = UDim2.fromScale(width, length)
	line.BackgroundColor3 = color
	line.BorderSizePixel = 0
	line.Parent = holder
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(1, 0)
	round.Parent = line
	return holder
end
local function getClockTemplate()
	if clockTemplate then
		return clockTemplate
	end
	 
	local gui = Instance.new("BillboardGui")
	gui.Name = "TimeBulletClock"
	gui.Size = UDim2.fromScale(3.6, 3.6)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 260
	gui.LightInfluence = 0
	gui.Active = false
	circle("Halo", gui, 1, TIME, 0.8)
	local face = circle("ClockFace", gui, 0.78, FACE, 0.12)
	local rim = Instance.new("UIStroke")
	rim.Name = "Rim"
	rim.Color = TIME
	rim.Thickness = 2
	rim.Parent = face
	 
	local gear = Instance.new("Frame")
	gear.Name = "GearRing"
	gear.AnchorPoint = Vector2.new(0.5, 0.5)
	gear.Position = UDim2.fromScale(0.5, 0.5)
	gear.Size = UDim2.fromScale(1, 1)
	gear.BackgroundTransparency = 1
	gear.BorderSizePixel = 0
	gear.Parent = face
	for index = 0, 7 do
		local a = index * math.pi / 4
		local major = index % 2 == 0
		local tick = Instance.new("Frame")
		tick.Name = "Tick"
		tick.AnchorPoint = Vector2.new(0.5, 0.5)
		tick.Position = UDim2.fromScale(0.5 + math.sin(a) * 0.41, 0.5 - math.cos(a) * 0.41)
		tick.Size = major and UDim2.fromScale(0.075, 0.13) or UDim2.fromScale(0.05, 0.08)
		tick.Rotation = index * 45
		tick.BackgroundColor3 = major and WHITE or TIME
		tick.BorderSizePixel = 0
		tick.Parent = gear
	end
	local inner = circle("InnerRing", face, 0.56, TIME, 1)
	local innerStroke = Instance.new("UIStroke")
	innerStroke.Color = TIME
	innerStroke.Thickness = 1
	innerStroke.Transparency = 0.55
	innerStroke.Parent = inner
	handFrame(face, "HourHand", 0.07, 0.27, WHITE)
	handFrame(face, "MinuteHand", 0.05, 0.38, WHITE)
	handFrame(face, "SecondHand", 0.025, 0.45, GOLD)
	circle("Pivot", face, 0.13, WHITE, 0)
	clockTemplate = gui
	return gui
end
local function attachClock(body)
	local gui = getClockTemplate():Clone()
	gui.Enabled = false
	gui.Parent = body
	local face = gui.ClockFace
	return {
		Gui = gui,
		Halo = gui.Halo,
		Face = face,
		Rim = face.Rim,
		Gear = face.GearRing,
		Hour = face.HourHand,
		Minute = face.MinuteHand,
		Second = face.SecondHand,
	}
end
local function buildTimeFX(body)
	local fx = { Trails = {}, All = {} }
	local function attach(name, y)
		local a = Instance.new("Attachment")
		a.Name = name
		a.Position = Vector3.new(0, y, 0)
		a.Parent = body
		table.insert(fx.All, a)
		return a
	end
	 
	local a0, a1 = attach("TrailTop", 0.42), attach("TrailBottom", -0.42)
	local main = Instance.new("Trail")
	main.Name = "BulletEnergyTrail"
	main.Attachment0 = a0
	main.Attachment1 = a1
	main.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, WHITE),
		ColorSequenceKeypoint.new(0.3, TIME),
		ColorSequenceKeypoint.new(1, DEEP),
	})
	main.LightEmission = 1
	main.FaceCamera = true
	main.Lifetime = 0.34
	main.MinLength = 0.05
	main.Enabled = false
	main.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.5, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	main.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
	main.Parent = body
	fx.Main = main
	table.insert(fx.All, main)
	 
	local b0, b1 = attach("SmearTop", 1.05), attach("SmearBottom", -1.05)
	local smear = Instance.new("Trail")
	smear.Name = "TimeSmear"
	smear.Attachment0 = b0
	smear.Attachment1 = b1
	smear.Color = ColorSequence.new(TIME, DEEP)
	smear.LightEmission = 0.5
	smear.FaceCamera = true
	smear.Lifetime = 0.6
	smear.MinLength = 0.1
	smear.Enabled = false
	smear.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 1) })
	smear.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.1) })
	smear.Parent = body
	table.insert(fx.Trails, smear)
	table.insert(fx.All, smear)
	 
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "TimeSand"
	emitter.Rate = 28
	emitter.Lifetime = NumberRange.new(0.45, 0.85)
	emitter.Speed = NumberRange.new(0.5, 2.5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = 2
	emitter.Acceleration = Vector3.new(0, 1.5, 0)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.26), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, WHITE),
		ColorSequenceKeypoint.new(0.4, GOLD),
		ColorSequenceKeypoint.new(1, TIME),
	})
	emitter.LightEmission = 1
	emitter.RotSpeed = NumberRange.new(-180, 180)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.LockedToPart = false
	emitter.Enabled = false
	emitter.Parent = body
	fx.Emitter = emitter
	table.insert(fx.All, emitter)
	local light = Instance.new("PointLight")
	light.Name = "TimeGlow"
	light.Color = TIME
	light.Range = 8
	light.Brightness = 1.5
	light.Shadows = false
	light.Enabled = false
	light.Parent = body
	fx.Light = light
	table.insert(fx.All, light)
	return fx
end
 
local function setTimeVisual(record, state)
	local fx = record.FX
	if
		not fx
		or record.FXKind ~= "Time"
		or record.Removed
		or not record.Body.Parent
		or Effects.LeaseId(record.Body) ~= record.BodyLease
	then
		return
	end
	state = state or STATE_OF[record.State] or "Summon"
	local body = record.Body
	body:SetAttribute("TimeState", state)
	local paused = (record.CollapsePauseRemaining or 0) > 0
	local flying = state == "Flying" and not paused
	record.Trail.Enabled = flying
	for _, extra in ipairs(fx.Trails) do
		extra.Enabled = flying
	end
	local emitter, light = fx.Emitter, fx.Light
	if state == "Flying" then
		emitter.Enabled = not paused
		emitter.Rate = 28
		light.Enabled = true
		light.Brightness = 1.7
		light.Range = 9
		light.Color = TIME
		body.Color = CORE
	elseif state == "Cue" then
		emitter.Enabled = true
		emitter.Rate = 75
		light.Enabled = true
		light.Brightness = 3.2
		light.Range = 14
		light.Color = WHITE
		body.Color = WHITE
	elseif state == "Frozen" then
		emitter.Enabled = false
		light.Enabled = true
		light.Brightness = 0.5
		light.Range = 6
		light.Color = FROZEN
		body.Color = FROZEN
	else  
		emitter.Enabled = true
		emitter.Rate = 40
		light.Enabled = true
		light.Brightness = 1
		light.Range = 7
		light.Color = TIME
		body.Color = CORE
	end
	local clock = record.Clock
	if clock then
		local rim = clock.Rim
		if state == "Cue" then
			rim.Color = WHITE
			rim.Thickness = 4
		elseif state == "Frozen" then
			rim.Color = FROZEN
			rim.Thickness = 2
		else
			rim.Color = TIME
			rim.Thickness = 2
		end
	end
end
 
 
 
local flareTemplate
local function getFlareTemplate()
	if flareTemplate then
		return flareTemplate
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "GoldenBulletFlare"
	gui.Size = UDim2.fromScale(3.2, 3.2)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 220
	gui.LightInfluence = 0
	gui.Active = false
	circle("Glow", gui, 1, GOLD, 0.82)
	circle("Bloom", gui, 0.5, WHITE, 0.5)
	local function streak(name, width, height, rotation, alpha)
		local f = Instance.new("Frame")
		f.Name = name
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.Size = UDim2.fromScale(width, height)
		f.Rotation = rotation
		f.BackgroundColor3 = WHITE
		f.BackgroundTransparency = alpha
		f.BorderSizePixel = 0
		f.Parent = gui
		local round = Instance.new("UICorner")
		round.CornerRadius = UDim.new(1, 0)
		round.Parent = f
	end
	streak("FlareH", 1, 0.07, 0, 0.35)
	streak("FlareV", 0.07, 1, 0, 0.35)
	streak("FlareD1", 0.68, 0.04, 45, 0.55)
	streak("FlareD2", 0.68, 0.04, -45, 0.55)
	circle("Core", gui, 0.2, Color3.new(1, 1, 1), 0)
	flareTemplate = gui
	return gui
end
local function buildGoldFX(body, withLight)
	local fx = { Trails = {}, All = {} }
	local function attach(name, y)
		local a = Instance.new("Attachment")
		a.Name = name
		a.Position = Vector3.new(0, y, 0)
		a.Parent = body
		table.insert(fx.All, a)
		return a
	end
	local a0, a1 = attach("TrailTop", 0.34), attach("TrailBottom", -0.34)
	local main = Instance.new("Trail")
	main.Name = "BulletEnergyTrail"
	main.Attachment0 = a0
	main.Attachment1 = a1
	main.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, WHITE),
		ColorSequenceKeypoint.new(0.3, GOLD),
		ColorSequenceKeypoint.new(1, ORANGE),
	})
	main.LightEmission = 1
	main.FaceCamera = true
	main.Lifetime = 0.28
	main.MinLength = 0.05
	main.Enabled = false
	main.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1, 1),
	})
	main.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
	main.Parent = body
	fx.Main = main
	table.insert(fx.All, main)
	local b0, b1 = attach("GlowTop", 0.8), attach("GlowBottom", -0.8)
	local glow = Instance.new("Trail")
	glow.Name = "GoldenGlowTrail"
	glow.Attachment0 = b0
	glow.Attachment1 = b1
	glow.Color = ColorSequence.new(GOLD, AMBER)
	glow.LightEmission = 0.6
	glow.FaceCamera = true
	glow.Lifetime = 0.45
	glow.MinLength = 0.1
	glow.Enabled = false
	glow.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	glow.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.1) })
	glow.Parent = body
	table.insert(fx.Trails, glow)
	table.insert(fx.All, glow)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "GoldenEmbers"
	emitter.Rate = 34
	emitter.Lifetime = NumberRange.new(0.3, 0.6)
	emitter.Speed = NumberRange.new(0.5, 3)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Drag = 3
	emitter.Acceleration = Vector3.new(0, -4, 0)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.24), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, WHITE),
		ColorSequenceKeypoint.new(0.4, GOLD),
		ColorSequenceKeypoint.new(1, ORANGE),
	})
	emitter.LightEmission = 1
	emitter.RotSpeed = NumberRange.new(-200, 200)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.LockedToPart = false
	emitter.Enabled = false
	emitter.Parent = body
	fx.Emitter = emitter
	table.insert(fx.All, emitter)
	if withLight then
		local light = Instance.new("PointLight")
		light.Name = "GoldenGlow"
		light.Color = GOLD
		light.Range = 9
		light.Brightness = 1.6
		light.Shadows = false
		light.Parent = body
		fx.Light = light
		table.insert(fx.All, light)
	end
	local flare = getFlareTemplate():Clone()
	flare.Enabled = false
	flare.Parent = body
	fx.Flare = flare
	table.insert(fx.All, flare)
	return fx
end
local function setGoldVisual(record)
	local fx = record.FX
	if
		not fx
		or record.FXKind ~= "Gold"
		or record.Removed
		or not record.Body.Parent
		or Effects.LeaseId(record.Body) ~= record.BodyLease
	then
		return
	end
	local paused = (record.CollapsePauseRemaining or 0) > 0
	local flying = record.State == "Flying" and not paused
	record.Trail.Enabled = flying
	for _, extra in ipairs(fx.Trails) do
		extra.Enabled = flying
	end
	fx.Emitter.Enabled = flying
	if fx.Light then
		fx.Light.Enabled = not paused
	end
	fx.Flare.Enabled = not paused
end
 
local function refreshVisual(record, state)
	if record.FXKind == "Time" then
		setTimeVisual(record, state)
	elseif record.FXKind == "Gold" then
		setGoldVisual(record)
	end
end

local function destroyFX(record)
	local fx = record.FX
	if not fx then
		return
	end
	record.FX = nil
	if Effects.LeaseId(record.Body) == record.BodyLease then
		CollectionService:RemoveTag(record.Body, VISUAL_TAG)
		record.Body:SetAttribute("TimeState", nil)
		record.Body:SetAttribute("TimePhase", nil)
	end
	for _, item in ipairs(fx.All) do
		item:Destroy()
	end
	if record.Clock then
		record.Clock.Gui:Destroy()
		record.Clock = nil
	end
end

local function closest(point, a, b)
	local delta = b - a
	local length = delta:Dot(delta)
	local t = length > 0.0001 and math.clamp((point - a):Dot(delta) / length, 0, 1) or 0
	local offset = point - (a + delta * t)
	return offset:Dot(offset), t
end
local function turnTowards(current, desired, maxAngle)
	local dot = math.clamp(current:Dot(desired), -1, 1)
	local angle = math.acos(dot)
	if angle <= maxAngle then
		return desired
	end
	local axis = current:Cross(desired)
	if axis.Magnitude < 0.0001 then
		axis = current:Cross(math.abs(current.Y) < 0.9 and Vector3.yAxis or Vector3.xAxis)
	end
	return CFrame.fromAxisAngle(axis.Unit, maxAngle):VectorToWorldSpace(current).Unit
end
function api.Burst(actor, target, options)
 target = require(BossSystem.Combat.AttackTargetContinuity).For(target)
	local kind = options.Kind
	local owner = ownerOf(actor)
	local h = owner:FindFirstChildOfClass("Humanoid")
	local core = Registry.For(actor, "P1CombatCore")
	local count = math.min(options.Count, api.Capacity(actor, kind))
	if count <= 0 or not activeTarget(target) then
		return false
	end
	local usage = counter(owner)
	local homingDuration = kind == "Golden" and math.clamp(options.HomingDuration or 0, 0, 8) or 0
	local knives = options.Visual == "Knife"
	local horizontalAim = knives and options.HorizontalAim == true
	local function aimPoint(position, point)
		return horizontalAim and Vector3.new(point.X, position.Y, point.Z) or point
	end
	local fixedDirections = options.Directions or options.SpawnDirections
	local spatialVolley = kind == "Golden" and fixedDirections ~= nil and options.LockedTrajectory == true
	if knives and fixedDirections then
		homingDuration = 0
	end
	local preparation = knives and ((options.AimDuration or 0) + (options.ReactionCue or 0)) or 0
	 
	local summon = kind == "Time" and math.clamp(options.SummonTime or 0, 0, 1.5) or 0
	local stagger = summon > 0 and math.min(0.04, summon * 0.6 / math.max(count, 1)) or 0
	local flightLifetime = options.FlightLifetime or (homingDuration > 0 and homingDuration + 1 or 2)
	local duration = kind == "Time" and Config.TimeBulletMaxDelay + 12
		or math.max(3.5, flightLifetime + 0.5) + (options.LaunchDelay or 0) + preparation
	local cast = Effects.NewCast(actor, "P2" .. kind .. "Bullets", duration)
	local records = {}
	local hitCounts = setmetatable({}, { __mode = "k" })
	local phase = owner:GetAttribute("Phase")
	local generation = owner:GetAttribute("PhaseGeneration") or 0
	local frame = core.Root.CFrame
	local aim = options.PreparedAim or target.HumanoidRootPart.Position
	local speed = options.Speed or (kind == "Time" and Config.TimeBulletSpeed or Config.GoldenBulletSpeed)
	local damage = (options.Damage or (kind == "Time" and Config.TimeBulletDamage or Config.GoldenBulletDamage))
		* (options.DamageScale or 1)
	local launchJobs = {}
	local volleyAudible = false
	local function retire(record)
		if record.Removed then
			return
		end
		record.Removed = true
		usage[kind] = math.max(0, usage[kind] - 1)
		if record.Motion then
			record.Motion:Dispose()
		end
		if record.Deferred then
			TimeEffects.UnregisterDeferred(record.Deferred)
		end
		destroyFX(record)
		if Effects.LeaseId(record.Body) == record.BodyLease then
			Effects.Release(record.Body)
		end
		if record.Guard and Effects.LeaseId(record.Guard) == record.GuardLease then
			Effects.Release(record.Guard)
		end
		for _, item in ipairs(record.KnifeParts or {}) do
			if Effects.LeaseId(item.Part) == item.Lease then
				Effects.Release(item.Part)
			end
		end
	end
	cast.OnDispose = function()
		for _, record in ipairs(records) do
			retire(record)
		end
	end
	local function flash(position, color, scale)
		local light = part(cast, "BulletImpact", Vector3.one, color, 0.12, position)
		Effects:Create(light, TweenInfo.new(0.2), { Size = Vector3.one * scale, Transparency = 1 }):Play()
		Effects.ReleaseAfter(light, 0.23)
	end
	 
	local function shock(position, direction, color, radius)
		local dir = direction and direction.Magnitude > 0.01 and direction.Unit or Vector3.yAxis
		local up = math.abs(dir.Y) > 0.99 and Vector3.xAxis or Vector3.yAxis
		local ring = part(cast, "BulletShock", Vector3.new(0.1, 0.4, 0.4), color, 0.1, position)
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.Neon
		ring.CFrame = CFrame.lookAt(position, position + dir, up) * CFrame.Angles(0, math.pi / 2, 0)
		Effects:Create(
			ring,
			TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.1, radius * 2, radius * 2), Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(ring, 0.3)
	end
	local function sparks(position, amount, gold)
		local anchor = part(cast, "BulletSparks", Vector3.one * 0.2, gold and GOLD or TIME, 1, position)
		local emitter = (gold and goldSparkTemplate or sparkTemplate):Clone()
		emitter.Parent = anchor
		emitter:Emit(amount)
		Debris:AddItem(emitter, 1.2)
		Effects.ReleaseAfter(anchor, 1.2)
	end
	local function aimDirection(record)
		local root = target and target:FindFirstChild("HumanoidRootPart")
		if root then
			local delta = root.Position - record.Position
			if delta.Magnitude > 0.01 then
				return delta.Unit
			end
		end
		return record.InitialDirection or frame.LookVector
	end
	 
	local function appear(record)
		if record.Appeared or record.Removed then
			return
		end
		if not record.Body.Parent or Effects.LeaseId(record.Body) ~= record.BodyLease then
			return
		end
		record.Appeared = true
		local body = record.Body
		body.Transparency = options.Transparency or 0.06
		if record.Clock then
			record.Clock.Gui.Enabled = true
		end
		if record.State == "Materializing" then
			Effects:Create(
				body,
				TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Size = Vector3.one * TIME_SIZE }
			):Play()
			shock(record.Position, record.InitialDirection, TIME, 2.6)
		else
			body.Size = Vector3.one * TIME_SIZE
		end
		setTimeVisual(record)
	end
	local function fire(record, position)
		if record.Removed then
			return
		end
		if not record.Body.Parent or Effects.LeaseId(record.Body) ~= record.BodyLease then
			retire(record)
			return
		end
		if kind == "Time" then
			appear(record)
		end
		record.State = "Flying"
		record.Pass = (record.Pass or 0) + 1
		record.Age = 0
		if options.VolleyCue and not volleyAudible then
			volleyAudible = true
			Audio.Emit(actor, options.VolleyCue, record.Body)
		end
		if options.ShotCue then
			Audio.Emit(actor, options.ShotCue, record.Body)
		end
		if record.Deferred then
			TimeEffects.UnregisterDeferred(record.Deferred)
			record.Deferred = nil
		end
		record.HitTargets = setmetatable({}, { __mode = "k" })
		record.Body.Transparency = options.Transparency or 0.05
		record.Trail.Enabled = true
		local delta = position - record.Position
		record.Direction = delta.Magnitude > 0.01 and delta.Unit or frame.LookVector
		if record.Pass == 1 and (kind == "Golden" or options.LockedTrajectory) then
			record.Direction = record.InitialDirection
		end
		record.Travelled = 0
		record.MaxDistance = options.MaxDistance
		if knives then
			record.MaxDistance = options.MaxDistance
				or options.Range
				or ((position - record.Position).Magnitude + (options.PastTargetDistance or 14))
			for _, item in ipairs(record.KnifeParts or {}) do
				if item.Warning and item.Part.Parent then
					item.Part.Transparency = 1
				end
			end
		end
		if kind == "Time" then
			setTimeVisual(record, "Flying")
			flash(record.Position, TIME, 2)
		elseif record.FXKind == "Gold" then
			setGoldVisual(record)
		end
	end
	local function dormant(record)
		if record.Removed or not record.Body.Parent or Effects.LeaseId(record.Body) ~= record.BodyLease then
			retire(record)
			return
		end
		record.State = "Dormant"
		record.Trail.Enabled = false
		record.Body.Transparency = 0.5
		setTimeVisual(record, "Frozen")
		 
		shock(record.Position, record.Direction or record.InitialDirection, FROZEN, 2.2)
		local delay = random:NextNumber(Config.TimeBulletMinDelay, Config.TimeBulletMaxDelay)
		record.HiddenDelay = delay
		record.FrozenAt = cast:Now()
		record.RelaunchJob = cast:Schedule(delay, function()
			if record.Removed or not (spatialVolley or activeTarget(target)) then
				return
			end
			if not record.Body.Parent or Effects.LeaseId(record.Body) ~= record.BodyLease then
				retire(record)
				return
			end
			record.State = "Cue"
			record.Body.Transparency = 0.05
			setTimeVisual(record, "Cue")
			 
			shock(record.Position, aimDirection(record), WHITE, 3)
			cast:Schedule(0.18, function()
				if not record.Removed and activeTarget(target) then
					fire(record, target.HumanoidRootPart.Position)
				end
			end)
		end)
		local token = {}
		function token.Alive()
			return not cast.closed
				and not record.Removed
				and record.State == "Dormant"
				and record.Body.Parent ~= nil
				and Effects.LeaseId(record.Body) == record.BodyLease
		end
		function token.Advance(seconds, force)
			if not token.Alive() then
				return false
			end
			return cast:Reschedule(
				record.RelaunchJob,
				force and 0.01 or math.max(0.01, record.RelaunchJob.at - cast:Now() - seconds)
			)
		end
		record.Deferred = TimeEffects.RegisterDeferred(owner, token)
	end
	local function stop(record, impact)
		if impact then
			flash(record.Position, kind == "Time" and TIME or WHITE, 4)
			if kind == "Time" then
				sparks(record.Position, 18)
			elseif record.FXKind == "Gold" then
				sparks(record.Position, 18, true)
				shock(record.Position, record.Direction, GOLD, 2.8)
			end
		end
		retire(record)
	end
	local center = options.Origin or frame.Position + Vector3.new(0, 1, 0) + frame.LookVector * 3
	local forward = (aim - center).Magnitude > 0.01 and (aim - center).Unit or frame.LookVector
	if kind == "Golden" and not options.NoMuzzleFlash then
		flash(center, WHITE, 7)
		if not knives then
			 
			shock(center, forward, GOLD, 6)
			shock(center, forward, WHITE, 3.2)
			sparks(center, 30, true)
		end
	end
	local aimFrame = CFrame.lookAt(Vector3.zero, forward)
	for index = 1, count do
		local position = options.SpawnPositions and options.SpawnPositions[index] or center
		if options.SpawnPositions then
			 
		elseif kind == "Time" then
			local angle = index * 2.399963
			local radius = 9 + math.floor((index - 1) / 6) * 4
			local offset = Vector3.new(
				math.sin(angle) * radius,
				4 + (index % 5) * 2.3 + random:NextNumber(-0.4, 0.4),
				7 + math.abs(math.cos(angle)) * radius
			)
			local spawnFrame = options.Origin and CFrame.lookAt(center, aim) or frame
			position = spawnFrame:PointToWorldSpace(offset)
			local ground = Placement.GroundPoint(position, { Margin = 5, Clamp = true })
			if ground then
				position = Vector3.new(ground.X, math.max(ground.Y + 5, position.Y), ground.Z)
			end
			 
			for _, previous in ipairs(records) do
				if (previous.Position - position).Magnitude < 2 then
					position += Vector3.new(0, 2.5, 0)
				end
			end
		elseif (options.SpawnRadius or 0) > 0 then
			local angle = index * 2.399963
			local radius = math.sqrt(index / count) * options.SpawnRadius
			position = center
				+ Vector3.new(
					math.sin(angle) * radius,
					random:NextNumber(-1, 1) * (options.SpawnHeightSpread or 0),
					math.cos(angle) * radius
				)
			local ground = Placement.GroundPoint(position, { Margin = 5, Clamp = true })
			if ground then
				position = Vector3.new(ground.X, math.max(ground.Y + 3.2, position.Y), ground.Z)
			end
		end
		local body = part(
			cast,
			kind == "Time" and "TimeBullet" or "GoldenBullet",
			Vector3.one * (kind == "Time" and TIME_SIZE or 0.7),
			kind == "Time" and CORE or GOLD,
			options.Transparency or 0.12,
			position
		)
		local record = { Position = position, Body = body, BodyLease = Effects.LeaseId(body), State = "Materializing" }
		if kind == "Time" then
			body.Material = Enum.Material.Neon
			record.FX = buildTimeFX(body)
			record.Trail = record.FX.Main
			record.FXKind = "Time"
			record.Clock = attachClock(body)
			body:SetAttribute("TimeState", "Summon")
			body:SetAttribute("TimePhase", random:NextNumber(0, 6.2832))
			CollectionService:AddTag(body, VISUAL_TAG)
			 
			body.Size = Vector3.one * 0.2
			body.Transparency = 1
			cast:Schedule((index - 1) * stagger, function()
				appear(record)
			end)
		elseif kind == "Golden" and not knives then
			body.Material = Enum.Material.Neon
			body.Color = BULLET_GOLD
			body.Size = Vector3.one * 0.8
			record.FX = buildGoldFX(body, index % 3 == 1)
			record.Trail = record.FX.Main
			record.FXKind = "Gold"
			setGoldVisual(record)
		else
			record.Trail = trail(body, GOLD)
		end
		if knives then
			body.Name = "TargetedKnifeBlade"
			body.Shape = Enum.PartType.Block
			body.Size = Vector3.new(0.65, 0.16, 2.2)
			body.Material = Enum.Material.Metal
			body.Color = GOLD
			body:SetAttribute("GoldenKnife", true)
			record.Guard = part(
				cast,
				"TargetedKnifeGuard",
				Vector3.new(1.3, 0.28, 0.24),
				Color3.fromRGB(184, 124, 33),
				0,
				position
			)
			record.Guard.Shape = Enum.PartType.Block
			record.Guard.Material = Enum.Material.Metal
			record.GuardLease = Effects.LeaseId(record.Guard)
			local tip = part(cast, "TargetedKnifePoint", Vector3.new(0.16, 0.65, 0.95), body.Color, 0, position)
			tip.Material = Enum.Material.Metal
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Wedge
			mesh.Parent = tip
			local handle =
				part(cast, "TargetedKnifeGrip", Vector3.new(0.3, 0.3, 0.95), Color3.fromRGB(52, 38, 27), 0, position)
			handle.Material = Enum.Material.SmoothPlastic
			record.KnifeParts = {
				{
					Part = tip,
					Lease = Effects.LeaseId(tip),
					Offset = CFrame.new(0, 0, -1.52) * CFrame.Angles(0, 0, math.pi * 0.5),
				},
				{ Part = handle, Lease = Effects.LeaseId(handle), Offset = CFrame.new(0, 0, 1.8) },
			}
			if options.ArrowWarnings then
				for _, warning in ipairs({
					{
						Name = "KnifeAimArrowShaft",
						Size = Vector3.new(0.17, 0.12, 3),
						Offset = CFrame.new(0, 0.7, -3.4),
					},
					{
						Name = "KnifeAimArrowLeft",
						Size = Vector3.new(0.17, 0.12, 1.6),
						Offset = CFrame.new(-0.43, 0.7, -4.35) * CFrame.Angles(0, -math.pi / 4, 0),
					},
					{
						Name = "KnifeAimArrowRight",
						Size = Vector3.new(0.17, 0.12, 1.6),
						Offset = CFrame.new(0.43, 0.7, -4.35) * CFrame.Angles(0, math.pi / 4, 0),
					},
				}) do
					local arrow = part(cast, warning.Name, warning.Size, GOLD, 0.1, position)
					arrow.Shape = Enum.PartType.Block
					arrow:SetAttribute("KnifeWarning", "Aiming")
					table.insert(
						record.KnifeParts,
						{ Part = arrow, Lease = Effects.LeaseId(arrow), Offset = warning.Offset, Warning = true }
					)
				end
			end
			record.Trail.Enabled = false
			record.State = "Aiming"
			if options.FollowTargetDuringAim then
				record.TrackingOffset = position - target.HumanoidRootPart.Position
			end
		end
		usage[kind] += 1
		table.insert(records, record)
		local radius = knives and 0
			or index == 1 and 0
			or math.sqrt((index - 1) / (count - 1)) * math.tan(math.rad(options.SpreadDegrees or 16))
		local angle = index * 2.399963 + random:NextNumber(-0.08, 0.08)
		local preparedAim = aimPoint(position, aim)
		local recordAim = (preparedAim - position).Magnitude > 0.01
				and CFrame.lookAt(Vector3.zero, (preparedAim - position).Unit)
			or aimFrame
		record.InitialDirection =
			recordAim:VectorToWorldSpace(Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius, -1)).Unit
		if
			fixedDirections
			and typeof(fixedDirections[index]) == "Vector3"
			and fixedDirections[index].Magnitude > 0.001
		then
			record.InitialDirection = fixedDirections[index].Unit
			record.FixedHeading = knives
		end
		record.Body:SetAttribute("PreparedDirection", record.InitialDirection)
		if knives then
			 
			 
			body.CFrame = CFrame.lookAt(position, position + record.InitialDirection)
			record.Guard.CFrame = body.CFrame * CFrame.new(0, 0, 1.18)
			for _, item in ipairs(record.KnifeParts) do
				item.Part.CFrame = body.CFrame * item.Offset
			end
		end
		record.HomingDuration = homingDuration
		if knives then
			cast:Schedule(options.AimDuration or 0, function()
				if record.Removed or not (spatialVolley or activeTarget(target)) then
					return
				end
				if not record.Body.Parent or Effects.LeaseId(record.Body) ~= record.BodyLease then
					retire(record)
					return
				end
				record.State = "Cue"
				record.LockedAim = record.FixedHeading
						and record.Position + record.InitialDirection * (options.Range or options.MaxDistance or 130)
					or aimPoint(record.Position, target.HumanoidRootPart.Position)
				if not record.FixedHeading then
					local delta = record.LockedAim - record.Position
					record.InitialDirection = delta.Magnitude > 0.01 and delta.Unit or frame.LookVector
				end
				record.Body.Color = options.KnifeTurnsRed and Color3.fromRGB(255, 60, 55) or GOLD
				record.Body.Transparency = 0
				if options.KnifeTurnsRed then
					for _, item in ipairs(record.KnifeParts or {}) do
						if not item.Warning and item.Part.Name == "TargetedKnifePoint" then
							item.Part.Color = record.Body.Color
						end
					end
				end
				for _, item in ipairs(record.KnifeParts or {}) do
					if item.Warning and item.Part.Parent then
						item.Part.Color = Color3.fromRGB(255, 60, 55)
						item.Part:SetAttribute("KnifeWarning", "Launching")
					end
				end
			end)
		end
		launchJobs[index] = cast:Schedule(
			preparation + (options.LaunchDelay or 0) + summon + (kind == "Time" and (index - 1) * 0.065 or 0),
			function()
				if spatialVolley or activeTarget(target) or options.PreserveAfterCue and record.LockedAim then
					fire(record, record.LockedAim or (kind == "Time" and target.HumanoidRootPart.Position or aim))
				end
			end
		)
	end
	if not options.IsLastMinuteEcho and not knives then
		local emissionName = options.Skill or actor:GetAttribute("CurrentAttackFile")
		local definition = emissionName and Metadata.Get(emissionName)
		if definition and definition.CanLastMinuteEcho then
			local positions, directions = {}, {}
			local echoCount = math.min(count, Config.LastMinuteEchoProjectileMaxCount)
			for i = 1, echoCount do
				local index = math.clamp(math.floor((i - 0.5) * count / echoCount) + 1, 1, count)
				positions[i] = records[index].Position
				directions[i] = records[index].InitialDirection
			end
			local snapshot = table.freeze({
				Kind = kind,
				Count = echoCount,
				Positions = table.freeze(positions),
				Directions = table.freeze(directions),
				Aim = aim,
				Speed = speed,
				Damage = damage,
				Skill = emissionName,
			})
			local delay = require(BossSystem.Phases.Phase25Controller).OnTemporalEmission(
				actor,
				emissionName,
				snapshot,
				function(saved, echo)
					return api.Burst(actor, target, {
						Kind = saved.Kind,
						Count = saved.Count,
						SpawnPositions = saved.Positions,
						SpawnDirections = saved.Directions,
						PreparedAim = saved.Aim,
						Speed = saved.Speed,
						Damage = saved.Damage,
						Skill = saved.Skill,
						LockedTrajectory = true,
						NoMuzzleFlash = true,
						IsLastMinuteEcho = true,
						VolleyCue = options.VolleyCue,
						ShotCue = options.ShotCue,
						DamageScale = echo.DamageScale,
						Transparency = echo.Transparency,
						CollapsePause = echo.CollapsePause,
					})
				end
			) or 0
			if delay > 0 then
				for _, job in ipairs(launchJobs) do
					cast:Reschedule(job, math.max(0, job.at - cast:Now()) + delay)
				end
				cast.expires += delay
			end
		end
	end
	local params = core.Params()
	local visualClock = 0
	local targetBuffer = {}
	local collisionTargets
	local hitRadiusSquared = (options.HitRadius or 2.6) ^ 2
	local function hasCommittedKnife()
		if not knives or not options.PreserveAfterCue then
			return false
		end
		for _, record in ipairs(records) do
			if not record.Removed and record.LockedAim then
				return true
			end
		end
		return false
	end
	local function validBurst()
		local current = owner:GetAttribute("Phase")
		local samePhase = current == phase or phase == 2 and current == 2.5
		return owner.Parent
			and h
			and h.Health > 0
			and owner:GetAttribute("AIEnabled") ~= false
			and samePhase
			and (owner:GetAttribute("PhaseGeneration") or 0) == generation
			and (not owner:GetAttribute("PhaseTransitionInProgress") or owner:GetAttribute("TransitionKeepsTemporal"))
			and (spatialVolley or activeTarget(target) or hasCommittedKnife())
	end
	local function updateKnifeVisual(record)
		if not record.KnifeParts then
			return
		end
		if record.Guard and record.Guard.Parent and Effects.LeaseId(record.Guard) == record.GuardLease then
			record.Guard.CFrame = record.Body.CFrame * CFrame.new(0, 0, 1.18)
		end
		for _, item in ipairs(record.KnifeParts or {}) do
			if item.Part.Parent and Effects.LeaseId(item.Part) == item.Lease then
				item.Part.CFrame = record.Body.CFrame * item.Offset
			end
		end
	end
	local function updateRecord(record, dt, now, animate)
		if record.Removed then
			return
		end
		if not record.Body.Parent or Effects.LeaseId(record.Body) ~= record.BodyLease then
			retire(record)
			return
		end
		if record.Guard and (not record.Guard.Parent or Effects.LeaseId(record.Guard) ~= record.GuardLease) then
			record.Guard = nil
		end
		 
		if animate and not CLIENT_ANIM and record.Clock then
			record.Clock.Minute.Rotation = (now * 135) % 360
			record.Clock.Hour.Rotation = (now * 11) % 360
		end
		if knives and record.State == "Aiming" and not record.FixedHeading then
			if not activeTarget(target) then
				retire(record)
				return
			end
			if record.TrackingOffset then
				local requested = target.HumanoidRootPart.Position + record.TrackingOffset
				local ground = Placement.GroundPoint(requested, { Margin = 4, Clamp = true })
				if ground then
					local nextPosition = Vector3.new(ground.X, math.max(ground.Y + 2, requested.Y), ground.Z)
					record.Position = record.Position:Lerp(nextPosition, math.clamp(dt * 20, 0, 1))
				end
			end
			local delta = aimPoint(record.Position, target.HumanoidRootPart.Position) - record.Position
			if delta.Magnitude > 0.01 then
				record.InitialDirection = delta.Unit
			end
		end
		if knives and record.State ~= "Flying" then
			record.Body.CFrame = CFrame.lookAt(record.Position, record.Position + record.InitialDirection)
			updateKnifeVisual(record)
		end
		if record.State ~= "Flying" then
			return
		end
		 
		 
		local collapsePause = math.clamp(options.CollapsePause or 0, 0, 0.18)
		if collapsePause > 0 and record.Pass == 1 and not record.CollapsePauseUsed and record.Age >= 0.22 then
			record.CollapsePauseUsed = true
			record.CollapsePauseRemaining = collapsePause
			record.Body.Transparency = 0.38
			record.Trail.Enabled = false
			refreshVisual(record)
		end
		if (record.CollapsePauseRemaining or 0) > 0 then
			record.CollapsePauseRemaining = math.max(0, record.CollapsePauseRemaining - dt)
			if record.CollapsePauseRemaining <= 0 then
				record.Body.Transparency = options.Transparency or 0.05
				record.Trail.Enabled = true
				refreshVisual(record)
			end
			return
		end
		local freezeAfterStep = false
		if kind == "Time" and record.Pass == 1 then
			local initialRemaining = Config.TimeBulletInitialTravelTime - record.Age
			if initialRemaining <= 1e-6 then
				dormant(record)
				return
			end
			dt = math.min(dt, initialRemaining)
			freezeAfterStep = dt >= initialRemaining - 1e-6
		end
		record.Age += dt
		if homingDuration > 0 and record.Age <= homingDuration then
			local desired = target.HumanoidRootPart.Position - record.Position
			if desired.Magnitude > 0.01 then
				record.Direction = turnTowards(
					record.Direction,
					desired.Unit,
					(options.HomingTurnRate or Config.GoldenHourHomingTurnRate) * math.min(dt, 0.15)
				)
			end
		end
		local from = record.Position
		local travelSpeed = kind == "Time" and record.Pass == 1 and (Config.TimeBulletApproachSpeed or speed * 0.45)
			or speed
		local delta = record.Direction * travelSpeed * math.min(dt, 0.15)
		if record.MaxDistance then
			delta = record.Direction * math.min(delta.Magnitude, math.max(0, record.MaxDistance - record.Travelled))
		end
		local wall = workspace:Spherecast(from, 0.4, delta, params)
		local destination = wall and wall.Position + wall.Normal * 0.45 or from + delta
		local hitCharacter, hitTime
		local damageReady = workspace:GetServerTimeNow() >= (owner:GetAttribute("MissingFrameDamageGraceUntil") or 0)
		if damageReady and not collisionTargets then
			collisionTargets = core.Characters(targetBuffer)
		end
		for _, character in ipairs(damageReady and collisionTargets or NO_TARGETS) do
			if activeTarget(character) then
				local distance, t = closest(character.HumanoidRootPart.Position, from, destination)
				if distance <= hitRadiusSquared then
					if kind == "Time" then
						 
						 
						if not record.HitTargets[character] then
							record.HitTargets[character] = true
							local applied = core.Damage(character, damage,options.Skill)
       if applied>0 and options.OnHit then local ok,err=pcall(options.OnHit,character,applied,record);if not ok then warn("Projectile hit effect: "..tostring(err)) end end
							record.AppliedDamage = (record.AppliedDamage or 0) + applied
							record.PiercedCount = (record.PiercedCount or 0) + 1
							sparks(character.HumanoidRootPart.Position, 14)
						end
					elseif not hitTime or t < hitTime then
						hitCharacter = character
						hitTime = t
					end
				end
			end
		end
		if hitCharacter then
			destination = from + (destination - from) * hitTime
		end
		record.Travelled += (destination - from).Magnitude
		record.Position = destination
		record.Body.CFrame = CFrame.lookAt(destination, destination + record.Direction)
		updateKnifeVisual(record)
		if options.OnTravel then
			local ok, err = xpcall(options.OnTravel, debug.traceback, record, from, destination)
			if not ok then
				warn("Projectile travel effect: " .. tostring(err))
			end
		end
		if hitCharacter then
			if kind == "Golden" then
				local hits = hitCounts[hitCharacter] or 0
				if hits < (options.MaxHits or Config.GoldenBulletMaxHits) then
					local applied=core.Damage(hitCharacter, damage,options.Skill)
     if applied>0 then
      if options.OnHit then local ok,err=pcall(options.OnHit,hitCharacter,applied,record);if not ok then warn("Projectile hit effect: "..tostring(err)) end end
						hitCounts[hitCharacter] = hits + 1
					end
				end
			end
		end
		if hitCharacter then
			stop(record, true)
		elseif wall and kind == "Time" and record.Pass == 1 then
			 
			record.Direction = (record.Direction - 2 * record.Direction:Dot(wall.Normal) * wall.Normal).Unit
		elseif
			wall
			or record.Age >= (kind == "Time" and 2 or flightLifetime)
			or (record.MaxDistance and record.Travelled >= record.MaxDistance - 0.001)
		then
			stop(record, not knives)
		end
		 
		 
		if freezeAfterStep and not record.Removed and record.State == "Flying" then
			dormant(record)
		end
	end
	for _, record in ipairs(records) do
		record.Motion = api.RegisterMotion(actor, {
			Cast = cast,
			Skill = options.Skill or (kind == "Time" and "P2TimeBullets" or "P2GoldenBullets"),
			Moving = function()
				return not record.Removed
					and record.State == "Flying"
					and record.Body.Parent ~= nil
					and Effects.LeaseId(record.Body) == record.BodyLease
					and validBurst()
			end,
			Hide = function(hidden)
				if record.Removed or not record.Body.Parent or Effects.LeaseId(record.Body) ~= record.BodyLease then
					return
				end
				local clockGui = record.Body:FindFirstChild("TimeBulletClock")
				local guard = record.Guard
					and record.Guard.Parent
					and Effects.LeaseId(record.Guard) == record.GuardLease
					and record.Guard
				local ribbon = record.Trail.Parent and record.Trail
				if hidden then
					record.HiddenDisplay = {
						Body = record.Body.Transparency,
						Trail = ribbon and ribbon.Enabled,
						Guard = guard and guard.Transparency,
						Clock = clockGui and clockGui.Enabled,
						KnifeParts = {},
					}
					for _, item in ipairs(record.KnifeParts or {}) do
						if item.Part.Parent and Effects.LeaseId(item.Part) == item.Lease then
							record.HiddenDisplay.KnifeParts[item] = item.Part.Transparency
							item.Part.Transparency = 1
						end
					end
					record.Body.Transparency = 1
					if ribbon then
						ribbon.Enabled = false
					end
					if guard then
						guard.Transparency = 1
					end
					if clockGui then
						clockGui.Enabled = false
					end
					if record.FX then
						record.FX.Emitter.Enabled = false
						if record.FX.Light then
							record.FX.Light.Enabled = false
						end
						if record.FX.Flare then
							record.FX.Flare.Enabled = false
						end
						for _, extra in ipairs(record.FX.Trails) do
							extra.Enabled = false
						end
					end
				elseif record.HiddenDisplay then
					local prior = record.HiddenDisplay
					record.HiddenDisplay = nil
					record.Body.Transparency = record.State == "Dormant" and 0.5 or prior.Body
					if ribbon then
						ribbon.Enabled = record.State == "Flying" and prior.Trail or false
					end
					if guard and prior.Guard ~= nil then
						guard.Transparency = prior.Guard
					end
					if clockGui and prior.Clock ~= nil then
						clockGui.Enabled = prior.Clock
					end
					for item, alpha in pairs(prior.KnifeParts or {}) do
						if item.Part.Parent and Effects.LeaseId(item.Part) == item.Lease then
							item.Part.Transparency = alpha
						end
					end
					refreshVisual(record)
				end
			end,
			Advance = function(seconds)
				if not validBurst() then
					return false
				end
				local remaining = seconds
				while remaining > 0 and not record.Removed and record.State == "Flying" do
					local dt = math.min(kind == "Time" and 1 / 15 or 0.1, remaining)
					if kind == "Time" and record.Pass == 1 then
						dt = math.min(dt, math.max(0, Config.TimeBulletInitialTravelTime - record.Age))
					end
					if dt <= 1e-6 then
						updateRecord(record, 0, cast:Now(), false)
						break
					end
					updateRecord(record, dt, cast:Now(), false)
					remaining -= dt
				end
				return true
			end,
			Settle = function()
				if record.Removed then
					return
				end
				record.Position =
					api.SafeReappearance(record.Position, record.Direction or record.InitialDirection, 4, params)
				record.Body.CFrame =
					CFrame.lookAt(record.Position, record.Position + (record.Direction or record.InitialDirection))
				updateKnifeVisual(record)
			end,
		})
	end
	cast:Step(function(dt, now)
		if not validBurst() then
			cast:Dispose()
			return false
		end
		if TimeEffects.IsStopped(owner) then
			return true
		end
		visualClock += dt
		local animate = visualClock >= 0.05
		if animate then
			visualClock = 0
		end
		-- Each volley shares one fresh target list during this step.
		collisionTargets = nil
		params = core.Params()
		local remaining = 0
		for _, record in ipairs(records) do
			if not record.Removed then
				remaining += 1
				if not record.Motion:IsHidden() then
					updateRecord(record, dt, now, animate)
				end
			end
		end
		if remaining == 0 then
			cast:Schedule(0.25, function()
				cast:Dispose()
			end)
			return false
		end
		return true
	end)
	return { Cast = cast, Count = count, Records = records }
end
return api

]==]