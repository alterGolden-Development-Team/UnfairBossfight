local Players = game:GetService("Players")
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Config = require(Shared.Config.EncounterConfig)
local api = {}
local attributes = { "HalvedStacks", "HalvedBaseMaxHealth", "HalvedHealthFraction" }

function api.Reset(player, character)
	for _, name in ipairs(attributes) do
		character:SetAttribute(name, nil)
		if player.Character == character then
			player:SetAttribute(name, nil)
		end
	end
end

function api.Cleanse(player, character)
 local humanoid = character:FindFirstChildOfClass("Humanoid")
 local base = character:GetAttribute("HalvedBaseMaxHealth")
 if humanoid and humanoid.Health > 0 and base then
  local fraction = humanoid.Health / math.max(humanoid.MaxHealth, 0.001)
  humanoid.MaxHealth = base
  humanoid.Health = math.min(base, base * fraction)
 end
 api.Reset(player, character)
end

function api.Apply(player, fraction)
	if player:GetAttribute("ViewAsServer") == true then
		return nil
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if player.Parent ~= Players or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	local previousMax, previousHealth = humanoid.MaxHealth, humanoid.Health
	local base = character:GetAttribute("HalvedBaseMaxHealth") or previousMax
	local stacks = (character:GetAttribute("HalvedStacks") or 0) + 1
	fraction = Difficulty.Penalty(fraction)
	local remaining = 1 - fraction
	local maximum = previousMax * remaining
	local values =
		{ HalvedStacks = stacks, HalvedBaseMaxHealth = base, HalvedHealthFraction = maximum / math.max(base, 1) }
	for name, value in pairs(values) do
		character:SetAttribute(name, value)
		player:SetAttribute(name, value)
	end
	 
	 
	humanoid.MaxHealth = maximum
	humanoid.Health = maximum < 1 and 0 or math.min(maximum, previousHealth * remaining)
	return {
		UserId = player.UserId,
		Fraction = fraction,
		PreviousMaxHealth = previousMax,
		MaxHealth = maximum,
		HealthLost = previousHealth - humanoid.Health,
		Stacks = stacks,
	}
end

function api.ApplyRound(contestants, pupilPlayer)
	local results = {}
	for _, player in ipairs(contestants) do
		local fraction = (#contestants == 1 or player == pupilPlayer) and (Config.PickThePupilsInsidePenalty or 0.5)
			or (Config.PickThePupilsOutsidePenalty or 0.15)
		local result = api.Apply(player, fraction)
		if result then
			table.insert(results, result)
		end
	end
	return results
end

return api
