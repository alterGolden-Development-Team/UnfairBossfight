--[[
 P5ModeService - Phase 5 alternates two states:
  * a mode (Space, Natural or Time, one P5 folder): the boss carries that mode's weapon (Combat/P5ModeWeapon)
    and uses only the mode's skills, at a calm pace (Phase5ModeAttackGap, 2-4 combos). His weapon swing (the M1,
    Attacks/P5/Weapon) was taken out of the modes on 2026-10-31. Each mode has its own look: Space floats him
    (P5Floating, Boss/BossLocomotion), Time hangs a clock behind his back and Natural lights his hands in Polaris
    colours (BossClient.Presentation.P5ModeAuraClient, from P5Mode);
  * no mode: his own Normal Attack folder only, fast (Phase5NormalAttackGap, 5-6 combos, 4s combo cooldown).
 A mode lasts Phase5ModeDuration (30s); then Phase5ModeGap (30s) without one before the next mode, never the same
 one twice in a row. Time (Finality alone) is entered only when Finality can be cast. AttackController calls Update
 every tick; AttackSelector asks Allows. Boss attributes: P5Mode, P5ModeUntil, P5ModeNextAt, P5ModeLast, P5ModeSwitches.
]]
local BossSystem = script:FindFirstAncestor("BossSystem")
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local Metadata = require(BossSystem.Combat.AbilityMetadata)
local Cooldowns = require(BossSystem.Combat.AbilityCooldownService)
local api = {}
local MODES = table.freeze({ "Space", "Natural", "Time" })
local rng = Random.new()

local function now()
	return workspace:GetServerTimeNow()
end

local function ready(actor, mode)
	return true  -- Time has Golden Eternity and Overclock besides Finality now, so every mode is always worth entering
end

local function weapon()
	return require(BossSystem.Combat.P5ModeWeapon)
end

local function enter(actor, mode)
	local span = Config.Phase5ModeDuration or { 30, 30 }
	actor:SetAttribute("P5Mode", mode)
	actor:SetAttribute("P5Floating", mode == "Space" or nil)
	actor:SetAttribute("P5ModeUntil", now() + rng:NextNumber(span[1], span[2]))
	actor:SetAttribute("P5ModeSwitches", (actor:GetAttribute("P5ModeSwitches") or 0) + 1)
	if mode == "Natural" then  -- only Natural carries a mode weapon (the Aurora Glaive); Space and Time fight without one
		pcall(function() weapon().Equip(actor, mode) end)
	end
	pcall(function()
		require(game.ReplicatedStorage.VFXEngine.Net).Send("P5Strikes", "Mode", { Boss = actor, Mode = mode })
	end)
	local line = Config.Phase5ModeLines and Config.Phase5ModeLines[mode]
	if line then
		pcall(require(BossSystem.Players.PlayerEncounter).Say, line, nil, { Duration = 2.2 })
	end
end

local function leave(actor)
	local mode = actor:GetAttribute("P5Mode")
	actor:SetAttribute("P5ModeLast", mode)
	actor:SetAttribute("P5Mode", nil)
	actor:SetAttribute("P5ModeUntil", nil)
	actor:SetAttribute("P5Floating", nil)
	actor:SetAttribute("P5ModeNextAt", now() + (Config.Phase5ModeGap or 30))
	pcall(function() weapon().Unequip(actor) end)
end

function api.Clear(actor)
	if actor:GetAttribute("P5Mode") then pcall(function() weapon().Unequip(actor) end) end
	for _, name in ipairs({ "P5Mode", "P5ModeUntil", "P5ModeNextAt", "P5ModeLast", "P5Floating" }) do
		actor:SetAttribute(name, nil)
	end
end

function api.Update(actor)
	local mode = actor:GetAttribute("P5Mode")
	if (actor:GetAttribute("Phase") or 0) < 5 then
		if mode or actor:GetAttribute("P5ModeNextAt") then api.Clear(actor) end
		return
	end
	if actor:GetAttribute("PhaseTransitionInProgress") or actor:GetAttribute("IsGoldenClone")
		or actor:GetAttribute("AIEnabled") == false then
		return
	end
	local t = now()
	if mode then
		if t >= (actor:GetAttribute("P5ModeUntil") or 0) then leave(actor) end
		return
	end
	if t < (actor:GetAttribute("P5ModeNextAt") or 0) then
		return  -- the no-mode stretch: his normal attacks
	end
	local last = actor:GetAttribute("P5ModeLast")
	if not last then  -- Phase 5 always opens in Natural
		enter(actor, "Natural")
		return
	end
	local options = {}
	for _, other in ipairs(MODES) do
		if other ~= last and ready(actor, other) then
			options[#options + 1] = other
		end
	end
	if #options == 0 then
		return  -- nothing ready yet (Time waits on Finality): stay without a mode a little longer
	end
	enter(actor, options[rng:NextInteger(1, #options)])
end

 -- true when the boss's current state lets him use this attack: Normal skills only without a mode,
 -- the mode's own skills only inside one (never the weapon swing)
function api.Allows(actor, name)
	local entry = Metadata.Get(name)
	local group = entry and entry.P5Mode
	if not actor or not group or (actor:GetAttribute("Phase") or 0) < 5 then
		return true
	end
	local mode = actor:GetAttribute("P5Mode")
	if group == "Normal" then
		return mode == nil
	elseif group == "Weapon" then
		return false  -- the M1 is gone from the modes; the weapon is only carried
	end
	return group == mode
end

function api.IsModeSkill(name)
	local entry = Metadata.Get(name)
	return entry ~= nil and entry.P5Mode ~= nil and entry.P5Mode ~= "Normal" and entry.P5Mode ~= "Weapon"
end

function api.Active(actor)
	return actor ~= nil and actor:GetAttribute("P5Mode") ~= nil
end

api.Modes = MODES
return table.freeze(api)
