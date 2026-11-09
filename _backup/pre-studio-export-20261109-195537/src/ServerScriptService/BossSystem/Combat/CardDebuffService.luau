local B=script:FindFirstAncestor("BossSystem")
local S=require(B.Combat.StatusEffectService)
local Effects=require(B.Combat.EffectService)
local Registry=require(B.Combat.AttackRegistry)
local Runtime=require(B.Combat.CombatRuntime)
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local api={}
local owned=setmetatable({}, {__mode="k"})
local function track(character,cast)
 local entries=owned[character]
 if not entries then entries={};owned[character]=entries end
 entries[cast]=true
 return cast
end
function api.ClearCharacter(character)
 local entries=owned[character]
 owned[character]=nil
 if entries then for cast in pairs(entries) do cast:Dispose() end end
end
local Config=require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
function api.RollHalved(rng)
 return rng:NextNumber()<math.clamp(Config.P3CardsHalvedChance or .001,0,1)
end
api.Names=table.freeze({"Fear","HPRegenBlock","StaminaRegenBlock","CardBurn","Bleed","Slow","AttackDebuff",
 "Poison","ProjectileDarkness","GoldenBurn","Electricified","Flung","Chained","Stunned",
 "GoldenMark","Deceleration","Halved","StolenSecond","ControlDistortion","AbilitiesSealed", "Vulnerability", "CooldownIncrease", "CooldownFreeze", "ChainCurse", "TemporalWound", "Acid", "DeathMark", "JumpLock", "Blur", "Rupture", "IllusionRot", "Frostbite", "Hemorrhage", "Corruption", "Decay"})
function api.Active(character,name)
 if name=="Halved" then return (character:GetAttribute("HalvedStacks") or 0)>0 end
 if name=="GoldenBurn" then return character:GetAttribute("GoldenBurnActive")==true end
 if name=="Chained" then return character:GetAttribute("ChainedControlActive")==true end
 if name=="StolenSecond" then return character:GetAttribute("StolenSecondActive")==true end
 if name=="Stunned" then name="CardStunned" end
 return (character:GetAttribute(name.."Until") or 0)>workspace:GetServerTimeNow()
end
local function context(actor)
 local core=Registry.For(actor,"P1CombatCore")
 local generation=actor:GetAttribute("PhaseGeneration") or 0
 local ctx={Actor=actor,Owner=actor,Core=core,Root=core.Root,Filter=Runtime.FilterFor(actor)}
 function ctx.Valid()
  return actor.Parent and core.Alive(actor) and math.floor(actor:GetAttribute("Phase") or 1)==3
   and (actor:GetAttribute("PhaseGeneration") or 0)==generation
   and not actor:GetAttribute("EncounterEnded") and not actor:GetAttribute("PhaseTransitionInProgress")
 end
 function ctx.Cast(name,seconds)
  local cast=Effects.NewCast(actor,name,seconds)
  cast.TimeStopExempt=true
  cast:Step(function() if not ctx.Valid() then cast:Dispose();return false end return true end)
  return cast
 end
 function ctx.Damage(character,amount,skill)
  if ctx.Valid() then return core.Damage(character,amount,skill) end return 0
 end
 function ctx.Part(cast,name,frame,size,color,alpha)
  local p=Effects.AcquirePart()
  p.Name=name;p.CFrame=frame;p.Size=size;p.Color=color;p.Transparency=alpha or 0
  p.Parent=Runtime.Effects
  return cast:Add(p)
 end
 function ctx.Line(cast,name,from,to,width,color,alpha)
  return ctx.Part(cast,name,CFrame.lookAt((from+to)*.5,to),Vector3.new(width,width,math.max(.01,(to-from).Magnitude)),color,alpha)
 end
 return ctx
end
function api.Apply(character,name,seconds,actor)
 local player=Players:GetPlayerFromCharacter(character)
 if not player or not actor or not require(B.Players.PlayerEncounter).CanReceiveHit(character)
  or actor:GetAttribute("IsIllusion") then return false end
 if name~="Deceleration" and name~="Halved" and S.IsDebuffImmune(character) then return false end
 local ctx=context(actor)
 if not ctx.Valid() then return false end
 if table.find({"Vulnerability","CooldownIncrease","CooldownFreeze","ChainCurse","TemporalWound","Acid","DeathMark","JumpLock","Blur","Rupture","IllusionRot","Frostbite","Hemorrhage","Corruption","Decay"},name) then
  return S.ApplyAdvancedDebuff(character,name,seconds,actor)
 elseif name=="Electricified" then return require(B.Attacks.Shared.ShieldBreakControl).Electricify(ctx,character)
 elseif name=="Flung" then
  return require(B.Attacks.Shared.ShieldBreakControl).Apply(ctx,character,1.2,true,
   character.HumanoidRootPart.Position-ctx.Root.Position,{Speed=65,Lift=75})
 elseif name=="GoldenMark" then return S.ApplyGoldenMark(character,actor)>0
 elseif name=="Deceleration" then return require(B.Mechanics.Time.TimeEffectController).ApplyDeceleration(character,seconds)~=nil
 elseif name=="Halved" then return require(B.Combat.HealthPenaltyService).Apply(player,.5)~=nil
 elseif name=="ControlDistortion" then return require(B.Mechanics.Reality.RealityController).ControlDistortion(actor,character)
 elseif name=="AbilitiesSealed" then return require(B.Mechanics.Reality.RealityController).SealAbilities(actor,character)
 elseif name=="StolenSecond" then return Registry.For(actor,"P2.5StolenSecond").Begin(character,true)~=false
 elseif name=="Chained" or name=="Stunned" then
  local duration=name=="Chained" and 2 or .5
  local cast=track(character,ctx.Cast("Card"..name,duration+.05))
  if not S.ApplyStun(character,cast,duration,1,{Family="CardControl",AllowDefense=true,Effect=name}) then cast:Dispose();return false end
  if name=="Stunned" then
   character:SetAttribute("CardStunnedUntil",workspace:GetServerTimeNow()+duration)
   player:SetAttribute("CardStunnedUntil",workspace:GetServerTimeNow()+duration)
  end
  cast.OnDispose=function()
    local entries=owned[character];if entries then entries[cast]=nil end
   S.ReleaseRestraint(character,cast)
   if name=="Stunned" then
    character:SetAttribute("CardStunnedUntil",0)
    if player.Character==character then player:SetAttribute("CardStunnedUntil",0) end
   end
  end
  return true
 elseif name=="ProjectileDarkness" then
  local cast=track(character,ctx.Cast("CardDarkness",seconds))
  local token=Http:GenerateGUID(false)
  if not S.ApplyProjectileDarkness(character,seconds,actor,token) then cast:Dispose();return false end
  local remote=game.ReplicatedStorage.BossCombatEffects
  character:SetAttribute("ProjectileDarknessToken",token)
  remote:FireClient(player,"P3ProjectileDarkness",{Token=token,Owner=actor,EndsAt=workspace:GetServerTimeNow()+seconds})
  cast.OnDispose=function()
    local entries=owned[character];if entries then entries[cast]=nil end
   S.ClearProjectileDarkness(character,token)
   if character:GetAttribute("ProjectileDarknessToken")==token then character:SetAttribute("ProjectileDarknessToken",nil) end
   if player.Parent then remote:FireClient(player,"P3ProjectileDarknessEnd",{Token=token}) end
  end
  cast:Step(function()
   if player.Character~=character or not ctx.Core.Alive(character) or S.IsDebuffImmune(character)
    or character:GetAttribute("ProjectileDarknessToken")~=token then cast:Dispose();return false end
   return true
  end)
  return true
 end
 return false
end
return api