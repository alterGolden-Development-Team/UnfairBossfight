local Visuals = {}
function Visuals.shards(ctx)
	local HOT = ctx.HOT
	local function shards(host, count, color, speed)
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "StolenSecondShards"
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(0.3, 0.6)
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
		emitter:Emit(count)
		return emitter
	end
	return shards
end
function Visuals.flourish(ctx)
	local Effects = ctx.Effects
	local actor = ctx.actor
	local floorY = ctx.floorY
	local core = ctx.core
	local GOLD = ctx.GOLD
	local shards = ctx.shards
	local function flourish(position, color, count)
		local fx = Effects.NewCast(actor, "StolenSecondFlourish", 1)
		fx.TimeStopExempt = true
		local floor = Vector3.new(position.X, floorY(position) + 0.2, position.Z)
		local disc = fx:Add(core.Part("StolenSecondPulse", CFrame.new(floor), Vector3.new(0.14, 1, 1), color, 0.5))
		disc.Shape = Enum.PartType.Cylinder
		local host = fx:Add(core.Part("StolenSecondBurst", CFrame.new(position), Vector3.one, GOLD, 1))
		fx:Add(shards(host, count, color, 22))
		local began = fx:Now()
		fx:Step(function(_, now)
			local t = math.clamp((now - began) / 0.4, 0, 1)
			local radius = 2 + 8 * (1 - (1 - t) ^ 3)
			disc.Size = Vector3.new(0.14, radius * 2, radius * 2)
			disc.CFrame = CFrame.new(floor) * CFrame.Angles(0, 0, math.pi * 0.5)
			disc.Transparency = 0.5 + 0.5 * t
			return t < 1
		end)
	end
	return flourish
end
return table.freeze(Visuals)
