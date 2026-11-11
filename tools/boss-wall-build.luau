-- Run in the boss Studio window (Edit mode, never in a playtest) after MeshKit.Fetch("BossWall"). Rebuilds the arena's castle wall and the
-- boss entrance gate from the BossWall kit (lobby/blender/boss_wall.py). Safe to run again: it replaces what it built before.
--   * SurroundingWalls.BlenderWall: three tiers of wall bays and corner towers (the invisible TerraceBlock colliders stay, so collision,
--     the boss's wall perch and the knockback barriers are untouched; the old rock skins are destroyed, the gold caps and steps hidden)
--   * RuinedApproach.SwordGate: two door leaves (ClosedFrame / OpenFrame like every gate piece, so ArenaController.SetSealed swings them)
--   * RuinedApproach.ExteriorRuins: the gatehouse frame and its colliders; the old jambs, banners and columns in its way are removed
local RS = game:GetService("ReplicatedStorage")
local kit = RS.BlenderMeshes
local arena = workspace.GoldenGrasslandArena
local walls = arena.SurroundingWalls
local approach = arena.RuinedApproach
local report = {}

local function ry(a)
	return CFrame.Angles(0, a, 0)
end

-- a prepared piece as a list of { part, rel } (rel = the part's CFrame in the piece's own space, scaled per axis)
local function pieces(name, scale)
	scale = scale or Vector3.one
	local list = {}
	for _, p in kit[name]:GetDescendants() do
		if p:IsA("BasePart") then
			local part = p:Clone()
			local rel = part.CFrame
			part.Size = part.Size * scale
			table.insert(list, { part = part, rel = CFrame.new(rel.Position * scale) * rel.Rotation })
		end
	end
	return list
end

-- 1. old wall visuals -------------------------------------------------------------------------------------------------------------
local old = walls:FindFirstChild("BlenderWall")
if old then
	old:Destroy()
end
local doomed, hidden = {}, 0
for _, d in walls:GetDescendants() do
	if d.Name == "RockSkin" then
		table.insert(doomed, d)
	elseif d.Name == "TerraceCap" or d.Name == "TerraceStep" then
		d.Transparency = 1 -- they stay as colliders
		hidden += 1
	end
end
for _, d in doomed do
	d:Destroy()
end
table.insert(report, "rock skins removed " .. #doomed .. ", caps/steps hidden " .. hidden)

-- 2. the wall --------------------------------------------------------------------------------------------------------------------
local folder = Instance.new("Folder")
folder.Name = "BlenderWall"
folder.Parent = walls
-- face lines (where the wall meets the arena side), deck heights, body depth scale (the bay body is 22 deep)
local TIERS = {
	{ fx = 310, fz = 230, deck = 11.7, depth = 16 / 22, gap = 33, gateTowers = false },
	{ fx = 326.5, fz = 246.5, deck = 23.5, depth = 1, gap = 70, gateTowers = true },
	{ fx = 348, fz = 268, deck = 35.5, depth = 1, gap = 70, gateTowers = true },
}
local placed = 0
local function put(list, frame, parent, name)
	local model = Instance.new("Model")
	model.Name = name
	for _, item in list do
		item.part.CFrame = frame * item.rel
		item.part.Parent = model
	end
	model.Parent = parent
	placed += 1
	if placed % 20 == 0 then
		task.wait()
	end
	return model
end

for index, tier in TIERS do
	local base = tier.deck - 14
	local sub = Instance.new("Folder")
	sub.Name = "Tier" .. index
	sub.Parent = folder
	local function run(side, a, b)
		local len = b - a
		local n = math.max(1, math.floor(len / 24 + 0.5))
		local sx = len / (n * 24)
		for i = 1, n do
			local c = a + (i - 0.5) * len / n
			local variant = ((i + index * 2 + #side) % 3 == 0) and "WallBayB" or "WallBayA"
			local frame
			if side == "S" then
				frame = CFrame.new(c, base, -tier.fz)
			elseif side == "N" then
				frame = CFrame.new(c, base, tier.fz) * ry(math.pi)
			elseif side == "W" then
				frame = CFrame.new(-tier.fx, base, c) * ry(math.pi / 2)
			else
				frame = CFrame.new(tier.fx, base, c) * ry(-math.pi / 2)
			end
			put(pieces(variant, Vector3.new(sx, 1, tier.depth)), frame, sub, side .. i)
		end
	end
	run("N", -(tier.fx - 4), tier.fx - 4)
	run("S", -(tier.fx - 4), tier.fx - 4)
	run("E", -(tier.fz - 4), tier.fz - 4)
	run("W", -(tier.fz - 4), -tier.gap)
	run("W", tier.gap, tier.fz - 4)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			put(pieces("WallTower"), CFrame.new(sx * (tier.fx + 5), base, sz * (tier.fz + 5)), sub, "Corner" .. sx .. sz)
		end
	end
	if tier.gateTowers then
		for _, sz in { -1, 1 } do
			put(pieces("WallTower"), CFrame.new(-(tier.fx + 5), base, sz * 61), sub, "GateEnd" .. sz)
		end
	end
end
table.insert(report, "wall parts placed: " .. placed)

-- 3. the gate ---------------------------------------------------------------------------------------------------------------------
local GATE_X, OPENING = -314, 44
local gate = approach.SwordGate
for _, c in gate:GetChildren() do
	if c.Name ~= "SealedGateCollision" then
		c:Destroy()
	end
end
for _, leafFrame in {
	{ name = "LeafSouth", hinge = Vector3.new(GATE_X, 0, -OPENING / 2), closed = 0, open = -math.pi / 2 },
	{ name = "LeafNorth", hinge = Vector3.new(GATE_X, 0, OPENING / 2), closed = math.pi, open = math.pi * 1.5 },
} do
	local closed = CFrame.new(leafFrame.hinge) * ry(leafFrame.closed)
	local open = CFrame.new(leafFrame.hinge) * ry(leafFrame.open)
	for i, item in pieces("BossGateLeaf") do
		local part = item.part
		part.Name = leafFrame.name .. i
		part:SetAttribute("ClosedFrame", closed * item.rel)
		part:SetAttribute("OpenFrame", open * item.rel)
		part:SetAttribute("BlocksEntrance", false)
		part.CFrame = open * item.rel
		part.Parent = gate
	end
end

local ext = approach.ExteriorRuins
local removeNames = { BrokenGateJamb = true, GateJambFoot = true, RuinedBannerPole = true, TatteredBanner = true, FadedBannerGlyph = true }
local clutter = { BrokenColumn = true, ErodedColumnFoot = true, WeatheredGoldInlay = true, FallenMasonry = true }
local removed = 0
for _, c in ext:GetChildren() do
	if c.Name == "GateFrame" or c.Name == "GateTowerCollider" or c.Name == "GateWallFill" then
		c:Destroy()
	elseif removeNames[c.Name] then
		c:Destroy()
		removed += 1
	elseif clutter[c.Name] and c:IsA("BasePart") then
		local p = c.Position
		if p.X > -326 and p.X < -302 and math.abs(p.Z) > 17 and math.abs(p.Z) < 37 then
			c:Destroy()
			removed += 1
		end
	end
end
local statue = approach:FindFirstChild("BrokenR6GateStatue")
if statue and statue:GetPivot().Position.X > -330 then
	statue:PivotTo(statue:GetPivot() + Vector3.new(-26, 0, 0)) -- clear of the gatehouse
	table.insert(report, "moved the broken gate statue out of the gatehouse")
end
put(pieces("BossGateFrame"), CFrame.new(GATE_X, 0, 0), ext, "GateFrame")
local function collider(name, size, position)
	local p = Instance.new("Part")
	p.Name, p.Size, p.Position = name, size, position
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, true, true, false, 1
	p.Parent = ext
end
collider("GateTowerCollider", Vector3.new(18, 27, 11), Vector3.new(GATE_X, 13.5, -27.5))
collider("GateTowerCollider", Vector3.new(18, 27, 11), Vector3.new(GATE_X, 13.5, 27.5))
collider("GateWallFill", Vector3.new(16, 17, 12), Vector3.new(-318, 3.5, 39)) -- the old gap between the gate and the first wall block
table.insert(report, "gate rebuilt, " .. removed .. " old pieces removed")
return table.concat(report, "\n")
