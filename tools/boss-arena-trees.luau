-- Run in the boss Studio window (Edit mode, never in a playtest). Clears the arena's scenery of trees that are where they should not be:
--   * trees whose trunk stands on the castle wall tiers (SurroundingWalls, Tier3 outline + 4 studs),
--   * trees whose crown overlaps a tower (Scenery.Spires) or a ruin (Scenery.Ruins),
--   * trees in the gate corridor in front of the entrance (west end, |z| < 48).
-- Removed trees are parked in ServerStorage.ArenaOldScenery.TreesRemoved (nothing is deleted). Safe to run again.
local arena = workspace.GoldenGrasslandArena
local trees = arena.Scenery.Trees
local old = game.ServerStorage:FindFirstChild("ArenaOldScenery")
if not old then
	old = Instance.new("Folder")
	old.Name = "ArenaOldScenery"
	old.Parent = game.ServerStorage
end
local parking = old:FindFirstChild("TreesRemoved")
if not parking then
	parking = Instance.new("Folder")
	parking.Name = "TreesRemoved"
	parking.Parent = old
end

local tier3 = arena.SurroundingWalls.Tier3
local wallCF, wallSize = tier3:GetBoundingBox()
local wallHX, wallHZ = wallSize.X * 0.5 + 4, wallSize.Z * 0.5 + 4

local obstacles = {}
for _, group in { arena.Scenery.Spires, arena.Scenery.Ruins } do
	for _, m in group:GetChildren() do
		local cf, sz = m:GetBoundingBox()
		table.insert(obstacles, { Vector2.new(cf.X, cf.Z), math.max(sz.X, sz.Z) * 0.5 * 0.75, m.Name })
	end
end

local removed = { Wall = 0, Obstacle = 0, Gate = 0 }
for _, tree in trees:GetChildren() do
	local pivot = tree:GetPivot().Position
	local cf, sz = tree:GetBoundingBox()
	local crown = math.max(sz.X, sz.Z) * 0.5 * 0.7
	local p = Vector2.new(pivot.X, pivot.Z)
	local why
	if math.abs(pivot.X - wallCF.X) < wallHX and math.abs(pivot.Z - wallCF.Z) < wallHZ then
		why = "Wall"
	elseif pivot.X < wallCF.X - wallHX + 20 and math.abs(pivot.Z) < 48 then
		why = "Gate"
	else
		for _, o in obstacles do
			if (p - o[1]).Magnitude < crown + o[2] + 3 then
				why = "Obstacle"
				break
			end
		end
	end
	if why then
		removed[why] += 1
		tree.Parent = parking
	end
end
print(string.format("trees removed: wall %d, tower/ruin %d, gate corridor %d; left %d", removed.Wall, removed.Obstacle, removed.Gate, #trees:GetChildren()))
return removed
