local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Tween = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer
local frozenView = require(script.Parent:WaitForChild("GoldenHourView")).new(player)
local remote = game:GetService("ReplicatedStorage"):WaitForChild("BossCombatEffects")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local tickSound = Instance.new("Sound")
tickSound.Name = "LastMinuteTemporalTick"
tickSound.SoundId = Config.LastMinuteTickSound
tickSound.Volume = 0.18
tickSound.Parent = SoundService
local dongSound = Instance.new("Sound")
dongSound.Name = "LastMinuteTemporalDong"
dongSound.SoundId = Config.LastMinuteDongSound
dongSound.Volume = 0.22
dongSound.PlaybackSpeed = 0.42
dongSound.Parent = SoundService
local debuffBlur = Instance.new("BlurEffect")
debuffBlur.Name = "StatusDebuffBlur"
debuffBlur.Size = Config.NewDebuffs.Blur.Size
debuffBlur.Enabled = false
debuffBlur.Parent = Lighting
local color = Instance.new("ColorCorrectionEffect")
color.Name = "GoldenParryTimeStop"
color.Saturation = -1
color.Contrast = 0.35
color.Brightness = -0.06
color.Enabled = false
color.Parent = Lighting
local hourColor = Instance.new("ColorCorrectionEffect")
hourColor.Name = "GoldenHourDesaturation"
hourColor.Saturation = -1
hourColor.Contrast = 0.32
hourColor.Brightness = -0.045
hourColor.TintColor = Color3.fromRGB(240, 235, 215)
hourColor.Enabled = false
hourColor.Parent = Lighting
 
local impactTint = Instance.new("ColorCorrectionEffect")
impactTint.Name = "ShieldBreakImpactTint"
impactTint.Enabled = false
impactTint.Parent = Lighting
local impactTintTween
local impactTintAt = 0
local clockSky = Instance.new("ColorCorrectionEffect")
clockSky.Name = "AncientClockSkyTint"
clockSky.Enabled = false
clockSky.Parent = Lighting
 
 
local fogRecords = {}
 -- spatial fog goes through the VFXEngine lighting arbiter (highest priority: it is a
 -- gameplay debuff), so it blends with sky/night layers and restores to the live base
local LightingArbiter = require(game.ReplicatedStorage:WaitForChild("VFXEngine"):WaitForChild("Lighting"))
local FOG_LAYER = "GoldenFog"
local function restoreFog()
	LightingArbiter.Pop(FOG_LAYER, 0.4)
	player:SetAttribute("SpatialWorldFogActive", false)
	player:SetAttribute("WorldVisibilityDistance", nil)
end
local function applyFog()
	local distance, density = nil, 0
	for _, record in pairs(fogRecords) do
		distance = distance and math.min(distance, record.Distance) or record.Distance
		density = math.max(density, record.Density)
	end
	if not distance then
		restoreFog()
		return
	end
	LightingArbiter.Push(FOG_LAYER, {
		Lighting = { FogStart = math.min(10, distance * 0.2), FogEnd = distance, FogColor = Color3.fromRGB(24, 19, 29) },
		Atmosphere = {
			Density = density,
			Offset = 0,
			Color = Color3.fromRGB(41, 31, 43),
			Decay = Color3.fromRGB(15, 12, 20),
			Glare = 0,
			Haze = 3,
		},
	}, { Priority = 80, Fade = 0.25 })
	player:SetAttribute("SpatialWorldFogActive", true)
	player:SetAttribute("WorldVisibilityDistance", distance)
end
local function startFog(kind, data, distance, density)
	if player:GetAttribute("ViewAsServer") then return false end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if
		not hum
		or hum.Health <= 0
		or typeof(data.Owner) ~= "Instance"
		or not data.Owner.Parent
		or math.floor(data.Owner:GetAttribute("Phase") or 1) ~= 3
		or data.Owner:GetAttribute("EncounterEnded")
	then
		return false
	end
	local limit = kind == "Projectile" and (Config.P3ProjectileDarknessDuration or 18) or 20
	fogRecords[kind] = {
		Token = data.Token,
		Owner = data.Owner,
		Character = char,
		EndsAt = math.min(data.EndsAt or 0, workspace:GetServerTimeNow() + limit),
		Distance = distance,
		Density = density,
	}
	applyFog()
	return true
end
local function stopFog(kind, token)
	local record = fogRecords[kind]
	if not record or token and token ~= record.Token then
		return
	end
	fogRecords[kind] = nil
	applyFog()
end
local etherealToken, etherealOwner, etherealEndsAt
local stopOrbit
local function stopEthereal(token, immediate)
	if token and token ~= etherealToken then
		return
	end
	stopFog("Ethereal", token)
	etherealToken = nil
	etherealOwner = nil
	etherealEndsAt = nil
	player:SetAttribute("EtherealWorldActive", false)
	if stopOrbit then
		stopOrbit(token)
	end
end
local function startEthereal(data)
	local distance = math.clamp(Config.EtherealAcumenWorldVisibilityDistance or 60, 42, 80)
	if not startFog("Ethereal", data, distance, 0.5) then
		return
	end
	etherealToken = data.Token
	etherealOwner = data.Owner
	etherealEndsAt = data.EndsAt or 0
	player:SetAttribute("EtherealWorldActive", true)
end
local clockToken, clockDeadline, skySnapshot, skyPhase
local skyTweens = {}
local function cancelSkyTweens()
	for _, tween in ipairs(skyTweens) do
		tween:Cancel()
	end
	table.clear(skyTweens)
end
local function stopClockIntro(token, immediate)
	if token and token ~= clockToken then
		return
	end
	cancelSkyTweens()
	clockDeadline = nil
	clockToken = nil
	local boss = workspace:FindFirstChild("alterGolden, the Nothing")
	local duration = immediate and 0 or 0.65
	if skySnapshot and (not boss or boss:GetAttribute("Phase") == skyPhase) then
		if immediate then
			for property, value in pairs(skySnapshot) do
				Lighting[property] = value
			end
		else
			local tween = Tween:Create(Lighting, TweenInfo.new(duration), skySnapshot)
			tween:Play()
			table.insert(skyTweens, tween)
		end
	end
	skySnapshot = nil
	skyPhase = nil
	if immediate then
		clockSky.Enabled = false
		clockSky.TintColor = Color3.new(1, 1, 1)
		clockSky.Brightness = 0
	else
		local tween = Tween:Create(
			clockSky,
			TweenInfo.new(duration),
			{ TintColor = Color3.new(1, 1, 1), Brightness = 0, Saturation = 0 }
		)
		tween:Play()
		table.insert(skyTweens, tween)
	end
end
local function startClockIntro(data)
	if clockToken then
		stopClockIntro(nil, true)
	end
	cancelSkyTweens()
	clockToken = data.Token
	clockDeadline = os.clock() + (data.Duration or 15)
	local boss = workspace:FindFirstChild("alterGolden, the Nothing")
	skyPhase = boss and boss:GetAttribute("Phase")
	skySnapshot = { ClockTime = Lighting.ClockTime, ExposureCompensation = Lighting.ExposureCompensation }
	clockSky.Enabled = true
	clockSky.TintColor = Color3.new(1, 1, 1)
	clockSky.Brightness = 0
	clockSky.Saturation = 0
	local tint = Tween:Create(
		clockSky,
		TweenInfo.new(1.1),
		{ TintColor = Color3.fromRGB(255, 220, 147), Brightness = -0.025, Saturation = 0.1 }
	)
	local light = Tween:Create(
		Lighting,
		TweenInfo.new(1.1),
		{  -- Hellaven stays night: only the exposure dips
			ClockTime = require(Shared.Presentation.EncounterTheme).IsHellaven() and skySnapshot.ClockTime or 17.2,
			ExposureCompensation = skySnapshot.ExposureCompensation - 0.25,
		}
	)
	tint:Play()
	light:Play()
	table.insert(skyTweens, tint)
	table.insert(skyTweens, light)
end
local gui = Instance.new("ScreenGui")
gui.Name = "BossCinematicFX"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 80
gui.Parent = player:WaitForChild("PlayerGui")

 
 
local sightToken, sightOwner, sightEndsAt
local surroundFolder
local surroundHosts={}
local surroundElapsed=0
local function clearSurround()
 if surroundFolder then surroundFolder:Destroy();surroundFolder=nil end
 table.clear(surroundHosts)
end
local function placeSurround()
 local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 if not root then return end
 local radius=Config.P3ProjectileSurroundRadius or 22
 local camera=workspace.CurrentCamera
 if camera then radius=math.max(radius,(camera.CFrame.Position-root.Position).Magnitude+11) end
 for index,host in ipairs(surroundHosts) do
  local angle=(index-1)*math.pi*2/#surroundHosts
  host.Position=root.Position+Vector3.new(math.cos(angle)*radius,index%2==0 and 11 or 2,math.sin(angle)*radius)
 end
end
local function makeSurround()
 clearSurround()
 surroundFolder=Instance.new("Folder")
 surroundFolder.Name="ProjectileDarknessSurround"
 surroundFolder.Parent=workspace
 for index=1,32 do
  local host=Instance.new("Part")
  host.Name="DarknessFog"
  host.Size=Vector3.one
  host.Transparency=1
  host.Anchored=true
  host.CanCollide=false;host.CanTouch=false;host.CanQuery=false;host.CastShadow=false
  host.Parent=surroundFolder
  surroundHosts[#surroundHosts+1]=host
  local mist=Instance.new("ParticleEmitter")
  mist.Name="SurroundingDarkMist"
  mist.Texture="rbxasset://textures/particles/smoke_main.dds"
  mist.Color=ColorSequence.new(Color3.fromRGB(8,7,12),Color3.fromRGB(20,17,26))
  mist.LightEmission=0;mist.LightInfluence=0
  mist.Rate=12;mist.Lifetime=NumberRange.new(1.8,2.4)
  mist.Speed=NumberRange.new(0);mist.LockedToPart=true
  mist.Rotation=NumberRange.new(0,360);mist.RotSpeed=NumberRange.new(-12,12)
  mist.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,18),NumberSequenceKeypoint.new(.5,24),NumberSequenceKeypoint.new(1,26)})
  mist.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.15,.18),NumberSequenceKeypoint.new(.8,.24),NumberSequenceKeypoint.new(1,1)})
  mist.Parent=host
 end
 placeSurround()
 for _,host in ipairs(surroundHosts) do host.SurroundingDarkMist:Emit(18) end
end
local hiddenShieldHighlights = {}
local shieldHighlightAdded
local function hideShieldHighlight(object)
 if not object:IsA("Highlight") or object.Name ~= "ShieldGlow" or hiddenShieldHighlights[object] then return end
 local record = { OutlineTransparency = object.OutlineTransparency, FillTransparency = object.FillTransparency, Connections = {} }
 hiddenShieldHighlights[object] = record
 for _, property in ipairs({ "OutlineTransparency", "FillTransparency" }) do
  record.Connections[#record.Connections + 1] = object:GetPropertyChangedSignal(property):Connect(function()
   if object[property] ~= 1 then
    record[property] = object[property]
    object[property] = 1
   end
  end)
  object[property] = 1
 end
end
local function hideDarknessShieldOutlines()
 if not shieldHighlightAdded then
  shieldHighlightAdded = workspace.DescendantAdded:Connect(hideShieldHighlight)
 end
 for _, object in ipairs(workspace:GetDescendants()) do
  if object:IsA("Highlight") then hideShieldHighlight(object) end
 end
end
local function restoreDarknessShieldOutlines()
 if shieldHighlightAdded then shieldHighlightAdded:Disconnect(); shieldHighlightAdded = nil end
 for object, record in pairs(hiddenShieldHighlights) do
  for _, connection in ipairs(record.Connections) do connection:Disconnect() end
  if object.Parent then
   object.OutlineTransparency = record.OutlineTransparency
   object.FillTransparency = record.FillTransparency
  end
 end
 table.clear(hiddenShieldHighlights)
end
local function stopSight(token)
 if token and token~=sightToken then return end
 clearSurround()
 restoreDarknessShieldOutlines()
 stopFog("Projectile",token)
 sightToken=nil;sightOwner=nil;sightEndsAt=nil
 player:SetAttribute("ProjectileLimitedSightActive",false)
end
local function startSight(data)
 local distance=math.clamp(Config.P3ProjectileWorldVisibilityDistance or 22,18,100)
 if not startFog("Projectile",data,distance,math.clamp(Config.P3ProjectileFogDensity or .8,.2,.8)) then return end
 sightToken=data.Token;sightOwner=data.Owner
 sightEndsAt=math.min(data.EndsAt or 0,workspace:GetServerTimeNow()+(Config.P3ProjectileDarknessDuration or 18))
 makeSurround()
 hideDarknessShieldOutlines()
 player:SetAttribute("ProjectileLimitedSightActive",true)
end
local flash = Instance.new("Frame")
flash.Name = "TimeStopFlash"
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = Color3.new(1, 1, 1)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Parent = gui
 
local criticalEdges = {}
local criticalTarget, criticalOpacity = 0, 0
local healthConnection, maxHealthConnection
local healthGeneration = 0
local function criticalEdge(name, size, position, rotation)
	local edge = Instance.new("Frame")
	edge.Name = name
	edge.Size = size
	edge.Position = position
	edge.BackgroundColor3 = Color3.fromRGB(190, 0, 12)
	edge.BackgroundTransparency = 1
	edge.BorderSizePixel = 0
	edge.ZIndex = 2
	edge.Parent = gui
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation
	gradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	gradient.Parent = edge
	criticalEdges[#criticalEdges + 1] = edge
end
criticalEdge("CriticalHealthTop", UDim2.fromScale(1, 0.14), UDim2.fromScale(0, 0), 90)
criticalEdge("CriticalHealthBottom", UDim2.fromScale(1, 0.14), UDim2.fromScale(0, 0.86), 270)
criticalEdge("CriticalHealthLeft", UDim2.fromScale(0.12, 1), UDim2.fromScale(0, 0), 0)
criticalEdge("CriticalHealthRight", UDim2.fromScale(0.12, 1), UDim2.fromScale(0.88, 0), 180)
local lastMinute = Instance.new("TextLabel")
lastMinute.Name = "TimeCollapseStage"
lastMinute.AnchorPoint = Vector2.new(0.5, 0)
lastMinute.Position = UDim2.fromScale(0.5, 0.19)
lastMinute.Size = UDim2.fromOffset(420, 55)
lastMinute.BackgroundTransparency = 1
lastMinute.Font = Enum.Font.Garamond
lastMinute.TextSize = 32
lastMinute.TextColor3 = Color3.fromRGB(255, 204, 67)
lastMinute.TextStrokeTransparency = 0.12
lastMinute.Visible = false
lastMinute.ZIndex = 4
lastMinute.Parent = gui
local collapseTitle = Instance.new("TextLabel")
collapseTitle.Name = "TimeCollapseTitle"
collapseTitle.Position = UDim2.new(0, 0, 1, -4)
collapseTitle.Size = UDim2.new(1, 0, 0, 24)
collapseTitle.BackgroundTransparency = 1
collapseTitle.Font = Enum.Font.Garamond
collapseTitle.TextSize = 20
collapseTitle.TextColor3 = Color3.fromRGB(255, 222, 130)
collapseTitle.TextStrokeTransparency = 0.2
collapseTitle.Text = "TIME IS COLLAPSING"
collapseTitle.Parent = lastMinute
local collapseActive = false
local collapseWords = { "TIME FRACTURES", "FUTURES COLLIDE", "MOMENTS COLLAPSE", "REALITY UNRAVELS", "THE LAST MOMENT" }
local collapsePulse = 0
local collapseStageIndex = 1
local glitch = Instance.new("Frame")
glitch.Name = "MissingFrameGlitch"
glitch.Size = UDim2.fromScale(1, 1)
glitch.BackgroundColor3 = Color3.fromRGB(12, 10, 7)
glitch.BackgroundTransparency = 1
glitch.BorderSizePixel = 0
glitch.ZIndex = 5
glitch.Parent = gui
local glitchUntil = 0
local distortion = Instance.new("ColorCorrectionEffect")
distortion.Name = "MissingFrameDistortion"
distortion.Contrast = 0.16
distortion.Saturation = -0.24
distortion.Brightness = -0.04
distortion.TintColor = Color3.fromRGB(235, 225, 202)
distortion.Enabled = false
distortion.Parent = Lighting
local distortionBlur = Instance.new("BlurEffect")
distortionBlur.Name = "MissingFrameSoftTear"
distortionBlur.Size = 0
distortionBlur.Enabled = false
distortionBlur.Parent = Lighting
local missingVFXReadyAt = 0
local missingResumeUntil = 0
local glitchBars = {}
for index = 1, 6 do
	local bar = Instance.new("Frame")
	bar.Name = "TemporalScreenTear"
	bar.Size = UDim2.fromScale(1, index % 2 == 0 and 0.023 or 0.012)
	bar.Position = UDim2.fromScale(0, 0.08 + index * 0.125)
	bar.BackgroundColor3 = index % 2 == 0 and Color3.fromRGB(255, 225, 118) or Color3.fromRGB(187, 237, 255)
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel = 0
	bar.ZIndex = 6
	bar.Parent = glitch
	glitchBars[index] = bar
end
 
local function collapseStage(value)
	collapseStageIndex = math.clamp(math.floor(tonumber(value) or 1), 1, #collapseWords)
	lastMinute.Text = collapseWords[math.clamp(math.floor(tonumber(value) or 1), 1, #collapseWords)]
	collapsePulse = os.clock()
end
 
 
 
local clockOverlay = Instance.new("Frame")
clockOverlay.Name = "StoppedTimeClockSilhouette"
clockOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
clockOverlay.Position = UDim2.fromScale(0.5, 0.5)
clockOverlay.Size = UDim2.fromScale(0.72, 0.72)
clockOverlay.BackgroundTransparency = 1
clockOverlay.Visible = false
clockOverlay.Parent = gui
local aspect = Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio = 1
aspect.Parent = clockOverlay
local rounded = Instance.new("UICorner")
rounded.CornerRadius = UDim.new(1, 0)
rounded.Parent = clockOverlay
local clockRim = Instance.new("UIStroke")
clockRim.Color = Color3.fromRGB(255, 232, 159)
clockRim.Thickness = 3
clockRim.Transparency = 0.76
clockRim.Parent = clockOverlay
local clockTicks = {}
for index = 1, 12 do
	local angle = index * math.pi / 6
	local tick = Instance.new("Frame")
	tick.Name = "TemporalHourGlyph"
	tick.AnchorPoint = Vector2.new(0.5, 0.5)
	tick.Position = UDim2.fromScale(0.5 + math.sin(angle) * 0.46, 0.5 - math.cos(angle) * 0.46)
	tick.Size = UDim2.fromScale(index % 3 == 0 and 0.012 or 0.006, index % 3 == 0 and 0.055 or 0.035)
	tick.Rotation = index * 30
	tick.BackgroundColor3 = Color3.fromRGB(255, 233, 167)
	tick.BackgroundTransparency = 0.67
	tick.BorderSizePixel = 0
	tick.Parent = clockOverlay
	clockTicks[#clockTicks + 1] = tick
end
local resumeAt
local quote = Instance.new("TextLabel")
quote.Name = "ParryQuote"
quote.AnchorPoint = Vector2.new(0.5, 0.5)
quote.Position = UDim2.fromScale(0.5, 0.25)
quote.Size = UDim2.fromScale(0.8, 0.1)
quote.BackgroundTransparency = 1
quote.Font = Enum.Font.Garamond
quote.TextSize = 42
quote.TextColor3 = Color3.new(1, 1, 1)
quote.TextStrokeTransparency = 0.1
quote.Text = "Too late..."
quote.Visible = false
quote.Parent = gui
local parryUntil = 0
local savedType
local savedSubject
local parryCamera
local shakeUntil = 0
local shakeDuration = 1
local strength = 0
local lastCamera, lastBase, lastApplied
local hourStopped = false
local function updateGoldenHour()
	local stopped = workspace:GetAttribute("GoldenTimeStopped") == true
	hourColor.Enabled = stopped
	if stopped then
		resumeAt = nil
		clockOverlay.Visible = true
		clockOverlay.Rotation = 0
		clockRim.Transparency = 0.76
		for _, tick in ipairs(clockTicks) do
			tick.BackgroundTransparency = 0.67
		end
		cancelSkyTweens()
		clockSky.Enabled = false
		if not hourStopped then
			frozenView.Start()
			flash.BackgroundColor3 = Color3.new(1, 1, 1)
			flash.BackgroundTransparency = 0.18
			Tween:Create(flash, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		end
	elseif hourStopped then
		frozenView.Stop()
		stopClockIntro()
	end
	hourStopped = stopped
end
 
local numberPool, numbers = {}, {}
local numberRandom = Random.new()
local numberPanel
local function releaseNumber(index)
	local record = table.remove(numbers, index)
	record.Label.Visible = false
	record.Label.Text = ""
	table.insert(numberPool, record.Label)
end
local function damageNumber(data, isPlayerDamage)
	if type(data.Damage) ~= "number" or data.Damage <= 0 or typeof(data.Position) ~= "Vector3" then
		return
	end
	if #numbers >= 24 then
		releaseNumber(1)
	end
	local label = table.remove(numberPool)
	if not label then
		label = Instance.new("TextLabel")
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Size = UDim2.fromOffset(100, 40)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.Garamond
		label.TextSize = 30
		label.TextStrokeColor3 = Color3.fromRGB(25, 17, 5)
		label.ZIndex = 3
		label.Parent = gui
	end
	label.Name = isPlayerDamage and "PlayerDamageNumber" or "BossDamageNumber"
	local value = math.floor(data.Damage * 10 + 0.5) / 10
	label.Text = value % 1 == 0 and tostring(math.floor(value)) or string.format("%.1f", value)
	label.TextColor3 = isPlayerDamage and Color3.fromRGB(255, 112, 90)
		or ((data.HealthDamage or 0) > 0 and Color3.fromRGB(255, 251, 220) or Color3.fromRGB(255, 222, 67))
	label.TextTransparency = 0
	label.TextStrokeTransparency = 0.15
	label.Visible = true
	table.insert(numbers, {
		Label = label,
		Position = data.Position,
		At = os.clock(),
		Offset = numberRandom:NextNumber(-22, 22),
		PlayerDamage = isPlayerDamage,
	})
end
local function finishParry()
	color.Enabled = false
	quote.Visible = false
	flash.BackgroundTransparency = 1
	parryUntil = 0
	if parryCamera and savedType then
		parryCamera.CameraType = savedType
		if savedSubject and savedSubject.Parent then
			parryCamera.CameraSubject = savedSubject
		end
	end
	parryCamera = nil
	savedType = nil
	savedSubject = nil
	local char = player.Character
	if char then
		char:SetAttribute("ParryCinematicActive", false)
	end
end
local orbitRecord
stopOrbit = function(token)
	local record = orbitRecord
	if not record or token and token ~= record.Token then
		return
	end
	orbitRecord = nil
	player:SetAttribute("EtherealCinematicActive", false)
	local camera = record.Camera
	if camera and camera.Parent and camera:GetAttribute("EtherealCameraToken") == record.Token then
		camera:SetAttribute("EtherealCameraToken", nil)
		if camera.CameraType == Enum.CameraType.Scriptable then
			camera.CameraType = record.Type
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			camera.CameraSubject = hum or record.Subject
			camera.CFrame = record.Frame
		end
	end
end
local function startOrbit(data)
	local owner = data.Owner
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local camera = workspace.CurrentCamera
	if
		typeof(owner) ~= "Instance"
		or not owner.Parent
		or math.floor(owner:GetAttribute("Phase") or 1) ~= 3
		or not hum
		or hum.Health <= 0
		or typeof(data.Center) ~= "Vector3"
		or not camera
	then
		return
	end
	finishParry()
	stopOrbit()
	orbitRecord = {
		Token = data.Token,
		Owner = owner,
		Character = char,
		Camera = camera,
		Type = camera.CameraType,
		Subject = camera.CameraSubject,
		Frame = camera.CFrame,
		At = workspace:GetServerTimeNow(),
		EndsAt = data.EndsAt or 0,
		Center = data.Center,
		Height = math.clamp(data.Height or 28, 18, 70),
		Radius = math.clamp(data.Radius or 46, 30, 70),
		Speed = math.clamp(data.Speed or 0.6, 0.2, 2.5),
		BobHeight = math.clamp(data.BobHeight or 5.5, 0, 8),
		BobSpeed = math.clamp(data.BobSpeed or 2, 0.5, 3),
	}
	camera:SetAttribute("EtherealCameraToken", data.Token)
	camera.CameraType = Enum.CameraType.Scriptable
	player:SetAttribute("EtherealCinematicActive", true)
end
local function resetCriticalHealth()
	healthGeneration += 1
	criticalTarget = 0
	criticalOpacity = 0
	for _, edge in ipairs(criticalEdges) do
		edge.BackgroundTransparency = 1
	end
	if healthConnection then
		healthConnection:Disconnect()
		healthConnection = nil
	end
	if maxHealthConnection then
		maxHealthConnection:Disconnect()
		maxHealthConnection = nil
	end
end
local function bindCriticalHealth(character)
	resetCriticalHealth()
	local generation = healthGeneration
	task.spawn(function()
		local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 10)
		if not humanoid or character ~= player.Character or generation ~= healthGeneration then
			return
		end
		local function update()
			if humanoid.Health <= 0 then
				criticalTarget = 0
				criticalOpacity = 0
			else
				criticalTarget = 0.48 * math.clamp(1 - (humanoid.Health / math.max(1, humanoid.MaxHealth)) / 0.32, 0, 1)
			end
		end
		healthConnection = humanoid.HealthChanged:Connect(update)
		maxHealthConnection = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
		update()
	end)
end
local remoteConnection = remote.OnClientEvent:Connect(function(kind, data)
	if kind == "BossDamage" then
		damageNumber(data, false)
	elseif kind == "PlayerDamage" then
		damageNumber(data, true)
	elseif kind == "LastMinute" then
		collapseActive = true
		collapseStage(data.Stage)
	elseif kind == "LastMinuteStage" then
		collapseStage(data.Stage)
	elseif kind == "LastMinuteTick" then
		collapsePulse = os.clock()
		tickSound.PlaybackSpeed = 1 + (collapseStageIndex - 1) * 0.025
		tickSound:Play()
	elseif kind == "LastMinuteRevolution" then
		dongSound:Play()
		collapsePulse = os.clock()
		shakeUntil = math.max(shakeUntil, os.clock() + 0.45)
		shakeDuration = 0.45
		strength = 0.3 + (data.Revolution or 1) * 0.12
	elseif kind == "LastMinuteVisualHitch" then
		glitchUntil = math.max(glitchUntil, os.clock() + 0.06)
	elseif kind == "LastMinuteShatter" then
		collapseActive = false
		lastMinute.Visible = false
		flash.BackgroundColor3 = Color3.fromRGB(255, 214, 73)
		flash.BackgroundTransparency = 0.82
		Tween:Create(flash, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
	elseif kind == "LastMinuteEnd" then
		collapseActive = false
		lastMinute.Visible = false
	elseif kind == "MissingFrame" then
		local now = os.clock()
		if now >= missingVFXReadyAt then
			missingVFXReadyAt = now + 0.8
			missingResumeUntil = now + 0.6
			glitchUntil = now + 0.24
		end
	elseif kind == "MissingFrameResume" then
		if os.clock() < missingResumeUntil then
			glitchUntil = math.max(glitchUntil, os.clock() + 0.14)
			missingResumeUntil = 0
		end
	elseif kind == "StolenSecondRelease" then
		flash.BackgroundColor3 = Color3.fromRGB(255, 218, 106)
		flash.BackgroundTransparency = 0.9
		Tween:Create(flash, TweenInfo.new(0.22), { BackgroundTransparency = 1 }):Play()
		tickSound.PlaybackSpeed = 1.4
		tickSound:Play()
	elseif kind == "StolenSecond" then
		glitchUntil = math.max(glitchUntil, os.clock() + 0.1)
	elseif kind == "FutureSightDodge" then
		flash.BackgroundColor3 = Color3.fromRGB(255, 214, 73)
		flash.BackgroundTransparency = 0.92
		Tween:Create(flash, TweenInfo.new(0.22), { BackgroundTransparency = 1 }):Play()
	elseif kind == "EtherealAcumenStart" then
		startEthereal(data)
	elseif kind == "EtherealAcumenEnd" then
		stopEthereal(data.Token)
	elseif kind == "EtherealOrbitStart" then
		startOrbit(data)
	elseif kind == "EtherealOrbitEnd" then
		stopOrbit(data.Token)
	elseif kind == "P3ProjectileDarkness" then
		startSight(data)
	elseif kind == "P3ProjectileDarknessEnd" then
		stopSight(data.Token)
	elseif kind == "AscensionImpactFrame" then
		flash.BackgroundColor3 = Color3.fromRGB(90, 4, 15)
		flash.BackgroundTransparency = 0.6
		Tween
			:Create(flash, TweenInfo.new(math.clamp(data.Duration or 0.08, 0.06, 0.12)), { BackgroundTransparency = 1 })
			:Play()
	elseif kind == "GoldenClockIntro" then
		startClockIntro(data)
	elseif kind == "GoldenClockIntroEnd" then
		stopClockIntro(data.Token)
	elseif kind == "GoldenHourStart" or kind == "GoldenHourEnd" then
		updateGoldenHour()
	elseif kind == "GoldenClockRelease" then
		resumeAt = os.clock()
		clockOverlay.Visible = true
		flash.BackgroundColor3 = Color3.fromRGB(255, 239, 163)
		flash.BackgroundTransparency = 0.12
		Tween:Create(flash, TweenInfo.new(0.65, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
		local char = player.Character
		if char then
			char:SetAttribute("GoldenClockReleaseVFXSequence", data.Sequence)
		end
	elseif kind == "ImpactTint" then
		local now = os.clock()
		if now - impactTintAt < 0.08 or player:GetAttribute("ViewAsServer") then
			return
		end
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and data.Origin and (root.Position - data.Origin).Magnitude > (data.Radius or 160) then
			return
		end
		impactTintAt = now
		if impactTintTween then
			impactTintTween:Cancel()
		end
		local strength = math.clamp(data.Intensity or 0.5, 0, 1)
		impactTint.TintColor = Color3.new(1, 1, 1):Lerp(data.Color or Color3.new(1, 0.9, 0.6), 0.55 * strength)
		impactTint.Contrast = 0.35 * strength
		impactTint.Brightness = 0.12 * strength
		impactTint.Saturation = data.Invert and -1 or 0.25 * strength
		impactTint.Enabled = true
		impactTintTween = Tween:Create(
			impactTint,
			TweenInfo.new(data.Duration or 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ TintColor = Color3.new(1, 1, 1), Contrast = 0, Brightness = 0, Saturation = 0 }
		)
		impactTintTween.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed then
				impactTint.Enabled = false
			end
		end)
		impactTintTween:Play()
	elseif kind == "Shake" then
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local distance = root and data.Origin and (root.Position - data.Origin).Magnitude or 0
		strength = (data.Intensity or 0.5) * math.max(0.15, 1 - distance / (data.Radius or 240))
		shakeDuration = data.Duration or 0.8
		shakeUntil = os.clock() + shakeDuration
		if char then
			char:SetAttribute("BossShakeCount", (char:GetAttribute("BossShakeCount") or 0) + 1)
		end
	elseif kind == "ParryStart" then
		stopOrbit()
		finishParry()
		parryUntil = os.clock() + (data.Duration or 2.8)
		parryCamera = workspace:FindFirstChildOfClass("Camera")
		if parryCamera then
			savedType = parryCamera.CameraType
			savedSubject = parryCamera.CameraSubject
			parryCamera.CameraType = Enum.CameraType.Scriptable
		end
		color.Enabled = true
		quote.Text = data.Text or "Too late..."
		quote.Visible = true
		flash.BackgroundTransparency = 0.25
		Tween:Create(flash, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
		local char = player.Character
		if char then
			char:SetAttribute("ParryCinematicActive", true)
		end
	elseif kind == "ParryEnd" then
		finishParry()
	end
end)
local characterConnection = player.CharacterAdded:Connect(function(character)
	frozenView.Stop()
 stopClockIntro(nil,true)
	stopEthereal(nil, true)
	stopOrbit()
	stopSight()
	finishParry()
	shakeUntil = 0
	glitchUntil = 0
	missingResumeUntil = 0
	distortion.Enabled = false
	distortionBlur.Enabled = false
	bindCriticalHealth(character)
	if workspace:GetAttribute("GoldenTimeStopped") == true then frozenView.Start() end
end)
local characterRemovingConnection = player.CharacterRemoving:Connect(function()
 stopClockIntro(nil,true)
 finishParry()
	frozenView.Stop()
	stopEthereal(nil, true)
	stopOrbit()
	stopSight()
	resetCriticalHealth()
end)
require(game.ReplicatedStorage.BossShared.Presentation.CinematicReset).Register(script,function()
 stopClockIntro(nil,true)finishParry()stopOrbit()stopSight()stopEthereal(nil,true)
 frozenView.Stop()
 shakeUntil=0 glitchUntil=0 missingResumeUntil=0
 distortion.Enabled=false distortionBlur.Enabled=false
 table.clear(fogRecords)restoreFog()
end)
if player.Character then
 bindCriticalHealth(player.Character)
end
local timeStopConnection = workspace:GetAttributeChangedSignal("GoldenTimeStopped"):Connect(updateGoldenHour)
local collapseConnection = workspace:GetAttributeChangedSignal("LastMinuteActive"):Connect(function()
	collapseActive = workspace:GetAttribute("LastMinuteActive") == true
	if collapseActive and lastMinute.Text == "" then
		collapseStage(1)
	end
end)
collapseActive = workspace:GetAttribute("LastMinuteActive") == true
if collapseActive then
	collapseStage(1)
end
updateGoldenHour()
Run:BindToRenderStep("GoldenBossCinematicFX", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local blurCharacter = player.Character
	local blurHumanoid = blurCharacter and blurCharacter:FindFirstChildOfClass("Humanoid")
	debuffBlur.Enabled = blurHumanoid ~= nil and blurHumanoid.Health > 0 and not player:GetAttribute("ViewAsServer")
		and (blurCharacter:GetAttribute("BlurUntil") or 0) > workspace:GetServerTimeNow()
	local fogExpired = {}
	local fogNow = workspace:GetServerTimeNow()
	for kind, record in pairs(fogRecords) do
		local hum = record.Character:FindFirstChildOfClass("Humanoid")
		local ownerHum = record.Owner:FindFirstChildOfClass("Humanoid")
		if
			player.Character ~= record.Character
			or player:GetAttribute("ViewAsServer")
			or not hum
			or hum.Health <= 0
			or not record.Owner.Parent
			or not ownerHum
			or ownerHum.Health <= 0
			or math.floor(record.Owner:GetAttribute("Phase") or 1) ~= 3
			or record.Owner:GetAttribute("EncounterEnded")
			or fogNow >= record.EndsAt
		then
			fogExpired[#fogExpired + 1] = kind
		end
	end
	for _, kind in ipairs(fogExpired) do
		if kind == "Ethereal" then
			stopEthereal()
		else
			stopSight()
		end
	end
	if sightToken then
		surroundElapsed += dt
		if surroundElapsed >= 1/30 then surroundElapsed=0;placeSurround() end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if
			not sightOwner
			or not sightOwner.Parent
			or math.floor(sightOwner:GetAttribute("Phase") or 1) ~= 3
			or sightOwner:GetAttribute("EncounterEnded")
			or not hum
			or hum.Health <= 0
			or workspace:GetServerTimeNow() >= (sightEndsAt or 0)
		then
			stopSight()
		end
	end
	if etherealToken then
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local ownerHum = etherealOwner and etherealOwner:FindFirstChildOfClass("Humanoid")
		if
			not etherealOwner
			or not etherealOwner.Parent
			or math.floor(etherealOwner:GetAttribute("Phase") or 1) ~= 3
			or etherealOwner:GetAttribute("EtherealAcumenActive") ~= true
			or etherealOwner:GetAttribute("EncounterEnded")
			or not ownerHum
			or ownerHum.Health <= 0
			or not hum
			or hum.Health <= 0
			or workspace:GetServerTimeNow() >= (etherealEndsAt or 0)
		then
			stopEthereal()
		end
	end
	local camera = workspace:FindFirstChildOfClass("Camera")
	if not camera then
		return
	end
	if orbitRecord then
		local record = orbitRecord
		local hum = record.Character:FindFirstChildOfClass("Humanoid")
		local now = workspace:GetServerTimeNow()
		if
			player.Character ~= record.Character
			or not hum
			or hum.Health <= 0
			or not record.Owner.Parent
			or math.floor(record.Owner:GetAttribute("Phase") or 1) ~= 3
			or record.Owner:GetAttribute("EtherealAcumenActive") ~= true
			or now >= record.EndsAt
			or now - record.At > 0.5 and record.Character:GetAttribute("EtherealOrbitActive") ~= true
			or camera ~= record.Camera
			or camera:GetAttribute("EtherealCameraToken") ~= record.Token
		then
			stopOrbit()
		else
			local elapsed = now - record.At
			local angle = elapsed * record.Speed * 0.65
			local bob = math.sin(elapsed * record.BobSpeed) * record.BobHeight * 0.45
			local lookAt = record.Center + Vector3.new(0, record.Height + 4 + bob, 0)
			local eye = record.Center
				+ Vector3.new(
					math.cos(angle) * (record.Radius + 17),
					record.Height + 14 + bob,
					math.sin(angle) * (record.Radius + 17)
				)
			camera.CFrame = CFrame.lookAt(eye, lookAt)
		end
	end
	criticalOpacity += (criticalTarget - criticalOpacity) * (1 - math.exp(-dt * 9))
	for _, edge in ipairs(criticalEdges) do
		edge.BackgroundTransparency = 1 - criticalOpacity
	end
	lastMinute.Visible = collapseActive
	local pulse = math.max(0, 1 - (os.clock() - collapsePulse) / 0.28)
	lastMinute.TextColor3 = Color3.fromRGB(255, 204 + math.floor(pulse * 35), 67 + math.floor(pulse * 60))
	local skipping = os.clock() < glitchUntil
	glitch.BackgroundTransparency = skipping and 0.965 or 1
	distortion.Enabled = skipping
	distortionBlur.Enabled = skipping
	distortionBlur.Size = skipping and (2 + math.abs(math.sin(os.clock() * 75)) * 2) or 0
	for index, bar in ipairs(glitchBars) do
		bar.BackgroundTransparency = skipping and (index % 2 == 0 and 0.66 or 0.78) or 1
		if skipping then
			bar.Position = UDim2.fromScale(
				math.sin(os.clock() * 95 + index) * 0.07,
				0.06 + index * 0.125 + math.sin(os.clock() * 64 + index) * 0.04
			)
			bar.Rotation = math.sin(os.clock() * 53 + index) * 1.2
		end
	end
	if clockDeadline and os.clock() >= clockDeadline then
		stopClockIntro()
	end
	if resumeAt then
		local alpha = math.clamp((os.clock() - resumeAt) / 0.7, 0, 1)
		clockOverlay.Rotation = alpha * 40
		clockRim.Transparency = 0.76 + 0.24 * alpha
		for _, tick in ipairs(clockTicks) do
			tick.BackgroundTransparency = 0.67 + 0.33 * alpha
		end
		if alpha >= 1 then
			clockOverlay.Visible = false
			resumeAt = nil
		end
	elseif not hourStopped then
		clockOverlay.Visible = false
	end
	if #numbers > 0 and (not numberPanel or not numberPanel.Parent) then
		local hud = player.PlayerGui:FindFirstChild("AlterGoldenBossHUD")
		numberPanel = hud and hud:FindFirstChild("BossPanel", true)
	end
	local minimumY = numberPanel and numberPanel.AbsolutePosition.Y + numberPanel.AbsoluteSize.Y + 45
		or camera.ViewportSize.Y * 0.25
	for index = #numbers, 1, -1 do
		local number = numbers[index]
		local age = os.clock() - number.At
		if age >= 0.85 then
			releaseNumber(index)
		else
			local point, visible = camera:WorldToViewportPoint(number.Position)
			number.Label.Visible = visible
			number.Label.Position = UDim2.fromOffset(
				point.X + number.Offset,
				math.max(number.PlayerDamage and 20 or minimumY, point.Y - age * 48)
			)
			local alpha = math.clamp((age - 0.18) / 0.67, 0, 1)
			number.Label.TextTransparency = alpha
			number.Label.TextStrokeTransparency = 0.15 + 0.85 * alpha
		end
	end
	if lastCamera == camera and lastApplied and camera.CFrame == lastApplied then
		camera.CFrame = lastBase
	end
	lastApplied = nil
	if parryUntil > 0 then
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if os.clock() > parryUntil or not root or not hum or hum.Health <= 0 then
			finishParry()
		else
			local eye = root.Position + root.CFrame.RightVector * 9 + Vector3.new(0, 4, 0) + root.CFrame.LookVector * 2
			camera.CFrame = CFrame.lookAt(eye, root.Position - root.CFrame.LookVector * 2 + Vector3.new(0, 1, 0))
		end
	end
	if os.clock() < shakeUntil or skipping then
		local fade = math.clamp((shakeUntil - os.clock()) / shakeDuration, 0, 1)
		local t = os.clock() * 35
		local amplitude = strength * fade
		lastCamera = camera
		lastBase = camera.CFrame
		local offset = Vector3.new(math.noise(t, 0) * amplitude, math.noise(0, t) * amplitude, 0)
		local tear = skipping and math.sin(os.clock() * 85) * 0.005 or 0
		camera.CFrame = lastBase
			* CFrame.new(offset)
			* CFrame.Angles(0, tear * 0.35, math.noise(t, t) * amplitude * 0.015 + tear)
		lastApplied = camera.CFrame
	end
end)
script.Destroying:Connect(function()
	frozenView.Destroy()
	remoteConnection:Disconnect()
	characterConnection:Disconnect()
	characterRemovingConnection:Disconnect()
	timeStopConnection:Disconnect()
	collapseConnection:Disconnect()
	Run:UnbindFromRenderStep("GoldenBossCinematicFX")
	resetCriticalHealth()
	stopEthereal(nil, true)
	stopOrbit()
	stopSight()
	table.clear(fogRecords)
	restoreFog()
	finishParry()
	stopClockIntro(nil, true)
	cancelSkyTweens()
	gui:Destroy()
	debuffBlur:Destroy()
	color:Destroy()
	hourColor:Destroy()
	clockSky:Destroy()
	distortion:Destroy()
	distortionBlur:Destroy()
	tickSound:Destroy()
	dongSound:Destroy()
	table.clear(numberPool)
	table.clear(numbers)
end)
