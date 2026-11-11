 
local Players = game:GetService("Players")
local Encounter = require(game.ServerScriptService.BossSystem.Players.PlayerEncounter)
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local BOSS_NAME = "alterGolden, the Nothing"
local phases = { [1] = true, [1.5] = true, [2] = true, [2.5] = true, [3] = true, [3.5] = true, [4] = true }
local boss, phaseConnection
local highestPhase = 1
local function unhook()
	if phaseConnection then
		phaseConnection:Disconnect()
		phaseConnection = nil
	end
	boss = nil
	highestPhase = 1
end
local function hook(candidate)
	if boss == candidate then
		return
	end
	unhook()
	if not candidate or not candidate:IsA("Model") then
		return
	end
	boss = candidate
	highestPhase = candidate:GetAttribute("Phase") or 1
	phaseConnection = candidate:GetAttributeChangedSignal("Phase"):Connect(function()
		local phase = candidate:GetAttribute("Phase")
		if
			workspace:GetAttribute("EncounterStarted") ~= true
			or workspace:GetAttribute("BossEncounterWon") == true
			or candidate.Parent ~= workspace
			or candidate:GetAttribute("EncounterEnded")
			or not phases[phase]
			or phase <= highestPhase
		then
			return
		end
		highestPhase = phase
		 
		for _ = 1, Difficulty.Get(candidate).PhaseLives or 1 do
			for _, player in ipairs(Players:GetPlayers()) do
				Encounter.GrantLife(player)
			end
		end
	end)
end
workspace.ChildAdded:Connect(function(child)
	if child.Name == BOSS_NAME then
		hook(child)
	end
end)
workspace.ChildRemoved:Connect(function(child)
	if child == boss then
		unhook()
	end
end)
workspace:GetAttributeChangedSignal("EncounterStarted"):Connect(function()
	if workspace:GetAttribute("EncounterStarted") == true then
		hook(workspace:FindFirstChild(BOSS_NAME))
	else
		unhook()
	end
end)
hook(workspace:FindFirstChild(BOSS_NAME))
