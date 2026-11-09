local B = script:FindFirstAncestor("BossSystem")
local Effects = require(B.Combat.EffectService)
local V = {}
local GOLD = Color3.fromRGB(255, 210, 55)
local COLORS = {GOLD, Color3.fromRGB(255, 92, 153), Color3.fromRGB(103, 231, 255), Color3.fromRGB(170, 125, 255), Color3.fromRGB(130, 255, 164)}
local TAU = math.pi * 2

function V.Part(cast, parent, name, frame, size, color, alpha, shape)
	local p = cast:Add(Effects.AcquirePart())
	p.Name, p.CFrame, p.Size = name, frame, size
	p.Color, p.Transparency = color, alpha or 0
	p.Shape = shape or Enum.PartType.Block
	p.Material = Enum.Material.Neon
	p.Parent = parent
	return p
end

function V.Ring(cast, parent, point, radius, color, alpha)
	return V.Part(cast, parent, "IllusionCircle", CFrame.new(point) * CFrame.Angles(0, 0, math.pi/2),
		Vector3.new(.12, radius*2, radius*2), color or GOLD, alpha or .7, Enum.PartType.Cylinder)
end

function V.Arc(start, finish, height, progress)
	local t = math.clamp(progress, 0, 1)
	return start:Lerp(finish, t) + Vector3.yAxis * (4 * height * t * (1-t))
end

function V.AreaHit(character, point, radius, height)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local h = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not h or h.Health <= 0 then return false end
	local delta = root.Position-point
	return Vector3.new(delta.X, 0, delta.Z).Magnitude <= radius
		and delta.Y >= -2 and delta.Y <= height
end

function V.SweptDistance(point, first, last)
	local d = (last-first) * Vector3.new(1,0,1)
	local p = (point-first) * Vector3.new(1,0,1)
	local t = math.clamp(p:Dot(d) / math.max(d:Dot(d), 1e-6), 0, 1)
	return (p-d*t).Magnitude
end

function V.Bomb(cast, parent, position)
	local bomb = V.Part(cast, parent, "IllusionBomb", CFrame.new(position), Vector3.one*2.8, GOLD, 0, Enum.PartType.Ball)
	local fuse = Instance.new("Attachment")
	fuse.Position = Vector3.new(0,1.2,0) fuse.Parent = bomb
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(Color3.new(1,1,1), GOLD) sparks.LightEmission = 1 sparks.Rate = 18
	sparks.Lifetime = NumberRange.new(.12,.25) sparks.Speed = NumberRange.new(2,4)
	sparks.Size = NumberSequence.new(.3,0) sparks.Parent = fuse
	return bomb
end

function V.Pop(cast, parent, point, real, radius, now, rng)
	local records = {}
	if real then
		local sphere = V.Part(cast, parent, "GoldenBombBlast", CFrame.new(point+Vector3.yAxis),
			Vector3.one, GOLD, .25, Enum.PartType.Ball)
		local ring = V.Ring(cast,parent,point+Vector3.yAxis*.16,1,GOLD,.15)
		records[1], records[2] = sphere, ring
	else
		for i=1,12 do
			local p=V.Part(cast,parent,"Confetti",CFrame.new(point+Vector3.yAxis),Vector3.new(.3,.8,.08),COLORS[(i-1)%#COLORS+1])
			records[i]={Part=p,Velocity=Vector3.new(rng:NextNumber(-14,14),rng:NextNumber(14,27),rng:NextNumber(-14,14)),Spin=rng:NextNumber(-10,10)}
		end
	end
	return {Real=real,Parts=records,Point=point,Radius=radius,Born=now}
end

function V.UpdatePop(pop, now)
	local age=now-pop.Born
	if age>=.75 then
		for _,record in ipairs(pop.Parts)do Effects.Release(pop.Real and record or record.Part)end
		return false
	end
	local alpha=math.clamp(age/.75,0,1)
	if pop.Real then
		local diameter=math.max(.1,pop.Radius*2*(1-(1-alpha)^3))
		pop.Parts[1].Size=Vector3.new(diameter,math.min(diameter,12),diameter)
		pop.Parts[1].Transparency=.25+.75*alpha
		pop.Parts[2].Size=Vector3.new(.12,diameter,diameter)
		pop.Parts[2].Transparency=.15+.85*alpha
	else
		for _,record in ipairs(pop.Parts)do
			record.Part.CFrame=CFrame.new(pop.Point+Vector3.yAxis+record.Velocity*age-Vector3.yAxis*25*age*age)
				*CFrame.Angles(age*record.Spin,age*3,age*2)
			record.Part.Transparency=alpha
		end
	end
	return true
end

function V.Monster(cast, parent, frame)
	local model=cast:Add(Instance.new("Model"))
	model.Name="GoldenMysteriousIllusion" model:SetAttribute("IsIllusion",true)
	model:SetAttribute("Invulnerable",true) model:SetAttribute("AttackAimOnly",true) model.Parent=parent
	local root=V.Part(cast,model,"HumanoidRootPart",frame,Vector3.one*.1,Color3.new(),1)
	model.PrimaryPart=root
	local parts={}
	local specs={
		{"UndefinedBody",Vector3.new(0,1,0),Vector3.new(3.8,5.4,2.6)},
		{"UndefinedHead",Vector3.new(0,4,0),Vector3.one*2.8},
		{"LeftClaw",Vector3.new(-3,.4,0),Vector3.new(1.2,5.6,1.1)},
		{"RightClaw",Vector3.new(3,.4,0),Vector3.new(1.2,5.6,1.1)},
		{"LeftLeg",Vector3.new(-1.1,-2,0),Vector3.new(1,3.8,1)},
		{"RightLeg",Vector3.new(1.1,-2,0),Vector3.new(1,3.8,1)},
	}
	for i,spec in ipairs(specs)do
		local p=V.Part(cast,model,spec[1],frame*CFrame.new(spec[2]),spec[3],Color3.fromRGB(5,4,10),.12)
		parts[i]={Part=p,Offset=spec[2],Index=i}
	end
	for i=1,5 do
		local angle=i*TAU/5
		local offset=Vector3.new(math.cos(angle)*2.4,2+math.sin(angle)*2,math.sin(angle)*1.6)
		local p=V.Part(cast,model,"UndefinedShard",frame*CFrame.new(offset),Vector3.new(.8,3.5,.6),Color3.fromRGB(24,12,38),.25)
		parts[#parts+1]={Part=p,Offset=offset,Index=i+6}
	end
	local ghost={Model=model,Root=root,Parts=parts}
	function ghost.Update(pivot, time, fade)
		root.CFrame=pivot
		fade=math.clamp(fade or 0,0,1)
		for _,record in ipairs(parts)do
			local i=record.Index
			local glitch=Vector3.new(math.noise(time*8,i)*.35,math.sin(time*5+i)*.25,0)
			record.Part.CFrame=pivot*CFrame.new(record.Offset+glitch)
				*CFrame.Angles(math.sin(time*3+i)*.12,0,math.sin(time*5+i)*.18)
			record.Part.Transparency=.12+.88*fade
		end
	end
	ghost.Update(frame,0)
	return ghost
end

function V.HideSword(actor)
	local saved={}
	local sword=actor:FindFirstChild("Basic Sword")
	if sword then
		for _,p in ipairs(sword:GetDescendants())do
			if p:IsA("BasePart") then saved[p]=p.Transparency p.Transparency=1 end
		end
	end
	return function()
		for p,alpha in pairs(saved)do if p.Parent then p.Transparency=alpha end end
		table.clear(saved)
	end
end

 
 
 
 
 
 
 
local VOID = Color3.fromRGB(8, 5, 16)
local DEEP = Color3.fromRGB(64, 26, 120)
local VIOLET = Color3.fromRGB(150, 84, 255)
local PALE = Color3.fromRGB(228, 210, 255)
local DANGER = Color3.fromRGB(255, 64, 104)
local SPHERE = Enum.MeshType.Sphere
local V3 = Vector3.new

local function lerp(a, b, t) return a + (b - a) * t end
local function seq(...)
	local a, k = {...}, {}
	for i = 1, #a, 2 do k[#k+1] = NumberSequenceKeypoint.new(a[i], a[i+1]) end
	return NumberSequence.new(k)
end

 
local function solid(parent, name, size, color, alpha, material, mesh, shape, class)
	local p = Instance.new(class or "Part")
	if shape then p.Shape = shape end
	p.Name = name
	p.Anchored = true p.CanCollide = false p.CanTouch = false p.CanQuery = false
	p.CastShadow = false p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = material or Enum.Material.Neon
	p.Color = color p.Transparency = alpha or 0 p.Size = size
	if mesh then
		local m = Instance.new("SpecialMesh")
		m.MeshType = mesh
		m.Parent = p
	end
	p.Parent = parent
	return p
end

local function emit(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.LightInfluence = 0
	e.Rotation = NumberRange.new(0, 360)
	e.RotSpeed = NumberRange.new(-60, 60)
	for k, v in pairs(props) do e[k] = v end
	e.Parent = parent
	return e
end

 
 
 
 
 
function V.ShadowMonster(cast, parent, frame)
	local model = cast:Add(Instance.new("Model"))
	model.Name = "GoldenMysteriousIllusion" model:SetAttribute("IsIllusion", true)
	model:SetAttribute("Invulnerable", true) model:SetAttribute("AttackAimOnly", true) model.Parent = parent
	local root = V.Part(cast, model, "HumanoidRootPart", frame, Vector3.one * .1, Color3.new(), 1)
	model.PrimaryPart = root

	 -- every piece is welded to the root and posed through its weld, so the body moves as one unit
	 -- on clients (separately moved anchored parts replicate out of step and drift apart at speed)
	local recs = {}
	local function add(name, size, color, alpha, material, mesh)
		local part = solid(model, name, size, color, alpha, material, mesh)
		part.Anchored = false
		local weld = Instance.new("Weld")
		weld.Part0 = root weld.Part1 = part weld.Parent = part
		local rec = {Part = part, Weld = weld, Alpha = alpha or 0}
		recs[#recs+1] = rec
		return rec
	end

	 
	local hem = add("Hem", V3(1.7, 3, 1.4), VOID, .08, nil, SPHERE)
	local robe = add("Robe", V3(3, 3.8, 2.1), VOID, .06, nil, SPHERE)
	local chest = add("Chest", V3(3.9, 3, 2.2), VOID, .06, nil, SPHERE)
	local hood = add("Hood", V3(2.5, 3.1, 2.6), VOID, .04, nil, SPHERE)
	local aura = add("Aura", V3(5.2, 10.4, 3.9), VIOLET, .64, Enum.Material.ForceField, SPHERE)
	local eyeL = add("EyeL", V3(.8, .15, .14), PALE, 0)
	local eyeR = add("EyeR", V3(.8, .15, .14), PALE, 0)

	 
	local arms = {}
	for _, side in ipairs({-1, 1}) do
		local arm = {Side = side, Fingers = {}}
		arm.Upper = add("UpperArm", V3(.8, 3, .8), VOID, .06, nil, SPHERE)
		arm.Fore = add("Forearm", V3(.62, 3.4, .62), VOID, .06, nil, SPHERE)
		for i = 1, 3 do arm.Fingers[i] = add("Claw", V3(.24, 1.8, .24), DEEP, .04, nil, SPHERE) end
		local t0 = Instance.new("Attachment") t0.Position = V3(-.3, -1.5, 0) t0.Parent = arm.Fore.Part
		local t1 = Instance.new("Attachment") t1.Position = V3(.3, -1.5, 0) t1.Parent = arm.Fore.Part
		local trail = Instance.new("Trail")
		trail.Attachment0 = t0 trail.Attachment1 = t1
		trail.Lifetime = .35 trail.MinLength = .1 trail.LightEmission = 1 trail.LightInfluence = 0
		trail.Color = ColorSequence.new(PALE, VIOLET)
		trail.Transparency = seq(0, .35, 1, 1)
		trail.WidthScale = seq(0, 1, 1, 0)
		trail.Enabled = false
		trail.Parent = arm.Fore.Part
		arm.Trail = trail
		arms[#arms+1] = arm
	end

	 
	local ribbons = {}
	for i = 1, 3 do ribbons[i] = add("Cloak", V3(.9, 4.4, .06), VOID, .12) end

	 
	local smoke = emit(hem.Part, {
		Texture = "rbxasset://textures/particles/smoke_main.dds", Color = ColorSequence.new(DEEP, VOID),
		Size = seq(0, 1.6, 1, 4.2), Transparency = seq(0, .55, .5, .7, 1, 1), Lifetime = NumberRange.new(.8, 1.4),
		Speed = NumberRange.new(1, 4), SpreadAngle = Vector2.new(180, 180), Drag = 1.5, LightEmission = .1,
		Rate = 22, LockedToPart = false, Enabled = false,
	})
	local embers = emit(chest.Part, {
		Texture = "rbxasset://textures/particles/sparkles_main.dds", Color = ColorSequence.new(PALE, VIOLET),
		Size = seq(0, .35, 1, 0), Transparency = seq(0, 0, .8, .3, 1, 1), Lifetime = NumberRange.new(.6, 1.2),
		Speed = NumberRange.new(1, 4), SpreadAngle = Vector2.new(180, 180), Acceleration = V3(0, 4, 0),
		Drag = 1, LightEmission = 1, Rate = 9, LockedToPart = false, Enabled = false,
	})
	local eyeLight = Instance.new("PointLight")
	eyeLight.Color = VIOLET eyeLight.Range = 12 eyeLight.Brightness = 0 eyeLight.Shadows = false
	eyeLight.Parent = hood.Part

	local ghost = {Model = model, Root = root, Parts = recs}
	local lastPos, lastTime, speed = nil, 0, 0
	local lastFade, lastLive, alertLevel, cut, pendingClear = nil, nil, 0, false, false
	local pose = frame
	local function put(rec, cf) rec.Weld.C0 = pose:ToObjectSpace(cf) end
	local function eyeBrightness(fade) return (1.2 + alertLevel / 5 * 2) * (1 - fade) end

	function ghost.SetAlert(a)
		local level = math.floor(math.clamp(a, 0, 1) * 5 + .5)
		if level == alertLevel then return end
		alertLevel = level
		local k = level / 5
		local c = PALE:Lerp(DANGER, k)
		eyeL.Part.Color = c eyeR.Part.Color = c
		eyeLight.Color = VIOLET:Lerp(DANGER, k)
		eyeLight.Brightness = eyeBrightness(lastFade or 1)
		local claw = DEEP:Lerp(DANGER, k * .8)
		for _, arm in ipairs(arms) do
			for _, f in ipairs(arm.Fingers) do f.Part.Color = claw end
		end
	end

	 
	 
	function ghost.Cut() cut = true pendingClear = true end

	function ghost.Update(pivot, time, fade)
		root.CFrame = pivot
		pose = pivot
		fade = math.clamp(fade or 0, 0, 1)

		 
		local pos = pivot.Position
		if lastPos and time > lastTime and time - lastTime < .5 then
			local dt = time - lastTime
			local v = ((pos - lastPos) * Vector3.new(1, 0, 1)).Magnitude / dt
			if v < 90 then speed = speed + (math.min(v, 40) - speed) * math.min(dt * 8, 1) end
		end
		lastPos, lastTime = pos, time
		local lean = math.clamp(speed / 26, 0, 1)

		local sink = fade * fade * 4  
		local base = pivot * CFrame.new(0, math.sin(time * 2.1) * .22 - sink, 0)
			* CFrame.Angles(-lean * .26, 0, math.sin(time * 1.7) * .03)
		local top = base

		put(hem, base * CFrame.new(0, -1.3, .1))
		put(robe, base * CFrame.new(0, .7, 0))
		put(chest, top * CFrame.new(0, 3, 0))
		local hoodCF = top * CFrame.new(0, 5.3, -.1) * CFrame.Angles(-.18 - lean * .12, 0, 0)
		put(hood, hoodCF)
		put(aura, base * CFrame.new(0, 2.4, 0))
		put(eyeL, hoodCF * CFrame.new(-.55, .1, -1.17) * CFrame.Angles(0, 0, -.3))
		put(eyeR, hoodCF * CFrame.new(.55, .1, -1.17) * CFrame.Angles(0, 0, .3))

		 
		for _, arm in ipairs(arms) do
			local s = arm.Side
			local pitch = lerp(.3, 1.2, lean) + math.sin(time * 3.1 + s * 1.3) * .08
			local roll = lerp(.4, .22, lean)
			local elbow = lerp(.7, .2, lean) + math.sin(time * 2.3 + s) * .06
			local shoulder = top * CFrame.new(s * 1.75, 3.9, 0) * CFrame.Angles(pitch, 0, s * roll)
			put(arm.Upper, shoulder * CFrame.new(0, -1.5, 0))
			local elbowCF = shoulder * CFrame.new(0, -3, 0) * CFrame.Angles(elbow, 0, 0)
			put(arm.Fore, elbowCF * CFrame.new(0, -1.7, 0))
			local wrist = elbowCF * CFrame.new(0, -3.4, 0)
			local curl = .2 + (.25 + .3 * (.5 + .5 * math.sin(time * 5 + s * 2))) * lean
			for i, f in ipairs(arm.Fingers) do
				put(f, wrist * CFrame.Angles(curl, 0, (i - 2) * .42) * CFrame.new(0, -.9, 0))
			end
		end

		for i, rb in ipairs(ribbons) do
			local sweep = -(.12 + lean * .85 + math.sin(time * 3 + i * 1.4) * .1)
			put(rb, top * CFrame.new((i - 2) * .95, 3.9, 1) * CFrame.Angles(sweep, 0, math.sin(time * 2.2 + i) * .06)
				* CFrame.new(0, -2.2, 0))
		end

		if fade ~= lastFade then
			lastFade = fade
			for _, rec in ipairs(recs) do rec.Part.Transparency = rec.Alpha + (1 - rec.Alpha) * fade end
			eyeLight.Brightness = eyeBrightness(fade)
		end
		local live = not cut and fade < .55
		if live ~= lastLive then
			lastLive = live
			smoke.Enabled = live embers.Enabled = live
			for _, arm in ipairs(arms) do arm.Trail.Enabled = live end
		end
		if pendingClear then
			pendingClear = false
			for _, arm in ipairs(arms) do arm.Trail:Clear() end
		end
	end

	ghost.Update(frame, 0, 1)
	return ghost
end

local function thornHeight(t)  
	if t <= 0 then return 0 end
	if t < .12 then return 1 - (1 - t / .12) ^ 3 end
	if t < .30 then return 1 end
	if t < .68 then
		local u = (t - .30) / .38
		return 1 - u * u
	end
	return 0
end

 
 
 
function V.ShadowBlast(cast, parent, point, ground, radius, now, rng)
	local model = cast:Add(Instance.new("Model"))
	model.Name = "ShadowBlast" model.Parent = parent
	local st = {Model = model, Born = now, Radius = radius, Point = point, Thorns = {}, Shards = {}}
	local origin = CFrame.new(point)
	st.Core = solid(model, "Core", Vector3.one, PALE, 0, nil, nil, Enum.PartType.Ball)
	st.Void = solid(model, "Void", Vector3.one, VOID, .35, nil, nil, Enum.PartType.Ball)
	st.Shell = solid(model, "Shell", Vector3.one, VIOLET, .1, Enum.Material.ForceField, nil, Enum.PartType.Ball)
	st.Core.CFrame = origin st.Void.CFrame = origin st.Shell.CFrame = origin
	st.Light = Instance.new("PointLight")
	st.Light.Color = PALE st.Light.Range = 36 st.Light.Brightness = 8 st.Light.Shadows = false
	st.Light.Parent = st.Core

	local layers = {
		{count = 4, r = .45, hmin = 5, hmax = 7.5, delay = 0},
		{count = 6, r = .82, hmin = 7, hmax = 10.5, delay = .07},
	}
	for _, layer in ipairs(layers) do
		local offset = rng:NextNumber(0, TAU)
		for i = 1, layer.count do
			local a = offset + (i - 1) * TAU / layer.count + rng:NextNumber(-.15, .15)
			local out = V3(math.cos(a), 0, math.sin(a))
			local pos = ground + out * (radius * layer.r)
			local part = solid(model, "Thorn", V3(.7, 1, 1.3), DEEP, 1, nil, nil, nil, "WedgePart")
			st.Thorns[#st.Thorns+1] = {
				Part = part,
				Base = CFrame.lookAt(pos, pos + out) * CFrame.Angles(-rng:NextNumber(.1, .3), 0, 0),
				Height = rng:NextNumber(layer.hmin, layer.hmax),
				Delay = layer.delay + rng:NextNumber(0, .04),
			}
		end
	end

	for i = 1, 10 do
		local a = (i - 1) * TAU / 10 + rng:NextNumber(-.2, .2)
		local vel = V3(math.cos(a), rng:NextNumber(.25, .7), math.sin(a)).Unit * rng:NextNumber(26, 46)
		st.Shards[i] = {Part = solid(model, "Blade", V3(.18, .18, 2.4), i % 2 == 0 and VIOLET or PALE, 0), Vel = vel}
	end
	return st
end

function V.UpdateShadowBlast(st, now)
	local age = now - st.Born
	if age >= .75 then
		if not st.Done then
			st.Done = true
			for _, d in ipairs(st.Model:GetChildren()) do
				if d:IsA("BasePart") then d.Transparency = 1 end
			end
			st.Light.Brightness = 0
		end
		return false  
	end
	local a = age / .75

	local ca = math.clamp(age / .16, 0, 1)
	st.Core.Size = Vector3.one * lerp(3, st.Radius * 1.15, 1 - (1 - ca) ^ 3)
	st.Core.Transparency = ca
	st.Light.Brightness = 8 * (1 - ca)

	local va = math.clamp(age / .2, 0, 1)
	local diameter = math.max(.1, st.Radius * 2 * (1 - (1 - va) ^ 3))
	st.Void.Size = Vector3.one * diameter
	st.Void.Transparency = .35 + .65 * math.clamp((age - .1) / .5, 0, 1)
	st.Shell.Size = Vector3.one * math.max(.1, diameter * 1.18)
	st.Shell.Transparency = .15 + .85 * math.clamp((age - .06) / .62, 0, 1)

	for _, t in ipairs(st.Thorns) do
		local h = t.Height * thornHeight(age - t.Delay)
		if h < .08 then
			if t.Part.Transparency < 1 then t.Part.Transparency = 1 end
		else
			t.Part.Size = V3(.7, h, 1.3)
			t.Part.CFrame = t.Base * CFrame.new(0, h / 2, 0)
			if t.Part.Transparency ~= .08 then t.Part.Transparency = .08 end
		end
	end

	for _, sh in ipairs(st.Shards) do
		local p = st.Point + sh.Vel * age - Vector3.yAxis * 20 * age * age
		local v = sh.Vel - Vector3.yAxis * 40 * age
		local f = math.clamp((age - .3) / .4, 0, 1)
		local w = lerp(.18, .04, f)
		sh.Part.Size = V3(w, w, lerp(2.4, .6, a))
		sh.Part.CFrame = CFrame.lookAt(p, p + v)
		sh.Part.Transparency = f
	end
	return true
end

return V