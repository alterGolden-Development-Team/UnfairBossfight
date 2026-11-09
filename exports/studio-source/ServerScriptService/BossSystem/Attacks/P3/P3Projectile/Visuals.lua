local Visuals = {}
function Visuals.flatRing(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local Effects = ctx.Effects
	local QUINT = ctx.QUINT
	local OUT = ctx.OUT
	local function flatRing(position, color, fromSize, toSize, time, thickness, startTransparency)
		thickness = thickness or 0.3
		local p = cast:Add(
			core.Part(
				"ProjectileRing",
				CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2),
				Vector3.new(thickness, fromSize, fromSize),
				color,
				startTransparency or 0.25
			)
		)
		p.Shape = Enum.PartType.Cylinder
		p.Material = Enum.Material.Neon
		Effects:Create(
			p,
			TweenInfo.new(time, QUINT, OUT),
			{ Size = Vector3.new(thickness, toSize, toSize), Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(p, time + 0.1)
		return p
	end
	return flatRing
end
function Visuals.ringAlong(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local Effects = ctx.Effects
	local QUINT = ctx.QUINT
	local OUT = ctx.OUT
	local function ringAlong(position, normal, color, fromSize, toSize, time)
		local p = cast:Add(
			core.Part(
				"ProjectileBounceRing",
				CFrame.lookAt(position, position + normal) * CFrame.Angles(0, math.rad(90), 0),
				Vector3.new(0.3, fromSize, fromSize),
				color,
				0.2
			)
		)
		p.Shape = Enum.PartType.Cylinder
		p.Material = Enum.Material.Neon
		Effects:Create(
			p,
			TweenInfo.new(time, QUINT, OUT),
			{ Size = Vector3.new(0.3, toSize, toSize), Transparency = 1 }
		):Play()
		Effects.ReleaseAfter(p, time + 0.1)
	end
	return ringAlong
end
function Visuals.sphere(ctx)
	local cast = ctx.cast
	local core = ctx.core
	local Effects = ctx.Effects
	local QUINT = ctx.QUINT
	local OUT = ctx.OUT
	local function sphere(position, color, fromSize, toSize, time, startTransparency)
		local p = cast:Add(
			core.Part(
				"ProjectileBlastSphere",
				CFrame.new(position),
				Vector3.one * fromSize,
				color,
				startTransparency
			)
		)
		p.Shape = Enum.PartType.Ball
		p.Material = Enum.Material.Neon
		Effects:Create(p, TweenInfo.new(time, QUINT, OUT), { Size = Vector3.one * toSize, Transparency = 1 })
			:Play()
		Effects.ReleaseAfter(p, time + 0.1)
		return p
	end
	return sphere
end
return table.freeze(Visuals)
