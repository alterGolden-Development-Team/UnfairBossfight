local Visuals = {}
function Visuals.flatRing(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local Effects = ctx.Effects
	local function flatRing(position, color, fromSize, toSize, time)
		local p = cast:Add(
			core.Part(
				"CardHitRing",
				CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2),
				Vector3.new(0.25, fromSize, fromSize),
				color,
				0.25
			)
		)
		p.Shape = Enum.PartType.Cylinder
		p.Material = Enum.Material.Neon
		Effects:Create(
			p,
			TweenInfo.new(time, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.25, toSize, toSize), Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(p, time + 0.1)
	end
	return flatRing
end
function Visuals.puff(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local GOLD = ctx.GOLD
	local SPARKLE = ctx.SPARKLE
	local WHITE = ctx.WHITE
	local Effects = ctx.Effects
	local function puff(position, count)
		local p = cast:Add(core.Part("CardPuff", CFrame.new(position), Vector3.one * 0.1, GOLD, 1))
		local e = Instance.new("ParticleEmitter")
		e.Texture = SPARKLE
		e.Rate = 0
		e.Color = ColorSequence.new(GOLD, WHITE)
		e.Lifetime = NumberRange.new(0.25, 0.55)
		e.Speed = NumberRange.new(6, 16)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Drag = 4
		e.LightEmission = 0.7
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
		e.Parent = p
		e:Emit(count)
		Effects.ReleaseAfter(p, 0.7)
	end
	return puff
end
function Visuals.shatter(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local WHITE = ctx.WHITE
	local Effects = ctx.Effects
	local SHARD_COUNT = ctx.SHARD_COUNT
	local rng = ctx.rng
	local puff = ctx.puff
	local function shatter(position, normal, color)
		local anchor = position + normal * 0.15
		local up = math.abs(normal.Y) > 0.95 and Vector3.xAxis or Vector3.yAxis
		local tangent = normal:Cross(up).Unit
		local bitangent = normal:Cross(tangent).Unit
		 
		local ring = cast:Add(
			core.Part(
				"CardWallRing",
				CFrame.lookAt(anchor, anchor + normal) * CFrame.Angles(0, math.pi / 2, 0),
				Vector3.new(0.2, 1.5, 1.5),
				WHITE,
				0.1
			)
		)
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.Neon
		Effects:Create(
			ring,
			TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.2, 9, 9), Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(ring, 0.38)
		 
		local flash = cast:Add(core.Part("CardWallFlash", CFrame.new(anchor), Vector3.one, WHITE, 0.1))
		flash.Shape = Enum.PartType.Ball
		flash.Material = Enum.Material.Neon
		Effects:Create(
			flash,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.one * 4.5, Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(flash, 0.28)
		 
		for i = 1, SHARD_COUNT do
			local shardSize = Vector3.new(rng:NextNumber(0.5, 1.1), rng:NextNumber(0.7, 1.5), 0.07)
			local startPos = anchor
				+ tangent * rng:NextNumber(-1.2, 1.2)
				+ bitangent * rng:NextNumber(-1.5, 1.5)
			local startCF = CFrame.new(startPos)
				* CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28))
			local shard = cast:Add(core.Part("CardShard", startCF, shardSize, i % 2 == 0 and WHITE or color, 0))
			shard.Material = Enum.Material.Neon
			local spread = tangent * rng:NextNumber(-1, 1) + bitangent * rng:NextNumber(-1, 1)
			local direction = (normal * rng:NextNumber(0.5, 1.2) + spread).Unit
			local life = rng:NextNumber(0.45, 0.7)
			local endPos = startPos
				+ direction * rng:NextNumber(5, 11)
				- Vector3.new(0, rng:NextNumber(2, 5), 0)  
			local endCF = CFrame.new(endPos)
				* startCF.Rotation
				* CFrame.Angles(rng:NextNumber(-6, 6), rng:NextNumber(-6, 6), rng:NextNumber(-6, 6))
			Effects:Create(
				shard,
				TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ CFrame = endCF }
			):Play()
			 
			Effects:Create(
				shard,
				TweenInfo.new(
					life * 0.6,
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.Out,
					0,
					false,
					life * 0.4
				),
				{ Transparency = 1, Size = shardSize * 0.25 }
			):Play()
			Effects.ReleaseAfter(shard, life + 0.15)
		end
		puff(anchor, 12)
	end
	return shatter
end
function Visuals.handPosition(ctx)
	local actor = ctx.actor
	local core = ctx.core
	local function handPosition()
		local hand = actor:FindFirstChild("RightHand") or actor:FindFirstChild("Right Arm")
		if hand and hand:IsA("BasePart") then
			return hand.Position
		end
		return core.Root.Position + core.Root.CFrame.RightVector * 1.6 + Vector3.new(0, 0.6, 0)
	end
	return handPosition
end
function Visuals.chargeUp(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local handPosition = ctx.handPosition
	local GOLD = ctx.GOLD
	local valid = ctx.valid
	local Effects = ctx.Effects
	local CARD_SIZE = ctx.CARD_SIZE
	local SPARKLE = ctx.SPARKLE
	local WHITE = ctx.WHITE
	local function chargeUp()
		local start = cast:Now()
		local orb =
			cast:Add(core.Part("CardChargeOrb", CFrame.new(handPosition()), Vector3.one * 0.3, GOLD, 0.35))
		orb.Shape = Enum.PartType.Ball
		orb.Material = Enum.Material.Neon
		local glow = Instance.new("PointLight")
		glow.Color = GOLD
		glow.Range = 6
		glow.Brightness = 1
		glow.Parent = orb
		local symbol, suck, suckEmitter, flashed
		cast:Step(function(_, now)
			local t = now - start
			if t >= 0.3 or not valid() then
				Effects.Release(orb)
				if symbol then
					Effects.Release(symbol)
				end
				return false
			end
			local hand = handPosition()
			local k = t / 0.3
			local look = core.Root.CFrame.LookVector
			 
			orb.CFrame = CFrame.new(hand)
			orb.Size = Vector3.one * (0.3 + k * 0.9)
			orb.Transparency = 0.35 - k * 0.2
			glow.Range = 6 + k * 8
			glow.Brightness = 1 + k * 4 + (flashed and 5 or 0)
			 
			if t >= 0.08 then
				if not symbol then
					symbol =
						cast:Add(core.Part("CardChargeSymbol", CFrame.new(hand), CARD_SIZE * 0.1, GOLD, 0.7))
					symbol.Material = Enum.Material.Neon
				end
				local f = math.clamp((t - 0.08) / 0.12, 0, 1)
				local eased = 1 - (1 - f) ^ 3
				local pos = hand + look * 1.8 + Vector3.new(0, 0.6, 0)
				symbol.Size = CARD_SIZE * (0.1 + 0.9 * eased)
				symbol.Transparency = 0.7 - 0.5 * eased
				symbol.CFrame = CFrame.lookAt(pos, pos + look) * CFrame.Angles(0, 0, (1 - eased) * math.pi)
			end
			 
			if t >= 0.16 and not suck then
				suck = cast:Add(core.Part("CardChargeSuck", CFrame.new(hand), Vector3.one * 8, GOLD, 1))
				suckEmitter = Instance.new("ParticleEmitter")
				suckEmitter.Texture = SPARKLE
				suckEmitter.Shape = Enum.ParticleEmitterShape.Sphere
				suckEmitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
				suckEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
				suckEmitter.Rate = 140
				suckEmitter.Speed = NumberRange.new(28, 32)
				suckEmitter.Lifetime = NumberRange.new(0.12, 0.14)
				suckEmitter.Color = ColorSequence.new(GOLD, WHITE)
				suckEmitter.LightEmission = 1
				suckEmitter.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.55),
					NumberSequenceKeypoint.new(1, 0.1),
				})
				suckEmitter.Parent = suck
				Effects.ReleaseAfter(suck, 0.5)
			end
			if suck then
				suck.CFrame = CFrame.new(hand)
				if t >= 0.26 and suckEmitter then
					suckEmitter.Rate = 0
					suckEmitter = nil
				end
			end
			 
			if t >= 0.25 and not flashed then
				flashed = true
				local flash = cast:Add(core.Part("CardChargeFlash", CFrame.new(hand), Vector3.one, WHITE, 0))
				flash.Shape = Enum.PartType.Ball
				flash.Material = Enum.Material.Neon
				Effects:Create(
					flash,
					TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Size = Vector3.one * 5, Transparency = 1 }
				):Play()
				Effects.ReleaseAfter(flash, 0.2)
			end
			return true
		end)
	end
	return chargeUp
end
function Visuals.afterimage(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local CARD_SIZE = ctx.CARD_SIZE
	local cardColor = ctx.cardColor
	local Effects = ctx.Effects
	local function afterimage(cframe, alpha, life)
		local ghost = cast:Add(core.Part("CardAfterimage", cframe, CARD_SIZE, cardColor, alpha))
		ghost.Material = Enum.Material.Neon
		Effects:Create(
			ghost,
			TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 1, Size = CARD_SIZE * Vector3.new(0.55, 0.55, 1) }
		):Play()
		Effects.ReleaseAfter(ghost, life + 0.1)
	end
	return afterimage
end
return table.freeze(Visuals)
