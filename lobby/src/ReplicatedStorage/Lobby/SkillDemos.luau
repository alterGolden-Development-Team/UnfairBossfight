--!nonstrict
-- What the showroom dummy does when you click a skill. These are short stylised previews of what each skill does, not the fight's real effects,
-- which live in the boss place and need a boss to hit. One small toolbox of effects, one line per skill.
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Demos = {}

local NEON = Enum.Material.Neon
local WHITE = Color3.new(1, 1, 1)
local token = 0
local fxFolder = nil

local function fxPart(size, cf, color, shape, material)
	local p = Instance.new("Part")
	if shape then p.Shape = shape end
	p.Size, p.CFrame, p.Color = size, cf, color
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Material = material or NEON
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = fxFolder
	return p
end

local function fade(p, time, goals)
	local g = goals or {}
	g.Transparency = 1
	TweenService:Create(p, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), g):Play()
	Debris:AddItem(p, time + 0.1)
end

local function arc(center, radius, from, to, color, width)
	local count = 12
	for i = 0, count do
		local a = math.rad(from + (to - from) * i / count)
		local cf = center * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -radius)
		local p = fxPart(Vector3.new(radius * 0.32, width or 0.16, 0.34), cf, color)
		task.delay(i * 0.011, function()
			fade(p, 0.28)
		end)
	end
end

local function ring(position, color, radius, time, thickness)
	local p = fxPart(Vector3.new(thickness or 0.2, 1, 1), CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.PartType.Cylinder)
	p.Transparency = 0.15
	fade(p, time or 0.5, { Size = Vector3.new(thickness or 0.2, radius * 2, radius * 2) })
end

local function dome(position, color, radius, hold)
	local p = fxPart(Vector3.new(1, 1, 1), CFrame.new(position), color, Enum.PartType.Ball, Enum.Material.ForceField)
	p.Transparency = 0.2
	TweenService:Create(p, TweenInfo.new(0.25), { Size = Vector3.new(radius, radius, radius) * 2 }):Play()
	task.delay(hold or 0.8, function()
		fade(p, 0.35)
	end)
end

local function pillar(position, color, height, width, time)
	local p = fxPart(Vector3.new(0.4, width or 2, width or 2), CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.PartType.Cylinder)
	p.Transparency = 0.3
	local goal = position + Vector3.new(0, height / 2, 0)
	fade(p, time or 0.7, { Size = Vector3.new(height, width or 2, width or 2), CFrame = CFrame.new(goal) * CFrame.Angles(0, 0, math.rad(90)) })
end

local function beam(from, to, color, width, time)
	local p = fxPart(Vector3.new(width, width, (to - from).Magnitude), CFrame.lookAt((from + to) / 2, to), color)
	fade(p, time or 0.25, { Size = Vector3.new(0.05, 0.05, (to - from).Magnitude) })
end

local function shot(from, to, color, size, time, onHit)
	local p = fxPart(Vector3.new(size, size, size), CFrame.new(from), color, Enum.PartType.Ball)
	local tween = TweenService:Create(p, TweenInfo.new(time or 0.22, Enum.EasingStyle.Linear), { CFrame = CFrame.new(to) })
	tween:Play()
	tween.Completed:Connect(function()
		p:Destroy()
		if onHit then onHit() end
	end)
end

local function ghost(cf, color)
	local p = fxPart(Vector3.new(2, 5, 1), cf, color)
	p.Transparency = 0.45
	fade(p, 0.45)
end

local function popText(position, text, color)
	local anchor = fxPart(Vector3.new(0.1, 0.1, 0.1), CFrame.new(position), color)
	anchor.Transparency = 1
	local gui = Instance.new("BillboardGui")
	gui.Size, gui.AlwaysOnTop = UDim2.fromOffset(140, 60), true
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency, label.Text = UDim2.fromScale(1, 1), 1, text
	label.Font, label.TextScaled, label.TextColor3 = Enum.Font.GothamBlack, true, color
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	Debris:AddItem(anchor, 1.4)
end

local function hurt(ctx, color)
	local t = ctx.dummyTarget
	if not t then return end
	local old = t.Color
	t.Color = color or WHITE
	task.delay(0.1, function()
		if t.Parent then t.Color = old end
	end)
end

local function ahead(ctx, distance, height)
	local p = ctx.rig.position
	local dir = (ctx.rig.target - p) * Vector3.new(1, 0, 1)
	return p + dir.Unit * distance + Vector3.new(0, height or 0, 0)
end

local function targetPos(ctx, height)
	return Vector3.new(ctx.rig.target.X, ctx.rig.position.Y + (height or 0), ctx.rig.target.Z)
end

local function plane(ctx, roll)
	local at = ahead(ctx, 2, 0.4)
	return CFrame.lookAt(at, targetPos(ctx, 0.4)) * CFrame.Angles(0, 0, roll or 0)
end

local function swing(ctx, color, roll, size, power)
	local r = ctx.rig
	r:pose({ RA = 2.6, RAo = -0.4, T = -0.4 }, 0.08)
	task.wait(0.09)
	r:pose({ RA = 0.9, RAo = 0.2, T = 0.5, Lean = 0.1 }, 0.09)
	arc(plane(ctx, roll), size or 3.4, -70, 70, color, power and 0.26 or 0.16)
	hurt(ctx, color)
	task.wait(0.14)
end

local function lunge(ctx, distance, time, afterimages, color)
	local r = ctx.rig
	local from = r.position
	local to = ahead(ctx, distance)
	r:move(CFrame.lookAt(to, targetPos(ctx)), time)
	if afterimages then
		for i = 1, afterimages do
			ghost(CFrame.lookAt(from:Lerp(to, i / (afterimages + 1)), targetPos(ctx)), color)
		end
	end
	task.wait(time)
end

local function back(ctx, time)
	ctx.rig:move(CFrame.lookAt(ctx.rig.position, targetPos(ctx)), time or 0.22)
	task.wait(time or 0.22)
end

local function raiseCast(ctx)
	ctx.rig:pose({ RA = 1.9, LA = 0.5, T = 0.1 }, 0.14)
	task.wait(0.15)
end

local function handPos(ctx)
	return ahead(ctx, 1.6, 1.2)
end

local function slashes(n, gap)
	return function(ctx, color)
		for i = 1, n do
			swing(ctx, color, (i % 2 == 0 and 0.7 or -0.7) + (i * 0.2))
			if gap then task.wait(gap) end
		end
	end
end

local function xSlash(ctx, color)
	ctx.rig:pose({ RA = 2.8, LA = 2.8, T = 0 }, 0.14)
	task.wait(0.15)
	ctx.rig:pose({ RA = 0.6, LA = 0.6, Lean = 0.2 }, 0.1)
	local start = ahead(ctx, 2, 0.6)
	local stop = targetPos(ctx, 0.6)
	for _, roll in { 0.85, -0.85 } do
		local cf = CFrame.lookAt(start, stop) * CFrame.Angles(0, 0, roll)
		arc(cf, 4, -80, 80, color, 0.3)
	end
	shot(start, stop, color, 1.5, 0.22, function()
		hurt(ctx, color)
		ring(stop, color, 4, 0.4)
	end)
	task.wait(0.3)
end

local function guardUp(ctx, color, radius, hold)
	ctx.rig:pose({ LA = 1.6, LAo = 0.2, RA = 0.2, Lean = 0.12 }, 0.12)
	dome(ctx.rig.position + Vector3.new(0, 0.6, 0), color, radius or 4.2, hold or 0.8)
	task.wait((hold or 0.8) + 0.2)
end

local function groundRing(ctx, color, radius)
	ring(ctx.rig.position - Vector3.new(0, 2.8, 0), color, radius or 9, 0.55)
end

Demos.Skills = {
	Warrior = {
		M1 = slashes(1),
		F = function(ctx, color)
			guardUp(ctx, Color3.fromRGB(240, 205, 120), 3.8, 0.55)
			ctx.rig:rest(0.1)
			task.wait(0.1)
			swing(ctx, color, 0.5)
		end,
		C = xSlash,
		V = function(ctx, color)
			lunge(ctx, 5, 0.14, 3, color)
			swing(ctx, color, -0.6, 3.6, true)
			back(ctx)
			ring(ctx.rig.position + Vector3.new(0, 1, 0), Color3.fromRGB(240, 205, 120), 6, 0.5)
		end,
	},
	Mage = {
		M1 = function(ctx, color)
			raiseCast(ctx)
			shot(handPos(ctx), targetPos(ctx, 1), color, 1, 0.24, function()
				hurt(ctx, color)
				ring(targetPos(ctx, 1), color, 3, 0.3)
			end)
			task.wait(0.3)
		end,
		F = function(ctx, color)
			local p = ctx.rig.position
			for i = 1, 6 do
				local a = i / 6 * 6.28
				shot(p + Vector3.new(math.cos(a) * 5, 1, math.sin(a) * 5), p + Vector3.new(0, 0.5, 0), color, 0.6, 0.2)
			end
			task.wait(0.2)
			lunge(ctx, 4.5, 0.12, 2, color)
			task.wait(0.15)
			back(ctx)
		end,
		C = function(ctx, color)
			raiseCast(ctx)
			local c = targetPos(ctx, 1)
			for i = 1, 10 do
				local a = i / 10 * 6.28
				local from = c + Vector3.new(math.cos(a) * 4, math.random(0, 4), math.sin(a) * 4)
				local orb = fxPart(Vector3.new(0.8, 0.8, 0.8), CFrame.new(from), color, Enum.PartType.Ball)
				task.delay(0.08 * i, function()
					fade(orb, 0.2, { Size = Vector3.new(3, 3, 3) })
					ring(from, color, 2, 0.25)
					hurt(ctx, color)
				end)
			end
			task.wait(1)
		end,
		V = function(ctx, color)
			raiseCast(ctx)
			local charge = fxPart(Vector3.new(0.4, 0.4, 0.4), CFrame.new(handPos(ctx)), color, Enum.PartType.Ball)
			TweenService:Create(charge, TweenInfo.new(0.6), { Size = Vector3.new(2.6, 2.6, 2.6) }):Play()
			task.wait(0.6)
			charge:Destroy()
			local from, to = handPos(ctx), targetPos(ctx, 1) + (targetPos(ctx, 1) - handPos(ctx)).Unit * 4
			for _ = 1, 16 do
				beam(from, to, color, 1.3, 0.1)
				hurt(ctx, color)
				task.wait(0.05)
			end
		end,
	},
	Tank = {
		M1 = function(ctx, color)
			lunge(ctx, 2.5, 0.12)
			ctx.rig:pose({ LA = 1.6, RA = 0.2, Lean = 0.25 }, 0.08)
			ring(ahead(ctx, 5, 1), color, 4, 0.3)
			hurt(ctx, color)
			task.wait(0.14)
			back(ctx)
		end,
		F = function(ctx, color)
			ctx.rig:pose({ LA = 1.6, RA = 1.6, Lean = 0.15 }, 0.15)
			dome(ctx.rig.position + Vector3.new(0, 0.6, 0), color, 4.5, 1.1)
			for i = 1, 3 do
				task.delay(i * 0.26, function()
					groundRing(ctx, color, 12)
				end)
			end
			task.wait(1.2)
			ring(ctx.rig.position, Color3.fromRGB(255, 240, 200), 9, 0.4, 0.6)
		end,
		C = function(ctx, color)
			ctx.rig:pose({ LA = 1.6, RA = 0.5, Lean = 0.35 }, 0.1)
			lunge(ctx, 7, 0.22, 4, color)
			ring(ahead(ctx, 9, 1), Color3.fromRGB(255, 240, 120), 5, 0.35)
			hurt(ctx, color)
			popText(targetPos(ctx, 4), "STUNNED", Color3.fromRGB(255, 240, 120))
			task.wait(0.3)
			back(ctx, 0.3)
		end,
		V = function(ctx, color)
			ctx.rig:pose({ LA = 2.6, RA = 2.6 }, 0.2)
			task.wait(0.15)
			dome(ctx.rig.position + Vector3.new(0, 0.6, 0), Color3.fromRGB(120, 210, 255), 7, 1.2)
			task.wait(1.4)
		end,
	},
	Supporter = {
		M1 = function(ctx, color)
			raiseCast(ctx)
			local c = ahead(ctx, 2, 0.8)
			for i = 1, 3 do
				task.delay(i * 0.1, function()
					ring(c:Lerp(targetPos(ctx, 0.8), i / 3), color, 2.4, 0.3)
				end)
			end
			task.wait(0.45)
			hurt(ctx, color)
		end,
		F = function(ctx, color)
			ctx.rig:pose({ RA = 2.8, LA = 2.8 }, 0.18)
			for i = 1, 4 do
				task.delay(i * 0.12, function()
					pillar(ctx.rig.position - Vector3.new(0, 2.5, 0), color, 9, 3 + i, 0.6)
				end)
			end
			task.wait(0.9)
		end,
		C = function(ctx, color)
			local ally = ahead(ctx, -6, 0)
			ghost(CFrame.new(ally), color)
			local from = ctx.rig.position + Vector3.new(0, 0.5, 0)
			for i = 1, 8 do
				task.delay(i * 0.04, function()
					local a = from:Lerp(ally, i / 8)
					beam(a, a + Vector3.new(0.4, 0.3, 0), Color3.fromRGB(150, 255, 210), 0.5, 0.4)
				end)
			end
			popText(ally + Vector3.new(0, 4, 0), "PROTECTED", Color3.fromRGB(150, 255, 210))
			task.wait(0.8)
		end,
		V = function(ctx, color)
			ctx.rig:pose({ RA = 3, LA = 3 }, 0.2)
			ring(ctx.rig.position, Color3.fromRGB(180, 255, 220), 10, 0.7, 0.4)
			pillar(ctx.rig.position - Vector3.new(0, 2.5, 0), Color3.fromRGB(180, 255, 220), 18, 7, 1)
			popText(ctx.rig.position + Vector3.new(0, 5, 0), "SECOND WIND", WHITE)
			task.wait(1)
		end,
	},
	Gambler = {
		M1 = function(ctx, color)
			ctx.rig:pose({ RA = 1.57, T = 0.1 }, 0.08)
			task.wait(0.09)
			beam(handPos(ctx), targetPos(ctx, 1), Color3.fromRGB(255, 235, 170), 0.18, 0.12)
			ring(handPos(ctx), color, 1, 0.14)
			hurt(ctx, color)
			task.wait(0.14)
		end,
		F = function(ctx, color)
			local p = ctx.rig.position + Vector3.new(0, 4, 0)
			local die = fxPart(Vector3.new(1.4, 1.4, 1.4), CFrame.new(p), Color3.fromRGB(240, 240, 235), nil, Enum.Material.Marble)
			for i = 1, 14 do
				die.CFrame = CFrame.new(p) * CFrame.Angles(i * 0.9, i * 1.3, i * 0.7)
				task.wait(0.04)
			end
			die:Destroy()
			local roll = math.random(1, 20)
			popText(p + Vector3.new(0, 1, 0), tostring(roll), roll == 20 and Color3.fromRGB(120, 255, 160) or roll == 1 and Color3.fromRGB(255, 80, 70) or color)
			task.wait(0.8)
		end,
		C = function(ctx, color)
			ctx.rig:pose({ RA = 1.57, LA = 1.5 }, 0.08)
			for _ = 1, 6 do
				task.wait(0.11)
				beam(handPos(ctx), targetPos(ctx, 1), color, 0.24, 0.1)
				hurt(ctx, color)
			end
			task.wait(0.2)
		end,
		V = function(ctx, color)
			ctx.rig:pose({ RA = 3, LA = 3 }, 0.2)
			local p = ctx.rig.position + Vector3.new(0, 3, 0)
			for i = 1, 26 do
				local coin = fxPart(Vector3.new(0.14, 0.7, 0.7), CFrame.new(p) * CFrame.Angles(0, 0, math.rad(90)), color, Enum.PartType.Cylinder, Enum.Material.Foil)
				local a = i * 1.8
				TweenService:Create(coin, TweenInfo.new(0.7, Enum.EasingStyle.Quad), { CFrame = CFrame.new(p + Vector3.new(math.cos(a) * 7, -4, math.sin(a) * 7)) }):Play()
				Debris:AddItem(coin, 0.8)
				task.wait(0.012)
			end
			popText(p + Vector3.new(0, 2, 0), "JACKPOT", color)
			task.wait(0.8)
		end,
	},
	Duelist = {
		M1 = slashes(3),
		F = function(ctx, color)
			ghost(ctx.rig.root.CFrame, color)
			ctx.rig.root.CFrame = CFrame.lookAt(ahead(ctx, 5), targetPos(ctx))
			task.wait(0.32)
			swing(ctx, color, 0.3)
			ghost(ctx.rig.root.CFrame, color)
			back(ctx, 0.01)
		end,
		C = function(ctx, color)
			lunge(ctx, 9, 0.3, 6, color)
			hurt(ctx, color)
			task.wait(0.15)
			back(ctx, 0.15)
		end,
		V = function(ctx, color)
			for i = 1, 5 do
				local a = i / 5 * 6.28
				local spot = targetPos(ctx) + Vector3.new(math.cos(a) * 4, 0, math.sin(a) * 4)
				ctx.rig.root.CFrame = CFrame.lookAt(spot, targetPos(ctx))
				ghost(ctx.rig.root.CFrame, color)
				swing(ctx, color, i * 0.7, 3.8, true)
			end
			back(ctx, 0.1)
			ring(targetPos(ctx, 1), color, 8, 0.5)
		end,
	},
	Twinblade = {
		M1 = slashes(2),
		F = function(ctx, color)
			ctx.rig:pose({ RAo = 1.4, LAo = 1.4, RA = 1.2, LA = 1.2 }, 0.1)
			local base = CFrame.lookAt(ctx.rig.position, targetPos(ctx))
			for i = 1, 22 do
				ctx.rig.root.CFrame = base * CFrame.Angles(0, i * 0.6, 0)
				if i % 3 == 0 then
					arc(CFrame.new(ctx.rig.position), 3.4, i * 34, i * 34 + 80, color, 0.2)
				end
				task.wait(0.03)
			end
			ctx.rig.root.CFrame = base
		end,
		C = function(ctx, color)
			local r = ctx.rig
			r:pose({ RA = 3, LA = 3 }, 0.12)
			r:move(CFrame.lookAt(ahead(ctx, 3, 6), targetPos(ctx)), 0.22)
			task.wait(0.24)
			r:pose({ RA = 0.4, LA = 0.4, Lean = 0.4 }, 0.08)
			r:move(CFrame.lookAt(ahead(ctx, 6, 0), targetPos(ctx)), 0.1)
			for _, roll in { 0.8, -0.8 } do
				arc(CFrame.lookAt(targetPos(ctx, 1), targetPos(ctx, 1) + Vector3.xAxis) * CFrame.Angles(0, 0, roll), 4.5, -80, 80, color, 0.3)
			end
			hurt(ctx, color)
			task.wait(0.2)
			back(ctx)
		end,
		V = function(ctx, color)
			local center = ctx.rig.position
			local blades = {}
			for i = 1, 2 do
				blades[i] = fxPart(Vector3.new(0.4, 0.2, 4), CFrame.new(center), i == 1 and color or Color3.fromRGB(110, 190, 255))
			end
			for t = 1, 24 do
				for i, b in blades do
					local a = t * 0.34 + i * 3.14
					local p = center:Lerp(targetPos(ctx), math.sin(t / 24 * 3.14) * 0.8) + Vector3.new(math.cos(a) * 3, 1, math.sin(a) * 3)
					b.CFrame = CFrame.lookAt(p, targetPos(ctx, 1))
				end
				if t % 6 == 0 then hurt(ctx, color) end
				task.wait(0.03)
			end
			for _, b in blades do b:Destroy() end
		end,
	},
	TrueWarrior = {
		M1 = function(ctx, color)
			swing(ctx, color, 0.4)
			local c = targetPos(ctx, 1)
			for i = 1, 8 do
				task.delay(i * 0.05, function()
					arc(CFrame.new(c) * CFrame.Angles(i * 0.8, i * 1.7, 0), 3, -60, 60, color, 0.16)
					hurt(ctx, color)
				end)
			end
			task.wait(0.55)
		end,
		F = function(ctx, color)
			ctx.rig:pose({ RA = 3, T = -0.6 }, 0.14)
			task.wait(0.15)
			ctx.rig:pose({ RA = 1, T = 0.6 }, 0.08)
			shot(handPos(ctx), targetPos(ctx, 1), color, 1.2, 0.2, function()
				hurt(ctx, color)
				ring(targetPos(ctx, 1), color, 5, 0.4)
			end)
			task.wait(0.35)
		end,
		C = function(ctx, color)
			ctx.rig:pose({ RA = 3, LA = 3 }, 0.3)
			task.wait(0.35)
			ctx.rig:pose({ RA = 0.4, LA = 0.4, Lean = 0.3 }, 0.08)
			arc(plane(ctx, 1.57), 7, -90, 90, Color3.fromRGB(255, 170, 70), 0.4)
			hurt(ctx, color)
			task.wait(0.35)
		end,
		V = function(ctx, color)
			ctx.rig:pose({ RA = 2.9, LA = 2.9 }, 0.25)
			pillar(ctx.rig.position - Vector3.new(0, 2.5, 0), Color3.fromRGB(255, 240, 180), 20, 8, 1.1)
			popText(ctx.rig.position + Vector3.new(0, 5, 0), "LAST STAND", Color3.fromRGB(255, 240, 180))
			task.wait(1.2)
		end,
		R = function(ctx, color)
			ctx.rig:pose({ RA = 1.5, LA = 1.5, Lean = 0.1 }, 0.1)
			dome(ctx.rig.position + Vector3.new(0, 0.6, 0), Color3.fromRGB(255, 236, 170), 3.6, 0.45)
			task.wait(0.5)
			swing(ctx, color, 0.7, 4, true)
			shot(ahead(ctx, 2, 0.6), targetPos(ctx, 0.6), color, 1.2, 0.18, function()
				hurt(ctx, color)
			end)
			task.wait(0.25)
		end,
	},
	Disorderer = {
		M1 = function(ctx, color, color2)
			raiseCast(ctx)
			for i = 1, 5 do
				task.delay(i * 0.09, function()
					shot(handPos(ctx) + Vector3.new(0, i * 0.3 - 0.8, 0), targetPos(ctx, 1), i % 2 == 0 and color or color2, 0.6, 0.25, function()
						hurt(ctx, color)
					end)
				end)
			end
			task.wait(0.8)
		end,
		F = function(ctx, color, color2)
			ghost(ctx.rig.root.CFrame, color)
			ctx.rig.root.CFrame = CFrame.lookAt(ahead(ctx, 7, 0), targetPos(ctx))
			ghost(ctx.rig.root.CFrame, color2)
			task.wait(0.45)
			ghost(ctx.rig.root.CFrame, color)
			back(ctx, 0.01)
			ghost(ctx.rig.root.CFrame, color2)
			task.wait(0.15)
		end,
		C = function(ctx, color, color2)
			local d = fxPart(Vector3.new(3, 3, 3), CFrame.new(ctx.rig.position + Vector3.new(0, 4, 0)) * CFrame.Angles(math.rad(45), 0, math.rad(45)), color2, nil, Enum.Material.Glass)
			d.Transparency = 0.25
			Debris:AddItem(d, 1.6)
			for i = 1, 40 do
				d.CFrame = d.CFrame * CFrame.Angles(0, 0.14, 0)
				if i == 20 then dome(ctx.rig.position + Vector3.new(0, 0.6, 0), color, 4, 0.5) end
				task.wait(0.03)
			end
		end,
		V = function(ctx, color, color2)
			local p = ctx.rig.position
			ring(p - Vector3.new(0, 2.8, 0), color, 12, 0.8, 0.5)
			ring(p - Vector3.new(0, 2.7, 0), color2, 9, 0.8, 0.5)
			popText(p + Vector3.new(0, 5, 0), "CHECKPOINT SAVED", color2)
			for _ = 1, 8 do
				ghost(CFrame.new(p + Vector3.new(math.random(-6, 6), 0, math.random(-6, 6))), math.random() > 0.5 and color or color2)
				task.wait(0.06)
			end
			task.wait(0.4)
		end,
	},
}

-- A short shimmer for an orb's passive.
function Demos.PlayOrb(rig, orb)
	if not fxFolder then return end
	ring(rig.position, orb.Color, 8, 0.7, 0.4)
	pillar(rig.position - Vector3.new(0, 2.5, 0), orb.Color, 12, 5, 0.8)
end

function Demos.Setup(folder)
	fxFolder = folder
end

function Demos.Stop()
	token += 1
end

-- Plays one skill. Returns immediately; a newer call cancels by simply taking over the joints.
function Demos.Play(ctx, classId, key, color, color2)
	local demos = Demos.Skills[classId]
	local demo = demos and demos[key]
	if not demo then
		return
	end
	token += 1
	local mine = token
	task.spawn(function()
		ctx.rig:faceTarget(0.12)
		task.wait(0.13)
		local ok, err = pcall(demo, ctx, color, color2 or color)
		if not ok then
			warn("[Showcase] " .. classId .. "." .. key .. ": " .. tostring(err))
		end
		task.wait(0.3)
		if mine == token then
			ctx.rig:reset(0.3)
		end
	end)
end

return Demos
