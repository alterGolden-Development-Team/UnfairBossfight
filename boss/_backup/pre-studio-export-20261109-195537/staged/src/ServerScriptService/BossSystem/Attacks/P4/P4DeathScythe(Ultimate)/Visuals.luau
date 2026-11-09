


local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Style = require(script.Parent.Style)
local ScytheModel = require(game:GetService("ReplicatedStorage").BossShared.Presentation.DeathScythe.ScytheModel)

local api = {}

 
local BOSS_GRIP_Y = Style.BossGripAlongShaft or 6  
local GRIP_Y = -BOSS_GRIP_Y  
local GRIP_REACH = 40 - BOSS_GRIP_Y  
local HAND_R = 3.5         
local LEAD = 0.4           
 
 
local GROW_FROM = math.clamp(Style.GrowFromScale or 0.05, 0.02, 1)
local GROW_STEPS = 36
local FADE_IN = 0.08       
 
local SMEAR_STEP = 0.3
local SMEAR_BASE = { 0.55, 0.7, 0.82, 0.9, 0.94 }
local SMEAR_COLOR = Style.BloodHot:Lerp(Style.Edge, 0.35)

local function make(class, props, parent)
	local instance = Instance.new(class)
	for key, value in pairs(props) do
		instance[key] = value
	end
	if parent then instance.Parent = parent end
	return instance
end

local function smooth(a) return a * a * (3 - 2 * a) end

local FADE = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
local function shrink(from, to) return NumberSequence.new({ NumberSequenceKeypoint.new(0, from), NumberSequenceKeypoint.new(1, to) }) end

function api.Build(core, cast, target, ground, radius, height)
	local effects = core.Effects

	 
	 -- sized to reach the far corner; the cap allows the 620x460 arena (radius up to ~610)
	local scale = math.clamp((radius - HAND_R) / GRIP_REACH, 0.6, 18)
	local giant = ScytheModel.Build({ Detail = 1, Scale = scale, Low = true, Name = "DeathScytheSweeper" })
	ScytheModel.SetScale(giant, GROW_FROM)  
	cast:Add(giant.Model)
	giant.Model.Parent = effects
	giant.Root.CFrame = CFrame.new(ground)
	 
	local planeY = height - 0.7 * scale
	local planeGrip = ground.Y + planeY  
	local GIANT_GRIP = CFrame.new(0, GRIP_Y * scale, 0)  

	 
	local smear = {}
	for index = 1, math.clamp(Style.SmearCount or 0, 0, #SMEAR_BASE) do
		local ghost = ScytheModel.Build({ Detail = 0.3, Scale = scale, Low = true, Ghost = true, Name = "DeathScytheSmear" })
		for _, entry in ipairs(ghost.Entries) do
			entry.Part.Material, entry.Part.Color = Enum.Material.Neon, SMEAR_COLOR
		end
		cast:Add(ghost.Model)
		ghost.Model.Parent = effects
		ghost.Root.CFrame = CFrame.new(ground)
		ghost.Level = 1  
		smear[index] = ghost
	end

	 
	local mark = cast:Add(Instance.new("Highlight"))
	mark.Name = "DeathScytheLockedTarget"
	mark.Adornee = target
	mark.FillColor, mark.OutlineColor = Style.Marked, Style.Edge
	mark.FillTransparency, mark.OutlineTransparency = 0.75, 0
	mark.DepthMode = Enum.HighlightDepthMode.Occluded
	mark.Parent = effects

	 
	local aura
	local rig = core.Root and core.Root.Parent
	if rig and rig:IsA("Model") then
		aura = cast:Add(make("Highlight", {
			Name = "DeathScytheAura", Adornee = rig, FillColor = Style.BloodHot, OutlineColor = Style.Edge,
			FillTransparency = 1, OutlineTransparency = 1, DepthMode = Enum.HighlightDepthMode.Occluded,
		}, effects))
	end

	 
	local pool = cast:Add(make("Part", {
		Name = "DeathScythePool", Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false, CanQuery = false,
		CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Color = Style.Blood, Transparency = 1,
		Size = Vector3.new(0.2, 1, 1), CFrame = CFrame.new(ground + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi / 2),
	}, effects))
	local geyser = make("ParticleEmitter", {
		Enabled = false, Rate = 0, Lifetime = NumberRange.new(0.6, 1.1), Speed = NumberRange.new(40, 70),
		SpreadAngle = Vector2.new(25, 25), EmissionDirection = Enum.NormalId.Top, Acceleration = Vector3.new(0, -90, 0),
		LightEmission = 0.6, LightInfluence = 0, Transparency = FADE, Size = shrink(1, 0.2),
		Color = ColorSequence.new(Style.BloodHot, Style.Blood), Rotation = NumberRange.new(0, 360),
	}, pool)

	local function shock(diameter, life, color)
		if not cast:Alive() then return end
		local disc = cast:Add(make("Part", {
			Name = "DeathScytheShock", Shape = Enum.PartType.Cylinder, Anchored = true, CanCollide = false, CanQuery = false,
			CanTouch = false, CastShadow = false, Material = Enum.Material.Neon, Color = color, Transparency = 0.25,
			Size = Vector3.new(0.4, 2, 2), CFrame = CFrame.new(ground + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		}, effects))
		TweenService:Create(disc, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.4, diameter, diameter), Transparency = 1 }):Play()
		Debris:AddItem(disc, life + 0.1)
	end

	 
	 
	 
	 
	local function flatGrip(azimuth, grip)
		local radial = Vector3.new(math.cos(azimuth), 0, math.sin(azimuth))
		local tangent = Vector3.new(-math.sin(azimuth), 0, math.cos(azimuth))
		return CFrame.fromMatrix(grip, tangent, radial)
	end

	 
	 
	local latch
	local function gripAt(angle)
		local azimuth = angle + LEAD + latch.Phase
		return Vector3.new(
			latch.Center.X + latch.Radius * math.cos(azimuth),
			planeGrip,  
			latch.Center.Z + latch.Radius * math.sin(azimuth)
		)
	end

	 
	local visual = {}
	local grown, growLevel, giantKey = GROW_FROM, 0, nil  

	local function pulse()
		local p = 0.5 + 0.5 * math.sin(os.clock() * 11)
		giant.Gem.Color = Style.BloodHot:Lerp(Style.Edge, p * 0.45)
	end
	local function showGiant(reveal, fade)  
		local key = math.floor(reveal * 8) + math.floor((fade or 0) * 8) * 100
		if key ~= giantKey then
			giantKey = key
			ScytheModel.SetTransparency(giant, reveal, fade)
		end
	end

	 
	 
	 
	local function lay(angle, hand, size)
		local grip = Vector3.new(hand.X, planeGrip - 0.7 * scale * (1 - size), hand.Z)
		giant.Root.CFrame = flatGrip(angle + LEAD, grip) * CFrame.new(0, GRIP_Y * scale * size, 0)
	end

	 
	local function finishGrowth()
		if growLevel ~= GROW_STEPS then
			growLevel, grown = GROW_STEPS, 1
			ScytheModel.SetScale(giant, 1)
		end
		showGiant(1)
	end

	 
	function visual.Grow(growth, angle, hand)
		growth = math.clamp(growth, 0, 1)
		local level = math.floor(smooth(growth) * GROW_STEPS + 0.5)
		if level ~= growLevel then
			growLevel = level
			grown = level >= GROW_STEPS and 1 or GROW_FROM + (1 - GROW_FROM) * level / GROW_STEPS  
			ScytheModel.SetScale(giant, grown)
		end
		showGiant(math.clamp(growth / FADE_IN, 0, 1))
		lay(angle, hand, grown)
		pulse()
	end

	 
	function visual.Hold(alpha, angle, hand)
		local t, shake = os.clock(), 0.2 * scale
		lay(angle, hand + Vector3.new(math.sin(t * 71) * shake, 0, math.cos(t * 83) * shake), 1)
		pulse()
	end

	function visual.Latch(hand, center, angle)
		local offset = hand - center
		latch = {
			Center = center, Angle = angle,
			Radius = math.sqrt(offset.X * offset.X + offset.Z * offset.Z),
			Phase = math.atan2(offset.Z, offset.X) - (angle + LEAD),
		}
	end

	 
	function visual.Sweep(angle, speed)
		if not latch then return end
		giant.Root.CFrame = flatGrip(angle + LEAD, gripAt(angle)) * GIANT_GRIP
		 
		local visibility = math.clamp((speed - 0.1) * 2, 0, 1)
		for index, ghost in ipairs(smear) do
			local lagged = angle + index * SMEAR_STEP * speed
			ghost.Root.CFrame = flatGrip(lagged + LEAD, gripAt(lagged)) * GIANT_GRIP
			local transparency = math.floor((1 - (1 - SMEAR_BASE[index]) * visibility) * 10 + 0.5) / 10
			if transparency ~= ghost.Level then
				ghost.Level = transparency
				ScytheModel.SetTransparency(ghost, 1, transparency)
			end
		end
		pulse()
	end

	function visual.Fade(alpha)
		showGiant(1, alpha)
	end

	function visual.HideSweep()
		giant.Trail.Enabled = false
		for _, emitter in ipairs(giant.Scrape) do emitter.Enabled = false end
		for _, ghost in ipairs(smear) do
			ghost.Level = 1
			ScytheModel.SetTransparency(ghost, 0, 0)  
		end
	end

	local flare = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	function visual.Stage(name)
		if name == "Forming" then
			 
			TweenService:Create(pool, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = Vector3.new(0.2, 36, 36), Transparency = 0.45 }):Play()
			geyser.Rate, geyser.Enabled = 250, true
			cast:Schedule(0.2, function() geyser.Enabled = false end)
			shock(34, 0.55, Style.BloodHot)
			giant.Embers.Enabled = true
			TweenService:Create(giant.Light, flare, { Brightness = 3 }):Play()
			if aura then
				TweenService:Create(aura, TweenInfo.new(Style.FormationDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ FillTransparency = 0.7, OutlineTransparency = 0.25 }):Play()
			end
			 
			cast:Schedule(math.max(Style.FormationDuration - Style.JumpCueLead, 0.05), function()
				if aura then TweenService:Create(aura, flare, { FillTransparency = 0.35, OutlineTransparency = 0 }):Play() end
				shock(radius * 0.8, 0.45, Style.Edge)
				TweenService:Create(giant.Light, flare, { Brightness = 6 }):Play()
			end)
		elseif name == "Halted" then
			 
			TweenService:Create(pool, flare, { Transparency = 0.3 }):Play()
			giant.Embers.Rate = 70
			if aura then TweenService:Create(aura, flare, { FillTransparency = 0.4, OutlineTransparency = 0 }):Play() end
			shock(radius * 0.55, 0.5, Style.Edge)
			TweenService:Create(giant.Light, TweenInfo.new(Style.HaltDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Brightness = 9 }):Play()
		elseif name == "Impact" then
			 
			finishGrowth()
			giant.Embers.Rate, giant.Embers.Enabled, giant.Mist.Enabled = 90, true, true
			TweenService:Create(giant.Light, flare, { Brightness = 14 }):Play()
			shock(radius * 0.9, 0.5, Style.Edge)
		elseif name == "Sweeping" then
			giant.Trail.Lifetime = 0.22  
			giant.Trail.Enabled = true
			giant.Embers.Enabled, giant.Mist.Enabled = true, true
			for _, drip in ipairs(giant.Drips) do drip.Enabled = true end
			for _, emitter in ipairs(giant.Scrape) do emitter.Enabled = true end
			shock(radius * 1.6, 0.7, Style.Edge)
			cast:Schedule(0.12, function() shock(radius * 1.1, 0.6, Style.Blood) end)
			giant.Light.Brightness = 14
			TweenService:Create(giant.Light, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 6 }):Play()
		elseif name == "Recovering" then
			giant.Trail.Enabled = false
			giant.Embers.Enabled, giant.Mist.Enabled = false, false
			for _, drip in ipairs(giant.Drips) do drip.Enabled = false end
			for _, emitter in ipairs(giant.Scrape) do emitter.Enabled = false end
			giant.Mist.Rate, giant.Mist.Enabled = 150, true
			TweenService:Create(pool, TweenInfo.new(0.25), { Transparency = 1 }):Play()
			if aura then TweenService:Create(aura, TweenInfo.new(0.25), { FillTransparency = 1, OutlineTransparency = 1 }):Play() end
			TweenService:Create(giant.Light, TweenInfo.new(0.2), { Brightness = 0 }):Play()
		end
	end

	return visual
end

return api

