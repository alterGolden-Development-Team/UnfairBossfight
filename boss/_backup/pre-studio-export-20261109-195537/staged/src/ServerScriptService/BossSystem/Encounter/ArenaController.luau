local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Tween = game:GetService("TweenService")
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local api = {}
local VERSION = 3
local stone = Color3.fromRGB(98, 101, 93)
local oldGold = Color3.fromRGB(145, 130, 77)
local moss = Color3.fromRGB(72, 92, 55)
local cached, activation, holdStep, starStep
local holds, connections, tweens = {}, {}, {}
local buildInProgress = false
local yieldDuringBuild = false
local buildPartCount = 0
local sight = RaycastParams.new()
sight.FilterType = Enum.RaycastFilterType.Exclude
sight.RespectCanCollide = true
local function part(parent, name, size, frame, color, material, collide, className)
	local p = Instance.new(className or "Part")
	p.Name = name
	p.Size = size
	p.CFrame = frame
	p.Color = color
	p.Material = material or Enum.Material.Slate
	p.Anchored = true
	p.CanCollide = collide == true
	p.CanTouch = false
	p.CanQuery = p.CanCollide
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	if yieldDuringBuild then
		buildPartCount += 1
		if buildPartCount % 32 == 0 then
			task.wait()
		end
	end
	return p
end
local function model(parent, name)
	local value = Instance.new("Model")
	value.Name = name
	value.Parent = parent
	return value
end
local function read(arena)
	local approach = arena:FindFirstChild("RuinedApproach")
	local star = approach and approach:FindFirstChild("PolyStar")
	local core = star and star:FindFirstChild("Core")
	local gate = approach and approach:FindFirstChild("SwordGate")
	if not approach or not core or not gate then
		return nil
	end
	return {
		Arena = arena,
		Floor = arena.Grassland,
		Approach = approach,
		Gate = gate,
		PolyStar = star,
		Prompt = core:FindFirstChildOfClass("ProximityPrompt"),
		ExteriorSpawn = approach.ExteriorSpawn,
		BattlefieldSpawn = arena.GreyCircleSpawn,
	}
end
local function cancelTweens()
	for _, value in ipairs(tweens) do
		value:Cancel()
	end
	table.clear(tweens)
end
local function stopStarMotion()
	if starStep then
		starStep:Disconnect()
		starStep = nil
	end
end
local function startStarMotion(data)
	stopStarMotion()
	if not Run:IsRunning() or data.PolyStar:GetAttribute("Consumed") == true then
		return
	end
	local star = data.PolyStar
	local rest = star:GetAttribute("RestFrame")
	if typeof(rest) ~= "CFrame" then
		return
	end
	local elapsed, step = 0, 0
	 
	starStep = Run.Heartbeat:Connect(function(dt)
		if not star.Parent or star:GetAttribute("Consumed") == true then
			stopStarMotion()
			return
		end
		elapsed += dt
		step += dt
		if step < 0.05 then
			return
		end
		step = 0
		star:PivotTo(rest * CFrame.new(0, math.sin(elapsed * 1.35) * 0.28, 0) * CFrame.Angles(0, elapsed * 0.32, 0))
	end)
end
local function cutEntrance(arena, frame, opening)
	local walls = arena:FindFirstChild("SurroundingWalls")
	assert(walls, "Arena walls are missing")
	local halfX = arena.Grassland.Size.X * 0.5
	local wall
	for _, candidate in ipairs(walls:GetChildren()) do
		if candidate:IsA("BasePart") and candidate.Name == "StoneWall" then
			local point = frame:PointToObjectSpace(candidate.Position)
			if point.X < -halfX + 2 and math.abs(point.Z) < 2 and candidate.Size.Z > candidate.Size.X then
				wall = candidate
				break
			end
		end
	end
	local oldEntrance = walls:FindFirstChild("RuinedEntrance")
	local source = oldEntrance and oldEntrance:GetAttribute("SourceFrame") or wall and wall.CFrame
	local size = oldEntrance and oldEntrance:GetAttribute("SourceSize") or wall and wall.Size
	assert(typeof(source) == "CFrame" and typeof(size) == "Vector3", "The west arena wall source is missing")
	local side = (size.Z - opening) * 0.5
	assert(side > 8, "Arena wall is too small for the entry")
	local trimFrame, trimSize
	if oldEntrance then
		trimFrame = oldEntrance:GetAttribute("SourceTrimFrame")
		trimSize = oldEntrance:GetAttribute("SourceTrimSize")
		 
		 
		if not trimFrame then
			local oldSide = oldEntrance:FindFirstChild("NorthWall")
			local oldOpening = oldSide and size.Z - oldSide.Size.Z * 2
			local strip = oldEntrance:FindFirstChild("BrokenEntranceTrim")
			if strip and oldOpening then
				local localZ = source:PointToObjectSpace(strip.Position).Z
				local sign = localZ < 0 and -1 or 1
				trimFrame = strip.CFrame * CFrame.new(0, 0, -sign * (oldOpening * 0.5 + strip.Size.Z * 0.5))
				trimSize = Vector3.new(strip.Size.X, strip.Size.Y, strip.Size.Z * 2 + oldOpening)
			end
		end
	end
	for _, trim in ipairs(walls:GetChildren()) do
		if trim:IsA("BasePart") and trim.Name == "GoldenWallTrim" then
			local point = frame:PointToObjectSpace(trim.Position)
			if point.X < -halfX + 2 and math.abs(point.Z) < 2 and trim.Size.Z > trim.Size.X then
				trimFrame, trimSize = trim.CFrame, trim.Size
				trim:Destroy()
			end
		end
	end
	if oldEntrance then
		oldEntrance:Destroy()
	end
	if wall then
		wall:Destroy()
	end
	local entrance = model(walls, "RuinedEntrance")
	entrance:SetAttribute("SourceFrame", source)
	entrance:SetAttribute("SourceSize", size)
	entrance:SetAttribute("OpeningWidth", opening)
	local offset = opening * 0.5 + side * 0.5
	for _, sign in ipairs({ -1, 1 }) do
		part(
			entrance,
			sign < 0 and "NorthWall" or "SouthWall",
			Vector3.new(size.X, size.Y, side),
			source * CFrame.new(0, 0, sign * offset),
			stone,
			Enum.Material.Slate,
			true
		)
	end
	 
	if trimFrame and trimSize then
		entrance:SetAttribute("SourceTrimFrame", trimFrame)
		entrance:SetAttribute("SourceTrimSize", trimSize)
		local length = (trimSize.Z - opening) * 0.5
		for _, sign in ipairs({ -1, 1 }) do
			part(
				entrance,
				"BrokenEntranceTrim",
				Vector3.new(trimSize.X, trimSize.Y, length),
				trimFrame * CFrame.new(0, 0, sign * (opening * 0.5 + length * 0.5)),
				oldGold,
				Enum.Material.CorrodedMetal,
				false
			)
		end
	end
	return CFrame.new(source.Position.X, frame.Position.Y, source.Position.Z) * frame.Rotation
end
 
local function decorate(arena)
	if arena:GetAttribute("CourtDecorationVersion") == 1 and arena:FindFirstChild("ChronicleCourt") then
		return
	end
	local previous = arena:FindFirstChild("ChronicleCourt")
	if previous then
		previous:Destroy()
	end
	local details = model(arena, "ChronicleCourt")
	local floor = arena.Grassland
	local frame = floor.CFrame * CFrame.new(0, floor.Size.Y * 0.5, 0)
	local halfX, halfZ = floor.Size.X * 0.5, floor.Size.Z * 0.5
	local basalt = Color3.fromRGB(48, 53, 55)
	local pale = Color3.fromRGB(126, 129, 114)
	local brass = Color3.fromRGB(170, 145, 69)
	local radius = math.min(halfX, halfZ) * 0.38
	local function detail(name, size, cf, color, material, class)
		local value = part(details, name, size, frame * cf, color, material, false, class)
		value.CastShadow = size.Y > 0.5
		return value
	end
	floor.Color = Color3.fromRGB(72, 86, 61)
	local dial = detail(
		"WeatheredClockCourt",
		Vector3.new(0.09, radius * 2.22, radius * 2.22),
		CFrame.new(0, 0.014, 0) * CFrame.Angles(0, 0, math.pi / 2),
		basalt,
		Enum.Material.Slate
	)
	dial.Shape = Enum.PartType.Cylinder
	local function ring(r, count, width, color)
		for index = 1, count do
			local angle = (index - 0.5) * math.pi * 2 / count
			detail(
				"ClockInlay",
				Vector3.new(2 * r * math.sin(math.pi / count) * 0.98, 0.04, width),
				CFrame.new(math.cos(angle) * r, 0.08, math.sin(angle) * r) * CFrame.Angles(0, -angle + math.pi / 2, 0),
				color,
				Enum.Material.Metal
			)
		end
	end
	ring(radius, 48, 0.24, brass)
	ring(radius * 0.76, 40, 0.12, pale)
	ring(radius * 0.32, 24, 0.2, brass)
	for index = 1, 12 do
		local angle = index * math.pi / 6
		detail(
			"HourMarker",
			Vector3.new(index % 3 == 0 and 0.85 or 0.45, 0.05, index % 3 == 0 and 6 or 3.5),
			CFrame.new(math.sin(angle) * radius * 0.88, 0.09, math.cos(angle) * radius * 0.88)
				* CFrame.Angles(0, angle, 0),
			brass,
			Enum.Material.Metal
		)
	end
	detail(
		"BrokenHourHand",
		Vector3.new(0.6, 0.055, radius * 0.43),
		CFrame.new(-3, 0.11, -radius * 0.13) * CFrame.Angles(0, -0.55, 0),
		pale,
		Enum.Material.CorrodedMetal
	)
	detail(
		"BrokenMinuteHand",
		Vector3.new(0.4, 0.055, radius * 0.63),
		CFrame.new(5, 0.11, radius * 0.23) * CFrame.Angles(0, 0.7, 0),
		brass,
		Enum.Material.CorrodedMetal
	)
	 
	for index = 1, 8 do
		local angle = index * 0.91
		local r = radius * (0.28 + (index % 4) * 0.14)
		detail(
			"CourtStoneSeam",
			Vector3.new(7 + index % 3 * 3, 0.03, 0.15),
			CFrame.new(math.cos(angle) * r, 0.072, math.sin(angle) * r) * CFrame.Angles(0, index * 0.37, 0),
			Color3.fromRGB(27, 31, 32),
			Enum.Material.Slate
		)
	end
	for index = 1, 10 do
		local x = -halfX + 14 + index * (halfX - 20) / 11
		detail(
			"WornApproachPaving",
			Vector3.new(8, 0.045, 8),
			CFrame.new(x, 0.025, (index % 3 - 1) * 0.7) * CFrame.Angles(0, (index % 3 - 1) * 0.04, 0),
			Color3.fromRGB(97 + index % 2 * 7, 102 + index % 2 * 6, 91),
			Enum.Material.Cobblestone
		)
	end
	for _, side in ipairs({ -1, 1 }) do
		for index = 1, 4 do
			local x = (index - 2.5) * halfX * 0.48
			local base = CFrame.new(x, 0, side * (halfZ - 3.5))
			detail(
				"CourtButtressFoot",
				Vector3.new(7, 0.7, 5),
				base * CFrame.new(0, 0.35, 0),
				basalt,
				Enum.Material.Slate
			)
			detail("CourtButtress", Vector3.new(3.6, 11, 3), base * CFrame.new(0, 5.8, 0), pale, Enum.Material.Slate)
			detail(
				"ButtressGoldBand",
				Vector3.new(3.8, 0.3, 3.2),
				base * CFrame.new(0, 8, 0),
				brass,
				Enum.Material.CorrodedMetal
			)
			detail("ButtressCap", Vector3.new(5, 1, 4), base * CFrame.new(0, 11.6, 0), basalt, Enum.Material.Slate)
			local banner = base * CFrame.new(0, 7, -side * 2.15)
			detail(
				"TatteredRoyalBanner",
				Vector3.new(2.3, 5, 0.12),
				banner,
				Color3.fromRGB(43, 49, 43),
				Enum.Material.Fabric
			)
			detail(
				"BannerHourSigil",
				Vector3.new(0.3, 3, 0.14),
				banner * CFrame.new(0, 0, -side * 0.07),
				brass,
				Enum.Material.Metal
			)
			detail(
				"BannerCrownSigil",
				Vector3.new(1.5, 0.25, 0.15),
				banner * CFrame.new(0, 0.9, -side * 0.075),
				brass,
				Enum.Material.Metal
			)
			if index == 1 or index == 4 then
				local lamp = detail(
					"AmberCourtLantern",
					Vector3.new(1.2, 2, 1.2),
					base * CFrame.new(0, 12.7, 0),
					Color3.fromRGB(220, 174, 71),
					Enum.Material.Neon
				)
				lamp.Transparency = 0.35
				local light = Instance.new("PointLight")
				light.Color = lamp.Color
				light.Brightness = 0.6
				light.Range = 16
				light.Shadows = false
				light.Parent = lamp
			end
		end
	end
	for _, side in ipairs({ -1, 1 }) do
		local base = CFrame.new(halfX - 5, 0, side * halfZ * 0.55)
		detail(
			"CollapsedCourtPlinth",
			Vector3.new(9, 1.7, 8),
			base * CFrame.new(0, 0.85, 0),
			basalt,
			Enum.Material.Slate
		)
		detail(
			"FallenRoyalColumn",
			Vector3.new(3.5, 8, 3.5),
			base * CFrame.new(-3, 2, -side * 3) * CFrame.Angles(0, 0.35, math.pi * 0.43),
			pale,
			Enum.Material.Slate
		)
		detail(
			"BrokenColumnCapital",
			Vector3.new(6, 1.4, 5),
			base * CFrame.new(4, 1.2, side * 2) * CFrame.Angles(0, 0.4, 0.12),
			brass,
			Enum.Material.CorrodedMetal
		)
	end
	arena:SetAttribute("CourtDecorationVersion", 1)
	arena:SetAttribute("CourtDecorationPartCount", #details:GetDescendants())
end

function api.Decorate()
	local arena = assert(workspace:FindFirstChild("GoldenGrasslandArena"), "Arena is missing")
	decorate(arena)
	return arena:FindFirstChild("ChronicleCourt")
end
local function buildInternal()
	local arena = workspace:FindFirstChild("GoldenGrasslandArena")
	assert(arena and arena:FindFirstChild("Grassland"), "Production arena floor is missing")
	decorate(arena)
	if
		cached
		and cached.Arena == arena
		and cached.Approach.Parent
		and arena:GetAttribute("RuinedApproachVersion") == VERSION
	then
		return cached
	end
	if arena:GetAttribute("RuinedApproachVersion") == VERSION then
		cached = read(arena)
		if cached then
			return cached
		end
	end
	cancelTweens()
	stopStarMotion()
	local rebind = activation and #connections > 0
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
	table.clear(holds)
	if holdStep then
		holdStep:Disconnect()
		holdStep = nil
	end
	local old = arena:FindFirstChild("RuinedApproach")
	if old then
		old:Destroy()
	end
	local floor = arena.Grassland
	local frame = floor.CFrame * CFrame.new(0, floor.Size.Y * 0.5, 0)
	local halfX, halfZ = floor.Size.X * 0.5, floor.Size.Z * 0.5
	local distance = Config.ExteriorDistance or 70
	local opening = 44
	local portal = cutEntrance(arena, frame, opening)
	floor.Color = Color3.fromRGB(72, 86, 61)
	for _, piece in ipairs(arena.SurroundingWalls:GetDescendants()) do
		if piece:IsA("BasePart") then
			piece.Anchored = true
			piece.Color = piece.Name:find("Trim") and oldGold or stone
			piece.Material = piece.Name:find("Trim") and Enum.Material.CorrodedMetal or Enum.Material.Slate
		end
	end
	local oldDetails = arena:FindFirstChild("GrasslandDetails")
	if oldDetails then
		for _, piece in ipairs(oldDetails:GetDescendants()) do
			if piece:IsA("BasePart") then
				if piece.Name:find("Flower") then
					piece:Destroy()
				elseif piece.Name:find("Grass") then
					piece.Color = moss
				else
					piece.Color = Color3.fromRGB(106, 108, 95)
				end
			end
		end
	end
	local approach = model(arena, "RuinedApproach")
	local exterior = model(approach, "ExteriorRuins")
	local plazaCenter = -halfX - distance * 0.5 - 4
	 
	 
	part(
		exterior,
		"ExteriorGround",
		Vector3.new(distance + 32, 6, 72),
		frame * CFrame.new(plazaCenter, -3, 0),
		floor.Color,
		Enum.Material.Grass,
		true
	)
	part(
		exterior,
		"EntranceCauseway",
		Vector3.new(distance + 25, 0.2, 12),
		frame * CFrame.new(plazaCenter, -0.07, 0),
		Color3.fromRGB(116, 117, 102),
		Enum.Material.Cobblestone,
		true
	)
	part(
		exterior,
		"GateThreshold",
		Vector3.new(24, 0.22, opening),
		portal * CFrame.new(0, -0.08, 0),
		Color3.fromRGB(115, 115, 101),
		Enum.Material.Cobblestone,
		true
	)
	for _, sign in ipairs({ -1, 1 }) do
		part(
			exterior,
			"WornThresholdShoulder",
			Vector3.new(25, 0.16, 7),
			portal * CFrame.new(-1, -0.04, sign * (opening * 0.5 + 3.5)),
			Color3.fromRGB(103, 104, 79),
			Enum.Material.Ground,
			false
		)
		part(
			exterior,
			"OvergrownThresholdEdge",
			Vector3.new(25, 0.12, 4),
			portal * CFrame.new(-1, -0.04, sign * (opening * 0.5 + 8.4)),
			floor.Color,
			Enum.Material.Grass,
			false
		)
	end
	for index = 1, 8 do
		local x = -halfX - distance + index * distance / 9
		local side = index % 2 == 0 and -1 or 1
		part(
			exterior,
			"ErodedPathShoulder",
			Vector3.new(8 + index % 3 * 2, 0.12, 3 + index % 2),
			frame * CFrame.new(x, -0.035, side * 7.3) * CFrame.Angles(0, (index % 3 - 1) * 0.16, 0),
			Color3.fromRGB(104 + index % 3 * 3, 103 + index % 2 * 4, 82),
			Enum.Material.Ground,
			false
		)
	end
	for index = 1, 5 do
		local x = -halfX - distance + index * distance / 6
		for _, sign in ipairs({ -1, 1 }) do
			local z = sign * (19 + (index % 2) * 3)
			local height = 4 + (index * 7) % 11
			local base = frame * CFrame.new(x, 0, z)
			part(
				exterior,
				"BrokenColumn",
				Vector3.new(4, height, 4),
				base * CFrame.new(0, height * 0.5, 0),
				stone,
				nil,
				true
			)
			part(exterior, "ErodedColumnFoot", Vector3.new(6, 1, 6), base * CFrame.new(0, 0.5, 0), stone, nil, true)
			part(
				exterior,
				"FallenMasonry",
				Vector3.new(6, 2, 3),
				base * CFrame.new(4, 1, sign * 4) * CFrame.Angles(0, index * 0.8, 0.12),
				stone,
				nil,
				false
			)
			part(
				exterior,
				"WeatheredGoldInlay",
				Vector3.new(4.1, 0.25, 4.1),
				base * CFrame.new(0, math.min(3, height - 0.5), 0),
				oldGold,
				Enum.Material.CorrodedMetal,
				false
			)
		end
	end
	local statue = model(approach, "BrokenR6GateStatue")
	local statueFrame = portal * CFrame.new(-8, 0, opening * 0.5 + 11) * CFrame.Angles(0, math.pi * 0.5, 0)
	part(statue, "Pedestal", Vector3.new(14, 3, 12), statueFrame * CFrame.new(0, 1.5, 0), stone, nil, true)
	part(statue, "Right Leg", Vector3.new(4.5, 10, 5), statueFrame * CFrame.new(2.6, 8, 0), stone, nil, false)
	part(statue, "Broken Left Leg", Vector3.new(4.5, 4, 5), statueFrame * CFrame.new(-2.6, 11, 0), stone, nil, false)
	part(
		statue,
		"Torso",
		Vector3.new(10, 10, 5),
		statueFrame * CFrame.new(0, 18, 0) * CFrame.Angles(0, 0, -0.07),
		stone,
		nil,
		false
	)
	part(
		statue,
		"Head",
		Vector3.new(8, 5, 6),
		statueFrame * CFrame.new(-0.5, 25.5, 0) * CFrame.Angles(0.12, 0, -0.08),
		stone,
		nil,
		false
	)
	part(
		statue,
		"WeatheredRightEye",
		Vector3.new(1.7, 0.35, 0.15),
		statueFrame * CFrame.new(1.35, 26.1, -3.1),
		Color3.fromRGB(49, 52, 46),
		Enum.Material.Slate,
		false
	)
	part(
		statue,
		"BrokenLeftEye",
		Vector3.new(0.7, 0.35, 0.15),
		statueFrame * CFrame.new(-2.2, 26, -3.1) * CFrame.Angles(0, 0, -0.15),
		Color3.fromRGB(49, 52, 46),
		Enum.Material.Slate,
		false
	)
	part(
		statue,
		"WornStoneMouth",
		Vector3.new(2.6, 0.2, 0.15),
		statueFrame * CFrame.new(-0.5, 24.8, -3.12),
		Color3.fromRGB(49, 52, 46),
		Enum.Material.Slate,
		false
	)
	part(
		statue,
		"Right Arm",
		Vector3.new(4.5, 10, 5),
		statueFrame * CFrame.new(7, 19, -1) * CFrame.Angles(-0.65, 0, -0.2),
		stone,
		nil,
		false
	)
	part(
		statue,
		"Broken Left Arm",
		Vector3.new(4.5, 4, 5),
		statueFrame * CFrame.new(-7, 21, 0) * CFrame.Angles(0, 0, 0.2),
		stone,
		nil,
		false
	)
	part(
		statue,
		"FallenForearm",
		Vector3.new(4.5, 6, 5),
		statueFrame * CFrame.new(-9, 3.5, -5) * CFrame.Angles(0, 0.3, math.pi * 0.42),
		stone,
		nil,
		false
	)
	part(
		statue,
		"FallenFoot",
		Vector3.new(4.5, 6, 5),
		statueFrame * CFrame.new(-2.5, 3, -10) * CFrame.Angles(0.15, 0.3, math.pi * 0.5),
		stone,
		nil,
		false
	)
	part(
		statue,
		"FadedKnightCrest",
		Vector3.new(5, 0.3, 0.2),
		statueFrame * CFrame.new(0, 21, -2.55),
		oldGold,
		Enum.Material.CorrodedMetal,
		false
	)
	local swordFrame = statueFrame * CFrame.new(9, 17, -6) * CFrame.Angles(0.2, 0, -0.3)
	part(statue, "BrokenSwordGrip", Vector3.new(1.2, 5, 1.2), swordFrame, oldGold, Enum.Material.CorrodedMetal, false)
	part(statue, "StoneSwordGuard", Vector3.new(7, 1, 2), swordFrame * CFrame.new(0, -3, 0), stone, nil, false)
	part(statue, "BrokenStoneSword", Vector3.new(2.5, 11, 1), swordFrame * CFrame.new(0, -9, 0), stone, nil, false)
	for index = -1, 1 do
		part(
			statue,
			"BrokenCrownSpire",
			Vector3.new(1.2, 3.5 + index * 0.4, 1.2),
			statueFrame * CFrame.new(index * 2.6, 29, 0) * CFrame.Angles(0, 0, -index * 0.22),
			stone,
			nil,
			false
		)
	end
	for index = 1, 7 do
		local height = 13 + index * 1.8
		part(
			statue,
			"StoneFracture",
			Vector3.new(0.16, 2.3, 0.12),
			statueFrame
				* CFrame.new((index % 3 - 1) * 1.5, height, -2.65)
				* CFrame.Angles(0, 0, index % 2 == 0 and 0.48 or -0.6),
			Color3.fromRGB(42, 45, 39),
			Enum.Material.Slate,
			false
		)
	end
	for index = 1, 4 do
		local base = frame
			* CFrame.new(-halfX - distance + index * 13, 0.4, index % 2 == 0 and 9 or -10)
			* CFrame.Angles(math.pi * 0.5, 0, index * 0.8)
		part(
			exterior,
			"AbandonedWeaponBlade",
			Vector3.new(0.6, 5, 0.12),
			base,
			Color3.fromRGB(72, 72, 65),
			Enum.Material.CorrodedMetal,
			false
		)
		part(
			exterior,
			"AbandonedWeaponGuard",
			Vector3.new(2, 0.2, 0.25),
			base * CFrame.new(0, -2.5, 0),
			oldGold,
			Enum.Material.CorrodedMetal,
			false
		)
		part(
			exterior,
			"AbandonedWeaponHilt",
			Vector3.new(0.25, 1.5, 0.25),
			base * CFrame.new(0, -3.3, 0),
			Color3.fromRGB(70, 55, 39),
			Enum.Material.Wood,
			false
		)
	end
	for _, sign in ipairs({ -1, 1 }) do
		local base = portal * CFrame.new(-2, 11, sign * 17)
		part(
			exterior,
			"RuinedBannerPole",
			Vector3.new(0.3, 15, 0.3),
			base,
			Color3.fromRGB(70, 62, 49),
			Enum.Material.Wood,
			false
		)
		part(
			exterior,
			"TatteredBanner",
			Vector3.new(0.15, 5, 3.5),
			base * CFrame.new(0, 3, sign * 1.7),
			Color3.fromRGB(82, 74, 58),
			Enum.Material.Fabric,
			false
		)
		part(
			exterior,
			"FadedBannerGlyph",
			Vector3.new(0.18, 1.7, 0.16),
			base * CFrame.new(0, 3, sign * 1.7) * CFrame.Angles(0.4, 0, 0),
			oldGold,
			Enum.Material.Fabric,
			false
		)
	end
	 
	 
	local gate = model(approach, "SwordGate")
	local closed = portal * CFrame.new(0, 0, -opening * 0.5)
	local opened = closed * CFrame.Angles(0, -math.pi * 0.5, 0)
	local function gatePiece(name, size, offset, color, material, blocks)
		local value = part(gate, name, size, opened * offset, color, material, false)
		value:SetAttribute("ClosedFrame", closed * offset)
		value:SetAttribute("OpenFrame", opened * offset)
		value:SetAttribute("BlocksEntrance", blocks == true)
		return value
	end
	for _, z in ipairs({ 0, opening }) do
		gatePiece("BrokenGateStile", Vector3.new(1.6, 16, 1.6), CFrame.new(0, 8, z), stone, Enum.Material.Slate, true)
	end
	for _, height in ipairs({ 1.4, 13.6 }) do
		gatePiece(
			"WeatheredGateRail",
			Vector3.new(1.1, 0.8, opening),
			CFrame.new(0, height, opening * 0.5),
			oldGold,
			Enum.Material.CorrodedMetal,
			true
		)
	end
	for index = 1, 17 do
		local z = index * opening / 18
		gatePiece(
			"SwordBladeBar",
			Vector3.new(0.7, 13, 1),
			CFrame.new(0, 7.5, z),
			Color3.fromRGB(111, 110, 90),
			Enum.Material.CorrodedMetal,
			true
		)
		if index % 3 == 0 then
			gatePiece(
				"FadedSwordGuard",
				Vector3.new(0.9, 0.35, 2),
				CFrame.new(0, 11.5, z),
				oldGold,
				Enum.Material.CorrodedMetal,
				false
			)
		end
	end
	local gateCollision = gatePiece(
		"SealedGateCollision",
		Vector3.new(0.8, 15, opening),
		CFrame.new(0, 7.5, opening * 0.5),
		stone,
		nil,
		true
	)
	gateCollision.Transparency = 1
	gateCollision.CastShadow = false
	for _, sign in ipairs({ -1, 1 }) do
		local height = sign < 0 and 18 or 22
		part(
			exterior,
			"BrokenGateJamb",
			Vector3.new(8, height, 6),
			portal * CFrame.new(0, height * 0.5, sign * (opening * 0.5 + 4)),
			stone,
			nil,
			true
		)
		part(
			exterior,
			"GateJambFoot",
			Vector3.new(10, 1.3, 8),
			portal * CFrame.new(0, 0.65, sign * (opening * 0.5 + 4)),
			stone,
			nil,
			true
		)
	end
	local ruins = model(approach, "BattlefieldRuins")
	for index = 1, 14 do
		local angle = index * math.pi * 2 / 14
		local x = math.cos(angle) * (halfX - 11)
		local z = math.sin(angle) * (halfZ - 10)
		if x < -halfX + 30 and math.abs(z) < 25 then
			continue
		end
		local height = 3 + (index * 3) % 9
		local base = frame * CFrame.new(x, 0, z) * CFrame.Angles(0, angle, 0.04)
		part(
			ruins,
			"RuinedButtress",
			Vector3.new(6, height, 4),
			base * CFrame.new(0, height * 0.5, 0),
			stone,
			nil,
			false
		)
		part(
			ruins,
			"FadedGoldenRelief",
			Vector3.new(6.1, 0.35, 4.1),
			base * CFrame.new(0, math.min(2.5, height - 0.5), 0),
			oldGold,
			Enum.Material.CorrodedMetal,
			false
		)
		part(
			ruins,
			"FallenRuin",
			Vector3.new(7, 1.8, 4),
			base * CFrame.new(4, 0.9, 4) * CFrame.Angles(0, 0.45, 0.13),
			stone,
			nil,
			false
		)
	end
	for index = 1, 24 do
		local side = index % 4
		local x, z
		if side < 2 then
			x = -halfX + index / 25 * floor.Size.X
			z = side == 0 and -halfZ + 1 or halfZ - 1
		else
			x = side == 2 and -halfX + 1 or halfX - 1
			z = -halfZ + index / 25 * floor.Size.Z
		end
		if x < -halfX + 3 and math.abs(z) < 19 then
			continue
		end
		local base = frame * CFrame.new(x, 0, z)
		local turn = (index % 2 == 0) and 0.24 or -0.27
		for section = 0, 2 do
			part(
				ruins,
				"ClimbingVine",
				Vector3.new(0.3, 5, 0.4),
				base * CFrame.new(section * 0.65, 9 + section * 4, 0) * CFrame.Angles(0, 0, turn),
				moss,
				Enum.Material.Grass,
				false
			)
		end
	end
	local star = model(approach, "PolyStar")
	local bossCircle = arena.SpawnCircles.BossCircle
	local position =
		Vector3.new(bossCircle:GetAttribute("SpawnX"), frame.Position.Y + 3.5, bossCircle:GetAttribute("SpawnZ"))
	local starFrame = CFrame.lookAt(position, position - frame.RightVector)
	local core =
		part(star, "Core", Vector3.new(1, 1, 1), starFrame, Color3.fromRGB(255, 238, 150), Enum.Material.Neon, false)
	core.Transparency = 1
	local function triangle(a, b, c)
		local ab, ac, bc = b - a, c - a, c - b
		if ab:Dot(ab) > ac:Dot(ac) and ab:Dot(ab) > bc:Dot(bc) then
			a, c = c, a
		elseif ac:Dot(ac) > bc:Dot(bc) and ac:Dot(ac) > ab:Dot(ab) then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		local right = ac:Cross(ab).Unit
		local up = bc:Cross(right).Unit
		local back = bc.Unit
		local height = math.abs(ab:Dot(up))
		for _, data in ipairs({
			{ (a + b) * 0.5, right, back, math.abs(ab:Dot(back)) },
			{ (a + c) * 0.5, -right, -back, math.abs(ac:Dot(back)) },
		}) do
			local wedge = part(
				star,
				"FivePointStarFace",
				Vector3.new(0.24, height, data[4]),
				CFrame.fromMatrix(data[1], data[2], up, data[3]),
				Color3.fromRGB(255, 214, 69),
				Enum.Material.Neon,
				false,
				"WedgePart"
			)
			wedge.CastShadow = false
			wedge.Transparency = 0.04
			wedge:SetAttribute("PolyStarVisual", true)
			wedge:SetAttribute("RestingTransparency", wedge.Transparency)
		end
	end
	local points = {}
	for index = 0, 9 do
		local angle = math.pi * 0.5 + index * math.pi / 5
		local radius = index % 2 == 0 and 3.1 or 1.35
		points[index + 1] =
			starFrame:PointToWorldSpace(Vector3.new(math.cos(angle) * radius, math.sin(angle) * radius, 0))
	end
	for index = 1, 10 do
		triangle(starFrame.Position, points[index], points[index % 10 + 1])
	end
	local light = Instance.new("PointLight")
	light.Name = "PolyStarGlow"
	light.Color = Color3.fromRGB(255, 214, 69)
	light.Brightness = 0.65
	light.Range = 9
	light.Shadows = false
	light:SetAttribute("RestingEnabled", true)
	light.Parent = core
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "WaitingStarSparkles"
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(Color3.fromRGB(255, 235, 155), Color3.fromRGB(230, 186, 77))
	sparkles.Rate = 5
	sparkles.Lifetime = NumberRange.new(1.1, 1.8)
	sparkles.Speed = NumberRange.new(0.25, 0.8)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.LightEmission = 0.65
	sparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.12),
		NumberSequenceKeypoint.new(0.25, 0.19),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparkles:SetAttribute("RestingEnabled", true)
	sparkles.Parent = core
	star.PrimaryPart = core
	star:PivotTo(starFrame)
	star:SetAttribute("RestFrame", starFrame)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BeginBattle"
	prompt.ActionText = "Begin encounter"
	prompt.ObjectText = "PolyStar"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = Config.PolyStarHoldDuration or 2
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = true
	prompt.Parent = core
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "ExteriorSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(7, 0.2, 7)
	spawn.CFrame = frame * CFrame.new(-halfX - distance + 9, 0.2, 0)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.CanTouch = false
	spawn.CanQuery = false
	spawn.Parent = approach
	arena.GreyCircleSpawn.Enabled = false
	arena:SetAttribute("RuinedApproachVersion", VERSION)
	arena:SetAttribute("EntranceSealed", false)
	cached = read(arena)
	startStarMotion(cached)
	if rebind then
		local callback = activation
		task.defer(function()
			if callback then
				api.BindActivation(callback)
			end
		end)
	end
	return cached
end
function api.Build()
	while buildInProgress do
		task.wait()
	end
	buildInProgress = true
	yieldDuringBuild = true
	buildPartCount = 0
	local ok, result = xpcall(buildInternal, debug.traceback)
	yieldDuringBuild = false
	buildInProgress = false
	if not ok then
		error(result, 0)
	end
	return result
end
api.Ensure = api.Build
function api.Contains(point, margin)
	local data = api.Build()
	local floor = data.Floor
	local localPoint = floor.CFrame:PointToObjectSpace(point)
	margin = margin or 0
	return math.abs(localPoint.X) < floor.Size.X * 0.5 - margin and math.abs(localPoint.Z) < floor.Size.Z * 0.5 - margin
end
function api.SpawnFrame(character, battlefield)
	local data = api.Build()
	local h = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local leg = character and character:FindFirstChild("Right Leg")
	local height = (root and root.Size.Y * 0.5 or 1) + (h and h.HipHeight or 0) + (leg and leg.Size.Y or 2) + 0.35
	local floor = data.Floor
	local groundY = (floor.CFrame * CFrame.new(0, floor.Size.Y * 0.5, 0)).Y
	local position, target
	if battlefield then
		local circles = data.Arena.SpawnCircles
		position = Vector3.new(
			circles.PlayerCircle:GetAttribute("SpawnX"),
			groundY + height,
			circles.PlayerCircle:GetAttribute("SpawnZ")
		)
		target = Vector3.new(
			circles.BossCircle:GetAttribute("SpawnX"),
			position.Y,
			circles.BossCircle:GetAttribute("SpawnZ")
		)
	else
		position = Vector3.new(data.ExteriorSpawn.Position.X, groundY + height, data.ExteriorSpawn.Position.Z)
		target = Vector3.new(data.PolyStar.Core.Position.X, position.Y, data.PolyStar.Core.Position.Z)
	end
	return CFrame.lookAt(position, target)
end
function api.SetSealed(sealed, instant)
	local data = api.Build()
	cancelTweens()
	data.Arena:SetAttribute("EntranceSealed", sealed == true)
	for _, piece in ipairs(data.Gate:GetChildren()) do
		if piece:IsA("BasePart") then
			piece.CanCollide = sealed == true and piece:GetAttribute("BlocksEntrance") == true
			piece.CanQuery = piece.CanCollide
			local frame = piece:GetAttribute(sealed and "ClosedFrame" or "OpenFrame")
			if instant then
				piece.CFrame = frame
			else
				local tween = Tween:Create(
					piece,
					TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut),
					{ CFrame = frame }
				)
				table.insert(tweens, tween)
				tween:Play()
			end
		end
	end
end
local function validHold(player, character)
	local data = cached
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local h = character and character:FindFirstChildOfClass("Humanoid")
	local available = data
		and data.Prompt.Enabled
		and player.Parent == Players
		and player.Character == character
		and root
		and h
		and h.Health > 0
		and not player:GetAttribute("PermanentlyDefeated")
		and (root.Position - data.PolyStar.Core.Position).Magnitude <= data.Prompt.MaxActivationDistance + 1
		and api.Contains(root.Position, 2)
	if not available then
		return false
	end
	sight.FilterDescendantsInstances = { character, data.PolyStar }
	return workspace:Raycast(root.Position, data.PolyStar.Core.Position - root.Position, sight) == nil
end
local function stopHoldStep()
	if holdStep then
		holdStep:Disconnect()
		holdStep = nil
	end
end
local function sampleHolds()
	for player, record in pairs(holds) do
		if not validHold(player, record.Character) or os.clock() - record.StartedAt > 15 then
			holds[player] = nil
		end
	end
	if not next(holds) then
		stopHoldStep()
	end
end
local function clearHolds()
	table.clear(holds)
	stopHoldStep()
end
function api.SetActive(active)
	local data = api.Build()
	clearHolds()
	local wasConsumed = data.PolyStar:GetAttribute("Consumed") == true
	data.PolyStar:SetAttribute("Consumed", active == true)
	if active then
		stopStarMotion()
		local sparks = data.PolyStar.Core:FindFirstChild("WaitingStarSparkles")
		if sparks and not wasConsumed then
			sparks:Emit(18)
		end
	else
		data.PolyStar:PivotTo(data.PolyStar:GetAttribute("RestFrame"))
		startStarMotion(data)
	end
	for _, object in ipairs(data.PolyStar:GetDescendants()) do
		if object:IsA("BasePart") and object:GetAttribute("PolyStarVisual") then
			object.Transparency = active and 1 or object:GetAttribute("RestingTransparency") or 0
		elseif object:IsA("Light") or object:IsA("ParticleEmitter") or object:IsA("Beam") or object:IsA("Trail") then
			local resting = object:GetAttribute("RestingEnabled")
			if resting == nil then
				resting = object.Enabled
				object:SetAttribute("RestingEnabled", resting)
			end
			object.Enabled = not active and resting or false
		end
	end
	data.Prompt.Enabled = not active
	data.ExteriorSpawn.Enabled = not active
	data.BattlefieldSpawn.Enabled = active == true
	for _, player in ipairs(Players:GetPlayers()) do
		player.RespawnLocation = active and data.BattlefieldSpawn or data.ExteriorSpawn
	end
end
 -- start the encounter for `player` the way the PolyStar prompt does (the Enraged Gate uses it); false if it can't
function api.Activate(player)
	return activation ~= nil and activation(player) == true
end
function api.BindActivation(callback)
	api.Build()
	activation = callback
	startStarMotion(cached)
	if #connections > 0 then
		return
	end
	local prompt = cached.Prompt
	table.insert(
		connections,
		prompt.PromptButtonHoldBegan:Connect(function(player)
			local character = player.Character
			if not validHold(player, character) or workspace:GetAttribute("EncounterStarted") == true then
				return
			end
			holds[player] = { Character = character, StartedAt = os.clock() }
			if not holdStep then
				local elapsed = 0
				holdStep = Run.Heartbeat:Connect(function(dt)
					elapsed += dt
					if elapsed >= 0.1 then
						elapsed = 0
						sampleHolds()
					end
				end)
			end
		end)
	)
	table.insert(
		connections,
		prompt.PromptButtonHoldEnded:Connect(function(player)
			local record = holds[player]
			if not record then
				return
			end
			 
			 
			 
			task.delay(0.15, function()
				if holds[player] == record and not record.PendingTrigger then
					holds[player] = nil
					sampleHolds()
				end
			end)
		end)
	)
	table.insert(
		connections,
		prompt.Triggered:Connect(function(player)
			local record = holds[player]
			if
				not record
				or workspace:GetAttribute("EncounterStarted") == true
				or not validHold(player, record.Character)
				or record.PendingTrigger
			then
				return
			end
			local requiredDuration = math.max(0.25, prompt.HoldDuration - 0.08)
			local remaining = requiredDuration - (os.clock() - record.StartedAt)
			 
			 
			if remaining > 0.15 then
				return
			end
			local function complete()
				if holds[player] ~= record then
					return
				end
				record.PendingTrigger = false
				local allowed = workspace:GetAttribute("EncounterStarted") ~= true
					and validHold(player, record.Character)
					and os.clock() - record.StartedAt >= requiredDuration
				holds[player] = nil
				if allowed and activation and activation(player) == true then
					api.SetActive(true)
				end
				sampleHolds()
			end
			if remaining > 0 then
				record.PendingTrigger = true
				task.delay(remaining, complete)
			else
				complete()
			end
		end)
	)
	table.insert(
		connections,
		Players.PlayerRemoving:Connect(function(player)
			holds[player] = nil
			sampleHolds()
		end)
	)
end
function api.Reset()
	api.SetActive(false)
	api.SetSealed(false)
end
function api.Destroy()
	activation = nil
	clearHolds()
	cancelTweens()
	stopStarMotion()
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
end
return api
