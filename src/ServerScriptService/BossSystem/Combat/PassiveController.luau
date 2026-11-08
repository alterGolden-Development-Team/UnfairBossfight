local BossSystem = script:FindFirstAncestor("BossSystem")
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
 
local Registry = require(BossSystem.Combat.AttackRegistry)
local Effects = require(BossSystem.Combat.EffectService)
local Config = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Metadata = require(BossSystem.Combat.AbilityMetadata)
local api = {}
local records = setmetatable({}, { __mode = "k" })
local random = Random.new()
local hudPassives = {
 Passive_P3Misdirection="P3Misdirection(Passive)",
 Passive_P35Debuffer="P3.5Debuffer(Passive)",
	Passive_P1Unstoppable = "P1Unstoppable(Passive)",
	Passive_P15Clone = "P1.5Clone(Passive)",
	Passive_P2HourDebt = "P2HourDebt(Passive)",
	Passive_P25FutureSight = "P2.5FutureSight(Passive)",
	Passive_P4Regeneration = "P4Regeneration(Passive)",
	Passive_P4Enraged = "P4Enraged(Passive)",
 Passive_P4Karmanation="P4Karmanation(Passive)",
 Passive_P4TrueSpirit="P4TrueSpirit(Passive)",
	Passive_P3GoldenMark = "P3GoldenMark(Passive)",
	Passive_P5God = "P5God(Passive)",
}
function api.Start(actor, getTarget)
	if records[actor] then
		return records[actor]
	end
	 
	pcall(function() require(script.Parent.DifficultyPassive).Start(actor) end)
	local god = Registry.For(actor, "P5God(Passive)")
	god.Tick()
	local clone = Registry.For(actor, "P1.5Clone(Passive)")
	local debt = Registry.For(actor, "P2HourDebt(Passive)")
	local unstoppable = Registry.For(actor, "P1Unstoppable(Passive)")
	local regeneration = Registry.For(actor, "P4Regeneration(Passive)")
	local enraged = Registry.For(actor, "P4Enraged(Passive)")
	local misdirection=Registry.For(actor,"P3Misdirection(Passive)")
	local debuffer=Registry.For(actor,"P3.5Debuffer(Passive)")
 local spirit=Registry.For(actor,"P4TrueSpirit(Passive)")
 local karma=Registry.For(actor,"P4Karmanation(Passive)")
 local mark = Registry.For(actor, "P3GoldenMark(Passive)")
	local future = Registry.For(actor, "P2.5FutureSight(Passive)")
	if debt.Start then
		debt.Start()
	end
	local cast = Effects.NewCast(actor, "EncounterPassives", math.huge)
	cast.TimeStopExempt = true
	cast.PersistsThroughEmitterStun = true  -- a class stun or a Mysterious Guy catch must not end the passives
	local now = workspace:GetServerTimeNow()
	local record = {
		Clone = clone,
		Debt = debt,
		Regeneration = regeneration,
		Enraged = enraged,
		Mark = mark,
  Spirit=spirit,
  Misdirection=misdirection,
  Debuffer=debuffer,
  Karma=karma,
		Future = future,
		Cast = cast,
		NextClone = now + Config.ClonePassiveInitialDelay,
		NextShield = now + Config.UnstoppableInterval,
	}
	records[actor] = record
	actor:SetAttribute("Passive_P3Regeneration", false)
	for attribute, name in pairs(hudPassives) do
		actor:SetAttribute(attribute, Metadata.PassiveAvailable(name, actor:GetAttribute("Phase") or 1) and Difficulty.Allowed(name, Metadata.Get(name), actor))
	end
	cast.OnDispose = function()
		if records[actor] == record then
			records[actor] = nil
		end
		clone.Dispose()
		debt.Dispose()
		unstoppable.Dispose()
		regeneration.Reset()
		enraged.Reset()
		mark.Reset()
  spirit.Reset()
  misdirection.Reset()
  debuffer.Reset()
  karma.Reset()
		future.Reset()
		god.Reset()
	end
	local scan = 0
	cast:Step(function(dt)
		scan += dt
		if scan < 0.1 then
			return true
		end
		scan = 0
		enraged.Tick()
		god.Tick()
		if actor:GetAttribute("EncounterEnded") then
			cast:Dispose()
			return false
		end
		if
			actor:GetAttribute("AIEnabled") == false
			or actor:GetAttribute("PhaseTransitionInProgress")
			or actor:GetAttribute("ExecutionLocked")
		then
			return true
		end
		local now = workspace:GetServerTimeNow()
		local phase = actor:GetAttribute("Phase") or 1
		for attribute, name in pairs(hudPassives) do
			local available = Metadata.PassiveAvailable(name, phase) and Difficulty.Allowed(name, Metadata.Get(name), actor)
			if name == "P4Regeneration(Passive)" then available = available and regeneration.Ready() end
			if name == "P5God(Passive)" then available = available and god.IsActive() end  -- stripped by a TP break
			if actor:GetAttribute(attribute) ~= available then
				actor:SetAttribute(attribute, available)
			end
		end
		if Metadata.PassiveAvailable("P2.5FutureSight(Passive)", phase) and Difficulty.Allowed("P2.5FutureSight(Passive)", Metadata.Get("P2.5FutureSight(Passive)"), actor) then
			future.Tick()
		end
		if now >= record.NextShield and Metadata.PassiveAvailable("P1Unstoppable(Passive)", phase) and Difficulty.Allowed("P1Unstoppable(Passive)", Metadata.Get("P1Unstoppable(Passive)"), actor) then
			record.NextShield = now + Config.UnstoppableInterval * Difficulty.Get(actor).Cooldown
			unstoppable.Tick()
		end
		if
			now >= record.NextClone
			and Metadata.PassiveAvailable("P1.5Clone(Passive)", phase) and Difficulty.Allowed("P1.5Clone(Passive)", Metadata.Get("P1.5Clone(Passive)"), actor)
			and actor:GetAttribute("CloneEnabled") ~= false
		then
			local target = getTarget()
			if target and clone.CanUse(target) then
				local cooldown =
					math.max(0.5, tonumber(actor:GetAttribute("ClonePassiveCooldown")) or Config.ClonePassiveCooldown)
				record.NextClone = now + cooldown * Difficulty.Get(actor).Cooldown
				local chance =
					math.clamp(tonumber(actor:GetAttribute("ClonePassiveChance")) or Config.ClonePassiveChance, 0, 1)
				if random:NextNumber() < chance and clone.Spawn(target) then
					actor:SetAttribute("ClonePassiveProcs", (actor:GetAttribute("ClonePassiveProcs") or 0) + 1)
				end
			end
		end
		return true
	end)
	return record
end
function api.OnAttackStarted(actor, name, target)
	local record = records[actor]
 if record and not record.Cast.closed and Difficulty.Allowed("P3Misdirection(Passive)", Metadata.Get("P3Misdirection(Passive)"), actor) then record.Misdirection.Try(name,target) end
	if
		not record
		or record.Cast.closed
		or actor:GetAttribute("ExecutionLocked")
		or not (Metadata.PassiveAvailable("P2HourDebt(Passive)", actor:GetAttribute("Phase") or 1) or Difficulty.Mercy("EchoAllPhases", actor) == true)
        or not Difficulty.Allowed("P2HourDebt(Passive)", Metadata.Get("P2HourDebt(Passive)"), actor)
	then
		return false
	end
	local handle = record.Debt.Record(name, target)
	if handle then
		actor:SetAttribute("HourDebtPassiveProcs", (actor:GetAttribute("HourDebtPassiveProcs") or 0) + 1)
		actor:SetAttribute("LastHourDebtRecordedAttack", name)
	end
	return handle
end
function api.OnSuccessfulHit(actor,character,actualDamage)
 if not actor or not actor.Parent or actor:GetAttribute("IsGoldenClone") or actor:GetAttribute("EncounterEnded")
  or type(actualDamage)~="number" or actualDamage~=actualDamage or actualDamage<=0 or actualDamage==math.huge then return false end
 local h=actor:FindFirstChildOfClass("Humanoid") if not h or h.Health<=0 then return false end
 local phase=actor:GetAttribute("Phase") or 1
 if Metadata.PassiveAvailable("P3GoldenMark(Passive)",phase) and Difficulty.Allowed("P3GoldenMark(Passive)",Metadata.Get("P3GoldenMark(Passive)"),actor) then
  Registry.For(actor,"P3GoldenMark(Passive)").Apply(character,actualDamage)
 end
 if Metadata.PassiveAvailable("P4Enraged(Passive)",phase) and Difficulty.Allowed("P4Enraged(Passive)",Metadata.Get("P4Enraged(Passive)"),actor) then
  Registry.For(actor,"P4Enraged(Passive)").Apply(character,actualDamage)
 end
 return true
end
function api.OnDamageDealt(actor, character, actualDamage, balance)
	local record = records[actor]
	if
		not record
		or record.Cast.closed
		or type(actualDamage) ~= "number"
		or actualDamage ~= actualDamage
		or actualDamage <= 0
		or actualDamage == math.huge
		or actor:GetAttribute("EncounterEnded")
		or actor:GetAttribute("AIEnabled") == false
		or actor:GetAttribute("PhaseTransitionInProgress")
	then
		return false
	end
	local phase = actor:GetAttribute("Phase") or 1
 if not (balance and balance.IsStatusDamage) and Metadata.PassiveAvailable("P3.5Debuffer(Passive)", phase)
  and Difficulty.Allowed("P3.5Debuffer(Passive)", Metadata.Get("P3.5Debuffer(Passive)"), actor) then
  record.Debuffer.Apply(character)
 end
 if Metadata.PassiveAvailable("P4TrueSpirit(Passive)",phase) and not (balance and balance.IsStatusDamage) then
  record.Spirit.Apply(character,actualDamage)
  record.Karma.Apply(character,actualDamage)
 end
 if Metadata.PassiveAvailable("P4Regeneration(Passive)", phase) and Difficulty.Allowed("P4Regeneration(Passive)", Metadata.Get("P4Regeneration(Passive)"), actor) then
  record.Regeneration.Apply(character,actualDamage)
 end
	return true
end
function api.DamageMultiplier(actor)
 local record = records[actor]
 if not record or record.Cast.closed or not Metadata.PassiveAvailable("P4Enraged(Passive)", actor:GetAttribute("Phase") or 0) then return 1 end
 return Difficulty.Allowed("P4Enraged(Passive)", Metadata.Get("P4Enraged(Passive)"), actor) and record.Enraged.Multiplier() or 1
end
function api.OnAttackFinished(handle, successful)
	if handle and not successful then
		handle:Cancel("Original active attack interrupted")
	end
end
 -- true while the actor's passive record is alive (phase changes and owner-wide cancels end it)
function api.Running(actor)
	local record = records[actor]
	return record ~= nil and not record.Cast.closed
end
function api.Stop(actor)
	local record = records[actor]
	if record then
		record.Cast:Dispose()
	end
end
return api
