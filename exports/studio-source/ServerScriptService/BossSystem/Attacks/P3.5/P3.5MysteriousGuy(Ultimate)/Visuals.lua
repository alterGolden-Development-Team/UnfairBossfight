local B=script:FindFirstAncestor("BossSystem")
local Shared=require(B.Attacks.Shared.P35IllusionFX)
local S=require(script.Parent.Style)
local Placement=require(B.Encounter.ArenaPlacement)
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
require(script.Parent.Presentation).Publish()
local PAL=S.Palette
local TEX_SPARK="rbxasset://textures/particles/sparkles_main.dds"
local TEX_SMOKE="rbxasset://textures/particles/smoke_main.dds"
local BURST_WINDOW=.18
local QUAD,QUART,LINEAR=Enum.EasingStyle.Quad,Enum.EasingStyle.Quart,Enum.EasingStyle.Linear
local OUT,IN=Enum.EasingDirection.Out,Enum.EasingDirection.In
local DISC=CFrame.Angles(0,0,math.pi/2)  
local V3=Vector3.new

local function lerp(a,b,t)return a+(b-a)*t end
local function seq(...)
 local a,k={...},{}
 for i=1,#a,2 do k[#k+1]=NumberSequenceKeypoint.new(a[i],a[i+1])end
 return NumberSequence.new(k)
end

local warned={}
local function safe(fn,...)
 local ok,err=pcall(fn,...)
 if not ok then
  local key=tostring(err)
  if not warned[key]then warned[key]=true warn("[MysteriousGuy] cosmetic FX error (gameplay unaffected): "..key)end
 end
end

local fxRoot
local function fxFolder()
 if fxRoot and fxRoot.Parent then return fxRoot end
 fxRoot=workspace:FindFirstChild("MysteriousGuyFX")
 if not fxRoot then
  fxRoot=Instance.new("Folder")
  fxRoot.Name="MysteriousGuyFX"
  fxRoot.Parent=workspace
 end
 return fxRoot
end

local function newPart(size,cf,color,material,transparency,shape)
 local p=Instance.new("Part")
 if shape then p.Shape=shape end
 p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Massless=true
 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 p.Material=material p.Color=color p.Transparency=transparency
 p.Size=size p.CFrame=cf
 return p
end

local function tween(obj,time,props,style,dir)
 local t=TweenService:Create(obj,TweenInfo.new(time,style or QUAD,dir or OUT),props)
 t:Play()
 return t
end

local function emitter(parent,props)
 local e=Instance.new("ParticleEmitter")
 e.LightInfluence=0
 e.Rotation=NumberRange.new(0,360)
 e.RotSpeed=NumberRange.new(-60,60)
 for k,v in pairs(props)do e[k]=v end
 e.Parent=parent
 return e
end

 
local function burst(pos,count,spec)
 local life=spec.life or NumberRange.new(.4,.8)
 local holder=newPart(Vector3.one*.2,CFrame.new(pos),PAL.Void,Enum.Material.SmoothPlastic,1)
 holder.Parent=fxFolder()
 local e=emitter(holder,{
  Texture=spec.texture or TEX_SPARK,
  Color=spec.color or ColorSequence.new(PAL.Pale,PAL.Violet),
  Size=spec.size or seq(0,.7,1,0),
  Transparency=spec.transparency or seq(0,0,.7,.25,1,1),
  Lifetime=life,
  Speed=spec.speed or NumberRange.new(10,26),
  SpreadAngle=Vector2.new(spec.spread or 180,spec.spread or 180),
  EmissionDirection=spec.dir or Enum.NormalId.Top,
  Acceleration=spec.accel or Vector3.zero,
  Drag=spec.drag or 2,
  LightEmission=spec.emission or 1,
  Rate=count/BURST_WINDOW,
 })
 task.delay(BURST_WINDOW,function()if e.Parent then e.Enabled=false end end)
 Debris:AddItem(holder,BURST_WINDOW+life.Max+.6)
end

local function sparkBurst(pos,count,speed)
 burst(pos,count,{size=seq(0,.8,1,0),life=NumberRange.new(.35,.8),speed=NumberRange.new(speed*.4,speed),accel=V3(0,-28,0),drag=1.5})
end

local function smokeBurst(pos,count,size)
 burst(pos,count,{
  texture=TEX_SMOKE,color=ColorSequence.new(PAL.Deep,PAL.Void),
  size=seq(0,size*.4,1,size),transparency=seq(0,.45,.6,.7,1,1),
  life=NumberRange.new(.7,1.2),speed=NumberRange.new(4,12),spread=70,
  accel=V3(0,2,0),drag=3,emission=.1,
 })
end

 
local function flash(pos,size,color,time,light)
 local p=newPart(Vector3.one*size*.25,CFrame.new(pos),color,Enum.Material.Neon,0,Enum.PartType.Ball)
 p.Parent=fxFolder()
 tween(p,time,{Size=Vector3.one*size,Transparency=1},QUART)
 if light then
  local l=Instance.new("PointLight")
  l.Color=color l.Range=math.min(size*2.4,40) l.Brightness=5 l.Shadows=false
  l.Parent=p
  tween(l,time,{Brightness=0})
 end
 Debris:AddItem(p,time+.15)
end

local function dome(pos,size,color,time)  
 local p=newPart(Vector3.one*size*.2,CFrame.new(pos),color,Enum.Material.ForceField,.1,Enum.PartType.Ball)
 p.Parent=fxFolder()
 tween(p,time,{Size=Vector3.one*size,Transparency=1},QUART)
 Debris:AddItem(p,time+.15)
end

local function streak(a,b,color,time,width)
 local d=(b-a).Magnitude
 if d<2 then return end
 local p=newPart(V3(width,width,d),CFrame.lookAt((a+b)/2,b),color,Enum.Material.Neon,.05)
 p.Parent=fxFolder()
 tween(p,time,{Size=V3(.06,.06,d),Transparency=1},QUAD)
 Debris:AddItem(p,time+.15)
end

local function sfxAt(id,pos,volume,pitch)
 if not id or id==""then return end
 local holder=newPart(Vector3.one*.2,CFrame.new(pos),PAL.Void,Enum.Material.SmoothPlastic,1)
 holder.Parent=fxFolder()
 local s=Instance.new("Sound")
 s.SoundId=id s.Volume=volume or .8 s.PlaybackSpeed=(pitch or 1)*(.95+math.random()*.1)
 s.RollOffMode=Enum.RollOffMode.InverseTapered s.RollOffMinDistance=16 s.RollOffMaxDistance=150
 s.Parent=holder
 s:Play()
 Debris:AddItem(holder,8)
end

local function sfxLoop(id,parent)
 if not id or id==""then return nil end
 local s=Instance.new("Sound")
 s.SoundId=id s.Looped=true s.Volume=0 s.PlaybackSpeed=.8
 s.RollOffMode=Enum.RollOffMode.InverseTapered s.RollOffMinDistance=16 s.RollOffMaxDistance=150
 s.Parent=parent
 s:Play()
 return s
end

 
local CinemaRemote=ReplicatedStorage:FindFirstChild("P35MysteriousGuyFX")
if not CinemaRemote then
 CinemaRemote=Instance.new("RemoteEvent")
 CinemaRemote.Name="P35MysteriousGuyFX"
 CinemaRemote.Parent=ReplicatedStorage
end
local function cinema(player,kind,arg)
 if S.ClientCinema and player and player.Parent then CinemaRemote:FireClient(player,kind,arg)end
end


local Visuals={Monster=Shared.ShadowMonster,Blast=Shared.ShadowBlast,UpdateBlast=Shared.UpdateShadowBlast,HideSword=Shared.HideSword,Pop=Shared.Pop,UpdatePop=Shared.UpdatePop,SweptDistance=Shared.SweptDistance,Safe=safe,Cinema=cinema,Folder=fxFolder}
function Visuals.Create(actor,core,ghost,charge,getVictim)
 local root=core.Root
 local FIST_NAMES=S.FistNames
 local rayParams=RaycastParams.new()rayParams.FilterType=Enum.RaycastFilterType.Exclude
 local bin,anchors={},{}
 local shadow,trail,wisps,motes,glow
 local orb,orbLight,aura,auraEmitter,chargeSound,hold
 local warnArmed,proxLevel,lastGround,rearmAt=true,-1,nil,nil
 local function own(i)bin[#bin+1]=i return i end
   local function findFist()
    if S.FistPart~="" then
     local named=actor:FindFirstChild(S.FistPart,true)
     if named and named:IsA("BasePart")then return named end
    end
    for _,n in ipairs(FIST_NAMES)do
     local p=actor:FindFirstChild(n,true)
     if p and p:IsA("BasePart")then return p end
    end
    return root
   end
   local function groundBelow(pos)
    local skip={actor,fxFolder()}
    if ghost and ghost.Model then skip[#skip+1]=ghost.Model end
    for _,c in ipairs(core.Characters())do skip[#skip+1]=c end
    rayParams.FilterDescendantsInstances=skip
    local res=workspace:Raycast(pos+V3(0,2,0),V3(0,-18,0),rayParams)
    return res and res.Position or pos-V3(0,3,0)
   end


   local function summonFX(point)
    local g=point+V3(0,.15,0)
    burst(point+V3(0,.6,0),30,{spread=24,speed=NumberRange.new(8,18),life=NumberRange.new(.6,1.1),
     accel=V3(0,5,0),size=seq(0,.55,1,0),color=ColorSequence.new(PAL.Violet,PAL.Void)})
    smokeBurst(point+V3(0,.4,0),12,3.2)
    sfxAt(S.Sounds.Summon,point,.8)
   end

   local function buildChaseFX(point)
    lastGround=point
     
    shadow=own(newPart(V3(.12,S.CatchRadius*2,S.CatchRadius*2),CFrame.new(point+V3(0,.1,0))*DISC,
     PAL.Void,Enum.Material.Neon,1,Enum.PartType.Cylinder))
    shadow.Parent=fxFolder()
    tween(shadow,S.SummonTime,{Transparency=.5})
     
    local a0=own(Instance.new("Attachment")) a0.Position=V3(0,2.3,0) a0.Parent=ghost.Root
    local a1=own(Instance.new("Attachment")) a1.Position=V3(0,-2.4,0) a1.Parent=ghost.Root
    trail=own(Instance.new("Trail"))
    trail.Attachment0=a0 trail.Attachment1=a1
    trail.Lifetime=.45 trail.MinLength=.1 trail.FaceCamera=true trail.LightEmission=.35 trail.LightInfluence=0
    trail.Color=ColorSequence.new(PAL.Deep,PAL.Void)
    trail.Transparency=seq(0,.55,1,1)
    trail.WidthScale=seq(0,1,1,0)
    trail.Parent=ghost.Root
    glow=own(Instance.new("PointLight"))
    glow.Color=PAL.Violet glow.Range=14 glow.Brightness=0 glow.Shadows=false
    glow.Parent=ghost.Root
    tween(glow,S.SummonTime,{Brightness=1.3})
    wisps=own(emitter(ghost.Root,{
     Texture=TEX_SMOKE,Color=ColorSequence.new(PAL.Deep,PAL.Void),Size=seq(0,1.3,1,3.4),
     Transparency=seq(0,.55,.4,.7,1,1),Lifetime=NumberRange.new(.7,1.2),Speed=NumberRange.new(1,3.5),
     SpreadAngle=Vector2.new(180,180),Acceleration=V3(0,2.5,0),Drag=1.5,LightEmission=.15,
     Rate=18,LockedToPart=false,Enabled=false,
    }))
    motes=own(emitter(ghost.Root,{
     Texture=TEX_SPARK,Color=ColorSequence.new(PAL.Pale,PAL.Violet),Size=seq(0,.35,1,0),
     Transparency=seq(0,0,.8,.3,1,1),Lifetime=NumberRange.new(.5,1),Speed=NumberRange.new(2,7),
     SpreadAngle=Vector2.new(180,180),Acceleration=V3(0,5,0),Drag=1,LightEmission=1,
     Rate=12,LockedToPart=false,Enabled=false,
    }))
   end

   local function huntFX()  
    local pos=ghost.Root.Position
    flash(pos,9,PAL.Violet,.3,true)
    sparkBurst(pos,16,16)
    if wisps then wisps.Enabled=true end
    if motes then motes.Enabled=true end
   end

   local function chaseFX(ground,r,dist,now)
    if not(shadow and glow)then return end
    lastGround=ground
    shadow.CFrame=CFrame.new(ground+V3(0,.1,0))*DISC
     
    local prox=math.clamp(1-(dist-S.CatchRadius)/(S.WarnDistance-S.CatchRadius),0,1)
    if ghost.SetAlert then ghost.SetAlert(prox)end  -- eyes and claws redden as it closes in
    local level=math.floor(prox*5+.5)
    if level~=proxLevel then
     proxLevel=level
     local a=level/5
     glow.Brightness=lerp(1.3,3.2,a)
     shadow.Color=PAL.Void:Lerp(PAL.Danger,a*.55)
    end
     
    if warnArmed and dist<S.WarnDistance then
     warnArmed=false
     sfxAt(S.Sounds.Warn,ghost.Root.Position,.55)
    elseif not warnArmed then
     if dist>S.WarnDistance*1.4 then warnArmed=true
     elseif rearmAt and now>=rearmAt and dist>S.CatchRadius*2.5 then warnArmed=true rearmAt=nil end
    end
   end


   local function seizeFX(char,fromCF,toCF)
    local r=char.HumanoidRootPart
    local pos=r.Position
    local g=groundBelow(pos)
     
    streak(fromCF.Position,toCF.Position,PAL.Pale,.3,1)
    flash(toCF.Position,8,PAL.Pale,.25,false)
     
    flash(pos,10,PAL.Violet,.32,true)
    sparkBurst(pos,28,26)
     
    hold=own(Instance.new("Attachment"))
    hold.Parent=r
    for i=1,4 do
     local ang=(i/4)*math.pi*2+math.random()*.6
     local anchor=own(newPart(Vector3.one*.2,CFrame.new(g+V3(math.cos(ang)*3.2,.2,math.sin(ang)*3.2)),
      PAL.Void,Enum.Material.SmoothPlastic,1))
     local from=Instance.new("Attachment")
     from.Parent=anchor
     anchor.Parent=fxFolder()
     local beam=Instance.new("Beam")
     beam.Attachment0=from beam.Attachment1=hold
     beam.Color=ColorSequence.new(PAL.Void,PAL.Violet)
     beam.Transparency=NumberSequence.new(.1)
     beam.LightEmission=.5 beam.LightInfluence=0 beam.FaceCamera=true beam.Segments=14
     beam.CurveSize0=(math.random()-.5)*7 beam.CurveSize1=(math.random()-.5)*7
     beam.Width0=0 beam.Width1=0
     beam.Parent=anchor
     tween(beam,.3,{Width0=.75,Width1=.3},QUART)
     anchors[#anchors+1]=anchor
    end
     
    sfxAt(S.Sounds.Seize,pos,1)
    core.ScreenEffect("Shake",{Origin=pos,Radius=70,Duration=.16,Intensity=.4})
    local victimPlayer=getVictim()
    if victimPlayer then cinema(victimPlayer,"Seize",charge)end
   end

   local function chargeFX()
    local fist=findFist()
    local offset=(fist==root)and V3(1.4,1,-2.6)or S.FistOffset
    orb=own(newPart(Vector3.one*.4,fist.CFrame*CFrame.new(offset),PAL.Pale,Enum.Material.Neon,.1,Enum.PartType.Ball))
    orb.Anchored=false
    orb.Parent=fxFolder()
    local w=Instance.new("WeldConstraint")
    w.Part0=fist w.Part1=orb w.Parent=orb
    aura=own(newPart(Vector3.one*9,orb.CFrame,PAL.Violet,Enum.Material.SmoothPlastic,1,Enum.PartType.Ball))
    aura.Anchored=false
    aura.Parent=fxFolder()
    local w2=Instance.new("WeldConstraint")
    w2.Part0=orb w2.Part1=aura w2.Parent=aura
     
    auraEmitter=emitter(aura,{
     Texture=TEX_SPARK,Color=ColorSequence.new(PAL.Pale,PAL.Violet),Size=seq(0,.45,1,.1),
     Transparency=seq(0,.1,.8,.2,1,1),Lifetime=NumberRange.new(.3,.45),Speed=NumberRange.new(-16,-11),
     Shape=Enum.ParticleEmitterShape.Sphere,ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface,
     ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward,LightEmission=1,Rate=10,
    })
    orbLight=Instance.new("PointLight")
    orbLight.Color=PAL.Violet orbLight.Range=20 orbLight.Brightness=0 orbLight.Shadows=false
    orbLight.Parent=orb
    tween(orb,charge,{Size=Vector3.one*3},QUAD,IN)
    tween(orbLight,charge,{Brightness=4.5},QUAD,IN)
    tween(auraEmitter,charge,{Rate=150},QUAD,IN)
    chargeSound=sfxLoop(S.Sounds.Charge,orb)
    if chargeSound then tween(chargeSound,charge,{Volume=.9,PlaybackSpeed=1.7},QUAD,IN)end
   end

   local function punchFX(impact,connected)
    local g=groundBelow(impact)
    local k=connected and 1 or .55  
     
    if orb then tween(orb,.12,{Size=Vector3.one*.3,Transparency=1})end
    if orbLight then tween(orbLight,.12,{Brightness=0})end
    if auraEmitter then auraEmitter.Enabled=false end
    if chargeSound then tween(chargeSound,.15,{Volume=0})Debris:AddItem(chargeSound,.3)chargeSound=nil end
    for _,a in ipairs(anchors)do
     local b=a:FindFirstChildOfClass("Beam")
     if b then tween(b,.12,{Width0=0,Width1=0})end
     Debris:AddItem(a,.2)
    end
    table.clear(anchors)
    if hold then Debris:AddItem(hold,.2)hold=nil end
     
    flash(impact,24*k,PAL.Pale,.42,true)
    dome(g,S.ShockRadius*2.2*k,PAL.Violet,.6)
    dome(g,S.ShockRadius*1.2*k,PAL.Danger,.35)
    sparkBurst(impact,math.floor(70*k),60)
    smokeBurst(g+V3(0,.5,0),math.floor(26*k),10)
    streak(impact,impact+V3(0,40*k,0),PAL.Pale,.4,2.2)
    sfxAt(S.Sounds.Punch,impact,connected and 1 or .6,connected and 1 or 1.25)
   end


 local fx={}
 fx.Summon=summonFX fx.BuildChase=buildChaseFX fx.Hunt=huntFX fx.Chase=chaseFX
 fx.Seize=seizeFX fx.Charge=chargeFX fx.Punch=punchFX
 function fx.Whiff(char,rearmTime)
  rearmAt=rearmTime

     local pos=char.HumanoidRootPart.Position
     local g=lastGround or groundBelow(pos)
     sparkBurst(pos,16,20)
     smokeBurst(ghost.Root.Position,8,3)
     sfxAt(S.Sounds.Whiff,pos,.8,1.1)

 end
 function fx.Dissolve()

     if wisps then wisps.Enabled=false end
     if motes then motes.Enabled=false end
     if trail then trail.Enabled=false end
     smokeBurst(ghost.Root.Position,24,5)
     sparkBurst(ghost.Root.Position,12,10)
     if shadow then tween(shadow,S.DissolveTime,{Transparency=1})end
     if glow then tween(glow,S.DissolveTime,{Brightness=0})end

 end
  -- a blink: the shadow tears forward along a pale streak, smoke left where it was
 function fx.Blink(fromPos,toPos)
  streak(fromPos,toPos,PAL.Pale,.28,1.2)
  streak(fromPos+V3(0,2.5,0),toPos+V3(0,2.5,0),PAL.Violet,.35,.7)
  smokeBurst(fromPos,10,4)
  flash(toPos+V3(0,2,0),9,PAL.Violet,.25,false)
  sparkBurst(toPos+V3(0,2,0),14,22)
  if trail then trail:Clear()end
 end
  -- no catch: the shadow collapses into a void and erupts
 function fx.Erupt(point)
  local g=groundBelow(point)
  flash(point,S.EruptRadius*1.3,PAL.Violet,.4,true)
  dome(g,S.EruptRadius*2.2,PAL.Violet,.55)
  sparkBurst(point,50,48)
  smokeBurst(g+V3(0,.5,0),22,9)
  core.ScreenEffect("Shake",{Origin=point,Radius=90,Duration=.3,Intensity=.7})
 end
 function fx.StopChase()
  if ghost.Cut then ghost.Cut()end
  if trail then trail.Enabled=false end
  if wisps then wisps.Enabled=false end
  if motes then motes.Enabled=false end
  if shadow then tween(shadow,.25,{Transparency=1})end
  if glow then tween(glow,.3,{Brightness=0})end
 end
 function fx.ClearTrail()if trail then trail:Clear()end end
 function fx.Clear()
  for _,i in ipairs(bin)do i:Destroy()end table.clear(bin)
 end
 return fx
end
return table.freeze(Visuals)
