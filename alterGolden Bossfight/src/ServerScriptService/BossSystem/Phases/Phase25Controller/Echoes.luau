-- Phase25Controller: temporal echoes: delaying player shots into echoes while the clock is stopped.
-- Registers its api.<Name> functions on the shared table from Core; init.luau requires this module.
local Core = require(script.Parent.Core)
local api, Config, Metadata, alive, launchEcho, pruneEchoes, random, records = Core.api, Core.Config, Core.Metadata, Core.alive, Core.launchEcho, Core.pruneEchoes, Core.random, Core.records

 
 
local function echoSnapshot(value, depth)
	if type(value) ~= "table" then
		return value
	end
	if depth > 4 then
		return nil
	end
	local copy = {}
	for key, item in pairs(value) do
		copy[key] = echoSnapshot(item, depth + 1)
	end
	return table.freeze(copy)
end
function api.OnTemporalEmission(actor, name, immutablePayload, replay)
	local definition = Metadata.Get(name)
	local record = records[actor]
	local state = record and record.Echoes
	if
		not state
		or state.Closed
		or state.Replaying
		or not definition
		or not definition.CanLastMinuteEcho
		or definition.Passive
		or definition.Ultimate
		or definition.TimeStopOnly
		or definition.NativePhase == 2.5
		or type(replay) ~= "function"
		or not alive(actor)
		or actor:GetAttribute("Phase") ~= 2.5
		or not actor:GetAttribute("LastMinuteActive")
		or actor:GetAttribute("PhaseTransitionInProgress")
		or actor:GetAttribute("ExecutionLocked")
		or actor:GetAttribute("IsGoldenClone")
		or actor:GetAttribute("IsClone")
		or actor:GetAttribute("IsIllusion")
		or actor:FindFirstChild("EncounterOwner")
		or type(immutablePayload) == "table" and immutablePayload.IsLastMinuteEcho
	then
		return 0
	end
	local stage = Config.LastMinuteStages[actor:GetAttribute("LastMinuteStage") or 1]
	if not stage or (stage.EchoChance or 0) <= 0 or random:NextNumber() >= stage.EchoChance then
		return 0
	end
	if #state.Queue >= Config.LastMinuteEchoMaxQueued then
		return 0
	end
	local snapshot = echoSnapshot(immutablePayload, 0)
	local now = state.Cast:Now()
	local originalDelay = 0
	pruneEchoes(state)
	if
		(actor:GetAttribute("LastMinuteStage") or 1) >= 4
		and now >= state.NextLaunchAt
		and #state.Active < Config.LastMinuteEchoMaxActive
	then
		if launchEcho(actor, state, { Replay = replay, Payload = snapshot, Variant = "Past" }) then
			originalDelay = Config.LastMinutePastEchoLead
		end
	end
	local delay = originalDelay > 0 and originalDelay + Config.LastMinuteCollapseFutureDelay
		or Config.LastMinuteFutureEchoDelay
	local job = { At = now + delay, Payload = snapshot, Replay = replay, Variant = "Future" }
	local index = #state.Queue + 1
	while index > 1 and state.Queue[index - 1].At > job.At do
		index -= 1
	end
	table.insert(state.Queue, index, job)
	return originalDelay
end

return api
