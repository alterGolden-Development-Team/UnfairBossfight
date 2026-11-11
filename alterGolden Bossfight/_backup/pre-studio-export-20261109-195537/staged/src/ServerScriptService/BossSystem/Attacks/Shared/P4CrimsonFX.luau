 
 
local BossSystem = script:FindFirstAncestor("BossSystem")
local FX = require(BossSystem.Attacks.Shared.ShieldBreakVFX)
local api = {
	FX = FX,
	CRIMSON = Color3.fromRGB(226, 34, 58),
	DEEP = Color3.fromRGB(128, 10, 30),
	ROSE = Color3.fromRGB(255, 96, 128),
	BLUSH = Color3.fromRGB(255, 214, 226),
	GOLD = Color3.fromRGB(255, 205, 70),
	WHITE = Color3.fromRGB(255, 244, 236),
	DUST = Color3.fromRGB(176, 150, 140),
}
function api.Context(core)
	return {
		Core = core,
		Root = core.Root,
		Filter = function()
			return core.Params()
		end,
		Part = function(cast, name, frame, size, color, alpha)
			return cast:Add(core.Part(name, frame, size, color, alpha or 0))
		end,
	}
end
 
function api.Disc(ctx, cast, name, position, diameter, color, alpha, life)
	local d = FX.Temp(ctx, cast, name, CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2), Vector3.new(0.08, diameter, diameter),
		color, alpha, life)
	d.Shape = Enum.PartType.Cylinder
	return d
end
 
 
function api.BeamRing(ctx, cast, name, center, radius, color, width, segments)
	segments = segments or 28
	local anchor = FX.Temp(ctx, cast, name, CFrame.new(center), Vector3.one * 0.2, color, 1)
	local points, beams = {}, {}
	for i = 1, segments do
		local a = Instance.new("Attachment")
		a.Parent = anchor
		points[i] = a
	end
	for i = 1, segments do
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1 = points[i], points[i % segments + 1]
		b.FaceCamera, b.Segments, b.LightEmission, b.LightInfluence = true, 1, 1, 0
		b.Color = ColorSequence.new(color)
		b.Parent = anchor
		beams[i] = b
	end
	local function set(r, alpha, w)
		for i, a in ipairs(points) do
			local ang = (i - 1) / segments * math.pi * 2
			a.Position = Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)
		end
		local t = NumberSequence.new(math.clamp(alpha, 0, 1))
		for _, b in ipairs(beams) do
			b.Transparency = t
			b.Width0, b.Width1 = w, w
		end
	end
	set(radius, 0, width)
	return anchor, set
end
return api
