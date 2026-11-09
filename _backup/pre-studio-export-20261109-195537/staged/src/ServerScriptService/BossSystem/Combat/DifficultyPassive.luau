 
 
 
 
 
 
local Players = game:GetService("Players")
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)

local api = {}
local IDS = { Hellaven = "DiffHellaven", TrueHardcore = "DiffTrueHardcore", Hardcore = "DiffHardcore", NerfedHardcore = "DiffNerfedHardcore", Easy = "DiffEasy" }
api.Ids = IDS
api.Tuning = table.freeze({
	BloodlustPerStack = 0.04, BloodlustMax = 10, BloodlustDuration = 6,
	ResolveThreshold = 0.25, ResolveReduction = 0.15,
	HonorStreak = 4, HonorStagger = 1.2,
	PatienceWindow = 4, PatienceTellMultiplier = 2, PatienceMinimumTell = 0.25,
	GentleInterval = 15, GentleHeal = 0.06,
})
local T = api.Tuning
local started = setmetatable({}, { __mode = "k" })

local function now()
	return workspace:GetServerTimeNow()
end
local function isBoss(actor)
	return typeof(actor) == "Instance" and actor:IsA("Model") and not actor:GetAttribute("IsGoldenClone") and not actor:GetAttribute("IsIllusion")
end

function api.Start(actor)
	if not isBoss(actor) or started[actor] then
		return
	end
	started[actor] = true
	local id = Difficulty.Id(actor)
	for _, attr in pairs(IDS) do
		actor:SetAttribute("Passive_" .. attr, nil)
	end
	actor:SetAttribute("Passive_" .. IDS[id], true)
	actor:SetAttribute("DifficultyPassive", IDS[id])
	if id == "Easy" then
		 
		task.spawn(function()
			while actor.Parent and started[actor] do
				task.wait(T.GentleInterval)
				local h = actor:FindFirstChildOfClass("Humanoid")
				if not actor.Parent or not h or h.Health <= 0 or actor:GetAttribute("EncounterEnded") then
					break
				end
				if not actor:GetAttribute("PhaseTransitionInProgress") then
					local healed = 0
					for _, player in ipairs(Players:GetPlayers()) do
						local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
						if hum and hum.Health > 0 and hum.Health < hum.MaxHealth then
							hum.Health = math.min(hum.MaxHealth, hum.Health + hum.MaxHealth * T.GentleHeal)
							healed += 1
						end
					end
					actor:SetAttribute("GentleHeartPulses", (actor:GetAttribute("GentleHeartPulses") or 0) + 1)
					actor:SetAttribute("GentleHeartLastHealed", healed)
				end
			end
			started[actor] = nil
		end)
	end
end

 
function api.OutgoingMultiplier(owner)
	if not isBoss(owner) or owner:GetAttribute("Passive_DiffHellaven") ~= true then
		return 1
	end
	if now() > (owner:GetAttribute("BloodlustUntil") or 0) then
		return 1
	end
	return 1 + T.BloodlustPerStack * (owner:GetAttribute("BloodlustStacks") or 0)
end

 
function api.OnPlayerHit(owner, char, isStatus)
	if not isBoss(owner) then
		return
	end
	if char then
		char:SetAttribute("DuelStreak", 0)  
	end
	if isStatus then
		return
	end
	if owner:GetAttribute("Passive_DiffHellaven") == true then
		local stacks = now() <= (owner:GetAttribute("BloodlustUntil") or 0) and (owner:GetAttribute("BloodlustStacks") or 0) or 0
		owner:SetAttribute("BloodlustStacks", math.min(T.BloodlustMax, stacks + 1))
		owner:SetAttribute("BloodlustUntil", now() + T.BloodlustDuration)
	elseif owner:GetAttribute("Passive_DiffNerfedHardcore") == true then
		owner:SetAttribute("PatienceUntil", now() + T.PatienceWindow)
	end
end

 
function api.IncomingMultiplier(actor)
	if actor:GetAttribute("Passive_DiffTrueHardcore") == true then
		local h = actor:FindFirstChildOfClass("Humanoid")
		if h and h.MaxHealth > 0 and h.Health / h.MaxHealth <= T.ResolveThreshold then
			return 1 - T.ResolveReduction
		end
	end
	return 1
end
function api.OnBossHit(actor, attacker, onStagger)
	if actor:GetAttribute("Passive_DiffHardcore") ~= true then
		return
	end
	local char = typeof(attacker) == "Instance" and (attacker:IsA("Player") and attacker.Character or attacker) or nil
	if not char or not char:IsA("Model") then
		return
	end
	local streak = (char:GetAttribute("DuelStreak") or 0) + 1
	if streak >= T.HonorStreak then
		streak = 0
		actor:SetAttribute("ExposedUntil", now() + T.HonorStagger)
		actor:SetAttribute("DuelistHonorStaggers", (actor:GetAttribute("DuelistHonorStaggers") or 0) + 1)
		if onStagger then
			pcall(onStagger, T.HonorStagger)
		end
	end
	char:SetAttribute("DuelStreak", streak)
end

 
function api.Tell(actor, tell)
	if actor:GetAttribute("Passive_DiffNerfedHardcore") == true and now() < (actor:GetAttribute("PatienceUntil") or 0) then
		return math.max(tell, T.PatienceMinimumTell) * T.PatienceTellMultiplier
	end
	return tell
end

return api
