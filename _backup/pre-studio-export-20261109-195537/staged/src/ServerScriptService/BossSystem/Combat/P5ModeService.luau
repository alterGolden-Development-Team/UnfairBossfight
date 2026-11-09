local BossSystem = script:FindFirstAncestor("BossSystem")
local Config = require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local Metadata = require(BossSystem.Combat.AbilityMetadata)
local api = {}
local MODES = table.freeze({ "Space", "Natural", "Time" })
local LAST_STAND = table.freeze({ Space = "P5BlastBreath(Ultimate)", Natural = "P5TheGreatStorm(Ultimate)", Time = "P5Finality(Ultimate)" })
local rng = Random.new()

local function now()
	return workspace:GetServerTimeNow()
end
local function weapon()
	return require(BossSystem.Combat.P5ModeWeapon)
end
local function say(line, duration)
	if line then
		pcall(require(BossSystem.Players.PlayerEncounter).Say, line, nil, { Duration = duration or 2.6 })
	end
end
local function broken(actor)
	local list = {}
	for mode in string.gmatch(actor:GetAttribute("P5ModesDone") or "", "%a+") do
		list[mode] = true
	end
	return list
end
local function shieldOf(mode)
	local shields = Config.Phase5ModeShields
	return shields and shields[mode] or Config.Phase5ModeShield or 2000
end

local function enter(actor, mode)
	actor:SetAttribute("P5BaseShield", actor:GetAttribute("Shield") or 0)
	actor:SetAttribute("P5BaseMaxShield", actor:GetAttribute("MaxShield") or 0)
	local shield = shieldOf(mode)
	actor:SetAttribute("MaxShield", shield)
	actor:SetAttribute("Shield", shield)
	actor:SetAttribute("P5ShieldDown", nil)
	actor:SetAttribute("P5Mode", mode)
	actor:SetAttribute("P5Floating", mode == "Space" or nil)
	actor:SetAttribute("P5ModeSwitches", (actor:GetAttribute("P5ModeSwitches") or 0) + 1)
	local glow = actor:FindFirstChild("ShieldGlow")
	if glow then glow.Enabled = true end
	pcall(function()
		require(game.ReplicatedStorage.VFXEngine.Net).Send("P5Strikes", "Mode", { Boss = actor, Mode = mode })
	end)
	say(Config.Phase5ModeLines and Config.Phase5ModeLines[mode], 2.6)
end

local function leave(actor, defeated)
	local mode = actor:GetAttribute("P5Mode")
	actor:SetAttribute("P5Mode", nil)
	actor:SetAttribute("P5Floating", nil)
	actor:SetAttribute("P5ShieldDown", nil)
	actor:SetAttribute("MaxShield", actor:GetAttribute("P5BaseMaxShield") or 0)
	actor:SetAttribute("Shield", actor:GetAttribute("P5BaseShield") or 0)
	pcall(function() weapon().Unequip(actor) end)
	actor:SetAttribute("P5ModeNextAt", now() + (Config.Phase5NormalSpan or 30))
	if defeated and mode then
		local list = broken(actor)
		list[mode] = true
		local names = {}
		for _, m in ipairs(MODES) do
			if list[m] then names[#names + 1] = m end
		end
		actor:SetAttribute("P5ModesDone", table.concat(names, ","))
		if #names >= #MODES then
			task.delay(4, function()
				if actor.Parent then say(Config.Phase5AllModesLine, 3.5) end
			end)
		end
	end
end

function api.Clear(actor)
	if actor:GetAttribute("P5Mode") then
		leave(actor, false)
	end
	for _, name in ipairs({ "P5Mode", "P5ModeUntil", "P5ModeNextAt", "P5ModeLast", "P5Floating", "P5ModesDone", "P5LastStand", "P5ShieldDown", "P5ShieldInit", "P5Borrowed", "P5BorrowedKey" }) do
		actor:SetAttribute(name, nil)
	end
end

 -- the shield Phase 5 opens with (and keeps after every mode)
local function initShield(actor)
	if actor:GetAttribute("P5ShieldInit") or actor:GetAttribute("P5Mode") then
		return
	end
	actor:SetAttribute("P5ShieldInit", true)
	local base = actor:GetAttribute("GodStripped") and (Config.Phase5BaseShield or 5000) or (Config.Phase5UnlimitedShield or 1000000000)
	actor:SetAttribute("MaxShield", base)
	actor:SetAttribute("Shield", base)
	local glow = actor:FindFirstChild("ShieldGlow")
	if glow then glow.Enabled = true end
end

function api.Update(actor)
	local mode = actor:GetAttribute("P5Mode")
	if (actor:GetAttribute("Phase") or 0) < 5 then
		if mode or actor:GetAttribute("P5ModeNextAt") or actor:GetAttribute("P5ModesDone") or actor:GetAttribute("P5ShieldInit") then api.Clear(actor) end
		return
	end
	if not workspace:GetAttribute("Phase5HealthMultiplier") and not actor:GetAttribute("IsGoldenClone") then
		 -- Phase 5's reinforcement for the players: HP x10, +10 lives (once per encounter)
		pcall(function() require(BossSystem.Players.PlayerEncounter).ApplyPhase5Buff() end)
	end
	if actor:GetAttribute("IsGoldenClone") then
		return
	end
	initShield(actor)
	local stage = actor:GetAttribute("P5Stage")
	if actor:GetAttribute("PhaseTransitionInProgress") or actor:GetAttribute("AIEnabled") == false or stage and stage ~= "Frenzy" then
		return
	end
	local t = now()
	if mode then
		local hold = Config.Phase5ShieldHold or 1
		if not actor:GetAttribute("P5ShieldDown") then
			if (actor:GetAttribute("Shield") or 0) <= hold then
				 -- the shield is down: the mode's last stand is owed now
				actor:SetAttribute("P5ShieldDown", t)
				actor:SetAttribute("P5LastStand", LAST_STAND[mode])
				pcall(function() require(BossSystem.Presentation.CharacterEffects).ShieldBreak(actor) end)
				say(Config.Phase5ModeBreakLines and Config.Phase5ModeBreakLines[mode], 3)
			end
			return
		end
		 -- waiting for the last stand: it clears P5LastStand when its cast really starts, and the mode ends after that cast
		local owed = actor:GetAttribute("P5LastStand")
		local since = actor:GetAttribute("P5ShieldDown") or t
		if not owed and not actor:GetAttribute("AttackInProgress") then
			leave(actor, true)
		elseif t - since > (Config.Phase5LastStandWait or 25) then
			leave(actor, true)  -- it could not go (no target?): the mode ends anyway and the stand stays owed
		end
		return
	end
	local nextAt = actor:GetAttribute("P5ModeNextAt")
	if not nextAt then
		actor:SetAttribute("P5ModeNextAt", t + (Config.Phase5NormalSpan or 30))
		return
	end
	if t < nextAt then
		return
	end
	local list, options = broken(actor), {}
	for _, m in ipairs(MODES) do
		if not list[m] then options[#options + 1] = m end
	end
	if #options > 0 then
		enter(actor, options[rng:NextInteger(1, #options)])
	end
end

 -- 2 (Enraged) or 3 (Super Enraged, the Enraged Gate) random moves from EACH mode he has been defeated in - never its
 -- ultimates. The pick is made once per set of broken modes and kept in the boss attribute P5Borrowed ("A,B,C").
local function borrowed(actor)
	if not actor:GetAttribute("GodStripped") then
		return nil
	end
	local done = actor:GetAttribute("P5ModesDone") or ""
	if done == "" then
		return nil
	end
	local super = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig).Enraged() == true
	local key = done .. (super and "|3" or "|2")
	if actor:GetAttribute("P5BorrowedKey") ~= key then
		local per = super and 3 or 2
		local picked = {}
		for mode in string.gmatch(done, "%a+") do
			local pool = {}
			for _, n in ipairs(Metadata.ActiveNames) do
				local e = Metadata.Get(n)
				if e and e.P5Mode == mode and not e.Ultimate and not e.Passive and not n:find("Ultimate", 1, true) then
					pool[#pool + 1] = n
				end
			end
			for _ = 1, math.min(per, #pool) do
				picked[#picked + 1] = table.remove(pool, rng:NextInteger(1, #pool))
			end
		end
		actor:SetAttribute("P5BorrowedKey", key)
		actor:SetAttribute("P5Borrowed", table.concat(picked, ","))
	end
	local set = {}
	for n in string.gmatch(actor:GetAttribute("P5Borrowed") or "", "[^,]+") do
		set[n] = true
	end
	return set
end
api.Borrowed = borrowed

 -- true when his state lets him use this attack: normal mode - the Normal Attack folder; a mode - that mode's skills;
 -- a broken mode's last stand only while it is owed
function api.Allows(actor, name)
	local entry = Metadata.Get(name)
	local group = entry and entry.P5Mode
	if not actor or not group or (actor:GetAttribute("Phase") or 0) < 5 then
		return true
	end
	if group == "Weapon" or group == "Summoned" then
		return false  -- the weapon swing and the stars the Space passive drops are never picked
	elseif group == "LastStand" then
		return actor:GetAttribute("P5LastStand") == name
	end
	local mode = actor:GetAttribute("P5Mode")
	if group == "Normal" then
		return mode == nil
	end
	if mode == nil then
		local set = borrowed(actor)
		return set ~= nil and set[name] == true
	end
	return group == mode
end

 -- the last-stand ultimate a broken mode owes, if it can go now (AttackController casts it before anything else)
function api.LastStand(actor, attacks, target)
	local name = actor:GetAttribute("P5LastStand")
	if not name or not target then
		return nil
	end
	for _, entry in ipairs(attacks) do
		if entry.Name == name then
			if not entry.Skill.CanUse or entry.Skill.CanUse(target) then
				return entry  -- still owed: the last stand clears P5LastStand itself once its cast really starts
			end
			return nil
		end
	end
	actor:SetAttribute("P5LastStand", nil)
	return nil
end

function api.IsModeSkill(name)
	local entry = Metadata.Get(name)
	return entry ~= nil and entry.P5Mode ~= nil and entry.P5Mode ~= "Normal" and entry.P5Mode ~= "Weapon" and entry.P5Mode ~= "LastStand"
		and entry.P5Mode ~= "Summoned"
end

function api.Active(actor)
	return actor ~= nil and actor:GetAttribute("P5Mode") ~= nil
end

api.Modes = MODES
api.LastStands = LAST_STAND
return table.freeze(api)
