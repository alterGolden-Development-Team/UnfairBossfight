 
local Visuals = {}
function Visuals.part(ctx)
	local core = ctx.core
	local function part(cast, name, frame, size, color, alpha)
		return cast:Add(core.Part(name, frame, size, color, alpha))
	end
	return part
end
function Visuals.beam(ctx)
	local BRIGHT = ctx.BRIGHT
	local GOLD = ctx.GOLD
	local function beam(anchor, name, from, finish, width, curve)
		local first, last = Instance.new("Attachment"), Instance.new("Attachment")
		first.Position, last.Position = from, finish
		first.Parent, last.Parent = anchor, anchor
		if name:find("Arc", 1, true) then
			first.Orientation, last.Orientation = Vector3.new(0, 90, 0), Vector3.new(0, 90, 0)
		end
		local strand = Instance.new("Beam")
		strand.Name = name
		strand.Attachment0 = first
		strand.Attachment1 = last
		strand.Width0, strand.Width1 = width, width
		strand.Color = ColorSequence.new(BRIGHT, GOLD)
		strand.FaceCamera = true
		strand.LightEmission = 1
		strand.Transparency = NumberSequence.new(0.1)
		strand.Segments = 10
		strand.CurveSize0, strand.CurveSize1 = curve or 0, -(curve or 0)
		strand.Parent = anchor
		return strand
	end
	return beam
end
function Visuals.disc(ctx)
	local part = ctx.part
	local function disc(cast, name, frame, size, color, alpha, material)
		local piece = part(cast, name, frame, size, color, alpha)
		piece.Shape = Enum.PartType.Cylinder
		piece.Material = material or Enum.Material.Neon
		return piece
	end
	return disc
end
function Visuals.ball(ctx)
	local part = ctx.part
	local function ball(cast, name, frame, size, color, alpha)
		local piece = part(cast, name, frame, size, color, alpha)
		piece.Shape = Enum.PartType.Ball
		piece.Material = Enum.Material.Neon
		return piece
	end
	return ball
end
function Visuals.point(ctx)
	local function point(anchor, position)
		local attachment = Instance.new("Attachment")
		attachment.Position = position
		attachment.Parent = anchor
		return attachment
	end
	return point
end
function Visuals.link(ctx)
	local function link(anchor, from, to, width, color, alpha)
		local strand = Instance.new("Beam")
		strand.Name = "RoyalBowLine"
		strand.Attachment0 = from
		strand.Attachment1 = to
		strand.Width0, strand.Width1 = width, width
		strand.Color = ColorSequence.new(color)
		strand.FaceCamera = true
		strand.LightEmission = 1
		strand.Transparency = NumberSequence.new(alpha)
		strand.Segments = 1
		strand.Parent = anchor
		return strand
	end
	return link
end
function Visuals.ring(ctx)
	local point = ctx.point
	local link = ctx.link
	local function ring(anchor, radius, segments, width, color, alpha, vertical, offset, dashed)
		local points, beams = {}, {}
		for index = 1, segments do
			local angle = (index - 1) * math.pi * 2 / segments
			local x, y = math.cos(angle) * radius, math.sin(angle) * radius
			points[index] = point(anchor, vertical and Vector3.new(x, y, offset or 0) or Vector3.new(x, offset or 0, y))
		end
		for index = 1, segments do
			if not dashed or index % 2 == 1 then
				beams[#beams + 1] = link(anchor, points[index], points[index % segments + 1], width, color, alpha)
			end
		end
		return beams, points
	end
	return ring
end
function Visuals.setAlpha(ctx)
	local function setAlpha(beams, alpha)
		local sequence = NumberSequence.new(math.clamp(alpha, 0, 1))
		for _, strand in ipairs(beams) do
			strand.Transparency = sequence
		end
	end
	return setAlpha
end
function Visuals.recolor(ctx)
	local function recolor(beams, color)
		local sequence = ColorSequence.new(color)
		for _, strand in ipairs(beams) do
			strand.Color = sequence
		end
	end
	return recolor
end
function Visuals.resizeRing(ctx)
	local function resizeRing(points, radius, vertical, offset)
		local count = #points
		for index, attachment in ipairs(points) do
			local angle = (index - 1) * math.pi * 2 / count
			local x, y = math.cos(angle) * radius, math.sin(angle) * radius
			attachment.Position = vertical and Vector3.new(x, y, offset or 0) or Vector3.new(x, offset or 0, y)
		end
	end
	return resizeRing
end
return table.freeze(Visuals)
