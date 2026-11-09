local Fov=require(game.ReplicatedStorage.BossShared.Presentation.CameraFov)
if not game:GetService("RunService"):IsRunning() or not game:GetService("RunService"):IsClient() then return {} end
if not game:GetService("RunService"):IsClient() then return {} end
--!nonstrict
 
 
 
 
 
 
 
 
 
 
 
 
 

local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Lighting=game:GetService("Lighting")

local G=require(script.Parent:WaitForChild("Geometry"))
local LocalPlayer=Players.LocalPlayer

local V3=Vector3.new
local WHITE=Color3.new(1,1,1)
local TAU=math.pi*2
local CANVAS=1024      
local RING_FILL=0.9
local TEX_SMOKE="rbxasset://textures/particles/smoke_main.dds"

local M={}
local session=nil

local function c01(x) return x<0 and 0 or (x>1 and 1 or x) end
local function lerp(a,b,t) return a+(b-a)*t end
local function sm(t) t=c01(t) return t*t*(3-2*t) end
local function eo(t,p) return 1-(1-c01(t))^p end

local FADE_OUT=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.7,.3),NumberSequenceKeypoint.new(1,1)})
local function shrink(a) return NumberSequence.new({NumberSequenceKeypoint.new(0,a),NumberSequenceKeypoint.new(1,0)}) end

local function baseQuality()
 local ok,level=pcall(function() return settings().Rendering.QualityLevel.Value end)
 if ok and type(level)=="number" and level>0 then return math.clamp(level/12,.35,1) end
 return 1
end

 
 
 
local function newPart(parent,size,cf,color,material,transparency,shape)
 local p=Instance.new("Part")
 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false p.Massless=true
 p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth
 if shape then p.Shape=shape end
 p.Material=material or Enum.Material.Neon
 p.Color=color or WHITE
 p.Transparency=transparency or 0
 p.Size=size p.CFrame=cf p.Parent=parent
 return p
end

local function newGui(part,face,brightness)
 local gui=Instance.new("SurfaceGui")
 gui.Face=face gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize gui.CanvasSize=Vector2.new(CANVAS,CANVAS)
 gui.LightInfluence=0 gui.Brightness=brightness or 2 gui.AlwaysOnTop=false
 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 pcall(function() gui.MaxDistance=4000 end)
 gui.Parent=part
 return gui
end

 
local function newRing(parent,sides)
 local part=newPart(parent,V3(4,.05,4),CFrame.new(),WHITE,Enum.Material.SmoothPlastic,1)
 local strokes={}
 for _,face in ipairs(sides) do
  local gui=newGui(part,face,3)
  local fr=Instance.new("Frame")
  fr.AnchorPoint=Vector2.new(.5,.5) fr.Position=UDim2.fromScale(.5,.5) fr.Size=UDim2.fromScale(RING_FILL,RING_FILL)
  fr.BackgroundTransparency=1 fr.BorderSizePixel=0 fr.Parent=gui
  local cr=Instance.new("UICorner") cr.CornerRadius=UDim.new(.5,0) cr.Parent=fr
  local st=Instance.new("UIStroke") st.ApplyStrokeMode=Enum.ApplyStrokeMode.Border st.Thickness=2 st.Parent=fr
  table.insert(strokes,st)
 end
 return part,strokes
end
local function setRing(part,strokes,diameter,thickStuds,alpha,color)
 local full=diameter/RING_FILL
 part.Size=V3(full,.05,full)
 local px=math.clamp(thickStuds/full*CANVAS,1,230)
 for _,st in ipairs(strokes) do st.Thickness=px st.Transparency=1-c01(alpha) st.Color=color end
end

 
local function newTrailPart(parent,lifetime,width,colors)
 local p=newPart(parent,V3(.3,.3,.3),CFrame.new(),WHITE,Enum.Material.Neon,1)
 local a0=Instance.new("Attachment") a0.Position=V3(0,width*.5,0) a0.Parent=p
 local a1=Instance.new("Attachment") a1.Position=V3(0,-width*.5,0) a1.Parent=p
 local tr=Instance.new("Trail")
 tr.Attachment0=a0 tr.Attachment1=a1 tr.Lifetime=lifetime tr.LightEmission=1 tr.LightInfluence=0
 tr.FaceCamera=true tr.MinLength=.02 tr.Enabled=false tr.Color=colors
 tr.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(1,1)})
 tr.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})
 tr.Parent=p
 return p,tr
end

local function newEmitter(parent,props)
 local e=Instance.new("ParticleEmitter")
 e.Rate=0 e.LightEmission=1 e.LightInfluence=0
 for k,v in pairs(props) do e[k]=v end
 e.Parent=parent
 return e
end

local function makeSound(parent,id,volume,looped,speed)
 if type(id)~="string" or id=="" then return nil end
 local s=Instance.new("Sound")
 s.SoundId=id s.Volume=volume or .5 s.Looped=looped or false s.PlaybackSpeed=speed or 1
 s.RollOffMode=Enum.RollOffMode.InverseTapered s.RollOffMinDistance=60 s.RollOffMaxDistance=900
 s.Parent=parent
 return s
end

 
 
 
local function px(n) return math.max(1,math.floor(n*CANVAS/1024+.5)) end
local function bar(parent,cx,cy,len,thick,rot)
 local f=Instance.new("Frame")
 f.AnchorPoint=Vector2.new(.5,.5) f.Position=UDim2.fromScale(cx,cy) f.Size=UDim2.new(len,0,0,px(thick))
 f.Rotation=rot f.BackgroundColor3=WHITE f.BorderSizePixel=0 f.Parent=parent
 return f
end
 
local function line(parent,x0,y0,x1,y1,thick)
 local dx,dy=x1-x0,y1-y0
 local len=math.sqrt(dx*dx+dy*dy)
 return bar(parent,.5+(x0+x1)*.25,.5+(y0+y1)*.25,len*.5+px(thick)/CANVAS,thick,math.deg(math.atan2(dy,dx)))
end
local function circle(parent,r,thick)
 local f=Instance.new("Frame")
 f.AnchorPoint=Vector2.new(.5,.5) f.Position=UDim2.fromScale(.5,.5) f.Size=UDim2.fromScale(r,r)
 f.BackgroundTransparency=1 f.BorderSizePixel=0
 local cr=Instance.new("UICorner") cr.CornerRadius=UDim.new(.5,0) cr.Parent=f
 local st=Instance.new("UIStroke") st.Thickness=px(thick) st.Color=WHITE st.ApplyStrokeMode=Enum.ApplyStrokeMode.Border st.Parent=f
 f.Parent=parent
 return f
end
local function ticks(parent,count,r0,r1,thick,offset)
 local rm=(r0+r1)/2
 for i=0,count-1 do
  local a=offset+i/count*TAU
  bar(parent,.5+math.cos(a)*rm*.5,.5+math.sin(a)*rm*.5,(r1-r0)*.5,thick,math.deg(a))
 end
end
local function polygon(parent,n,r,thick,offset)
 for i=0,n-1 do
  local a0=offset+i/n*TAU local a1=offset+(i+1)/n*TAU
  line(parent,math.cos(a0)*r,math.sin(a0)*r,math.cos(a1)*r,math.sin(a1)*r,thick)
 end
end

 
 
 
local Session={}
Session.__index=Session

function Session.new(data)
 local now=workspace:GetServerTimeNow()
 local self=setmetatable({},Session)
 self.S=data.Params self.token=data.Token self.owner=data.Owner self.center=data.Center
 self.t0=data.StartedAt or now
 self.alive=true self.trauma=0 self.fov=0 Fov.Clear(self)
 self.camCF=nil self.camFov=0 self.ws=1
 self.rings,self.motes,self.shards={}, {}, {}
 self.quality=baseQuality() self.perf=1 self.accDt=0 self.accN=0
 self.rng=Random.new(7)
 self.fadeDur=.4
 self.crackIdx=1
 self.lastBeat=math.floor(G.BeatPhase(math.max(0,now-self.t0),self.S))
 session=self
 local ok,err=pcall(function()
  self:BuildWorld() self:BuildScreen() self:BuildAudio() self:BindRender()
  self:Sfx("Ignite",1,1)
 end)
 if not ok then warn("[Finality] build failed: "..tostring(err)) self:Destroy() return nil end
 return self
end

function Session:BindRender()
 local pri=Enum.RenderPriority.Camera.Value
 pcall(function() RunService:UnbindFromRenderStep("FinalityCamPre") end)
 pcall(function() RunService:UnbindFromRenderStep("FinalityStep") end)
  
  
 RunService:BindToRenderStep("FinalityCamPre",pri-1,function() self:UndoCamera() end)
 RunService:BindToRenderStep("FinalityStep",pri+1,function(dt)
  local ok,err=pcall(self.Step,self,dt)
  if not ok then warn("[Finality] "..tostring(err)) self:Destroy() end
 end)
end

function Session:UndoCamera()
 Fov.Clear(self)
 local cam=workspace.CurrentCamera
 if cam and self.camCF then
  cam.CFrame=cam.CFrame*self.camCF:Inverse()

 end
 self.camCF=nil self.camFov=0
end

function Session:Sfx(key,volume,speed,global)
 local sounds=self.S.Sounds
 local id=sounds and sounds[key]
 local parent=global and self.folder or self.soundPart
 local s=makeSound(parent,id,(volume or 1)*(self.S.SoundVolume or 1),false,speed or 1)
 if s then s.Ended:Once(function() s:Destroy() end) s:Play() end
end

 
 
 
function Session:BuildWorld()
 local S=self.S local rng=self.rng
 CANVAS=self.quality<.6 and 640 or 1024
 local C=self.center
 local R=S.PillarRadius local SR=S.SigilRadius local KR=R/SR
 local folder=Instance.new("Folder") folder.Name="FinalityVFX" folder.Archivable=false folder.Parent=workspace
 self.folder=folder
 self.goldWhite=ColorSequence.new({ColorSequenceKeypoint.new(0,S.White),ColorSequenceKeypoint.new(.4,S.Yellow),ColorSequenceKeypoint.new(1,S.Gold)})

  
 local sigil=newPart(folder,V3(SR*2,.2,SR*2),CFrame.new(C+V3(0,.25,0)),WHITE,Enum.Material.SmoothPlastic,1)
 local gui=newGui(sigil,Enum.NormalId.Top,3.5)
 local L={}
 local function mk(name,order)
  local g=Instance.new("CanvasGroup")
  g.AnchorPoint=Vector2.new(.5,.5) g.Position=UDim2.fromScale(.5,.5) g.Size=UDim2.fromScale(1,1)
  g.BackgroundTransparency=1 g.BorderSizePixel=0 g.GroupTransparency=1 g.ZIndex=order
  local sc=Instance.new("UIScale") sc.Parent=g
  g.Parent=gui
  L[name]={g=g,sc=sc,rot=0}
  return g
 end
 local g=mk("outer",1) circle(g,.985,3) ticks(g,72,.90,.95,3,0) ticks(g,12,.84,.95,7,0)
 g=mk("glyph",2) polygon(g,4,.80,4,0) polygon(g,4,.80,4,math.rad(45)) circle(g,.74,2) ticks(g,16,.70,.74,3,0)
 g=mk("kill",3) circle(g,KR,9) circle(g,KR-.04,2) ticks(g,48,KR-.075,KR-.04,3,0)
 g=mk("star",4) polygon(g,3,.5,4,-math.pi/2) polygon(g,3,.5,4,math.pi/2) circle(g,.5,2)
 g=mk("inner",5) circle(g,.27,4) circle(g,.2,2) ticks(g,12,.27,.33,4,0)
 g=mk("cracks",6)
 self.cracks={}
 local crng=Random.new(913)
 local N=22
 for i=1,N do
  local a=(i-1)/N*TAU+crng:NextNumber(-.1,.1)
  local r1=crng:NextNumber(.32,.98)
  local rm=r1*crng:NextNumber(.45,.7)
  local a2=a+crng:NextNumber(-.22,.22)
  local f1=line(g,math.cos(a)*.11,math.sin(a)*.11,math.cos(a)*rm,math.sin(a)*rm,4)
  local f2=line(g,math.cos(a)*rm,math.sin(a)*rm,math.cos(a2)*r1,math.sin(a2)*r1,2)
  f1.Visible=false f2.Visible=false
  self.cracks[i]={f1=f1,f2=f2,at=.06+.8*(i/N)}
 end
 local pit=Instance.new("Frame")
 pit.AnchorPoint=Vector2.new(.5,.5) pit.Position=UDim2.fromScale(.5,.5) pit.Size=UDim2.fromScale(.13,.13)
 pit.BackgroundColor3=S.Void pit.BackgroundTransparency=1 pit.BorderSizePixel=0 pit.ZIndex=10
 local pc=Instance.new("UICorner") pc.CornerRadius=UDim.new(.5,0) pc.Parent=pit
 pit.Parent=gui
 self.L=L self.pit=pit

  
 self.orb=newPart(folder,V3(1,1,1),CFrame.new(),S.Void,Enum.Material.SmoothPlastic,1,Enum.PartType.Ball)
 self.shells={}
 self.shellT={.84,.91,.965}
 local shellColors={S.White,S.Gold,S.Yellow}
 for i=1,3 do self.shells[i]=newPart(folder,V3(1,1,1),CFrame.new(),shellColors[i],Enum.Material.Neon,1,Enum.PartType.Ball) end
 self.accA,self.accAs=newRing(folder,{Enum.NormalId.Top,Enum.NormalId.Bottom})
 self.accB,self.accBs=newRing(folder,{Enum.NormalId.Top,Enum.NormalId.Bottom})
 self.orbLight=Instance.new("PointLight") self.orbLight.Color=S.Yellow self.orbLight.Range=60 self.orbLight.Brightness=0 self.orbLight.Parent=self.orb
 self.orbHidden=false

  
 local lp1=newPart(folder,V3(1,1,1),CFrame.new(C+V3(0,10,0)),WHITE,Enum.Material.SmoothPlastic,1)
 local lp2=newPart(folder,V3(1,1,1),CFrame.new(C+V3(0,70,0)),WHITE,Enum.Material.SmoothPlastic,1)
 self.lightBase=Instance.new("PointLight") self.lightBase.Color=S.Yellow self.lightBase.Range=60 self.lightBase.Brightness=0 self.lightBase.Parent=lp1
 self.lightMid=Instance.new("PointLight") self.lightMid.Color=S.White self.lightMid.Range=60 self.lightMid.Brightness=0 self.lightMid.Parent=lp2

  
 self.plumb=newPart(folder,V3(S.PillarHeight,1,1),CFrame.new(),S.White,Enum.Material.Neon,1,Enum.PartType.Cylinder)

  
 local groundPart=newPart(folder,V3(R*2.2,1,R*2.2),CFrame.new(C+V3(0,.6,0)),WHITE,Enum.Material.SmoothPlastic,1)
 self.emEmbers=newEmitter(groundPart,{Color=self.goldWhite,Size=shrink(.8),Lifetime=NumberRange.new(1.2,2.6),Speed=NumberRange.new(8,26),
  SpreadAngle=Vector2.new(14,14),Acceleration=V3(0,14,0),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-120,120),
  Transparency=FADE_OUT,Drag=.4,Shape=Enum.ParticleEmitterShape.Disc})
 local dustPart=newPart(folder,V3(S.StreamRadius*1.1,1,S.StreamRadius*1.1),CFrame.new(C+V3(0,1,0)),WHITE,Enum.Material.SmoothPlastic,1)
 self.emDust=newEmitter(dustPart,{Texture=TEX_SMOKE,Color=ColorSequence.new(Color3.fromRGB(214,168,70)),
  Size=NumberSequence.new({NumberSequenceKeypoint.new(0,6),NumberSequenceKeypoint.new(1,14)}),
  Lifetime=NumberRange.new(1.2,2),Speed=NumberRange.new(35,70),LightEmission=.25,
  Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.55),NumberSequenceKeypoint.new(1,1)}),
  Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-40,40),
  Shape=Enum.ParticleEmitterShape.Disc,ShapeInOut=Enum.ParticleEmitterShapeInOut.Inward,ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume})
 self.emFlare=newEmitter(self.orb,{Color=ColorSequence.new(S.White),Size=NumberSequence.new(20),Lifetime=NumberRange.new(.25,.4),
  Speed=NumberRange.new(0),Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.8),NumberSequenceKeypoint.new(1,1)}),
  Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-90,90)})
 self.emCrackle=newEmitter(self.orb,{Color=self.goldWhite,Size=shrink(.7),Lifetime=NumberRange.new(.4,.9),Speed=NumberRange.new(25,60),
  SpreadAngle=Vector2.new(180,180),Transparency=FADE_OUT,Drag=1.2})
 local ashPart=newPart(folder,V3(R*3,1,R*3),CFrame.new(C+V3(0,45,0)),WHITE,Enum.Material.SmoothPlastic,1)
 self.emAsh=newEmitter(ashPart,{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,S.Gold),ColorSequenceKeypoint.new(1,S.Void)}),
  Size=NumberSequence.new(.35),Lifetime=NumberRange.new(3,5),Speed=NumberRange.new(0,3),Acceleration=V3(0,-6,0),LightEmission=.5,
  Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.15,.2),NumberSequenceKeypoint.new(1,1)}),
  Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-60,60),EmissionDirection=Enum.NormalId.Bottom})

  
 for i=1,math.floor(28*self.quality) do
  local part,tr=newTrailPart(folder,.5,.55,self.goldWhite)
  local m={part=part,trail=tr,live=false,cd=0}
  self:ResetMote(m)
  m.u=rng:NextNumber()
  table.insert(self.motes,m)
 end
 for i=1,math.floor(14*self.quality) do
  local part=newPart(folder,V3(1,1,1),CFrame.new(),Color3.fromRGB(36,28,18),Enum.Material.Slate,1)
  local m={part=part,sx=rng:NextNumber(-2,2),sy=rng:NextNumber(-2,2),sz=rng:NextNumber(-2,2),
   size=V3(rng:NextNumber(1,3),rng:NextNumber(.8,2),rng:NextNumber(1,3))}
  self:ResetShard(m)
  m.u=rng:NextNumber()
  table.insert(self.shards,m)
 end
end

function Session:ResetMote(m)
 local rng=self.rng
 m.u=0 m.rate=rng:NextNumber(.45,.9) m.r0=rng:NextNumber(70,self.S.StreamRadius)
 m.a0=rng:NextNumber(0,TAU) m.twist=rng:NextNumber(5,9) m.h0=rng:NextNumber(.8,26)
 m.cd=2 m.trail.Enabled=false
end
function Session:ResetShard(m)
 local rng=self.rng
 m.u=0 m.rate=rng:NextNumber(.2,.4) m.r0=rng:NextNumber(20,115)
 m.a0=rng:NextNumber(0,TAU) m.twist=rng:NextNumber(4,7)
end

 
 
 
function Session:BuildScreen()
 local S=self.S
 local pg=LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
 if pg then
  local gui=Instance.new("ScreenGui")
  gui.Name="FinalityScreen" gui.IgnoreGuiInset=true gui.ResetOnSpawn=false gui.DisplayOrder=60 gui.Archivable=false
  gui.Parent=pg
  self.gui=gui
  local function frame(props)
   local f=Instance.new("Frame") f.BorderSizePixel=0
   for k,v in pairs(props) do f[k]=v end
   f.Parent=gui return f
  end
  self.wash=frame({Size=UDim2.fromScale(1,1),BackgroundColor3=S.Yellow,BackgroundTransparency=1})
  local function edge(pos,size,rot)
   local f=frame({Position=pos,Size=size,BackgroundColor3=S.Gold,BackgroundTransparency=1})
   local gr=Instance.new("UIGradient") gr.Rotation=rot
   gr.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
   gr.Parent=f
   return f
  end
  self.edges={edge(UDim2.fromScale(0,0),UDim2.fromScale(1,.34),90),edge(UDim2.fromScale(0,.66),UDim2.fromScale(1,.34),270),
   edge(UDim2.fromScale(0,0),UDim2.fromScale(.26,1),0),edge(UDim2.fromScale(.74,0),UDim2.fromScale(.26,1),180)}
  self.flash=frame({Size=UDim2.fromScale(1,1),BackgroundColor3=S.White,BackgroundTransparency=1})
 end
 self.cc=Instance.new("ColorCorrectionEffect") self.cc.Name="FinalityCC" self.cc.Parent=Lighting
 self.bloom=Instance.new("BloomEffect") self.bloom.Name="FinalityBloom" self.bloom.Intensity=0 self.bloom.Size=24 self.bloom.Threshold=1 self.bloom.Parent=Lighting
end

function Session:BuildAudio()
 local S=self.S
 self.soundPart=newPart(self.folder,V3(1,1,1),CFrame.new(self.center+V3(0,12,0)),WHITE,Enum.Material.SmoothPlastic,1)
 local sounds=S.Sounds or {}
 self.chargeLoop=makeSound(self.soundPart,sounds.ChargeLoop,0,true,.7)
 if self.chargeLoop then self.chargeLoop:Play() end
end

 
 
 
function Session:BuildPillar()
 local S=self.S local rng=self.rng local C=self.center local R=S.PillarRadius
 local Hv=S.PillarHeight*1.6  
 local P={Hv=Hv,layers={},flows={},helix={}}
  
 local specs={{S.White,.02,.30},{S.Yellow,.30,.62},{S.Gold,.62,1},{S.Gold,.88,1.13}}
 for _,sp in ipairs(specs) do
  local part=newPart(self.folder,V3(Hv,2,2),CFrame.new(),sp[1],Enum.Material.Neon,1,Enum.PartType.Cylinder)
  table.insert(P.layers,{part=part,base=sp[2],scale=sp[3]})
 end
  
 local flowColors=ColorSequence.new({ColorSequenceKeypoint.new(0,S.White),ColorSequenceKeypoint.new(1,S.Yellow)})
 for i=1,math.floor(34*self.quality) do
  local part,tr=newTrailPart(self.folder,.2,.55,flowColors)
  table.insert(P.flows,{part=part,trail=tr,f=rng:NextNumber(.1,.95),a=rng:NextNumber(0,TAU),y=rng:NextNumber(0,Hv),sp=rng:NextNumber(260,420),cd=2})
 end
 local nh=math.floor(10*self.quality)
 for i=1,nh do
  local part,tr=newTrailPart(self.folder,.8,1.1,self.goldWhite)
  table.insert(P.helix,{part=part,trail=tr,a0=i/nh*TAU,y=rng:NextNumber(0,Hv),sp=rng:NextNumber(150,240),cd=2})
 end
 local colPart=newPart(self.folder,V3(R*1.1,Hv*.7,R*1.1),CFrame.new(C+V3(0,Hv*.35,0)),WHITE,Enum.Material.SmoothPlastic,1)
 P.emCol=newEmitter(colPart,{Color=self.goldWhite,Size=shrink(1.1),Lifetime=NumberRange.new(.5,1.1),Speed=NumberRange.new(40,110),
  SpreadAngle=Vector2.new(4,4),Transparency=FADE_OUT})
 local basePart=newPart(self.folder,V3(R*1.8,1,R*1.8),CFrame.new(C+V3(0,.8,0)),WHITE,Enum.Material.SmoothPlastic,1)
 P.emBase=newEmitter(basePart,{Color=self.goldWhite,Size=shrink(1),Lifetime=NumberRange.new(1,2),Speed=NumberRange.new(40,120),
  SpreadAngle=Vector2.new(10,10),Acceleration=V3(0,20,0),Transparency=FADE_OUT,Shape=Enum.ParticleEmitterShape.Disc})
 P.emRingSmoke=newEmitter(basePart,{Texture=TEX_SMOKE,Color=ColorSequence.new(Color3.fromRGB(230,180,80)),LightEmission=.5,
  Size=NumberSequence.new({NumberSequenceKeypoint.new(0,12),NumberSequenceKeypoint.new(1,34)}),Lifetime=NumberRange.new(1,1.8),
  Speed=NumberRange.new(90,150),Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-30,30),
  Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.3),NumberSequenceKeypoint.new(1,1)}),
  Shape=Enum.ParticleEmitterShape.Disc,ShapeInOut=Enum.ParticleEmitterShapeInOut.Outward})
 local burstPart=newPart(self.folder,V3(1,1,1),CFrame.new(C+V3(0,3,0)),WHITE,Enum.Material.SmoothPlastic,1)
 P.emBurst=newEmitter(burstPart,{Color=self.goldWhite,Size=shrink(1.8),Lifetime=NumberRange.new(.6,1.4),Speed=NumberRange.new(70,190),
  SpreadAngle=Vector2.new(180,180),Acceleration=V3(0,-40,0),Transparency=FADE_OUT,Drag=.6})
 P.dome=newPart(self.folder,V3(1,1,1),CFrame.new(C+V3(0,4,0)),S.White,Enum.Material.Neon,1,Enum.PartType.Ball)
 self.P=P
end

 
 
 
function Session:SpawnRing(speed,maxR,thick,color,r0,mode,alpha,startedAt)
 if #self.rings>=(self.S.MaxRings or 40) then return end
 local part,strokes=newRing(self.folder,{Enum.NormalId.Top})
 part.CFrame=CFrame.new(self.center+V3(0,.35,0))
 table.insert(self.rings,{part=part,strokes=strokes,t0=startedAt or workspace:GetServerTimeNow(),speed=speed,max=maxR,thick=thick,
  color=color,r0=r0,mode=mode or "out",a=alpha or 1})
end

 
 
 
function Session:OnBeat(p,ws,index)
 local S=self.S
 self.trauma=math.min(1,self.trauma+(.03+.13*p)*ws)
 local wave=G.ChargeWave(index,S)
 self:SpawnRing(wave.Speed,wave.MaxRadius,wave.Thickness,S.Yellow:Lerp(S.White,p),wave.Radius,"out",.9,self.t0+wave.Start)
 self:Sfx("Beat",.55+.45*p,.85+.5*p)
 self.emEmbers:Emit(math.floor(12*self.quality*self.perf))
end

function Session:OnBreath(t)
 if self.tBreath then return end
 local S=self.S
 self.tBreath=t or workspace:GetServerTimeNow()
 self.trauma*=.15  
 self:SpawnRing(-(S.ShockwaveMaxRadius*.95)/S.Breath,S.ShockwaveMaxRadius,5,S.White,S.ShockwaveMaxRadius*.95,"in",1)
 self:Sfx("Inhale",1,1)
 self.emFlare:Emit(2)
end

function Session:OnPillar(t)
 if self.tFire then return end
 local S=self.S
 self.tFire=t or workspace:GetServerTimeNow()
 for i=#self.rings,1,-1 do self.rings[i].part:Destroy() self.rings[i]=nil end
 self:BuildPillar()
 self.trauma=math.max(self.trauma,self.ws)
 self.blur=Instance.new("BlurEffect") self.blur.Name="FinalityBlur" self.blur.Size=0 self.blur.Parent=Lighting
 local colors={S.White,S.Yellow,S.Gold}
 for index,wave in ipairs(G.BurstWaves(S)) do
  self:SpawnRing(wave.Speed,wave.MaxRadius,wave.Thickness,colors[index] or S.Gold,wave.Radius,"out",index==3 and .8 or 1,self.tFire+wave.Start)
 end
 local q=self.quality*self.perf
 self.P.emBurst:Emit(math.floor(160*q))
 self.P.emRingSmoke:Emit(math.floor(36*q))
 self.emFlare:Emit(3)
  
 for _,m in ipairs(self.shards) do
  if m.part.Transparency<1 then
   local d=m.pos and V3(m.pos.X-self.center.X,0,m.pos.Z-self.center.Z) or V3(1,0,0)
   local dir=d.Magnitude>.1 and d.Unit or V3(1,0,0)
   m.vel=dir*self.rng:NextNumber(70,130)+V3(0,self.rng:NextNumber(30,70),0)
  end
 end
 if self.chargeLoop then self.chargeLoop:Stop() end
 self:Sfx("Detonate",1,1)
 self:Sfx("SubBoom",1,1,true)
 self.pillarLoop=makeSound(self.soundPart,S.Sounds and S.Sounds.PillarLoop,0,true,1)
 if self.pillarLoop then self.pillarLoop:Play() end
end

function Session:OnAftermath(t)
 if self.tAfter then return end
 self.tAfter=t or workspace:GetServerTimeNow()
 self:Sfx("Aftershock",1,1)
end

function Session:OnEnd(interrupted)
 if self.tEnd then return end
 self.tEnd=workspace:GetServerTimeNow()
 self.fadeDur=interrupted and .35 or 3.2  
end

 
 
 
function Session:Step(dt)
 if not self.alive then return end
 local S=self.S
 local now=workspace:GetServerTimeNow()
 local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
 local visible=h~=nil and h.Health>0 and not LocalPlayer:GetAttribute("ViewAsServer")
 if self.gui then self.gui.Enabled=visible end
 for _,key in ipairs({"cc","bloom","blur"}) do if self[key] then self[key].Enabled=visible end end
 local owner=self.owner
 if not owner or not owner.Parent or owner:GetAttribute("Phase")~=5 or owner:GetAttribute("EncounterEnded") then self:Destroy() return end
 if now-self.t0>S.Charge+S.Breath+S.PillarDuration+S.Recovery+6 then self:Destroy() return end
 local C=self.center
 local R=S.PillarRadius
 local rel=now-self.t0
 local p=c01(rel/S.Charge)
 local tb=self.tBreath and now-self.tBreath
 local tf=self.tFire and now-self.tFire
 local ta=self.tAfter and now-self.tAfter
 local stage=ta and "after" or tf and "fire" or tb and "breath" or "charge"

 local fade=1
 if self.tEnd then
  fade=1-c01((now-self.tEnd)/self.fadeDur)
  if fade<=0 then self:Destroy() return end
 end

  
 self.accDt+=dt self.accN+=1
 if self.accDt>=1 then
  local avg=self.accDt/self.accN
  if avg>1/36 then self.perf=math.max(.35,self.perf-.2) elseif avg<1/52 then self.perf=math.min(1,self.perf+.05) end
  self.accDt=0 self.accN=0
 end

  
 local cam=workspace.CurrentCamera
 local dist=cam and (cam.CFrame.Position-C).Magnitude or 0
 local w=c01(1-dist/S.ShakeRange)
 local ws=.12+.88*w^.7
 local wv=.55+.45*w
 self.ws=ws

 local lr=LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 local inKill=false
 if lr then local d=lr.Position-C inKill=V3(d.X,0,d.Z).Magnitude<R+2 end

  
 local beats=G.BeatPhase(rel,S)
 local kick=0
 if stage=="charge" then
  kick=math.exp(-S.PulseSharpness*(beats-math.floor(beats)))
  local bi=math.floor(beats)
  while bi>self.lastBeat do self.lastBeat+=1 self:OnBeat(p,ws,self.lastBeat) end
 end

 local c={dt=dt,now=now,rel=rel,p=p,tb=tb,tf=tf,ta=ta,stage=stage,fade=fade,kick=kick,
  w=w,ws=ws,wv=wv,inKill=inKill,q=self.quality*self.perf}
 self:UpdateOrb(c)
 self:UpdateSigil(c)
 self:UpdateStreams(c)
 self:UpdateRings(c)
 self:UpdatePillar(c)
 self:UpdateAtmosphere(c)
 self:UpdateScreen(c)
 self:UpdateCamera(c)
 self:UpdateAudio(c)
end

function Session:UpdateOrb(c)
 local S=self.S
 local root=self.owner and self.owner.Parent and self.owner:FindFirstChild("HumanoidRootPart")
 local base=root and root.Position or (self.center+V3(0,5,0))
 local pos=base+V3(0,S.OrbHeight,0)
 c.orbPos=pos
 local r=0
 if c.stage=="charge" then r=lerp(.6,S.OrbRadiusEnd,c.p^1.7)*(1+.1*c.kick)*sm(c.rel/.9)
 elseif c.stage=="breath" then r=S.OrbRadiusEnd*lerp(1,.1,sm(c.tb/S.Breath))*(1+.06*math.sin(c.tb*70)) end
 r*=c.fade
 if r>.05 then
  self.orbHidden=false
  local d=r*2
  self.orb.Transparency=0 self.orb.Size=V3(d,d,d) self.orb.CFrame=CFrame.new(pos)
  for i,sh in ipairs(self.shells) do
   local s=d*(1.12+(i-1)*.28+.04*c.kick)
   sh.Size=V3(s,s,s) sh.CFrame=CFrame.new(pos)
   sh.Transparency=c01(self.shellT[i]-.1*c.kick-(c.stage=="breath" and .08 or 0))
  end
  local spin=c.now
  self.accA.CFrame=CFrame.new(pos)*CFrame.Angles(math.rad(22),0,0)*CFrame.Angles(0,spin*1.5,0)
  self.accB.CFrame=CFrame.new(pos)*CFrame.Angles(math.rad(-64),0,0)*CFrame.Angles(0,-spin*1.1,0)
  setRing(self.accA,self.accAs,d*2.1,r*.07+.15,.9,S.Yellow)
  setRing(self.accB,self.accBs,d*2.9,r*.05+.12,.7,S.Gold:Lerp(S.White,sm((c.p-.6)/.4)))
  local heat=c.stage=="breath" and 1 or c.p
  self.orbLight.Brightness=((.5+4*c.p)*(1+.6*c.kick)+(c.stage=="breath" and 6 or 0))*sm(c.rel/.9)
  self.orbLight.Range=math.min(60,14+46*heat)
  self.orbLight.Color=S.Yellow:Lerp(S.White,sm((heat-.7)/.3))
  self.emFlare.Rate=5*c.q
  self.emCrackle.Rate=(18+70*c.p)*c.q
  local k=math.floor(c.rel*8)
  if k~=self.flareK then self.flareK=k self.emFlare.Size=NumberSequence.new(math.max(6,r*5)) end
 elseif not self.orbHidden then
  self.orbHidden=true
  self.orb.Transparency=1
  for _,sh in ipairs(self.shells) do sh.Transparency=1 end
  setRing(self.accA,self.accAs,4,.1,0,S.Gold) setRing(self.accB,self.accBs,4,.1,0,S.Gold)
  self.orbLight.Brightness=0 self.emFlare.Rate=0 self.emCrackle.Rate=0
 end
end

function Session:UpdateSigil(c)
 local S=self.S local L=self.L
 local p,rel,stage,fade=c.p,c.rel,c.stage,c.fade
 local spd=1+3*p*p
 if stage=="breath" then spd=6 elseif stage=="fire" then spd=8*math.exp(-c.tf*2) elseif stage=="after" then spd=.3 end
 local tint=S.Gold:Lerp(S.Yellow,sm(p/.6)):Lerp(S.White,sm((p-.75)/.25)*.8)
 local decorA,decorScale=1,1
 if stage=="charge" then decorA=lerp(.55,1,p)
 elseif stage=="breath" then decorScale=lerp(1,.55,sm(c.tb/S.Breath)) tint=S.White:Lerp(S.Yellow,.15)  
 elseif stage=="fire" then decorA=1-sm(c.tf/.7) decorScale=.55+.9*eo(c.tf/.7,3) tint=S.White
 else decorA=0 end
 local rots={outer=6,glyph=-14,star=22,inner=-40}
 for i,name in ipairs({"outer","glyph","star","inner"}) do
  local l=L[name]
  l.rot+=c.dt*rots[name]*spd
  l.g.GroupTransparency=1-c01(sm((rel-.12*(i-1))/.7)*decorA*fade)
  l.g.GroupColor3=tint l.g.Rotation=l.rot l.sc.Scale=decorScale
 end
  
 local k=L.kill
 k.rot+=c.dt*3*spd
 local killA=sm((rel-.35)/.7)
 if stage=="fire" then killA=1-sm((c.tf-(S.PillarDuration-.5))/.5) elseif stage=="after" then killA=0 end
 killA*=.8+.2*c.kick
 local kcol=S.Yellow:Lerp(S.White,sm((p-.6)/.4)*c01(.2+.8*c.kick))
 if stage=="breath" or stage=="fire" then kcol=S.White end
 k.g.GroupTransparency=1-c01(killA*fade) k.g.GroupColor3=kcol k.g.Rotation=k.rot
  
 local rec=math.max(S.Recovery,.01)
 local crackA,crackTint=1,tint
 if stage=="charge" then crackA=sm((rel-.5)/1)
 elseif stage=="after" then
  crackA=1-.35*sm(c.ta/rec)
  crackTint=S.Gold:Lerp(Color3.fromRGB(190,80,14),sm(c.ta/(rec+1)))
 end
 L.cracks.g.GroupTransparency=1-c01(crackA*fade) L.cracks.g.GroupColor3=crackTint
 local reveal=stage=="charge" and p or 1
 while self.crackIdx<=#self.cracks and reveal>=self.cracks[self.crackIdx].at do
  local cr=self.cracks[self.crackIdx] cr.f1.Visible=true cr.f2.Visible=true
  self.crackIdx+=1
 end
 local pitA=sm((rel-.2)/.6)*fade
 if stage=="after" then pitA*=1-sm(c.ta/1.5) end
 self.pit.BackgroundTransparency=1-c01(pitA)
end

function Session:UpdateStreams(c)
 local S=self.S local C=self.center
 local stage=c.stage local p=c.p
 local targetH=c.orbPos.Y-C.Y
  
 local active=0
 if stage=="charge" then active=math.floor(#self.motes*(.25+.75*p)*math.min(1,c.q+.2)) elseif stage=="breath" then active=#self.motes end
 local sp=stage=="breath" and 4 or (.6+2.4*p*p)
 for i,m in ipairs(self.motes) do
  if i>active then
   if m.live then m.live=false m.trail.Enabled=false end
  else
   if not m.live then m.live=true self:ResetMote(m) end
   if m.cd>0 then
    m.cd-=1
    if m.cd==0 then m.trail.Enabled=true end
   else
    m.u+=c.dt*m.rate*sp
    if m.u>=1 then self:ResetMote(m) end
   end
   local u=m.u
   local rad=m.r0*(1-u)^1.5+.4
   local ang=m.a0+m.twist*u^.85
   m.part.CFrame=CFrame.new(C.X+math.cos(ang)*rad,C.Y+lerp(m.h0,targetH,u^1.3),C.Z+math.sin(ang)*rad)
  end
 end
  
 if stage=="charge" or stage=="breath" then
  local act=math.floor(#self.shards*c01((p-.05)/.45))
  local ssp=stage=="breath" and 3.2 or (.5+1.6*p*p)
  for i,m in ipairs(self.shards) do
   if i>act then
    m.part.Transparency=1
   else
    m.part.Transparency=0
    m.u+=c.dt*m.rate*ssp
    if m.u>=1 then self:ResetShard(m) end
    local u=m.u
    local rad=m.r0*(1-u)^1.3+1
    local ang=m.a0+m.twist*u^.85
    local scale=math.max(sm(u/.12)*(1-sm((u-.82)/.18)),.02)
    m.pos=V3(C.X+math.cos(ang)*rad,C.Y+lerp(.8,targetH,u^1.7),C.Z+math.sin(ang)*rad)
    m.part.Size=m.size*scale
    m.part.CFrame=CFrame.new(m.pos)*CFrame.fromEulerAnglesXYZ(m.sx*c.now,m.sy*c.now,m.sz*c.now)
   end
  end
 else
  for _,m in ipairs(self.shards) do
   if m.vel and m.pos and c.tf and c.tf<1.35 then
    m.vel+=V3(0,-90*c.dt,0) m.pos+=m.vel*c.dt
    m.part.CFrame=CFrame.new(m.pos)*CFrame.fromEulerAnglesXYZ(m.sx*c.now,m.sy*c.now,m.sz*c.now)
    m.part.Transparency=c01(c.tf/1.3)
   elseif m.part.Transparency<1 then
    m.part.Transparency=1
   end
  end
 end
end

function Session:UpdateRings(c)
 for i=#self.rings,1,-1 do
  local rg=self.rings[i]
  if c.now<rg.t0 then setRing(rg.part,rg.strokes,rg.r0*2,rg.thick,0,rg.color) continue end
  local r=rg.r0+rg.speed*(c.now-rg.t0)
  if (rg.speed>0 and r>=rg.max) or (rg.speed<0 and r<=6) then
   rg.part:Destroy() table.remove(self.rings,i)
  else
   local alpha
   if rg.mode=="in" then alpha=.3+.7*(1-r/rg.r0) else alpha=1-(r/rg.max)^1.6 end
   setRing(rg.part,rg.strokes,r*2,rg.thick*(1-.55*r/rg.max),c01(alpha*rg.a*c.fade),rg.color)
  end
 end
end

function Session:UpdatePillar(c)
 local S=self.S local C=self.center
  
 local plumbA=0
 if c.stage=="charge" then plumbA=sm((c.p-.55)/.45) elseif c.stage=="breath" then plumbA=1 end
 plumbA*=c.fade
 local pl=self.plumb
 if plumbA>.01 then
  local r=lerp(.12,.9,plumbA)*(c.stage=="breath" and lerp(1,1.8,sm(c.tb/S.Breath)) or 1)
  local H=S.PillarHeight
  pl.Size=V3(H,r*2,r*2)
  pl.CFrame=CFrame.new(C+V3(0,H/2,0))*CFrame.Angles(0,0,math.pi/2)
  pl.Transparency=1-c01(.15+.55*plumbA+.2*c.kick)
 elseif pl.Transparency<1 then
  pl.Transparency=1
 end

 local P=self.P
 if not P or not c.tf then return end
 local tf=c.tf local Hv=P.Hv
 local r=G.PillarRadius(tf,S)  
 local mid=CFrame.new(C+V3(0,Hv/2-8,0))*CFrame.Angles(0,0,math.pi/2)
 local taper=sm((tf-(S.PillarDuration-.3))/.3)
 for i,l in ipairs(P.layers) do
  local rr=r*l.scale
  if i==1 then rr*=1+.45*math.exp(-tf*7) end  
  if rr<.2 then
   l.part.Transparency=1
  else
   l.part.Size=V3(Hv,rr*2,rr*2) l.part.CFrame=mid
   local flick=.1*math.noise(c.now*9,i*3.1,.7)
   l.part.Transparency=c01(lerp(l.base+flick,1,math.max(1-c.fade,taper*.8)))
  end
 end
 local live=r>.5
 for _,m in ipairs(P.flows) do
  if not live then
   m.trail.Enabled=false
  else
   if m.cd>0 then
    m.cd-=1
    if m.cd==0 then m.trail.Enabled=true end
   else
    m.y+=m.sp*c.dt
    if m.y>Hv then m.y-=Hv m.cd=2 m.trail.Enabled=false end
   end
   local ang=m.a+tf*1.4
   m.part.CFrame=CFrame.new(C.X+math.cos(ang)*r*m.f,C.Y-8+m.y,C.Z+math.sin(ang)*r*m.f)
  end
 end
 for _,m in ipairs(P.helix) do
  if not live then
   m.trail.Enabled=false
  else
   if m.cd>0 then
    m.cd-=1
    if m.cd==0 then m.trail.Enabled=true end
   else
    m.y+=m.sp*c.dt
    if m.y>Hv then m.y-=Hv m.cd=2 m.trail.Enabled=false end
   end
   local ang=tf*3.2+m.a0+m.y*.012
   m.part.CFrame=CFrame.new(C.X+math.cos(ang)*r*1.04,C.Y-8+m.y,C.Z+math.sin(ang)*r*1.04)
  end
 end
 P.emCol.Rate=(r>S.PillarRadius*.3) and 230*c.q or 0
 P.emBase.Rate=(r>2) and 150*c.q or 0
  
 if tf<.35 then
  local d=140*eo(tf/.25,3)
  P.dome.Size=V3(math.max(d,.2),math.max(d,.2),math.max(d,.2))
  P.dome.Transparency=.35+.65*sm(tf/.3)
 elseif P.dome.Transparency<1 then
  P.dome.Transparency=1
 end
end

function Session:UpdateAtmosphere(c)
 local S=self.S local stage=c.stage local p=c.p
 local emb,dust=0,0
 if stage=="charge" then emb=30+150*p*p dust=10+55*p*p elseif stage=="breath" then emb=220 dust=80 end
 self.emEmbers.Rate=emb*c.q*c.fade
 self.emDust.Rate=dust*c.q*c.fade
 self.emAsh.Rate=((stage=="fire" and c.tf>1.2) or stage=="after") and 70*c.q*c.fade or 0
 local b=0
 if stage=="charge" then b=(.4+3*p)*(1+.5*c.kick)
 elseif stage=="breath" then b=6
 elseif stage=="fire" then
  local r=G.PillarRadius(c.tf,S)
  b=r>1 and (5+10*math.exp(-c.tf*2.4))*(r/S.PillarRadius) or 0
 end
 b*=c.fade
 self.lightBase.Brightness=b
 self.lightMid.Brightness=stage=="fire" and b*.8 or 0
end

function Session:UpdateScreen(c)
 local S=self.S local stage=c.stage
  
 local yel
 if stage=="charge" then yel=c.p^1.6
 elseif stage=="breath" then yel=1
 elseif stage=="fire" then yel=lerp(1,.55,sm(c.tf/S.PillarDuration))
 else yel=lerp(.55,0,sm(c.ta/(math.max(S.Recovery,.01)+1.2))) end
 yel*=c.fade*c.wv
  
 local dim=0
 if stage=="charge" then dim=-.05*sm(c.p)
 elseif stage=="breath" then dim=lerp(-.05,-.14,sm(c.tb/S.Breath))
 elseif stage=="fire" then dim=.32*math.exp(-c.tf*3.2) end
 local flashE=stage=="fire" and math.exp(-c.tf*4.5) or 0

 local cc=self.cc
 cc.TintColor=WHITE:Lerp(Color3.fromRGB(255,222,96),c01(yel*.85))
 cc.Saturation=.4*yel
 cc.Contrast=.18*yel+(stage=="breath" and .12*c.fade or 0)
 cc.Brightness=dim*c.wv*c.fade
 self.bloom.Intensity=.2*c.fade+1.1*yel+2.2*flashE*c.wv
 self.bloom.Size=24+32*yel+20*flashE
 self.bloom.Threshold=1-.25*yel
 if self.blur then self.blur.Size=22*flashE*c.wv end

 if self.gui then
  self.flash.BackgroundTransparency=1-c01(S.FlashPeak*flashE*(.45+.55*c.w))
  self.wash.BackgroundTransparency=1-c01(.03*c.fade+.15*yel^1.5)
   
  local edgeA=(.1*sm(c.rel/1.5)*c.fade+.5*yel)*(1+.3*c.kick)*((c.inKill and c.p>.5) and 1.25 or 1)
  local col=S.Gold:Lerp(S.White,sm((c.p-.7)/.3)*.8)
  if stage~="charge" then col=S.Gold:Lerp(S.White,.5) end
  for _,e in ipairs(self.edges) do
   e.BackgroundTransparency=1-math.min(edgeA,.85) e.BackgroundColor3=col
  end
 end
end

function Session:UpdateCamera(c)
 local h=LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
 if not h or h.Health<=0 or LocalPlayer:GetAttribute("ViewAsServer") then self:UndoCamera() self.fov=0 return end
 local S=self.S local ws=c.ws
 local sustain,fovT=0,0
 if c.stage=="charge" then
  sustain=(.04+.9*c.p^2.4)*ws
  fovT=-(2.5*sm(c.p)+5*c.p^3)*ws-1.8*c.kick*c.p*ws
 elseif c.stage=="breath" then
  sustain=.06*ws
  fovT=-lerp(7.5,13,sm(c.tb/S.Breath))*ws  
 elseif c.stage=="fire" then
  sustain=.5*ws*(1-.6*sm(c.tf/S.PillarDuration))
  fovT=(3+20*math.exp(-c.tf*3.2))*ws       
 else
  sustain=.12*ws*math.exp(-c.ta*1.5)
  fovT=2*ws*math.exp(-c.ta*1.2)
 end
 sustain*=c.fade fovT*=c.fade
 self.fov=lerp(self.fov,fovT,1-math.exp(-(c.stage=="fire" and 30 or 10)*c.dt))
 self.trauma=math.max(0,self.trauma-c.dt*1.4)
 local amp=c01(math.max(sustain,self.trauma*self.trauma))
 local cam=workspace.CurrentCamera
 if not cam then return end
 local n=c.now*24
 local nx,ny,nz=math.noise(n,1.3,.5)*2,math.noise(n,7.7,.5)*2,math.noise(n,13.1,.5)*2
 local deg=math.rad(S.ShakeDeg)*amp
 local off=CFrame.new(nx*S.ShakeStuds*amp,ny*S.ShakeStuds*amp,0)*CFrame.Angles(ny*deg,nx*deg,nz*deg*.6)
 cam.CFrame=cam.CFrame*off
 Fov.Set(self,self.fov)
 self.camCF=off self.camFov=0

end

function Session:UpdateAudio(c)
 local S=self.S local v=S.SoundVolume or 1
 local cl=self.chargeLoop
 if cl then
  local vol,spd=0,1
  if c.stage=="charge" then vol=.12+.88*c.p^1.4 spd=.7+.9*c.p
  elseif c.stage=="breath" then vol=lerp(1,0,sm(c.tb/.5)) spd=1.6+.4*sm(c.tb/S.Breath) end
  cl.Volume=vol*v*c.fade cl.PlaybackSpeed=spd
 end
 local pl=self.pillarLoop
 if pl then
  local vol=0
  if c.stage=="fire" then vol=1-sm((c.tf-(S.PillarDuration-.7))/.7) end
  pl.Volume=vol*v*c.fade
 end
end

 
 
 
function Session:Destroy()
 if not self.alive then return end
 self.alive=false
 if session==self then
  pcall(function() RunService:UnbindFromRenderStep("FinalityStep") end)
  pcall(function() RunService:UnbindFromRenderStep("FinalityCamPre") end)
 end
 pcall(function() self:UndoCamera() end)
 for _,key in ipairs({"folder","gui","cc","bloom","blur"}) do
  local o=self[key]
  if o then pcall(function() o:Destroy() end) self[key]=nil end
 end
 if session==self then session=nil end
end

 
 
 
function M.Handle(data)
 if not RunService:IsClient() then return end
 if type(data)~="table" or not data.Stage or not data.Params then return end
 local stage=data.Stage
 if stage=="Charge" then
  if session then session:Destroy() end
  Session.new(data)
  return
 end
 local s=session
 if not s or not s.alive or s.token~=data.Token then return end
 if stage=="Breath" then s:OnBreath(data.StartedAt)
 elseif stage=="Pillar" then s:OnPillar(data.StartedAt)
 elseif stage=="Aftermath" then s:OnAftermath(data.StartedAt)
 elseif stage=="End" then s:OnEnd(data.Interrupted) end
end
function M.Clear()
 if session then session:Destroy() end
end
function M.ResetView()
 if not session then return end
 session:UndoCamera() session.fov=0 session.trauma=0
 if session.gui then session.gui.Enabled=false end
 for _,key in ipairs({"cc","bloom","blur"})do if session[key]then session[key].Enabled=false end end
end
M.Play=M.Handle

return M
