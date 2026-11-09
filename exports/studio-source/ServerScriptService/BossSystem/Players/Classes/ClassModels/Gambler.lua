local Shared = require(script.Parent.Shared)
local rgb, NEON, FABRIC, BALL, CYL, holder, piece, glow, trail, R, rad, W, GRIP, sin, cos, swingTrail, tipAttachment = Shared.rgb, Shared.NEON, Shared.FABRIC, Shared.BALL, Shared.CYL, Shared.holder, Shared.piece, Shared.glow, Shared.trail, Shared.R, Shared.rad, Shared.W, Shared.GRIP, Shared.sin, Shared.cos, Shared.swingTrail, Shared.tipAttachment
local V2 = {}

do
	local RunService = game:GetService("RunService")

	local QUALITY              = 3
	local DIE_RADIUS           = 0.85
	local ALLOW_SERVER_AMBIENT = false
	local USE_W                = true

	local TAU = math.pi * 2

	local function C(r, g, b) return Color3.fromRGB(r, g, b) end
	local C_GOLD   = C(232, 190, 64)
	local C_EMBER  = C(255, 208, 102)
	local C_STEEL  = C(44, 48, 60)
	local C_BLUED  = C(24, 26, 33)
	local C_NICKEL = C(206, 211, 221)
	local C_PEARL  = C(241, 233, 213)
	local C_RUBY   = C(192, 30, 48)
	local C_RUBY_D = C(146, 18, 34)
	local C_INK    = C(30, 16, 10)
	local C_BLACK  = C(8, 8, 10)

	local MET, NEON, GLASS, SMOOTH = Enum.Material.Metal, Enum.Material.Neon, Enum.Material.Glass, Enum.Material.SmoothPlastic
	local CYLS, BALL = Enum.PartType.Cylinder, Enum.PartType.Ball

	local function make(class, parent, name, size, color, mat, cf, shape, trans)
		local p = Instance.new(class)
		p.Name = name
		if shape then p.Shape = shape end
		p.Size = size
		p.Color = color
		p.Material = mat
		p.Transparency = trans or 0
		p.Anchored = false
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.CastShadow = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CFrame = cf
		p.Parent = parent
		return p
	end

	local function weld(p0, p1, c0, name)
		local w = Instance.new("Weld")
		w.Name = name or "Weld"
		w.Part0 = p0
		w.Part1 = p1
		w.C0 = c0
		w.C1 = CFrame.new()
		w.Parent = p1
		return w
	end

	local function attach(root, parent, name, size, color, mat, rel, shape, trans, class)
		local p = make(class or "Part", parent, name, size, color, mat, root.CFrame * rel, shape, trans)
		return p, weld(root, p, rel)
	end

	local function newGroup(parent, limb, name, base, pose)
		pose = pose or base
		local hub = make("Part", parent, name .. "Hub", Vector3.new(0.04, 0.04, 0.04), C_BLUED, SMOOTH, limb.CFrame * pose, nil, 1)
		local g = { hub = hub, base = base, joint = weld(limb, hub, pose, name .. "Joint") }
		function g.add(pname, size, color, mat, rel, shape, trans)
			return attach(hub, parent, pname, size, color, mat, rel, shape, trans)
		end
		return g
	end

	local function lerp(a, b, t) return a + (b - a) * t end

	local ease = {
		outQuad   = function(t) return 1 - (1 - t) * (1 - t) end,
		inQuad    = function(t) return t * t end,
		outCubic  = function(t) return 1 - (1 - t) ^ 3 end,
		outQuart  = function(t) return 1 - (1 - t) ^ 4 end,
		inOutSine = function(t) return -(math.cos(math.pi * t) - 1) / 2 end,
		outBack   = function(t)
			local c1, c3 = 1.70158, 2.70158
			return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
		end,
	}

	local function makeAnimator(conns)
		return function(duration, curve, step, done)
			local started = os.clock()
			local conn
			conn = RunService.Heartbeat:Connect(function()
				local a = math.min((os.clock() - started) / duration, 1)
				step(curve(a))
				if a >= 1 then
					conn:Disconnect()
					conns[conn] = nil
					if done then done() end
				end
			end)
			conns[conn] = true
		end
	end

	local THICK = 0.014

	local function triangle(root, parent, a, b, c, color, mat, trans, name)
		local ab, ac, bc = b - a, c - a, c - b
		local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
		if abd > acd and abd > bcd then
			c, a = a, c
		elseif acd > bcd and acd > abd then
			a, b = b, a
		end
		ab, ac, bc = b - a, c - a, c - b
		local right = ac:Cross(ab).Unit
		local up = bc:Cross(right).Unit
		local back = bc.Unit
		local height = math.abs(ab:Dot(up))
		local s1 = math.max(math.abs(ab:Dot(back)), 0.002)
		local s2 = math.max(math.abs(ac:Dot(back)), 0.002)
		attach(root, parent, name, Vector3.new(THICK, height, s1), color, mat,
			CFrame.fromMatrix((a + b) / 2, right, up, back), nil, trans, "WedgePart")
		attach(root, parent, name, Vector3.new(THICK, height, s2), color, mat,
			CFrame.fromMatrix((a + c) / 2, -right, up, -back), nil, trans, "WedgePart")
	end

	local function d20Geometry(radius)
		local phi = (1 + math.sqrt(5)) / 2
		local raw = {
			{ -1, phi, 0 }, { 1, phi, 0 }, { -1, -phi, 0 }, { 1, -phi, 0 },
			{ 0, -1, phi }, { 0, 1, phi }, { 0, -1, -phi }, { 0, 1, -phi },
			{ phi, 0, -1 }, { phi, 0, 1 }, { -phi, 0, -1 }, { -phi, 0, 1 },
		}
		local k = radius / math.sqrt(1 + phi * phi)
		local V = {}
		for i, v in ipairs(raw) do V[i] = Vector3.new(v[1] * k, v[2] * k, v[3] * k) end

		local edgeLen = 2 * k
		local adj, E = {}, {}
		for i = 1, 12 do adj[i] = {} end
		for i = 1, 11 do
			for j = i + 1, 12 do
				if math.abs((V[i] - V[j]).Magnitude - edgeLen) < edgeLen * 0.01 then
					adj[i][j] = true
					adj[j][i] = true
					E[#E + 1] = { i, j }
				end
			end
		end
		local F = {}
		for i = 1, 10 do
			for j = i + 1, 11 do
				if adj[i][j] then
					for m = j + 1, 12 do
						if adj[i][m] and adj[j][m] then
							F[#F + 1] = { a = V[i], b = V[j], c = V[m] }
						end
					end
				end
			end
		end
		for _, f in ipairs(F) do
			local n = (f.b - f.a):Cross(f.c - f.a)
			f.center = (f.a + f.b + f.c) / 3
			if n:Dot(f.center) < 0 then
				f.b, f.c = f.c, f.b
				n = -n
			end
			f.normal = n.Unit
		end

		local order = {}
		for i = 1, #F do order[i] = i end
		table.sort(order, function(p, q)
			local np, nq = F[p].normal, F[q].normal
			if math.abs(np.Y - nq.Y) > 1e-4 then return np.Y > nq.Y end
			if math.abs(np.X - nq.X) > 1e-4 then return np.X < nq.X end
			return np.Z < nq.Z
		end)
		local opposite = {}
		for i = 1, #F do
			for j = 1, #F do
				if i ~= j and F[i].normal:Dot(F[j].normal) < -0.99 then opposite[i] = j end
			end
		end
		local highs = { 20, 12, 18, 14, 16, 11, 19, 13, 17, 15 }
		local used = 0
		for _, i in ipairs(order) do
			if not F[i].number then
				used = used + 1
				local hi = highs[used]
				local flip = (used % 2 == 0)
				F[i].number = flip and (21 - hi) or hi
				F[opposite[i]].number = flip and hi or (21 - hi)
			end
		end
		return V, E, F, edgeLen
	end

	local function numeral(plate, text, color)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 400
		gui.LightInfluence = 0
		gui.Parent = plate
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = Enum.Font.GothamBlack
		label.RichText = true
		label.TextScaled = true
		label.TextColor3 = color
		label.Text = text
		label.Parent = gui
	end

	local function buildGun(char, G, rig, animate)
		local limb = char:FindFirstChild("Right Arm")
		if not limb then return end
		local parent = holder(char)

		local BY, CY = 0.28, 0.12
		local ZR = R(0, rad(90), 0)

		local function gp(name, size, color, mat, cf, shape)
			local p = piece(char, "Right Arm", size, color, mat, G * cf, shape, name)
			if p and USE_W then W(p) end
			return p
		end

		gp("GunShield",   Vector3.new(0.40, 0.52, 0.18), C_STEEL, MET, CFrame.new(0, 0.14, 0.04))
		gp("GunRearPlate", Vector3.new(0.18, 0.30, 0.05), C_STEEL, MET, CFrame.new(0, 0.20, 0.155))
		gp("GunTang",     Vector3.new(0.18, 0.15, 0.24), C_STEEL, MET, CFrame.new(0, 0.10, 0.22))
		gp("GunFrameLow", Vector3.new(0.34, 0.16, 0.74), C_STEEL, MET, CFrame.new(0, -0.22, -0.24))
		gp("GunFrame",    Vector3.new(0.26, 0.06, 0.80), C_STEEL, MET, CFrame.new(0, 0.40, -0.23))
		gp("GunBoss",     Vector3.new(0.27, 0.54, 0.14), C_STEEL, MET, CFrame.new(0, 0.13, -0.68))
		gp("GunHammerPin", Vector3.new(0.22, 0.05, 0.05), C_GOLD, MET, CFrame.new(0, 0.21, 0.21), CYL)
		gp("GunGate",     Vector3.new(0.03, 0.26, 0.17), C_NICKEL, MET, CFrame.new(0.212, 0.08, 0.035))
		gp("GunGateScrew", Vector3.new(0.02, 0.05, 0.05), C_GOLD, MET, CFrame.new(0.228, 0.11, 0.035), CYL)

		gp("GunBarrel",   Vector3.new(1.14, 0.19, 0.19), C_STEEL, MET, CFrame.new(0, BY, -1.30) * ZR, CYL)
		gp("GunCollar",   Vector3.new(0.14, 0.25, 0.25), C_NICKEL, MET, CFrame.new(0, BY, -0.82) * ZR, CYL)
		gp("GunRib",      Vector3.new(0.045, 0.02, 0.86), C_GOLD, MET, CFrame.new(0, BY + 0.099, -1.28))
		gp("GunRod",      Vector3.new(0.62, 0.095, 0.095), C_BLUED, MET, CFrame.new(0.085, 0.125, -1.06) * ZR, CYL)
		gp("GunRodTip",   Vector3.new(0.05, 0.12, 0.12), C_GOLD, MET, CFrame.new(0.085, 0.125, -1.39) * ZR, CYL)
		gp("GunSightBase", Vector3.new(0.07, 0.035, 0.17), C_STEEL, MET, CFrame.new(0, BY + 0.11, -1.74))
		gp("GunSight",    Vector3.new(0.035, 0.08, 0.06), C_GOLD, MET, CFrame.new(0, BY + 0.155, -1.77))
		gp("GunSightRear", Vector3.new(0.15, 0.04, 0.09), C_STEEL, MET, CFrame.new(0, 0.455, 0.12))
		gp("GunTopLine",  Vector3.new(0.035, 0.012, 0.60), C_GOLD, MET, CFrame.new(0, 0.434, -0.22))
		gp("GunBore",     Vector3.new(0.02, 0.12, 0.12), C_BLACK, SMOOTH, CFrame.new(0, BY, -1.975) * ZR, CYL)
		local muzzle = gp("GunMuzzle", Vector3.new(0.10, 0.22, 0.22), C_GOLD, MET, CFrame.new(0, BY, -1.92) * R(0, rad(90), 0), CYL)
		tipAttachment(muzzle)
		swingTrail(muzzle, Vector3.new(0, 0.12, 0), Vector3.new(0, -0.12, 0), C_GOLD, rgb(255, 255, 255), 0.12)

		gp("GunGuard",      Vector3.new(0.045, 0.045, 0.42), C_GOLD, MET, CFrame.new(0, -0.43, -0.09))
		gp("GunGuardFront", Vector3.new(0.045, 0.14, 0.045), C_GOLD, MET, CFrame.new(0, -0.37, -0.30))
		gp("GunGuardBend",  Vector3.new(0.045, 0.075, 0.075), C_GOLD, MET, CFrame.new(0, -0.43, -0.30), CYL)

		local GR = CFrame.new(0, -0.20, 0.19) * R(rad(-18), 0, 0)
		gp("GunGrip",       Vector3.new(0.15, 0.62, 0.27), C_STEEL, MET, GR)
		gp("GunBackstrap",  Vector3.new(0.16, 0.56, 0.035), C_GOLD, MET, GR * CFrame.new(0, 0, 0.1525))
		gp("GunButt",       Vector3.new(0.30, 0.05, 0.33), C_GOLD, MET, GR * CFrame.new(0, -0.325, 0.01))
		local plateR = gp("GunGripPlateR", Vector3.new(0.07, 0.60, 0.29), C_PEARL, SMOOTH, GR * CFrame.new(0.108, 0, 0))
		local plateL = gp("GunGripPlateL", Vector3.new(0.07, 0.60, 0.29), C_PEARL, SMOOTH, GR * CFrame.new(-0.108, 0, 0))
		if plateR then plateR.Reflectance = 0.06 end
		if plateL then plateL.Reflectance = 0.06 end

		if QUALITY >= 2 then
			for _, side in ipairs({ 1, -1 }) do
				gp("GunGripScrew", Vector3.new(0.02, 0.05, 0.05), C_GOLD, MET, GR * CFrame.new(side * 0.147, 0.22, 0), CYL)
				gp("GunFrameInlay", Vector3.new(0.012, 0.018, 0.62), C_GOLD, MET, CFrame.new(side * 0.176, -0.22, -0.26))
			end
			local function suit(kind, side, color, mat)
				local x, s, cy = side * 0.1495, 0.10, 0.04
				local d = s * 0.7071
				local lobeY = (kind == "spade") and -d / 2 or d / 2
				gp(kind .. "Body", Vector3.new(0.012, s, s), color, mat, GR * CFrame.new(x, cy, 0) * R(rad(45), 0, 0))
				for _, z in ipairs({ -d / 2, d / 2 }) do
					gp(kind .. "Lobe", Vector3.new(0.012, s, s), color, mat, GR * CFrame.new(x, cy + lobeY, z), CYL)
				end
				if kind == "spade" then
					gp("spadeStem", Vector3.new(0.012, 0.06, 0.03), color, mat, GR * CFrame.new(x, cy - d - 0.02, 0))
				end
			end
			suit("spade", 1, C_GOLD, MET)
			suit("heart", -1, C_RUBY, SMOOTH)
		end

		local cyl = newGroup(parent, limb, "GunCylinder", G * CFrame.new(0, CY, -0.33))
		cyl.add("GunDrum", Vector3.new(0.56, 0.50, 0.50), C_STEEL, MET, ZR, CYLS)
		cyl.add("GunDrumFront", Vector3.new(0.035, 0.53, 0.53), C_GOLD, MET, CFrame.new(0, 0, -0.27) * ZR, CYLS)
		cyl.add("GunDrumRear", Vector3.new(0.035, 0.53, 0.53), C_GOLD, MET, CFrame.new(0, 0, 0.27) * ZR, CYLS)
		if QUALITY >= 2 then
			for k = 0, 5 do
				local a = rad(30 + 60 * k)
				cyl.add("GunFlute", Vector3.new(0.07, 0.022, 0.44), C_NICKEL, MET, R(0, 0, -a) * CFrame.new(0, 0.256, 0))
			end
		end

		local COCKED, RESTED, PULL = rad(46), rad(7), rad(-24)
		local hamBase = G * CFrame.new(0, 0.21, 0.21)
		local ham = newGroup(parent, limb, "GunHammer", hamBase, hamBase * R(COCKED, 0, 0))
		ham.add("GunHammer", Vector3.new(0.075, 0.28, 0.075), C_BLUED, MET, CFrame.new(0, 0.14, 0))
		ham.add("GunHammerNose", Vector3.new(0.07, 0.07, 0.10), C_BLUED, MET, CFrame.new(0, 0.05, -0.07))
		local spurCF = CFrame.new(0, 0.285, 0.07) * R(rad(-16), 0, 0)
		ham.add("GunSpur", Vector3.new(0.09, 0.045, 0.18), C_GOLD, MET, spurCF)
		if QUALITY >= 2 then
			for k = 1, 3 do
				ham.add("GunSpurGrip", Vector3.new(0.095, 0.012, 0.02), C_BLUED, MET, spurCF * CFrame.new(0, 0.026, (k - 2) * 0.045))
			end
		end

		local trg = newGroup(parent, limb, "GunTrigger", G * CFrame.new(0, -0.29, 0))
		trg.add("GunTrigger", Vector3.new(0.04, 0.115, 0.05), C_NICKEL, MET, CFrame.new(0, -0.0575, 0) * R(rad(10), 0, 0))

		local flashCF = G * CFrame.new(0, BY, -2.08)
		local flash = make("Part", parent, "GunFlash", Vector3.new(0.5, 0.5, 0.5), C_EMBER, NEON, limb.CFrame * flashCF, BALL, 1)
		weld(limb, flash, flashCF, "GunFlashWeld")
		local flashLight, sparks, smoke
		if flash then
			flash.Transparency = 1
			flashLight = Instance.new("PointLight")
			flashLight.Color = C_EMBER
			flashLight.Range = 14
			flashLight.Brightness = 0
			flashLight.Parent = flash

			sparks = Instance.new("ParticleEmitter")
			sparks.Rate = 0
			sparks.EmissionDirection = Enum.NormalId.Front
			sparks.Speed = NumberRange.new(14, 26)
			sparks.SpreadAngle = Vector2.new(22, 22)
			sparks.Lifetime = NumberRange.new(0.12, 0.28)
			sparks.Drag = 4
			sparks.Acceleration = Vector3.new(0, -12, 0)
			sparks.LightEmission = 1
			sparks.Color = ColorSequence.new(C_EMBER, C_GOLD)
			sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.16), NumberSequenceKeypoint.new(1, 0) })
			sparks.Parent = flash

			smoke = Instance.new("ParticleEmitter")
			smoke.Rate = 0
			smoke.EmissionDirection = Enum.NormalId.Front
			smoke.Speed = NumberRange.new(2, 5)
			smoke.SpreadAngle = Vector2.new(18, 18)
			smoke.Lifetime = NumberRange.new(0.5, 0.9)
			smoke.RotSpeed = NumberRange.new(-40, 40)
			smoke.Acceleration = Vector3.new(0, 2.5, 0)
			smoke.Color = ColorSequence.new(C(150, 150, 156))
			smoke.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1.1) })
			smoke.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 1) })
			smoke.Parent = flash
		end

		local state = { ham = COCKED, trig = 0, cyl = 0, cylTarget = 0 }
		local function setHam(a) state.ham = a; ham.joint.C0 = ham.base * R(a, 0, 0) end
		local function setTrig(a) state.trig = a; trg.joint.C0 = trg.base * R(a, 0, 0) end
		local function setCyl(a) state.cyl = a; cyl.joint.C0 = cyl.base * R(0, 0, a) end

		local function muzzleFlash()
			if not flash then return end
			flash.Transparency = 0.15
			if flashLight then flashLight.Brightness = 6 end
			sparks:Emit(9)
			smoke:Emit(4)
			animate(0.12, ease.outQuad, function(a)
				flash.Transparency = lerp(0.15, 1, a)
				local s = lerp(0.5, 0.95, a)
				flash.Size = Vector3.new(s, s, s)
				if flashLight then flashLight.Brightness = 6 * (1 - a) end
			end)
		end

		local function fire()
			local h0 = state.ham
			state.cylTarget = state.cylTarget - rad(60)
			local c0, c1 = state.cyl, state.cylTarget
			animate(0.05, ease.outQuad, function(a) setTrig(PULL * a) end)
			animate(0.055, ease.inQuad, function(a) setHam(lerp(h0, RESTED, a)) end, function()
				muzzleFlash()
				animate(0.20, ease.outBack, function(a) setHam(lerp(RESTED, COCKED, a)) end)
				animate(0.18, ease.outCubic, function(a) setCyl(lerp(c0, c1, a)) end)
				animate(0.14, ease.outQuad, function(a) setTrig(PULL * (1 - a)) end)
			end)
		end

		rig.Fire = fire
		function rig.Fan(n, gap)
			n = n or 4
			gap = gap or 0.07
			for i = 0, n - 1 do
				if i == 0 then fire() else task.delay(i * gap, fire) end
			end
		end
		function rig.Spin(duration, turns)
			local from = state.cyl
			state.cylTarget = from - TAU * (turns or 3)
			local to = state.cylTarget
			animate(duration or 1.3, ease.outQuart, function(a) setCyl(lerp(from, to, a)) end)
		end
		function rig.Cock(on)
			local from = state.ham
			local to = (on == false) and RESTED or COCKED
			animate(0.16, ease.outBack, function(a) setHam(lerp(from, to, a)) end)
		end

		rig.Muzzle = muzzle
		rig.Flash = flash
		rig.Gun = { Cylinder = cyl.joint, Hammer = ham.joint, Trigger = trg.joint, State = state }
	end

	local function buildDie(char, rig)
		local limb = char:FindFirstChild("Left Arm")
		if not limb then return end

		local model = Instance.new("Model")
		model.Name = "GamblerD20"
		model.Parent = holder(char)

		local base = GRIP * CFrame.new(0, 0.05, -0.35) * R(rad(20), rad(35), 0)
		local hover = newGroup(model, limb, "D20Hover", base)   -- floats / tosses / wobbles (never spins)
		model.PrimaryPart = hover.hub

		local coreSize = DIE_RADIUS * 0.62
		local core, spinJoint = attach(hover.hub, model, "D20Core", Vector3.new(coreSize, coreSize, coreSize), C_EMBER, NEON, CFrame.new(), BALL, 0)
		spinJoint.Name = "D20Spin"

		local V, E, F, edgeLen = d20Geometry(DIE_RADIUS)
		for i, f in ipairs(F) do
			local crit = (f.number == 20)
			local color = crit and C_EMBER or ((i % 2 == 0) and C_RUBY or C_RUBY_D)
			triangle(core, model, f.a, f.b, f.c, color, crit and NEON or GLASS, crit and 0.12 or 0.2, "D20Face" .. f.number)

			if QUALITY >= 3 then
				local toVertex = f.a - f.center
				local up = (toVertex - f.normal * toVertex:Dot(f.normal)).Unit
				local back = -f.normal
				local pos = f.center + f.normal * 0.016
				local plate = attach(core, model, "D20Num" .. f.number, Vector3.new(0.3, 0.3, 0.01), C_BLACK, SMOOTH,
					CFrame.fromMatrix(pos, up:Cross(back), up, back), nil, 1)
				local text = tostring(f.number)
				if f.number == 6 or f.number == 9 then text = "<u>" .. text .. "</u>" end
				numeral(plate, text, crit and C_INK or C_EMBER)
			end
		end

		if QUALITY >= 2 then
			for _, e in ipairs(E) do
				local a, b = V[e[1]], V[e[2]]
				local dir = (b - a).Unit
				local ref = (math.abs(dir.Y) < 0.95) and Vector3.new(0, 1, 0) or Vector3.new(1, 0, 0)
				local y = (ref - dir * ref:Dot(dir)).Unit
				local z = dir:Cross(y)
				attach(core, model, "D20Edge", Vector3.new(edgeLen + 0.03, 0.04, 0.04), C_GOLD, MET,
					CFrame.fromMatrix((a + b) / 2, dir, y, z), CYLS, 0)
			end
		end
		if QUALITY >= 3 then
			for _, v in ipairs(V) do
				attach(core, model, "D20Stud", Vector3.new(0.085, 0.085, 0.085), C_GOLD, MET, CFrame.new(v), BALL, 0)
			end
		end

		-- four suit tokens orbit the die (attached to the hover hub, so they do NOT spin with the die)
		local tokens = {}
		if QUALITY >= 3 then
			for k = 1, 4 do
				local _, j = hover.add("D20Token", Vector3.new(0.1, 0.1, 0.1), (k % 2 == 1) and C_GOLD or C_RUBY, NEON, CFrame.new(), nil, 0)
				tokens[k] = j
			end
		end

		glow(core, C_GOLD, 7, 1.2)
		local light = core:FindFirstChildWhichIsA("PointLight")

		local dust = Instance.new("ParticleEmitter")
		dust.Rate = 7
		dust.Lifetime = NumberRange.new(0.7, 1.3)
		dust.Speed = NumberRange.new(0.2, 0.7)
		dust.SpreadAngle = Vector2.new(180, 180)
		dust.Acceleration = Vector3.new(0, 0.8, 0)
		dust.LightEmission = 1
		dust.LockedToPart = true
		dust.Color = ColorSequence.new(C_EMBER)
		dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.09), NumberSequenceKeypoint.new(1, 0) })
		dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		dust.Parent = core

		local t0 = os.clock()
		local roll, critT
		local function stepDie()
			local now = os.clock()
			local t = now - t0
			local lift = Vector3.new(0, 0, 0)
			local tumble = CFrame.new()
			if roll then
				local a = (now - roll.t) / roll.dur
				if a >= 1 then
					roll = nil
				else
					lift = limb.CFrame:VectorToObjectSpace(Vector3.new(0, roll.height * 4 * a * (1 - a), 0))
					tumble = R(TAU * roll.turns * ease.inOutSine(a), 0, TAU * 0.5 * a)
				end
			end
			local extraSpin, heat = 0, 0
			if critT then
				local c = (now - critT) / 0.85
				if c >= 1 then
					critT = nil
				else
					extraSpin = TAU * 2 * ease.outCubic(c)
					heat = 1 - c
				end
			end
			hover.joint.C0 = CFrame.new(lift) * base
				* CFrame.new(0, math.sin(t * 2.2) * 0.05, 0)
				* R(math.sin(t * 1.6) * 0.10, 0, math.cos(t * 1.2) * 0.10)
				* tumble
			spinJoint.C0 = R(0, t * 0.9 + extraSpin, 0)
			if light then light.Brightness = 1.2 + math.sin(t * 3) * 0.25 + heat * 4.5 end
			for k = 1, #tokens do
				local ang = t * 1.35 + (k - 1) * TAU / #tokens
				tokens[k].C0 = R(rad(24), 0, rad(-14)) * R(0, ang, 0)
					* CFrame.new(DIE_RADIUS * 1.35, math.sin(ang * 2 + k) * 0.08, 0) * R(ang, ang * 0.7, 0)
			end
		end

		local ambient = RunService:IsClient() or ALLOW_SERVER_AMBIENT
		local loop
		local function startLoop()
			if loop then return end
			loop = RunService.Heartbeat:Connect(function()
				if not hover.hub.Parent then
					loop:Disconnect()
					loop = nil
					return
				end
				stepDie()
				if not ambient and not roll and not critT then
					loop:Disconnect()
					loop = nil
				end
			end)
		end

		stepDie()
		if ambient then startLoop() end

		function rig.Roll(height, turns, duration)
			roll = { t = os.clock(), dur = duration or 0.9, height = height or 1.8, turns = turns or 2 }
			startLoop()
		end
		function rig.Crit()
			critT = os.clock()
			startLoop()
		end
		function rig._stopDie()
			if loop then
				loop:Disconnect()
				loop = nil
			end
		end
		rig.Die = { Model = model, Core = core, Hover = hover.joint, Spin = spinJoint, Light = light }
	end

	V2.GamblerRigs = V2.GamblerRigs or setmetatable({}, { __mode = "k" })
	function V2.GetGamblerRig(char) return V2.GamblerRigs[char] end

	function V2.Gambler(char)
		local DARK, GOLD, RED, WHITE, WOODC = rgb(28, 28, 34), rgb(232, 190, 64), rgb(150, 30, 40), rgb(250, 250, 250), rgb(96, 58, 34)
		piece(char, "Head", Vector3.new(0.12, 2.5, 2.5), DARK, FABRIC, CFrame.new(0, 0.6, 0) * R(0, 0, rad(90)), CYL, "HatBrim")
		piece(char, "Head", Vector3.new(0.7, 1.35, 1.35), DARK, FABRIC, CFrame.new(0, 0.98, 0) * R(0, 0, rad(90)), CYL, "HatCrown")
		piece(char, "Head", Vector3.new(0.16, 1.38, 1.38), RED, FABRIC, CFrame.new(0, 0.74, 0) * R(0, 0, rad(90)), CYL, "HatBand")
		piece(char, "Head", Vector3.new(0.12, 0.16, 0.9), rgb(18, 18, 22), FABRIC, CFrame.new(0, 1.3, 0), nil, "HatPinch")
		piece(char, "Torso", Vector3.new(2.06, 2.04, 1.07), RED, FABRIC, CFrame.new(), nil, "Vest")
		piece(char, "Torso", Vector3.new(0.7, 1.6, 0.08), WHITE, FABRIC, CFrame.new(0, 0.2, -0.54), nil, "Shirt")
		piece(char, "Torso", Vector3.new(0.22, 1.1, 0.1), DARK, FABRIC, CFrame.new(0, 0.3, -0.58), nil, "Tie")
		for _, x in ipairs({ -0.55, 0.55 }) do
			piece(char, "Torso", Vector3.new(0.85, 1.5, 0.12), DARK, FABRIC, CFrame.new(x, -1.65, 0.52) * R(rad(-8), 0, 0), nil, "CoatTail")
		end

		local G = GRIP * R(rad(-90), 0, 0) * CFrame.new(0, 0, 0.35)
		local rig = { Char = char, _conns = {} }
		local animate = makeAnimator(rig._conns)
		buildGun(char, G, rig, animate)
		buildDie(char, rig)

		function rig.Destroy()
			for conn in pairs(rig._conns) do
				conn:Disconnect()
				rig._conns[conn] = nil
			end
			if rig._stopDie then rig._stopDie() end
		end

		V2.GamblerRigs[char] = rig
		return rig
	end
end

return V2.Gambler
