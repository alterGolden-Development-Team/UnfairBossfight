local BossSystem = script:FindFirstAncestor("BossSystem")
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Metadata = require(BossSystem.Combat.AbilityMetadata)
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local records = setmetatable({}, { __mode = "k" })
local api = {}
function api.Ready(actor, name)
 if not Difficulty.Allowed(name, Metadata.Get(name), actor) then return false end
	local metadata = Metadata.Get(name)
	if metadata and metadata.Ultimate and not require(BossSystem.Combat.UltimateService).Ready(actor, name) then return false end
	if name == "P2.5MissingFrame" and actor:GetAttribute("LastMinuteActive") then
		if
			(actor:GetAttribute("LastMinuteMissingFrameCount") or 0) >= Config.MissingFrameLastMinuteMaxCasts
			or workspace:GetServerTimeNow() < (actor:GetAttribute("LastMinuteMissingFrameReadyAt") or 0)
		then
			return false
		end
	end
	if require(BossSystem.Combat.UltimateService).IsTrueIllusionGate(actor, name) then return true end
	local entries = records[actor]
	local entry = entries and entries[name]
	return not entry or (entry.RealTime and os.clock() or Time.CooldownNow(actor)) >= entry.Deadline
end
function api.Start(actor, name, duration)
	if not duration or duration <= 0 then
		return
	end
	if actor:GetAttribute("LastMinuteActive") and (name == "P2.5MissingFrame" or name == "P2.5FalseFuture") then
		local index = math.clamp(actor:GetAttribute("LastMinuteStage") or 1, 1, #Config.LastMinuteStages)
		if name == "P2.5MissingFrame" then
			duration = math.max(duration, Config.MissingFrameLastMinuteSpacing)
		else
			duration /= math.clamp(1 + (index - 1) * 0.25, 1, 2)
		end
	end
	local tuning = Metadata.Get(name)
	if not tuning or not tuning.UnscaledDifficulty then duration *= Difficulty.Get(actor).Cooldown end
	local entries = records[actor]
	if not entries then
		entries = {}
		records[actor] = entries
	end
	local metadata = Metadata.Get(name)
	local real = metadata and metadata.CooldownUsesRealTime or name == "P2.5MissingFrame" or false
	entries[name] = { RealTime = real, Deadline = (real and os.clock() or Time.CooldownNow(actor)) + duration }
end
function api.Remaining(actor, name)
	local entries = records[actor]
	local entry = entries and entries[name]
	return entry and math.max(0, entry.Deadline - (entry.RealTime and os.clock() or Time.CooldownNow(actor))) or 0
end
 -- lift one ability's cooldown and hand back what was there (Put restores it); used when
 -- a Phase 5 combo follow-up runs off-cooldown
function api.Take(actor, name)
	local entries = records[actor]
	local entry = entries and entries[name]
	if entry then entries[name] = nil end
	return entry
end
function api.Put(actor, name, entry)
	if not entry then return end
	records[actor] = records[actor] or {}
	records[actor][name] = entry
end
function api.Clear(actor)
	records[actor] = nil
end
return api
