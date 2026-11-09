local Visuals = {}
function Visuals.part(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local GOLD = ctx.GOLD
	local function part(name, frame, size, color, alpha)
		return cast:Add(core.Part(name, frame, size, color or GOLD, alpha or 0.1))
	end
	return part
end
function Visuals.drop(ctx)
	local Effects = ctx.Effects
	local function drop(owner, object)
		owner.objects[object] = nil
		Effects.Release(object)
	end
	return drop
end
function Visuals.release(ctx)
	local drop = ctx.drop
	local cast = ctx.cast
	local function release(object)
		drop(cast, object)
	end
	return release
end
function Visuals.disc(ctx)
	local core = ctx.core
	local function disc(owner, position, diameter, color, alpha, normal)
		local frame = normal and CFrame.lookAt(position, position + normal) * CFrame.Angles(0, math.pi / 2, 0)
			or CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
		local piece =
			owner:Add(core.Part("P3DashDisc", frame, Vector3.new(0.2, diameter, diameter), color, alpha))
		piece.Shape = Enum.PartType.Cylinder
		piece.Material = Enum.Material.Neon
		return piece
	end
	return disc
end
function Visuals.pulse(ctx)
	local disc = ctx.disc
	local Effects = ctx.Effects
	local drop = ctx.drop
	local function pulse(owner, position, from, to, duration, color, alpha, normal)
		local wave = disc(owner, position, from, color, alpha, normal)
		Effects:Create(
			wave,
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(0.2, to, to), Transparency = 1 }
		):Play()
		owner:Schedule(duration + 0.05, function()
			drop(owner, wave)
		end)
	end
	return pulse
end
function Visuals.fling(ctx)
	local core = ctx.core
	local Run = ctx.Run
	local drop = ctx.drop
	local function fling(owner, origin, count, color, size, speed, life, gravity, lift)
		for index = 1, count do
			local angle = index / count * math.pi * 2 + index * 0.7
			local velocity = Vector3.new(math.cos(angle), 0, math.sin(angle))
					* speed
					* (0.5 + (index % 3) * 0.25)
				+ Vector3.new(0, lift * (0.7 + (index % 4) * 0.15), 0)
			local chunk = owner:Add(core.Part("P3DashDebris", CFrame.new(origin), size, color, 0.1))
			chunk.Material = Enum.Material.Neon
			local born = os.clock()
			local spin = index % 2 == 0 and 6 or -6
			task.spawn(function()
				while not owner.closed and chunk:IsDescendantOf(workspace) do
					local age = os.clock() - born
					if age >= life then
						break
					end
					local position = origin + velocity * age - Vector3.new(0, 0.5 * gravity * age * age, 0)
					chunk.CFrame = CFrame.new(position) * CFrame.Angles(age * spin, age * 4, 0)
					chunk.Transparency = 0.1 + 0.9 * (age / life) ^ 2
					Run.Heartbeat:Wait()
				end
				if not owner.closed and chunk:IsDescendantOf(workspace) then
					drop(owner, chunk)
				end
			end)
		end
	end
	return fling
end
function Visuals.sigil(ctx)
	local core = ctx.core
	local function sigil(owner, center, radius, color)
		local bars = {}
		local function ring(r, count, width)
			for index = 1, count do
				local angle = (index - 0.5) / count * math.pi * 2
				local position = center + Vector3.new(math.cos(angle) * r, 0.12, math.sin(angle) * r)
				local tangent = Vector3.new(-math.sin(angle), 0, math.cos(angle))
				local bar = owner:Add(
					core.Part(
						"P3DashSigil",
						CFrame.lookAt(position, position + tangent),
						Vector3.new(width, 0.1, 2 * math.pi * r / count * 1.08),
						color,
						1
					)
				)
				bar.Material = Enum.Material.Neon
				bars[#bars + 1] = bar
			end
		end
		ring(radius, 24, 0.3)
		ring(radius * 0.55, 12, 0.22)
		for index = 0, 2 do
			local bar = owner:Add(
				core.Part(
					"P3DashSigil",
					CFrame.new(center + Vector3.new(0, 0.13, 0)) * CFrame.Angles(0, index * math.pi / 3, 0),
					Vector3.new(0.2, 0.08, radius * 1.92),
					color,
					1
				)
			)
			bar.Material = Enum.Material.Neon
			bars[#bars + 1] = bar
		end
		return bars
	end
	return sigil
end
Visuals.buildBox = require(script.Parent.Box).buildBox
Visuals.placeBox = require(script.Parent.Box).placeBox
Visuals.flashEdges = require(script.Parent.Box).flashEdges
Visuals.boxExit = require(script.Parent.Box).boxExit
Visuals.buildSword = require(script.Parent.Swords).buildSword
Visuals.placeSwords = require(script.Parent.Swords).placeSwords
Visuals.swordDirection = require(script.Parent.Swords).swordDirection
return table.freeze(Visuals)
