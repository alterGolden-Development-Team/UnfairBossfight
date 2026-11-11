-- Phase25Controller core: the requires, colours, per-boss records and drawing helpers that more than one part of the
-- Phase 2.5 controller needs. The public functions (api.<Name>) live in the sibling modules and take what they use from here.
local BossSystem = script:FindFirstAncestor("BossSystem")
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Effects = require(BossSystem.Combat.EffectService)
local Runtime = require(BossSystem.Combat.CombatRuntime)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local Story = require(BossSystem.Encounter.EncounterStory)
local Audio = require(BossSystem.Presentation.CombatAudio)
local Locomotion = require(BossSystem.Boss.BossLocomotion)
local Metadata = require(BossSystem.Combat.AbilityMetadata)
local Players = game:GetService("Players")
local random = Random.new()
local api = {}
local records = setmetatable({}, { __mode = "k" })
local GOLD = Color3.fromRGB(255, 204, 38)
local function alive(actor)
	local h = actor and actor:FindFirstChildOfClass("Humanoid")
	return actor and actor.Parent and h and h.Health > 0 and not actor:GetAttribute("EncounterEnded")
end
local function send(kind, data)
	local remote = game.ReplicatedStorage:FindFirstChild("BossCombatEffects")
	if remote then
		remote:FireAllClients(kind, data)
	end
end
local function recordFor(actor)
	local record = records[actor]
	if not record then
		record = { Seen = setmetatable({}, { __mode = "k" }), Previews = {} }
		records[actor] = record
	end
	return record
end
local function addPart(cast, name, frame, size, color, alpha)
	local part = Effects.AcquirePart()
	part.Name = name
	part.CFrame = frame
	part.Size = size
	part.Color = color
	part.Transparency = alpha
	part.Parent = Runtime.Effects
	cast:Add(part)
	return part
end
local function pruneEchoes(state)
	for index = #state.Active, 1, -1 do
		local cast = state.Active[index]
		if cast.closed or not cast:Alive() then
			table.remove(state.Active, index)
		end
	end
end
local function launchEcho(actor, state, job)
	if
		state.Closed
		or not alive(actor)
		or actor:GetAttribute("Phase") ~= 2.5
		or not actor:GetAttribute("LastMinuteActive")
	then
		return false
	end
	pruneEchoes(state)
	if #state.Active >= Config.LastMinuteEchoMaxActive then
		return false
	end
	state.Replaying = true
	local ok, result = xpcall(job.Replay, debug.traceback, job.Payload, {
		Variant = job.Variant,
		DamageScale = Config.LastMinuteEchoDamageScale,
		IsLastMinuteEcho = true,
		Transparency = 0.5,
		MaxCount = Config.LastMinuteEchoProjectileMaxCount,
		CollapsePause = (actor:GetAttribute("LastMinuteStage") or 1) >= 3 and 0.12 or 0,
	})
	state.Replaying = false
	state.NextLaunchAt = state.Cast:Now() + Config.LastMinuteEchoMinInterval
	if not ok then
		warn("Last Minute emission echo: " .. tostring(result))
		return false
	end
	local cast = type(result) == "table" and (result.Cast or result) or nil
	if type(cast) ~= "table" or type(cast.Dispose) ~= "function" or type(cast.Alive) ~= "function" then
		return false
	end
	if state.Closed or not actor:GetAttribute("LastMinuteActive") then
		cast:Dispose()
		return false
	end
	table.insert(state.Active, cast)
	actor:SetAttribute("LastMinuteEchoesReleased", (actor:GetAttribute("LastMinuteEchoesReleased") or 0) + 1)
	if state.VFX then
		state.VFX.Echo()
	end
	return true
end

return {
 api=api,
 Audio=Audio,
 BossSystem=BossSystem,
 Config=Config,
 Difficulty=Difficulty,
 Effects=Effects,
 GOLD=GOLD,
 Locomotion=Locomotion,
 Metadata=Metadata,
 Placement=Placement,
 Players=Players,
 Runtime=Runtime,
 Shared=Shared,
 Story=Story,
 Time=Time,
 addPart=addPart,
 alive=alive,
 launchEcho=launchEcho,
 pruneEchoes=pruneEchoes,
 random=random,
 recordFor=recordFor,
 records=records,
 send=send,
}
