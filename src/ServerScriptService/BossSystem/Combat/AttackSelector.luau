local BossSystem = script:FindFirstAncestor("BossSystem")
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Metadata = require(BossSystem.Combat.AbilityMetadata)
local Cooldowns = require(BossSystem.Combat.AbilityCooldownService)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Modes = require(BossSystem.Combat.P5ModeService)
local random = Random.new()
local api = {}
local recent = setmetatable({}, { __mode = "k" }) -- actor -> last attack names, newest first

 -- a lingering heavy attack (P5 astral casts, black hole) is still running
function api.HeavyActive(actor)
	if not actor then
		return false
	end
	local casts = (actor:GetAttribute("HeavyCasts") or 0) > 0
		and workspace:GetServerTimeNow() < (actor:GetAttribute("HeavyCastsUntil") or 0)
	return casts or actor:GetAttribute("BlackHoleActive") == true
end

local function isHeavy(name, metadata)
	return (metadata and metadata.Ultimate) or (Config.HeavyAttacks and Config.HeavyAttacks[name]) or false
end

 -- phase 5 runs only its own attacks, so a non-ultimate heavy may start beside lingering astral
 -- casts (up to Phase5HeavyOverlap at once), never during the black hole or Polaris
local function canOverlap(actor, phase, metadata)
	return actor ~= nil and (phase or 0) >= 5 and not (metadata and metadata.Ultimate)
		and actor:GetAttribute("BlackHoleActive") ~= true and actor:GetAttribute("PolarisActive") ~= true
		and (actor:GetAttribute("HeavyCasts") or 0) < (Config.Phase5HeavyOverlap or 1)
end

 -- sword attacks favoured up close, ranged/area attacks favoured at distance
local function rangeFactor(actor, target, metadata)
	local root = actor and actor:FindFirstChild("HumanoidRootPart")
	local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
	if not root or not targetRoot or metadata and metadata.AnyRange then
		return 1
	end
	local d = ((targetRoot.Position - root.Position) * Vector3.new(1, 0, 1)).Magnitude
	local near, far = Config.MeleeRange or 22, Config.FarRange or 50
	local k = math.clamp((d - near) / math.max(far - near, 1), 0, 1) -- 0 close, 1 far
	if metadata and metadata.SwordBased then
		return 1.5 - 1.05 * k
	end
	return 0.8 + 0.5 * k
end

local function recentFactor(actor, name)
	local list = actor and recent[actor]
	local penalty = Config.RecentPenalty
	if not list or not penalty then
		return 1
	end
	for i, past in ipairs(list) do
		if past == name then
			return penalty[i] or 1
		end
	end
	return 1
end

function api.Record(actor, name)
	if not actor then
		return
	end
	local list = recent[actor] or {}
	recent[actor] = list
	table.insert(list, 1, name)
	while #list > 3 do
		table.remove(list)
	end
	local debt = actor:GetAttribute("FillerDebt") or 0
	local metadata = Metadata.Get(name)
	if debt > 0 and metadata and metadata.NativePhase < 5 then
		actor:SetAttribute("FillerDebt", debt - 1)
	end
end
function api.MinimumPhase(entry)
	local metadata = Metadata.Get(entry.Name)
	return entry.MinimumPhase or metadata and metadata.NativePhase or math.huge
end
function api.Weight(entry, phase)
	local metadata = Metadata.Get(entry.Name)
	if not metadata or metadata.Passive or metadata.TimeStopOnly or metadata.TriggerOnly then
		return 0
	end
	local minimum = api.MinimumPhase(entry)
	if phase == nil then
		return entry.Weight or 1
	end
	if not Metadata.Available(entry.Name, phase) or minimum > phase then
		return 0
	end
	local W = Config.AttackWeights
	local weights = phase >= 5 and (W.Phase5 or W.Phase4)
		or phase >= 4.5 and (W.Phase45 or W.Phase4)
		or phase >= 4 and W.Phase4
		or phase >= 3 and Config.AttackWeights.Phase3
		or phase >= 2.5 and Config.AttackWeights.Phase25
		or phase >= 2 and Config.AttackWeights.Phase2
		or phase >= 1.5 and Config.AttackWeights.Phase15
		or Config.AttackWeights.Phase1
	return (entry.Weight or 1) * (weights[minimum] or 0)
end
function api.Choose(attacks, target, lastName, repeatCount, rng, phase, actor, category)
	local goldenHour = actor and Time.IsGoldenHour(actor) or false
	if category == "GoldenHour" and not goldenHour or category ~= "GoldenHour" and goldenHour then
		return nil
	end
	if category ~= "GoldenHour" and actor and phase == 3.5 and actor:GetAttribute("Shield") == 1
		and Difficulty.Get(actor).Ultimates
		and not actor:GetAttribute("TrueIllusionCompleted") and not actor:GetAttribute("IsGoldenClone")
		and not actor:GetAttribute("IsIllusion") then
		for _, entry in ipairs(attacks) do
			if entry.Name == "P3.5TrueIllusion(Ultimate)" and Cooldowns.Ready(actor, entry.Name)
				and (not entry.Skill.CanUse or entry.Skill.CanUse(target)) then return entry end
		end
		return nil
	end
	local available, total, ultimates, ultimateTotal = {}, 0, {}, 0
	local heavyActive = category ~= "GoldenHour" and api.HeavyActive(actor)
	for _, entry in ipairs(attacks) do
		local metadata = Metadata.Get(entry.Name)
		local weight
		if category == "GoldenHour" then
			weight = metadata
					and metadata.TimeStopOnly
					and Metadata.Available(entry.Name, phase or actor and actor:GetAttribute("Phase"))
					and 1
				or 0
		else
			weight = api.Weight(entry, phase)
		end
		if category == "Combo" and metadata and metadata.Ultimate then weight = 0 end
		if heavyActive and isHeavy(entry.Name, metadata) and not canOverlap(actor, phase, metadata) then weight = 0 end -- no stacking on a lingering heavy
		 -- phase 5: only the current mode's skills and the normal attacks; the mode's own skills lead
		if weight > 0 and (phase or 0) >= 5 and actor then
			if not Modes.Allows(actor, entry.Name) then
				weight = 0
			elseif Modes.IsModeSkill(entry.Name) then
				weight *= Config.Phase5ModeSkillWeight or 1
			end
		end
		local filler = (phase or 0) >= 5 and metadata and metadata.NativePhase < 5
		 -- phase 5 fillers only run between heavies (the boss is often anchored mid-air during one)
		if filler and heavyActive then weight = 0 end
		 -- after a heavy, a few fillers must come before the next heavy
		if not filler and (phase or 0) >= 5 and isHeavy(entry.Name, metadata) and (actor and actor:GetAttribute("FillerDebt") or 0) > 0 then weight = 0 end
		if weight > 0 and category ~= "GoldenHour" then
			weight *= rangeFactor(actor, target, metadata) * recentFactor(actor, entry.Name)
		end
		if phase == 2.5 and actor and actor:GetAttribute("LastMinuteActive") then
			if metadata and metadata.Ultimate or entry.Name == "P2Acceleration" or entry.Name == "P2Deceleration" then
				weight = 0
			elseif metadata and metadata.NativePhase == 2.5 then
				weight *= actor:GetAttribute("LastMinutePhase25Weight") or 1
			end
		end
		if
			weight > 0
            and Difficulty.Allowed(entry.Name, metadata, actor)
			and not (not (metadata and metadata.Ultimate) and entry.Name == lastName and (repeatCount or 0) >= 2)
			and (not actor or Cooldowns.Ready(actor, entry.Name))
			and (not entry.Skill.CanUse or entry.Skill.CanUse(target))
		then
			if metadata and metadata.Ultimate and category ~= "GoldenHour" then
				ultimateTotal += weight
				table.insert(ultimates, { Entry = entry, Limit = ultimateTotal })
			else
				total += weight
				table.insert(available, { Entry = entry, Limit = total })
			end
		end
	end
	 
	 
	 -- a ready ultimate is usually, not always, taken (always when nothing else is ready)
	if ultimateTotal > 0 and (total <= 0 or (rng or random):NextNumber() < (Config.UltimatePickChance or 1)) then
		available, total = ultimates, ultimateTotal
	end
	if total <= 0 then
		 -- owed fillers but none can run (cooldowns, range): drop the debt rather than stall
		if actor and (actor:GetAttribute("FillerDebt") or 0) > 0 and not heavyActive then
			actor:SetAttribute("FillerDebt", 0)
			return api.Choose(attacks, target, lastName, repeatCount, rng, phase, actor, category)
		end
		return nil
	end
	local roll = (rng or random):NextNumber(0, total)
	local picked = available[#available].Entry
	for _, choice in ipairs(available) do
		if roll < choice.Limit then
			picked = choice.Entry
			break
		end
	end
	if category ~= "GoldenHour" then
		api.Record(actor, picked.Name)
	end
	return picked
end
function api.ReadyCount(attacks, target, actor, category)
	local phase = actor:GetAttribute("Phase") or 1
	local count = 0
	for _, entry in ipairs(attacks) do
		if
			api.Weight(entry, phase) > 0
            and Difficulty.Allowed(entry.Name, Metadata.Get(entry.Name), actor)
			and (phase < 5 or Modes.Allows(actor, entry.Name))
			and not (category == "Combo" and Metadata.Get(entry.Name).Ultimate)
			and Cooldowns.Ready(actor, entry.Name)
			and (not entry.Skill.CanUse or entry.Skill.CanUse(target))
		then
			count += 1
		end
	end
	return count
end
 -- the combo row for a phase: its own, or the nearest lower one (EncounterConfig.ComboByPhase)
function api.ComboSpec(actor)
	local phase = actor and actor:GetAttribute("Phase") or 1
	if phase >= 5 and (Config.Phase5NormalCombo or Config.Phase5ModeCombo) then
		return Modes.Active(actor) and Config.Phase5ModeCombo or Config.Phase5NormalCombo
	end
	local best, bestKey
	for key, spec in pairs(Config.ComboByPhase or {}) do
		if key <= phase and (not bestKey or key > bestKey) then
			best, bestKey = spec, key
		end
	end
	return best
end
function api.ComboCooldown(actor)
	local spec = api.ComboSpec(actor)
	return math.max(0, spec and spec.Cooldown or Config.Phase4ComboCooldown or 6) * Difficulty.Get(actor).Cooldown
end
function api.InComboRange(actor, target)
	local root = actor and actor:FindFirstChild("HumanoidRootPart")
	local targetRoot = target and target:FindFirstChild("HumanoidRootPart")
	if not root or not targetRoot then return false end
	local spec = api.ComboSpec(actor)
	local offset = targetRoot.Position - root.Position
	return Vector3.new(offset.X, 0, offset.Z).Magnitude <= (spec and spec.Range or Config.Phase4ComboRange or 18)
		and math.abs(offset.Y) <= (spec and spec.Height or Config.Phase4ComboHeight or 8)
end
 -- how many moves the next attack chains (1 = no combo); see EncounterConfig.ComboByPhase
function api.ComboCount(actor, rng, target)
	local profile = Difficulty.Get(actor)
	local pattern = profile.Mercy
	local spec = api.ComboSpec(actor)
	if not spec
		or actor:GetAttribute("IsGoldenClone")
		or actor:GetAttribute("PhaseTransitionInProgress")
		or Time.IsGoldenHour(actor)
		or workspace:GetServerTimeNow() < (actor:GetAttribute("Phase4ComboReadyAt") or 0)
	then return 1 end
	 -- Hellaven's ChainAllPhases lets early-phase combos start from any distance
	local early = (actor:GetAttribute("Phase") or 1) < 4
	if not (early and pattern.ChainAllPhases) and not api.InComboRange(actor, target) then return 1 end
	local r = rng or random
	local count = math.max(2, math.floor(Difficulty.Count(r:NextInteger(spec.Min, spec.Max), actor) + 0.5))
	return pattern.ChainMax and math.min(count, pattern.ChainMax) or count
end

return api
