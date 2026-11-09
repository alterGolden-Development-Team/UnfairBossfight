local Visuals = {}
function Visuals.flash(ctx)
	local Placement = ctx.Placement
	local Effects = ctx.Effects
	local BRIGHT = ctx.BRIGHT
	local Runtime = ctx.Runtime
	local GOLD = ctx.GOLD
	local function flash(frame, name, cast)
		local ground = Placement.GroundPoint(frame.Position) or frame.Position - Vector3.new(0, 3, 0)
		local orb = Effects.AcquirePart()
		orb.Name = name .. "Flash"
		orb.Shape = Enum.PartType.Ball
		orb.Size = Vector3.new(3.5, 5, 3.5)
		orb.CFrame = frame
		orb.Material = Enum.Material.Neon
		orb.Color = BRIGHT
		orb.Transparency = 0.25
		orb.Parent = Runtime.Effects
		cast:Add(orb)
		Effects:Create(
			orb,
			TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Size = Vector3.new(11, 0.2, 11), Transparency = 1 }
		):Play()
		 
		for index = 0, 5 do
			local angle = index * math.pi / 3
			local ray = Effects.AcquirePart()
			ray.Name = name .. "Ray"
			ray.Size = Vector3.new(0.12, 6, 0.12)
			ray.CFrame = CFrame.new(ground + Vector3.new(math.cos(angle) * 2.8, 3, math.sin(angle) * 2.8))
			ray.Material = Enum.Material.Neon
			ray.Color = GOLD
			ray.Transparency = 0.1
			ray.Parent = Runtime.Effects
			cast:Add(ray)
			Effects:Create(ray, TweenInfo.new(0.42), { Size = Vector3.new(0.03, 9, 0.03), Transparency = 1 }):Play()
		end
	end
	return flash
end
return table.freeze(Visuals)
