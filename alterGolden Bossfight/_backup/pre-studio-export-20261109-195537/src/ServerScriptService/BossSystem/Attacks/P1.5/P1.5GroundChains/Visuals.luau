local Visuals = {}
function Visuals.tweenOut(ctx)
	local function tweenOut(duration)
		return TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end
	return tweenOut
end
function Visuals.fxPart(ctx)
	local core = ctx.core
	local function fxPart(cast, name, frame, size, color, alpha, shape, material)
		local body = cast:Add(core.Part(name, frame, size, color, alpha))
		body.Shape = shape or Enum.PartType.Block
		body.Material = material or Enum.Material.Neon
		body.CastShadow = false
		return body
	end
	return fxPart
end
function Visuals.flat(ctx)
	local HALF_PI = ctx.HALF_PI
	local function flat(position)  
		return CFrame.new(position) * CFrame.Angles(0, 0, HALF_PI)
	end
	return flat
end
function Visuals.bend(ctx)
	local function bend(from, to, arc, s)
		return from:Lerp(to, s) + Vector3.new(0, math.sin(s * math.pi) * arc, 0)
	end
	return bend
end
function Visuals.updateDecor(ctx)
	local hideWarning = ctx.hideWarning
	local warningTime = ctx.warningTime
	local rim = ctx.rim
	local flat = ctx.flat
	local radius = ctx.radius
	local fill = ctx.fill
	local bars = ctx.bars
	local HALF_PI = ctx.HALF_PI
	local sockets = ctx.sockets
	local spikes = ctx.spikes
	local get_decorDone = ctx.get_decorDone
	local get_nativeSuppressed = ctx.get_nativeSuppressed
	local get_elapsed = ctx.get_elapsed
	local get_ground = ctx.get_ground
	local get_locked = ctx.get_locked
	local function updateDecor()
		if hideWarning or get_decorDone() then
			return
		end
		local hidden = get_nativeSuppressed()
		local progress = warningTime > 0 and math.clamp(get_elapsed() / warningTime, 0, 1) or 1
		rim.CFrame = flat(get_ground() + Vector3.new(0, 0.1, 0))
		rim.Transparency = hidden and 1 or 0.35 + math.sin(get_elapsed() * 9) * 0.1
		local diameter = math.max(0.5, radius * 2 * progress)
		fill.Size = Vector3.new(0.19, diameter, diameter)
		fill.CFrame = flat(get_ground() + Vector3.new(0, 0.16, 0))
		fill.Transparency = hidden and 1 or (get_locked() and 0.35 or 0.62 - 0.25 * progress)
		local spin = get_elapsed() * (1.2 + progress * 4)
		for index, bar in ipairs(bars) do
			bar.CFrame = CFrame.new(get_ground() + Vector3.new(0, 0.2, 0))
				* CFrame.Angles(0, spin + index * math.pi / 3, 0)
			bar.Transparency = hidden and 1 or 0.25 + math.sin(get_elapsed() * 7 + index) * 0.08
		end
		local height = math.max(0.1, 5 * progress)
		for index = 1, 4 do
			local angle = index * HALF_PI
			local base = get_ground()
				+ Vector3.new(math.cos(angle) * radius * 0.65, 0.15, math.sin(angle) * radius * 0.65)
			local pulse = 1.4 + 0.5 * math.sin(get_elapsed() * 8 + index)
			sockets[index].Size = Vector3.new(0.14, pulse, pulse)
			sockets[index].CFrame = flat(base)
			sockets[index].Transparency = hidden and 1 or 0.15
			spikes[index].Size = Vector3.new(height, 0.45, 0.45)
			spikes[index].CFrame = CFrame.new(base + Vector3.new(0, height * 0.5, 0)) * CFrame.Angles(0, 0, HALF_PI)
			spikes[index].Transparency = hidden and 1 or 0.3
		end
	end
	return updateDecor
end
function Visuals.lockFlash(ctx)
	local hideWarning = ctx.hideWarning
	local rim = ctx.rim
	local BRIGHT = ctx.BRIGHT
	local bars = ctx.bars
	local WHITE = ctx.WHITE
	local sockets = ctx.sockets
	local fxPart = ctx.fxPart
	local cast = ctx.cast
	local flat = ctx.flat
	local radius = ctx.radius
	local CYLINDER = ctx.CYLINDER
	local Effects = ctx.Effects
	local tweenOut = ctx.tweenOut
	local get_ground = ctx.get_ground
	local function lockFlash()
		if hideWarning then
			return
		end
		rim.Color = BRIGHT
		for _, bar in ipairs(bars) do
			bar.Color = WHITE
		end
		for _, socket in ipairs(sockets) do
			socket.Color = WHITE
		end
		local snap = fxPart(
			cast,
			"GoldenChainsLockSnap",
			flat(get_ground() + Vector3.new(0, 0.24, 0)),
			Vector3.new(0.14, radius * 3.2, radius * 3.2),
			WHITE,
			0.1,
			CYLINDER
		)
		Effects:Create(snap, tweenOut(0.25), { Size = Vector3.new(0.14, radius * 2, radius * 2), Transparency = 1 })
			:Play()
	end
	return lockFlash
end
function Visuals.eruptFx(ctx)
	local hideWarning = ctx.hideWarning
	local fxPart = ctx.fxPart
	local cast = ctx.cast
	local flat = ctx.flat
	local CYLINDER = ctx.CYLINDER
	local Effects = ctx.Effects
	local tweenOut = ctx.tweenOut
	local radius = ctx.radius
	local BRIGHT = ctx.BRIGHT
	local GOLD = ctx.GOLD
	local random = ctx.random
	local WHITE = ctx.WHITE
	local TweenService = ctx.TweenService
	local chains = ctx.chains
	local TAU = ctx.TAU
	local get_ground = ctx.get_ground
	local function eruptFx()
		if not hideWarning then
			local function ring(lift, fromD, toD, color, alpha, duration)
				local shock = fxPart(
					cast,
					"GoldenChainsShockwave",
					flat(get_ground() + Vector3.new(0, lift, 0)),
					Vector3.new(0.2, fromD, fromD),
					color,
					alpha,
					CYLINDER
				)
				Effects:Create(shock, tweenOut(duration), { Size = Vector3.new(0.2, toD, toD), Transparency = 1 })
					:Play()
			end
			ring(0.22, 2, radius * 2.5, BRIGHT, 0.1, 0.5)
			ring(0.18, radius * 2, radius * 3.1, GOLD, 0.35, 0.75)
			local offset = random:NextNumber(0, math.pi)
			for index = 1, 5 do
				local crack = fxPart(
					cast,
					"GoldenChainsCrack",
					CFrame.new(get_ground() + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, offset + index * math.pi / 5, 0),
					Vector3.new(radius * 0.3, 0.1, 0.4),
					WHITE,
					0.05
				)
				Effects:Create(
					crack,
					tweenOut(0.55),
					{ Size = Vector3.new(radius * random:NextNumber(1.6, 2), 0.1, 0.15), Transparency = 1 }
				):Play()
			end
		end
		local orb = fxPart(
			cast,
			"GoldenChainsBurst",
			CFrame.new(get_ground() + Vector3.new(0, 1.5, 0)),
			Vector3.one * 3,
			BRIGHT,
			0.1,
			Enum.PartType.Ball
		)
		Effects:Create(orb, tweenOut(0.4), { Size = Vector3.one * radius * 1.5, Transparency = 1 }):Play()
		local glow = Instance.new("PointLight")
		glow.Color = GOLD
		glow.Brightness = 4
		glow.Range = radius * 3
		glow.Shadows = false
		glow.Parent = orb
		TweenService:Create(glow, TweenInfo.new(0.5), { Brightness = 0 }):Play()
		task.delay(1, function()
			if glow.Parent then
				glow:Destroy()
			end
		end)
		for _, item in ipairs(chains) do
			local root = fxPart(
				cast,
				"GoldenChainsRoot",
				CFrame.new(item.First.WorldPosition + Vector3.new(0, 0.4, 0)),
				Vector3.one * 1.1,
				WHITE,
				0.05,
				Enum.PartType.Ball
			)
			Effects:Create(root, tweenOut(0.35), { Size = Vector3.one * 3.4, Transparency = 1 }):Play()
		end
		for index = 1, 10 do
			local angle = (index / 10) * TAU + random:NextNumber(-0.3, 0.3)
			local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local dir = (outward * random:NextNumber(0.6, 1.1) + Vector3.new(0, random:NextNumber(0.7, 1.4), 0)).Unit
			local start = get_ground() + Vector3.new(0, 0.6, 0) + outward * radius * 0.55
			local shard = fxPart(
				cast,
				"GoldenChainsShard",
				CFrame.lookAt(start, start + dir),
				Vector3.new(0.3, 0.3, 2.6),
				index % 2 == 0 and GOLD or BRIGHT,
				0.05
			)
			local finish = start + dir * random:NextNumber(8, 16) + Vector3.new(0, -2, 0)
			Effects:Create(shard, tweenOut(random:NextNumber(0.35, 0.6)), {
				CFrame = CFrame.lookAt(finish, finish + dir + Vector3.new(0, -0.8, 0)),
				Size = Vector3.new(0.08, 0.08, 0.6),
				Transparency = 1,
			}):Play()
		end
	end
	return eruptFx
end
function Visuals.buildLinks(ctx)
	local chains = ctx.chains
	local LINKS = ctx.LINKS
	local fxPart = ctx.fxPart
	local cast = ctx.cast
	local BRIGHT = ctx.BRIGHT
	local GOLD = ctx.GOLD
	local links = ctx.links
	local get_ground = ctx.get_ground
	local function buildLinks()
		for index = 1, #chains do
			local set = {}
			for i = 1, LINKS do
				local bright = i % 2 == 0
				set[i] = fxPart(
					cast,
					"GoldenChainLink",
					CFrame.new(get_ground()),
					Vector3.new(0.34, 0.8, 1.5),
					bright and BRIGHT or GOLD,
					0.04,
					nil,
					bright and Enum.Material.Neon or Enum.Material.Metal
				)
			end
			links[index] = set
		end
	end
	return buildLinks
end
function Visuals.updateLinks(ctx)
	local chains = ctx.chains
	local links = ctx.links
	local LINKS = ctx.LINKS
	local bend = ctx.bend
	local HALF_PI = ctx.HALF_PI
	local get_shattered = ctx.get_shattered
	local get_elapsed = ctx.get_elapsed
	local function updateLinks(tense)
		if get_shattered() then
			return
		end
		for index, item in ipairs(chains) do
			local set = links[index]
			if set then
				local from, to = item.First.WorldPosition, item.Last.WorldPosition
				local length = (to - from).Magnitude
				local arc = math.min(1.6, length * 0.12) + (tense and math.sin(get_elapsed() * 38 + index) * 0.12 or 0)
				local segment = math.clamp(length / LINKS * 1.25, 0.9, 3)
				for i, link in ipairs(set) do
					local s = (i - 0.5) / LINKS
					local pos = bend(from, to, arc, s)
					local dir = bend(from, to, arc, math.min(1, s + 0.03))
						- bend(from, to, arc, math.max(0, s - 0.03))
					if dir.Magnitude < 0.001 then
						dir = Vector3.yAxis
					end
					local frame = math.abs(dir.Unit.Y) > 0.98 and CFrame.lookAt(pos, pos + dir, Vector3.xAxis)
						or CFrame.lookAt(pos, pos + dir)
					link.Size = Vector3.new(0.34, 0.8, segment)
					link.CFrame = frame * CFrame.Angles(0, 0, (i % 2) * HALF_PI)
				end
			end
		end
	end
	return updateLinks
end
function Visuals.addCuff(ctx)
	local fxPart = ctx.fxPart
	local cast = ctx.cast
	local GOLD = ctx.GOLD
	local BRIGHT = ctx.BRIGHT
	local CYLINDER = ctx.CYLINDER
	local cuffs = ctx.cuffs
	local get_ground = ctx.get_ground
	local function addCuff(character)
		local set = {}
		for i = 1, 2 do
			local size = i == 1 and 5 or 4.2
			set[i] = fxPart(
				cast,
				"GoldenChainCuff",
				CFrame.new(get_ground()),
				Vector3.new(0.3, size, size),
				i == 1 and GOLD or BRIGHT,
				0.25,
				CYLINDER
			)
		end
		cuffs[character] = set
	end
	return addCuff
end
function Visuals.updateCuff(ctx)
	local cuffs = ctx.cuffs
	local HALF_PI = ctx.HALF_PI
	local get_elapsed = ctx.get_elapsed
	local function updateCuff(character)
		local set = cuffs[character]
		local root = character:FindFirstChild("HumanoidRootPart")
		if not set or not root then
			return
		end
		local p = root.Position
		local pulse = 1 + math.sin(get_elapsed() * 14) * 0.06
		set[1].Size = Vector3.new(0.3, 5 * pulse, 5 * pulse)
		set[2].Size = Vector3.new(0.3, 4.2 * pulse, 4.2 * pulse)
		set[1].CFrame = CFrame.new(p + Vector3.new(0, -1.6, 0)) * CFrame.Angles(0, 0, HALF_PI)
		set[2].CFrame = CFrame.new(p + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, HALF_PI)
	end
	return updateCuff
end
function Visuals.dropCuff(ctx)
	local cuffs = ctx.cuffs
	local function dropCuff(character)
		local set = cuffs[character]
		if set then
			for _, ring in ipairs(set) do
				ring.Transparency = 1
			end
			cuffs[character] = nil
		end
	end
	return dropCuff
end
return table.freeze(Visuals)
