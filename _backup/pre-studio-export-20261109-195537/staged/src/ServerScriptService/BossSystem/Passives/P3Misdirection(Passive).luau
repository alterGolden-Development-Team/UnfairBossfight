local B=script:FindFirstAncestor("BossSystem")
local Config=require(game.ReplicatedStorage.BossShared.Config.EncounterConfig)
local Registry=require(B.Combat.AttackRegistry)
local Effects=require(B.Combat.EffectService)
local Placement=require(B.Encounter.ArenaPlacement)
local Audio=require(B.Presentation.CombatAudio)
return function(actor)
 local api={IsPassive=true}
 local eligible=table.freeze({P3Projectile=true,P3Cards=true})
  -- shot attacks that fire their own decoy rounds at the point TryEmission hands back
 local emitters=table.freeze({["P3.5TrueIllusion(Ultimate)"]=true,["P3.5IllusionGun"]=true})
 api.Eligible=eligible
 local random=Random.new()
 local nextAt=0
 local cueName,cueUntil
 local active={}
 function api.CueEnabled(name)
  return cueName==name and workspace:GetServerTimeNow()<cueUntil
 end
 function api.Cue(core,part,position)
  if part and part.Parent then
   local lease=Effects.LeaseId(part)
   local color=part.Color
   part.Color=Color3.fromRGB(255,255,205)
   task.delay(.12,function()if part.Parent and Effects.LeaseId(part)==lease then part.Color=color end end)
  end
  local flash=core.Part("MisdirectionTrueFlash",CFrame.new(position),Vector3.one*2,Color3.fromRGB(255,245,160),.4)
  flash.Shape=Enum.PartType.Ball
  Effects:Create(flash,TweenInfo.new(.12),{Size=Vector3.one*4,Transparency=1}):Play()
  Effects.ReleaseAfter(flash,.15)
  Audio.Emit(actor,"P3Snap",position,{VolumeScale=.25})
 end
 function api.Try(name,target,rng)
  local now=workspace:GetServerTimeNow()
  if not eligible[name] or math.floor(actor:GetAttribute("Phase") or 1)~=3
   or actor:GetAttribute("IsGoldenClone") or actor:GetAttribute("IsIllusion")
   or actor:GetAttribute("EncounterEnded") or actor:GetAttribute("PhaseTransitionInProgress")
   or actor:GetAttribute("ExecutionLocked") or now<nextAt
   or not target or not target:FindFirstChild("HumanoidRootPart") then return false end
  if (rng or random):NextNumber()>=math.clamp(Config.P3MisdirectionChance or .35,0,1) then return false end
  local point
  for attempt=1,12 do
   local angle=random:NextNumber(0,math.pi*2)
   local candidate=Placement.GroundPoint(target.HumanoidRootPart.Position+Vector3.new(math.cos(angle),0,math.sin(angle))*random:NextNumber(55,85),{Margin=12,Clamp=true})
   if candidate and Vector3.new(candidate.X-target.HumanoidRootPart.Position.X,0,candidate.Z-target.HumanoidRootPart.Position.Z).Magnitude>=40 then point=candidate;break end
  end
  if not point then return false end
  nextAt=now+(Config.P3MisdirectionCooldown or 6)
  cueName,cueUntil=name,now+4
  local cast=Effects.NewCast(actor,"P3MisdirectionFakeTarget",6)
  active[cast]=true
  local generation=actor:GetAttribute("PhaseGeneration") or 0
  local proxy=Instance.new("Model");proxy.Name="MisdirectionAim"
  local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=Vector3.one
  root.Transparency=1;root.Anchored=true;root.CanCollide=false;root.CanQuery=false;root.CanTouch=false
  root.CFrame=CFrame.new(point+Vector3.yAxis*3);root.Parent=proxy
  local humanoid=Instance.new("Humanoid");humanoid.RequiresNeck=false;humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;humanoid.Parent=proxy
  proxy.PrimaryPart=root;proxy.Parent=require(B.Combat.CombatRuntime).Effects;cast:Add(proxy)
  api.LastFakeTarget=point
  actor:SetAttribute("MisdirectionProcs",(actor:GetAttribute("MisdirectionProcs") or 0)+1)
  actor:SetAttribute("MisdirectionLastAttack",name)
  actor:SetAttribute("MisdirectionCooldownUntil",nextAt)
  local fakeCast
  cast.OnDispose=function()
   active[cast]=nil
   if fakeCast and not fakeCast.closed then fakeCast:Dispose() end
  end
  cast:Step(function()
   if not actor.Parent or (actor:GetAttribute("PhaseGeneration") or 0)~=generation
    or math.floor(actor:GetAttribute("Phase") or 1)~=3 or actor:GetAttribute("EncounterEnded")
    or actor:GetAttribute("PhaseTransitionInProgress") then cast:Dispose();return false end
   return true
  end)
  task.spawn(function()
   local skill=Registry.For(actor,name)
   local ok,err=pcall(skill.Combo,proxy,{Fake=true})
   fakeCast=skill.LastFakeCast
   if cast.closed and fakeCast and not fakeCast.closed then fakeCast:Dispose() end
   if not ok then warn("Misdirection: "..tostring(err));cast:Dispose() end
  end)
  return true
 end
 function api.TryEmission(name,target,rng)
  local now=workspace:GetServerTimeNow()
  if not emitters[name] or actor:GetAttribute("Phase")~=3.5
   or actor:GetAttribute("IsGoldenClone") or actor:GetAttribute("IsIllusion")
   or actor:GetAttribute("EncounterEnded") or actor:GetAttribute("PhaseTransitionInProgress")
   or now<nextAt or not target or not target:FindFirstChild("HumanoidRootPart") then return nil end
  rng=rng or random
  if rng:NextNumber()>=math.clamp(Config.P3MisdirectionChance or .35,0,1) then return nil end
  local point
  for attempt=1,12 do
   local angle=rng:NextNumber(0,math.pi*2)
   local candidate=Placement.GroundPoint(target.HumanoidRootPart.Position+Vector3.new(math.cos(angle),0,math.sin(angle))*rng:NextNumber(55,85),{Margin=12,Clamp=true})
   if candidate and Vector3.new(candidate.X-target.HumanoidRootPart.Position.X,0,candidate.Z-target.HumanoidRootPart.Position.Z).Magnitude>=40 then point=candidate+Vector3.yAxis*3;break end
  end
  if not point then return nil end
  nextAt=now+(Config.P3MisdirectionCooldown or 6)
  actor:SetAttribute("MisdirectionProcs",(actor:GetAttribute("MisdirectionProcs") or 0)+1)
  actor:SetAttribute("MisdirectionLastAttack",name)
  actor:SetAttribute("MisdirectionCooldownUntil",nextAt)
  api.LastFakeTarget=point
  return point
 end
 function api.Reset()
  cueName,cueUntil=nil,0
  local list={}for cast in pairs(active) do table.insert(list,cast) end
  for _,cast in ipairs(list) do cast:Dispose() end
 end
 api.Dispose=api.Reset
 return api
end