local BossSystem = script:FindFirstAncestor("BossSystem")
local Difficulty = require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local api = {}
local Aim = require(BossSystem.Combat.AttackTargetContinuity)
local requiresCharacter = {
 P1BlockGrab=true, P1GoldenParry=true, ["P1GildedCataclysm(Ultimate)"]=true,
 P2Save=true, P2Load=true, P2Acceleration=true, P2Deceleration=true,
 ["P2.5StolenSecond"]=true, ["P1.5GoldenChain"]=true,
 P3Dash=true, P3Thief=true, P3ControlDistortion=true, P3Illusion=true, P3Clone=true,
 P3PlayerClone=true, ["P3PickThePupils(Ultimate)"]=true, P1ChainedCombo=true,
 ["P3.5IllusionBomb"]=true, ["P3.5MysteriousGuy(Ultimate)"]=true,
 ["P5Hyper-lasticBeam(Ultimate)"]=true, ["P5Finality(Ultimate)"]=true, P5BlackHole=true,
}

local Metadata = require(BossSystem.Combat.AbilityMetadata)
local function allowedForActor(name, metadata, actor)
 local phase = actor:GetAttribute("Phase") or 1
 -- phase 5 runs its own kit plus the P4 moves AbilityMetadata explicitly allows there (fillers)
 if phase == 5 and metadata and metadata.NativePhase >= 4 and metadata.NativePhase < 5 and not Metadata.Available(name, 5) then return false end
 return Difficulty.Allowed(name, metadata, actor)
end
local Weapons = require(BossSystem.Boss.WeaponController)
local factories = {}
local actors = setmetatable({}, { __mode = "k" })
function api.Module(name)
	local key = Metadata.ModuleFolder(name)
	if not key then
		return nil
	end
	local folder
	if key == "Passives" then
		folder = BossSystem:FindFirstChild("Passives")
	else
		local attacks = BossSystem:FindFirstChild("Attacks")
		folder = attacks
		for segment in key:gmatch("[^/]+") do
			folder = folder and folder:FindFirstChild(segment)
		end
	end
	local module = folder and folder:FindFirstChild(name)
	return module and module:IsA("ModuleScript") and module or nil
end
function api.For(actor, name)
	assert(actor and actor:IsA("Model"), "Attack requires an actor")
	local record = actors[actor]
	if not record then
		record = {}
		actors[actor] = record
	end
	if record[name] then
		return record[name]
	end
	local factory = factories[name]
	if not factory then
		local module = api.Module(name)
		assert(module, "Missing registered attack module: " .. tostring(name))
		factory = require(module)
		factories[name] = factory
	end
	local lease = Weapons.Acquire(actor)
	local ok, value = xpcall(factory, debug.traceback, actor)
	Weapons.Release(actor, lease)
	if not ok then
		error(value, 2)
	end
	local metadata = Metadata.Get(name)
	if metadata and metadata.SwordBased and value.Combo then
		local combo = value.Combo
		value.Combo = function(...)
			local attackLease = Weapons.Acquire(actor)
			local result = table.pack(xpcall(combo, debug.traceback, ...))
			Weapons.Release(actor, attackLease)
			if not result[1] then
				error(result[2], 2)
			end
			return table.unpack(result, 2, result.n)
		end
	end
	if metadata and metadata.Ultimate and value.Combo then
		value.IsUltimate = true
		if not metadata.TriggerOnly then
			local combo = value.Combo
			value.Combo = function(...)
				if value.CanUse and not value.CanUse(...) then return false end
				local ultimates = require(BossSystem.Combat.UltimateService)
				local handle = ultimates.Begin(actor, name)
				if not handle then return false end
				local result = table.pack(xpcall(combo, debug.traceback, ...))
				ultimates.Finish(handle)
				if not result[1] then error(result[2], 2) end
				return table.unpack(result, 2, result.n)
			end
		end
	end

 if requiresCharacter[name] then
  local canUse, combo = value.CanUse, value.Combo
  value.CanUse = function(target, ...)
   target = Aim.Character(target)
   local h = target and target:FindFirstChildOfClass("Humanoid")
   return h and h.Health > 0 and (not canUse or canUse(target, ...)) or false
  end
  if combo then
   value.Combo = function(target, ...)
    target = Aim.Character(target)
    local h = target and target:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then return false end
    return combo(target, ...)
   end
  end
 elseif value.Combo then
  local combo = value.Combo
  value.Combo = function(target, ...) return combo(Aim.For(target), ...) end
 end
 if metadata and not metadata.Passive and not metadata.Ultimate and not metadata.TimeStopOnly then
  local canUse,combo=value.CanUse,value.Combo
  local function targetFor(target)
   return require(BossSystem.Combat.TauntService).Target(actor) or target
  end
  if canUse then value.CanUse=function(target,...)return canUse(targetFor(target),...)end end
  if combo then value.Combo=function(target,...)return combo(targetFor(target),...)end end
 end
  
 if metadata and metadata.Passive then
  for _, method in ipairs({"Tick","Apply","Spawn","SpawnPersistent","Record","Try","TryEmission","Activate"}) do
   local action = value[method]
   if type(action) == "function" then
    value[method] = function(...)
     if not allowedForActor(name, metadata, actor) then return false end
     return action(...)
    end
   end
  end
 end
 if metadata then
  local canUse, combo = value.CanUse, value.Combo
  value.CanUse = function(...)
   return allowedForActor(name, metadata, actor) and (not canUse or canUse(...))
  end
  if combo then
   value.Combo = function(...)
    if not allowedForActor(name, metadata, actor) then return false end
    return combo(...)
   end
  end
 end
 record[name] = value
	return value
end
function api.Release(actor)
	local record = actors[actor]
	actors[actor] = nil
	if record then
		for _, value in pairs(record) do
			if value.Dispose then
				local ok, err = xpcall(value.Dispose, debug.traceback)
				if not ok then
					warn("Actor cleanup: " .. tostring(err))
				end
			end
		end
	end
	Weapons.Clear(actor)
end
return api
