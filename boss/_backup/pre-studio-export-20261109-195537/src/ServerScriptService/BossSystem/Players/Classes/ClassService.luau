 
 
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local BossSystem = script:FindFirstAncestor("BossSystem")
local ClassConfig = require(game.ReplicatedStorage.BossShared.Classes.ClassConfig)
local FX = require(script.Parent.ClassFX)
local Runtime=require(BossSystem.Combat.CombatRuntime)
local Time=require(BossSystem.Mechanics.Time.TimeEffectController)
local HitRules=require(BossSystem.Combat.PlayerHitRules)
local BattleScaling=require(game.ReplicatedStorage.BossShared.Config.BattleScaling)

local S = { Config = ClassConfig, FX = FX }
local states = setmetatable({}, { __mode = "k" })  
local stuns = setmetatable({}, { __mode = "k" })
local cooldownKeys = { "M1", "F", "C", "V", "R" }
local remote
local Kits = {}

local function now()
  return workspace:GetServerTimeNow()
end
local function setAttributeIfChanged(instance, key, value)
  if instance:GetAttribute(key) ~= value then
    instance:SetAttribute(key, value)
  end
end
S.Now = now
local function encounter()
  return require(BossSystem.Players.PlayerEncounter)
end

function S.State(char)
  return char and states[char]
end
function S.ClassOf(player)
  local id = player:GetAttribute("PlayerClass")
  return ClassConfig.Classes[id] and id or ClassConfig.Default
end
function S.Alive(char)
  local h = char and char:FindFirstChildOfClass("Humanoid")
  return h and h.Health > 0 and char:FindFirstChild("HumanoidRootPart") and char.Parent ~= nil
end

local EnemyTargets=require(game.ReplicatedStorage.BossShared.Classes.EnemyTargetRules)
 
function S.Boss()
  local boss = workspace:FindFirstChild("alterGolden, the Nothing")
  if boss and S.Alive(boss) then
    return boss
  end
end
 
local targetCache, targetCachedAt = {}, 0
function S.Targets()
  if os.clock() - targetCachedAt < 0.2 then
    local alive = {}
    for _, m in ipairs(targetCache) do
      if EnemyTargets.Available(m) then
        table.insert(alive, m)
      end
    end
    return alive
  end
  targetCachedAt = os.clock()
  local list = {}
  local boss = S.Boss()
  if boss and EnemyTargets.Available(boss) then
    table.insert(list, boss)
  end
  for _,m in Runtime.Targets() do
    if m~=boss and EnemyTargets.Available(m) then
      table.insert(list, m)
    end
  end
  targetCache = list
  return list
end
function S.AimTarget(char,aim,range)
 if not S.Alive(char) then return nil end
 local origin=char.HumanoidRootPart.Position
 local best,bestScore
 for _,target in ipairs(S.Targets()) do
  local position=target.HumanoidRootPart.Position
  if (position-origin).Magnitude<=(range or 240) then
   local score=typeof(aim)=="Vector3" and (position-aim).Magnitude or (position-origin).Magnitude
   if not bestScore or score<bestScore then best,bestScore=target,score end
  end
 end
 return best
end
 
function S.TargetNear(pos, radius)
  local best, bestD
  for _, m in ipairs(S.Targets()) do
     
    local delta = m.HumanoidRootPart.Position - pos
    local d = Vector3.new(delta.X, 0, delta.Z).Magnitude
    if d <= radius + 2.5 and math.abs(delta.Y) <= 9 and (not bestD or d < bestD) then
      best, bestD = m, d
    end
  end
  return best, bestD
end
local hitSerial = 0
local MELEE = {
 WarriorM1 = true, WarriorSlam = true, WarriorConclusion = true,
 TankSlam = true, TankRampage = true, DuelistM1 = true, DuelistRiposte = true,
 DuelistFlash = true, DuelistCross = true, DuelistPhase = true, DuelistPhaseSlash = true, DuelistWaltz = true, DuelistWaltzOpener = true,
}
function S.TimeStopped(char)
 return Time.IsStopped() or workspace:GetAttribute("GoldenTimeStopped")==true
  or char and char:GetAttribute("TimeFrozen")==true
end
function S.IsDefending(char)
 local st=states[char]
 return st~=nil and st.Data.DefenderHeld==true
end
function S.HoldingKey(char)
 local st=states[char] if not st then return nil end
 if st.Data.CHeld or st.Data.CHeldAt or st.Data.CloneCharge then return "C" end
 if st.Data.Lasering then return "V" end
 if S.IsDefending(char) or S.HasBuff(char,"Rolling") then return "F" end
 if S.HasBuff(char,"Rampage") or S.HasBuff(char,"ShieldRaised") then return "C" end
 if S.HasBuff(char,"ParryStance") then return "V" end
 return st.Busy and "V" or nil
end
function S.CanBlock(char)
 return S.CanAct(char) and not S.HoldingKey(char)
  and now()>=(char:GetAttribute("BlockBrokenUntil") or 0) and S.Ready(char,"R")
end
function S.CanAct(char)
 local player = char and Players:GetPlayerFromCharacter(char)
 return player and player.Character == char and S.Alive(char)
  and workspace:GetAttribute("BossEncounterWon")~=true
  and not player:GetAttribute("ViewAsServer") and not encounter().IsDefeated(player)
  and not player:GetAttribute("ExecutionPending") and not player:GetAttribute("PermanentlyDefeated")
  and not S.TimeStopped(char)
  and not char:GetAttribute("ParryFrozen") and not char:GetAttribute("TimeFrozen")
  and not char:GetAttribute("MovementLocked") and not char:GetAttribute("AbilitiesLocked")
  and not char:GetAttribute("PickThePupilsCaptured")
  and not char.HumanoidRootPart.Anchored
  and not require(BossSystem.Combat.StatusEffectService).IsLocked(player)
  and not require(BossSystem.Combat.StatusEffectService).IsMovementLocked(player)
  and now() >= math.max(player:GetAttribute("AbilitiesSealedUntil") or 0, char:GetAttribute("AbilitiesSealedUntil") or 0)
end
function S.NewAttack(char, tag, options)
 options = options or {}
 local st = states[char]
 if not st or not S.CanAct(char) then return nil end
 hitSerial += 1
 local token = {
  Direct = true, Kind = "PlayerClass", Attacker = char, Class = st.Class,
  Skill = tag, Sequence = hitSerial, Melee = MELEE[tag] == true,
  State = st, Revision = st.ActionRevision or 0, Source = options.Source or char,
 }
 char:SetAttribute("ClassAttackStartedAt", now())
 char:SetAttribute("ClassAttackSequence", hitSerial)
 if token.Melee then
  char:SetAttribute("SwordSwingStartedAt", now())
  char:SetAttribute("SwordSwingSequence", (char:GetAttribute("SwordSwingSequence") or 0) + 1)
 end
 return token
end
function S.AttackExists(char,token)
 return token~=nil and token.Attacker==char and states[char]==token.State
  and token.Revision==(token.State.ActionRevision or 0)
  and S.Alive(char) and S.Alive(token.Source)
end
function S.AttackValid(char,token)
 return S.AttackExists(char,token) and S.CanAct(char)
end
function S.CancelActions(char)
 local st = states[char]
 local reason=S.TimeStopped(char) and "Time" or "Control"
 if not st then return end
 if st.ControlBlocked and st.ControlReason==reason and not S.IsDefending(char) then return end
 st.ControlBlocked=true st.ControlReason=reason
 local kit=Kits[st.Class]
 if kit and kit.CancelActions then kit.CancelActions(S,char,st,reason) end
 if reason~="Time" then
  st.ActionRevision=(st.ActionRevision or 0)+1
  char:SetAttribute("ClassActionRevision",st.ActionRevision)
 end
 S.StopDefender(char)
 char:SetAttribute("ClassHoldingSkill",nil)
 st.Data.CHeld, st.Data.CHeldAt = false, nil
 st.Data.Lasering = false
 char:SetAttribute("MageLasering", nil)
 char:SetAttribute("ClassAimStream", nil)
 char:SetAttribute("TauntingUntil", nil)
 st.Busy=false
 for _,id in {"Blocking", "Riposte", "ParryStance", "Rampage", "Phasing", "PhaseCharge", "WaltzCharge", "PhasingReady"} do
  if S.HasBuff(char,id) then S.Unbuff(char,id) end
 end
 if remote then
  remote:FireClient(st.Player,"MoveStop")
  remote:FireClient(st.Player,"LaserEnd")
  remote:FireClient(st.Player,"Cinema",{Mode="End"})
 end
end
function S.ClearSight(char,target,token)
 local state=states[char]
 if not state or not token or not S.Alive(token.Source) then return false end
 local params=state.SightParams
 if not params then params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude params.RespectCanCollide=true state.SightParams=params end
 if state.SightTarget~=target or state.SightSource~=token.Source then
  local ignored={char,target,token.Source,Runtime.Effects,Runtime.Summons}
  local fx=workspace:FindFirstChild("ClassEffects")
  if fx then table.insert(ignored,fx) end
  local aim=workspace:FindFirstChild("BossAttackAimTargets")
  if aim then table.insert(ignored,aim) end
  params.FilterDescendantsInstances=ignored
  state.SightTarget,state.SightSource=target,token.Source
 end
 local origin=token.Origin or token.Source.HumanoidRootPart.Position
 return not workspace:Raycast(origin,target.HumanoidRootPart.Position-origin,params)
end
function S.ResolveBossDefense(char, target, token)
 if not S.AttackValid(char,token) or not EnemyTargets.Available(target)
  or target:GetAttribute("EncounterEnded") or target:GetAttribute("PhaseTransitionInProgress")
  or target:GetAttribute("Invulnerable") or target:GetAttribute("ShieldDamageLocked")
  or target:GetAttribute("LinkedProtection") or not S.ClearSight(char,target,token) then return false end
 local registry = require(BossSystem.Combat.AttackRegistry)
 if target:GetAttribute("ParryActive") and registry.For(target,"P1GoldenParry").TryCounter(char,token) then
  return false
 end
 if require(BossSystem.Phases.Phase25Controller).TryEvade(target,char,token) then return false end
 return true
end
function S.HitBoss(char,target,damage,tag,token)
 if type(damage)~="number" or damage~=damage or damage<=0 or damage==math.huge then return false end
 token = token or S.NewAttack(char,tag or "Class")
 if not S.ResolveBossDefense(char,target,token) then return false end
 local beforeHealth = target.Humanoid.Health
 local beforeShield = target:GetAttribute("Shield") or 0
 local ok, accepted = pcall(function()
  return require(BossSystem.Combat.AttackRegistry).For(target,"BossDamageService").ApplyDamage(damage*ClassConfig.DamageMultiplier*BattleScaling.DamageMultiplier(),char,token)
 end)
 local dealt = ok and accepted and (
  math.max(0,beforeHealth-target.Humanoid.Health)
  + math.max(0,beforeShield-(target:GetAttribute("Shield") or 0))) or 0
 if dealt > 0 then
    local st = states[char]
    if st and Kits[st.Class] and Kits[st.Class].OnHitBoss then
      pcall(Kits[st.Class].OnHitBoss, S, char, st, target, tag, dealt)
    end
  end
  return dealt > 0
end
function S.Allies(includeSelf, selfChar)
  local list = {}
  for _, p in ipairs(Players:GetPlayers()) do
    local c = p.Character
    if S.Alive(c) and not p:GetAttribute("ViewAsServer") and not encounter().IsDefeated(p)
   and (includeSelf or c~=selfChar) then
      table.insert(list, c)
    end
  end
  return list
end
 
function S.AimedAlly(char, aim, range)
  local best, bestD
  for _, c in ipairs(S.Allies(false, char)) do
    if (c.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude <= range then
      local d = aim and (c.HumanoidRootPart.Position - aim).Magnitude or 0
      if not bestD or d < bestD then
        best, bestD = c, d
      end
    end
  end
  return best
end
local function holdStun(target,seconds)
 local root=target:FindFirstChild("HumanoidRootPart")
 if not root then return false end
 local previous=stuns[target]
 if previous and previous.GenerationConnection then previous.GenerationConnection:Disconnect() end
 local wasAnchored=previous and previous.WasAnchored or root.Anchored
 if previous then wasAnchored=previous.WasAnchored end
 target:SetAttribute("MovementRevision",(target:GetAttribute("MovementRevision") or 0)+1)
 require(BossSystem.Combat.EffectService).CancelEmitter(target,"Class stun",function(cast)return cast.name~="ShieldGateMovement" and not cast.PersistsThroughEmitterStun end)
 target:SetAttribute("AttackInProgress",false)
 target:SetAttribute("AttackState","Stunned")
 local untilAt=math.max(now()+seconds,target:GetAttribute("ClassStunnedUntil") or 0)
 local lease={WasAnchored=wasAnchored,Generation=target:GetAttribute("PhaseGeneration") or 0,
  Revision=target:GetAttribute("MovementRevision") or 0,Frame=root.CFrame}
 stuns[target]=lease
 target:SetAttribute("ClassStunnedUntil",untilAt)
 target:SetAttribute("ClassStunFrame",lease.Frame)
 target:SetAttribute("NextAttackAt",math.max(target:GetAttribute("NextAttackAt") or 0,untilAt))
 Time.SetAnchored(root,true)
 FX.StatusOn(target,"Stunned")
 local function finish()
  if stuns[target]~=lease then return end
  stuns[target]=nil
  if lease.GenerationConnection then lease.GenerationConnection:Disconnect() end
  if not target.Parent then return end
  target:SetAttribute("ClassStunFrame",nil)
  target:SetAttribute("ClassStunnedUntil",0)
  FX.StatusOff(target,"Stunned")
  if (target:GetAttribute("PhaseGeneration") or 0)~=lease.Generation
   or (target:GetAttribute("MovementRevision") or 0)~=lease.Revision
   or target:GetAttribute("PhaseTransitionInProgress") then return end
  if root.Parent then Time.SetAnchored(root,wasAnchored) end
  if target:GetAttribute("AttackState")=="Stunned" then target:SetAttribute("AttackState","Idle") end
 end
 lease.GenerationConnection=target:GetAttributeChangedSignal("PhaseGeneration"):Connect(finish)
 task.delay(math.max(0,untilAt-now()),finish)
 return true
end
function S.Stun(target,seconds,char,token)
 if not char or not S.ResolveBossDefense(char,target,token) then return false end
 local skill=tostring(target:GetAttribute("CurrentSkill") or "")
 if target:GetAttribute("PhaseTransitionInProgress") or target:GetAttribute("EncounterEnded") or skill:find("(Ultimate)",1,true) then return false end
 if not holdStun(target,seconds) then return false end
 if not target:GetAttribute("IsGoldenClone") then
  for _,copy in Runtime.AllTargets() do
   local owner=copy:FindFirstChild("EncounterOwner")
   if copy~=target and copy:GetAttribute("IsGoldenClone") and owner and owner.Value==target and S.Alive(copy) then holdStun(copy,seconds) end
  end
 end
 return true
end

 
local function cooldownAttribute(char,key)
 return "ClassCD_"..(char:GetAttribute("ClassId") or ClassConfig.Default).."_"..key
end
function S.UpdateCooldowns(char)
 local st=states[char] if not st then return end
 local t,clock=now(),Time.CooldownNow(char)
 local player=Players:GetPlayerFromCharacter(char)
 st.CooldownMarks=st.CooldownMarks or {}
 for _,key in ipairs(cooldownKeys) do
  local attribute=cooldownAttribute(char,key)
  local deadline=math.max(char:GetAttribute("ClassCD_"..key) or 0,player and player:GetAttribute(attribute) or 0)
  local mark=st.CooldownMarks[key]
  if mark and deadline>mark.Real then
   local realElapsed=math.max(0,t-mark.Real)
   local recovered=math.max(0,clock-mark.Clock)
   local lost=math.max(0,realElapsed-recovered)
   if lost>.0001 then
    deadline+=lost
    char:SetAttribute("ClassCD_"..key,deadline)
    if player then player:SetAttribute(attribute,deadline) end
   end
  end
  if mark then
   mark.Real=t
   mark.Clock=clock
  else
   st.CooldownMarks[key]={Real=t,Clock=clock}
  end
 end
end
function S.Ready(char,key)
 S.UpdateCooldowns(char)
 local player=Players:GetPlayerFromCharacter(char)
 local deadline=math.max(char:GetAttribute("ClassCD_"..key) or 0,
  player and player:GetAttribute(cooldownAttribute(char,key)) or 0)
 return now()>=deadline
end
function S.Cooldown(char,key,seconds)
 S.UpdateCooldowns(char)
 if key=="M1" then seconds/=S.AttackSpeedMultiplier(char) end
 local deadline=now()+seconds
 local player=Players:GetPlayerFromCharacter(char)
 if player then
  local attribute=cooldownAttribute(char,key)
  player:SetAttribute(attribute,deadline)
  player:SetAttribute(attribute.."Length",seconds)
 end
 char:SetAttribute("ClassCD_"..key,deadline)
 char:SetAttribute("ClassCDLen_"..key,seconds)
 local st=states[char] if st then st.CooldownMarks=st.CooldownMarks or {} st.CooldownMarks[key]={Real=now(),Clock=Time.CooldownNow(char)} end
end
function S.ResetCooldowns(char)
 local player=Players:GetPlayerFromCharacter(char)
 for _,key in ipairs(cooldownKeys) do
  if player then player:SetAttribute(cooldownAttribute(char,key),0) end
  char:SetAttribute("ClassCD_"..key,0)
 end
end
 
function S.Sound(char, cue)
  pcall(function()
    local Audio = require(BossSystem.Presentation.CombatAudio)
    Audio.Emit(char, cue, char:FindFirstChild("HumanoidRootPart"))
  end)
end
 
function S.Anim(char, name)
  char:SetAttribute("ClassAnim", name .. "|" .. string.format("%.3f", now()))
end
function S.SpendStamina(char, cost)
  local st = char:GetAttribute("Stamina") or 0
  if st < cost then
    return false
  end
  char:SetAttribute("Stamina", st - cost)
  return true
end

 
 
function S.Buff(char, id, duration, mods)
  local st = states[char]
  if not st then
    return
  end
  local old=st.Buffs[id]
 local deadline=duration and now()+duration or math.huge
 if old then old.Until=deadline old.Mods=mods or old.Mods
 else st.Buffs[id]={Until=deadline,Mods=mods or {}} FX.StatusOn(char,id) end
 local shown=duration and deadline or -1
 local previous=char:GetAttribute("ClassStatus_"..id)
 if previous==nil or shown==-1 and previous~=-1 or shown~=-1 and math.abs(shown-previous)>=0.25 then
  char:SetAttribute("ClassStatus_"..id,shown)
 end
end
local function defenseCap(st)
 if st.Class=="Tank" then return ClassConfig.Classes.Tank.DefenseCap end
 if st.Class=="Mage" and st.StatSources.OrbWard then return ClassConfig.Classes.Mage.F.DefenseCap end
 return ClassConfig.DefenseCap
end
local function defenseRoom(st,exclude)
 local defense=st.Def.BaseDefense or 0
 for id,buff in pairs(st.Buffs) do if id~=exclude then defense+=buff.Mods.Defense or 0 end end
 return math.max(0,defenseCap(st)-defense)
end
local statEffects={
 {Field="Attack",Id="DamageBoost",Positive=true},{Field="Attack",Id="AttackDebuff",Positive=false},
 {Field="Defense",Id="DefenseBoost",Positive=true},
 {Field="Speed",Id="SpeedBoost",Positive=true},{Field="Speed",Id="Slow",Positive=false},
 {Field="StaminaRegen",Id="StaminaRegen",Positive=true},{Field="StaminaRegen",Id="StaminaRegenBlock",Positive=false},
 {Field="HealthRegen",Id="HPRegen",Positive=true},{Field="AttackSpeed",Id="AttackSpeedBoost",Positive=true},
}
function S.StatBuff(char,source,duration,mods)
 local st=states[char] if not st then return end
 st.StatSources[source]={Until=duration and now()+duration or math.huge,Mods=mods}
 S.RefreshStatBuffs(char)
end
function S.RefreshStatBuffs(char)
 local st=states[char] if not st then return end
 local t=now()
 for source,b in pairs(st.StatSources) do if t>=b.Until then st.StatSources[source]=nil end end
 for _,effect in ipairs(statEffects) do
  local field,id=effect.Field,effect.Id
  local value,deadline=nil,0
  for _,b in pairs(st.StatSources) do
   local modifier=b.Mods[field]
   if modifier and (field=="Defense" or effect.Positive and modifier>=1 or not effect.Positive and modifier<1) then
    value=field=="Defense" and (value or 0)+modifier or (value or 1)*modifier
    deadline=math.max(deadline,b.Until)
   end
  end
  if value and not (field=="Defense" and value<=0) then
   if st.Class=="Tank" and field=="Defense" then value=math.clamp(value,0,defenseRoom(st,id)) end
   local duration=deadline~=math.huge and math.max(0,deadline-t) or nil
   S.Buff(char,id,duration,{[field]=value})
   if char:GetAttribute("ClassStatusModifier_"..id)~=value then char:SetAttribute("ClassStatusModifier_"..id,value) end
   if char:GetAttribute("ClassStatusText_"..id)~=nil then char:SetAttribute("ClassStatusText_"..id,nil) end
  else
   if st.Buffs[id] then S.Unbuff(char,id) end
   char:SetAttribute("ClassStatusModifier_"..id,nil)
   char:SetAttribute("ClassStatusText_"..id,nil)
  end
 end
end
function S.RemoveStatBuff(char,source)
 local st=states[char] if not st then return end
 st.StatSources[source]=nil
 S.RefreshStatBuffs(char)
end
function S.StopDefender(char)
 local st=states[char] if not st then return false end
 local active=st.Data.DefenderHeld==true
 st.Data.DefenderHeld=false st.Data.DefenderLeaseUntil=nil
 char:SetAttribute("TankDefenderHeld",nil)
 char:SetAttribute("TauntingUntil",nil)
 if active then
  S.Cooldown(char,"F",ClassConfig.Classes.Tank.F.Cooldown)
  S.RemoveStatBuff(char,"Defender")
  S.Unbuff(char,"Taunt")
  char:SetAttribute("ClassHoldingSkill",nil)
  local speed=st.Def.Speed
  for _,buff in pairs(st.Buffs) do speed*=buff.Mods.Speed or 1 end
  char:SetAttribute("BaseWalkSpeed",speed)
  require(BossSystem.Combat.StatusEffectService).RefreshMovement(char)
 end
 return active
end
function S.Unbuff(char, id)
  local st = states[char]
  if id=="Blocking" and st and st.Buffs[id] then S.Cooldown(char,"R",ClassConfig.Block.Cooldown) end
  if id=="Taunt" and S.IsDefending(char) then S.StopDefender(char) return end
  if st and st.Buffs[id] then
    st.Buffs[id] = nil
  end
  char:SetAttribute("ClassStatus_" .. id, nil)
  FX.StatusOff(char, id)
end
function S.HasBuff(char, id)
  local st = states[char]
  return st and st.Buffs[id] ~= nil
end
local function product(st, field)
  local v = 1
  for _, b in pairs(st.Buffs) do
    if b.Mods[field] then
      v *= b.Mods[field]
    end
  end
  return v
end
function S.Defense(char)
  local st = states[char]
  if not st then
    return 0
  end
  local def = st.Def.BaseDefense or 0
  for _, b in pairs(st.Buffs) do
    def += b.Mods.Defense or 0
  end
  return math.clamp(def,0,defenseCap(st))
end
function S.AttackSpeedMultiplier(char)
 local st=states[char]return st and product(st,"AttackSpeed") or 1
end
function S.AttackMultiplier(char)
  local st = states[char]
  return st and product(st, "Attack") or 1
end

 


 
function S.Apply(player, char)
  while char and char:GetAttribute("R6AppearanceBusy") and player.Character==char and char.Parent do task.wait(.05) end
  if not char or not char.Parent or player.Parent~=Players or player.Character~=char
  or encounter().IsDefeated(player) then return end
  local id = S.ClassOf(player)
  local def = ClassConfig.Get(id)
  local h = char:FindFirstChildOfClass("Humanoid")
  if not h or h.Health<=0 then return end
 local old = states[char]
 if old then
  S.CancelActions(char)
  if old.DiedConnection then old.DiedConnection:Disconnect() end
 end
  if old and Kits[old.Class] and Kits[old.Class].Cleanup then
    pcall(Kits[old.Class].Cleanup, S, char, old)
  end
  if old then
    for bid in pairs(old.Buffs) do
      S.Unbuff(char, bid)
    end
  end
  local gear = char:FindFirstChild("ClassGear")
  if gear then
    gear:Destroy()
  end
  for _, place in ipairs({ char, player:FindFirstChildOfClass("Backpack") }) do
    if place then
      for _, t in ipairs(place:GetChildren()) do
        if t:IsA("Tool") then
          t:Destroy()
        end
      end
    end
  end
  local st = { Class=id, Def=def, Buffs={}, StatSources={}, Player=player, LastDamaged=0, Data={},
  ActionRevision=(char:GetAttribute("ClassActionRevision") or 0)+1 }
 char:SetAttribute("ClassActionRevision",st.ActionRevision)
  states[char] = st
  char:SetAttribute("ClassId",id)
 char:SetAttribute("UseAvatarAppearance",player:GetAttribute("UseAvatarAppearance")==true)
 char:SetAttribute("ClassLifeToken",game:GetService("HttpService"):GenerateGUID(false))
  char:SetAttribute("ClassDashCost", def.DashCost)
  char:SetAttribute("ClassDashImmunity", ClassConfig.DashImmunity)
  char:SetAttribute("MaxStamina", def.Stamina)
  char:SetAttribute("Stamina", def.Stamina)
  char:SetAttribute("BaseWalkSpeed", def.Speed)
  char:SetAttribute("ClassShieldHP", 0)
  local maxHealth = ClassConfig.GetMaxHealth(id)
  h.MaxHealth = maxHealth
  h.Health = maxHealth
  h.WalkSpeed = def.Speed
  for _,key in ipairs(cooldownKeys) do
   local attribute=cooldownAttribute(char,key)
   char:SetAttribute("ClassCD_"..key,player:GetAttribute(attribute) or 0)
   char:SetAttribute("ClassCDLen_"..key,player:GetAttribute(attribute.."Length") or 0)
  end
  S.UpdateCooldowns(char)
  local kit = Kits[id]
  local okModel, modelErr = pcall(require(script.Parent.ClassModels).Build, char, id)
  if not okModel then
    warn("Class model (" .. id .. "): " .. tostring(modelErr))
  end
  if kit and kit.Start then
    pcall(kit.Start, S, player, char, st)
  end
  st.DiedConnection=h.Died:Connect(function()
  if states[char]~=st then return end
    S.CancelActions(char)
    if kit and kit.Cleanup then
      pcall(kit.Cleanup, S, char, st)
    end
    for bid in pairs(st.Buffs) do
      S.Unbuff(char, bid)
    end
  end)
end

 
 
function S.Incoming(player, char, h, amount, balance)
  local st = states[char]
  if not st or amount <= 0 then
    return amount
  end
  if S.HasBuff(char, "Undying") or S.HasBuff(char, "Phasing") then
     
    if st.Class == "Duelist" and S.HasBuff(char, "Riposte") and not (balance and balance.IsStatusDamage) then
      local kit = Kits[st.Class]
      if kit and kit.Incoming then pcall(kit.Incoming, S, char, st, amount, balance) end
    end
    return 0
  end
  local piercingDot=HitRules.PiercingDot(balance)
  if S.HasBuff(char,"Blocking") and balance and balance.BreaksBlock==true then
   S.Unbuff(char,"Blocking")
   char:SetAttribute("BlockBrokenUntil",now()+ClassConfig.Block.Cooldown)
   S.Buff(char,"GuardBroken",ClassConfig.Block.Cooldown)
   FX.Text(char.HumanoidRootPart.Position+Vector3.new(0,3,0),"GUARD BROKEN",Color3.fromRGB(255,160,80))
  end
  local kit = Kits[st.Class]
  if not piercingDot and kit and kit.Incoming then
    local ok, result = pcall(kit.Incoming, S, char, st, amount, balance)
    if ok and type(result) == "number" then
      amount = result
    end
    if amount <= 0 then
      return 0
    end
  end
  if not piercingDot then amount*=1-S.Defense(char) end
   
  local shield = char:GetAttribute("ClassShieldHP") or 0
  if shield>0 and not piercingDot then
    local soak = math.min(shield, amount)
    shield -= soak
    amount -= soak
    char:SetAttribute("ClassShieldHP", shield)
    if shield <= 0 then
      S.Unbuff(char, "Almighty")
    end
    if amount <= 0 then
      return 0
    end
  end
   
  if amount >= h.Health then
    local saver = char:GetAttribute("FateLinkedBy")
    if saver then
      local ok = S.TriggerFate(char, saver)
      if ok then
        return 0
      end
    end
    if S.HasBuff(char, "SecondWind") then
      S.Unbuff(char, "SecondWind")
      h.Health = h.MaxHealth
      char:SetAttribute("Stamina", char:GetAttribute("MaxStamina") or 100)
      S.ResetCooldowns(char)
      FX.Flash(char.HumanoidRootPart.Position, Color3.fromRGB(180, 255, 220), 14, 0.6)
      FX.Text(char.HumanoidRootPart.Position + Vector3.new(0, 3, 0), "SECOND WIND", Color3.fromRGB(180, 255, 220))
      return 0
    end
  end
  return amount
end
function S.OnDodged(char)
  local st = states[char]
  local kit = st and Kits[st.Class]
  if kit and kit.OnDodged then
    pcall(kit.OnDodged, S, char, st)
  end
end
function S.OnDamaged(char, actual)
  local st = states[char]
  if not st or actual <= 0 then
    return
  end
  st.LastDamaged = os.clock()
  local kit = Kits[st.Class]
  if kit and kit.OnDamaged then
    pcall(kit.OnDamaged, S, char, st, actual)
  end
end
 
function S.ClearFateLink(char)
 char:SetAttribute("FateLinkedBy",nil)
 char:SetAttribute("FateLinkedLifeToken",nil)
 S.Unbuff(char,"FateLinked")
 local link=char:FindFirstChild("FateLinkBeam",true)
 if link then
  local a,b=link.Attachment0,link.Attachment1
  link:Destroy()
  if a then a:Destroy() end
  if b then b:Destroy() end
 end
end
function S.TriggerFate(char, saverName)
  local saverPlayer = Players:FindFirstChild(saverName)
  local saver=saverPlayer and saverPlayer.Character
  local st=saver and states[saver]
  local linkLife=char:GetAttribute("FateLinkedLifeToken")
  local boss=S.Boss()
  local validSaver=saverPlayer and saverPlayer.Character==saver and S.Alive(saver)
   and not encounter().IsDefeated(saverPlayer) and not saverPlayer:GetAttribute("ViewAsServer")
   and st and st.Class=="Supporter" and linkLife==saver:GetAttribute("ClassLifeToken")
   and not (boss and boss:GetAttribute("PickThePupilsActive"))
   and not saver:GetAttribute("PickThePupilsCaptured")
   and not char:GetAttribute("PickThePupilsCaptured")
  S.ClearFateLink(char)
  if not validSaver then return false end
  local h = char:FindFirstChildOfClass("Humanoid")
  if not h then
    return false
  end
  h.Health = 1
  local cfg = ClassConfig.Classes.Supporter.C
  if S.Alive(saver) then
    local a, b = char.HumanoidRootPart.CFrame, saver.HumanoidRootPart.CFrame
    char:PivotTo(b)
    saver:PivotTo(a)
    FX.Beam(a.Position, b.Position, Color3.fromRGB(150, 255, 210), 0.6, 0.5)
  end
  S.Buff(char, "Undying", cfg.Undying, { HealthRegen = 4, StaminaRegen = 2 })
  FX.Flash(char.HumanoidRootPart.Position, Color3.new(1, 1, 1), 12, 0.5)
  FX.Text(char.HumanoidRootPart.Position + Vector3.new(0, 3, 0), "FATE HOLDS", Color3.fromRGB(150, 255, 210))
  return true
end

 
local upkeep=0
local function pruneFateLinks()
 local boss=S.Boss()
 local puzzle=boss and boss:GetAttribute("PickThePupilsActive")
 for _,p in Players:GetPlayers() do
  local char=p.Character
  if char and char:GetAttribute("FateLinkedBy") then
   local owner=Players:FindFirstChild(char:GetAttribute("FateLinkedBy"))
   local saver=owner and owner.Character
   local st=saver and states[saver]
   if puzzle or not S.Alive(saver) or not st or st.Class~="Supporter" or encounter().IsDefeated(owner)
    or char:GetAttribute("FateLinkedLifeToken")~=saver:GetAttribute("ClassLifeToken") then S.ClearFateLink(char) end
  end
 end
end
local function step(dt)
 upkeep+=dt
 if upkeep<0.1 then return end
 dt=upkeep upkeep=0
 pruneFateLinks()
  local t = now()
  for char, st in pairs(states) do
    if not char.Parent then
      states[char] = nil
      continue
    end
    local h = char:FindFirstChildOfClass("Humanoid")
    if not h or h.Health <= 0 then
      continue
    end
  S.UpdateCooldowns(char)
  local canAct=S.CanAct(char)
  if not canAct then S.CancelActions(char) else st.ControlBlocked=false st.ControlReason=nil end
  local holding=S.HoldingKey(char)
  if char:GetAttribute("ClassHoldingSkill")~=holding then char:SetAttribute("ClassHoldingSkill",holding) end
    S.RefreshStatBuffs(char)
    for id, b in pairs(st.Buffs) do
      if t >= b.Until then
        S.Unbuff(char, id)
        local kit = Kits[st.Class]
        if kit and kit.OnBuffEnded then
          pcall(kit.OnBuffEnded, S, char, st, id)
        end
      end
    end
    local kit = Kits[st.Class]
    if canAct and kit and kit.Step then
      local ok, err = pcall(kit.Step, S, st.Player, char, st, dt)
      if not ok then
        warn("Class step (" .. st.Class .. "): " .. tostring(err))
      end
    end
     
    setAttributeIfChanged(char, "BaseWalkSpeed", st.Def.Speed * product(st, "Speed"))
    setAttributeIfChanged(char, "StaminaRegenMultiplier", product(st, "StaminaRegen"))
    setAttributeIfChanged(char, "ClassDefense", S.Defense(char))
    setAttributeIfChanged(char, "ClassAttack", S.AttackMultiplier(char))
  require(BossSystem.Combat.StatusEffectService).RefreshMovement(char)
     
    local r = ClassConfig.HealthRegen
    local fraction = st.Def.HealthRegenFraction
    st.RegenAcc = st.RegenAcc or 0
    if not S.TimeStopped(char) then st.RegenAcc += dt end
    if st.RegenAcc >= r.Interval then
      st.RegenAcc = 0
      if fraction > 0 and not st.Def.NoRegen and not require(BossSystem.Combat.StatusEffectService).IsRegenBlocked(char,"HP")
       and os.clock() - st.LastDamaged >= r.Delay and h.Health < h.MaxHealth then
        h.Health = math.min(h.MaxHealth, h.Health + h.MaxHealth * fraction * r.Interval * product(st, "HealthRegen"))
      end
    end
  end
   
  local boss = S.Boss()
  if boss and t < (boss:GetAttribute("ClassStunnedUntil") or 0) then
    boss.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
  end
end

 
function S.Start()
  if remote then
    return
  end
  remote = game.ReplicatedStorage:FindFirstChild("ClassControl") or Instance.new("RemoteEvent")
  remote.Name = "ClassControl"
  remote.Parent = game.ReplicatedStorage
  for _, id in ipairs(ClassConfig.Order) do
    local m = script.Parent.Kits:FindFirstChild(id)
    if m then
      local ok, kit = pcall(require, m)
      if ok then
        Kits[id] = kit
      else
        warn("Class kit " .. id .. " failed: " .. tostring(kit))
      end
    end
  end
  local function settings(player)
   if player:GetAttribute("ClassAutoAim")==nil then player:SetAttribute("ClassAutoAim",true) end
   if player:GetAttribute("UseAvatarAppearance")==nil then player:SetAttribute("UseAvatarAppearance",false) end
  end
  for _,player in Players:GetPlayers() do settings(player) end
  Players.PlayerAdded:Connect(settings)
  local arena = workspace:FindFirstChild("GoldenGrasslandArena")
  local statue = arena and arena:FindFirstChild("ClassStatue")
  local prompt = statue and statue:FindFirstChild("ClassPrompt", true)
  if prompt then
    prompt.Triggered:Connect(function(player)
      remote:FireClient(player, "Open")
    end)
  end
  remote.OnServerEvent:Connect(function(player, action, a, b, c, d)
    if action=="ToggleAppearance" then
     action,a,b="Setting","UseAvatarAppearance",player:GetAttribute("UseAvatarAppearance")~=true
    end
    if action=="Setting" then
     if (a~="ClassAutoAim" and a~="UseAvatarAppearance") or type(b)~="boolean" then return end
     player:SetAttribute(a,b)
     if a=="UseAvatarAppearance" and S.Alive(player.Character) then
      require(BossSystem.Players.PlayerR6Appearance).Request(player,player.Character)
     end
    elseif action == "Select" then
      if type(a) ~= "string" or not ClassConfig.Classes[a] then
        return
      end
      if workspace:GetAttribute("EncounterStarted") then
        remote:FireClient(player, "Result", { Message = "Classes are locked while the fight is running." })
        return
      end
      player:SetAttribute("PlayerClass", a)
      if player.Character then
        S.Apply(player, player.Character)
      end
      remote:FireClient(player, "Result", { Message = "You are now a " .. ClassConfig.Classes[a].Name .. "." })
    elseif action == "Action" then
      local char = player.Character
      local st = states[char]
      if not st or not S.Alive(char) or type(a)~="string" or not ({M1=true,F=true,C=true,V=true,R=true,Aim=true})[a] then
        return
      end
   if b=="End" and a=="F" and st.Class=="Tank" then
    Kits.Tank.StopDefender(S,char,st)
    return
   end
   if b=="End" and a=="R" then S.Unbuff(char,"Blocking") return end
   if a ~= "Aim" and not S.CanAct(char) then
    S.CancelActions(char)
    return
   end
   if S.CanAct(char) then st.ControlBlocked=false st.ControlReason=nil end
      local aim=typeof(c)=="Vector3" and c or nil
   if aim and (aim.X~=aim.X or aim.Y~=aim.Y or aim.Z~=aim.Z or math.abs(aim.X)>1e7 or math.abs(aim.Y)>1e7 or math.abs(aim.Z)>1e7) then aim=nil end
      if aim and (aim - char.HumanoidRootPart.Position).Magnitude > 600 then
        aim = nil
      end
      st.Aim = aim or st.Aim
      if a == "R" then
        if b=="Begin" and S.CanBlock(char) then
          S.Buff(char, "Blocking", nil, { Defense = ClassConfig.Block.Defense, Speed = ClassConfig.Block.SpeedMultiplier })
          local color = st.Def.Color or Color3.new(1, 1, 1)
          for _, arm in ipairs({ "Left Arm", "Right Arm" }) do
            local part = char:FindFirstChild(arm)
            if part then
              FX.HQ.Glint(part.Position, color, 2.5, 0.3)
            end
          end
          FX.HQ.Shockwave(CFrame.new(char.HumanoidRootPart.Position - Vector3.new(0, 2.7, 0)), 1, 4, 0.3, color, 0.3, 0.35)
          S.Sound(char, "GuardActivate")
        elseif b == "End" then
          S.Unbuff(char, "Blocking")
        end
        return
      end
      if now() < (char:GetAttribute("ClassSealed_" .. a) or 0) then
        return
      end
       
      if S.HasBuff(char,"Blocking") and a~="Aim" and b~="End" then
        return
      end
      local kit = Kits[st.Class]
      if kit and kit.Action then
        local ok, err = pcall(kit.Action, S, player, char, st, a, b, aim)
        char:SetAttribute("ClassHoldingSkill",S.HoldingKey(char))
        if not ok then
          warn("Class action (" .. st.Class .. " " .. a .. "): " .. tostring(err))
        end
      end
    end
  end)
  Run.Heartbeat:Connect(step)
   
  for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then
      task.spawn(S.Apply, p, p.Character)
    end
  end
end
S.Remote = function()
  return remote
end
return S
