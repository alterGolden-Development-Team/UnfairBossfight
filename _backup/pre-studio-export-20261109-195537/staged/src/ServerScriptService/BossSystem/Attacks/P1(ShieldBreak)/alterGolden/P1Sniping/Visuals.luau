local Style = require(script.Parent.Style)
local FX = require(script:FindFirstAncestor("BossSystem").Attacks.Shared.ShieldBreakVFX)
local Visuals = {}

local MUZZLE = CFrame.new(0, 0.05, -5.25)

 
local PIECES = {
	{ "Receiver", CFrame.new(0, 0, 0), Vector3.new(0.55, 0.72, 2.8), "Receiver", Enum.Material.Metal },
	{ "TopRail", CFrame.new(0, 0.38, -0.1), Vector3.new(0.6, 0.07, 2.7), "Gold", Enum.Material.Neon },
	{ "SideTrimR", CFrame.new(0.29, 0, -0.2), Vector3.new(0.04, 0.12, 2.2), "Bright", Enum.Material.Neon },
	{ "SideTrimL", CFrame.new(-0.29, 0, -0.2), Vector3.new(0.04, 0.12, 2.2), "Bright", Enum.Material.Neon },
	{ "Barrel", CFrame.new(0, 0.05, -3.05), Vector3.new(0.24, 0.24, 3.5), "Gold", Enum.Material.Metal },
	{ "BarrelLine", CFrame.new(0, 0.18, -3.05), Vector3.new(0.08, 0.04, 3.3), "Bright", Enum.Material.Neon },
	{ "Brake", CFrame.new(0, 0.05, -4.9), Vector3.new(0.46, 0.46, 0.62), "Receiver", Enum.Material.Metal },
	{ "BrakeRing", CFrame.new(0, 0.05, -4.75), Vector3.new(0.5, 0.5, 0.08), "Gold", Enum.Material.Neon },
	{ "MuzzleEye", CFrame.new(0, 0.05, -5.22), Vector3.new(0.3, 0.3, 0.05), "Aim", Enum.Material.Neon },
	{ "Stock", CFrame.new(0, -0.12, 1.85), Vector3.new(0.55, 0.85, 1.3), "Gold", Enum.Material.Metal },
	{ "StockPad", CFrame.new(0, -0.12, 2.53), Vector3.new(0.58, 0.9, 0.08), "Receiver", Enum.Material.Metal },
	{ "Grip", CFrame.new(0, -0.62, 0.55), Vector3.new(0.3, 0.72, 0.36), "Receiver", Enum.Material.Metal },
	{ "Mag", CFrame.new(0, -0.58, -0.45), Vector3.new(0.3, 0.62, 0.55), "Gold", Enum.Material.Metal },
	{ "MagGlow", CFrame.new(0, -0.58, -0.45), Vector3.new(0.32, 0.12, 0.57), "Bright", Enum.Material.Neon },
	{ "Scope", CFrame.new(0, 0.66, -0.3), Vector3.new(0.34, 0.34, 1.6), "Receiver", Enum.Material.Metal },
	{ "ScopeRingF", CFrame.new(0, 0.66, -0.95), Vector3.new(0.46, 0.46, 0.14), "Gold", Enum.Material.Neon },
	{ "ScopeRingB", CFrame.new(0, 0.66, 0.35), Vector3.new(0.46, 0.46, 0.14), "Gold", Enum.Material.Neon },
	{ "Lens", CFrame.new(0, 0.66, -1.11), Vector3.new(0.26, 0.26, 0.04), "Aim", Enum.Material.Neon },
}

local function frame(parent, props)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BorderSizePixel = 0
	for k, v in pairs(props) do
		f[k] = v
	end
	f.Parent = parent
	return f
end

function Visuals.Create(ctx, cast)
	local rifle = {}
	for _, spec in ipairs(PIECES) do
		local part = ctx.Part(cast, "GoldenSniper" .. spec[1], ctx.Root.CFrame, spec[3], Style[spec[4]], 1)
		part.Material = spec[5]
		table.insert(rifle, { Part = part, Offset = spec[2] })
	end
	 
	for i, item in ipairs(rifle) do
		cast:Schedule(i * 0.012, function()
			if item.Part.Parent then
				FX.Tween(item.Part, 0.16, { Transparency = 0 })
			end
		end)
	end

	local laser = ctx.Part(cast, "SniperAimLine", ctx.Root.CFrame, Vector3.one, Style.Aim, 0.1)
	local laserGlow = ctx.Part(cast, "SniperAimGlow", ctx.Root.CFrame, Vector3.one, Style.Aim, 0.8)

	local orb = ctx.Part(cast, "SniperChargeOrb", ctx.Root.CFrame, Vector3.one * 0.1, Style.Bright, 0.05)
	orb.Shape = Enum.PartType.Ball
	local orbLight = Instance.new("PointLight")
	orbLight.Color, orbLight.Range, orbLight.Brightness, orbLight.Shadows = Style.Aim, 14, 0, false
	orbLight.Parent = orb
	local converge = FX.Emitter(orb, {
		Color = FX.Grad(Style.Bright, Style.Aim),
		Size = FX.Seq(0.15, 0.4),
		Transparency = FX.Seq(1, 0.2, 0),
		Lifetime = NumberRange.new(0.35),
		Speed = NumberRange.new(-14),
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		Rate = 70,
	})

	 
	local anchor = ctx.Part(cast, "SniperReticleAnchor", ctx.Root.CFrame, Vector3.one * 0.2, Style.Aim, 1)
	local gui = Instance.new("BillboardGui")
	gui.Name = "SniperReticle"
	gui.Size = UDim2.fromScale(9, 9)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 400
	gui.Parent = anchor
	local spin = frame(gui, { Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
	local circle = frame(spin, { Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.8, 0.8), BackgroundTransparency = 1 })
	Instance.new("UICorner", circle).CornerRadius = UDim.new(0.5, 0)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Style.Aim
	stroke.Thickness = 2
	stroke.Parent = circle
	local ticks = {}
	for i = 0, 3 do
		local a = i * math.pi / 2
		ticks[i + 1] = frame(spin, {
			BackgroundColor3 = Style.Aim,
			Position = UDim2.fromScale(0.5 + math.cos(a) * 0.46, 0.5 + math.sin(a) * 0.46),
			Size = i % 2 == 0 and UDim2.new(0.16, 0, 0, 3) or UDim2.new(0, 3, 0.16, 0),
		})
	end
	local dot = frame(gui, { BackgroundColor3 = Style.Aim, Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.07, 0.07) })
	Instance.new("UICorner", dot).CornerRadius = UDim.new(0.5, 0)

	return {
		Rifle = rifle,
		Laser = laser,
		LaserGlow = laserGlow,
		Orb = orb,
		OrbLight = orbLight,
		Converge = converge,
		Reticle = { Anchor = anchor, Gui = gui, Spin = spin, Stroke = stroke, Dot = dot, Ticks = ticks },
		Frame = ctx.Root.CFrame,
		Recoil = 0,
		Glinted = false,
	}
end

local function placeRifle(view, at)
	view.Frame = at
	local kick = view.Recoil
	local recoil = CFrame.new(0, kick * 0.25, kick * 1.3) * CFrame.Angles(kick * 0.32, 0, 0)
	for _, item in ipairs(view.Rifle) do
		if item.Part.Parent then
			item.Part.CFrame = at * recoil * item.Offset
		end
	end
end

 
function Visuals.Aim(ctx, cast, view, aim, charge, target)
	local origin = (ctx.Root.CFrame * CFrame.new(1.1, 1, -0.7)).Position
	if (aim - origin).Magnitude < 0.01 then
		return false
	end
	local at = CFrame.lookAt(origin, aim)
	placeRifle(view, at)
	local muzzle = (at * MUZZLE).Position
	local wall = workspace:Raycast(muzzle, aim - muzzle, ctx.Filter())
	local finish = wall and wall.Position or aim
	local length = math.max(0.01, (finish - muzzle).Magnitude)
	local mid = CFrame.lookAt((muzzle + finish) / 2, finish)

	 
	local t = os.clock()
	local strobe = charge > 0.82 and math.floor(t * 30) % 2 == 0
	local core = 0.05 + 0.09 * charge
	view.Laser.CFrame = mid
	view.Laser.Size = Vector3.new(core, core, length)
	view.Laser.Color = strobe and Style.White or Style.Aim:Lerp(Style.AimHot, charge * 0.6)
	view.Laser.Transparency = 0.25 - 0.2 * charge
	local glow = 0.18 + 0.55 * charge + 0.08 * math.sin(t * 25)
	view.LaserGlow.CFrame = mid
	view.LaserGlow.Size = Vector3.new(glow, glow, length)
	view.LaserGlow.Transparency = 0.88 - 0.3 * charge

	local orbSize = 0.15 + 1.1 * charge ^ 1.6 + 0.08 * math.sin(t * 50)
	view.Orb.CFrame = CFrame.new(muzzle)
	view.Orb.Size = Vector3.one * math.max(orbSize, 0.05)
	view.OrbLight.Brightness = 1 + 6 * charge
	view.Converge.Rate = 40 + 120 * charge

	 
	if charge >= 0.8 and not view.Glinted then
		view.Glinted = true
		FX.Glint(ctx, cast, muzzle, Style.Aim, 6, 0.35, at)
		FX.Ring(ctx, cast, CFrame.lookAt(muzzle, finish), 5, 0.6, 0.3, Style.Bright, 0, 0.18)
	end

	local reticle = view.Reticle
	local hrp = target and target:FindFirstChild("HumanoidRootPart")
	reticle.Anchor.CFrame = CFrame.new(hrp and hrp.Position or aim)
	local closing = 9 - 5 * charge
	reticle.Gui.Size = UDim2.fromScale(closing, closing)
	reticle.Spin.Rotation = (t * (120 + 500 * charge)) % 360
	local col = strobe and Style.White or Style.Aim
	reticle.Stroke.Color = col
	reticle.Stroke.Thickness = 2 + 3 * charge
	reticle.Dot.BackgroundColor3 = col
	for _, tick in ipairs(reticle.Ticks) do
		tick.BackgroundColor3 = col
	end
	return muzzle
end

function Visuals.Fire(ctx, cast, shot, view, muzzle, finish, direction, hitCharacter)
	view.Laser.Transparency, view.LaserGlow.Transparency, view.Orb.Transparency = 1, 1, 1
	view.Converge.Enabled, view.OrbLight.Enabled = false, false
	view.Reticle.Gui.Enabled = false
	view.Recoil = 1
	cast:Step(function(dt)
		view.Recoil = math.max(0, view.Recoil - dt * 4.5)
		placeRifle(view, view.Frame)
		return view.Recoil > 0
	end)

	local up = math.abs(direction.Y) > 0.98 and Vector3.xAxis or Vector3.yAxis
	local aimFrame = CFrame.lookAt(muzzle, muzzle + direction, up)

	 
	FX.Flash(ctx, shot, muzzle, Style.White, 5, 0.12, 0)
	FX.Flash(ctx, shot, muzzle + direction * 1.5, Style.Gold, 8, 0.28, 0.25)
	for i = 0, 3 do
		local petal = FX.Temp(ctx, shot, "SniperMuzzlePetal",
			aimFrame * CFrame.Angles(0, 0, i * math.pi / 2 + math.pi / 4) * CFrame.new(0, 1.2, -0.6),
			Vector3.new(0.35, 2.6, 0.12), Style.Bright, 0, 0.2)
		FX.Tween(petal, 0.16, { Size = Vector3.new(0.02, 4.4, 0.02), Transparency = 1 })
	end
	local cone = FX.Temp(ctx, shot, "SniperMuzzleCone", aimFrame * CFrame.new(0, 0, -2.2), Vector3.new(0.8, 0.8, 4.2),
		Style.White, 0, 0.18)
	FX.Tween(cone, 0.14, { Size = Vector3.new(0.05, 0.05, 7), Transparency = 1 })
	FX.Ring(ctx, shot, aimFrame, 1, 10, 0.35, Style.Gold, 0, 0.45)
	FX.Ring(ctx, shot, aimFrame * CFrame.new(0, 0, -2.5), 0.5, 6, 0.25, Style.White, 0, 0.25)
	FX.Streaks(ctx, shot, muzzle, direction, Style.Gold, Style.White, 22, 18, 70, 140, 3.2)
	FX.Smoke(ctx, shot, muzzle, Color3.fromRGB(150, 140, 120), 3, 6, 9, 4)
	FX.Light(ctx, shot, muzzle, Style.Gold, 10, 26, 0.25)
	FX.Shake(ctx, muzzle, 70, 0.25, 0.35)

	 
	local shell = FX.Temp(ctx, shot, "SniperShell", CFrame.new(muzzle - direction * 4.5), Vector3.new(0.12, 0.12, 0.4),
		Style.Gold, 0, 0.9)
	shell.Material = Enum.Material.Metal
	local vel = aimFrame.RightVector * 14 + Vector3.new(0, 18, 0) - direction * 3
	shot:Step(function(dt)
		if not shell.Parent then
			return false
		end
		vel += Vector3.new(0, -80 * dt, 0)
		shell.CFrame = (shell.CFrame + vel * dt) * CFrame.Angles(dt * 20, dt * 13, 0)
		return true
	end)

	 
	local length = (finish - muzzle).Magnitude
	FX.Beam(ctx, shot, muzzle, finish, 2.6, Style.Gold, Style.White, 0.5)
	FX.Beam(ctx, shot, muzzle, finish, 0.35, Style.Bright, Style.White, 1.1)
	local rings = math.clamp(math.floor(length / 7), 3, 26)
	for i = 1, rings do
		local d = i / rings * length
		local at = muzzle + direction * d
		shot:Schedule(d / 900, function()
			FX.Ring(ctx, shot, CFrame.lookAt(at, at + direction, up) * CFrame.Angles(0, 0, i * 0.5), 1.4, 4.5 + (i % 3),
				0.3, i % 2 == 0 and Style.Gold or Style.Bright, 0.05, 0.22, 10)
		end)
	end
	for i = 1, math.min(8, rings) do
		FX.Streaks(ctx, shot, muzzle + direction * (i / 8 * length), direction, Style.Gold, Style.White, 5, 60, 25, 50, 1.6)
	end

	 
	local floor = FX.Floor(ctx, finish, 8)
	local big = hitCharacter ~= nil
	FX.Impact(ctx, shot, finish, Style.Gold, Style.White, big and 1.35 or 1, {
		Direction = -direction,
		Spread = 70,
		Ground = floor,
		Shake = big and 0.75 or 0.45,
		Tint = big and 0.7 or 0.3,
	})
	FX.Flash(ctx, shot, finish, Style.Aim, 4, 0.1, 0.2)
	FX.Ring(ctx, shot, CFrame.lookAt(finish, finish - direction, up), 1, 16, 0.4, Style.Bright, 0, 0.5)
	if floor then
		FX.Spikes(ctx, shot, floor.Position, 7, 3.2, 5.5, Style.Gold, Style.White, 0.75, 30)
		FX.Debris(ctx, shot, floor.Position + Vector3.new(0, 0.5, 0), 8, Style.Deep, 0.55, 34, Enum.Material.Metal, 0.9)
		local scorch = FX.Temp(ctx, shot, "SniperScorch", floor * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.05, 7, 7),
			Style.Deep, 0.35, 1.4)
		scorch.Shape = Enum.PartType.Cylinder
		FX.Tween(scorch, 1.3, { Transparency = 1, Size = Vector3.new(0.05, 4, 4) })
	end
end

 
function Visuals.Dissolve(ctx, cast, view, duration)
	for _, item in ipairs(view.Rifle) do
		if item.Part.Parent then
			FX.Tween(item.Part, duration, { Transparency = 1 })
		end
	end
	local anchor = FX.Anchor(ctx, cast, view.Frame, duration + 0.6)
	FX.Emitter(anchor, {
		Color = FX.Grad(Style.Bright, Style.Gold),
		Size = FX.Seq(0.3, 0),
		Transparency = FX.Seq(0, 1),
		Lifetime = NumberRange.new(0.4, 0.7),
		Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(180, 180),
		Acceleration = Vector3.new(0, 6, 0),
	}):Emit(24)
end

return Visuals
