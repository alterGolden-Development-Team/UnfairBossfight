-- Run in the boss Studio window (Edit mode, never in a playtest) after MeshKit.Fetch("BossCourt") and MeshKit.Fetch("BossFloor"). Safe to run again.
--   * the arena floor: the old ChronicleCourt (clock dial, buttresses, banners, plinths, fallen columns) and the FloorPattern lines / steps are
--     archived; a new ChronicleCourt holds the Blender paved court + medallion (lobby/blender/boss_floor.py). The two spawn-pad DiamondFills stay.
--   * the gate statue: the broken stone statue (RuinedApproach.BrokenR6GateStatue) is archived; RuinedApproach.AlterGateStatue is the Blender statue
--     of alterGolden (boss_court.py), standing where the old one stood and facing the arrivals.
--   * rocks: RuinedApproach.BattlefieldRuins and ExteriorRuins' BrokenColumn / ErodedColumnFoot / FallenMasonry / WeatheredGoldInlay are archived;
--     RuinedApproach.GateCourtRocks holds a few Blender boulders, a column stump, slabs and rubble around the statue.
-- Archived things go to ServerStorage.ArenaOldScenery (nothing is deleted).
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local kit = RS.BlenderMeshes
local arena = workspace.GoldenGrasslandArena
local approach = arena.RuinedApproach
local report = {}

local old = SS:FindFirstChild("ArenaOldScenery")
if not old then
	old = Instance.new("Folder")
	old.Name = "ArenaOldScenery"
	old.Parent = SS
end
local function archive(inst, bucket)
	local folder = old:FindFirstChild(bucket)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = bucket
		folder.Parent = old
	end
	inst.Parent = folder
end
local function flatten(model)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end
end

-- === floor ===================================================================================================================
local topY = arena.Grassland.Position.Y + arena.Grassland.Size.Y * 0.5
local court = arena:FindFirstChild("ChronicleCourt")
if court then
	if arena:GetAttribute("BlenderFloor") == true then
		court:Destroy()
	else
		archive(court, "ChronicleCourtOld")
	end
end
court = Instance.new("Model")
court.Name = "ChronicleCourt"
for _, name in { "ArenaTiles", "ArenaMedallion" } do
	local piece = kit[name]:Clone()
	piece:PivotTo(CFrame.new(0, topY, 0))
	for _, p in piece:GetChildren() do
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Name = name .. p.Name
		p.Parent = court
	end
	piece:Destroy()
end
court.Parent = arena
arena:SetAttribute("CourtDecorationVersion", 1) -- ArenaController.decorate() leaves a court with this version alone
arena:SetAttribute("BlenderFloor", true)
arena:SetAttribute("CourtDecorationPartCount", #court:GetDescendants())
local pattern = arena:FindFirstChild("FloorPattern")
local movedPattern = 0
if pattern then
	for _, p in pattern:GetChildren() do
		if p.Name == "Line" or p.Name == "Step" then
			archive(p, "FloorPatternOld")
			movedPattern += 1
		end
	end
end
table.insert(report, ("floor: %d parts, archived %d floor-pattern pieces"):format(#court:GetChildren(), movedPattern))

-- === statue ==================================================================================================================
local px, pz = -347, 33
local oldStatue = approach:FindFirstChild("BrokenR6GateStatue")
if oldStatue then
	local ped = oldStatue:FindFirstChild("Pedestal")
	if ped then
		px, pz = ped.Position.X, ped.Position.Z
	end
	archive(oldStatue, "BrokenR6GateStatue")
end
local previous = approach:FindFirstChild("AlterGateStatue")
if previous then
	previous:Destroy()
end
local function groundAt(x, z, ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(Vector3.new(x, 80, z), Vector3.new(0, -160, 0), params)
	return hit and hit.Position.Y or nil
end
local gy = groundAt(px, pz, {}) or 0
local facing = Vector3.new(-1, 0, -0.35).Unit -- toward the people arriving from the west spawn
local statue = kit.AlterStatue:Clone()
statue.Name = "AlterGateStatue"
statue:PivotTo(CFrame.lookAt(Vector3.new(px, gy, pz), Vector3.new(px, gy, pz) + facing))
flatten(statue)
statue.Parent = approach
table.insert(report, ("statue at (%.0f, %.2f, %.0f)"):format(px, gy, pz))

-- === rocks ===================================================================================================================
local function archiveChildren(parent, names, bucket)
	local n = 0
	if parent then
		for _, c in parent:GetChildren() do
			if names[c.Name] then
				archive(c, bucket)
				n += 1
			end
		end
	end
	return n
end
local ruins = approach:FindFirstChild("BattlefieldRuins")
local ruinCount = ruins and #ruins:GetChildren() or 0
if ruins then
	archive(ruins, "BattlefieldRuins")
end
local movedRocks = archiveChildren(approach:FindFirstChild("ExteriorRuins"), { BrokenColumn = true, ErodedColumnFoot = true, FallenMasonry = true, WeatheredGoldInlay = true }, "ExteriorRocks")
table.insert(report, ("archived %d battlefield ruin pieces and %d gateway rock pieces"):format(ruinCount, movedRocks))

local rocks = approach:FindFirstChild("GateCourtRocks")
if rocks then
	rocks:Destroy()
end
rocks = Instance.new("Model")
rocks.Name = "GateCourtRocks"
local LAYOUT = {
	{ "CourtBoulderA", px - 15, pz + 17, 40, 1.0 },
	{ "CourtBoulderB", px + 17, pz + 19, 200, 1.0 },
	{ "CourtRockCluster", px - 19, pz - 11, 75, 1.0 },
	{ "CourtColumnStump", px - 29, pz + 7, 20, 0.9 },
	{ "CourtSlab", px + 9, pz - 12, 15, 1.0 },
	{ "CourtSlab", px - 10, pz + 16, 130, 0.8 },
	{ "CourtRubble", px + 11, pz - 5, 0, 1.0 },
	{ "CourtRubble", px - 13, pz - 6, 70, 1.0 },
	{ "CourtRubble", px - 8, pz + 12, 150, 1.2 },
	{ "CourtRubble", px + 12, pz + 11, 230, 1.0 },
	{ "CourtRubble", px - 21, pz + 3, 300, 1.1 },
}
local placed = 0
for _, row in LAYOUT do
	local name, x, z, yaw, scale = row[1], row[2], row[3], row[4], row[5]
	local y = groundAt(x, z, { statue, rocks })
	if y and kit:FindFirstChild(name) then
		local m = kit[name]:Clone()
		if scale ~= 1 then
			m:ScaleTo(scale)
		end
		m:PivotTo(CFrame.new(x, y - 0.15, z) * CFrame.Angles(0, math.rad(yaw), 0))
		flatten(m)
		m.Parent = rocks
		placed += 1
	end
end
rocks.Parent = approach
table.insert(report, ("placed %d rock props"):format(placed))
return table.concat(report, "\n")
