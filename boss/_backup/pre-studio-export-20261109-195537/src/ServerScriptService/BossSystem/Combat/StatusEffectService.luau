local Observer = require(script:FindFirstAncestor("BossSystem").Players.PlayerObserver)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("BossShared")
 
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Service = {}
local Classes = require(Shared.Classes.ClassConfig)
local function baseSpeed(character)
  local def = Classes.Classes[character:GetAttribute("ClassId")] or Classes.Classes[Classes.Default]
  return character:GetAttribute("BaseWalkSpeed") or def.Speed
end
local EncounterConfig = require(Shared:WaitForChild("Config"):WaitForChild("EncounterConfig"))
local Time = require(BossSystem.Mechanics.Time.TimeEffectController)
local records = {}
local active = {}
local damage
local started = false
local ADVANCED_DEBUFFS = { "Vulnerability", "CooldownIncrease", "CooldownFreeze", "ChainCurse", "TemporalWound", "Acid", "DeathMark", "JumpLock", "Blur", "Rupture", "IllusionRot", "Frostbite", "Hemorrhage", "Corruption", "Decay" }
local AdvancedTuning = EncounterConfig.NewDebuffs
local NAMED_DEBUFFS = { "Electricified", "Flung" }
local TICKED_EFFECTS = { "CardBurn", "CupRegenBoost", "Poison" }

function Service.IsDebuffImmune(character)
	return Observer.IsCharacter(character)
end

local function staleToken(token)
	return type(token) == "table" and (token.closed or token.Disposed)
		or typeof(token) == "Instance" and not token.Parent
end

local function resolveSource(actor)
	if not actor then
		return nil
	end
	return require(BossSystem.Players.PlayerEncounter).DamageOwner(actor)
end

local function setAttribute(instance, name, value)
	if instance and instance:GetAttribute(name) ~= value then
		instance:SetAttribute(name, value)
	end
end

local function publish(record, name, value)
	setAttribute(record.character, name, value)
	if record.player.Character == record.character then
		setAttribute(record.player, name, value)
	end
end
local function publishDeadline(record, name, deadline)
	local remaining = math.max(0, deadline - Time.ActionNow(record.character))
	local rate = Time.Rate(record.character)
	local display = remaining > 0 and workspace:GetServerTimeNow() + remaining / (rate > 0 and rate or 1) or 0
	if display == 0 or math.abs((record.character:GetAttribute(name) or 0) - display) > 0.08 then
		publish(record, name, display)
	end
end

local function isCurrent(record)
	return record.player.Parent == Players
		and record.player.Character == record.character
		and record.character.Parent
		and record.humanoid.Parent
		and record.humanoid.Health > 0
end

local function hasLocks(record)
	for token in pairs(record.locks) do
		if staleToken(token) then
			record.locks[token] = nil
		end
	end
	return next(record.locks) ~= nil
end
local function hasMovementLocks(record)
	 
	 
	local now = Time.EncounterNow(nil)
	for token, entry in pairs(record.movementLocks) do
		if entry.expires <= now or type(token) == "table" and (token.closed or token.Disposed) then
			record.movementLocks[token] = nil
		end
	end
	return next(record.movementLocks) ~= nil
end

local function hasJumpLocks(record)
	for token in pairs(record.jumpLocks) do
		if staleToken(token) then
			record.jumpLocks[token] = nil
		end
	end
	local jumpLock = record.p3Effects and record.p3Effects.JumpLock
	return not Service.IsDebuffImmune(record.character) and (next(record.jumpLocks) ~= nil
		or jumpLock ~= nil and jumpLock.deadline > Time.ActionNow(record.character))
end

local function refreshJump(record, movementLocked)
	local h, character = record.humanoid, record.character
	local disabled = movementLocked or hasJumpLocks(record)
	publish(record, "JumpDisabled", disabled)
	if disabled then
		if not record.jumpSnapshot then
			record.jumpSnapshot = {
				Power = h.JumpPower,
				Height = h.JumpHeight,
				Enabled = h:GetStateEnabled(Enum.HumanoidStateType.Jumping),
			}
		end
		h.JumpPower = 0
		h.JumpHeight = 0
		h.Jump = false
		h:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	elseif
		record.jumpSnapshot
		and not character:GetAttribute("ParryFrozen")
		and not character:GetAttribute("ExecutionPending")
	then
		local snapshot = record.jumpSnapshot
		record.jumpSnapshot = nil
		h.JumpPower = snapshot.Power
		h.JumpHeight = snapshot.Height
		h:SetStateEnabled(Enum.HumanoidStateType.Jumping, snapshot.Enabled)
	end
end

local function clearMark(record)
	record.goldenMarkStacks = 0
	record.goldenMarkUntil = 0
	record.goldenMarkOwner = nil
	publish(record, "GoldenMarkStacks", 0)
	publish(record, "GoldenMarkUntil", 0)
end

local function refreshMark(record, now)
	if Service.IsDebuffImmune(record.character) then
		clearMark(record)
		return
	end
	if record.goldenMarkStacks > 0 then
		local owner = record.goldenMarkOwner
		local h = owner and owner:FindFirstChildOfClass("Humanoid")
		if
			now >= record.goldenMarkUntil
			or not owner
			or not owner.Parent
			or not h
			or h.Health <= 0
			or owner:GetAttribute("EncounterEnded")
			or math.floor(owner:GetAttribute("Phase") or 1) ~= 3
		then
			clearMark(record)
		else
			publishDeadline(record, "GoldenMarkUntil", record.goldenMarkUntil)
		end
	end
end

local function refreshBurn(record)
	for token in pairs(record.burnZones) do
		if
			type(token) == "table" and (token.closed or token.Disposed)
			or typeof(token) == "Instance" and not token.Parent
		then
			record.burnZones[token] = nil
		end
	end
	local timed=record.p3Effects and record.p3Effects.GoldenBurn
 local burning = not Service.IsDebuffImmune(record.character)
  and (next(record.burnZones) ~= nil or timed and timed.deadline>Time.ActionNow(record.character))
	publish(record, "GoldenBurnActive", burning)
	return burning
end

local function refreshSlow(record, now)
	local multiplier, deadline, zones = 1, 0, 0
 local displayDeadline = 0
	local immune = Service.IsDebuffImmune(record.character)
	for token, entry in pairs(record.timedSlows) do
  if entry.realDeadline then entry.deadline = now + math.max(0, entry.realDeadline - workspace:GetServerTimeNow()) end
		if entry.deadline <= now then
			record.timedSlows[token] = nil
		elseif not immune then
			multiplier = math.min(multiplier, entry.multiplier)
			deadline = math.max(deadline, entry.deadline)
   local rate = Time.Rate(record.character)
   displayDeadline = math.max(displayDeadline, entry.realDeadline or workspace:GetServerTimeNow() + (entry.deadline - now) / (rate > 0 and rate or 1))
		end
	end
	for token, value in pairs(record.zoneSlows) do
		 
		local stale = type(token) == "table" and (token.closed == true or token.Disposed == true)
		if typeof(token) == "Instance" and not token.Parent then
			stale = true
		end
		if stale then
			record.zoneSlows[token] = nil
		elseif not immune then
			multiplier = math.min(multiplier, value)
			zones += 1
		end
	end
	local frostbite = record.p3Effects and record.p3Effects.Frostbite
	if frostbite and frostbite.deadline > now and not immune then
		multiplier = math.min(multiplier, 1 - AdvancedTuning.Frostbite.SlowAmount)
	end
	record.slowUntil, record.slowMultiplier = deadline, multiplier
	publish(record, "SlowUntil", displayDeadline)
	publish(record, "SlowMultiplier", multiplier)
	publish(record, "SlowAmount", 1 - multiplier)
	publish(record, "ZoneSlowActive", zones > 0)
	publish(record, "ZoneSlowCount", zones)
end

local P3_DEBUFFS = { "AstralBurn", "Vulnerability", "CooldownIncrease", "CooldownFreeze", "ChainCurse", "TemporalWound", "Acid", "DeathMark", "JumpLock", "Blur", "Rupture", "IllusionRot", "Frostbite", "Hemorrhage", "Corruption", "Decay", "Fear", "HPRegenBlock", "StaminaRegenBlock", "AttackDebuff", "CardBurn", "ProjectileDarkness", "Poison", "GoldenBurn" }
local P3_EFFECTS = { "AstralBurn", "Vulnerability", "CooldownIncrease", "CooldownFreeze", "ChainCurse", "TemporalWound", "Acid", "DeathMark", "JumpLock", "Blur", "Rupture", "IllusionRot", "Frostbite", "Hemorrhage", "Corruption", "Decay", "Fear",
 "Poison", "GoldenBurn",
	"HPRegenBlock",
	"StaminaRegenBlock",
	"AttackDebuff",
	"CardBurn",
	"ProjectileDarkness",
 "Cleanse",
	"CupAttackBoost",
	"CupRegenBoost",
}
local function refreshP3(record, now)
	local effects = record.p3Effects or {}
	record.p3Effects = effects
	for _, name in ipairs(P3_EFFECTS) do
		local entry = effects[name]
  if entry and entry.realDeadline then
   entry.deadline = now + math.max(0, entry.realDeadline - workspace:GetServerTimeNow())
  end
		if
			entry
			and (now >= entry.deadline or table.find(P3_DEBUFFS, name) and Service.IsDebuffImmune(record.character))
		then
			effects[name] = nil
			entry = nil
		end
  if entry and entry.realDeadline then publish(record, name .. "Until", entry.realDeadline)
  else publishDeadline(record, name .. "Until", entry and entry.deadline or 0) end
	end
	publish(record, "HemorrhageStacks", effects.Hemorrhage and effects.Hemorrhage.stacks or 0)
	publish(record, "DeathMarkStacks", effects.DeathMark and effects.DeathMark.stacks or 0)
	Time.RefreshPlayerCooldowns(record.character)
	publish(record, "CooldownRecoveryRate", effects.CooldownFreeze and 0
		or effects.CooldownIncrease and AdvancedTuning.CooldownIncrease.RecoveryRate or 1)
end

local function refreshNamedDebuffs(record)
 local now=workspace:GetServerTimeNow()
 for _,name in ipairs(NAMED_DEBUFFS) do
  local entries=record.namedDebuffs[name] or {}
  record.namedDebuffs[name]=entries
  local deadline=0
  for token,untilTime in pairs(entries) do
   if staleToken(token) or now>=untilTime or Service.IsDebuffImmune(record.character) then entries[token]=nil
   else deadline=math.max(deadline,untilTime) end
  end
  publish(record,name.."Until",deadline)
  publish(record,name.."Active",deadline>now)
 end
end
local function refresh(record)
	local humanoid, character = record.humanoid, record.character
	if not humanoid.Parent then
		return
	end
	refreshNamedDebuffs(record)
	refreshSlow(record, Time.ActionNow(character))
	local movementLocked = hasMovementLocks(record)
	local abilityLocked = hasLocks(record)
	local chainedControl = abilityLocked
	for _,entry in pairs(record.movementLocks) do
	 if entry.effect~="Electricified" and entry.effect~="Flung" and entry.effect~="Stunned" then chainedControl=true end
	end
	publish(record,"ChainedControlActive",chainedControl)
	for _, entry in pairs(record.movementLocks) do
		if not entry.allowDefense then
			abilityLocked = true
		end
	end
	local locked = movementLocked or hasLocks(record)
	publish(record, "AbilitiesLocked", abilityLocked)
	publish(record, "StatusLocked", abilityLocked)
	publish(record, "MovementLocked", locked)
	publish(record, "DashLocked", locked)
	refreshJump(record, locked)
	if locked then
		if not record.movementSnapshot then
			record.movementSnapshot = {
				AutoRotate = humanoid.AutoRotate,
			}
		end
		humanoid.AutoRotate = false
		if humanoid.WalkSpeed ~= 0 then
			humanoid.WalkSpeed = 0
		end
		return
	end
	local cinematicLocked = character:GetAttribute("ParryFrozen") or character:GetAttribute("ExecutionPending")
	local snapshot = record.movementSnapshot
	if snapshot and not cinematicLocked then
		record.movementSnapshot = nil
		humanoid.AutoRotate = snapshot.AutoRotate
	end
	 
	if cinematicLocked then
		return
	end
	local base = baseSpeed(character)
	local slow = record.slowMultiplier
	local speed = base * slow * Time.Rate(character)
	if math.abs(humanoid.WalkSpeed - speed) > 0.001 then
		humanoid.WalkSpeed = speed
	end
end

local function clearRecord(player, expected)
	local record = records[player]
	if not record or (expected and record ~= expected) then
		return
	end
	record.namedDebuffs={}
	publish(record,"ElectricifiedUntil",0)
	publish(record,"ElectricifiedActive",false)
	publish(record,"FlungUntil",0)
	publish(record,"FlungActive",false)
	table.clear(record.locks)
	table.clear(record.movementLocks)
	table.clear(record.stunFamilies)
	table.clear(record.jumpLocks)
	table.clear(record.timedSlows)
	table.clear(record.zoneSlows)
	table.clear(record.burnZones)
	record.p3Effects = {}
	publish(record, "HemorrhageStacks", 0)
	publish(record, "DeathMarkStacks", 0)
	Time.RefreshPlayerCooldowns(record.character)
	publish(record, "CooldownRecoveryRate", 1)
	for _, name in ipairs(P3_EFFECTS) do
		publish(record, name .. "Until", 0)
	end
	publish(record, "GoldenBurnActive", false)
	record.slowUntil = 0
	record.slowMultiplier = 1
 record.cupBleedUntil = nil
	record.bleedUntil = 0
	record.bleedSource = nil
	clearMark(record)
	refresh(record)
	publish(record, "SlowUntil", 0)
	publish(record, "BleedUntil", 0)
	publish(record, "SlowMultiplier", 1)
	publish(record, "SlowAmount", 0)
	publish(record, "ZoneSlowActive", false)
	publish(record, "ZoneSlowCount", 0)
	 
	 
	if isCurrent(record) and (record.jumpSnapshot or record.movementSnapshot) then
		record.pendingClear = true
		active[record] = true
		return
	end
	records[player] = nil
	active[record] = nil
	for _, connection in ipairs(record.connections) do
		connection:Disconnect()
	end
end

local function ensure(character)
	if not character or not character.Parent then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not player or player.Character ~= character or not humanoid or humanoid.Health <= 0 then
		return
	end
	local record = records[player]
	if record and record.character == character then
		 
		record.pendingClear = nil
		return record
	end
	if record then
		clearRecord(player)
	end
	record = {
		player = player,
		character = character,
		humanoid = humanoid,
		baseSpeed = baseSpeed(character),
		slowUntil = 0,
		slowMultiplier = 1,
		bleedUntil = 0,
		nextBleed = 0,
		locks = {},
		movementLocks = {},
		namedDebuffs = {},
		stunFamilies = {},
		jumpLocks = {},
		timedSlows = {},
		zoneSlows = {},
		burnZones = {},
		nextBurn = 0,
		connections = {},
		goldenMarkStacks = 0,
		goldenMarkUntil = 0,
	}
	records[player] = record
	table.insert(
		record.connections,
		humanoid.Died:Connect(function()
			clearRecord(player, record)
		end)
	)


	table.insert(
		record.connections,
		character:GetAttributeChangedSignal("ParryFrozen"):Connect(function()
			refresh(record)
		end)
	)
	publish(record, "SlowUntil", 0)
	publish(record, "BleedUntil", 0)
	publish(record, "SlowMultiplier", 1)
	publish(record, "SlowAmount", 0)
	publish(record, "ZoneSlowActive", false)
	publish(record, "ZoneSlowCount", 0)
	publish(record, "AbilitiesLocked", false)
	publish(record, "StatusLocked", false)
	publish(record, "MovementLocked", false)
	publish(record, "DashLocked", false)
	publish(record, "GoldenBurnActive", false)
	publish(record, "JumpDisabled", false)
	publish(record, "GoldenMarkStacks", 0)
	publish(record, "GoldenMarkUntil", 0)
	return record
end

function Service.TrackDebuff(character,name,token,deadline)
 assert(name=="Electricified" or name=="Flung","Unknown shield-break debuff")
 assert(token~=nil,"Debuff requires ownership")
 local player=character and Players:GetPlayerFromCharacter(character)
 local record=deadline and ensure(character) or player and records[player]
 if not record or record.character~=character then return false end
 if deadline and Service.IsDebuffImmune(character) then return false end
 record.namedDebuffs[name]=record.namedDebuffs[name] or {}
 record.namedDebuffs[name][token]=deadline
 active[record]=true
 refresh(record)
 return true
end
function Service.RefreshMovement(character)
	local record = ensure(character)
	if record then
		refresh(record)
	end
end

function Service.SetDebuffImmunity(character, enabled)
	local record = ensure(character)
	if not record then
		return false
	end
	publish(record, "DebuffImmune", enabled == true)
	if enabled then
		table.clear(record.timedSlows)
		table.clear(record.movementLocks)
		table.clear(record.stunFamilies)
		 
		for token in pairs(record.locks) do
			if type(token) ~= "table" or not (token.TimeStopControl or token.TransitionControl) then
				record.locks[token] = nil
			end
		end
		record.bleedUntil = 0
		record.bleedSource = nil
		publish(record, "BleedUntil", 0)
		clearMark(record)
		refreshP3(record, Time.ActionNow(character))
		refreshBurn(record)
	end
	active[record] = true
	refresh(record)
	return true
end

function Service.IsLocked(player)
	local record = records[player]
	if not record or not isCurrent(record) then
		return false
	end
	hasMovementLocks(record)
	if hasLocks(record) then
		return true
	end
	for _, entry in pairs(record.movementLocks) do
		if not entry.allowDefense then
			return true
		end
	end
	return false
end
function Service.IsMovementLocked(player)
	local record = records[player]
	return record and isCurrent(record) and (hasLocks(record) or hasMovementLocks(record)) or false
end
function Service.IsUninterrupted(character)
 return character~=nil and (character:GetAttribute("TankDefenderHeld")==true or character:GetAttribute("ClassStatus_Uninterrupted")~=nil)
end
function Service.Restrain(character, token, seconds, options)
 local cinematic=options and options.TransitionControl or type(token)=="table"
  and (token.TimeStopControl or token.TransitionControl or tostring(token.name or ""):find("(Ultimate)",1,true))
 if Service.IsUninterrupted(character) and not cinematic then return false end
 assert(token ~= nil, "Movement restraint requires an owner token")
	if Service.IsDebuffImmune(character) then
		return false
	end
	local record = ensure(character)
	if not record then
		return false
	end
	record.movementLocks[token] = {
		expires = Time.EncounterNow(nil) + math.clamp(seconds, 0.05, 30),
		allowDefense = options and options.AllowDefense == true,
		effect = options and options.Effect,
	}
	active[record] = true
	refresh(record)
	return true
end

 
 
function Service.ApplyStun(character, token, seconds, grace, options)
 if Service.IsUninterrupted(character) and not (options and options.TransitionControl) then return false end
	assert(token ~= nil, "Combat stun requires an owner token")
	options = options or {}
	local record = ensure(character)
	if not record then
		return false
	end
	local now = Time.EncounterNow(nil)
	local family = options.Family or "ChainStun"
	if now < (record.stunFamilies[family] or 0) then
		return false
	end
	seconds = math.clamp(seconds or 0.5, 0.05, 30)
	if not Service.Restrain(character, token, seconds, options) then
		return false
	end
	record.stunFamilies[family] = now + seconds + math.clamp(grace or 0.9, 0, 5)
	return true
end

function Service.IsStunProtected(character, family)
	if Service.IsDebuffImmune(character) or Service.IsUninterrupted(character) then
		return true
	end
	local player = character and Players:GetPlayerFromCharacter(character)
	local record = player and records[player]
	return record ~= nil
			and record.character == character
			and isCurrent(record)
			and Time.EncounterNow(nil) < (record.stunFamilies[family or "ChainStun"] or 0)
		or false
end
function Service.ReleaseRestraint(character, token)
	local player = character and Players:GetPlayerFromCharacter(character)
	local record = player and records[player]
	if not record or record.character ~= character then
		return false
	end
	record.movementLocks[token] = nil
	refresh(record)
	return true
end
function Service.ExclusivelyRestrainedBy(character, token)
	local player = character and Players:GetPlayerFromCharacter(character)
	local record = player and records[player]
	if
		not record
		or record.character ~= character
		or not isCurrent(record)
		or not record.movementLocks[token]
		or hasLocks(record)
	then
		return false
	end
	for owner in pairs(record.movementLocks) do
		if owner ~= token then
			return false
		end
	end
	return true
end

 
function Service.SetJumpDisabled(character, token, disabled)
	assert(token ~= nil, "Jump suppression requires an owner token")
	local player = character and Players:GetPlayerFromCharacter(character)
	local record = disabled and ensure(character) or player and records[player]
	if not record or record.character ~= character then
		return false
	end
	record.jumpLocks[token] = disabled and true or nil
	if disabled then
		active[record] = true
	end
	refresh(record)
	return true
end

function Service.ApplyGoldenMark(character, owner)
	if Service.IsDebuffImmune(character) then
		return 0
	end
	owner = resolveSource(owner)
	local ownerHumanoid = owner and owner:FindFirstChildOfClass("Humanoid")
	if
		not owner
		or math.floor(owner:GetAttribute("Phase") or 1) ~= 3
		or not owner.Parent
		or not ownerHumanoid
		or ownerHumanoid.Health <= 0
		or owner:GetAttribute("EncounterEnded")
	then
		return 0
	end
	local record = ensure(character)
	if not record then
		return 0
	end
	local now = Time.ActionNow(character)
	refreshMark(record, now)
	if record.goldenMarkOwner ~= owner then
		clearMark(record)
	end
	record.goldenMarkOwner = owner
	record.goldenMarkStacks = math.min(EncounterConfig.GoldenMarkMaxStacks, record.goldenMarkStacks + 1)
	record.goldenMarkUntil = now + EncounterConfig.GoldenMarkDuration
	active[record] = true
	publish(record, "GoldenMarkStacks", record.goldenMarkStacks)
	publishDeadline(record, "GoldenMarkUntil", record.goldenMarkUntil)
	return record.goldenMarkStacks
end

function Service.ClearGoldenMark(character, owner)
	local player = character and Players:GetPlayerFromCharacter(character)
	local record = player and records[player]
	if not record or record.character ~= character or owner and record.goldenMarkOwner ~= owner then
		return false
	end
	clearMark(record)
	return true
end

function Service.ClearGoldenMarksFor(owner)
	for _, record in pairs(records) do
		if record.goldenMarkOwner == owner then
			clearMark(record)
		end
	end
end

function Service.GoldenMarkDamageMultiplier(character)
	local player = character and Players:GetPlayerFromCharacter(character)
	local record = player and records[player]
	if not record or record.character ~= character then
		return 1
	end
	refreshMark(record, Time.ActionNow(character))
	return 1 + record.goldenMarkStacks * EncounterConfig.GoldenMarkDamagePerStack
end

 
function Service.SetLocked(player, token, locked)
	assert(token ~= nil, "A status lock requires an owner token")
	if
		locked
		and Service.IsDebuffImmune(player.Character)
		and not (type(token) == "table" and (token.TimeStopControl or token.TransitionControl))
	then
		return false
	end
	local record = locked and ensure(player.Character) or records[player]
	if not record then
		return false
	end
	record.locks[token] = locked and true or nil
	if hasLocks(record) then
		active[record] = true
	end
	refresh(record)
	return true
end

function Service.ApplySlow(character, amount, seconds, ownerToken)
	if Service.IsDebuffImmune(character) then
		return false
	end
	local record = ensure(character)
	if not record then
		return false
	end
	local now = Time.ActionNow(character)
	local multiplier = 1 - math.clamp(amount, 0, 1)
	local token = ownerToken or multiplier
	local previous = record.timedSlows[token]
	record.timedSlows[token] = {
		multiplier = multiplier,
		deadline = math.max(previous and previous.deadline or 0, now + math.clamp(seconds, 0.1, 30)),
	}
	active[record] = true
	refresh(record)
	return true
end

 
function Service.SetZoneSlow(character, ownerToken, amount)
	assert(ownerToken ~= nil, "A zone slow requires an owner token")
	local record = amount ~= nil and ensure(character) or records[Players:GetPlayerFromCharacter(character)]
	if not record or record.character ~= character then
		return false
	end
	record.zoneSlows[ownerToken] = amount ~= nil and 1 - math.clamp(amount, 0, 1) or nil
	if amount ~= nil then
		active[record] = true
	end
	refresh(record)
	return true
end

 
 
function Service.RemoveZoneSlow(characterOrToken, ownerToken)
	if ownerToken ~= nil then
		return Service.SetZoneSlow(characterOrToken, ownerToken, nil)
	end
	local removed = false
	for _, record in pairs(records) do
		if record.zoneSlows[characterOrToken] ~= nil then
			record.zoneSlows[characterOrToken] = nil
			refresh(record)
			removed = true
		end
	end
	return removed
end
Service.ClearZoneSlow = Service.RemoveZoneSlow

 
function Service.SetZoneBurn(character, token, inside, sourceActor)
	assert(token ~= nil, "Golden Burn needs an owner token")
	if inside and sourceActor and sourceActor:GetAttribute("IsIllusion") then
		return false
	end
	local record = inside and ensure(character) or records[Players:GetPlayerFromCharacter(character)]
	if not record or record.character ~= character then
		return false
	end
	local wasBurning = refreshBurn(record)
	local previous = record.burnZones[token]
	record.burnZones[token] = inside and { Source = resolveSource(sourceActor) or previous and previous.Source } or nil
	if inside then
		if not wasBurning and record.nextBurn <= Time.ActionNow(character) then
			record.nextBurn = Time.ActionNow(character) + 0.5
		end
		active[record] = true
	end
	refreshBurn(record)
	return true
end
function Service.RemoveZoneBurn(token)
	for _, record in pairs(records) do
		if record.burnZones[token] then
			record.burnZones[token] = nil
			refreshBurn(record)
		end
	end
end

function Service.ApplyBleed(character, seconds, sourceActor)
	if sourceActor and sourceActor:GetAttribute("IsIllusion") then
		return false
	end
	if Service.IsDebuffImmune(character) then
		return false
	end
	if not require(BossSystem.Players.PlayerEncounter).CanReceiveHit(character) then
		return false
	end
	local record = ensure(character)
	if not record then
		return false
	end
	local now = Time.ActionNow(character)
	if record.bleedUntil <= now then
		record.nextBleed = now + 1
	end
	record.bleedUntil = math.max(record.bleedUntil, now + math.clamp(seconds, 0.1, 30))
	record.bleedSource = resolveSource(sourceActor) or record.bleedSource
	active[record] = true
	publishDeadline(record, "BleedUntil", record.bleedUntil)
	return true
end

function Service.IsRegenBlocked(character,kind)
 if kind=="HP" and character and character:GetAttribute("DeathRoarsHealthCap") then return true end
 local player=character and Players:GetPlayerFromCharacter(character)
 local record=player and records[player]
 if not record or record.character~=character or Service.IsDebuffImmune(character) then return false end
 local effects=record.p3Effects or {}
 local now=Time.ActionNow(character)
 local fear,block=effects.Fear,effects[kind.."RegenBlock"]
 return (fear~=nil and fear.deadline>now) or (block~=nil and block.deadline>now)
end

function Service.P3DamageMultiplier(character)
	local player = character and Players:GetPlayerFromCharacter(character)
	local record = player and records[player]
	if not record or record.character ~= character or not isCurrent(record) then
		return 1
	end
	local effects = record.p3Effects or {}
	local now, multiplier = Time.ActionNow(character), 1
	if effects.AttackDebuff and effects.AttackDebuff.deadline > now and not Service.IsDebuffImmune(character) then
		multiplier *= EncounterConfig.P3CardsAttackMultiplier or 0.75
	end
	if effects.CupAttackBoost and effects.CupAttackBoost.deadline > now then
		multiplier *= EncounterConfig.PickThePupilsRewardAttackMultiplier or 1.25
	end
	return multiplier
end

local function setP3Effect(character, name, seconds, sourceActor)
	local record = ensure(character)
	if not record then
		return false
	end
	local now = Time.ActionNow(character)
	record.p3Effects = record.p3Effects or {}
	local previous = record.p3Effects[name]
	record.p3Effects[name] = {
		deadline = math.max(previous and previous.deadline or 0, now + seconds),
		nextTick = previous and previous.deadline > now and previous.nextTick or now + (name=="Poison" and (EncounterConfig.PoisonTickInterval or .5) or 1),
		source = resolveSource(sourceActor),
	}
	active[record] = true
	refreshP3(record, now)
	return true
end


local BurnSchedule=require(BossSystem.Combat.AstralBurnSchedule)
function Service.ApplyAstralBurn(character,amounts,interval,sourceActor,skill,key,immediate)
 if Service.IsDebuffImmune(character)or Observer.IsCharacter(character)then return false end
 local metadata=require(BossSystem.Combat.AbilityMetadata).Get(skill)
 if not metadata or metadata.NativePhase~=5 then return false end
 local record=ensure(character)
 if not record then return false end
 record.p3Effects=record.p3Effects or {}  -- a fresh record has none until its first P3-style effect
 local now=Time.ActionNow(character)
 local entry=record.p3Effects.AstralBurn
 if not entry or entry.deadline<=now then entry={streams={},deadline=now}record.p3Effects.AstralBurn=entry end
 key=key or skill
 if entry.streams[key]then return false end
 local stream=BurnSchedule.New(amounts,interval,now,immediate)
 stream.Source=resolveSource(sourceActor)stream.Skill=skill
 stream.Generation=stream.Source and(stream.Source:GetAttribute("PhaseGeneration")or 0)
 entry.streams[key]=stream entry.deadline=math.max(entry.deadline,BurnSchedule.Deadline(stream))
 active[record]=true refreshP3(record,now)
 return true
end
local function tickAstralBurn(record,now)
 local entry=record.p3Effects.AstralBurn
 if not entry or Time.Rate(record.character)<=0 then return end
 for key,stream in pairs(entry.streams)do
  local owner=stream.Source
  local h=owner and owner:FindFirstChildOfClass("Humanoid")
  if not owner or not owner.Parent or not h or h.Health<=0 or owner:GetAttribute("EncounterEnded")or owner:GetAttribute("Phase")~=5 or(owner:GetAttribute("PhaseGeneration")or 0)~=stream.Generation then
   entry.streams[key]=nil
  else
   local amount=BurnSchedule.Take(stream,now)
   if amount and damage then damage(record.character,amount,owner,nil,{Skill=stream.Skill,IsStatusDamage=true})end
   if records[record.player]~=record then return end
   if BurnSchedule.Done(stream)then entry.streams[key]=nil
   else entry.deadline=math.max(entry.deadline,BurnSchedule.Deadline(stream))end
  end
 end
end

function Service.ApplyAdvancedDebuff(character, name, seconds, sourceActor, options)
	assert(table.find(ADVANCED_DEBUFFS, name), "Unknown advanced debuff")
	if Service.IsDebuffImmune(character) or sourceActor and sourceActor:GetAttribute("IsIllusion")
		or not (options and options.CupPenalty) and not require(BossSystem.Players.PlayerEncounter).CanReceiveHit(character) then return false end
	local record = ensure(character)
	if not record then return false end
	local now = Time.ActionNow(character)
	record.p3Effects = record.p3Effects or {}
	local previous = record.p3Effects[name]
	local live = previous and previous.deadline > now
	local tuning = AdvancedTuning[name]
	local root = character:FindFirstChild("HumanoidRootPart")
	if not (options and options.CupPenalty) and (name == "CooldownFreeze" or name == "JumpLock") then seconds = math.min(seconds or tuning.MaxDuration, tuning.MaxDuration) end
	local entry = {
		deadline = math.max(live and previous.deadline or 0, now + math.clamp(seconds or 10, 0.1, 30)),
		nextTick = live and previous.nextTick or now + tuning.Interval,
		source = resolveSource(sourceActor),
		startedAt = live and previous.startedAt or now,
		stacks = (name == "Hemorrhage" or name == "DeathMark") and math.min(tuning.MaxStacks, (live and previous.stacks or 0) + 1) or 1,
		recordedDamage = live and previous.recordedDamage or 0,
		lastPosition = root and root.Position,
		distance = live and previous.distance or 0,
	}
	record.p3Effects[name] = entry
	if name == "DeathMark" and entry.stacks >= tuning.MaxStacks then
		record.p3Effects.DeathMark = nil
		if damage then damage(character, tuning.BurstDamage, entry.source, nil, { Skill = "DeathMark", IsStatusDamage = true }) end
		if records[record.player] ~= record then return true end
	end
	active[record] = true
	refreshP3(record, now)
	refresh(record)
	return true
end
for _, name in ipairs(ADVANCED_DEBUFFS) do
	Service["Apply" .. name] = function(character, seconds, sourceActor)
		return Service.ApplyAdvancedDebuff(character, name, seconds, sourceActor)
	end
end
local function advancedDamage(record, entry, name, amount)
	if amount > 0 and damage then
		damage(record.character, amount, entry.source, nil, { Skill = name, IsStatusDamage = true })
	end
end
function Service.OnDash(character)
	local player = character and Players:GetPlayerFromCharacter(character)
	local record = player and records[player]
	if not record or record.character ~= character or not isCurrent(record) then return end
	local now = Time.ActionNow(character)
	refreshP3(record, now)
	local entry = record.p3Effects.Rupture
	if entry and entry.deadline > now and Time.Rate(character) > 0 then
		entry.distance = 0
		entry.nextTick = now + AdvancedTuning.Rupture.Interval
		advancedDamage(record, entry, "Rupture", AdvancedTuning.Rupture.DashDamage)
	end
end
local function tickAdvancedDebuffs(record, now)
	local character = record.character
	local root = character:FindFirstChild("HumanoidRootPart")
	local running = Time.Rate(character) > 0
	for _, name in ipairs(ADVANCED_DEBUFFS) do
		local entry = record.p3Effects[name]
		if not entry then continue end
		local tuning = AdvancedTuning[name]
		if name == "Rupture" and root then
			if running and entry.lastPosition and not character:GetAttribute("Dashing") then
				local delta = root.Position - entry.lastPosition
				local distance = Vector3.new(delta.X, 0, delta.Z).Magnitude
				if distance <= 12 then entry.distance += distance end
			end
			entry.lastPosition = root.Position
		end
		if not running or now + 0.001 < entry.nextTick then continue end
		entry.nextTick = now + tuning.Interval
		local amount = 0
		if name == "Rupture" then
			if not character:GetAttribute("Dashing") and entry.distance >= tuning.MoveDistance then
				amount = tuning.MoveDamage
			end
			entry.distance = 0
		elseif name == "IllusionRot" then
			local darkness = record.p3Effects.ProjectileDarkness
			local worldNow = workspace:GetServerTimeNow()
			if darkness and darkness.deadline > now
				or (character:GetAttribute("ControlDistortionUntil") or 0) > worldNow then
				amount = tuning.Damage
			end
		elseif name == "Frostbite" then
			amount = tuning.Damage
		elseif name == "Hemorrhage" then
			amount = tuning.DamagePerStack * entry.stacks
		elseif name == "Corruption" then
			amount = math.min(tuning.MaxDamage, tuning.BaseDamage + math.max(0, math.floor(now - entry.startedAt - tuning.Interval + 0.001)) * tuning.GrowthPerSecond)
		elseif name == "Decay" then
			amount = tuning.Damage
		elseif name == "Acid" then
			amount = tuning.Damage
		elseif name == "TemporalWound" then
			amount = entry.recordedDamage * tuning.RepeatFraction
			entry.recordedDamage = 0
		elseif name == "ChainCurse" then
			amount = tuning.Damage
			if root then
				for _, teammate in ipairs(Players:GetPlayers()) do
					local char = teammate.Character
					local teammateRoot = char and char:FindFirstChild("HumanoidRootPart")
					if char ~= character and teammateRoot and (teammateRoot.Position - root.Position).Magnitude <= tuning.Radius
						and not Service.IsDebuffImmune(char) and damage then
						damage(char, tuning.NearbyDamage, entry.source, nil, { Skill = "ChainCurse", IsStatusDamage = true })
					end
				end
			end
		end
		advancedDamage(record, entry, name, amount)
		if records[record.player] ~= record then return end
	end
end

local function activeEntry(character, name)
	local player = character and Players:GetPlayerFromCharacter(character)
	local record = player and records[player]
	if not record or record.character ~= character or not isCurrent(record) or Service.IsDebuffImmune(character) then return end
	local entry = record.p3Effects and record.p3Effects[name]
	if entry and entry.deadline > Time.ActionNow(character) then return entry, record end
end
function Service.IncomingDamageMultiplier(character, balance)
	local entry = activeEntry(character, "Vulnerability")
	return entry and not (balance and balance.IsStatusDamage) and AdvancedTuning.Vulnerability.Multiplier or 1
end
function Service.DefenseReduction(character)
	return activeEntry(character, "Acid") and AdvancedTuning.Acid.DefenseReduction or 0
end
function Service.OnDamageReceived(character, amount, balance)
	if amount <= 0 then return end
	local vulnerability, record = activeEntry(character, "Vulnerability")
	if vulnerability and not (balance and balance.IsStatusDamage) then
		record.p3Effects.Vulnerability = nil
		publish(record, "VulnerabilityUntil", 0)
	end
	local wound = activeEntry(character, "TemporalWound")
	if wound and not (balance and balance.Skill == "TemporalWound") then
		wound.recordedDamage += amount
	end
end
function Service.ClearFearFor(owner)
 for _,record in pairs(records) do
  local entry=record.p3Effects and record.p3Effects.Fear
  if entry and entry.source==owner then record.p3Effects.Fear=nil;publish(record,"FearUntil",0) end
 end
end
function Service.ClearGoldenBurnFor(owner)
 for _,record in pairs(records) do
  local entry=record.p3Effects.GoldenBurn
  if entry and entry.source==owner then record.p3Effects.GoldenBurn=nil;publish(record,"GoldenBurnUntil",0);refreshBurn(record) end
 end
end
function Service.ApplyFear(character,seconds,source)
 if Service.IsDebuffImmune(character) then return false end
 return setP3Effect(character,"Fear",seconds or 2,source)
end
function Service.ApplyPoison(character,seconds,source)
 if Service.IsDebuffImmune(character) then return false end
 return setP3Effect(character,"Poison",seconds or EncounterConfig.PoisonDuration or 10,source)
end
function Service.ApplyGoldenBurn(character,seconds,source)
 if Service.IsDebuffImmune(character) then return false end
 if not setP3Effect(character,"GoldenBurn",seconds or EncounterConfig.TrueSpiritBurnDuration or 4,source) then return false end
 local record=ensure(character)
 if record.nextBurn<=Time.ActionNow(character) then record.nextBurn=Time.ActionNow(character)+0.5 end
 refreshBurn(record)
 return true
end
function Service.ApplyCardDebuff(character,name,seconds,sourceActor)
 if not table.find(P3_DEBUFFS,name) and name~="Slow" and name~="Bleed" then
  return require(BossSystem.Combat.CardDebuffService).Apply(character,name,seconds,sourceActor)
 end
 if Service.IsDebuffImmune(character) or sourceActor and sourceActor:GetAttribute("IsIllusion")
  or not require(BossSystem.Players.PlayerEncounter).CanReceiveHit(character) then return false end
 seconds=math.clamp(seconds,5,10)
 if table.find(ADVANCED_DEBUFFS,name) then return Service.ApplyAdvancedDebuff(character,name,seconds,sourceActor) end
 if name=="Slow" then return Service.ApplySlow(character,EncounterConfig.P3CardsSlowAmount or .25,seconds,"P3Cards")
 elseif name=="Bleed" then return Service.ApplyBleed(character,seconds,sourceActor)
 elseif name=="Fear" then return Service.ApplyFear(character,2,sourceActor)
 elseif name=="Poison" then return Service.ApplyPoison(character,seconds,sourceActor)
 elseif name=="GoldenBurn" then return Service.ApplyGoldenBurn(character,seconds,sourceActor)
 elseif name=="ProjectileDarkness" then return require(BossSystem.Combat.CardDebuffService).Apply(character,name,seconds,sourceActor)
 end
 return setP3Effect(character,name,seconds,sourceActor)
end

function Service.ApplyProjectileDarkness(character, seconds, source, token)
	if Service.IsDebuffImmune(character) or source and source:GetAttribute("UltimateActive") then
		return false
	end
	if not setP3Effect(character, "ProjectileDarkness", seconds, source) then
		return false
	end
	local record = ensure(character)
	record.p3Effects.ProjectileDarkness.token = token
	return true
end
function Service.ClearProjectileDarkness(character, token)
	local player = Players:GetPlayerFromCharacter(character)
	local record = player and records[player]
	local entry = record and record.character == character and record.p3Effects.ProjectileDarkness
	if entry and (not token or entry.token == token) then
		record.p3Effects.ProjectileDarkness = nil
		publish(record, "ProjectileDarknessUntil", 0)
	end
end

function Service.ClearProjectileDarknessFor(owner)
	for player, record in pairs(records) do
		local entry = record.p3Effects and record.p3Effects.ProjectileDarkness
		if entry and entry.source == owner then
			Service.ClearProjectileDarkness(record.character, entry.token)
			record.character:SetAttribute("ProjectileDarknessToken", nil)
			local remote = game.ReplicatedStorage:FindFirstChild("BossCombatEffects")
			if remote and player.Parent == Players then
				remote:FireClient(player, "P3ProjectileDarknessEnd", { Token = entry.token })
			end
		end
	end
end

function Service.GrantCupAttackBoost(character)
	return setP3Effect(character, "CupAttackBoost", EncounterConfig.PickThePupilsAttackBoostDuration or 45)
end

function Service.GrantCupRegenBoost(character)
	return setP3Effect(character, "CupRegenBoost", EncounterConfig.PickThePupilsRegenBoostDuration or 45)
end

function Service.GrantCupReward(character)
	local attack = Service.GrantCupAttackBoost(character)
	local regen = Service.GrantCupRegenBoost(character)
	return attack and regen
end

local CUP_DEBUFFS = table.freeze({
 "Vulnerability", "CooldownIncrease", "CooldownFreeze", "ChainCurse", "TemporalWound",
 "Acid", "DeathMark", "JumpLock", "Blur", "Rupture", "IllusionRot", "Frostbite",
 "Hemorrhage", "Corruption", "Decay", "Fear", "HPRegenBlock", "StaminaRegenBlock",
 "AttackDebuff", "CardBurn", "Poison", "GoldenBurn", "Bleed", "Slow",
})
function Service.ApplyCupPenalty(character, sourceActor, rng)
 local applied = {}
 if Service.IsDebuffImmune(character) or sourceActor and sourceActor:GetAttribute("IsIllusion")
  or Observer.IsCharacter(character) then return applied end
 local humanoid = character and character:FindFirstChildOfClass("Humanoid")
 if not humanoid or humanoid.Health <= 0 then return applied end
 rng = rng or Random.new()
 local pool = table.clone(CUP_DEBUFFS)
 local endsAt = workspace:GetServerTimeNow() + 30
 while #applied < 5 and #pool > 0 do
  local name = table.remove(pool, rng:NextInteger(1, #pool))
  local ok
  if table.find(ADVANCED_DEBUFFS, name) then
   ok = Service.ApplyAdvancedDebuff(character, name, 30, sourceActor, {CupPenalty=true})
  elseif name == "Bleed" then ok = Service.ApplyBleed(character, 30, sourceActor)
  elseif name == "Slow" then ok = Service.ApplySlow(character, EncounterConfig.P3CardsSlowAmount or .25, 30, "CupPenalty")
  elseif name == "GoldenBurn" then ok = Service.ApplyGoldenBurn(character, 30, sourceActor)
  else ok = setP3Effect(character, name, 30, sourceActor) end
  if ok then
   local record = ensure(character)
   local entry = record.p3Effects[name]
   if entry then entry.realDeadline = endsAt;entry.deadline=Time.ActionNow(character)+30 end
   if name == "Bleed" then record.cupBleedUntil = endsAt end
   if name == "Slow" then record.timedSlows.CupPenalty.realDeadline = endsAt end
   table.insert(applied, name)
  end
 end
 local record = ensure(character)
 if record then
  publish(record, "CupPenaltyDebuffs", table.concat(applied, ","))
  publish(record, "CupPenaltyUntil", #applied > 0 and endsAt or 0)
  refreshP3(record, Time.ActionNow(character))
 end
 return applied
end

function Service.CleanseDebuffs(character, sourceActor)
 local player = character and Players:GetPlayerFromCharacter(character)
 local humanoid = character and character:FindFirstChildOfClass("Humanoid")
 if not player or not humanoid or humanoid.Health <= 0 then return false end
 local record = records[player]
 local buffs = {}
 if record and record.character == character then
  for name, entry in pairs(record.p3Effects or {}) do
   if not table.find(P3_DEBUFFS, name) then buffs[name] = entry end
  end
 end
 require(BossSystem.Combat.CardDebuffService).ClearCharacter(character)
 require(BossSystem.Attacks.Shared.ShieldBreakControl).Clear(character)
 require(BossSystem.Mechanics.Reality.RealityController).ClearCharacter(character)
 if sourceActor then
  require(BossSystem.Combat.AttackRegistry).For(sourceActor, "P2.5StolenSecond").CancelTarget(character)
 end
 Time.ClearDeceleration(character)
 require(BossSystem.Combat.HealthPenaltyService).Cleanse(player, character)
 clearRecord(player)
 record = ensure(character)
 record.p3Effects = buffs
 record.cupBleedUntil = nil
 publish(record, "CardStunnedUntil", 0)
 publish(record, "CupPenaltyUntil", 0)
 publish(record, "CupPenaltyDebuffs", nil)
 character:SetAttribute("ProjectileDarknessToken", nil)
 setP3Effect(character, "Cleanse", 3)
 refresh(record)
 return true
end

function Service.Clear(player)
	clearRecord(player)
end

function Service.Start(damageCallback)
	if damageCallback then
		damage = damageCallback
	end
	if started then
		return
	end
	started = true
	Players.PlayerRemoving:Connect(function(player)
		clearRecord(player)
	end)
	local function joined(player)
		player.CharacterRemoving:Connect(function(character)
			local record = records[player]
			if record and record.character == character then
				clearRecord(player, record)
			end
		end)
		 
		setAttribute(player, "SlowUntil", 0)
		setAttribute(player, "BleedUntil", 0)
		setAttribute(player, "GoldenBurnActive", false)
		setAttribute(player, "AbilitiesLocked", false)
		setAttribute(player, "JumpDisabled", false)
		setAttribute(player, "GoldenMarkStacks", 0)
		setAttribute(player, "GoldenMarkUntil", 0)
	end
	Players.PlayerAdded:Connect(joined)
	for _, player in ipairs(Players:GetPlayers()) do
		joined(player)
	end
	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < 0.1 then
			return
		end
		elapsed = 0
		for record in pairs(active) do
			if not isCurrent(record) then
				clearRecord(record.player, record)
				continue
			end
			local now = Time.ActionNow(record.character)
			refreshP3(record, now)
			tickAdvancedDebuffs(record, now)
   tickAstralBurn(record,now)
			if records[record.player] ~= record then continue end
			for _, name in ipairs(TICKED_EFFECTS) do
				local entry = record.p3Effects[name]
				if entry and Time.Rate(record.character) > 0 and now + 0.001 >= entry.nextTick then
					entry.nextTick = now + (name=="Poison" and (EncounterConfig.PoisonTickInterval or .5) or 1)
					if name=="Poison" and damage then
      damage(record.character,EncounterConfig.PoisonDamage or 5,entry.source,nil,{Skill="Poison",IsStatusDamage=true})
     elseif name == "CardBurn" and damage then
						damage(
							record.character,
							EncounterConfig.P3CardsBurnDamage or 2,
							entry.source,nil,{Skill="CardBurn",IsStatusDamage=true}
						)
					elseif name == "CupRegenBoost" and not Service.IsRegenBlocked(record.character, "HP") then
						record.humanoid.Health = math.min(
							record.humanoid.MaxHealth,
							record.humanoid.Health
								+ record.humanoid.MaxHealth
									* (EncounterConfig.PickThePupilsRewardHealFraction or 0.02)
						)
					end
					if records[record.player] ~= record then
						break
					end
				end
			end
			if records[record.player] ~= record then
				continue
			end
   if record.cupBleedUntil then
    record.bleedUntil = now + math.max(0, record.cupBleedUntil - workspace:GetServerTimeNow())
    if now >= record.bleedUntil then record.cupBleedUntil = nil end
   end
			 
			if
				Time.Rate(record.character) > 0
				and record.bleedUntil > 0
				and record.nextBleed <= math.min(now, record.bleedUntil) + 0.001
			then
				record.nextBleed += 1
				if record.nextBleed <= now then
					record.nextBleed = now + 1
				end
				if damage then
					damage(record.character, record.humanoid.MaxHealth * 0.01, record.bleedSource,nil,{Skill="Bleed",IsStatusDamage=true})
				end
				if records[record.player] ~= record then
					continue
				end
			end
			if record.bleedUntil > 0 and now >= record.bleedUntil then
				record.bleedUntil = 0
				record.bleedSource = nil
				publish(record, "BleedUntil", 0)
			end
			if record.bleedUntil > 0 then
    if record.cupBleedUntil then publish(record, "BleedUntil", record.cupBleedUntil)
    else publishDeadline(record, "BleedUntil", record.bleedUntil) end
			end
			if Time.Rate(record.character) > 0 and refreshBurn(record) and now + 0.001 >= record.nextBurn then
				record.nextBurn = now + 0.5
				local timed=record.p3Effects.GoldenBurn
    local source=timed and timed.source
				for _, zone in pairs(record.burnZones) do
					if zone.Source then
						source = zone.Source
						break
					end
				end
				if damage then
					damage(
						record.character,
						2,
						source,nil,{Skill="GoldenBurn",IsStatusDamage=true}
					)
				end
				if records[record.player] ~= record then
					continue
				end
			end
			refreshMark(record, now)
			refresh(record)
			if record.pendingClear and not record.jumpSnapshot and not record.movementSnapshot then
				clearRecord(record.player, record)
				continue
			end
			if
				next(record.namedDebuffs.Electricified or {}) == nil
				and next(record.namedDebuffs.Flung or {}) == nil
				and next(record.p3Effects or {}) == nil
				and next(record.timedSlows) == nil
				and next(record.zoneSlows) == nil
				and next(record.burnZones) == nil
				and record.bleedUntil == 0
				and record.goldenMarkStacks == 0
				and not hasJumpLocks(record)
				and not record.jumpSnapshot
				and not record.movementSnapshot
				and not hasLocks(record)
				and not hasMovementLocks(record)
			then
				active[record] = nil
			end
		end
	end)
end


 
 
 
 
 
do
	local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
	local depth = 0
	local function scaled(name, index, knob, graceIndex)
		local raw = Service[name]
		if type(raw) ~= "function" then
			return
		end
		Service[name] = function(...)
			if depth > 0 then
				return raw(...)
			end
			local args = table.pack(...)
			local profile = Difficulty.Get()
			local factor = knob == "Control" and (profile.Mercy.Control or 1) or (profile[knob] or 1)
			if type(args[index]) == "number" then
				args[index] *= factor
			end
			if graceIndex then
				args[graceIndex] = (type(args[graceIndex]) == "number" and args[graceIndex] or 0.9) * (profile.Mercy.Grace or 1)
				args.n = math.max(args.n, graceIndex)
			end
			depth += 1
			local results = table.pack(pcall(raw, table.unpack(args, 1, args.n)))
			depth -= 1
			if not results[1] then
				error(results[2], 0)
			end
			return table.unpack(results, 2, results.n)
		end
	end
	 
	scaled("Restrain", 3, "Control")
	scaled("ApplyStun", 3, "Control", 4)
	 
	scaled("ApplySlow", 3, "DebuffDuration")
	scaled("ApplyBleed", 2, "DebuffDuration")
	scaled("ApplyAdvancedDebuff", 3, "DebuffDuration")
	scaled("ApplyFear", 2, "DebuffDuration")
	scaled("ApplyPoison", 2, "DebuffDuration")
	scaled("ApplyGoldenBurn", 2, "DebuffDuration")
	scaled("ApplyCardDebuff", 3, "DebuffDuration")
	scaled("ApplyProjectileDarkness", 2, "DebuffDuration")
end
return Service
