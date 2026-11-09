local AttackDebuffs=require(script:FindFirstAncestor("BossSystem").Combat.AttackDebuffService)
local Difficulty=require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
local BossSystem = script:FindFirstAncestor("BossSystem")
local Style = require(script.Parent.Style)
local Effects = require(BossSystem.Combat.EffectService)
local Placement = require(BossSystem.Encounter.ArenaPlacement)
local Visuals = require(script.Parent.Visuals)
local Audio = require(BossSystem.Presentation.CombatAudio)
return function(actor)
 local Registry = require(BossSystem.Combat.AttackRegistry)
 local core = Registry.For(actor, "P1CombatCore")
 local split = Registry.For(actor, "P1GoldenSplit")
 local api = { Cooldown = Style.Cooldown }
 local current
 local hazards={}
  
 local sharedTick=setmetatable({},{__mode="k"})
 local function startHazard(lane,groundY,duration)
  duration=duration or Style.HazardDuration
  local cast=Effects.NewCast(actor,"P4EnhancedSplitHazard",duration+.4)
  hazards[cast]=true
  cast.OnDispose=function() hazards[cast]=nil end
  local generation=actor:GetAttribute("PhaseGeneration") or 0
  local born=cast:Now()
  local nextTick=sharedTick
  local hazardStyle=setmetatable({HazardDuration=duration},{__index=Style})
  Visuals.Hazard(core,split,actor,lane,groundY,cast,hazardStyle)
  actor:SetAttribute("LastEnhancedSplitHazardDamage",Style.HazardDamage)
  actor:SetAttribute("LastEnhancedSplitHazardDuration",Style.HazardDuration)
  cast:Step(function(_,now)
   if math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) ~= 4 or (actor:GetAttribute("PhaseGeneration") or 0)~=generation
    or actor:GetAttribute("PhaseTransitionInProgress") or actor:GetAttribute("EncounterEnded") then
    cast:Dispose(); return false
   end
   if now-born>=duration then return false end
   for _,character in ipairs(core.Characters()) do
    if core.Alive(character) then
     local hum=character:FindFirstChildOfClass("Humanoid")
     local p=lane.frame:PointToObjectSpace(character.HumanoidRootPart.Position)
     local rootY=character.HumanoidRootPart.Position.Y
     if math.abs(p.X)<=lane.width*.5 and p.Z<=0 and p.Z>=-lane.length
      and rootY>=groundY-1 and rootY<=groundY+Style.HazardHeight
      and os.clock()>=(nextTick[hum] or 0) and now>=born+Style.HazardInterval then
      nextTick[hum]=os.clock()+Style.HazardInterval
      local damage=core.Damage(character,Style.HazardDamage,"P4EnhancedSplitHazard")
      if damage>0 then
       actor:SetAttribute("LastEnhancedSplitHazardTickDamage",damage)
       actor:SetAttribute("EnhancedSplitHazardTicks",(actor:GetAttribute("EnhancedSplitHazardTicks") or 0)+1)
       core.Melee.HitFx(character.HumanoidRootPart.Position)
      end
     end
    end
   end
   return true
  end)
 end
  
  
 local function laneThrough(origin,direction,width,forwardOnly)
  local bounds=Placement.GetBounds()
  if not bounds then return nil end
  local p=bounds.Frame:PointToObjectSpace(origin)
  local d=bounds.Frame:VectorToObjectSpace(direction)
  local low,high=-math.huge,math.huge
  for _,axis in ipairs({{p.X,d.X,bounds.HalfX},{p.Z,d.Z,bounds.HalfZ}}) do
   if math.abs(axis[2])>.0001 then
    local a=(-axis[3]-axis[1])/axis[2]
    local z=(axis[3]-axis[1])/axis[2]
    low=math.max(low,math.min(a,z));high=math.min(high,math.max(a,z))
   end
  end
  if forwardOnly then low=math.max(0,low) end
  if low>=high then return nil end
  local first=origin+direction*low
  local last=origin+direction*high
  return {frame=CFrame.lookAt(first,last),length=high-low,width=width,nextTick={}},first,last
 end
 function api.CanUse(target)
  return not current and math.min(4, math.floor(actor:GetAttribute("Phase") or 0)) == 4 and core.Active() and core.Alive(target)
   and not actor:GetAttribute("PhaseTransitionInProgress")
   and not actor:GetAttribute("EncounterEnded")
   and Placement.Contains(target.HumanoidRootPart.Position)
 end
 function api.Combo(target)
  if not api.CanUse(target) then return false end
  local result = core.Perform(target, "P4EnhancedSplit", function()
   core.Face(target)
   local ground = Placement.GroundPoint(core.Root.Position)
   if not ground then return false end

    
    
   local bounds=Placement.GetBounds()
   if not bounds then return false end
   local direction=core.Root.CFrame.LookVector
   local origin=core.Root.Position
   local p=bounds.Frame:PointToObjectSpace(origin)
   local d=bounds.Frame:VectorToObjectSpace(direction)
   local low,high=-math.huge,math.huge
   for _,axis in ipairs({{p.X,d.X,bounds.HalfX},{p.Z,d.Z,bounds.HalfZ}}) do
    if math.abs(axis[2])>.0001 then
     local a=(-axis[3]-axis[1])/axis[2]
     local z=(axis[3]-axis[1])/axis[2]
     low=math.max(low,math.min(a,z));high=math.min(high,math.max(a,z))
    end
   end
   if low>=high then return false end
   low=math.max(0,low)
   if low>=high then return false end
   local first=origin+direction*low
   local last=origin+direction*high
   local lane={frame=CFrame.lookAt(first,last),length=high-low,width=Style.Width,nextTick={}}
   local cast = Effects.NewCast(actor, "P4EnhancedSplit", Style.Windup + Style.CrossWindup + 3)
   current = cast
   cast.OnDispose = function() if current == cast then current = nil end end
   local band, line = split.Warning(lane, ground.Y)
   cast:Add(band); cast:Add(line)
   actor:SetAttribute("AttackState", "Enhanced Split: aimed line warning")
   core.PoseAngles({RightShoulder={160,0,-8},LeftShoulder={30,0,-20},Waist={-8,0,0}},0.15)
   Audio.Emit(actor, "SplitCharge", core.Root)
   Visuals.Charge(core,lane,ground.Y,cast,Style)
   Visuals.ChargeFlourish(core,cast,Style,Style.Windup)
   if not core.WaitFor(Style.Windup) or not cast:Alive() then return false end
   Effects.Release(band); cast.objects[band]=nil
   Effects.Release(line); cast.objects[line]=nil
   actor:SetAttribute("AttackState", "Enhanced Split: single slash")
   core.PoseAngles({RightShoulder={10,0,-12},Waist={28,0,0}},0.08)
   if not core.WaitFor(0.08) or not cast:Alive() then return false end
   split.StrikeTemporary(lane, ground.Y, {
    Damage=Style.Damage, Height=Style.Height, Hit={}, Origin=core.Root.Position, Skill="P4EnhancedSplit",
    OnHit=function(char) AttackDebuffs.Apply(actor,char,"Rupture",3,cast) end,
   }, cast)
   Visuals.Cleave(core,lane,ground.Y,cast,Style,1)
   startHazard(lane,ground.Y)

    
    
    
   if Style.CrossSplit and Difficulty.Mercy("CrossSplit")~=false and core.Alive(target) and cast:Alive() then
    local tp=target.HumanoidRootPart.Position
    local flat=Vector3.new(direction.X,0,direction.Z)
    flat=flat.Magnitude>.01 and flat.Unit or Vector3.zAxis
    local crossDir=Vector3.new(-flat.Z,0,flat.X)
    local cross=laneThrough(Vector3.new(tp.X,origin.Y,tp.Z),crossDir,Style.CrossWidth,false)
    if cross then
     local band2,line2=split.Warning(cross,ground.Y)
     cast:Add(band2);cast:Add(line2)
     actor:SetAttribute("AttackState","Enhanced Split: cross warning")
     core.PoseAngles({RightShoulder={150,0,40},LeftShoulder={30,0,-20},Waist={-6,-60,0}},Style.CrossWindup*.6)
     Visuals.ChargeFlourish(core,cast,Style,Style.CrossWindup)
     if not core.WaitFor(Style.CrossWindup) or not cast:Alive() then return false end
     Effects.Release(band2);cast.objects[band2]=nil
     Effects.Release(line2);cast.objects[line2]=nil
     actor:SetAttribute("AttackState","Enhanced Split: cross slash")
     core.PoseAngles({RightShoulder={20,0,60},Waist={20,70,0}},0.07)
     Audio.Emit(actor,"SplitCharge",core.Root)
     split.StrikeTemporary(cross,ground.Y,{
      Damage=Style.CrossDamage,Height=Style.Height,Hit={},Origin=core.Root.Position,Skill="P4EnhancedSplit",
      OnHit=function(char) AttackDebuffs.Apply(actor,char,"Rupture",3,cast) end,
     },cast)
     Visuals.Cleave(core,cross,ground.Y,cast,Style,.8)
     startHazard(cross,ground.Y,Style.CrossHazardDuration)
     actor:SetAttribute("LastEnhancedSplitLaneCount",2)
    end
   end
   actor:SetAttribute("LastEnhancedSplitDamage",Style.Damage)
   actor:SetAttribute("LastEnhancedSplitLength",lane.length)
   actor:SetAttribute("LastEnhancedSplitWidth",lane.width)
   actor:SetAttribute("LastEnhancedSplitStart",first)
   actor:SetAttribute("LastEnhancedSplitEnd",last)
   return core.WaitFor(Style.Recovery)
  end)
  if current then current:Dispose() end
  return result
 end
 function api.Dispose()
  if current then current:Dispose() end
  local pending={}
  for cast in pairs(hazards) do table.insert(pending,cast) end
  for _,cast in ipairs(pending) do cast:Dispose() end
 end
 return api
end
