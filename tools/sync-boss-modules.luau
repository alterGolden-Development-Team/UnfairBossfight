-- Run in the boss Studio window after tools/sync-boss-modules.ps1. Copies the Source of the scripts listed in PATHS from the freshly built
-- boss project into the open place (adding a script that does not exist yet). Nothing else in the place is touched.
local PATHS = {
	"ReplicatedStorage.BossShared.Presentation.MeshKit",
	"ReplicatedStorage.BossShared.Presentation.DeathScythe.ScytheModel",
	"ServerScriptService.BossSystem.Players.Classes.ClassModels",
	"ServerScriptService.BossSystem.Attacks.P1.5.P1.5Raining.Visuals",
	"ServerScriptService.BossSystem.Combat.P5SonicBlaster",
	"ServerScriptService.BossSystem.Players.Classes.ClassModels.Gambler",
	"StarterPlayer.StarterPlayerScripts.BossClient.Players.ClassAnimator",
	"ReplicatedStorage.VFXEngine.Effects.Disorderer",
	"ServerScriptService.BossSystem.Attacks.P1.5.P1.5GoldenHand.Visuals",
	"ServerScriptService.BossSystem.Attacks.P1.5.P1.5GoldenHand.Behavior",
	"ServerScriptService.BossSystem.Phases.Phase5Transition",
	"ServerScriptService.BossSystem.Encounter.DifficultyService",
	"ServerScriptService.BossSystem.Encounter.Intake",
	"ServerScriptService.BossSystem.Players.Classes.ClassService",
	"ServerScriptService.BossSystem.BossController",
	"ServerScriptService.BossSystem.ProjectGuide",
	-- the lobby-redesign boss hooks the scripts above call: without them Intake errors and every lobby arrival plays as the default class
	"ServerScriptService.BossSystem.Encounter.Orbs",
	"ServerScriptService.BossSystem.Encounter.PlayerRecord",
	"ServerScriptService.BossSystem.Encounter.CashService",
	"ReplicatedStorage.BossShared.Classes.ClassUnlocks",
	"ServerScriptService.BossSystem.Players.Classes.TrainingDummy",
	"ServerScriptService.BossSystem.Players.PlayerEncounter",
	"StarterPlayer.StarterPlayerScripts.BossClient.Players.ClassClient",
	-- the shared lobby/boss modules (Orbs needs OrbConfig, Intake needs IntakeRules...); UnfairConfig.Env must be "Live" in the repo first
	"ReplicatedStorage.UnfairShared.UnfairConfig",
	"ReplicatedStorage.UnfairShared.CashLedger",
	"ReplicatedStorage.UnfairShared.CashRules",
	"ReplicatedStorage.UnfairShared.IntakeRules",
	"ReplicatedStorage.UnfairShared.LaunchPlan",
	"ReplicatedStorage.UnfairShared.OrbConfig",
	"ReplicatedStorage.UnfairShared.PartyState",
	"ReplicatedStorage.UnfairShared.ReturnRules",
	"ReplicatedStorage.UnfairShared.TeleportPayload",
	"ReplicatedStorage.UnfairShared.UnlockCheck",
	-- 2026-11-11: two trials only (alterGolden / Beyond alterGolden) and their lines, no training dummy in the fight, class puppets
	-- (the lobby showroom), the hidden Reality Orb + inventory, the Disorderer quest unlock
	"ReplicatedStorage.BossShared.Config.DifficultyConfig",
	"ServerScriptService.BossSystem.Encounter.DialogueScripts",
	"ServerScriptService.BossSystem.Encounter.EncounterStory",
	"ServerScriptService.BossSystem.Encounter.RealityOrb",
	"ServerScriptService.BossSystem.FightBootstrap",
	"ServerScriptService.BossSystem.Players.Classes.PuppetMotion",
	"ServerScriptService.BossSystem.Players.Classes.TrainingDummy",
	"StarterPlayer.StarterPlayerScripts.BossClient.Players.InventoryClient",
	"ReplicatedStorage.UnfairShared.ItemConfig",
	"ReplicatedStorage.UnfairShared.RecordStore",
	"ReplicatedStorage.UnfairShared.InventoryUI",
}
local built = game:GetObjects("rbxasset://unfair_bosssync.rbxm")[1]
local function walk(root, path, separator)
	local node = root
	for _, name in path do
		node = node and node:FindFirstChild(name)
	end
	return node
end
local report = {}
for _, full in PATHS do
	-- names may contain dots (P1.5): split on the known service then match children greedily
	local service, rest = full:match("^(%w+)%.(.+)$")
	local function resolve(root)
		local node = root
		local remaining = rest
		while node and remaining and remaining ~= "" do
			local found
			for _, child in node:GetChildren() do
				local n = child.Name
				if remaining == n or remaining:sub(1, #n + 1) == n .. "." then
					if not found or #n > #found.Name then
						found = child
					end
				end
			end
			if not found then
				return nil, node
			end
			remaining = remaining:sub(#found.Name + 2)
			node = found
		end
		return node
	end
	local source = resolve(built:FindFirstChild(service))
	local target, parentGuess = resolve(game:GetService(service))
	if not source then
		table.insert(report, full .. ": not in build")
	elseif target then
		target.Source = source.Source
		table.insert(report, full .. ": updated")
	elseif parentGuess then
		local copy = source:Clone()
		copy:ClearAllChildren()
		copy.Parent = parentGuess
		table.insert(report, full .. ": added under " .. parentGuess:GetFullName())
	end
end
built:Destroy()
return table.concat(report, "\n")
