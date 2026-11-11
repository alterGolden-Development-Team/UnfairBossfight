local B=script:FindFirstAncestor("BossSystem")
local Registry=require(B.Combat.AttackRegistry)
local Effects=require(B.Combat.EffectService)
local Encounter=require(B.Players.PlayerEncounter)
local Status=require(B.Combat.StatusEffectService)
local Cooldowns=require(B.Combat.AbilityCooldownService)
local Time=require(B.Mechanics.Time.TimeEffectController)
local Placement=require(B.Encounter.ArenaPlacement)
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local A={}
A.Palette=table.freeze({Color3.fromRGB(115,255,205),Color3.fromRGB(98,195,255),Color3.fromRGB(174,114,255),Color3.fromRGB(255,106,199),Color3.fromRGB(255,208,111)})
function A.SegmentDistance(point,a,b)
 local d=b-a
 local t=d:Dot(d)>.0001 and math.clamp((point-a):Dot(d)/d:Dot(d),0,1)or 0
 return (point-(a+d*t)).Magnitude,t
end
function A.Create(actor,style,lifetime,onEnd)
 local core=Registry.For(actor,"P1CombatCore")
 local cast=Effects.NewCast(actor,style.Name,lifetime)cast.TimeStopExempt=true cast.PersistsThroughEmitterStun=true
  -- heavy-cast bookkeeping: the selector won't start ultimates or other heavy attacks while
  -- one of these lingers; HeavyCastsUntil expires a count that was never released
 actor:SetAttribute("HeavyCasts",(actor:GetAttribute("HeavyCasts")or 0)+1)
 actor:SetAttribute("HeavyCastsUntil",math.max(actor:GetAttribute("HeavyCastsUntil")or 0,workspace:GetServerTimeNow()+lifetime+1))
 local generation=actor:GetAttribute("PhaseGeneration")or 0
 local revision=actor:GetAttribute("MovementRevision")or 0
 local ctx={Actor=actor,Core=core,Cast=cast,Style=style,Palette=A.Palette,Token=Http:GenerateGUID(false),Started=cast:Now(),Burned={}}
 local originalAnchored,hover
 function ctx.Valid()
  local h=actor:FindFirstChildOfClass("Humanoid")
  return cast:Alive()and actor.Parent and actor:GetAttribute("AIEnabled")~=false and h and h.Health>0 and actor:GetAttribute("Phase")==5
   and not actor:GetAttribute("EncounterEnded")and not actor:GetAttribute("PhaseTransitionInProgress")
   and (actor:GetAttribute("PhaseGeneration")or 0)==generation
 end
 function ctx.Elapsed()return cast:Now()-ctx.Started end
 function ctx.Target(char)
  local player=char and Players:GetPlayerFromCharacter(char)
  return player and player.Character==char and not player:GetAttribute("ViewAsServer")
   and not Encounter.IsDefeated(player)and core.Alive(char)
 end
 function ctx.Targets(range,center)
  local out={}
  for _,player in ipairs(Players:GetPlayers())do
   local char=player.Character
   if ctx.Target(char)and(not range or(char.HumanoidRootPart.Position-center).Magnitude<=range)then out[#out+1]=char end
  end
  return out
 end
 function ctx.Send(stage,data)
  data=data or{}data.Stage=stage data.Attack=style.Name data.Token=ctx.Token data.Owner=actor
  data.Params=style data.Generation=generation data.StartedAt=data.StartedAt or workspace:GetServerTimeNow()
  data.Radius=1000 core.ScreenEffect("P5Astral",data)
 end
 function ctx.Ground(point)return Placement.GroundPoint(point,{Clamp=true})or point-Vector3.yAxis*3 end
 function ctx.Part(name,size,position,color,transparency,shape)
  local part=cast:Add(Effects.AcquirePart())
  part.Name=name part.Size=size part.CFrame=CFrame.new(position)part.Color=color
  part.Transparency=transparency or 0 part.Shape=shape or Enum.PartType.Ball
  part:SetAttribute("TimeStopExempt",true)part.Parent=core.Effects
  return part
 end
 function ctx.Remove(part)Effects.Release(part)end
 function ctx.Glow(part,color,range,brightness)
  local light=cast:Add(Instance.new("PointLight"))light.Color=color light.Range=range light.Brightness=brightness light.Parent=part
  return light
 end
 function ctx.Line(name,a,b,width,color,alpha)
  local length=(b-a).Magnitude
  local part=ctx.Part(name,Vector3.new(width,width,math.max(.1,length)),(a+b)*.5,color,alpha,Enum.PartType.Block)
  if length>.01 then part.CFrame=CFrame.lookAt((a+b)*.5,b)end
  return part
 end
 function ctx.Ring(position,radius,color)
  local holder=cast:Add(Instance.new("Folder"))holder.Name="AstralGroundRing"holder.Parent=core.Effects
  local segments={}
  for i=1,24 do
   local angle=(i-1)*math.pi/12
   local part=ctx.Part("AstralRing",Vector3.new(.3,.25,math.max(.3,radius*math.pi/12)),position,color,.12,Enum.PartType.Block)
   part.Parent=holder segments[i]=part
   part.CFrame=CFrame.new(position+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius))*CFrame.Angles(0,-angle,0)
  end
  return holder,segments
 end
 function ctx.CanHit(char,origin)
  return ctx.Target(char)and core.CanHit(char,origin or core.Root.Position)
 end
 function ctx.Damage(char,amount,dot,origin)
  if not ctx.Target(char)or not ctx.CanHit(char,origin)then return 0 end
  return Encounter.Damage(char,amount,actor,nil,{Skill=style.Name,IsStatusDamage=dot==true})
 end
 function ctx.Burn(char,amounts,interval,key,immediate,origin)
  if not ctx.Target(char)or not ctx.CanHit(char,origin)then return false end
  if style.BurnOnce and ctx.Burned[char]then return false end
  local applied=Status.ApplyAstralBurn(char,amounts,interval,actor,style.Name,key or cast,immediate)
  if applied and style.BurnOnce then ctx.Burned[char]=true end
  return applied
 end
 function ctx.AnchorBoss()
  if originalAnchored==nil then originalAnchored=core.Root.Anchored Time.SetAnchored(core.Root,true)hover=0 end
 end
 function ctx.Hover(height)
  if core.Root.Parent and (actor:GetAttribute("MovementRevision")or 0)==revision then core.Root.CFrame+=Vector3.yAxis*(height-(hover or 0))hover=height end
 end
 function ctx.Step(fn)
  cast:Step(function(dt,now)
   if not ctx.Valid()then cast:Dispose()return false end
   return fn(math.min(dt,.1),ctx.Elapsed(),now)
  end)
 end
 function ctx.WaitFor(seconds)
  while ctx.Valid()and ctx.Elapsed()<seconds do task.wait(.03)end
  if not ctx.Valid()then cast:Dispose()return false end
  return true
 end
 function ctx.Wait()
  while ctx.Valid()do task.wait(.03)end
  cast:Dispose()
 end
 cast.OnDispose=function()
  local left=math.max((actor:GetAttribute("HeavyCasts")or 1)-1,0)
  actor:SetAttribute("HeavyCasts",left)
  if left==0 and actor.Parent then  -- last lingering heavy ended: a short breather for players
   local breather=require(game.ReplicatedStorage.BossShared.Config.EncounterConfig).HeavyBreather or 1.2
   actor:SetAttribute("NextAttackAt",math.max(actor:GetAttribute("NextAttackAt")or 0,workspace:GetServerTimeNow()+breather))
   if actor:GetAttribute("Phase")==5 then actor:SetAttribute("FillerDebt",require(game.ReplicatedStorage.BossShared.Config.EncounterConfig).Phase5FillerBetween or 2)end
  end
  if originalAnchored~=nil and core.Root.Parent and (actor:GetAttribute("MovementRevision")or 0)==revision
   and (actor:GetAttribute("PhaseGeneration")or 0)==generation then
   if hover and hover~=0 then core.Root.CFrame-=Vector3.yAxis*hover end
   Time.SetAnchored(core.Root,originalAnchored)
  end
  ctx.Send("End")
  if onEnd then onEnd(ctx)end
 end
 return ctx
end
function A.Ready(actor,style,current,target)
 local core=Registry.For(actor,"P1CombatCore")
 return not current and actor:GetAttribute("Phase")==5 and core.Active()and core.Alive(target)
  and not actor:GetAttribute("IsGoldenClone")and not actor:GetAttribute("IsIllusion")
  and not actor:GetAttribute("PhaseTransitionInProgress")and Cooldowns.Ready(actor,style.Name)
end
 -- difficulty knobs for Phase 5 (DifficultyConfig): Telegraph scales windups/tells, ProjectileSpeed
 -- scales travel/pull speeds, Density scales shot counts and tick rates
local Difficulty=require(game.ReplicatedStorage.BossShared.Config.DifficultyConfig)
function A.Knobs(actor)
 local ok,p=pcall(Difficulty.Get,actor)
 p=ok and type(p)=="table"and p or{}
 return {Telegraph=p.Telegraph or 1,Speed=p.ProjectileSpeed or 1,Density=p.Density or 1}
end
 -- per-cast copy of a style scaled by the knobs; spec lists field names per category:
 --   Speed  x Speed            Agile  x (1+(Speed-1)*3): turning/chasing reacts harder than raw speed
 --   Count  x Density, rounded Rate   / Density (intervals)        Tell   x Telegraph
 -- TrueHardcore (all knobs 1) gets the style back untouched
function A.Tune(actor,style,spec)
 local k=A.Knobs(actor)
 if k.Telegraph==1 and k.Speed==1 and k.Density==1 then return style end
 local s=table.clone(style)
 local function each(list,fn)for _,f in ipairs(list or{})do if type(s[f])=="number"then s[f]=fn(s[f])end end end
 each(spec.Speed,function(v)return v*k.Speed end)
 each(spec.Agile,function(v)return v*(1+(k.Speed-1)*3)end)
 each(spec.Count,function(v)return math.max(1,math.floor(v*k.Density+.5))end)
 each(spec.Rate,function(v)return v/k.Density end)
 each(spec.Tell,function(v)return v*k.Telegraph end)
 return s
end
function A.StartCooldown(actor,style)Cooldowns.Start(actor,style.Name,style.Cooldown)end
function A.Shoot(ctx,origin,target,style,color,onHit,buildVisual)
 local part=buildVisual(ctx,origin,color)
 local position=origin
 local aim=target.HumanoidRootPart.Position
 local delta=aim-origin
 local direction=delta.Magnitude>.01 and delta.Unit or -Vector3.yAxis
 local born=ctx.Elapsed()
 local done=false
 local projectile={}
 function projectile.Step(dt)
  if done then return false end
  local age=ctx.Elapsed()-born
  if age>=style.ProjectileLife then ctx.Remove(part)done=true return false end
  if ctx.Target(target)then
   aim=target.HumanoidRootPart.Position
   local desired=aim-position
   if desired.Magnitude>.01 then
    local nextDirection=direction:Lerp(desired.Unit,math.clamp(dt*style.TurnRate,0,1))
    if nextDirection.Magnitude>.01 then direction=nextDirection.Unit end
   end
  end
  local nextPosition=position+direction*style.ProjectileSpeed*dt
  local hit=ctx.Target(target)and A.SegmentDistance(target.HumanoidRootPart.Position,position,nextPosition)<=style.HitRadius
  local params=ctx.Core.Params()
  local wall=workspace:Raycast(position,nextPosition-position,params)
  if wall and ctx.Target(target)and wall.Instance:IsDescendantOf(target)then hit=true end
  if hit then
   if ctx.CanHit(target,nextPosition)then onHit(target,nextPosition)end
   ctx.Remove(part)done=true return false
  elseif wall then ctx.Remove(part)done=true return false end
  position=nextPosition part.CFrame=CFrame.lookAt(position,position+direction)
  return true
 end
 return projectile
end
return table.freeze(A)
