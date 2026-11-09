local Visuals = {}
function Visuals.bolt(ctx)
	local rng = ctx.rng
	local motionLine = ctx.motionLine
	local bright = ctx.bright
	local function bolt(from, to, spread, width)
		local dir = to - from
		local len = dir.Magnitude
		if len < 1 then
			return
		end
		local unit = dir / len
		local side = unit:Cross(Vector3.yAxis)
		side = side.Magnitude > 0.01 and side.Unit or Vector3.xAxis
		local up = side:Cross(unit)
		local segments = math.clamp(math.floor(len / 2.5), 2, 6)
		local prev = from
		for i = 1, segments do
			local point = from + dir * (i / segments)
			if i < segments then
				point += side * rng:NextNumber(-spread, spread) + up * rng:NextNumber(-spread, spread) * 0.6
			end
			motionLine("GoldenThrustBolt", prev, point, width or 0.14, bright, 0.18)
			prev = point
		end
	end
	return bolt
end
function Visuals.radial(ctx)
	local rng = ctx.rng
	local motionLine = ctx.motionLine
	local gold = ctx.gold
	local bright = ctx.bright
	local function radial(center, axisA, axisB, count, inner, outer, width, fade)
		for i = 1, count do
			local angle = i / count * math.pi * 2 + rng:NextNumber(-0.08, 0.08)
			local d = axisA * math.cos(angle) + axisB * math.sin(angle)
			local length = outer * rng:NextNumber(0.75, 1.1)
			motionLine(
				"GoldenThrustBurst",
				center + d * inner,
				center + d * length,
				width,
				i % 2 == 0 and gold or bright,
				fade
			)
		end
	end
	return radial
end
function Visuals.flash(ctx)
	local part = ctx.part
	local bright = ctx.bright
	local Tween = ctx.Tween
	local Debris = ctx.Debris
	local function flash(position, size, duration, color)
		local f = part(
			"GoldenThrustFlash",
			CFrame.new(position),
			Vector3.new(size * 0.25, size * 0.25, size * 0.25),
			color or bright,
			0.1
		)
		if not f then
			return
		end
		pcall(function()
			f.Shape = Enum.PartType.Ball
			f.Material = Enum.Material.Neon
		end)
		Tween:Create(
			f,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(size, size, size), Transparency = 1 }
		):Play()
		Debris:AddItem(f, duration + 0.03)
	end
	return flash
end
function Visuals.groundSparks(ctx)
	local rng = ctx.rng
	local motionLine = ctx.motionLine
	local gold = ctx.gold
	local bright = ctx.bright
	local function groundSparks(position, count)
		for _ = 1, count do
			local base = position + Vector3.new(rng:NextNumber(-2.2, 2.2), 0, rng:NextNumber(-2.2, 2.2))
			local tip = base
				+ Vector3.new(rng:NextNumber(-1.5, 1.5), rng:NextNumber(1.5, 3.8), rng:NextNumber(-1.5, 1.5))
			motionLine("GoldenThrustSpark", base, tip, 0.1, rng:NextNumber() > 0.5 and gold or bright, 0.22)
		end
	end
	return groundSparks
end
function Visuals.stabPose(ctx)
	local core = ctx.core
	local function stabPose(extended, duration)
		 
		local pose = extended
				and {
					RightShoulder = { 55, 0, -8 },
					RightElbow = { 8, 0, 0 },
					RightWrist = { -63, 0, 0 },
					Waist = { 12, -20, 0 },
					LeftShoulder = { -20, 0, -15 },
					LeftElbow = { 35, 0, 0 },
					LeftHip = { -18, 0, 0 },
					RightHip = { 22, 0, 0 },
				}
			or {
				RightShoulder = { 15, 0, 15 },
				RightElbow = { 75, 0, 0 },
				RightWrist = { -60, 0, 0 },
				Waist = { 5, 20, 0 },
				LeftShoulder = { -10, 0, -20 },
				LeftElbow = { 50, 0, 0 },
				LeftHip = { 15, 0, 0 },
				RightHip = { -20, 0, 0 },
			}
		core.PoseAngles(pose, duration)
	end
	return stabPose
end
return table.freeze(Visuals)
