local Visuals = {}
function Visuals.part(ctx)
	local core = ctx.core
	local function part(cast, name, frame, size, color, alpha, material)
		local body = cast:Add(core.Part(name, frame, size, color, alpha))
		body.Shape = Enum.PartType.Block  
		body.Material = material or Enum.Material.Neon
		body.CastShadow = false
		return body
	end
	return part
end
function Visuals.disk(ctx)
	local part = ctx.part
	local HALF_PI = ctx.HALF_PI
	local function disk(cast, name, position, lift, diameter, thickness, color, alpha)
		local body = part(
			cast,
			name,
			CFrame.new(position + Vector3.new(0, lift, 0)) * CFrame.Angles(0, 0, HALF_PI),
			Vector3.new(thickness, diameter, diameter),
			color,
			alpha
		)
		body.Shape = Enum.PartType.Cylinder
		return body
	end
	return disk
end
function Visuals.CreateSword(ctx)
	local part = ctx.part
	local gold = ctx.gold
	local TIP_RIGHT = ctx.TIP_RIGHT
	local TIP_LEFT = ctx.TIP_LEFT
	local white = ctx.white
	local bright = ctx.bright
	local deep = ctx.deep
	local HALF_PI = ctx.HALF_PI
	local Effects = ctx.Effects
	local function CreateSword(cast, scale, lod)
		scale = scale or 1
		local pieces, extras, aura = {}, {}, nil
		local NEON, METAL = Enum.Material.Neon, Enum.Material.Metal
		local function at(x, y, z)
			return CFrame.new(x * scale, y * scale, z * scale)
		end
		local function piece(name, size, color, offset, options)
			options = options or {}
			local body = part(cast, name, CFrame.identity, size * scale, color, options.Alpha or 0.04, options.Material)
			if options.Wedge then
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Wedge
				mesh.Parent = body
				extras[#extras + 1] = mesh
			elseif options.Shape then
				body.Shape = options.Shape
			end
			local item = { Body = body, Offset = offset }
			pieces[#pieces + 1] = item
			return item
		end
	
		-- the Blender sword (MeshKit "RainSword", lobby/blender/boss_gear.py) when the place has it; else the old primitive one
		local mesh = require(game:GetService("ReplicatedStorage").BossShared.Presentation.MeshKit).Get("RainSword")
		if mesh then
			if scale ~= 1 then
				mesh:ScaleTo(scale)
			end
			local host = part(cast, "GoldenRainSwordHost", CFrame.identity, Vector3.one * 0.1, gold, 1)
			for _, p in ipairs(mesh:GetChildren()) do
				if p:IsA("BasePart") then
					local offset = p.CFrame -- the mesh is parked at the origin, so this is its offset from the sword's frame
					p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
					p.Name = "GoldenRainSword" .. p.Name
					p.Parent = host.Parent
					cast:Add(p)
					pieces[#pieces + 1] = { Body = p, Offset = offset }
				end
			end
			mesh:Destroy()
			if not lod then
				aura = piece("GoldenRainSwordAura", Vector3.new(30, 4.2, 4.2), gold, at(0, -1, 0) * CFrame.Angles(0, 0, HALF_PI), { Shape = Enum.PartType.Cylinder, Alpha = 0.82 })
			end
		else
		piece("GoldenRainSwordBlade", Vector3.new(2.2, 12, 0.5), gold, at(0, -1, 0))
		piece("GoldenRainSwordTipR", Vector3.new(0.5, 1.1, 6), gold, at(0.55, -10, 0) * TIP_RIGHT, { Wedge = true })
		piece("GoldenRainSwordTipL", Vector3.new(0.5, 1.1, 6), gold, at(-0.55, -10, 0) * TIP_LEFT, { Wedge = true })
		piece("GoldenRainSwordFuller", Vector3.new(0.34, 15.5, 0.64), white, at(0, -3.25, 0))
		piece("GoldenRainSwordGuard", Vector3.new(8, 0.8, 0.9), bright, at(0, 5.6, 0), { Material = METAL })
		if not lod then
			piece("GoldenRainSwordGem", Vector3.one * 1.5, white, at(0, 5.6, 0), { Shape = Enum.PartType.Ball })
			piece(
				"GoldenRainSwordGrip",
				Vector3.new(4.6, 0.62, 0.62),
				deep,
				at(0, 8.4, 0) * CFrame.Angles(0, 0, HALF_PI),
				{ Shape = Enum.PartType.Cylinder, Material = METAL, Alpha = 0.02 }
			)
			piece("GoldenRainSwordPommel", Vector3.one * 1.3, bright, at(0, 11.2, 0), { Shape = Enum.PartType.Ball })
			aura = piece(
				"GoldenRainSwordAura",
				Vector3.new(30, 4.2, 4.2),
				gold,
				at(0, -1, 0) * CFrame.Angles(0, 0, HALF_PI),
				{ Shape = Enum.PartType.Cylinder, Alpha = 0.82 }
			)
		end
		end
	
		local visual = { Pieces = pieces }
		 
		function visual:Draw(frame, streak)
			for _, item in ipairs(pieces) do
				item.Body.CFrame = frame * item.Offset
			end
			if aura then
				streak = streak or 0
				aura.Body.Size = Vector3.new((30 + streak) * scale, 4.2 * scale, 4.2 * scale)
				aura.Body.CFrame = frame * at(0, -1 + streak * 0.5, 0) * CFrame.Angles(0, 0, HALF_PI)
			end
		end
		 
		function visual:Sink(frame, duration)
			for _, item in ipairs(pieces) do
				Effects:Create(
					item.Body,
					TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{ Transparency = 1, CFrame = frame * item.Offset }
				):Play()
			end
		end
		function visual:Cleanup()
			for _, extra in ipairs(extras) do
				if extra.Parent then
					extra:Destroy()
				end
			end
			table.clear(extras)
		end
		return visual
	end
	return CreateSword
end
function Visuals.impactFx(ctx)
	local part = ctx.part
	local cast = ctx.cast
	local position = ctx.position
	local bright = ctx.bright
	local Effects = ctx.Effects
	local OUT = ctx.OUT
	local radius = ctx.radius
	local disk = ctx.disk
	local gold = ctx.gold
	local HALF_PI = ctx.HALF_PI
	local TAU = ctx.TAU
	local random = ctx.random
	local TweenService = ctx.TweenService
	local function impactFx()
		local orb = part(
			cast,
			"GoldenRainExplosion",
			CFrame.new(position + Vector3.new(0, 1.8, 0)),
			Vector3.one * 2,
			bright,
			0.1
		)
		orb.Shape = Enum.PartType.Ball
		Effects:Create(orb, OUT, { Size = Vector3.one * radius * 1.7, Transparency = 1 }):Play()
	
		local wave = disk(cast, "GoldenRainShockwave", position, 0.2, 3, 0.3, bright, 0.12)
		Effects:Create(
			wave,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.3, radius * 2.6, radius * 2.6), Transparency = 1 }
		):Play()
		local waveOuter = disk(cast, "GoldenRainShockwaveOuter", position, 0.16, 3, 0.2, gold, 0.3)
		Effects:Create(
			waveOuter,
			TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.2, radius * 3.4, radius * 3.4), Transparency = 1 }
		):Play()
	
		local pillar = part(
			cast,
			"GoldenRainLightPillar",
			CFrame.new(position + Vector3.new(0, 45, 0)) * CFrame.Angles(0, 0, HALF_PI),
			Vector3.new(90, radius * 0.8, radius * 0.8),
			bright,
			0.12
		)
		pillar.Shape = Enum.PartType.Cylinder
		Effects:Create(
			pillar,
			TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(90, 0.4, 0.4), Transparency = 1 }
		):Play()
	
		for index = 1, 8 do
			local angle = (index / 8) * TAU + random:NextNumber(-0.3, 0.3)
			local outward = Vector3.new(math.cos(angle), 0, math.sin(angle))
			local dir = (outward * random:NextNumber(0.7, 1.1) + Vector3.new(0, random:NextNumber(0.6, 1.3), 0)).Unit
			local startPos = position + Vector3.new(0, 1, 0) + outward * radius * 0.3
			local shard = part(
				cast,
				"GoldenRainShard",
				CFrame.lookAt(startPos, startPos + dir),
				Vector3.new(0.4, 0.4, 3.2),
				index % 2 == 0 and gold or bright,
				0.05
			)
			local endPos = startPos + dir * random:NextNumber(10, 20) + Vector3.new(0, -3, 0)
			Effects:Create(
				shard,
				TweenInfo.new(random:NextNumber(0.4, 0.65), Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					CFrame = CFrame.lookAt(endPos, endPos + dir + Vector3.new(0, -0.8, 0)),
					Size = Vector3.new(0.1, 0.1, 0.8),
					Transparency = 1,
				}
			):Play()
		end
	
		local glow = Instance.new("PointLight")
		glow.Color = gold
		glow.Brightness = 4
		glow.Range = radius * 3
		glow.Shadows = false
		glow.Parent = orb
		TweenService:Create(glow, TweenInfo.new(0.5), { Brightness = 0 }):Play()
		local sparks = Instance.new("ParticleEmitter")
		sparks.Enabled = false
		sparks.Color = ColorSequence.new(bright, gold)
		sparks.LightEmission = 1
		sparks.Lifetime = NumberRange.new(0.35, 0.7)
		sparks.Speed = NumberRange.new(12, 28)
		sparks.SpreadAngle = Vector2.new(60, 60)
		sparks.EmissionDirection = Enum.NormalId.Top
		sparks.Drag = 2
		sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		sparks.Transparency =
			NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		sparks.Parent = orb
		sparks:Emit(26)
		task.delay(1, function()
			if glow.Parent then
				glow:Destroy()
			end
			if sparks.Parent then
				sparks:Destroy()
			end
		end)
	end
	return impactFx
end
function Visuals.SummonAura(ctx)
	local core = ctx.core
	local Effects = ctx.Effects
	local actor = ctx.actor
	local disk = ctx.disk
	local gold = ctx.gold
	local bright = ctx.bright
	local part = ctx.part
	local HALF_PI = ctx.HALF_PI
	local api = ctx.api
	local encounterAlive = ctx.encounterAlive
	local TAU = ctx.TAU
	local function SummonAura(duration)
		local root = core.Root
		local cast = Effects.NewCast(actor, "GoldenSwordRainSummon", duration + 0.4)
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -80, 0), core.Params())
		local ground = (hit and hit.Position or root.Position - Vector3.new(0, 3, 0)) + Vector3.new(0, 0.15, 0)
		local outer = disk(cast, "GoldenRainSummonSigil", ground, 0, 6, 0.16, gold, 0.55)
		local inner = disk(cast, "GoldenRainSummonSigilCore", ground, 0.05, 4, 0.18, bright, 0.5)
		local bars = {}
		for index = 1, 3 do
			bars[index] = part(
				cast,
				"GoldenRainSummonRune",
				CFrame.new(ground + Vector3.new(0, 0.3, 0)),
				Vector3.new(6, 0.12, 0.5),
				bright,
				0.15
			)
		end
		local column = part(
			cast,
			"GoldenRainSummonColumn",
			CFrame.new(ground + Vector3.new(0, 55, 0)) * CFrame.Angles(0, 0, HALF_PI),
			Vector3.new(110, 2, 2),
			bright,
			0.8
		)
		column.Shape = Enum.PartType.Cylinder
		local minis = {}
		for index = 1, 6 do
			minis[index] = api.CreateSword(cast, 0.3, true)
		end
		cast.OnDispose = function()
			for _, mini in ipairs(minis) do
				mini:Cleanup()
			end
		end
	
		local began = cast:Now()
		cast:Step(function(_, now)
			if not (encounterAlive() and root.Parent) then
				cast:Dispose()
				return false
			end
			local elapsed = now - began
			local p = math.clamp(elapsed / duration, 0, 1)
			local eased = 1 - (1 - p) ^ 2
			local diameter = 5 + 28 * eased
			outer.Size = Vector3.new(0.16, diameter, diameter)
			inner.Size = Vector3.new(0.18, diameter * 0.62, diameter * 0.62)
			outer.Transparency = 0.6 - 0.15 * math.sin(elapsed * 10)
			local rotation = elapsed * (1.2 + p * 3)
			for index, bar in ipairs(bars) do
				bar.Size = Vector3.new(diameter * 0.92, 0.12, 0.5)
				bar.CFrame = CFrame.new(ground + Vector3.new(0, 0.3, 0))
					* CFrame.Angles(0, rotation + index * math.pi / 3, 0)
			end
			local width = 2 + 2.5 * eased + math.sin(elapsed * 14) * 0.4
			column.Size = Vector3.new(110, width, width)
			column.Transparency = 0.85 - 0.25 * p
	
			local center = root.Position
			local spin = elapsed * (2 + p * 5)
			for index, mini in ipairs(minis) do
				local angle = spin + (index - 1) / #minis * TAU
				local orbit = 10 - 4 * eased
				local lift = 7 + 10 * eased + math.sin(now * 4 + index) * 0.6
				local pos = center + Vector3.new(math.cos(angle) * orbit, lift, math.sin(angle) * orbit)
				mini:Draw(CFrame.new(pos) * CFrame.Angles(0, -angle, 0), 0)
			end
			return true
		end)
		return cast
	end
	return SummonAura
end
return table.freeze(Visuals)
