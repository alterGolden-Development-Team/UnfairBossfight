local Assets = script.Parent.Parent:WaitForChild("Assets")
local NEON = Enum.Material.Neon
local MESH_RADIUS = 7.16
local MESH_LIFT = 2.85
local WHITE = Color3.new(1, 1, 1)
local T = {}

local function layer(g, width, color, alpha)
	local template = Assets.ArcSlash
	local p = template:Clone()
	p.Size = template.Size * (width / template.Size.X)
	p.TextureID = ""
	p.Material = NEON
	p.Color = color
	p.Transparency = alpha
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Parent = g.Folder
	return p
end

function T.Draw(E, d)
	local g = E.Group("ClassSlash")
	local radius = d.Radius
	local life = math.max(0.16, d.Time)
	local base = d.Frame * CFrame.Angles(math.rad(9), 0, 0)
	local flip = d.Reverse and -1 or 1
	local count = math.max(1, math.ceil(d.Arc / math.rad(190)))
	local deep = d.Color:Lerp(Color3.new(), 0.25)
	local specs = {
		{ Width = 2.24, Color = deep, Alpha = 0.62, Spin = 0.9 },
		{ Width = 2.08, Color = d.Color, Alpha = 0.22, Spin = 1 },
		{ Width = 2, Color = d.Core:Lerp(d.Color, 0.15), Alpha = 0, Spin = 1.08 },
	}
	local pieces = {}
	for i = 1, count do
		local center = count == 1 and 0 or -d.Arc / 2 + (i - 0.5) * d.Arc / count
		for _, spec in ipairs(specs) do
			local p = layer(g, radius * spec.Width, spec.Color, 1)
			pieces[#pieces + 1] = { Part = p, Center = center, Spec = spec }
		end
	end
	local tipAngle = (d.Arc / 2) * flip
	local tip = base * CFrame.new(math.sin(tipAngle) * radius, 0, -math.cos(tipAngle) * radius)
	local anchor = E.Anchor(g, CFrame.new(tip.Position))
	E.Sprite(anchor, { tex = "star.anime", size = { { 0, radius * 0.1 }, { 0.2, radius * 0.5 }, { 1, 0 } }, alpha = { { 0, 0 }, { 0.7, 0 }, { 1, 1 } }, color = WHITE, rot = { 45, 45 } }, life * 0.8)
	E.Sprite(anchor, { tex = "flare.big", size = { { 0, radius * 0.15 }, { 0.2, radius * 0.6 }, { 1, radius * 0.3 } }, alpha = { { 0, 0 }, { 0.5, 0.35 }, { 1, 1 } }, color = d.Color }, life)
	E.Emit(anchor, { tex = "dot", orient = "velocity", squash = { { 0, 3 }, { 1, 0 } }, size = { { 0, 0.5 }, { 1, 0 } }, color = { { 0, WHITE }, { 1, d.Color } }, life = { 0.18, 0.4 }, speed = { radius * 3, radius * 8 }, spread = 70, dir = Enum.NormalId.Top }, 14)
	local start = os.clock()
	local lift = MESH_LIFT / MESH_RADIUS
	E.Step(g, function()
		local k = math.clamp((os.clock() - start) / life, 0, 1)
		local eased = 1 - (1 - k) ^ 3
		local grow = 0.8 + 0.38 * eased
		for _, piece in ipairs(pieces) do
			local spec = piece.Spec
			local sweep = -flip * d.Arc * 0.24 * (1 - eased) * spec.Spin
			local r = radius * grow
			local frame = base * CFrame.Angles(0, -(piece.Center + sweep), 0)
			local matrix = CFrame.fromMatrix(Vector3.new(0, 0, -r * lift), Vector3.xAxis * flip, -Vector3.zAxis, Vector3.yAxis * flip)
			piece.Part.Size = Assets.ArcSlash.Size * (r * spec.Width / Assets.ArcSlash.Size.X)
			piece.Part.CFrame = frame * matrix
			piece.Part.Transparency = spec.Alpha + (1 - spec.Alpha) * k ^ 2.2
		end
		if k >= 1 then
			g:Destroy()
			return false
		end
	end)
end

return T
