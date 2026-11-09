--[[
 ArenaRuin - the first Wild Hunt of a fight burns the world outside the arena. Ruin sets workspace ArenaRuinedAt;
 every client (BossClient.Presentation.ArenaRuinClient) then crumbles the castle walls, trees, spires and ruins past
 the arena barriers, chars them and lights golden fires across them. The arena itself is untouched, but a ring of
 fire burns along its rim (BossShared.Config.ArenaRuinFires lays it out): anyone touching one of those fires takes
 EncounterConfig.ArenaFireDamage every ArenaFireTick seconds. The attribute is cleared when the encounter ends, so
 the next attempt starts on the whole map again.
]]
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Fires = require(Shared.Config.ArenaRuinFires)
local Config = require(Shared.Config.EncounterConfig)
local B = script:FindFirstAncestor("BossSystem")
local api = {}
local source  -- the boss whose Wild Hunt lit the ring; its burns count as his damage
local burning = false

function api.Ruined()
	return workspace:GetAttribute("ArenaRuinedAt") ~= nil
end

function api.Ruin(actor)
	if api.Ruined() then return false end
	source = actor
	workspace:SetAttribute("ArenaRuinedAt", workspace:GetServerTimeNow())
	return true
end

function api.Restore()
	workspace:SetAttribute("ArenaRuinedAt", nil)
end

local function burn()
	if burning then return end
	burning = true
	local Encounter = require(B.Players.PlayerEncounter)
	local arena = workspace:FindFirstChild("GoldenGrasslandArena")
	local rim = Fires.Rim(arena and arena:FindFirstChild("Grassland"))
	while true do
		local at = workspace:GetAttribute("ArenaRuinedAt")
		if not at then break end
		local elapsed = workspace:GetServerTimeNow() - at
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if root and Fires.Touching(rim, root.Position, elapsed) then
				pcall(Encounter.Damage, char, Config.ArenaFireDamage, source, nil, { Skill = "ArenaFire" })
			end
		end
		task.wait(Config.ArenaFireTick)
	end
	burning = false
end

workspace:GetAttributeChangedSignal("ArenaRuinedAt"):Connect(function()
	if api.Ruined() then
		task.spawn(burn)
	else
		source = nil
	end
end)

workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(function()
	if workspace:GetAttribute("EncounterStarted") ~= true then api.Restore() end
end)

return api
