local Players=game:GetService("Players")
local Lighting=game:GetService("Lighting")
local VFX=game.ReplicatedStorage:WaitForChild("VFXEngine")
local ASSETS=VFX:WaitForChild("Assets")
local P={}
local UP=Vector3.yAxis
local WHITE=Color3.new(1,1,1)
local GOLD=Color3.fromRGB(255,208,111)
local SHINE=Color3.fromRGB(255,246,214)
local AMBER=Color3.fromRGB(255,146,36)
local BRIGHT=Color3.fromRGB(255,214,60)
local RAGE=Color3.fromRGB(255,72,36)
local BLOOD=Color3.fromRGB(150,16,10)
local RED=Color3.fromRGB(255,40,40)
local UMBER=Color3.fromRGB(110,60,10)
local NEON=Enum.Material.Neon
local FF=Enum.Material.ForceField
local CYL=Enum.PartType.Cylinder
local BALL=Enum.PartType.Ball
local HIDDEN=CFrame.new(0,-1e4,0)
local FIRE_BODY="rbxassetid://17703378809"
local FIRE_TOON="rbxassetid://93253997872542"

local function part(g,size,color,alpha,shape,material)
 local p=Instance.new("Part")
 p.Anchored=true p.CanCollide=false p.CanQuery=false p.CanTouch=false p.CastShadow=false
 p.Material=material or NEON p.Color=color p.Transparency=alpha or 0 p.Size=size p.CFrame=HIDDEN
 if shape then p.Shape=shape end
 p.Parent=g.Folder
 return p
end
local function rootOf(m)return m and m.Parent and m:FindFirstChild("HumanoidRootPart")end
 -- the floor under pos, looking past every character (a player standing in an effect would otherwise be the "floor")
local function groundAt(E,pos,g,...)
 local skip={g.Folder,...}
 for _,pl in ipairs(Players:GetPlayers())do if pl.Character then skip[#skip+1]=pl.Character end end
 return E.Ground(pos,skip)
end
local function smooth(x)x=math.clamp(x,0,1)return x*x*(3-2*x)end
local function look(a)return CFrame.Angles(0,a,0).LookVector end
local function ns(...)local k,v={...},{} for i=1,#k,2 do v[#v+1]=NumberSequenceKeypoint.new(k[i],k[i+1])end return NumberSequence.new(v)end
local function grade(E,props,t)
 local cc=Instance.new("ColorCorrectionEffect")
 for k,v in pairs(props)do cc[k]=v end
 cc.Parent=Lighting
 E.Tween(cc,t,{Brightness=0,Contrast=0,Saturation=0,TintColor=WHITE})
 task.delay(t+.1,function()cc:Destroy()end)
end
local function dome(E,g,pos,color,d0,d1,t,alpha,material)
 local p=part(g,Vector3.one*d0,color,alpha or .2,BALL,material)
 p.CFrame=CFrame.new(pos)
 E.Tween(p,t,{Size=Vector3.one*d1,Transparency=1})
 return p
end
 -- radial here); dash leaves every other segment out
local function flatRing(g,radius,width,color,alpha,n,dash)
 local carrier=part(g,Vector3.one*.2,WHITE,1)
 local pts={}
 for i=1,n do
  local a=(i-1)/n*math.pi*2
  local dir=Vector3.new(math.cos(a),0,math.sin(a))
  local at=Instance.new("Attachment") at.CFrame=CFrame.fromMatrix(dir*radius,UP,dir) at.Parent=carrier
  pts[i]=at
 end
 local beams={}
 for i=1,n do
  if not dash or i%2==1 then
   local b=Instance.new("Beam")
   b.Attachment0=pts[i] b.Attachment1=pts[i%n+1] b.FaceCamera=false b.Segments=1 b.LightEmission=1 b.LightInfluence=0
   b.Width0=width b.Width1=width b.Color=ColorSequence.new(color) b.Transparency=NumberSequence.new(alpha) b.Parent=carrier
   beams[#beams+1]=b
  end
 end
 return carrier,beams,pts
end
local function tint(beams,color)for _,b in ipairs(beams)do b.Color=ColorSequence.new(color)end end
 -- n slivers flung out of c on arcs, spinning, gone by `life`
local function shards(E,g,c,n,speed,size,colors,life)
 local list={}
 for i=1,n do
  local a=math.random()*math.pi*2
  list[i]={P=part(g,Vector3.new(size*.22,size*.22,size)*(.6+math.random()*.8),colors[(i-1)%#colors+1],0),
   V=Vector3.new(math.cos(a),.5+math.random()*.9,math.sin(a))*speed*(.6+math.random()*.6),R=CFrame.Angles(math.random()*6,math.random()*6,0),
   S=(math.random()-.5)*20}
 end
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  for _,s in ipairs(list)do
   parts[#parts+1]=s.P cfs[#cfs+1]=CFrame.new(c+s.V*t+Vector3.new(0,-45*t*t,0))*s.R*CFrame.Angles(t*s.S,t*s.S*.6,0)
   s.P.Transparency=math.clamp((t-life*.6)/(life*.4),0,1)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<life
 end)
end
 -- rock thrown up out of the ground
local function debris(E,g,c,n,power)
 power=power or 1
 local rocks={}
 for i=1,n do
  local p=part(g,Vector3.one*(.6+math.random()*1.6)*power,Color3.fromRGB(150,112,48),0,nil,Enum.Material.Slate)
  local a=math.random()*math.pi*2
  local out=(8+math.random()*18)*power
  rocks[i]={P=p,V=Vector3.new(math.cos(a)*out,(26+math.random()*26)*power,math.sin(a)*out),R=CFrame.Angles(math.random()*6,math.random()*6,0)}
 end
 E.Step(g,function(_,t)
  local parts,cfs={},{}
  for _,r in ipairs(rocks)do
   parts[#parts+1]=r.P cfs[#cfs+1]=CFrame.new(c+r.V*t+Vector3.new(0,-38*t*t,0))*r.R*CFrame.Angles(t*5,t*3,0)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if t>1.4 then for _,r in ipairs(rocks)do r.P.Transparency=1 end return false end
  return true
 end)
end
 -- glowing cracks splitting out across the floor from c
local function cracks(E,g,c,R,n,color,life)
 local floor=groundAt(E,c+UP*3,g)
 local at=(floor or c)+UP*.08
 for i=1,n do
  local a=(i-1)*math.pi*2/n+math.random()*.5
  local len=R*(.55+math.random()*.7)
  local dir=Vector3.new(math.cos(a),0,math.sin(a))
  local cf=CFrame.lookAt(at+dir*len/2,at+dir*len)
  local p=part(g,Vector3.new(.3+math.random()*.35,.06,len),color,.05)
  local q=part(g,Vector3.new(1.6,.05,len),UMBER,.5,nil,Enum.Material.SmoothPlastic)
  p.CFrame=cf q.CFrame=cf
  E.Tween(p,life*.5,{Transparency=1},nil,nil,life*.5)
  E.Tween(q,life*.4,{Transparency=1},nil,nil,life*.4)
 end
end
 -- a one-shot burst of stylized flame and smoke thrown along `frame`'s look (with Drag 5 a flame thrown at v stops
 -- about v/5 out, so these roll to a stop around Reach)
local function fireBlast(E,g,frame,o)
 local R,S,spread=o.Reach or 15,o.Size or 6,o.Spread or 30
 local muzzle=part(g,Vector3.new(o.Width or 1,o.Width or 1,.2),WHITE,1)
 muzzle.CFrame=frame
 local function emit(n,props)
  local p=Instance.new("ParticleEmitter")
  p.Rate=0 p.LightInfluence=0 p.EmissionDirection=Enum.NormalId.Front p.SpreadAngle=Vector2.new(spread,spread*.6)
  p.Shape=Enum.ParticleEmitterShape.Box
  for k,v in pairs(props)do p[k]=v end
  p.Parent=muzzle p:Emit(n)
 end
 local hot=o.Hot or Color3.fromRGB(255,214,120)
 emit(o.Count or 30,{Texture=FIRE_BODY,FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,FlipbookMode=Enum.ParticleFlipbookMode.OneShot,
  Color=ColorSequence.new({ColorSequenceKeypoint.new(0,hot),ColorSequenceKeypoint.new(.25,Color3.fromRGB(255,130,26)),
   ColorSequenceKeypoint.new(.6,Color3.fromRGB(196,52,12)),ColorSequenceKeypoint.new(1,Color3.fromRGB(70,22,10))}),
  LightEmission=.1,Brightness=1.3,Size=ns(0,S*.35,.25,S,1,S*1.4),Transparency=ns(0,0,.55,.15,1,1),Lifetime=NumberRange.new(.45,.8),
  Speed=NumberRange.new(R*4.2,R*5.8),Drag=5,Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-70,70)})
 emit(math.floor((o.Count or 30)*.6),{Texture=FIRE_TOON,FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4,FlipbookMode=Enum.ParticleFlipbookMode.OneShot,
  Color=ColorSequence.new(Color3.fromRGB(255,246,200),Color3.fromRGB(255,150,40)),LightEmission=.4,Brightness=1.6,Size=ns(0,S*.25,.3,S*.6,1,S*.3),
  Transparency=ns(0,0,.7,.2,1,1),Lifetime=NumberRange.new(.3,.5),Speed=NumberRange.new(R*4.5,R*6.5),Drag=6,Rotation=NumberRange.new(0,360)})
 local a=E.Anchor(g,frame)
 if (o.Smoke or 0)>0 then
  E.Emit(a,{tex="smoke",light=0,size={{0,S*.5},{1,S*2.4}},alpha={{0,.3},{.3,.2},{1,1}},color={{0,Color3.fromRGB(70,58,50)},{1,Color3.fromRGB(32,30,30)}},
   life={1,1.7},speed={R*2.4,R*3.4},spread=spread*.8,dir=Enum.NormalId.Front,drag=3,accel=Vector3.new(0,5,0)},o.Smoke)
 end
 if (o.Embers or 0)>0 then
  E.Emit(a,{tex="star.crisp",size={{0,.9},{1,0}},color={{0,WHITE},{1,AMBER}},life={.3,.7},speed={R*3,R*6},spread=spread,dir=Enum.NormalId.Front,drag=2,
   accel=Vector3.new(0,-30,0)},o.Embers)
 end
 return a
end
 -- the slash meshes (VFXEngine.Assets): a bright core, a coloured glow copy behind it, a streak swirl
local function mesh(g,name,width,color,alpha)
 local template=ASSETS[name]
 local p=template:Clone()
 p.Size=template.Size*(width/template.Size.X)
 p.Color=color p.Transparency=alpha or 0 p.TextureID="" p.Material=NEON
 p.CFrame=HIDDEN p.Parent=g.Folder
 return p
end
local function slash(g,width,core,glow,streak)
 local layers={
  {Part=mesh(g,"ArcSlash",width,core,.02),Offset=CFrame.new()},
  {Part=mesh(g,"ArcSlash",width*1.16,glow,.38),Offset=CFrame.new(0,-width*.02,.2)},
 }
 if streak then
  layers[#layers+1]={Part=mesh(g,"StreakSlash",width*1.3,streak,.4),Offset=CFrame.new(0,0,.4)*CFrame.Angles(math.pi/2,0,0)}
 end
 for _,l in ipairs(layers)do l.Base=l.Part.Size l.Alpha=l.Part.Transparency end
 return layers
end
local function place(layers,frame,scale,fade,parts,cfs)
 for _,l in ipairs(layers)do
  if scale then l.Part.Size=l.Base*scale end
  if fade then l.Part.Transparency=l.Alpha+(1-l.Alpha)*fade end
  parts[#parts+1]=l.Part cfs[#cfs+1]=frame*l.Offset
 end
end
 -- an afterimage: every visible part of `model` copied as it stands, fading out over `life`
local function echo(E,g,model,color,alpha,life)
 local list={}
 for _,p in ipairs(model:GetDescendants())do
  if p:IsA("BasePart")and p.Name~="HumanoidRootPart"and p.Transparency<.9 and p.Size.Magnitude<12 and not p:IsDescendantOf(g.Folder)then
   local q=part(g,p.Size,color,alpha) q.CFrame=p.CFrame
   list[#list+1]=q
   E.Tween(q,life,{Transparency=1})
  end
 end
 E.After(g,life+.05,function()for _,q in ipairs(list)do q:Destroy()end end)
end

 -- a gold fan on the floor from angle a0 to a1 (the sweep) out to R: flat wedge beams, dark and unlit inside so they
 -- read on the gold floor, with a bright edge along the arc and the two sides; grow(k) draws it out to k*R
local function fan(g,c,a0,a1,R)
 local carrier=part(g,Vector3.one*.2,WHITE,1)
 carrier.CFrame=CFrame.new(c)
 local span=a1-a0
 local n=math.max(4,math.ceil(math.abs(span)/.16))
 local step=span/n
 local slices,edges={}, {}
 for i=1,n do
  local a=a0+step*(i-.5)
  local dir=look(a)
  local perp=dir:Cross(UP)
  local inner=Instance.new("Attachment") inner.CFrame=CFrame.fromMatrix(Vector3.zero,UP,perp) inner.Parent=carrier
  local outer=Instance.new("Attachment") outer.CFrame=CFrame.fromMatrix(dir*R,UP,perp) outer.Parent=carrier
  local b=Instance.new("Beam")
  b.Attachment0=inner b.Attachment1=outer b.FaceCamera=false b.Segments=1 b.LightEmission=0 b.LightInfluence=0
  b.Color=ColorSequence.new(Color3.fromRGB(150,80,10),UMBER) b.Transparency=ns(0,.95,.5,.72,1,.55)
  b.Width0=.1 b.Width1=2*R*math.tan(math.abs(step)/2)*1.08 b.Parent=carrier
  slices[i]={B=b,Out=outer,Dir=dir,W=b.Width1}
 end
  -- the bright edge: the arc and the two sides
 local arc={}
 for i=0,n do
  local a=a0+step*i
  local dir=look(a)
  local at=Instance.new("Attachment") at.CFrame=CFrame.fromMatrix(dir*R,UP,dir) at.Parent=carrier
  arc[i]={At=at,Dir=dir}
 end
 for i=1,n do
  local b=Instance.new("Beam")
  b.Attachment0=arc[i-1].At b.Attachment1=arc[i].At b.FaceCamera=false b.Segments=1 b.LightEmission=1 b.LightInfluence=0
  b.Color=ColorSequence.new(SHINE) b.Transparency=NumberSequence.new(.15) b.Width0=.9 b.Width1=.9 b.Parent=carrier
  edges[#edges+1]=b
 end
 for _,a in ipairs({a0,a1})do
  local dir=look(a)
  local perp=dir:Cross(UP)
  local i0=Instance.new("Attachment") i0.CFrame=CFrame.fromMatrix(Vector3.zero,UP,perp) i0.Parent=carrier
  local i1=Instance.new("Attachment") i1.CFrame=CFrame.fromMatrix(dir*R,UP,perp) i1.Parent=carrier
  local b=Instance.new("Beam")
  b.Attachment0=i0 b.Attachment1=i1 b.FaceCamera=false b.Segments=1 b.LightEmission=1 b.LightInfluence=0
  b.Color=ColorSequence.new(GOLD) b.Transparency=ns(0,.8,1,.1) b.Width0=.3 b.Width1=.8 b.Parent=carrier
  edges[#edges+1]=b
  arc[#arc+1]={At=i1,Dir=dir,Side=true}
 end
 local f={Carrier=carrier,Edges=edges,Slices=slices}
 function f.grow(k,fade)
  k=math.max(k,.02)
  for _,s in ipairs(slices)do
   s.Out.Position=s.Dir*R*k
   s.B.Width1=s.W*k
   if fade then s.B.Transparency=ns(0,.95+.05*fade,.5,.72+.28*fade,1,.55+.45*fade)end
  end
  for _,a in pairs(arc)do a.At.Position=a.Dir*R*k end
  if fade then for _,b in ipairs(edges)do b.Transparency=NumberSequence.new(.15+.85*fade)end end
 end
 f.grow(.02)
 return f
end

function P.MatterCharge(E,d)
 local boss=d.Boss
 local r=rootOf(boss)
 if not r then return end
 local g=E.Group("P5MatterCharge")
 local T=d.Time or 1.6
 local R=d.Range or 70
 local floor=groundAt(E,d.Origin+UP*3,g,boss)
 local c=(floor or d.Origin)+UP*.14
 local fans={}
 local full=math.abs(d.Sweep or 0)>=math.pi*2-.01  -- a full circle: one disc covers every beam
 for i,off in ipairs(d.Offsets or{0})do
  if not full or i==1 then fans[#fans+1]=fan(g,c,d.Start+off,d.Start+(d.Sweep or 0)+off,R)end
 end
  -- the orb: golden matter packing itself into his palm
 local core=part(g,Vector3.one*.4,SHINE,0,BALL)
 local shell=part(g,Vector3.one*.8,GOLD,.1,BALL,FF)
 local hold=E.Anchor(g,r.CFrame)
 local suck=part(g,Vector3.one*16,WHITE,1)
 local motes=Instance.new("ParticleEmitter")
 motes.Texture=E.Lib.Id("star.tiny") motes.Shape=Enum.ParticleEmitterShape.Sphere motes.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
 motes.ShapeInOut=Enum.ParticleEmitterShapeInOut.Inward motes.Speed=NumberRange.new(14,20) motes.Lifetime=NumberRange.new(.4,.55)
 motes.Size=ns(0,.7,1,0) motes.Color=ColorSequence.new(SHINE,GOLD) motes.LightEmission=1 motes.LightInfluence=0 motes.Rate=70*E.Quality
 motes.Parent=suck
 E.Sprite(hold,{tex="star.lens",size={{0,1},{1,7}},alpha={{0,.6},{.9,.1},{1,1}},color=SHINE,spin={140,140}},T)
 local light=E.Light(g,hold,GOLD,16,1)
  -- the pull: streaks and dust sliding in across the floor from every side toward him
 local field=part(g,Vector3.new(120,1,120),WHITE,1)
 local streaks=Instance.new("ParticleEmitter")
 streaks.Texture=E.Lib.Id("wind.dash") streaks.Shape=Enum.ParticleEmitterShape.Disc streaks.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
 streaks.ShapeInOut=Enum.ParticleEmitterShapeInOut.Inward streaks.Orientation=Enum.ParticleOrientation.VelocityParallel
 streaks.Speed=NumberRange.new(55,75) streaks.Lifetime=NumberRange.new(.6,.9) streaks.Size=ns(0,1.6,1,.6) streaks.Squash=NumberSequence.new(-1)
 streaks.Color=ColorSequence.new(SHINE,GOLD) streaks.Transparency=ns(0,1,.2,.45,1,1) streaks.LightEmission=1 streaks.LightInfluence=0
 streaks.Rate=50*E.Quality streaks.Parent=field
 local dust=Instance.new("ParticleEmitter")
 dust.Texture=E.Lib.Id("smoke") dust.Shape=Enum.ParticleEmitterShape.Disc dust.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
 dust.ShapeInOut=Enum.ParticleEmitterShapeInOut.Inward dust.Speed=NumberRange.new(30,45) dust.Lifetime=NumberRange.new(1,1.4)
 dust.Size=ns(0,3,1,7) dust.Color=ColorSequence.new(Color3.fromRGB(190,150,80),Color3.fromRGB(120,95,50)) dust.Transparency=ns(0,1,.3,.7,1,1)
 dust.LightEmission=0 dust.LightInfluence=0 dust.Rate=18*E.Quality dust.Parent=field
 E.Step(g,function(_,t)
  local root=rootOf(boss)
  local k=math.clamp(t/T,0,1)
  if root then
   local at=(root.CFrame*CFrame.new(1.2,.5,-2.4)).Position
   local s=.4+2.4*smooth(k)
   core.Size=Vector3.one*s shell.Size=Vector3.one*(s*1.7)
   workspace:BulkMoveTo({core,shell,hold,suck,field},{CFrame.new(at),CFrame.new(at)*CFrame.Angles(t*2,t*3,0),CFrame.new(at),CFrame.new(at),
    CFrame.new(c.X,c.Y+.5,c.Z)},Enum.BulkMoveMode.FireCFrameChanged)
   light.Brightness=1+7*k light.Range=16+20*k
  end
  for _,f in ipairs(fans)do f.grow(1-(1-math.min(k*1.4,1))^3)end
  if t>=T then
   motes.Enabled=false streaks.Enabled=false dust.Enabled=false
   local u=math.clamp((t-T)/.3,0,1)
   for _,f in ipairs(fans)do f.grow(1,u)end
   core.Transparency=u shell.Transparency=.1+.9*u
   return u<1
  end
  return true
 end)
 E.After(g,T+1.2,function()g:Destroy()end)
end

function P.MatterBeam(E,d)
 local boss=d.Boss
 local g=E.Group("P5MatterBeam")
 local R,W=d.Range or 70,d.Width or 5
 local ST,PA=d.SweepTime or 1.1,d.Pause or .35
 local total=ST*2+PA
 local start,sweep=d.Start or 0,d.Sweep or 0
 local floor=groundAt(E,d.Origin+UP*3,g,boss)
 local base=floor or d.Origin
 local beams={}
 for _,off in ipairs(d.Offsets or{0})do
  local b={Off=off}
  b.Core=part(g,Vector3.one,WHITE,0,CYL)
  b.Body=part(g,Vector3.one,BRIGHT,.3,CYL)
  b.Sheath=part(g,Vector3.one,AMBER,.2,CYL,FF)
  b.Start=E.Anchor(g,CFrame.new(base))
  b.End=E.Anchor(g,CFrame.new(base))
  local a0,a1=E.Attach(b.Start,CFrame.new()),E.Attach(b.End,CFrame.new())
  b.Glow=E.Beam(g,a0,a1,{color=GOLD,alpha={{0,.35},{1,.55}},width=W*2.6})
  b.Glow.FaceCamera=true b.Glow.LightEmission=1 b.Glow.LightInfluence=0
   -- where it bites into the floor: the brightest point of the whole effect
  E.Sprite(b.End,{tex="flare.burst",size=W*2.6,alpha={{0,1},{.04,.15},{.9,.25},{1,1}},color=SHINE,spin={200,200}},total)
  E.Sprite(b.End,{tex="glow.soft",size=W*4,alpha={{0,1},{.04,.35},{.9,.4},{1,1}},color=GOLD},total)
  b.Sparks=E.Stream(b.End,{tex="star.crisp",size={{0,1.2},{1,0}},color={{0,WHITE},{1,GOLD}},life={.25,.5},speed={18,40},spread=55,
   dir=Enum.NormalId.Top,accel=Vector3.new(0,-60,0),drag=1},70)
  b.Smoke=E.Stream(b.End,{tex="smoke",light=0,size={{0,2.5},{1,7}},alpha={{0,.55},{1,1}},color={{0,Color3.fromRGB(150,110,50)},{1,Color3.fromRGB(80,65,45)}},
   life={.6,1},speed={5,10},spread=40,dir=Enum.NormalId.Top,drag=1.5},20)
  b.Light=E.Light(g,b.End,GOLD,W*6,6)
  E.Sprite(b.Start,{tex="star.glare",size={{0,W*5},{.08,W*2.4},{1,W*2}},alpha={{0,0},{.9,.2},{1,1}},color=SHINE,rot={0,0}},total)
  beams[#beams+1]=b
 end
 local ring=part(g,Vector3.new(.2,W*1.2,W*1.2),SHINE,.1,CYL)
 E.Tween(ring,.35,{Size=Vector3.new(.1,W*7,W*7),Transparency=1},Enum.EasingStyle.Quint)
 grade(E,{Brightness=.1,Contrast=.15,TintColor=Color3.fromRGB(255,240,205)},.3)
 local lastScorch=0
 E.Step(g,function(_,t)
  local a
  local pass
  if t<=ST then a,pass=start+sweep*smooth(t/ST),1
  elseif t<=ST+PA then a,pass=start+sweep,0
  else a,pass=start+sweep*(1-smooth((t-ST-PA)/ST)),2 end
  local root=rootOf(boss)
  local origin=root and root.Position or base+UP*3
  local intro=math.clamp(t/.12,0,1)
  local outro=math.clamp((total-t)/.2,0,1)
  local thick=(pass==0 and .4 or 1)*(1+.07*math.sin(t*45))*outro  -- it thins while it holds, then swells for the way back
  local scorch=pass~=0 and t-lastScorch>=.04 and outro>0
  local parts,cfs={},{}
  for i,b in ipairs(beams)do
   local dir=look(a+b.Off)
   local s=origin+UP*1+dir*1.6
   local e=base+dir*R*intro+UP*.6
   local len=(e-s).Magnitude
   local mid=(s+e)/2
   local cf=CFrame.lookAt(mid,e)*CFrame.Angles(0,math.pi/2,0)
   b.Core.Size=Vector3.new(len,W*.32*thick,W*.32*thick)
   b.Body.Size=Vector3.new(len,W*.75*thick,W*.75*thick)
   b.Sheath.Size=Vector3.new(len,W*1.2*thick,W*1.2*thick)
   b.Glow.Width0=W*1.6*thick b.Glow.Width1=W*2.6*thick
   parts[#parts+1]=b.Core cfs[#cfs+1]=cf
   parts[#parts+1]=b.Body cfs[#cfs+1]=cf
   parts[#parts+1]=b.Sheath cfs[#cfs+1]=cf*CFrame.Angles(t*4,0,0)
   parts[#parts+1]=b.Start cfs[#cfs+1]=CFrame.new(s)
   parts[#parts+1]=b.End cfs[#cfs+1]=CFrame.new(e)
   if i==1 then parts[#parts+1]=ring cfs[#cfs+1]=CFrame.lookAt(s,e)*CFrame.Angles(0,math.pi/2,0)end
   b.Light.Brightness=6*thick
    -- the cut it leaves in the floor behind it
   if scorch then
    local q=part(g,Vector3.new(W*.5,.08,math.max(R*.04,1.6)),AMBER,.1)
    local at=base+dir*R+UP*.07
    q.CFrame=CFrame.lookAt(at,at+dir:Cross(UP))
    E.Tween(q,.9,{Transparency=1,Size=Vector3.new(.1,.08,q.Size.Z)},nil,nil,.2)
   end
  end
  if scorch then lastScorch=t end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if t>=total then
   for _,b in ipairs(beams)do b.Sparks.Enabled=false b.Smoke.Enabled=false b.Core.Transparency=1 b.Body.Transparency=1 b.Sheath.Transparency=1
    b.Glow.Enabled=false b.Light.Enabled=false end
   return false
  end
  return true
 end)
 E.After(g,total+1.4,function()g:Destroy()end)
end

-- Judgement Zone / Nullified Zone (replicated marker parts, tagged VFXDecorate)
local function judgement(E,marker)
 local g=E.Group("P5JudgementZone")
 local R=marker:GetAttribute("Radius")or 14
 local cur=marker.Position
 local y=cur.Y  -- the server puts the marker on the floor
  -- the field: a dark amber stain on the floor (unlit, so it reads on gold) under a shimmer of gold force
 local stain=part(g,Vector3.new(.06,R*2,R*2),Color3.fromRGB(110,58,8),.45,CYL,Enum.Material.SmoothPlastic)
 local shimmer=part(g,Vector3.new(.12,R*2,R*2),GOLD,.35,CYL,FF)
 local rim,rimBeams=flatRing(g,R,1.2,SHINE,.05,48)
 local ticks,tickBeams=flatRing(g,R*.82,.55,GOLD,.15,36,true)
 local hold=E.Anchor(g,CFrame.new(cur))
 local motes=E.Stream(hold,{tex="star.twinkle",size={{0,.7},{1,0}},color={{0,SHINE},{1,GOLD}},life={.8,1.3},speed={4,8},spread=25,dir=Enum.NormalId.Top},18)
 local light=E.Light(g,hold,GOLD,R*2,2)
 local gui=Instance.new("BillboardGui")
 gui.Size=UDim2.fromOffset(120,96) gui.StudsOffsetWorldSpace=Vector3.new(0,8,0) gui.AlwaysOnTop=true gui.LightInfluence=0 gui.MaxDistance=260
 gui.Adornee=hold
 local num=Instance.new("TextLabel")
 num.BackgroundTransparency=1 num.Size=UDim2.fromScale(1,1) num.Font=Enum.Font.GothamBlack num.TextScaled=true num.Text=""
 num.TextColor3=GOLD num.TextStrokeColor3=Color3.fromRGB(50,20,0) num.TextStrokeTransparency=0 num.Parent=gui
 local scale=Instance.new("UIScale") scale.Parent=num
 gui.Parent=g.Folder
 local lastSecond,red=nil,false
 E.Step(g,function(dt,t)
  if not marker.Parent then
   gui.Enabled=false motes.Enabled=false light.Enabled=false
   for _,p in ipairs({stain,shimmer})do E.Tween(p,.15,{Transparency=1})end
   tint(rimBeams,RED) tint(tickBeams,RED)
   E.After(g,.2,function()g:Destroy()end)
   return false
  end
  cur=cur:Lerp(marker.Position,math.min(1,dt*14))
  y=marker.Position.Y
  local cf=CFrame.new(cur.X,y+.1,cur.Z)
  local left=(marker:GetAttribute("EndsAt")or 0)-workspace:GetServerTimeNow()
  local state=marker:GetAttribute("State")
  if state=="Red"and not red then
   red=true
   stain.Color=BLOOD shimmer.Color=RED tint(rimBeams,RED) tint(tickBeams,RAGE) num.TextColor3=RED light.Color=RED
   num.Text="!"
   scale.Scale=1.6
   E.Tween(scale,.2,{Scale=1})
  end
  if not red then
   local sec=math.max(1,math.ceil(left))
   if sec~=lastSecond then
    lastSecond=sec
    num.Text=tostring(sec)
    scale.Scale=1.45
    E.Tween(scale,.25,{Scale=1},Enum.EasingStyle.Back)
   end
   local hot=math.clamp(1-left/3,0,1)  -- the last seconds burn toward red
   local col=GOLD:Lerp(RAGE,hot)
   num.TextColor3=col shimmer.Color=col
  end
  local pulse=red and(.5+.5*math.sin(t*40))or(.5+.5*math.sin(t*6))
  light.Brightness=red and 3+4*pulse or 1.6+pulse
  shimmer.Transparency=red and .15+.25*pulse or .35
  local flat=cf*CFrame.Angles(0,0,math.pi/2)
  workspace:BulkMoveTo({stain,shimmer,rim,ticks,hold},{flat,flat*CFrame.new(.05,0,0),cf,cf*CFrame.Angles(0,t*(red and 4 or .8),0),cf},
   Enum.BulkMoveMode.FireCFrameChanged)
  return true
 end)
end

local function nullified(E,marker)
 local g=E.Group("P5NullifiedZone")
 local R,H=marker:GetAttribute("Radius")or 26,marker:GetAttribute("Height")or 26
 local c=marker.Position  -- the server puts the marker on the floor
 local n=E.Quality<.6 and 28 or 44
 local chord=2*R*math.sin(math.pi/n)*1.04
  -- the barrier: panels of shimmering gold force standing all the way round, rising out of the floor
 local panels={}
 for i=1,n do
  local a=(i-1)/n*math.pi*2
  local dir=Vector3.new(math.cos(a),0,math.sin(a))
  panels[i]={P=part(g,Vector3.new(chord,.1,.35),GOLD,.12,nil,FF),Glow=part(g,Vector3.new(chord,.1,.3),BRIGHT,.55),
   Rib=i%4==1 and part(g,Vector3.new(.35,.1,.35),SHINE,.1)or nil,Edge=part(g,Vector3.new(chord,.25,.25),SHINE,.05),Dir=dir,
   CF=CFrame.lookAt(c+dir*R,c+dir*(R+1))}
 end
 local base,baseBeams=flatRing(g,R,2.6,AMBER,.2,n)
 base.CFrame=CFrame.new(c+UP*.12)
 local floorDark=part(g,Vector3.new(.05,R*2,R*2),Color3.fromRGB(90,50,10),.75,CYL,Enum.Material.SmoothPlastic)
 floorDark.CFrame=CFrame.new(c+UP*.06)*CFrame.Angles(0,0,math.pi/2)
  -- streaks of light running up the wall
 local risers={}
 for i=1,8 do
  local a=(i-1)/8*math.pi*2
  local an=E.Anchor(g,CFrame.new(c+Vector3.new(math.cos(a)*R,.5,math.sin(a)*R)))
  risers[i]=E.Stream(an,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,GOLD}},life={.8,1.2},speed={14,22},spread=4,dir=Enum.NormalId.Top},10)
 end
 local mid=E.Anchor(g,CFrame.new(c+UP*H*.5))
 local light=E.Light(g,mid,GOLD,R*2.2,1.6)
 E.Sprite(mid,{tex="flare.big",size={{0,4},{.15,R*2.6},{1,R*3}},alpha={{0,0},{.4,.4},{1,1}},color=SHINE},.45)
 local ending=nil
 E.Step(g,function(_,t)
  local rise=1-(1-math.clamp(t/.45,0,1))^3
  local left=(marker:GetAttribute("EndsAt")or 0)-workspace:GetServerTimeNow()
  if not marker.Parent and not ending then ending=t end
  local sink=ending and math.clamp((t-ending)/.35,0,1)or 0
  local h=math.max(H*rise*(1-sink),.1)
  local flick=left<3 and not ending and(.5+.5*math.sin(t*(30-left*6)))or 0
  local parts,cfs={},{}
  for _,p in ipairs(panels)do
   p.P.Size=Vector3.new(chord,h,.35) p.Glow.Size=Vector3.new(chord,h*.3,.3)
   p.P.Transparency=.12+.5*flick+.88*sink
   p.Glow.Transparency=.55+.3*flick+.45*sink
   p.Edge.Transparency=.05+.6*flick+.95*sink
   parts[#parts+1]=p.P cfs[#cfs+1]=p.CF*CFrame.new(0,h/2,0)
   parts[#parts+1]=p.Glow cfs[#cfs+1]=p.CF*CFrame.new(0,h*.15,-.1)
   if p.Rib then
    p.Rib.Size=Vector3.new(.35,h,.35) p.Rib.Transparency=.1+.6*flick+.9*sink
    parts[#parts+1]=p.Rib cfs[#cfs+1]=p.CF*CFrame.new(chord/2,h/2,0)
   end
   parts[#parts+1]=p.Edge cfs[#cfs+1]=p.CF*CFrame.new(0,h,0)
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if ending then
   for _,r in ipairs(risers)do r.Enabled=false end
   light.Enabled=false
   floorDark.Transparency=.75+.25*sink
   for _,b in ipairs(baseBeams)do b.Transparency=NumberSequence.new(.2+.8*sink)end
   if sink>=1 then g:Destroy()return false end
  end
  return true
 end)
end

function P.Decorate(E,marker)
 local kind=marker:GetAttribute("Kind")
 if kind=="Judgement"then judgement(E,marker)
 elseif kind=="Nullified"then nullified(E,marker)end
end

function P.JudgementBoom(E,d)
 local g=E.Group("P5JudgementBoom")
 local R=d.Radius or 14
 local c=d.Pos  -- a floor point from the server
 local a=E.Anchor(g,CFrame.new(c+UP*2))
  -- judgement: a red-gold blast up out of the zone, a pillar of light, the ground splitting
 dome(E,g,c+UP*2,WHITE,4,R*1.3,.22,0)
 dome(E,g,c+UP*2,RED,5,R*2.6,.55,.25,FF)
 dome(E,g,c+UP*2,RAGE,4,R*1.8,.4,.35)
  -- (no sky laser any more: this is a proper fireball)
 
 
 
 
 
 fireBlast(E,g,CFrame.lookAt(c+UP*1,c+UP*10),{Reach=R*1.8,Spread=24,Count=40,Size=R*1.1,Width=R*.8,Smoke=18,Embers=40,Hot=Color3.fromRGB(255,190,120)})
  -- the classic blast: fire thrown out low in every direction, a rolling skirt of dust and the smoke column rising on top
 for i=1,8 do
  local ang=i*math.pi/4+math.random()*.3
  local dir=Vector3.new(math.cos(ang),.2,math.sin(ang))
  fireBlast(E,g,CFrame.lookAt(c+UP*1.5,c+UP*1.5+dir),{Reach=R*.9,Spread=20,Count=10,Size=R*.55,Width=2,Smoke=0,Embers=0,Hot=Color3.fromRGB(255,190,120)})
 end
 local skirt=E.Anchor(g,CFrame.new(c+UP*.2))
 E.Emit(skirt,{tex="smoke",light=0,size={{0,5},{1,14}},alpha={{0,.35},{1,1}},color={{0,Color3.fromRGB(150,110,80)},{1,Color3.fromRGB(70,55,50)}},
  life={1.2,1.8},speed={30,48},spread=180,dir=Enum.NormalId.Top,drag=2.5},30)
 E.Emit(a,{tex="smoke",light=0,size={{0,6},{1,18}},alpha={{0,.3},{1,1}},color={{0,Color3.fromRGB(110,70,50)},{1,Color3.fromRGB(40,34,32)}},
  life={1.5,2.2},speed={18,30},spread=25,dir=Enum.NormalId.Top,drag=1.2,accel=Vector3.new(0,6,0)},18)
 E.Sprite(a,{tex="flare.big",size={{0,4},{.12,R*2.6},{1,R*3}},alpha={{0,0},{.5,.35},{1,1}},color=SHINE},.4)
 E.Sprite(a,{tex="burst.spiky2",size={{0,3},{1,R*2.4}},alpha={{0,0},{1,1}},color=RAGE,rot={0,360}},.35)
 local f=E.Anchor(g,CFrame.new(c+UP*.15))
 E.Sprite(f,{tex="ring.crisp",orient="flat",size={{0,R*.6},{1,R*2.8}},alpha={{0,0},{1,1}},color=BLOOD,light=0},.45)
 shards(E,g,c+UP*2,12,36,2.4,{WHITE,GOLD,RAGE},.75)
 debris(E,g,c+UP,10)
 cracks(E,g,c,R*1.3,10,RAGE,1.4)
 E.Light(g,a,RAGE,R*4,14,.7)
 grade(E,{Brightness=.26,Contrast=.25,TintColor=Color3.fromRGB(255,215,205)},.5)
 E.After(g,2.6,function()g:Destroy()end)
end

function P.NullifiedEnd(E,d)
 local g=E.Group("P5NullifiedEnd")
 local R,H=d.Radius or 26,d.Height or 26
 local c=d.Pos
  -- the barrier shatters: a ring of gold glass thrown outward, a flash running round the floor
 for i=1,8 do
  local ang=(i-1)/8*math.pi*2
  shards(E,g,c+Vector3.new(math.cos(ang)*R,H*.4,math.sin(ang)*R),4,22,2,{SHINE,GOLD},.7)
 end
 local f=E.Anchor(g,CFrame.new(c+UP*.15))
 E.Sprite(f,{tex="ring.crisp",orient="flat",size={{0,R*1.9},{1,R*2.5}},alpha={{0,0},{1,1}},color=GOLD},.4)
 E.Light(g,E.Anchor(g,CFrame.new(c+UP*6)),GOLD,R*2,6,.4)
 E.After(g,1.2,function()g:Destroy()end)
end

 -- the rage that stays on him through the whole rampage: red-gold flame off his body and a red outline
local function rage(E,g,boss,T)
 local r=rootOf(boss)
 if not r then return end
 local body=part(g,Vector3.new(3.4,5.6,2.2),WHITE,1)
 local tongues=Instance.new("ParticleEmitter")
 tongues.Texture=FIRE_TOON tongues.FlipbookLayout=Enum.ParticleFlipbookLayout.Grid4x4 tongues.FlipbookMode=Enum.ParticleFlipbookMode.OneShot
 tongues.LightInfluence=0 tongues.LightEmission=.5 tongues.Brightness=1.6 tongues.Shape=Enum.ParticleEmitterShape.Box
 tongues.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume tongues.EmissionDirection=Enum.NormalId.Top
 tongues.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,236,180)),ColorSequenceKeypoint.new(.35,Color3.fromRGB(255,120,40)),
  ColorSequenceKeypoint.new(1,AMBER)})
 tongues.Size=ns(0,1.6,.4,2.8,1,.6) tongues.Squash=NumberSequence.new(.5) tongues.Transparency=ns(0,.2,.7,.3,1,1)
 tongues.Lifetime=NumberRange.new(.4,.65) tongues.Speed=NumberRange.new(4,8) tongues.Acceleration=UP*10 tongues.Rate=60*E.Quality tongues.Parent=body
 local outline=Instance.new("Highlight")
 outline.FillColor=AMBER outline.FillTransparency=.7 outline.OutlineColor=Color3.fromRGB(255,190,120) outline.OutlineTransparency=0
 outline.DepthMode=Enum.HighlightDepthMode.Occluded outline.Adornee=boss outline.Parent=g.Folder
 local light=E.Light(g,body,AMBER,22,3)
 E.Step(g,function(_,t)
  local root=rootOf(boss)
  if not root or t>=T then
   tongues.Enabled=false light.Enabled=false outline:Destroy()
   return false
  end
  body.CFrame=root.CFrame
  light.Brightness=3+1.5*math.sin(t*14)
  return true
 end)
end

function P.RampageRoar(E,d)
 local boss=d.Boss
 local r=rootOf(boss)
 if not r then return end
 local T=d.Time or 4
 local g=E.Group("P5RampageRoar")
 rage(E,g,boss,T)
 local head=boss:FindFirstChild("Head")
 local at=head and head.Position or r.Position+UP*2
 local a=E.Anchor(g,CFrame.new(at))
  -- the roar: rings of sound rolling off him one after another, a flare at the mouth, the floor's dust blown out
 E.Sprite(a,{tex="flare.burst",size={{0,3},{.2,16},{1,20}},alpha={{0,0},{1,1}},color=AMBER},.5)
 E.Sprite(a,{tex="star.glare",size={{0,2},{.2,26},{1,8}},alpha={{0,0},{1,1}},color=GOLD,rot={15,15}},.4)
 for i=0,2 do
  E.After(g,i*.16,function()
   E.Sprite(a,{tex="ring.crisp",size={{0,4},{1,60}},alpha={{0,.1},{.6,.5},{1,1}},color=i==1 and GOLD or AMBER},.55)
  end)
 end
 local floor=E.Ground(r.Position,{boss,g.Folder})
 local f=E.Anchor(g,CFrame.new((floor or r.Position-UP*3)+UP*.2))
 E.Sprite(f,{tex="ring.soft",orient="flat",size={{0,4},{1,70}},alpha={{0,.2},{1,1}},color=AMBER},.6)
 E.Emit(f,{tex="smoke",light=0,size={{0,3},{1,9}},alpha={{0,.4},{1,1}},color={{0,Color3.fromRGB(170,130,70)},{1,Color3.fromRGB(110,85,50)}},
  life={.6,1},speed={40,60},spread=180,drag=3},26)
 E.Emit(a,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,AMBER}},life={.4,.7},speed={30,60},spread=180,drag=2.5},30)
 E.Light(g,a,AMBER,40,8,.6)
 grade(E,{Brightness=.08,Contrast=.25,Saturation=.15,TintColor=Color3.fromRGB(255,210,200)},.6)
 E.After(g,T+.5,function()g:Destroy()end)
end

function P.RampageSprint(E,d)
 local boss=d.Boss
 local r=rootOf(boss)
 if not r then return end
 local T=d.Time or 2.2
 local g=E.Group("P5RampageSprint")
  -- the run: a red-gold trail off him, dust torn up at his feet, afterimages left behind
 local top=Instance.new("Attachment") top.Position=Vector3.new(0,2.6,0) top.Parent=r
 local bottom=Instance.new("Attachment") bottom.Position=Vector3.new(0,-2.6,0) bottom.Parent=r
 local trail=Instance.new("Trail")
 trail.Attachment0=top trail.Attachment1=bottom trail.Lifetime=.28 trail.LightEmission=1 trail.LightInfluence=0 trail.FaceCamera=true
 trail.Color=ColorSequence.new(SHINE,AMBER) trail.Transparency=ns(0,.25,1,1) trail.Parent=r
 local feet=E.Anchor(g,r.CFrame)
 local dust=E.Stream(feet,{tex="smoke",light=0,size={{0,2},{1,6}},alpha={{0,.45},{1,1}},color={{0,Color3.fromRGB(170,130,70)},{1,Color3.fromRGB(110,85,50)}},
  life={.4,.7},speed={6,12},spread=50,dir=Enum.NormalId.Back,drag=2},40)
 local sparks=E.Stream(feet,{tex="star.crisp",size={{0,.8},{1,0}},color={{0,WHITE},{1,AMBER}},life={.2,.4},speed={10,20},spread=40,dir=Enum.NormalId.Back,
  accel=Vector3.new(0,-30,0)},40)
 local nextEcho=0
 E.Step(g,function(_,t)
  local root=rootOf(boss)
  if not root or t>=T then
   dust.Enabled=false sparks.Enabled=false trail.Enabled=false
   E.After(g,.35,function()top:Destroy()bottom:Destroy()trail:Destroy()end)
   return false
  end
  feet.CFrame=root.CFrame*CFrame.new(0,-2.8,0)
  if t>=nextEcho and E.Quality>=.6 then
   nextEcho=t+.2
   echo(E,g,boss,AMBER,.55,.3)
  end
  return true
 end)
 E.After(g,T+1,function()g:Destroy()end)
end

function P.RampageSlash(E,d)
 local g=E.Group("P5RampageSlash")
 local frame=d.Frame
 local i=d.Index or 1
 local side=i%2==1 and 1 or -1
 local layers=slash(g,20,SHINE,AMBER,GOLD)
 local roll=side*(.25+math.random()*.35)
 local base=frame*CFrame.new(0,.6,-5)*CFrame.Angles(0,0,roll)*CFrame.Angles(-math.pi/2,0,0)
 local a=E.Anchor(g,frame*CFrame.new(side*3,1,-8))
 E.Emit(a,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,AMBER}},life={.2,.4},speed={20,40},spread=60,dir=Enum.NormalId.Front,drag=2},12)
  -- a scrape on the floor where the blade bit in
 local floor=E.Ground(frame.Position,{d.Boss,g.Folder})
 if floor then
  local mark=part(g,Vector3.new(.5,.06,9),AMBER,.1)
  mark.CFrame=CFrame.new(floor+UP*.07)*frame.Rotation*CFrame.new(side*1.5,0,-6)*CFrame.Angles(0,side*.9,0)
  E.Tween(mark,.5,{Transparency=1},nil,nil,.15)
 end
 E.Step(g,function(_,t)
  local k=math.clamp(t/.09,0,1)
  local parts,cfs={},{}
  place(layers,base*CFrame.Angles(0,0,side*(1-(1-(1-k)^3))*.9),.85+.25*k,t<.1 and 0 or math.clamp((t-.12)/.16,0,1),parts,cfs)
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  return t<.3
 end)
 E.After(g,.8,function()g:Destroy()end)
end

function P.RampageLock(E,d)
 local g=E.Group("P5RampageLock")
 local lane,L,W,T=d.Frame,d.Length or 90,d.Width or 8,d.Time or .8
 local floor=E.Ground(lane.Position+UP*3,{d.Boss,g.Folder})
 local base=CFrame.new(Vector3.new(lane.X,(floor or lane.Position).Y,lane.Z))*lane.Rotation
  -- the path, dark and unlit on the floor with bright edges, chevrons racing down it to where it will all go off
 local fill=part(g,Vector3.new(W*2,.06,L),UMBER,.55,nil,Enum.Material.SmoothPlastic)
 fill.CFrame=base*CFrame.new(0,.06,-L/2)
 for _,s in ipairs({-1,1})do
  local e=part(g,Vector3.new(.45,.08,L),AMBER,.05)
  e.CFrame=base*CFrame.new(s*W,.08,-L/2)
 end
 local chevrons={}
 for i=1,6 do
  local v={}
  for _=1,2 do v[#v+1]=part(g,Vector3.new(.5,.08,W*.9),SHINE,.1)end
  chevrons[i]={V=v,Off=(i-1)/6}
 end
  -- a beacon of red light standing where the path ends
 local endAt=base*CFrame.new(0,0,-L)
 local beacon=part(g,Vector3.new(60,1.2,1.2),AMBER,.2,CYL)
 beacon.CFrame=endAt*CFrame.new(0,30,0)*CFrame.Angles(0,0,math.pi/2)
 local glow=E.Anchor(g,endAt*CFrame.new(0,2,0))
 E.Sprite(glow,{tex="glow.soft",size={{0,4},{1,(d.Blast or 22)*1.2}},alpha={{0,.6},{1,.35}},color=AMBER},T)
 E.Light(g,glow,AMBER,30,3,T+.1)
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local parts,cfs={},{}
  for _,c in ipairs(chevrons)do
   local u=(c.Off+t*1.6)%1
   local z=-L*u
   for j,p in ipairs(c.V)do
    local s=j==1 and -1 or 1
    parts[#parts+1]=p cfs[#cfs+1]=base*CFrame.new(s*W*.32,.1,z)*CFrame.Angles(0,s*.75,0)
    p.Transparency=.1+.6*(1-math.sin(u*math.pi))  -- each chevron fades in and out along the run
   end
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  local pulse=.5+.5*math.sin(t*(12+k*20))
  fill.Transparency=.55-.15*pulse
  beacon.Size=Vector3.new(60,.6+1.2*k,.6+1.2*k)
  return t<T
 end)
 E.After(g,T,function()g:Destroy()end)
end

function P.RampageCut(E,d)
 local g=E.Group("P5RampageCut")
 local lane,L,W=d.Frame,d.Length or 90,d.Width or 8
 local floor=E.Ground(lane.Position+UP*3,{d.Boss,g.Folder})
 local base=CFrame.new(Vector3.new(lane.X,(floor or lane.Position).Y,lane.Z))*lane.Rotation
  -- one flash down the whole path: a white-hot line of light with a red-gold sheet over it, standing upright like the
  -- blade's arc, his streak through it, the ground split along it and the air torn up behind
 local line=part(g,Vector3.new(1.4,.1,L),WHITE,0)
 local sheet=part(g,Vector3.new(.3,12,L),BRIGHT,.35)
 local glow=part(g,Vector3.new(W*1.8,.08,L),AMBER,.4)
 local streak=part(g,Vector3.new(L,2.4,2.4),SHINE,.15,CYL)  -- a cylinder runs along X: turned to run down the path
 line.CFrame=base*CFrame.new(0,.1,-L/2)
 sheet.CFrame=base*CFrame.new(0,6,-L/2)
 glow.CFrame=base*CFrame.new(0,.08,-L/2)
 streak.CFrame=base*CFrame.new(0,3,-L/2)*CFrame.Angles(0,math.pi/2,0)
 E.Tween(sheet,.3,{Size=Vector3.new(.05,22,L),Transparency=1},Enum.EasingStyle.Quad)
 E.Tween(streak,.22,{Size=Vector3.new(L,.2,.2),Transparency=1},Enum.EasingStyle.Quad)
 E.Tween(line,.9,{Transparency=1,Size=Vector3.new(.3,.1,L)},nil,nil,.35)
 E.Tween(glow,.6,{Transparency=1},nil,nil,.2)
 local n=math.clamp(math.floor(L/10),3,10)
 for i=1,n do
  local a=E.Anchor(g,base*CFrame.new(0,1,-L*(i-.5)/n))
  E.Emit(a,{tex="smoke",light=0,size={{0,2},{1,6}},alpha={{0,.45},{1,1}},color={{0,Color3.fromRGB(170,130,70)},{1,Color3.fromRGB(110,85,50)}},
   life={.5,.9},speed={8,16},spread=70,dir=Enum.NormalId.Top,drag=2},4)
  E.Emit(a,{tex="star.crisp",size={{0,1},{1,0}},color={{0,WHITE},{1,AMBER}},life={.25,.5},speed={18,36},spread=80,dir=Enum.NormalId.Top,
   accel=Vector3.new(0,-40,0)},6)
 end
 local mid=E.Anchor(g,base*CFrame.new(0,3,-L/2))
 E.Light(g,mid,GOLD,L*.6,8,.4)
 grade(E,{Brightness=.16,Contrast=.2,TintColor=Color3.fromRGB(255,232,210)},.3)
 E.After(g,1.6,function()g:Destroy()end)
end

function P.RampageFuse(E,d)
 local g=E.Group("P5RampageFuse")
 local T,R=d.Time or .35,d.Radius or 22
 local c=d.Pos
  -- the ground gathering itself: light sucked into the spot, the floor glowing hotter, then nothing for a heartbeat
 local suck=part(g,Vector3.one*R*1.2,WHITE,1)
 suck.CFrame=CFrame.new(c+UP*2)
 local motes=Instance.new("ParticleEmitter")
 motes.Texture=E.Lib.Id("star.crisp") motes.Shape=Enum.ParticleEmitterShape.Sphere motes.ShapeStyle=Enum.ParticleEmitterShapeStyle.Surface
 motes.ShapeInOut=Enum.ParticleEmitterShapeInOut.Inward motes.Speed=NumberRange.new(R*1.6,R*2) motes.Lifetime=NumberRange.new(.3,.35)
 motes.Size=ns(0,1,1,0) motes.Color=ColorSequence.new(SHINE,AMBER) motes.LightEmission=1 motes.LightInfluence=0 motes.Rate=180*E.Quality
 motes.Parent=suck
 local core=part(g,Vector3.one*1,SHINE,0,BALL)
 core.CFrame=CFrame.new(c+UP*.5)
 E.Tween(core,T,{Size=Vector3.one*5})
 cracks(E,g,c,R*.8,8,AMBER,T+.5)
 local a=E.Anchor(g,CFrame.new(c+UP*2))
 E.Light(g,a,AMBER,R*1.6,6,T+.1)
 E.After(g,T,function()motes.Enabled=false core.Transparency=1 end)
 E.After(g,T+1,function()g:Destroy()end)
end

function P.RampageBlast(E,d)
 local g=E.Group("P5RampageBlast")
 local R=d.Radius or 22
 local c=d.Pos
 local a=E.Anchor(g,CFrame.new(c+UP*3))
  -- the detonation: the flash first (the brightest thing in the fight), then fire up and out, a column of smoke, rock
  -- and gold glass thrown everywhere, the floor split wide
 dome(E,g,c+UP*2,WHITE,4,R*1.3,.22,0)
 dome(E,g,c+UP*2,AMBER,5,R*2.6,.55,.25,FF)
 dome(E,g,c+UP*2,AMBER,4,R*1.8,.4,.35)
 E.Sprite(a,{tex="flare.big",size={{0,6},{.1,R*3.2},{1,R*3.6}},alpha={{0,0},{.4,.3},{1,1}},color=SHINE},.45)
 E.Sprite(a,{tex="burst.spiky2",size={{0,4},{1,R*2.8}},alpha={{0,0},{1,1}},color=GOLD,rot={0,360}},.4)
 fireBlast(E,g,CFrame.lookAt(c+UP*1,c+UP*10),{Reach=R*1.8,Spread=24,Count=40,Size=R*1.1,Width=R*.8,Smoke=18,Embers=40})
 for i=1,8 do
  local ang=i*math.pi/4+math.random()*.3
  local dir=Vector3.new(math.cos(ang),.2,math.sin(ang))
  fireBlast(E,g,CFrame.lookAt(c+UP*1.5,c+UP*1.5+dir),{Reach=R*.9,Spread=20,Count=10,Size=R*.55,Width=2,Smoke=0,Embers=0})
 end
 local f=E.Anchor(g,CFrame.new(c+UP*.2))
 E.Emit(f,{tex="smoke",light=0,size={{0,5},{1,14}},alpha={{0,.35},{1,1}},color={{0,Color3.fromRGB(150,120,80)},{1,Color3.fromRGB(70,60,50)}},
  life={1.2,1.8},speed={30,48},spread=180,dir=Enum.NormalId.Top,drag=2.5},30)
 E.Emit(a,{tex="smoke",light=0,size={{0,6},{1,18}},alpha={{0,.3},{1,1}},color={{0,Color3.fromRGB(110,80,50)},{1,Color3.fromRGB(40,35,32)}},
  life={1.5,2.2},speed={18,30},spread=25,dir=Enum.NormalId.Top,drag=1.2,accel=Vector3.new(0,6,0)},18)
 shards(E,g,c+UP*3,18,48,3,{WHITE,GOLD,BRIGHT,AMBER},.9)
 debris(E,g,c+UP,16,1.3)
 cracks(E,g,c,R*1.6,14,AMBER,2)
 E.Light(g,a,GOLD,R*4,14,.7)
 grade(E,{Brightness=.28,Contrast=.25,TintColor=Color3.fromRGB(255,228,196)},.5)
 E.After(g,2.6,function()g:Destroy()end)
end

function P.RampageWall(E,d)
 local g=E.Group("P5RampageWall")
 local speed,range,H=d.Speed or 70,d.Range or 80,d.Height or 16
 local T=range/speed
 local c=d.Pos
  -- a tall wall of force rolling out in a ring: hot panels with a white-hot top edge, dust torn up at its foot
 local n=E.Quality<.6 and 28 or 44
 local panels={}
 for i=1,n do
  local ang=(i-1)/n*math.pi*2
  panels[i]={P=part(g,Vector3.one,AMBER,.45,nil,FF),Glow=part(g,Vector3.one,BRIGHT,.7),Edge=part(g,Vector3.one,SHINE,0),
   Dir=Vector3.new(math.cos(ang),0,math.sin(ang))}
 end
 local dust={}
 for i=1,8 do
  local ang=(i-1)/8*math.pi*2+math.random()*.4
  local an=E.Anchor(g,CFrame.new(c))
  dust[i]={A=an,Dir=Vector3.new(math.cos(ang),0,math.sin(ang)),
   S=E.Stream(an,{tex="smoke",light=0,size={{0,3},{1,8}},alpha={{0,.45},{1,1}},color={{0,Color3.fromRGB(170,130,70)},{1,Color3.fromRGB(110,85,50)}},
    life={.4,.7},speed={8,16},spread=40,dir=Enum.NormalId.Top,drag=2},30)}
 end
 E.Step(g,function(_,t)
  local k=math.clamp(t/T,0,1)
  local r=math.max(range*(1-(1-k)^1.6),1)
  local h=H*(1-k*k*.6)
  local chord=2*r*math.sin(math.pi/n)*1.06
  local parts,cfs={},{}
  for _,p in ipairs(panels)do
   local at=c+p.Dir*r
   local cf=CFrame.lookAt(at,at+p.Dir)*CFrame.Angles(-.18,0,0)
   p.P.Size=Vector3.new(chord,h,.4) p.Glow.Size=Vector3.new(chord,h*.45,.3) p.Edge.Size=Vector3.new(chord,.5,.5)
   p.P.Transparency=.45+.55*k^2 p.Glow.Transparency=.7+.3*k^2 p.Edge.Transparency=k^2
   parts[#parts+1]=p.P cfs[#cfs+1]=cf*CFrame.new(0,h/2,0)
   parts[#parts+1]=p.Glow cfs[#cfs+1]=cf*CFrame.new(0,h*.225,-.1)
   parts[#parts+1]=p.Edge cfs[#cfs+1]=cf*CFrame.new(0,h,0)
  end
  for _,dd in ipairs(dust)do parts[#parts+1]=dd.A cfs[#cfs+1]=CFrame.new(c+dd.Dir*r+UP*.5)end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if k>=1 then
   for _,dd in ipairs(dust)do dd.S.Enabled=false end
   for _,p in ipairs(panels)do p.P.Transparency=1 p.Glow.Transparency=1 p.Edge.Transparency=1 end
   return false
  end
  return true
 end)
 E.After(g,T+1,function()g:Destroy()end)
end


 -- the Nullified Zone's wall (Workspace.P5NullifiedWall): the server leaves its panels non-colliding so the boss and his
 -- attacks pass through; on this client they turn solid, and since each player's own physics runs here, that blocks
local function solidWall(folder)
 local function solid(p)if p:IsA("BasePart")then p.CanCollide=true end end
 for _,p in ipairs(folder:GetDescendants())do solid(p)end
 folder.DescendantAdded:Connect(solid)
end
if game:GetService("RunService"):IsClient()then
 workspace.ChildAdded:Connect(function(c)if c.Name=="P5NullifiedWall"then solidWall(c)end end)
 local now=workspace:FindFirstChild("P5NullifiedWall")
 if now then solidWall(now)end
end
return P
