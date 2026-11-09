local Visuals = {}
function Visuals.addPart(ctx)
	local Effects = ctx.Effects
	local Runtime = ctx.Runtime
	local function addPart(fx, frame, size, color, alpha)
		local part = Effects.AcquirePart()
		part.Name = "MissingFrameVFX"
		part.CFrame = frame
		part.Size = size
		part.Color = color
		part.Transparency = alpha
		part.Parent = Runtime.Effects
		part:SetAttribute("TimeStopExempt", true)
		fx:Add(part)
		return part
	end
	return addPart
end
function Visuals.drop(ctx)
	local Effects = ctx.Effects
	local function drop(fx, parts)
		for _, part in ipairs(parts) do
			fx.objects[part] = nil
			Effects.Release(part)
		end
	end
	return drop
end
function Visuals.play(ctx)
	local function play(fx, delay, life, setup)
		fx:Schedule(math.max(0, delay), function()
			local update, cleanup = setup()
			local began = fx:Now()
			fx:Step(function(_, now)
				local t = math.clamp((now - began) / life, 0, 1)
				update(t)
				if t >= 1 then
					cleanup()
					return false
				end
				return true
			end)
		end)
	end
	return play
end
function Visuals.floorY(ctx)
	local Placement = ctx.Placement
	local function floorY(position)
		local ground = Placement.GroundPoint(position, { Margin = 2, Clamp = true })
		return ground and ground.Y or position.Y - 2.9
	end
	return floorY
end
function Visuals.gate(ctx)
	local play = ctx.play
	local addPart = ctx.addPart
	local GOLD = ctx.GOLD
	local drop = ctx.drop
	local function gate(fx, delay, life, frame, width, height, style)
		play(fx, delay, life, function()
			local bars = {}
			for i = 1, 4 do
				bars[i] = addPart(fx, CFrame.identity, Vector3.one, GOLD, 1)
			end
			return function(t)
				local scale, alpha, color, thickness, offset = style(t)
				local w = math.max(0.05, width * scale)
				local h = math.max(0.05, height * scale)
				local base = frame * CFrame.new(offset or 0, 0, 0)
				local layout = {
					{ 0, h * 0.5, w, thickness },
					{ 0, -h * 0.5, w, thickness },
					{ -w * 0.5, 0, thickness, h },
					{
						w * 0.5,
						0,
						thickness,
						h,
					},
				}
				for i, bar in ipairs(bars) do
					local item = layout[i]
					bar.Size = Vector3.new(item[3], item[4], thickness)
					bar.CFrame = base * CFrame.new(item[1], item[2], 0)
					bar.Transparency = alpha
					bar.Color = color
				end
			end, function()
				drop(fx, bars)
			end
		end)
	end
	return gate
end
function Visuals.pulse(ctx)
	local play = ctx.play
	local addPart = ctx.addPart
	local drop = ctx.drop
	local function pulse(fx, delay, life, position, color, from, to, alpha)
		play(fx, delay, life, function()
			local part = addPart(fx, CFrame.new(position), Vector3.new(0.14, 1, 1), color, alpha)
			part.Shape = Enum.PartType.Cylinder
			return function(t)
				local radius = from + (to - from) * (1 - (1 - t) ^ 3)
				part.Size = Vector3.new(0.14, radius * 2, radius * 2)
				part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi * 0.5)
				part.Transparency = alpha + (1 - alpha) * t
			end, function()
				drop(fx, { part })
			end
		end)
	end
	return pulse
end
function Visuals.burst(ctx)
	local addPart = ctx.addPart
	local GOLD = ctx.GOLD
	local HOT = ctx.HOT
	local function burst(fx, position, count, speed, color)
		local host = addPart(fx, CFrame.new(position), Vector3.one, GOLD, 1)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "MissingFrameShards"
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(0.3, 0.55)
		emitter.Speed = NumberRange.new(speed * 0.5, speed)
		emitter.Drag = 5
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.LightEmission = 1
		emitter.Rotation = NumberRange.new(0, 360)
		emitter.RotSpeed = NumberRange.new(-400, 400)
		emitter.Color = ColorSequence.new(HOT, color)
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		emitter.Parent = host
		fx:Add(emitter)
		emitter:Emit(count)
	end
	return burst
end
function Visuals.streak(ctx)
	local play = ctx.play
	local addPart = ctx.addPart
	local HOT = ctx.HOT
	local CYAN = ctx.CYAN
	local drop = ctx.drop
	local function streak(fx, from, to)
		local distance = (to - from).Magnitude
		if distance < 1 then
			return
		end
		play(fx, 0, 0.32, function()
			local part = addPart(fx, CFrame.lookAt((from + to) * 0.5, to), Vector3.new(0.5, 0.5, distance), HOT, 0.1)
			return function(t)
				local width = math.max(0.05, 0.5 * (1 - t))
				part.Size = Vector3.new(width, width, distance)
				part.Transparency = 0.1 + 0.9 * t
				part.Color = HOT:Lerp(CYAN, t)
			end, function()
				drop(fx, { part })
			end
		end)
	end
	return streak
end
function Visuals.flash(ctx)
	local play = ctx.play
	local actor = ctx.actor
	local HOT = ctx.HOT
	local GOLD = ctx.GOLD
	local Runtime = ctx.Runtime
	local function flash(fx)
		play(fx, 0, 0.28, function()
			local highlight = Instance.new("Highlight")
			highlight.Name = "MissingFrameReturn"
			highlight.Adornee = actor
			highlight.FillColor = HOT
			highlight.OutlineColor = GOLD
			highlight.FillTransparency = 0.3
			highlight.OutlineTransparency = 0
			highlight.Parent = Runtime.Effects
			fx:Add(highlight)
			return function(t)
				highlight.FillTransparency = 0.3 + 0.7 * t
				highlight.OutlineTransparency = t
			end, function()
				fx.objects[highlight] = nil
				highlight:Destroy()
			end
		end)
	end
	return flash
end
function Visuals.departure(ctx)
	local gate = ctx.gate
	local HOT = ctx.HOT
	local GOLD = ctx.GOLD
	local floorY = ctx.floorY
	local pulse = ctx.pulse
	local CYAN = ctx.CYAN
	local burst = ctx.burst
	local function departure(fx, frame, direction, hidden)
		local position = frame.Position
		gate(fx, 0, hidden + 0.04, CFrame.lookAt(position, position + direction), 6, 9, function(t)
			return 1 - t * t, 0.1 + 0.7 * t, HOT:Lerp(GOLD, t), 0.2
		end)
		local floor = Vector3.new(position.X, floorY(position) + 0.2, position.Z)
		pulse(fx, 0, 0.35, floor, GOLD, 3, 13, 0.5)
		pulse(fx, 0, 0.55, floor, CYAN, 4, 32, 0.82)
		burst(fx, position, 20, 24, GOLD)
	end
	return departure
end
function Visuals.arrival(ctx)
	local streak = ctx.streak
	local flash = ctx.flash
	local CYAN = ctx.CYAN
	local GOLD = ctx.GOLD
	local gate = ctx.gate
	local HOT = ctx.HOT
	local pulse = ctx.pulse
	local floorY = ctx.floorY
	local burst = ctx.burst
	local function arrival(fx, originFrame, goalFrame, direction)
		local from, to = originFrame.Position, goalFrame.Position
		local path = to - from
		local flat = Vector3.new(path.X, 0, path.Z)
		local heading = flat.Magnitude > 0.5 and flat.Unit or direction
		streak(fx, from, to)
		flash(fx)
		local count = math.clamp(math.floor(path.Magnitude / 7), 0, 5)
		for i = 1, count do
			local position = from + path * (i / (count + 1))
			local color = i % 2 == 1 and CYAN or GOLD
			gate(fx, (i - 1) * 0.035, 0.3, CFrame.lookAt(position, position + heading), 6, 9, function(t)
				local alpha = 0.1 + 0.9 * t
				if math.floor(t * 12) % 2 == 1 then
					alpha *= 0.6
				end
				return 1, alpha, color, 0.2 - 0.14 * t, math.sin(t * 50 + i) * 0.3 * (1 - t)
			end)
		end
		gate(fx, 0, 0.4, CFrame.lookAt(to, to + heading), 6, 9, function(t)
			local settle = math.min(1, t / 0.3)
			return 1 + 0.9 * (1 - settle) ^ 2, t < 0.3 and 0.1 or 0.1 + 0.9 * (t - 0.3) / 0.7, HOT:Lerp(CYAN, t), 0.18
		end)
		pulse(fx, 0, 0.3, Vector3.new(to.X, floorY(to) + 0.2, to.Z), HOT, 2, 10, 0.45)
		burst(fx, to, 16, 18, CYAN)
	end
	return arrival
end
return table.freeze(Visuals)
