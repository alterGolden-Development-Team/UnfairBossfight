local Fov=require(game.ReplicatedStorage.BossShared.Presentation.CameraFov)
if not game:GetService("RunService"):IsRunning() or not game:GetService("RunService"):IsClient() then return {} end
 
if not game:GetService("RunService"):IsClient() then return {} end



local CollectionService=game:GetService("CollectionService")
local Debris=game:GetService("Debris")
local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local UserInputService=game:GetService("UserInputService")

local Reset=require(game.ReplicatedStorage.BossShared.Presentation.CinematicReset)
local TAG="P5BlackHoleRoot"
local PULLED="BlackHolePulled"
local TAU=math.pi*2
local HALF_PI=math.pi/2
local localPlayer=Players.LocalPlayer

local CFG={
 Violet=Color3.fromRGB(132,72,255), Gold=Color3.fromRGB(255,185,62), Pale=Color3.fromRGB(235,220,255),
 Ember=Color3.fromRGB(255,110,40), Crimson=Color3.fromRGB(255,60,95), Void=Color3.new(0,0,0),
 Rock=Color3.fromRGB(38,32,48),
 Spark="rbxasset://textures/particles/sparkles_main.dds",
 Smoke="rbxasset://textures/particles/smoke_main.dds",
 RippleStart=115,    
 Sounds={Summon="",Loop="",Devour="",Collapse=""},
}

 
 
 
local Q=1
do
 local ok,level=pcall(function() return settings().Rendering.QualityLevel.Value end)
 if ok and type(level)=="number" and level>0 then Q=math.clamp(level/10,.35,1) end
 if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then Q=math.min(Q,.6) end
end
local MOTES=math.max(24,math.floor(64*Q))
local DEBRIS=math.max(16,math.floor(44*Q))
local ARCS=math.max(2,math.floor(5*Q))

 
 
 
local function smooth(t) t=math.clamp(t,0,1) return t*t*(3-2*t) end
local function lerp(a,b,t) return a+(b-a)*t end
local function rand(a,b) return a+(b-a)*math.random() end
local function kp(t,v) return NumberSequenceKeypoint.new(t,v) end
local function seq(...) return NumberSequence.new({...}) end

local folder=Instance.new("Folder") folder.Name="BlackHoleFX" folder.Parent=workspace

local function newPart(parent,name,shape,size,color,material,transparency)
 local p=Instance.new("Part")
 p.Name=name p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.CastShadow=false p.Massless=true
 p.Shape=shape p.Size=size p.Color=color p.Material=material p.Transparency=transparency or 0
 p.Parent=parent
 return p
end

local function tween(inst,time,props,style,dir)
 local t=TweenService:Create(inst,TweenInfo.new(time,style or Enum.EasingStyle.Quad,dir or Enum.EasingDirection.Out),props)
 t:Play()
 return t
end

local function flashBall(pos,color,r0,r1,time,transparency0,material)
 local p=newPart(folder,"BH_Flash",Enum.PartType.Ball,Vector3.one*r0*2,color,material or Enum.Material.Neon,transparency0 or 0)
 p.CFrame=CFrame.new(pos)
 tween(p,time,{Size=Vector3.one*r1*2,Transparency=1})
 Debris:AddItem(p,time+.1)
end

local function burstEmitter(pos,props,count,life)
 local p=newPart(folder,"BH_Burst",Enum.PartType.Block,Vector3.one*.4,Color3.new(),Enum.Material.SmoothPlastic,1)
 p.CFrame=CFrame.new(pos)
 local e=Instance.new("ParticleEmitter")
 e.Enabled=false e.Rate=0
 for k,v in pairs(props) do e[k]=v end
 e.Parent=p
 e:Emit(count)
 Debris:AddItem(p,life)
end

local SPARK={
 Texture=CFG.Spark, Color=ColorSequence.new(CFG.Gold,CFG.Pale), LightEmission=1,
 Lifetime=NumberRange.new(.7,1.4), Speed=NumberRange.new(60,200), SpreadAngle=Vector2.new(180,180), Drag=2.5,
 Size=seq(kp(0,1.5),kp(1,0)), Transparency=seq(kp(0,0),kp(1,1)),
}
local SMOKE={
 Texture=CFG.Smoke, Color=ColorSequence.new(Color3.fromRGB(80,62,115),Color3.fromRGB(28,22,44)), LightEmission=.25,
 Lifetime=NumberRange.new(1.2,2.2), Speed=NumberRange.new(25,70), SpreadAngle=Vector2.new(180,180), Drag=3,
 Rotation=NumberRange.new(0,360), RotSpeed=NumberRange.new(-60,60),
 Size=seq(kp(0,6),kp(1,22)), Transparency=seq(kp(0,.55),kp(1,1)),
}

local function playSound(id,pos,volume)
 if id==nil or id=="" then return end
 local p=newPart(folder,"BH_Sound",Enum.PartType.Block,Vector3.one*.2,Color3.new(),Enum.Material.SmoothPlastic,1)
 p.CFrame=CFrame.new(pos)
 local s=Instance.new("Sound")
 s.SoundId=id s.Volume=volume or 1 s.RollOffMode=Enum.RollOffMode.InverseTapered s.RollOffMaxDistance=450
 s.Parent=p s:Play()
 Debris:AddItem(p,12)
end

local function proximity(pos,range)
 local char=localPlayer.Character
 local hrp=char and char:FindFirstChild("HumanoidRootPart")
 if not hrp then return 0 end
 return 1-math.clamp((hrp.Position-pos).Magnitude/range,0,1)
end

 
 
 
local cc=Instance.new("ColorCorrectionEffect") cc.Name="BlackHoleCC" cc.Enabled=false cc.Parent=Lighting
local bloom=Instance.new("BloomEffect") bloom.Name="BlackHoleBloom" bloom.Size=28 bloom.Threshold=.9 bloom.Intensity=0 bloom.Enabled=false bloom.Parent=Lighting
local blur=Instance.new("BlurEffect") blur.Name="BlackHoleBlur" blur.Size=0 blur.Enabled=false blur.Parent=Lighting
local post={base=0,blur=0,rumble=0,fov=0,flash=0}
local fovState={written=-1,applied=0}

local function addFlash(v) post.flash=math.max(post.flash,v) end

local function resetView()
 local cam=workspace.CurrentCamera
 Fov.Clear(script)
 fovState.written=-1 fovState.applied=0
 post.base=0 post.blur=0 post.rumble=0 post.fov=0 post.flash=0
 cc.Enabled=false bloom.Enabled=false blur.Enabled=false
end
local function applyPost(dt,agg)
 if not Reset.ViewAllowed() then resetView() return end
 local a=1-math.exp(-dt*6)
 post.base=lerp(post.base,agg.base,a) post.blur=lerp(post.blur,agg.blur,a)
 post.rumble=lerp(post.rumble,agg.rumble,a) post.fov=lerp(post.fov,agg.fov,a)
 post.flash=math.max(0,post.flash-dt*1.8)
 local b,f=post.base,post.flash
 local on=b>.004 or f>.004
 cc.Enabled=on bloom.Enabled=on
 if on then
  cc.Brightness=-.05*b+.45*f
  cc.Contrast=.2*b
  cc.Saturation=-.3*b+.25*f
  cc.TintColor=Color3.new(1,1,1):Lerp(Color3.fromRGB(205,190,255),math.clamp(b*.8,0,1))
  bloom.Intensity=.35*b+1.1*f
 end
 blur.Enabled=post.blur>.05
 blur.Size=post.blur
end

local function applyCamera(now)
 if not Reset.ViewAllowed() then return end
 local cam=workspace.CurrentCamera
 if not cam then return end
  
 local offset=post.fov
 Fov.Set(script,offset)

 local r=post.rumble
 if r>.003 then
  cam.CFrame=cam.CFrame*CFrame.Angles(
   math.noise(now*23,1.3)*r*.035,math.noise(now*19,7.1)*r*.035,math.noise(now*27,3.7)*r*.018)
 end
end

 
 
 
local function makeRingPart(parent,color,thickness)
 local p=newPart(parent,"GravityRing",Enum.PartType.Cylinder,Vector3.new(.2,8,8),Color3.new(1,1,1),Enum.Material.SmoothPlastic,1)
 local strokes={}
 for _,face in ipairs({Enum.NormalId.Right,Enum.NormalId.Left}) do
  local sg=Instance.new("SurfaceGui")
  sg.Face=face sg.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize sg.CanvasSize=Vector2.new(512,512)
  sg.LightInfluence=0 sg.Brightness=2 sg.Parent=p
  local f=Instance.new("Frame") f.BackgroundTransparency=1 f.Size=UDim2.fromScale(1,1) f.Parent=sg
  local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(.5,0) corner.Parent=f
  local stroke=Instance.new("UIStroke") stroke.Thickness=thickness or 10 stroke.Color=color stroke.Transparency=1 stroke.Parent=f
  strokes[#strokes+1]=stroke
 end
 return {part=p,strokes=strokes}
end

 
local function setRing(ring,center,radius,alpha)
 radius=math.max(radius,.5)
 ring.part.Size=Vector3.new(.2,radius*2,radius*2)
 ring.part.CFrame=CFrame.new(center)*CFrame.Angles(0,0,HALF_PI)
 for _,s in ipairs(ring.strokes) do s.Transparency=1-math.clamp(alpha,0,1) end
end

 
local ringPool={}
local function spawnRing(opt)
 local r
 for _,e in ipairs(ringPool) do if not e.active then r=e break end end
 if not r then
  if #ringPool>=20 then return end
  r=makeRingPart(folder,CFG.Violet,10)
  ringPool[#ringPool+1]=r
 end
 r.active=true r.t0=os.clock() r.life=opt.life r.r0=opt.r0 r.r1=opt.r1
 r.mode=opt.mode or "fade" r.peak=opt.peak or .9 r.pos=opt.pos r.follow=opt.follow
 for _,s in ipairs(r.strokes) do s.Color=opt.color s.Thickness=opt.thick or 10 s.Transparency=1 end
 r.part.Parent=folder
end

local function updateRings(now)
 for _,r in ipairs(ringPool) do
  if r.active then
   local a=(now-r.t0)/r.life
   if a>=1 or (r.follow and r.follow.dead) then
    r.active=false r.part.Parent=nil
   else
    local radius,alpha
    if r.mode=="pulse" then
     radius=lerp(r.r0,r.r1,a*a) alpha=r.peak*math.sin(a*math.pi)
    else
     radius=lerp(r.r0,r.r1,1-(1-a)*(1-a)) alpha=r.peak*(1-a)
    end
    local p=r.pos
    if r.follow then p=Vector3.new(r.follow.pos.X,r.follow.groundY+.15,r.follow.pos.Z) end
    setRing(r,p,radius,alpha)
   end
  end
 end
end

 
 
 
local function makeMote(parent)
 local roll=math.random()
 local c0,c1
 if roll<.45 then c0,c1=CFG.Gold,CFG.Ember elseif roll<.8 then c0,c1=CFG.Violet,CFG.Pale else c0,c1=CFG.Pale,CFG.Violet end
 local p=newPart(parent,"Mote",Enum.PartType.Ball,Vector3.one*.9,c0,Enum.Material.Neon,0)
 local a0=Instance.new("Attachment") a0.Position=Vector3.new(0,.7,0) a0.Parent=p
 local a1=Instance.new("Attachment") a1.Position=Vector3.new(0,-.7,0) a1.Parent=p
 local tr=Instance.new("Trail")
 tr.Attachment0=a0 tr.Attachment1=a1 tr.Lifetime=.8 tr.MinLength=.08 tr.FaceCamera=true
 tr.LightEmission=1 tr.LightInfluence=0
 tr.Color=ColorSequence.new(c0,c1)
 tr.Transparency=seq(kp(0,.05),kp(1,1))
 tr.WidthScale=seq(kp(0,1),kp(1,0))
 tr.Parent=p
 return {part=p,trail=tr,r=0,a=0,h=0,hold=0,dead=false}
end

local function makeDebris(parent)
 local p=newPart(parent,"Debris",Enum.PartType.Block,Vector3.one*2,CFG.Rock,Enum.Material.Slate,1)
 return {part=p,r=0,r0=1,a=0,h0=1,s=2,hot=false,dead=false}
end

 
 
 
local Hole={}
Hole.__index=Hole
local holes={}

function Hole.new(root)
 local sNow=workspace:GetServerTimeNow()
 local function a(n,d) local v=root:GetAttribute(n) if v==nil then return d end return v end
 local self=setmetatable({
  root=root, core=a("Core",16), pull=a("Pull",190), sky=a("Sky",90), hover=a("Hover",14),
  summonT=a("SummonT",2.2), activeT=a("ActiveT",9), fadeT=a("FadeT",1.6), shockR=a("ShockR",42),
  armT=a("ArmT",.55), foot=a("Foot",11.6), burstAt=a("BurstAt",.62), born=a("Born",sNow),
  pos=root.Position, tethers={}, arcs={}, motes={}, debris={}, conns={},
  landed=false, finished=false, dead=false, rippleClock=0, lastR=-1, ringsShown=true, debrisOn=false,
  moteParts={}, moteCFs={}, hot=false,
 },Hole)
 self.groundY=a("GroundY",self.pos.Y-self.hover-self.sky)
 self.debrisR=math.min(self.pull*.62,125)

 local stage=a("Stage","Summon")
 if stage=="Collapse" then
  local c=(sNow-a("CollapseAt",sNow))/self.fadeT
  if c>=self.burstAt then return nil end  
 end
 if stage~="Summon" then self.landed=true end

 root.LocalTransparencyModifier=1  
 local m=Instance.new("Folder") m.Name="BlackHole" m.Parent=folder
 self.model=m
 local W=Enum.PartType

  
 self.coreP=newPart(m,"EventHorizon",W.Ball,Vector3.one,CFG.Void,Enum.Material.SmoothPlastic,0)
 self.corona=newPart(m,"Corona",W.Ball,Vector3.one,CFG.Violet,Enum.Material.ForceField,.62)
 self.photonHot=newPart(m,"PhotonHot",W.Cylinder,Vector3.new(.2,1,1),Color3.fromRGB(255,244,220),Enum.Material.Neon,0)
 self.photonGlow=newPart(m,"PhotonGlow",W.Cylinder,Vector3.new(.2,1,1),CFG.Gold,Enum.Material.Neon,.35)
  
 self.haze1=newPart(m,"Haze1",W.Cylinder,Vector3.new(.3,1,1),CFG.Violet,Enum.Material.Neon,.9)
 self.haze2=newPart(m,"Haze2",W.Cylinder,Vector3.new(.3,1,1),CFG.Gold,Enum.Material.Neon,.86)
 self.jetCore=newPart(m,"JetCore",W.Cylinder,Vector3.new(1,1,1),CFG.Pale,Enum.Material.Neon,1)
 self.jetGlow=newPart(m,"JetGlow",W.Cylinder,Vector3.new(1,1,1),CFG.Violet,Enum.Material.Neon,1)
 self.column=newPart(m,"SummonColumn",W.Cylinder,Vector3.new(1,1,1),CFG.Gold,Enum.Material.Neon,.6)
 self.footFill=newPart(m,"LethalFill",W.Cylinder,Vector3.new(.1,1,1),CFG.Crimson,Enum.Material.Neon,1)
 self.footRing=makeRingPart(m,CFG.Crimson,14)
 self.shockRing=makeRingPart(m,CFG.Gold,8)
 self.targetRing=makeRingPart(m,CFG.Pale,10)

  
 self.shell=newPart(m,"Shell",W.Ball,Vector3.one,CFG.Void,Enum.Material.SmoothPlastic,1)
 local shellEm=Instance.new("ParticleEmitter")
 shellEm.Texture=CFG.Spark shellEm.Color=ColorSequence.new(CFG.Gold,CFG.Pale) shellEm.LightEmission=1
 shellEm.Rate=0 shellEm.Lifetime=NumberRange.new(.45,.8) shellEm.Speed=NumberRange.new(-100,-70)
 shellEm.Shape=Enum.ParticleEmitterShape.Sphere shellEm.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
 shellEm.ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward
 shellEm.Size=seq(kp(0,.55),kp(1,0)) shellEm.Transparency=seq(kp(0,.1),kp(1,1))
 shellEm.Parent=self.shell
 self.shellEm=shellEm

  
 local jetEm=Instance.new("ParticleEmitter")
 jetEm.Texture=CFG.Spark jetEm.Color=ColorSequence.new(CFG.Pale,CFG.Violet) jetEm.LightEmission=1
 jetEm.Rate=70*Q jetEm.Lifetime=NumberRange.new(.4,.8) jetEm.Speed=NumberRange.new(45,90)
 jetEm.EmissionDirection=Enum.NormalId.Right jetEm.SpreadAngle=Vector2.new(3,3)
 jetEm.Size=seq(kp(0,1.4),kp(1,0)) jetEm.Transparency=seq(kp(0,.1),kp(1,1)) jetEm.Enabled=false
 jetEm.Parent=self.jetGlow
 self.jetEm=jetEm

  
 self.dustP=newPart(m,"Dust",W.Block,Vector3.new(self.foot*2.8,.4,self.foot*2.8),CFG.Void,Enum.Material.SmoothPlastic,1)
 local dustEm=Instance.new("ParticleEmitter")
 dustEm.Texture=CFG.Smoke dustEm.Color=ColorSequence.new(Color3.fromRGB(95,75,130),Color3.fromRGB(35,28,55))
 dustEm.LightEmission=.3 dustEm.Rate=22*Q dustEm.Lifetime=NumberRange.new(1.6,2.6)
 dustEm.Speed=NumberRange.new(2,8) dustEm.Acceleration=Vector3.new(0,12,0)
 dustEm.Rotation=NumberRange.new(0,360) dustEm.RotSpeed=NumberRange.new(-40,40)
 dustEm.Size=seq(kp(0,7),kp(1,18)) dustEm.Transparency=seq(kp(0,.75),kp(1,1)) dustEm.Enabled=false
 dustEm.Parent=self.dustP
 self.dustEm=dustEm

  
 self.skyP=newPart(m,"SkyTrail",W.Block,Vector3.one*.2,CFG.Void,Enum.Material.SmoothPlastic,1)
 self.skyA0=Instance.new("Attachment") self.skyA0.Parent=self.skyP
 self.skyA1=Instance.new("Attachment") self.skyA1.Parent=self.skyP
 local skyTrail=Instance.new("Trail")
 skyTrail.Attachment0=self.skyA0 skyTrail.Attachment1=self.skyA1 skyTrail.Lifetime=.55 skyTrail.MinLength=.1
 skyTrail.FaceCamera=true skyTrail.LightEmission=1 skyTrail.LightInfluence=0
 skyTrail.Color=ColorSequence.new(CFG.Pale,CFG.Gold) skyTrail.Transparency=seq(kp(0,.2),kp(1,1))
 skyTrail.WidthScale=seq(kp(0,1),kp(1,.1)) skyTrail.Parent=self.skyP
 self.skyTrail=skyTrail

  
 self.haloP=newPart(m,"Halo",W.Block,Vector3.one*.2,CFG.Void,Enum.Material.SmoothPlastic,1)
 local bb=Instance.new("BillboardGui")
 bb.Size=UDim2.fromScale(10,10) bb.AlwaysOnTop=false bb.LightInfluence=0 bb.Brightness=2 bb.Parent=self.haloP
 for i=1,9 do
  local k=1-(i-1)*.1
  local f=Instance.new("Frame")
  f.AnchorPoint=Vector2.new(.5,.5) f.Position=UDim2.fromScale(.5,.5) f.Size=UDim2.fromScale(k,k)
  f.BackgroundColor3=i<=5 and CFG.Violet or CFG.Gold f.BackgroundTransparency=.97-(i-1)*.03 f.BorderSizePixel=0
  local corner=Instance.new("UICorner") corner.CornerRadius=UDim.new(.5,0) corner.Parent=f
  f.Parent=bb
 end
 self.halo=bb

  
 for i=1,MOTES do
  local mote=makeMote(m)
  mote.r=self.core*rand(1.2,3.5) mote.a=rand(0,TAU) mote.h=rand(-.06,.06)
  self.motes[i]=mote self.moteParts[i]=mote.part self.moteCFs[i]=CFrame.new(root.Position)
 end
  
 for i=1,DEBRIS do
  local d=makeDebris(m)
  d.r=rand(.35,1)*self.debrisR d.r0=d.r d.a=rand(0,TAU) d.h0=rand(.4,3) d.s=rand(1.2,3.4)
  self.debris[i]=d
 end
  
 for i=1,ARCS do
  local a0=Instance.new("Attachment") a0.Parent=workspace.Terrain
  local a1=Instance.new("Attachment") a1.Parent=workspace.Terrain
  local beam=Instance.new("Beam")
  beam.Attachment0=a0 beam.Attachment1=a1 beam.FaceCamera=true beam.LightEmission=1 beam.LightInfluence=0
  beam.Segments=14 beam.Width0=1.8 beam.Width1=.25 beam.Color=ColorSequence.new(CFG.Pale,CFG.Violet)
  beam.Transparency=NumberSequence.new(.1) beam.Enabled=false beam.Parent=m
  self.arcs[i]={a0=a0,a1=a1,beam=beam,t=rand(0,.25),dir=Vector3.xAxis}
 end

 if CFG.Sounds.Loop~="" then
  local s=Instance.new("Sound")
  s.SoundId=CFG.Sounds.Loop s.Looped=true s.Volume=.8 s.RollOffMode=Enum.RollOffMode.InverseTapered s.RollOffMaxDistance=450
  s.Parent=self.coreP s:Play()
  self.loop=s
 end
 playSound(CFG.Sounds.Summon,self.pos)

 self.conns[#self.conns+1]=root:GetAttributeChangedSignal("Devoured"):Connect(function() self:Devour() end)
 self.conns[#self.conns+1]=root.AncestryChanged:Connect(function(_,parent) if not parent then self:Destroy(true) end end)
 return self
end

 
function Hole:Land()
 local pos=self.pos
 local gp=Vector3.new(pos.X,self.groundY+.15,pos.Z)
 flashBall(pos,CFG.Pale,self.core*.7,self.core*3,.3,.15)
 spawnRing{pos=gp,r0=self.foot,r1=self.shockR*2.4,life=.75,color=CFG.Gold,thick=14,peak=1}
 spawnRing{pos=gp,r0=self.foot*.6,r1=self.shockR*1.5,life=.5,color=CFG.Crimson,thick=10,peak=1}
 burstEmitter(gp,SMOKE,math.floor(46*Q),3.5)
 burstEmitter(pos,SPARK,math.floor(90*Q),2.5)
 self.column.Transparency=1
 self.skyTrail.Enabled=false
 addFlash(.35*proximity(pos,self.pull))
end

 
function Hole:Devour()
 local at=self.root:GetAttribute("DevourPos") or self.pos
 flashBall(at,CFG.Pale,1,9,.3,.1)
 flashBall(at,CFG.Violet,1,16,.45,.4)
 spawnRing{pos=Vector3.new(at.X,self.groundY+.15,at.Z),r0=3,r1=34,life=.5,color=CFG.Crimson,thick=10,peak=1}
 burstEmitter(at,SPARK,math.floor(40*Q),1.8)
 addFlash(.2*proximity(at,60))
 playSound(CFG.Sounds.Devour,at)
end

 
function Hole:Supernova()
 if self.finished then return end
 self.finished=true
 self.model.Parent=nil  
 local pos,core,gy=self.pos,self.core,self.groundY
 local gp=Vector3.new(pos.X,gy+.15,pos.Z)
 flashBall(pos,CFG.Pale,core*.4,core*5,.35,0)
 flashBall(pos,CFG.Gold,core*.3,core*9,.55,.1)
 flashBall(pos,CFG.Violet,core*.6,self.pull*.5,.9,.35)
 local pillar=newPart(folder,"BH_Pillar",Enum.PartType.Cylinder,Vector3.new(420,core*.9,core*.9),CFG.Pale,Enum.Material.Neon,.05)
 pillar.CFrame=CFrame.new(pos.X,gy+210,pos.Z)*CFrame.Angles(0,0,HALF_PI)
 tween(pillar,.9,{Size=Vector3.new(420,.5,.5),Transparency=1},Enum.EasingStyle.Sine)
 Debris:AddItem(pillar,1)
 spawnRing{pos=gp,r0=self.foot,r1=self.pull*.7,life=1.1,color=CFG.Pale,thick=14,peak=1}
 spawnRing{pos=gp,r0=self.foot*.6,r1=self.pull*.45,life=.8,color=CFG.Gold,thick=10,peak=1}
 spawnRing{pos=gp,r0=self.foot*.3,r1=self.pull*.9,life=1.5,color=CFG.Violet,thick=6,peak=.7}
 burstEmitter(pos,SPARK,math.floor(220*Q),2.2)
 burstEmitter(gp,SMOKE,math.floor(60*Q),3.5)
 addFlash(math.clamp(proximity(pos,self.pull*1.1)*1.2+.25,.25,1))
 playSound(CFG.Sounds.Collapse,pos)
 if self.loop then self.loop:Stop() end
end

local function destroyTether(t)
 t.beam:Destroy() t.a0:Destroy() t.a1:Destroy()
end

function Hole:Destroy(abort)
 if self.dead then return end
 self.dead=true
 for _,c in ipairs(self.conns) do c:Disconnect() end
 if abort and not self.finished then  
  flashBall(self.pos,CFG.Pale,self.core*.9,self.core*.15,.25,.2)
  spawnRing{pos=Vector3.new(self.pos.X,self.groundY+.15,self.pos.Z),r0=self.core*2,r1=self.core*.4,life=.3,color=CFG.Violet,peak=1}
 end
 for _,t in pairs(self.tethers) do destroyTether(t) end
 for _,arc in ipairs(self.arcs) do arc.a0:Destroy() arc.a1:Destroy() end
 self.model:Destroy()
end

function Hole:Step(dt,now,agg)
 if self.dead or self.finished then return end
 local root=self.root
 if not root.Parent then self:Destroy(true) return end
 local sNow=workspace:GetServerTimeNow()
 self.pos=self.pos:Lerp(root.Position,1-math.exp(-dt*20))
 self.groundY=root:GetAttribute("GroundY") or self.groundY
 local stage=root:GetAttribute("Stage") or "Summon"
 local power=root:GetAttribute("Power") or 1
 local elapsed=sNow-self.born
 local active=elapsed-self.summonT
 local pos,core,gy=self.pos,self.core,self.groundY

  
 local scale,presence,spin,infall,jet,footAlpha,shockAlpha,targetAlpha=1,1,1,1,0,0,0,0
 local summonP=smooth(elapsed/self.summonT)
 local collapsing,hunting=false,false
 if stage=="Summon" then
  scale=.2+.8*summonP presence=summonP*.7 spin=.5+.5*summonP infall=.35
  footAlpha=.3+.7*summonP shockAlpha=.35+.4*summonP targetAlpha=summonP
 elseif stage=="Hunt" then
  hunting=true
  if not self.landed then self.landed=true self:Land() end
  spin=power infall=power jet=smooth(active/.9)
  local arm=1-math.clamp(active/(self.armT+.4),0,1)
  footAlpha=.5+.5*arm shockAlpha=arm*.9
 else
  collapsing=true hunting=true
  local c=math.clamp((sNow-(root:GetAttribute("CollapseAt") or sNow))/self.fadeT,0,1)
  if c>=self.burstAt then self:Supernova() return end
  local k=c/self.burstAt
  scale=lerp(1,.22,smooth(k)) spin=1+6*k*k infall=1+10*k
  jet=1-smooth(k*1.4) footAlpha=1-smooth(k*2)
 end

  
 local close=proximity(pos,self.pull)
 local char=localPlayer.Character
 agg.base=math.max(agg.base,presence*(.3+.7*close^.8))
 agg.rumble=math.max(agg.rumble,presence*close^1.5*(stage=="Summon" and .5 or 1))
 if char and char:GetAttribute(PULLED)==true then
  agg.blur=math.max(agg.blur,9*close^2)
  agg.fov=math.max(agg.fov,11*close^1.4)
 end

 local R=core*scale
 local frame=CFrame.new(pos)*CFrame.Angles(.2*math.sin(now*.45),0,.2*math.cos(now*.37))
 local centerCF=CFrame.new(pos)

  
 if R~=self.lastR then
  self.lastR=R
  self.coreP.Size=Vector3.one*R*2
  self.corona.Size=Vector3.one*R*2.14
  self.shell.Size=Vector3.one*math.max(1,core*6*scale)
  self.halo.Size=UDim2.fromScale(R*14,R*14)
 end
 self.coreP.CFrame=centerCF self.corona.CFrame=centerCF self.shell.CFrame=centerCF self.haloP.CFrame=centerCF
 self.corona.Transparency=.62+.12*math.sin(now*7)
 self.shellEm.Rate=110*Q*scale*(stage=="Summon" and .5 or 1)

  
 local cam=workspace.CurrentCamera
 local camPos=cam.CFrame.Position
 local toCam=camPos-pos
 local dc=toCam.Magnitude
 local showRings=dc>R*1.15
 if showRings then
  local away=-toCam.Unit
  local ang=math.asin(math.min(R/dc,.98))
  local function place(part,mult,behind)
   local rad=(dc+R*behind)*math.tan(math.min(ang*mult,1.45))
   part.Size=Vector3.new(.25,rad*2,rad*2)
   part.CFrame=CFrame.lookAt(pos+away*(R*behind),camPos)*CFrame.Angles(0,HALF_PI,0)
  end
  place(self.photonHot,1.045,.5)
  place(self.photonGlow,1.2,.55)
  self.photonGlow.Transparency=.35+.15*math.sin(now*5)
  self.photonHot.Transparency=0
 else
  self.photonHot.Transparency=1 self.photonGlow.Transparency=1
 end

  
 local flatCF=frame*CFrame.Angles(0,0,HALF_PI)
 self.haze1.Size=Vector3.new(.3,R*6.2,R*6.2) self.haze1.CFrame=flatCF
 self.haze2.Size=Vector3.new(.3,R*4.2,R*4.2) self.haze2.CFrame=flatCF
 self.haze1.Transparency=.9+.04*math.sin(now*3) self.haze2.Transparency=.86+.04*math.sin(now*4+1)

  
 local jetLen=math.max(.5,72*jet)
 local w=1.2+.5*math.noise(now*9,2.2)
 self.jetCore.Size=Vector3.new(jetLen,w,w) self.jetGlow.Size=Vector3.new(jetLen,w*4.2,w*4.2)
 local jetCF=frame*CFrame.new(0,R*.85+jetLen/2,0)*CFrame.Angles(0,0,HALF_PI)
 self.jetCore.CFrame=jetCF self.jetGlow.CFrame=jetCF
 local jetVisible=jet>.03
 self.jetCore.Transparency=jetVisible and .12 or 1
 self.jetGlow.Transparency=jetVisible and .78 or 1
 self.jetEm.Enabled=jet>.3

  
 if stage=="Summon" then
  local colLen=math.max(pos.Y-gy,.1)
  local cw=2+core*.3*(.6+.4*math.sin(now*14))
  self.column.Size=Vector3.new(colLen,cw,cw)
  self.column.CFrame=CFrame.new(pos.X,gy+colLen/2,pos.Z)*CFrame.Angles(0,0,HALF_PI)
  self.column.Transparency=.55+.4*(1-summonP)
  self.skyP.CFrame=centerCF
  self.skyA0.Position=Vector3.new(-R*.95,0,0) self.skyA1.Position=Vector3.new(R*.95,0,0)
 end

  
 local gc=Vector3.new(pos.X,gy+.12,pos.Z)
 local pulse=stage=="Summon" and (2+8*summonP) or 3
 local fillBase=stage=="Summon" and .82 or .88
 self.footFill.Size=Vector3.new(.1,self.foot*2,self.foot*2)
 self.footFill.CFrame=CFrame.new(gc)*CFrame.Angles(0,0,HALF_PI)
 self.footFill.Transparency=1-(1-fillBase)*footAlpha*(.7+.3*math.sin(now*pulse*TAU/2))
 setRing(self.footRing,gc,self.foot,footAlpha*(.75+.25*math.sin(now*pulse*TAU/2)))
 setRing(self.shockRing,gc,self.shockR,shockAlpha*.7)
 setRing(self.targetRing,gc,lerp(self.shockR*2.2,self.foot,smooth(targetAlpha)),stage=="Summon" and targetAlpha*.9 or 0)

  
 local spinBase=4.4*spin
 local motes=self.motes
 for i=1,#motes do
  local mote=motes[i]
  if not mote.dead then
   local r=mote.r
   local ratio=core/math.max(r,core*.5)
   mote.a+=spinBase*ratio^1.5*dt
   r-=dt*core*(.2+.55*ratio*ratio)*infall
   if r<core*1.02 then
    if collapsing then
     mote.dead=true mote.trail.Enabled=false mote.part.Transparency=1
    else
     r=core*rand(2.9,3.5) mote.a=rand(0,TAU) mote.h=rand(-.06,.06) mote.hold=3 mote.trail.Enabled=false
    end
   end
   mote.r=r
   if mote.hold>0 then
    mote.hold-=1
    if mote.hold==0 then mote.trail.Enabled=true end
   end
   local rr=r*scale
   self.moteCFs[i]=frame*CFrame.new(math.cos(mote.a)*rr,mote.h*rr,math.sin(mote.a)*rr)
  end
 end
 workspace:BulkMoveTo(self.moteParts,self.moteCFs,Enum.BulkMoveMode.FireCFrameChanged)

  
 if hunting then
  if not self.debrisOn then
   self.debrisOn=true
   for _,d in ipairs(self.debris) do d.part.Transparency=0 end
  end
  for _,d in ipairs(self.debris) do
   if not d.dead then
    local r=d.r
    local ratio=core/math.max(r,core*.6)
    local vr=(16+240*ratio*ratio)*infall
    d.a+=2.4*ratio^1.2*spin*dt
    r-=vr*dt
    if r<core*.9 then
     if collapsing then
      d.dead=true d.part.Transparency=1
     else
      r=rand(.35,1)*self.debrisR d.r0=r d.a=rand(0,TAU) d.h0=rand(.4,3) d.s=rand(1.2,3.4)
     end
    end
    if not d.dead then
     d.r=r
     local t=1-math.clamp((r-core)/math.max(d.r0-core,1),0,1)
     local h=d.h0+(self.hover-d.h0)*t*t
     local ca,sa=math.cos(d.a),math.sin(d.a)
     local wp=Vector3.new(pos.X+ca*r,gy+h,pos.Z+sa*r)
     local vel=Vector3.new(-ca,0,-sa)*vr+Vector3.new(-sa,0,ca)*(2.4*ratio^1.2*spin*r)
     local speed=math.max(vel.Magnitude,.01)
     local stretch=math.clamp(speed/35,0,7)
     d.part.Size=Vector3.new(d.s,d.s*.75,d.s*(1+stretch))
     d.part.CFrame=CFrame.lookAt(wp,wp+vel/speed)
     local heat=1-math.clamp((r-core)/(core*2.5),0,1)
     d.part.Color=CFG.Rock:Lerp(CFG.Ember,heat)
     local hot=heat>.45
     if hot~=d.hot then
      d.hot=hot
      d.part.Material=hot and Enum.Material.Neon or Enum.Material.Slate
     end
    end
   end
  end
 end

  
 local live=stage=="Hunt"
 self.dustEm.Enabled=live
 self.dustP.CFrame=CFrame.new(pos.X,gy+.4,pos.Z)
 if live and active>self.armT then
  self.rippleClock+=dt
  if self.rippleClock>=.55 then
   self.rippleClock=0
   spawnRing{follow=self,r0=math.min(self.pull*.7,CFG.RippleStart),r1=self.foot*.8,life=1.5,color=CFG.Violet,mode="pulse",peak=.55,thick=9}
  end
 end

 for _,arc in ipairs(self.arcs) do
  if live then
   arc.t-=dt
   if arc.t<=0 then
    arc.t=rand(.1,.26)
    local ang=rand(0,TAU)
    local rr=core*rand(1.3,3.2)
    local target=Vector3.new(pos.X+math.cos(ang)*rr,gy+.3,pos.Z+math.sin(ang)*rr)
    arc.dir=(target-pos).Unit
    arc.a1.WorldPosition=target
    arc.beam.CurveSize0=rand(-1,1)*core*1.2 arc.beam.CurveSize1=rand(-1,1)*core*.9
    arc.beam.Width0=rand(1.2,2.4)
    arc.beam.Enabled=true
   end
   arc.a0.WorldPosition=pos+arc.dir*R*.95
  else
   arc.beam.Enabled=false
  end
 end

 for _,plr in ipairs(Players:GetPlayers()) do
  local pc=plr.Character
  local hrp=live and pc and pc:GetAttribute(PULLED)==true and pc:FindFirstChild("HumanoidRootPart") or nil
  local tether=self.tethers[plr]
  if hrp then
   if tether and tether.root~=hrp then destroyTether(tether) tether=nil end
   if not tether then
    local a0=Instance.new("Attachment") a0.Parent=workspace.Terrain
    local a1=Instance.new("Attachment") a1.Parent=hrp
    local beam=Instance.new("Beam")
    beam.Attachment0=a0 beam.Attachment1=a1 beam.FaceCamera=true beam.LightEmission=1 beam.LightInfluence=0
    beam.Segments=20 beam.Color=ColorSequence.new(CFG.Gold,CFG.Violet) beam.Parent=self.model
    tether={a0=a0,a1=a1,beam=beam,root=hrp,seed=math.random()*10}
    self.tethers[plr]=tether
   end
   local c=1-math.clamp((hrp.Position-pos).Magnitude/self.pull,0,1)
   tether.a0.WorldPosition=pos
   tether.beam.Width0=lerp(.6,3.4,c) tether.beam.Width1=lerp(.15,.8,c)
   tether.beam.CurveSize0=math.sin(now*6+tether.seed)*core*.8
   tether.beam.CurveSize1=math.cos(now*5+tether.seed)*core*.6
   tether.beam.Transparency=NumberSequence.new(lerp(.78,.1,c))
  elseif tether then
   destroyTether(tether) self.tethers[plr]=nil
  end
 end
end

 
 
 
local function onRoot(root)
 if holes[root] then return end
 local hole=Hole.new(root)
 if hole then holes[root]=hole end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(onRoot)
for _,root in ipairs(CollectionService:GetTagged(TAG)) do task.spawn(onRoot,root) end

RunService:BindToRenderStep("BlackHoleFX",Enum.RenderPriority.Camera.Value+1,function(dt)
 local now=os.clock()
 local agg={base=0,blur=0,rumble=0,fov=0}
 local gone
 for root,hole in pairs(holes) do
  hole:Step(dt,now,agg)
  if hole.dead then gone=gone or {} gone[#gone+1]=root end
 end
 if gone then for _,root in ipairs(gone) do holes[root]=nil end end
 updateRings(now)
 applyPost(dt,agg)
 applyCamera(now)
end)

 
local Client={}
function Client.Clear()
 for root,hole in pairs(holes)do
  hole:Destroy(false)
  if root.Parent then root.LocalTransparencyModifier=0 end
  holes[root]=nil
 end
 for _,r in ipairs(ringPool)do if r.part then r.part:Destroy()end end
 table.clear(ringPool)
 for _,child in ipairs(folder:GetChildren())do child:Destroy()end
 resetView()
end
Client.ResetView=resetView
Reset.Register(script,Client.Clear,Client.ResetView)
return Client
