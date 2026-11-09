local Fov=require(game.ReplicatedStorage.BossShared.Presentation.CameraFov)
if not game:GetService("RunService"):IsRunning() or not game:GetService("RunService"):IsClient() then return {} end
if not game:GetService("RunService"):IsClient() then return {} end
local Reset=require(game.ReplicatedStorage.BossShared.Presentation.CinematicReset)
local Quality=require(game.ReplicatedStorage.BossShared.Presentation.VisualQuality)



local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")

local BeamMath = require(game.ReplicatedStorage.BossShared.Presentation.HyperElasticBeam)

local VFX = {}

 
local SOUNDS = { Charge = "", Lock = "", Fire = "", Ring = "", TallRing = "", Impact = "" }

 
local CAMERA_FOV = true

local TAU = math.pi * 2

 
local FALLBACK = {
	White = Color3.fromRGB(255, 247, 228),
	Yellow = Color3.fromRGB(246, 214, 134),
	Gold = Color3.fromRGB(218, 156, 62),
	Amber = Color3.fromRGB(176, 104, 40),
	Soot = Color3.fromRGB(44, 34, 28),
	Dust = Color3.fromRGB(168, 142, 110),
}

local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"

local MAT = Enum.Material

local RING_SEGMENTS = 60
local UNIT = table.create(RING_SEGMENTS)
for i = 1, RING_SEGMENTS do
	local a = (i - 1) / RING_SEGMENTS * TAU
	UNIT[i] = Vector3.new(math.cos(a), 0, math.sin(a))
end

 
local LAYERS = {
	{ Color = "Amber", Material = MAT.ForceField, Transparency = 0.55, Scale = 1.00, Wobble = 0.00, Freq = 0 },
	{ Color = "Gold", Material = MAT.Neon, Transparency = 0.80, Scale = 0.80, Wobble = 0.03, Freq = 17 },
	{ Color = "Yellow", Material = MAT.Neon, Transparency = 0.45, Scale = 0.56, Wobble = 0.06, Freq = 26 },
	{ Color = "White", Material = MAT.Neon, Transparency = 0.05, Scale = 0.30, Wobble = 0.08, Freq = 34 },
}

local PULSE_COUNT = 10
local HELIX_SEGS = 44
local HELIX_TWIST = 0.04  
local STREAK_COUNT = 28
local ARC_SEGS = 7
local MAX_DEBRIS = 70
local RELEASE_TIME = 0.7  

local effects = {}
local activeCount = 0
local shakePending = 0
local bound = false
local blockedTokens = {}

 
 
 

local function clamp01(x)
	return math.clamp(x, 0, 1)
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local smooth = BeamMath.Smooth

local function easeOutCubic(x)
	x = clamp01(x)
	return 1 - (1 - x) ^ 3
end

local function easeOutBack(x)
	x = clamp01(x) - 1
	return 1 + 2.4 * x * x * x + 1.4 * x * x
end

local function tweenInfo(duration, style)
	return TweenInfo.new(duration, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

local function nseq(list)
	local keys = {}
	for i, k in ipairs(list) do
		keys[i] = NumberSequenceKeypoint.new(k[1], k[2])
	end
	return NumberSequence.new(keys)
end

local function cseq(list)
	local keys = {}
	for i, k in ipairs(list) do
		keys[i] = ColorSequenceKeypoint.new(k[1], k[2])
	end
	return ColorSequence.new(keys)
end

local function newPart(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = MAT.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = Vector3.one
	for key, value in pairs(props) do
		p[key] = value
	end
	p.Parent = parent
	return p
end

local function newEmitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX_SPARK
	e.LightEmission = 0
	e.Rate = 0
	e.Lifetime = NumberRange.new(0.5, 1)
	e.Speed = NumberRange.new(0)
	for key, value in pairs(props) do
		e[key] = value
	end
	e.Rate=Quality.Rate(e.Rate)
	e.Parent = parent
	return e
end

local function newLight(parent, color, brightness, range)
	local l = Instance.new("PointLight")
	l.Enabled=Quality.Get().Lights
 l.Shadows=false
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Parent = parent
	return l
end

local function bulk(parts, cfs)
	if #parts > 0 then
		workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function randomUnit(rng)
	local v = Vector3.new(rng:NextNumber(-1, 1), rng:NextNumber(-1, 1), rng:NextNumber(-1, 1))
	if v.Magnitude < 0.05 then
		return Vector3.yAxis
	end
	return v.Unit
end

local function addShake(position, amount)
 if not Reset.ViewAllowed() then return end
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local d = (cam.CFrame.Position - position).Magnitude
	shakePending = math.max(shakePending, amount / (1 + d / 120))
end

local function playSound(name, position, volume)
	local id = SOUNDS[name]
	if not id or id == "" then
		return
	end
	local holder = newPart(workspace, { Transparency = 1, Position = position })
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 1
	s.RollOffMinDistance = 60
	s.RollOffMaxDistance = 700
	s.Parent = holder
	s:Play()
	Debris:AddItem(holder, 10)
end

 
local function burst(position, color, startSize, endSize, duration, coreColor)
	local shell = newPart(workspace, {
		Shape = Enum.PartType.Ball,
		Material = MAT.ForceField,
		Color = color,
		Transparency = 0.35,
		Size = Vector3.one * startSize,
		Position = position,
	})
	TweenService:Create(shell, tweenInfo(duration), { Size = Vector3.one * endSize, Transparency = 1 }):Play()
	Debris:AddItem(shell, duration + 0.1)
	if coreColor then
		local core = newPart(workspace, {
			Shape = Enum.PartType.Ball,
			Material = MAT.Neon,
			Color = coreColor,
			Transparency = 0.2,
			Size = Vector3.one * startSize * 0.6,
			Position = position,
		})
		TweenService:Create(core, tweenInfo(duration * 0.7), { Size = Vector3.one * endSize * 0.45, Transparency = 1 })
			:Play()
		Debris:AddItem(core, duration + 0.1)
	end
end

 
local function shockDisc(position, color, endDiameter, duration, startTransparency)
	local p = newPart(workspace, {
		Shape = Enum.PartType.Cylinder,
		Material = MAT.ForceField,
		Color = color,
		Transparency = startTransparency or 0.4,
		Size = Vector3.new(0.6, 2, 2),
		CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
	})
	TweenService:Create(p, tweenInfo(duration), { Size = Vector3.new(0.6, endDiameter, endDiameter), Transparency = 1 })
		:Play()
	Debris:AddItem(p, duration + 0.1)
end

 
local function sparkBurst(position, color, count, speedMin, speedMax, parent)
	local holder = newPart(parent or workspace, { Transparency = 1, Position = position })
	local e = newEmitter(holder, {
		LightEmission = 0.5,
		Color = ColorSequence.new(color, FALLBACK.Gold),
		Size = nseq({ { 0, 0.2 }, { 0.2, 1.3 }, { 1, 0 } }),
		Transparency = nseq({ { 0, 0 }, { 0.7, 0.3 }, { 1, 1 } }),
		Lifetime = NumberRange.new(0.5, 1.1),
		Speed = NumberRange.new(speedMin, speedMax),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -40, 0),
		Drag = 1,
	})
	e:Emit(count)
	Debris:AddItem(holder, 2)
end

local function screenFlash(origin, strength, color)
 if not Reset.ViewAllowed() then return end
	local gui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local cam = workspace.CurrentCamera
	if not gui or not cam then
		return
	end
	local d = (cam.CFrame.Position - origin).Magnitude
	local s = strength / (1 + d / 250)
	local sg = Instance.new("ScreenGui")
	sg.Name = "HyperElasticFlash"
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 50
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BorderSizePixel = 0
	f.BackgroundColor3 = color or FALLBACK.White
	f.BackgroundTransparency = 1 - s
	f.Parent = sg
	sg.Parent = gui
	TweenService:Create(f, tweenInfo(0.55), { BackgroundTransparency = 1 }):Play()
	Debris:AddItem(sg, 0.8)
end

 
 
 

local fov = { refs = 0 }

function fov.acquire()
 if not Reset.ViewAllowed() then return end
	if not CAMERA_FOV then
		return
	end
	fov.refs = fov.refs + 1
	if fov.refs == 1 then
		local cam = workspace.CurrentCamera
		fov.base = Fov.Base(cam)
	end
end

local fovValue=Instance.new("NumberValue")
fovValue.Changed:Connect(function(value)Fov.Set(fov,value)end)

function fov.to(offset, duration, style)
 if not Reset.ViewAllowed() then return end
	if not CAMERA_FOV or fov.refs <= 0 or not fov.base then
		return
	end
	local cam = workspace.CurrentCamera
	if cam then
		if fov.tween then fov.tween:Cancel() end
		fov.tween=TweenService:Create(fovValue, tweenInfo(duration, style), { Value = offset })
		fov.tween:Play()
	end
end

function fov.release()
	if not CAMERA_FOV or fov.refs <= 0 then
		return
	end
	fov.refs = fov.refs - 1
	if fov.refs == 0 then
		local cam = workspace.CurrentCamera
		if cam and fov.base then
			if fov.tween then fov.tween:Cancel() end
			fov.tween=TweenService:Create(fovValue, tweenInfo(0.7), { Value = 0 })
			fov.tween:Play()
		end
		fov.base = nil
	end
end

 
 
 

local post = { refs = 0 }

local GRADES = {
	charge = { Bloom = 0.4, Brightness = -0.05, Contrast = 0.08, Saturation = -0.08, Tint = Color3.fromRGB(255, 238, 222) },
	fire = { Bloom = 0.85, Brightness = 0.02, Contrast = 0.1, Saturation = -0.04, Tint = Color3.fromRGB(255, 244, 226) },
	idle = { Bloom = 0.25, Brightness = 0, Contrast = 0.03, Saturation = 0, Tint = Color3.fromRGB(255, 250, 240) },
}

function post.set(mode, duration)
 if not Reset.ViewAllowed() then return end
	local g = GRADES[mode]
	if not g or not post.bloom then
		return
	end
	TweenService:Create(post.bloom, tweenInfo(duration), { Intensity = g.Bloom }):Play()
	TweenService:Create(post.grade, tweenInfo(duration), {
		Brightness = g.Brightness,
		Contrast = g.Contrast,
		Saturation = g.Saturation,
		TintColor = g.Tint,
	}):Play()
end

function post.acquire(mode)
 if not Reset.ViewAllowed() then return end
	post.refs = post.refs + 1
	if post.refs > 1 then
		post.set(mode, 0.4)
		return
	end
	local bloom = Instance.new("BloomEffect")
	bloom.Enabled=Quality.Get().Post
	bloom.Name = "HyperElasticBloom"
	bloom.Intensity = 0
	bloom.Size = 36
	bloom.Threshold = 0.92
	bloom.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Enabled=Quality.Get().Post
	grade.Name = "HyperElasticGrade"
	grade.Parent = Lighting
	post.bloom, post.grade = bloom, grade
	post.set(mode, 0.6)
end

function post.release()
	post.refs = math.max(0, post.refs - 1)
	if post.refs > 0 then
		return
	end
	local bloom, grade = post.bloom, post.grade
	post.bloom, post.grade = nil, nil
	if not bloom then
		return
	end
	TweenService:Create(bloom, tweenInfo(0.8), { Intensity = 0 }):Play()
	TweenService:Create(grade, tweenInfo(0.8), {
		Brightness = 0,
		TintColor = Color3.new(1, 1, 1),
		Contrast = 0,
		Saturation = 0,
	}):Play()
	Debris:AddItem(bloom, 1)
	Debris:AddItem(grade, 1)
end

 
 
 

 
local function newSegRing(parent, n, props)
 n=Quality.Count(n,10)
	local ring = { N = n, Parts = table.create(n), CFs = table.create(n) }
	for i = 1, n do
		ring.Parts[i] = newPart(parent, props)
	end
	return ring
end

local function placeSegRing(ring, frame, radius, thick, depth, fill, spin, transparency)
	local n = ring.N
	radius = math.max(radius, 0.2)
	local chord = 2 * radius * math.sin(math.pi / n) * fill + 0.2
	local size = Vector3.new(chord, thick, depth)
	for i = 1, n do
		local a = spin + (i - 1) * TAU / n
		local part = ring.Parts[i]
		part.Size = size
		if transparency then
			part.Transparency = transparency
		end
		ring.CFs[i] = frame * CFrame.new(math.cos(a) * radius, math.sin(a) * radius, 0) * CFrame.Angles(0, 0, a + math.pi / 2)
	end
	bulk(ring.Parts, ring.CFs)
end

local function newArc(parent, color, thickness)
 local segments=Quality.Count(ARC_SEGS,3)
	local arc = { Parts = table.create(segments), CFs = table.create(segments), Thickness = thickness, Next = 0, Visible = false }
	for i = 1, segments do
		arc.Parts[i] = newPart(parent, {
			Material = MAT.Neon,
			Color = color,
			Transparency = 1,
			Size = Vector3.new(thickness, thickness, 1),
		})
	end
	return arc
end

local function hideArc(arc)
	if arc.Visible then
		arc.Visible = false
		for _, part in ipairs(arc.Parts) do
			part.Transparency = 1
		end
	end
end

local function setArc(arc, a, b, jitter, transparency, rng)
	local d = b - a
	local len = d.Magnitude
	if len < 0.5 then
		hideArc(arc)
		return
	end
	arc.Visible = true
	local dir = d / len
	local side = dir:Cross(Vector3.yAxis)
	if side.Magnitude < 0.01 then
		side = Vector3.xAxis
	end
	side = side.Unit
	local up = dir:Cross(side)
	local points = { a }
 local segments=#arc.Parts
	for i = 1, segments - 1 do
		local f = i / segments
		local amp = jitter * math.sin(f * math.pi)
		points[i + 1] = a + d * f + side * rng:NextNumber(-amp, amp) + up * rng:NextNumber(-amp, amp)
	end
	points[segments + 1] = b
	for i = 1, segments do
		local p, q = points[i], points[i + 1]
		local seg = q - p
		local part = arc.Parts[i]
		part.Size = Vector3.new(arc.Thickness, arc.Thickness, math.max(seg.Magnitude, 0.1) + 0.3)
		part.Transparency = transparency
		arc.CFs[i] = CFrame.lookAt((p + q) * 0.5, q)
	end
	bulk(arc.Parts, arc.CFs)
end

 
 
 

local Effect = {}
Effect.__index = Effect

local function subFolder(parent, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function Effect:Muzzle()
	return self.Pivot + BeamMath.Dir(self.Heading) * self.P.MuzzleOffset
end

 
function Effect:AddDebris(part, pos, vel, ang, life)
	local list = self.Debris
	if #list >= MAX_DEBRIS then
		local oldest = table.remove(list, 1)
		oldest.Part:Destroy()
	end
	part.Parent = self.DebrisFolder
	table.insert(list, {
		Part = part,
		Pos = pos,
		Vel = vel,
		Ang = ang,
		Orient = CFrame.fromAxisAngle(randomUnit(self.Rng), self.Rng:NextNumber(0, TAU)),
		Age = 0,
		Life = life or self.Rng:NextNumber(2.6, 3.6),
		Half = math.max(part.Size.Y * 0.5, 0.6),
	})
end

 -- the floor's own colour and material (terrain or a part), so the rocks the beam tears up and
 -- the dust it raises match whatever ground the arena has
function Effect:GroundLook()
	if not self.GroundColor then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		local arena = workspace:FindFirstChild("GoldenGrasslandArena")
		params.FilterDescendantsInstances = { workspace.Terrain, arena and arena:FindFirstChild("Grassland"), arena and arena:FindFirstChild("ApproachFloor") }
		local hit = workspace:Raycast(self.Floor + Vector3.yAxis * 12, -Vector3.yAxis * 60, params)
		if hit and hit.Instance == workspace.Terrain then
			self.GroundColor, self.GroundMaterial = workspace.Terrain:GetMaterialColor(hit.Material), hit.Material
		elseif hit then
			self.GroundColor, self.GroundMaterial = hit.Instance.Color, hit.Instance.Material
		else
			self.GroundColor, self.GroundMaterial = self.C.Dust, MAT.Slate
		end
	end
	return self.GroundColor, self.GroundMaterial
end

function Effect:NewRock(size)
	local rng = self.Rng
	local color, material = self:GroundLook()
	return newPart(self.DebrisFolder, {
		Size = Vector3.new(size, size * rng:NextNumber(0.6, 1), size * rng:NextNumber(0.7, 1.1)),
		Material = material,
		Color = color:Lerp(Color3.new(0, 0, 0), rng:NextNumber(0, 0.25)),
	})
end

function Effect:ThrowRock(pos, vel, size)
	local rock = self:NewRock(size)
	rock.Position = pos
	self:AddDebris(rock, pos, vel, randomUnit(self.Rng) * self.Rng:NextNumber(2, 7))
end

function Effect:BuildCharge()
	local P, C, rng = self.P, self.C, self.Rng
	local W = P.BeamWidth
	local folder = subFolder(self.Folder, "Charge")
	self.ChargeFolder = folder
	local ch = {}
	self.Ch = ch
	local M = self:Muzzle()
	local floorY = self.Floor.Y
	local F = Vector3.new(self.Pivot.X, floorY + 0.12, self.Pivot.Z)

	 
	ch.Core = newPart(folder, { Shape = Enum.PartType.Ball, Material = MAT.Neon, Color = C.White, Position = M })
	ch.Shell = newPart(folder, {
		Shape = Enum.PartType.Ball, Material = MAT.ForceField, Color = C.Gold, Transparency = 0.5, Position = M,
	})
	ch.Aura = newPart(folder, {
		Shape = Enum.PartType.Ball, Material = MAT.Neon, Color = C.Amber, Transparency = 0.9, Position = M,
	})
	ch.Light = newLight(ch.Core, C.Yellow, 1, 16)

	 
	ch.GlowField = newPart(folder, { Transparency = 1, Position = M })
	ch.Glow = newEmitter(ch.GlowField, {
		LightEmission = 0.6,
		Color = ColorSequence.new(C.Yellow, C.Gold),
		Size = nseq({ { 0, W * 0.9 }, { 1, W * 1.1 } }),
		Transparency = nseq({ { 0, 1 }, { 0.3, 0.84 }, { 1, 1 } }),
		Lifetime = NumberRange.new(0.7, 0.9),
		Rate = 3,
		LockedToPart = true,
		Rotation = NumberRange.new(0, 360),
	})

	 
	ch.MoteField = newPart(folder, { Transparency = 1, Size = Vector3.one * W * 0.9, Position = M })
	ch.Motes = newEmitter(ch.MoteField, {
		LightEmission = 0.7,
		Color = ColorSequence.new(C.White, C.Yellow),
		Size = nseq({ { 0, 0 }, { 0.2, 1.5 }, { 1, 0.2 } }),
		Transparency = nseq({ { 0, 1 }, { 0.15, 0.15 }, { 1, 1 } }),
		Lifetime = NumberRange.new(0.85, 0.95),
		Speed = NumberRange.new(W * 0.5, W * 0.6),
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
	})

	 
	ch.LockSparks = newEmitter(ch.GlowField, {
		LightEmission = 0.6,
		Color = ColorSequence.new(C.White, C.Gold),
		Size = nseq({ { 0, 0.3 }, { 0.2, 2 }, { 1, 0 } }),
		Transparency = nseq({ { 0, 0 }, { 0.7, 0.3 }, { 1, 1 } }),
		Lifetime = NumberRange.new(0.4, 0.8),
		Speed = NumberRange.new(60, 140),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 2,
	})

	 
	ch.Gyros = {}
	for i = 1, 3 do
		ch.Gyros[i] = {
			Ring = newSegRing(folder, 28, {
				Material = MAT.Metal, Color = i == 2 and C.Yellow or C.Gold, Transparency = 1,
			}),
			Radius = W * (0.62 - 0.1 * (i - 1)),
			Thick = 1.9 - 0.3 * i,
			Tilt = Vector3.new(rng:NextNumber(0, TAU), rng:NextNumber(0, TAU), rng:NextNumber(0, TAU)),
			Rate = Vector3.new(rng:NextNumber(0.6, 1.2), rng:NextNumber(0.5, 1.1), rng:NextNumber(0.2, 0.6))
				* (i % 2 == 0 and -1 or 1),
			Spin = (i % 2 == 0 and -1 or 1) * (0.8 + 0.3 * i),
		}
	end

	 
	ch.Barrel = {}
	for k = 1, 4 do
		ch.Barrel[k] = {
			Ring = newSegRing(folder, 24, { Material = MAT.Metal, Color = C.Yellow, Transparency = 1 }),
			Dist = W * (0.55 + 0.32 * k),
			Radius = W * (0.52 - 0.075 * k),
			Start = 0.22 + 0.1 * k,
			Spin = (k % 2 == 0 and -1 or 1) * (0.5 + 0.1 * k),
		}
	end

	 
	ch.Rocks = {}
	for i = 1, Quality.Count(22,6) do
		local size = rng:NextNumber(1.8, 5.5)
		if i % 7 == 0 then
			size = rng:NextNumber(6, 9)
		end
		local rock = self:NewRock(size)
		local r0 = rng:NextNumber(14, 66)
		local ang = rng:NextNumber(0, TAU)
		rock.Position = Vector3.new(F.X + math.cos(ang) * r0, floorY + size * 0.4, F.Z + math.sin(ang) * r0)
		ch.Rocks[i] = {
			Part = rock, Size = size, Ang = ang, R0 = r0, Rise = rng:NextNumber(10, 38), Start = rng:NextNumber(0, 0.35),
			Spin = rng:NextNumber(0.3, 1.1) * (rng:NextInteger(0, 1) == 0 and -1 or 1),
			Axis = randomUnit(rng), Tumble = rng:NextNumber(0.4, 1.6), Pos = rock.Position,
		}
	end

	 
	ch.Cracks = {}
	for i = 1, 8 do
		local ang = (i - 1) / 8 * TAU + rng:NextNumber(-0.25, 0.25)
		local pt = F
		for j = 1, 4 do
			ang = ang + rng:NextNumber(-0.35, 0.35)
			local len = rng:NextNumber(9, 15) * (1 - 0.08 * j)
			local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
			local thick = 2.8 * (1 - 0.18 * (j - 1))
			table.insert(ch.Cracks, {
				P0 = pt, Dir = dir, Len = len, Thick = thick, Start = (j - 1) / 4 * 0.7 + rng:NextNumber(0, 0.06),
				Done = false,
				Dark = newPart(self.GroundFolder, {
					Color = C.Soot, Transparency = 0.1, Size = Vector3.new(0.05, 0.15, thick), Position = pt,
				}),
				Seam = newPart(self.GroundFolder, {
					Material = MAT.Neon, Color = C.Amber, Transparency = 1, Size = Vector3.new(0.05, 0.1, 0.4),
					Position = pt,
				}),
			})
			pt = pt + dir * len
		end
	end

	 
	ch.Arcs = {}
	for i = 1, 4 do
		ch.Arcs[i] = newArc(folder, C.Yellow, 0.7)
	end

	 
	ch.DustField = newPart(self.GroundFolder, {
		Transparency = 1, Size = Vector3.new(70, 1, 70), Position = Vector3.new(F.X, floorY + 0.6, F.Z),
	})
	ch.Dust = newEmitter(ch.DustField, {
		Texture = TEX_SMOKE,
		Color = ColorSequence.new((self:GroundLook()), (self:GroundLook()):Lerp(C.Soot, 0.4)),
		Size = nseq({ { 0, 6 }, { 1, 26 } }),
		Transparency = nseq({ { 0, 0.72 }, { 0.5, 0.8 }, { 1, 1 } }),
		Lifetime = NumberRange.new(1.8, 2.8),
		Speed = NumberRange.new(6, 16),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(75, 75),
		Acceleration = Vector3.new(0, 1.5, 0),
		Drag = 1,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-25, 25),
		LightInfluence = 1,
		Rate = 4,
	})

	addShake(M, 0.9)
	playSound("Charge", M, 1)
end

function Effect:OnLock(now)
	local ch, C, P = self.Ch, self.C, self.P
	if not ch then
		return
	end
	local W = P.BeamWidth
	local M = self:Muzzle()
	ch.LockSparks:Emit(70)
	burst(M, C.Yellow, W * 0.3, W * 0.9, 0.35, C.White)
	screenFlash(M, 0.12, C.Yellow)
	addShake(M, 1.3)
	fov.to(-1, 0.12)
	playSound("Lock", M, 1.2)
end

function Effect:UpdateCharge(now, dt)
	local P, C, ch, rng = self.P, self.C, self.Ch, self.Rng
	local W = P.BeamWidth
	local t = now - self.ChargeStart
	local p = clamp01(t / P.Charge)
	local e = p * p
	local lockT = P.Charge - P.AimLockWindow
	local locked = t >= lockT
	if locked and not self.LockFired then
		self.LockFired = true
		self:OnLock(now)
	end
	local lockAge = locked and (t - lockT) or 0

	local dir = BeamMath.Dir(self.Heading)
	local M = self.Pivot + dir * P.MuzzleOffset
	local floorY = self.Floor.Y
	local F = Vector3.new(self.Pivot.X, floorY + 0.12, self.Pivot.Z)

	 
	local jitter = 1 + 0.05 * math.sin(now * 43) + (locked and 0.03 * math.sin(now * 91) or 0)
	local implode = 1 - 0.55 * smooth((p - 0.93) / 0.07)
	local orbD = lerp(2, W * 0.5, smooth(p / 0.95) ^ 1.5) * jitter * implode
	ch.Core.Size = Vector3.one * orbD * 0.55
	ch.Core.Position = M
	ch.Shell.Size = Vector3.one * orbD
	ch.Shell.Position = M
	ch.Shell.Transparency = lerp(0.6, 0.35, e) + 0.04 * math.sin(now * 17)
	ch.Aura.Size = Vector3.one * orbD * 1.55
	ch.Aura.Position = M
	ch.Aura.Transparency = lerp(0.93, 0.84, e)
	ch.GlowField.Position = M
	ch.MoteField.Position = M
	ch.Light.Brightness = lerp(1, 5, e)
	ch.Light.Range = lerp(16, 60, e)
	ch.Glow.Rate = Quality.Rate(lerp(3, 9, e))
	ch.Motes.Rate = Quality.Rate(lerp(15, 240, e) * (1 - 0.7 * smooth((p - 0.96) / 0.04)))
	ch.Dust.Rate = Quality.Rate(lerp(4, 28, p))

	 
	local spinUp = 1 + 2.4 * e
	for i, g in ipairs(ch.Gyros) do
		local appear = smooth((p - 0.08 * i) / 0.2)
		local frame = CFrame.new(M) * CFrame.fromEulerAnglesXYZ(
			g.Tilt.X + now * g.Rate.X * spinUp,
			g.Tilt.Y + now * g.Rate.Y * spinUp,
			g.Tilt.Z + now * g.Rate.Z * spinUp
		)
		local radius = g.Radius * lerp(1.15, 0.62, smooth(p)) * lerp(0.8, 1, appear) * implode
		placeSegRing(g.Ring, frame, radius, g.Thick, 2.6, 0.62, now * g.Spin * spinUp, lerp(1, 0.18, appear))
	end

	 
	local snap = locked and easeOutBack(lockAge / 0.24) or 0
	for _, b in ipairs(ch.Barrel) do
		local appear = smooth((p - b.Start) / 0.16)
		local dist = b.Dist * lerp(1.45, 1, appear) * (1 - 0.1 * snap)
		local radius = b.Radius * lerp(0.5, 1, appear) * (1 - 0.3 * snap) * implode
		local pos = M + dir * dist
		local frame = CFrame.lookAt(pos, pos + dir)
		local flash = locked and (1 - clamp01(lockAge / 0.5)) or 0
		placeSegRing(b.Ring, frame, radius, 1.5, 3, 0.7, now * b.Spin, math.max(lerp(1, 0.25, appear) - 0.2 * flash, 0))
	end

	 
	local rockParts, rockCFs = {}, {}
	for i, rk in ipairs(ch.Rocks) do
		local lift = smooth((p - rk.Start) / 0.45)
		local r = rk.R0 * (1 - 0.45 * smooth(p))
		local ang = rk.Ang + rk.Spin * t * lift
		rk.Pos = Vector3.new(F.X + math.cos(ang) * r, floorY + rk.Size * 0.4 + rk.Rise * lift, F.Z + math.sin(ang) * r)
		rockParts[i] = rk.Part
		rockCFs[i] = CFrame.new(rk.Pos) * CFrame.fromAxisAngle(rk.Axis, t * rk.Tumble * lift)
	end
	bulk(rockParts, rockCFs)

	 
	local seamTransparency = lerp(0.85, 0.3, e) - (locked and 0.12 or 0) + 0.05 * math.sin(now * 23)
	for _, c in ipairs(ch.Cracks) do
		local g = smooth((p - c.Start) / 0.22)
		if g > 0 and not c.Done then
			local len = c.Len * g
			local mid = c.P0 + c.Dir * (len * 0.5)
			local cf = CFrame.lookAt(mid, mid + c.Dir) * CFrame.Angles(0, math.pi * 0.5, 0)
			c.Dark.Size = Vector3.new(len, 0.15, c.Thick)
			c.Dark.CFrame = cf
			c.Seam.Size = Vector3.new(len, 0.1, 0.4)
			c.Seam.CFrame = cf
			if g >= 1 then
				c.Done = true
			end
		end
		if g > 0 then
			c.Seam.Transparency = seamTransparency
		end
	end

	 
	if p > 0.45 then
		for _, arc in ipairs(ch.Arcs) do
			if now >= arc.Next then
				arc.Next = now + rng:NextNumber(0.06, 0.16)
				if rng:NextNumber() < 0.25 + 0.6 * e then
					local ang = rng:NextNumber(0, TAU)
					local reach = rng:NextNumber(25, 60)
					local b = Vector3.new(F.X + math.cos(ang) * reach, floorY + 0.5, F.Z + math.sin(ang) * reach)
					setArc(arc, M + randomUnit(rng) * orbD * 0.3, b, 5, 0.15, rng)
				else
					hideArc(arc)
				end
			end
		end
	end

	addShake(M, 0.08 + 0.5 * e + (locked and 0.25 or 0))
end

 
 
 

function Effect:BuildBeam()
	local P, C, rng = self.P, self.C, self.Rng
	local W = P.BeamWidth
	local folder = subFolder(self.Folder, "Beam")
	self.BeamFolder = folder
	local bm = {}
	self.Bm = bm
	bm.All = {}

	 
	bm.Layers = {}
	for i, spec in ipairs(LAYERS) do
		local color = C[spec.Color]
		local layer = {
			Spec = spec,
			Body = newPart(folder, {
				Shape = Enum.PartType.Cylinder, Material = spec.Material, Color = color, Transparency = spec.Transparency,
			}),
			Tip = newPart(folder, {
				Shape = Enum.PartType.Ball, Material = spec.Material, Color = color, Transparency = spec.Transparency,
			}),
			Tail = newPart(folder, {
				Shape = Enum.PartType.Ball, Material = spec.Material, Color = color, Transparency = spec.Transparency,
			}),
		}
		bm.Layers[i] = layer
		table.insert(bm.All, layer.Body)
		table.insert(bm.All, layer.Tip)
		table.insert(bm.All, layer.Tail)
	end

	 
	bm.Flare = newPart(folder, { Shape = Enum.PartType.Ball, Material = MAT.Neon, Color = C.White, Transparency = 0.3 })
	bm.FlareLight = newLight(bm.Flare, C.Yellow, 4, 60)
	bm.MidMarker = newPart(folder, { Transparency = 1 })
	bm.MidLight = newLight(bm.MidMarker, C.Yellow, 2.4, 60)
	bm.TipMarker = newPart(folder, { Transparency = 1 })
	bm.TipLight = newLight(bm.TipMarker, C.Gold, 2.4, 60)
	table.insert(bm.All, bm.Flare)

	 
	bm.MuzzleGlow = newEmitter(bm.Flare, {
		LightEmission = 0.6,
		Color = ColorSequence.new(C.Yellow, C.Gold),
		Size = nseq({ { 0, W * 1.5 }, { 1, W * 1.9 } }),
		Transparency = nseq({ { 0, 1 }, { 0.3, 0.78 }, { 1, 1 } }),
		Lifetime = NumberRange.new(0.5, 0.7),
		Rate = 4,
		LockedToPart = true,
		Rotation = NumberRange.new(0, 360),
	})
	bm.HeadField = newPart(folder, { Transparency = 1, Size = Vector3.one * 10 })
	bm.HeadGlow = newEmitter(bm.HeadField, {
		LightEmission = 0.6,
		Color = ColorSequence.new(C.Yellow, C.Gold),
		Size = nseq({ { 0, W * 1.1 }, { 1, W * 1.4 } }),
		Transparency = nseq({ { 0, 1 }, { 0.3, 0.8 }, { 1, 1 } }),
		Lifetime = NumberRange.new(0.5, 0.7),
		Rate = 4,
		LockedToPart = true,
	})
	bm.HeadSparks = newEmitter(bm.HeadField, {
		LightEmission = 0.5,
		Color = ColorSequence.new(C.White, C.Gold),
		Size = nseq({ { 0, 0.2 }, { 0.2, 1.8 }, { 1, 0 } }),
		Transparency = nseq({ { 0, 0 }, { 0.7, 0.3 }, { 1, 1 } }),
		Lifetime = NumberRange.new(0.4, 0.9),
		Speed = NumberRange.new(40, 110),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 1,
	})

	 
	bm.Pulses = {}
	for k = 1, Quality.Count(PULSE_COUNT,3) do
		bm.Pulses[k] = newPart(folder, {
			Shape = Enum.PartType.Cylinder, Material = MAT.ForceField, Color = C.Yellow, Transparency = 1,
			Size = Vector3.new(1.2, 2, 2),
		})
		table.insert(bm.All, bm.Pulses[k])
	end

	 
	bm.Helix = {}
	local specs = {
		{ Radius = 0.40, Phase = 0, Dir = 1, Spin = -2.2, Color = C.White },
		{ Radius = 0.40, Phase = math.pi, Dir = 1, Spin = -2.2, Color = C.Yellow },
		{ Radius = 0.64, Phase = 1.3, Dir = -1, Spin = 1.6, Color = C.Gold },
	}
	for s, spec in ipairs(specs) do
		local segments=Quality.Count(HELIX_SEGS,14)
		local strand = { Spec = spec, Parts = table.create(segments), CFs = table.create(segments) }
		for j = 1, segments do
			strand.Parts[j] = newPart(folder, { Material = MAT.Neon, Color = spec.Color, Transparency = 1 })
			table.insert(bm.All, strand.Parts[j])
		end
		bm.Helix[s] = strand
	end

	 
	bm.Streaks = {}
 bm.StreakParts,bm.StreakCFs={},{}
	for k = 1, Quality.Count(STREAK_COUNT,8) do
		local streak = {
			Angle = rng:NextNumber(0, TAU), Radius = rng:NextNumber(0.12, 0.9), Speed = rng:NextNumber(260, 620),
			Length = rng:NextNumber(14, 50), Thick = rng:NextNumber(0.5, 1.5), Phase = rng:NextNumber(0, 400),
			Part = newPart(folder, {
				Material = MAT.Neon, Color = k % 3 == 0 and C.White or C.Yellow, Transparency = 1,
			}),
		}
		bm.Streaks[k] = streak
		table.insert(bm.All, streak.Part)
	end

	 
	bm.Arcs = {}
	for i = 1, 5 do
		bm.Arcs[i] = newArc(folder, C.White, 0.6)
	end

	 
	bm.BodyField = newPart(folder, { Transparency = 1 })
	bm.Embers = newEmitter(bm.BodyField, {
		LightEmission = 0.55,
		Color = cseq({ { 0, C.White }, { 0.3, C.Yellow }, { 1, C.Amber } }),
		Size = nseq({ { 0, 0.3 }, { 0.2, 1.6 }, { 1, 0 } }),
		Transparency = nseq({ { 0, 0.1 }, { 0.7, 0.4 }, { 1, 1 } }),
		Lifetime = NumberRange.new(1.2, 2.2),
		Speed = NumberRange.new(10, 36),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, -24, 0),
		Drag = 0.6,
	})
	bm.Smoke = newEmitter(bm.BodyField, {
		Texture = TEX_SMOKE,
		Color = ColorSequence.new(C.Soot, (self:GroundLook())),
		Size = nseq({ { 0, W * 0.12 }, { 1, W * 0.38 } }),
		Transparency = nseq({ { 0, 0.55 }, { 0.6, 0.78 }, { 1, 1 } }),
		Lifetime = NumberRange.new(2.2, 3.4),
		Speed = NumberRange.new(4, 14),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 5, 0),
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-20, 20),
		LightInfluence = 1,
	})
	table.insert(bm.All, bm.BodyField)
	bm.GroundField = newPart(folder, { Transparency = 1, Size = Vector3.new(10, 1, 10) })
	bm.Dust = newEmitter(bm.GroundField, {
		Texture = TEX_SMOKE,
		Color = ColorSequence.new((self:GroundLook()), (self:GroundLook()):Lerp(C.Soot, 0.35)),
		Size = nseq({ { 0, 12 }, { 1, 34 } }),
		Transparency = nseq({ { 0, 0.55 }, { 0.5, 0.75 }, { 1, 1 } }),
		Lifetime = NumberRange.new(1.6, 2.6),
		Speed = NumberRange.new(8, 22),
		EmissionDirection = Enum.NormalId.Top,
		SpreadAngle = Vector2.new(40, 40),
		Acceleration = Vector3.new(0, 3, 0),
		Drag = 1,
		Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-20, 20),
		LightInfluence = 1,
	})
	table.insert(bm.All, bm.GroundField)

	 
	bm.Scorch = newPart(self.GroundFolder, { Color = C.Soot, Transparency = 0.35, Size = Vector3.new(1, 0.15, 1) })
	bm.Seam = newPart(self.GroundFolder, {
		Material = MAT.Neon, Color = C.Amber, Transparency = 0.8, Size = Vector3.new(1, 0.12, 1),
	})
	table.insert(bm.All, bm.Scorch)
	table.insert(bm.All, bm.Seam)
end

function Effect:StartFire(data)
	if self.FireStart then
		return
	end
	self.FireStart = data.StartedAt
	self.Pivot = data.BeamOrigin or self.Pivot
	if data.Heading then
		if not self.Heading then
			self.Heading = data.Heading
		end
		self.AimSample = { Heading = data.Heading, Speed = 0, At = data.StartedAt }
	end
	local P, C = self.P, self.C
	local W = P.BeamWidth
	local M = self:Muzzle()
	local dir = BeamMath.Dir(self.Heading)
	local floorY = self.Floor.Y

	if not self.GroundFolder.Parent then
		self.GroundFolder = subFolder(self.Folder, "Ground")
	end
	local ch = self.Ch
	if ch then
		 
		for _, part in ipairs({ ch.Core, ch.Shell, ch.Aura }) do
			TweenService:Create(part, tweenInfo(0.35), { Size = Vector3.one * W * 1.3, Transparency = 1 }):Play()
		end
		TweenService:Create(ch.Light, tweenInfo(0.35), { Brightness = 0 }):Play()
		ch.Motes.Rate = 0
		ch.Glow.Rate = 0
		ch.Dust.Rate = 0
		for _, arc in ipairs(ch.Arcs) do
			hideArc(arc)
		end
		 
		for _, rk in ipairs(ch.Rocks) do
			local out = Vector3.new(rk.Pos.X - M.X, 0, rk.Pos.Z - M.Z)
			out = out.Magnitude > 0.1 and out.Unit or dir
			self:AddDebris(rk.Part, rk.Pos, out * self.Rng:NextNumber(70, 150) + Vector3.new(0, self.Rng:NextNumber(30, 80), 0),
				randomUnit(self.Rng) * self.Rng:NextNumber(2, 7))
		end
		ch.Rocks = {}
		 
		self.CrackTrail = ch.Cracks
		for _, c in ipairs(ch.Cracks) do
			c.Seam.Transparency = 0.1
		end
	end

	self:BuildBeam()
	if not self.PostOn then
		self.PostOn = true
		post.acquire("fire")
	else
		post.set("fire", 0.15)
	end
	if not self.FovOn then
		self.FovOn = true
		fov.acquire()
	end

	 
	screenFlash(M, 0.38, C.White)
	addShake(M, 2.6)
	fov.to(9, 0.08)
	task.delay(0.12, function()
		if not self.Dead then
			fov.to(0, 1.4)
		end
	end)
	burst(M, C.Yellow, W * 0.3, W * 1.5, 0.7, C.White)
	burst(M, C.Amber, W * 0.2, W * 2.2, 1.0)
	shockDisc(Vector3.new(M.X, floorY + 0.35, M.Z), C.Yellow, W * 1.8, 0.6, 0.55)
	sparkBurst(M, C.White, 120, 60, 200)
	self.Bm.Dust:Emit(40)
	for k = 1, 3 do
		local delay = (k - 1) * 0.07
		task.delay(delay, function()
			if self.Dead then
				return
			end
			local blast = newPart(self.BeamFolder, {
				Shape = Enum.PartType.Cylinder, Material = MAT.ForceField, Color = C.Yellow, Transparency = 0.5,
				Size = Vector3.new(1.5, W * 0.4, W * 0.4),
				CFrame = CFrame.lookAt(M, M + dir) * CFrame.Angles(0, math.rad(90), 0),
			})
			local far = M + dir * (W * 2.2)
			TweenService:Create(blast, tweenInfo(0.7), {
				Size = Vector3.new(1.5, W * 1.9, W * 1.9),
				Transparency = 1,
				CFrame = CFrame.lookAt(far, far + dir) * CFrame.Angles(0, math.rad(90), 0),
			}):Play()
			Debris:AddItem(blast, 0.9)
		end)
	end
	for _ = 1, 16 do
		local ang = self.Rng:NextNumber(0, TAU)
		local out = Vector3.new(math.cos(ang), 0, math.sin(ang))
		self:ThrowRock(
			Vector3.new(M.X, floorY + 2, M.Z) + out * self.Rng:NextNumber(8, 30),
			out * self.Rng:NextNumber(60, 140) + Vector3.new(0, self.Rng:NextNumber(40, 90), 0),
			self.Rng:NextNumber(1.8, 5)
		)
	end
	playSound("Fire", M, 1.5)
end

function Effect:UpdateRelease(now)
	local ch, P = self.Ch, self.P
	if not ch then
		return
	end
	local age = now - self.FireStart
	if age >= RELEASE_TIME then
		self.ChargeFolder:Destroy()
		self.Ch = nil
		return
	end
	local W = P.BeamWidth
	local x = clamp01(age / RELEASE_TIME)
	local dir = BeamMath.Dir(self.Heading)
	local M = self:Muzzle()
	local alpha = easeOutCubic(x)
	for i, g in ipairs(ch.Gyros) do
		local frame = CFrame.new(M) * CFrame.fromEulerAnglesXYZ(
			g.Tilt.X + now * g.Rate.X * 3.4, g.Tilt.Y + now * g.Rate.Y * 3.4, g.Tilt.Z + now * g.Rate.Z * 3.4
		)
		placeSegRing(g.Ring, frame, g.Radius * 0.62 * (1 + 2.4 * alpha), g.Thick, 2.6, 0.62, now * g.Spin * 3.4, lerp(0.18, 1, alpha))
	end
	for k, b in ipairs(ch.Barrel) do
		local pos = M + dir * (b.Dist * 0.9 + 560 * alpha * (0.5 + 0.2 * k))
		local frame = CFrame.lookAt(pos, pos + dir)
		placeSegRing(b.Ring, frame, b.Radius * 0.7 * (1 + 1.4 * alpha), 1.5, 3, 0.7, now * b.Spin, lerp(0.25, 1, alpha))
	end
end

function Effect:HideBeam()
	self.BeamHidden = true
	local bm = self.Bm
	for _, inst in ipairs(bm.All) do
		if inst ~= bm.Scorch and inst ~= bm.Seam then
			inst.Transparency = 1
		end
	end
	for _, arc in ipairs(bm.Arcs) do
		hideArc(arc)
	end
	bm.Embers.Rate = 0
	bm.Smoke.Rate = 0
	bm.Dust.Rate = 0
	bm.HeadSparks.Rate = 0
	bm.HeadGlow.Rate = 0
	bm.MuzzleGlow.Rate = 0
	bm.FlareLight.Enabled = false
	bm.MidLight.Enabled = false
	bm.TipLight.Enabled = false
	 
	TweenService:Create(bm.Scorch, tweenInfo(2.5), { Transparency = 1 }):Play()
	TweenService:Create(bm.Seam, tweenInfo(1.2), { Transparency = 1 }):Play()
	local M = self:Muzzle()
	burst(M, self.C.Yellow, self.P.BeamWidth * 0.6, self.P.BeamWidth * 1.2, 0.6)
	fov.to(0, 0.5)
	post.set("idle", 1.2)
end

function Effect:UpdateFire(now, dt)
	local P, C, rng = self.P, self.C, self.Rng
	local t = now - self.FireStart
	if t < 0 then
		return
	end
	if t >= P.FireDuration then
		if not self.BeamHidden then
			self:HideBeam()
		end
		return
	end
	local bm = self.Bm
	local W = P.BeamWidth

	 
	self.Folder:SetAttribute("BeamSampleTime", now)
	self.Folder:SetAttribute("BeamStartedAt", self.FireStart)
	self.Folder:SetAttribute("BeamHeading", self.Heading)

	local dir = BeamMath.Dir(self.Heading)
	local side = Vector3.new(-dir.Z, 0, dir.X)
	local up = Vector3.yAxis
	local a = self.Pivot + dir * P.MuzzleOffset
	local len = math.max(BeamMath.Length(t, P), 0.1)
	local w = BeamMath.Width(t, P)
	local wn = clamp01(w / W)
	local tip = a + dir * len
	local mid = a + dir * (len * 0.5)
	local along = CFrame.lookAt(mid, mid + dir) * CFrame.Angles(0, math.rad(90), 0)
	local floorY = self.Floor.Y
	local radius = w * 0.5
	local axisHeight = math.max(self.Pivot.Y - floorY, 0)
	local footWidth = math.max(2 * math.sqrt(math.max(radius * radius - axisHeight * axisHeight, 0)), 0.05)

	 
	for i, layer in ipairs(bm.Layers) do
		local spec = layer.Spec
		local d = math.max(w * spec.Scale * (1 + spec.Wobble * math.sin(now * spec.Freq + i)), 0.05)
		layer.Body.Size = Vector3.new(len, d, d)
		layer.Body.CFrame = along
		layer.Tip.Size = Vector3.one * d
		layer.Tip.Position = tip
		layer.Tail.Size = Vector3.one * d
		layer.Tail.Position = a
	end

	 
	bm.Flare.Size = Vector3.one * math.max(w * 0.42 * (1 + 0.06 * math.sin(now * 50)), 0.05)
	bm.Flare.Position = a
	bm.FlareLight.Brightness = 3.5 + 1.5 * math.sin(now * 30)
	bm.MidMarker.Position = mid + up * 6
	bm.TipMarker.Position = tip
	bm.HeadField.Position = tip
	bm.MuzzleGlow.Rate = Quality.Rate(4 * wn)
	bm.HeadGlow.Rate = Quality.Rate(4 * wn)

	 
	local spacing = P.BeamRange / #bm.Pulses
	for k, disc in ipairs(bm.Pulses) do
		local dist = (now * 280 + k * spacing) % P.BeamRange
		if dist <= len and w > 1 then
			local pos = a + dir * dist
			disc.Size = Vector3.new(1.2, w * 0.93, w * 0.93)
			disc.CFrame = CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, math.rad(90), 0)
			disc.Transparency = 0.72 + 0.25 * (dist / len) ^ 2
		else
			disc.Transparency = 1
		end
	end

	 
	local thick = math.max(w * 0.014, 0.1)
	for _, strand in ipairs(bm.Helix) do
		local spec = strand.Spec
		local parts, cfs = strand.Parts, strand.CFs
  local segments=#parts
		local rad = w * spec.Radius
		local prev
		for j = 0, segments do
			local dist = len * j / segments
			local ang = spec.Phase + spec.Dir * dist * HELIX_TWIST + now * spec.Spin
			local pos = a + dir * dist + (side * math.cos(ang) + up * math.sin(ang)) * rad
			if prev then
				local seg = parts[j]
				seg.Size = Vector3.new(thick, thick, (pos - prev).Magnitude + 0.5)
				seg.Transparency = w > 2 and (0.3 + 0.6 * (j / segments) ^ 3) or 1
				cfs[j] = CFrame.lookAt((pos + prev) * 0.5, pos)
			end
			prev = pos
		end
		bulk(parts, cfs)
	end

	 
	local streakParts, streakCFs = bm.StreakParts, bm.StreakCFs
 table.clear(streakParts); table.clear(streakCFs)
	for k, s in ipairs(bm.Streaks) do
		local d = (s.Phase + now * s.Speed) % len
		local visible = w > 2 and d + s.Length * 0.5 < len
		s.Part.Transparency = visible and (0.35 + 0.5 * d / len) or 1
		if visible then
			local pos = a + dir * d + (side * math.cos(s.Angle) + up * math.sin(s.Angle)) * (radius * s.Radius)
			s.Part.Size = Vector3.new(s.Thick, s.Thick, s.Length)
			streakParts[#streakParts + 1] = s.Part
			streakCFs[#streakCFs + 1] = CFrame.lookAt(pos, pos + dir)
		end
	end
	bulk(streakParts, streakCFs)

	 
	for _, arc in ipairs(bm.Arcs) do
		if now >= arc.Next then
			arc.Next = now + rng:NextNumber(0.07, 0.16)
			if wn > 0.5 and rng:NextNumber() < 0.7 then
				local d1 = rng:NextNumber(0.05, 0.9) * len
				local d2 = math.min(d1 + rng:NextNumber(25, 70), len)
				local a1 = rng:NextNumber(0, TAU)
				local a2 = a1 + rng:NextNumber(-1, 1)
				local p1 = a + dir * d1 + (side * math.cos(a1) + up * math.sin(a1)) * radius * 0.96
				local p2 = a + dir * d2 + (side * math.cos(a2) + up * math.sin(a2)) * radius * 0.96
				setArc(arc, p1, p2, 4, 0.15, rng)
			else
				hideArc(arc)
			end
		end
	end

	 
	local fm = Vector3.new(mid.X, floorY + 0.15, mid.Z)
	local floorCF = CFrame.lookAt(fm, fm + dir) * CFrame.Angles(0, math.rad(90), 0)
	bm.Scorch.Size = Vector3.new(len, 0.15, footWidth)
	bm.Scorch.CFrame = floorCF
	bm.Seam.Size = Vector3.new(len, 0.12, footWidth * 0.55)
	bm.Seam.CFrame = floorCF
	bm.Seam.Transparency = 0.78 + 0.08 * math.sin(now * 14)
	bm.GroundField.Size = Vector3.new(len, 1, math.max(footWidth * 0.9, 0.05))
	bm.GroundField.CFrame = CFrame.lookAt(Vector3.new(mid.X, floorY + 0.6, mid.Z), Vector3.new(mid.X, floorY + 0.6, mid.Z) + dir)
		* CFrame.Angles(0, math.rad(90), 0)
	bm.Dust.Rate = Quality.Rate(math.clamp(len * 0.5, 0, 180) * wn)
	local fieldSize = math.max(w * 0.9, 0.05)
	bm.BodyField.Size = Vector3.new(len, fieldSize, fieldSize)
	bm.BodyField.CFrame = along
	bm.Embers.Rate = Quality.Rate(math.clamp(len * 0.45, 0, 160) * wn)
	bm.Smoke.Rate = Quality.Rate(14 * wn)
	bm.HeadSparks.Rate = Quality.Rate(120 * wn)

	 
	if t > 0.3 and wn > 0.5 and now >= (self.DebrisNext or 0) then
		self.DebrisNext = now + 0.1
		local maximum=math.min(len,230)
  local d = rng:NextNumber(math.min(30,maximum),maximum)
		local sign = rng:NextInteger(0, 1) == 0 and -1 or 1
		local pos = Vector3.new(a.X, floorY + 2, a.Z) + dir * d + side * sign * footWidth * 0.5
		self:ThrowRock(pos, side * sign * rng:NextNumber(30, 75) + dir * rng:NextNumber(-10, 40)
			+ Vector3.new(0, rng:NextNumber(35, 80), 0), rng:NextNumber(1.6, 4.5))
	end

	 
	if self.CrackTrail then
		local cool = lerp(0.15, 0.85, clamp01(t / (P.FireDuration + 1)))
		for _, c in ipairs(self.CrackTrail) do
			c.Seam.Transparency = cool
		end
	end

	addShake(a, 0.15 + 0.95 * wn)
end

 
 
 

function Effect:SpawnRing(data)
	local P, C = self.P, self.C
	local tall = data.Tall
	local center = data.Center or self.Floor
	local folder = subFolder(self.RingsFolder, "Ring" .. tostring(data.Index))
	local segments=Quality.Count(RING_SEGMENTS,24)
 local units={}
 for i=1,segments do local angle=(i-1)/segments*TAU; units[i]=Vector3.new(math.cos(angle),0,math.sin(angle)) end
 local body, lip = table.create(segments), nil
	for i = 1, segments do
		body[i] = newPart(folder, {
			Material = MAT.ForceField, Color = tall and C.Yellow or C.Gold, Transparency = 0.7,
		})
		 
		if i % 5 == 1 then
			newEmitter(body[i], {
				Texture = TEX_SMOKE,
				Color = ColorSequence.new((self:GroundLook()), (self:GroundLook()):Lerp(C.Soot, 0.4)),
				Size = nseq({ { 0, 4 }, { 1, tall and 16 or 10 } }),
				Transparency = nseq({ { 0, 0.7 }, { 0.5, 0.82 }, { 1, 1 } }),
				Lifetime = NumberRange.new(1.0, 1.8),
				Speed = NumberRange.new(4, 12),
				EmissionDirection = Enum.NormalId.Top,
				SpreadAngle = Vector2.new(35, 35),
				Acceleration = Vector3.new(0, 4, 0),
				Rotation = NumberRange.new(0, 360),
				LightInfluence = 1,
				Rate = tall and 7 or 4,
			})
		end
	end
	if tall then
		lip = table.create(segments)
		for i = 1, segments do
			lip[i] = newPart(folder, { Material = MAT.Neon, Color = C.White, Transparency = 0.25 })
		end
	end
	table.insert(self.Rings, { Born = data.StartedAt, Tall = tall, Center = center, Body = body, Lip = lip, Folder = folder, Units=units, BodyCFs=table.create(segments), LipCFs=tall and table.create(segments) or nil })
	if tall then
		shockDisc(center + Vector3.new(0, 0.3, 0), C.Yellow, 90, 0.6, 0.5)
	end
	addShake(center, tall and 1.8 or 0.8)
	for _ = 1, tall and 7 or 4 do
		local ang = self.Rng:NextNumber(0, TAU)
		local out = Vector3.new(math.cos(ang), 0, math.sin(ang))
		self:ThrowRock(center + out * self.Rng:NextNumber(6, 16) + Vector3.new(0, 1.5, 0),
			out * self.Rng:NextNumber(40, 100) + Vector3.new(0, self.Rng:NextNumber(30, 70), 0), self.Rng:NextNumber(1.4, 3.6))
	end
	playSound(tall and "TallRing" or "Ring", center, tall and 1.2 or 0.8)
end

function Effect:UpdateRings(now)
	local P = self.P
	for i = #self.Rings, 1, -1 do
		local ring = self.Rings[i]
		local r = (now - ring.Born) * P.RingSpeed
		if r >= P.RingMaxRadius then
			ring.Folder:Destroy()
			table.remove(self.Rings, i)
		elseif r > 0 then
			local h = ring.Tall and P.TallHeight or P.LowHeight
			local fade = clamp01((P.RingMaxRadius - r) / 60)
			local base = ring.Tall and (0.55 + 0.05 * math.sin(now * 20)) or 0.68
			local transparency = base + (1 - fade) * (1 - base)
			local chord = 2 * r * math.sin(math.pi / #ring.Body) + 2
			local thick = P.RingThickness + 1.5
			local bodyCFs = ring.BodyCFs
			local lipCFs = ring.LipCFs
			for s, seg in ipairs(ring.Body) do
				local u = ring.Units[s]
				local pos = ring.Center + u * r + Vector3.new(0, h * 0.5, 0)
				seg.Size = Vector3.new(chord, h, thick)
				seg.Transparency = transparency
				bodyCFs[s] = CFrame.lookAt(pos, pos + u)
				if ring.Lip then
					local lp = ring.Lip[s]
					lp.Size = Vector3.new(chord, 0.7, thick * 0.7)
					lp.Transparency = math.min(0.25 + (1 - fade) * 0.75, 1)
					lipCFs[s] = CFrame.lookAt(ring.Center + u * r + Vector3.new(0, h - 0.35, 0), ring.Center + u * r + Vector3.new(0, h - 0.35, 0) + u)
				end
			end
			bulk(ring.Body, bodyCFs)
			if ring.Lip then
				bulk(ring.Lip, lipCFs)
			end
		end
	end
end

 
 
 

function Effect:UpdateDebris(dt)
	local list = self.Debris
	local parts, cfs = {}, {}
	local gravity = 130
	local floorY = self.Floor.Y
	for i = #list, 1, -1 do
		local d = list[i]
		d.Age = d.Age + dt
		if d.Age >= d.Life then
			d.Part:Destroy()
			table.remove(list, i)
		else
			d.Vel = d.Vel + Vector3.new(0, -gravity * dt, 0)
			d.Pos = d.Pos + d.Vel * dt
			local gy = floorY + d.Half
			if d.Pos.Y < gy then
				d.Pos = Vector3.new(d.Pos.X, gy, d.Pos.Z)
				if d.Vel.Y < -8 then
					d.Vel = Vector3.new(d.Vel.X * 0.6, -d.Vel.Y * 0.32, d.Vel.Z * 0.6)
					d.Ang = d.Ang * 0.6
				else
					local k = 1 - math.min(1, 6 * dt)
					d.Vel = Vector3.new(d.Vel.X * k, 0, d.Vel.Z * k)
					d.Ang = d.Ang * (1 - math.min(1, 5 * dt))
				end
			end
			local w = d.Ang.Magnitude
			if w > 0.001 then
				d.Orient = CFrame.fromAxisAngle(d.Ang / w, w * dt) * d.Orient
			end
			local remaining = d.Life - d.Age
			if remaining < 0.6 then
				d.Part.Transparency = 1 - remaining / 0.6
			end
			parts[#parts + 1] = d.Part
			cfs[#cfs + 1] = CFrame.new(d.Pos) * d.Orient
		end
	end
	bulk(parts, cfs)
end

function Effect:UpdateAim(now, dt)
	local s = self.AimSample
	if not s then
		return
	end
	local target = BeamMath.Extrapolate(s.Heading, s.Speed, now - s.At)
	local diff = BeamMath.Wrap(target - self.Heading)
	self.Heading = self.Heading + diff * (1 - math.exp(-dt * 14))
end

function Effect:Update(now, dt)
	self:UpdateAim(now, dt)
	if not self.FireStart then
		if self.Ch then
			self:UpdateCharge(now, dt)
		end
	else
		self:UpdateRelease(now)
		self:UpdateFire(now, dt)
	end
	self:UpdateRings(now)
	self:UpdateDebris(dt)
end

local function unbind()
	if not bound then
		return
	end
	bound = false
	RunService:UnbindFromRenderStep("HyperElasticUpdate")
	RunService:UnbindFromRenderStep("HyperElasticShake")
	shakePending = 0
end

function Effect:Finish()
	if self.Dead then
		return
	end
	self.Dead = true
	effects[self.Token] = nil
	activeCount = activeCount - 1
	if self.PostOn then
		post.release()
	end
	if self.FovOn then
		fov.release()
	end
	for _, d in ipairs(self.Folder:GetDescendants()) do
		if d:IsA("BasePart") then
			if d.Transparency < 1 then
				TweenService:Create(d, tweenInfo(0.4), { Transparency = 1 }):Play()
			end
		elseif d:IsA("ParticleEmitter") or d:IsA("Light") then
			d.Enabled = false
		end
	end
	Debris:AddItem(self.Folder, 1.6)
	if activeCount <= 0 then
		activeCount = 0
		unbind()
	end
end

local visualElapsed=0
local function step(dt)
 visualElapsed+=dt
 if visualElapsed<Quality.Get().Interval then return end
 dt=visualElapsed
 visualElapsed=0
	local now = workspace:GetServerTimeNow()
 if post.bloom then post.bloom.Enabled=Quality.Get().Post and Reset.ViewAllowed() end
 if post.grade then post.grade.Enabled=Quality.Get().Post and Reset.ViewAllowed() end
	for _, fx in pairs(effects) do
		local owner = fx.Owner
		local h = owner and owner:FindFirstChildOfClass("Humanoid")
		if not owner or not owner.Parent or owner:GetAttribute("Phase") ~= 5 or owner:GetAttribute("EncounterEnded")
			or (h and h.Health <= 0) or os.clock() - fx.Created > fx.MaxLife then
			fx:Finish()
		else
			fx:Update(now, math.min(dt, 0.1))
		end
	end
end

local function bind()
	if bound then
		return
	end
	bound = true
	 
	RunService:BindToRenderStep("HyperElasticUpdate", Enum.RenderPriority.Camera.Value - 1, step)
	RunService:BindToRenderStep("HyperElasticShake", Enum.RenderPriority.Camera.Value + 1, function()
		local m = Reset.ViewAllowed() and shakePending or 0
		shakePending = 0
		if m < 0.001 then
			return
		end
		local cam = workspace.CurrentCamera
		if cam then
			cam.CFrame = cam.CFrame
				* CFrame.new((math.random() - 0.5) * m, (math.random() - 0.5) * m, 0)
				* CFrame.Angles(0, 0, (math.random() - 0.5) * m * 0.01)
		end
	end)
end

local function createEffect(data, withCharge)
	local P = data.Params
	local self = setmetatable({}, Effect)
	self.Token = data.Token
	self.Owner = data.Owner
	self.P = P
	self.C = {}
	for key, fallback in pairs(FALLBACK) do
		self.C[key] = P[key] or fallback
	end
	self.Rng = Random.new()
	self.Pivot = data.BeamOrigin
	self.Heading = data.Heading or 0
	self.AimSample = { Heading = self.Heading, Speed = 0, At = data.StartedAt or workspace:GetServerTimeNow() }
	self.Floor = data.Floor or (data.Origin - Vector3.yAxis * 3)
	self.ChargeStart = data.StartedAt
	self.Rings = {}
	self.Debris = {}
	self.Created = os.clock()
	self.MaxLife = P.Charge + P.FireDuration + P.RingMaxRadius / P.RingSpeed + 4
	self.Folder = Instance.new("Folder")
	self.Folder.Name = "HyperElasticVFX"
	self.Folder.Parent = workspace
	self.GroundFolder = subFolder(self.Folder, "Ground")
	self.RingsFolder = subFolder(self.Folder, "Rings")
	self.DebrisFolder = subFolder(self.Folder, "Debris")
	effects[self.Token] = self
	activeCount = activeCount + 1
	if withCharge then
		self.PostOn = true
		post.acquire("charge")
		self.FovOn = true
		fov.acquire()
		fov.to(-4, P.Charge, Enum.EasingStyle.Sine)
		self:BuildCharge()
	end
	bind()
	return self
end

 
 
 

function VFX.Handle(data)
	if type(data) ~= "table" then
		return
	end
	local stage = data.Stage
	local blocked=data.Token and blockedTokens[data.Token]
	if blocked and blocked>os.clock() then return end
	for token,at in pairs(blockedTokens) do if at<=os.clock() then blockedTokens[token]=nil end end
	local fx = data.Token and effects[data.Token]
 if stage=="End" and data.Token then blockedTokens[data.Token]=os.clock()+40 end

	if stage == "Charge" then
		if not fx and data.Params and data.BeamOrigin then
			createEffect(data, true)
		end
	elseif stage == "Aim" then
		if fx and data.Heading then
			fx.AimSample = { Heading = data.Heading, Speed = data.Speed or 0, At = data.At or workspace:GetServerTimeNow() }
		end
	elseif stage == "Fire" then
		if not fx and data.Params and data.BeamOrigin then
			fx = createEffect(data, false)
		end
		if fx then
			fx:StartFire(data)
		end
	elseif stage == "Ring" then
		if fx then
			fx:SpawnRing(data)
		end
	elseif stage == "Impact" then
		if data.Position then
			burst(data.Position, FALLBACK.Yellow, 4, 44, 0.45, FALLBACK.White)
			shockDisc(data.Position, FALLBACK.Yellow, 60, 0.45, 0.5)
			sparkBurst(data.Position, FALLBACK.White, 40, 30, 90)
			addShake(data.Position, 1.2)
			playSound("Impact", data.Position, 1)
		end
	elseif stage == "End" then
		if fx then
			fx:Finish()
		end
	end
end

function VFX.ResetView()
 local restoreFov=fov.base
 for _,fx in pairs(effects)do fx.PostOn=false fx.FovOn=false end
 if fov.tween then fov.tween:Cancel()fov.tween=nil end
 local camera=workspace.CurrentCamera
 fovValue.Value=0 Fov.Clear(fov)
 fov.refs=0 fov.base=nil post.refs=0 post.bloom=nil post.grade=nil
 shakePending=0
 for _,effect in ipairs(Lighting:GetChildren())do
  if effect.Name=="HyperElasticBloom"or effect.Name=="HyperElasticGrade"then effect:Destroy()end
 end
 local gui=Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
 if gui then for _,effect in ipairs(gui:GetChildren())do if effect.Name=="HyperElasticFlash"then effect:Destroy()end end end
end

function VFX.Clear()
	local restoreFov=fov.base
	local selected = {}
	for _, fx in pairs(effects) do
		table.insert(selected, fx)
		blockedTokens[fx.Token]=os.clock()+40
	end
	for _, fx in ipairs(selected) do fx:Finish() fx.Folder:Destroy() end
	if fov.tween then fov.tween:Cancel() fov.tween=nil end
	local camera=workspace.CurrentCamera
	fovValue.Value=0 Fov.Clear(fov)
	fov.refs=0 fov.base=nil
	post.refs=0 post.bloom=nil post.grade=nil
	for _,effect in ipairs(Lighting:GetChildren()) do
	 if effect.Name=="HyperElasticBloom" or effect.Name=="HyperElasticGrade" then effect:Destroy() end
	end
	unbind()
end

Reset.Register(script,VFX.Clear,VFX.ResetView)
return VFX
